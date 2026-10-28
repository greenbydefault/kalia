"""bilder/ -> AVIF thumb/small/medium (480/900/2000, laengste Kante, kein Crop).

Wie lib/shared/images/image_variants.dart: EXIF-Orientierung anwenden, EXIF entfernen, nie
hochskalieren. Qualitaet wird gegen ein Byte-Budget kalibriert (sips-Werte 35/30/40 sind nicht
uebertragbar). images.id = uuid5(Namespace, "<trail>/<dateiname-ohne-endung>"), images.hash =
SHA-256 der medium-Datei.
"""
from __future__ import annotations

import hashlib
import io
import os
import uuid
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image, ImageOps

from . import config, lists
from .geometry import distance_to_trail_m

NAMESPACE = uuid.UUID(config.IMAGE_NAMESPACE)
ENDUNGEN = (".jpg", ".jpeg", ".png", ".webp", ".avif", ".tif", ".tiff", ".heic")


def image_id(trail_id: str, datei: str) -> str:
    stem = os.path.basename(datei)
    for ext in ENDUNGEN:
        if stem.lower().endswith(ext):
            stem = stem[: -len(ext)]
            break
    return str(uuid.uuid5(NAMESPACE, "%s/%s" % (trail_id, stem)))


def _dms(vals, ref) -> Optional[float]:
    try:
        d, m, s = (float(v) for v in vals)
    except (TypeError, ValueError):
        return None
    deg = d + m / 60.0 + s / 3600.0
    return -deg if ref in ("S", "W") else deg


def exif_gps(img: Image.Image) -> Optional[Tuple[float, float]]:
    try:
        gps = img.getexif().get_ifd(0x8825)
    except Exception:
        return None
    if not gps or 2 not in gps or 4 not in gps:
        return None
    la = _dms(gps.get(2), gps.get(1))
    lo = _dms(gps.get(4), gps.get(3))
    if la is None or lo is None:
        return None
    return la, lo


def _to_rgb(im: Image.Image) -> Image.Image:
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        bg = Image.new("RGB", im.size, (255, 255, 255))
        bg.paste(im, mask=im.split()[-1])
        return bg
    return im.convert("RGB") if im.mode != "RGB" else im


def _encode(im: Image.Image, variant: str) -> bytes:
    budget = config.BILD_ZIEL_BYTES[variant]
    q = config.AVIF_QUALITAET_START[variant]
    while True:
        buf = io.BytesIO()
        im.save(buf, format="AVIF", quality=q)
        data = buf.getvalue()
        if len(data) <= budget or q <= config.AVIF_QUALITAET_MIN:
            return data
        q -= 5


def make_variants(path: str) -> Dict[str, Any]:
    """-> {thumb, small, medium: bytes, width, height, gps, hash, mime_type}. Wirft ValueError."""
    if os.path.getsize(path) > config.MAX_BILD_MB * 1024 * 1024:
        raise ValueError("Bild ist groesser als %d MB" % config.MAX_BILD_MB)
    try:
        src = Image.open(path)
        src.load()
    except Exception as e:
        raise ValueError("Bild nicht lesbar: %s" % e)
    gps = exif_gps(src)
    im = _to_rgb(ImageOps.exif_transpose(src))
    w, h = im.size
    out: Dict[str, Any] = {"width": w, "height": h, "gps": gps, "mime_type": "image/avif"}
    for name, edge in config.BILD_VARIANTEN:
        scale = min(1.0, edge / float(max(w, h)))
        v = im if scale >= 1.0 else im.resize(
            (max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
        out[name] = _encode(v, name)
    out["hash"] = hashlib.sha256(out["medium"]).hexdigest()
    return out


def geo_check(gps: Optional[Tuple[float, float]], route, area, flaeche: bool) -> str:
    if gps is None:
        return "none"
    d = distance_to_trail_m(gps, route, area)
    if d is None:
        return "none"
    on_site = config.FOTO_NAH_M_FLAECHE if flaeche else config.FOTO_NAH_M_LINIE
    if d <= on_site:
        return "match"
    if d <= config.FOTO_GEGEND_M:
        return "near"
    return "far"


def lizenz_status(lizenz: Optional[str]) -> str:
    return "approved" if lizenz in lists.BILD_LIZENZ_APPROVED else "pending"


def process_bilder(root: str, slug: str, rows: List[Dict[str, Any]], route, area, flaeche: bool,
                   find_file) -> Dict[str, Any]:
    """Verarbeitet die Bildzeilen aus Abschnitt 7.

    -> {"bilder": [Record...], "issues": [...]}.  Record enthaelt "files" (Bytes) zum Hochladen,
    das ganze Objekt wird nie als JSON gespeichert.
    """
    records: List[Dict[str, Any]] = []
    issues: List[Dict[str, Any]] = []
    seen: set = set()
    for i, r in enumerate(rows):
        datei = (r.get("datei") or "").strip()
        feld = "bilder[%d]" % (i + 1)
        if not datei:
            issues.append({"code": "DATEI_FEHLT", "feld": feld, "wert": None})
            continue
        path = find_file(os.path.join(root, "bilder") if os.path.isdir(os.path.join(root, "bilder")) else root,
                         datei, ())
        if path is None:
            issues.append({"code": "DATEI_FEHLT", "feld": feld, "wert": datei})
            continue
        iid = image_id(slug, datei)
        if iid in seen:
            issues.append({"code": "BILD_DATEI", "feld": feld, "wert": "doppelter Dateiname " + datei})
            continue
        seen.add(iid)
        try:
            v = make_variants(path)
        except ValueError as e:
            issues.append({"code": "BILD_DATEI", "feld": feld, "wert": "%s: %s" % (datei, e)})
            continue
        lizenz = r.get("license")
        status = lizenz_status(lizenz)
        if lizenz not in lists.BILD_LIZENZ_APPROVED:
            issues.append({"code": "BILD_LIZENZ", "feld": feld,
                           "wert": {"datei": datei, "lizenz": lizenz}})
        kind = r.get("kind") or "hero"
        station_nr = r.get("station_reihenfolge")
        records.append({
            "id": iid, "datei": datei, "kind": "station" if kind == "station" else "ort",
            "station_reihenfolge": station_nr if kind == "station" else None,
            "caption": r.get("caption") or "", "credit": r.get("credit") or "",
            "license": lizenz or "", "license_url": r.get("license_url") or "",
            "source_url": r.get("source_url") or "",
            "sort": r.get("sort") or (i + 1), "status": status,
            "hash": v["hash"], "mime_type": v["mime_type"],
            "width": v["width"], "height": v["height"],
            "thumb_bytes": len(v["thumb"]), "small_bytes": len(v["small"]),
            "medium_bytes": len(v["medium"]),
            "geo_check": geo_check(v["gps"], route, area, flaeche),
            "files": {"thumb": v["thumb"], "small": v["small"], "medium": v["medium"]},
        })
    return {"bilder": records, "issues": issues}
