"""Baut aus einem Seed (assets/seed/<id>.json) ein ausgefuelltes Dossier.

Zweck: Round-Trip-Tests (Seed -> Dossier -> Parser -> Vergleich) und Fixtures fuer den Pilot.
Nutzung: python3 -m import_worker dossier <seed.json> <ordner>
"""
from __future__ import annotations

import json
import os
import shutil
import xml.etree.ElementTree as ET
from typing import Any, Dict, List, Optional

import docx

from . import config
from .docxutil import add_row_like_last, set_cell, set_text
from .parse_dossier import _classify, _supabase_key
from .docxutil import iter_body

TEMPLATE = os.path.join(os.path.dirname(__file__), "templates", "Vorlage_Pfad-Dossier_v3.docx")
SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")


def _land(lat: float, lon: float) -> str:
    for land, (la0, la1, lo0, lo1) in config.LAENDER_BOX.items():
        if la0 <= lat <= la1 and lo0 <= lon <= lo1:
            return land
    return "DE"


def _ja(v: Any) -> str:
    return "ja" if v else "nein"


def _fmt(v: Any) -> str:
    if v is None:
        return ""
    if isinstance(v, float) and v == int(v):
        return str(int(v)) if abs(v) > 1000 else repr(v)
    return str(v)


def seed_to_values(seed: Dict[str, Any], opts: Dict[str, Any]) -> Dict[str, str]:
    route = seed.get("route") or []
    area = seed.get("area") or []
    form = seed.get("form") or "linie"
    if route:
        lat, lon = route[0][0], route[0][1]
    elif area:
        lat = sum(p[0] for p in area) / len(area)
        lon = sum(p[1] for p in area) / len(area)
    else:
        lat = lon = 0.0
    v = {
        "trails.id": seed["id"], "trails.name": seed["name"], "trails.typ": seed["typ"],
        "trails.form": form,
        "trails.land": opts.get("land") or _land(lat, lon),
        "trails.bundesland": opts.get("bundesland", ""), "trails.kreis": opts.get("kreis", ""),
        "trails.ort": opts.get("ort", ""), "trails.schutzgebiet": opts.get("schutzgebiet", ""),
        "trails.region": seed.get("region", ""), "trails.betreiber": seed.get("betreiber", ""),
        "trails.website": seed.get("website") or "",
        "trails.kurzbeschreibung": seed.get("kurzbeschreibung", ""),
        "trails.beschreibung": seed.get("beschreibung", ""),
        "trails.anreise": seed.get("anreise", ""),
        "trails.besuchshinweise": seed.get("besuchshinweise") or "",
        "trails.markierung": seed.get("markierung", ""),
        "trails.start_name": seed.get("startName", ""),
        "trails.hoertext": seed.get("hoertext") or "",
        "trails.start_lat": "%s, %s" % (round(lat, 6), round(lon, 6)),
        "trails.route": opts.get("geometrie_datei", ""),
        "trails.laenge_km": "" if form == "flaeche" else _fmt(seed.get("laengeKm")),
        "trails.dauer_min": _fmt(seed.get("dauerMin")),
        "trails.rundkurs": _ja(seed.get("rundkurs")) if form != "flaeche" else "nein",
        "trails.eintritt": _ja(seed.get("eintritt")),
        "trails.eintritt_preise": seed.get("eintrittPreise") or "",
        "trails.oeffnungszeiten": seed.get("oeffnungszeiten") or "",
        "trails.tags": ", ".join(seed.get("tags") or []),
        "trails.naturraum": seed.get("naturraum") or "",
        "trails.lebensraeume": ", ".join(seed.get("lebensraeume") or []),
        "import.geometrie_quelle": opts.get("geometrie_quelle", ""),
        "import.geometrie_lizenz": opts.get("geometrie_lizenz", ""),
    }
    return {k: ("" if x is None else str(x)) for k, x in v.items()}


def _fill_table(table, rows: List[List[str]]) -> None:
    """Fuellt eine Listen-Tabelle: Zeile 1 ist vorbereitet, weitere werden kopiert."""
    for i, vals in enumerate(rows):
        row = table.rows[1] if i == 0 else add_row_like_last(table)
        for cell, text in zip(row.cells, vals):
            set_cell(cell, text)


def build_docx(seed: Dict[str, Any], out_path: str, opts: Optional[Dict[str, Any]] = None,
               species_lat: Optional[Dict[str, str]] = None) -> None:
    opts = opts or {}
    status = opts.get("status", "fertig")
    doc = docx.Document(TEMPLATE)
    values = seed_to_values(seed, opts)

    for p in doc.paragraphs:
        if p.text.startswith("Status Abschnitt:"):
            set_text(p, "Status Abschnitt: %s" % status)

    stat = opts.get("abschnitt_status") or {}
    sec = None
    for kind, el in iter_body(doc):
        if kind == "p":
            if el.style is not None and el.style.name.lower().startswith("heading 2"):
                import re
                m = re.match(r"^(\d+)\.\s", el.text.strip())
                sec = int(m.group(1)) if m else None
            elif el.text.startswith("Status Abschnitt:") and sec in stat:
                set_text(el, "Status Abschnitt: %s" % stat[sec])
            continue
        t = _classify(el)
        if t == "felder":
            for r in el.rows[1:]:
                key = _supabase_key(r.cells[1].text, r.cells[0].text.strip())
                if key in values:
                    set_cell(r.cells[2], values[key])
        elif t == "quellen" and sec in (1, 2, 3):
            if opts.get("quellen", True):
                _fill_table(el, [["1", "Betreiberseite", seed.get("website") or "https://example.org", "22.10.2026"]])
        elif t == "arten":
            nachweis = seed.get("artenNachweis") or {}
            rows = []
            for i, name in enumerate(seed.get("arten") or [], 1):
                lat = (species_lat or {}).get(name, "")
                rows.append([str(i), name, lat, "", nachweis.get(name, "typisch"), seed.get("website") or ""])
            if rows:
                _fill_table(el, rows)
        elif t == "stationen":
            rows = []
            for s in seed.get("stationen") or []:
                rows.append([
                    str(s["reihenfolge"]), _fmt(s.get("km")), repr(s["lat"]), repr(s["lon"]),
                    str(s.get("osmId") or ""), s.get("titel", ""), s.get("thema", ""),
                    s.get("kurztext", ""), ", ".join(s.get("erlebnisse") or []),
                    _ja(s.get("barrierefrei")), "",
                ])
            if rows:
                _fill_table(el, rows)
        elif t == "steckbrief":
            rows = []
            for s in seed.get("stationen") or []:
                for k, val in (s.get("steckbrief") or {}).items():
                    rows.append([str(s["reihenfolge"]), k, str(val)])
            if rows:
                _fill_table(el, rows)
        elif t == "bilder":
            rows = []
            for i, b in enumerate(opts.get("bilder") or [], 1):
                rows.append([str(i), b.get("kind", "hero"), str(b.get("station") or ""), b.get("caption", ""),
                             b["datei"], b.get("source_url", ""), b.get("license", ""),
                             b.get("license_url", ""), b.get("credit", "")])
            if rows:
                _fill_table(el, rows)
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    doc.save(out_path)


def write_gpx(route: List[List[float]], path: str) -> None:
    gpx = ET.Element("gpx", {"version": "1.1", "creator": "kalia-test", "xmlns": "http://www.topografix.com/GPX/1/1"})
    trk = ET.SubElement(gpx, "trk")
    seg = ET.SubElement(trk, "trkseg")
    for la, lo in route:
        ET.SubElement(seg, "trkpt", {"lat": repr(la), "lon": repr(lo)})
    ET.ElementTree(gpx).write(path, encoding="utf-8", xml_declaration=True)


def build_package(seed_path: str, out_dir: str, opts: Optional[Dict[str, Any]] = None) -> str:
    """Legt <out_dir>/<id>/ mit Dossier, route.gpx bzw. flaeche.geojson an. Gibt den Ordner zurueck."""
    with open(seed_path, encoding="utf-8") as f:
        seed = json.load(f)
    opts = dict(opts or {})
    folder = os.path.join(out_dir, seed["id"])
    os.makedirs(folder, exist_ok=True)
    form = seed.get("form") or "linie"
    if form == "flaeche" and seed.get("area"):
        gj = {"type": "Feature", "properties": {}, "geometry": {
            "type": "Polygon", "coordinates": [[[p[1], p[0]] for p in seed["area"]]]}}
        with open(os.path.join(folder, "flaeche.geojson"), "w", encoding="utf-8") as f:
            json.dump(gj, f)
        opts.setdefault("geometrie_datei", "flaeche.geojson")
    elif seed.get("route"):
        write_gpx(seed["route"], os.path.join(folder, "route.gpx"))
        opts.setdefault("geometrie_datei", "route.gpx")
    if opts.get("geometrie_datei"):
        opts.setdefault("geometrie_quelle", "Eigene Aufnahme")
        opts.setdefault("geometrie_lizenz", "eigen")
    sl = {}
    sp_path = os.path.join(SEED_DIR, "species.json")
    if os.path.isfile(sp_path):
        with open(sp_path, encoding="utf-8") as f:
            for s in json.load(f):
                for n in [s["nameDe"], *s.get("aliases", [])]:
                    sl[n] = s.get("nameLat", "")
    build_docx(seed, os.path.join(folder, "%s – Dossier.docx" % seed["id"]), opts, sl)
    return folder


def zip_folder(folder: str, zip_path: str) -> str:
    base = os.path.splitext(zip_path)[0]
    shutil.make_archive(base, "zip", os.path.dirname(folder), os.path.basename(folder))
    return base + ".zip"
