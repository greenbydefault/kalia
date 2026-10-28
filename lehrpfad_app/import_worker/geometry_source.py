"""Waehlt die Geometrie eines Pfads: Datei aus dem ZIP (mit Quelle und Lizenz) oder OSM-Rueckfall."""
from __future__ import annotations

import json
import os
from typing import Any, Dict, List, Optional

from . import lists
from .geometry import GeometrieFehler, centroid, length_km, read_geojson, read_gpx

OSM_DIR = os.path.join(os.path.dirname(__file__), "..", "tools", "osm")


def find_file(root: str, name: Optional[str], defaults) -> Optional[str]:
    """Sucht unterhalb von root (ohne Beachtung von Gross/Klein und Tiefe) nach name oder defaults."""
    wanted = [os.path.basename(n).lower() for n in ([name] if name else []) + list(defaults)]
    for dp, _dn, fn in os.walk(root):
        for f in sorted(fn):
            if f.lower() in wanted:
                return os.path.join(dp, f)
    return None


def pick_geometry(root: str, slug: str, form: str, meta: Dict[str, Any],
                  osm_dir: str = OSM_DIR) -> Dict[str, Any]:
    """-> {route, area, herkunft: gpx|geojson|osm|None, quelle, lizenz, datei, issues}

    issues: [{"code", "feld", "wert"}]  (GEOMETRIE_LIZENZ, DATEI_FEHLT, GEOMETRIE_FEHLT, GEOMETRIE_DATEI)
    """
    issues: List[Dict[str, Any]] = []
    out: Dict[str, Any] = {"route": [], "area": [], "herkunft": None, "quelle": None,
                           "lizenz": None, "datei": None, "issues": issues}
    flaeche = form == "flaeche"
    defaults = ("flaeche.geojson", "flaeche.json") if flaeche else ("route.gpx", "route.geojson")
    named = meta.get("geometrie_datei")
    # Dossier-Eintrag kann eine Beschreibung sein ("route.gpx (Betreiber)"); nur Dateinamen zaehlen
    if named and " " in named.strip():
        named = named.strip().split()[0]
    path = find_file(root, named, defaults)
    if not path and not flaeche:
        path = find_file(root, None, ("track.gpx",)) or _any_ext(root, ".gpx")
    if flaeche and not path:
        path = _any_ext(root, ".geojson")

    quelle = meta.get("geometrie_quelle")
    lizenz = meta.get("geometrie_lizenz")
    if path:
        lizenz_ok = lizenz in lists.GEOMETRIE_LIZENZEN
        if not (quelle and lizenz_ok):
            issues.append({"code": "GEOMETRIE_LIZENZ", "feld": "route" if not flaeche else "area",
                           "wert": {"quelle": quelle, "lizenz": lizenz, "datei": os.path.basename(path)}})
        else:
            try:
                if path.lower().endswith(".gpx"):
                    route = read_gpx(path)
                    if flaeche:
                        issues.append({"code": "GEOMETRIE_DATEI", "feld": "area",
                                       "wert": "GPX statt GeoJSON bei Fläche"})
                    else:
                        out.update(route=route, herkunft="gpx")
                else:
                    gj = read_geojson(path)
                    if flaeche and "area" in gj:
                        out.update(area=gj["area"], herkunft="geojson")
                    elif not flaeche and "route" in gj:
                        out.update(route=gj["route"], herkunft="geojson")
                    else:
                        issues.append({"code": "GEOMETRIE_DATEI", "feld": "area" if flaeche else "route",
                                       "wert": "GeoJSON passt nicht zur Form " + form})
                if out["herkunft"]:
                    out.update(quelle=quelle, lizenz=lizenz, datei=os.path.basename(path))
            except GeometrieFehler as e:
                issues.append({"code": "GEOMETRIE_DATEI", "feld": "area" if flaeche else "route", "wert": str(e)})
    elif named:
        issues.append({"code": "DATEI_FEHLT", "feld": "route" if not flaeche else "area", "wert": named})

    if not out["herkunft"] and not flaeche:
        osm = os.path.join(osm_dir, "%s_route.json" % slug)
        if os.path.isfile(osm):
            with open(osm, encoding="utf-8") as f:
                route = json.load(f)
            if isinstance(route, list) and len(route) >= 2:
                out.update(route=[[round(p[0], 6), round(p[1], 6)] for p in route], herkunft="osm",
                           quelle="OpenStreetMap", lizenz="osm-odbl", datei=os.path.basename(osm))
    if not out["herkunft"]:
        issues.append({"code": "GEOMETRIE_FEHLT", "feld": "area" if flaeche else "route", "wert": None})
    return out


def _any_ext(root: str, ext: str) -> Optional[str]:
    for dp, _dn, fn in os.walk(root):
        for f in sorted(fn):
            if f.lower().endswith(ext):
                return os.path.join(dp, f)
    return None


def derive_from_geometry(trail: Dict[str, Any], geo: Dict[str, Any]) -> None:
    """Setzt Start, Laenge, Rundkurs aus der Geometrie, wo das Dossier nichts angibt."""
    form = trail.get("form") or "linie"
    if form == "flaeche":
        trail["laenge_km"] = 0
        trail["rundkurs"] = False
        if geo.get("area") and (trail.get("start_lat") is None or trail.get("start_lon") is None):
            c = centroid(geo["area"])
            trail["start_lat"], trail["start_lon"] = round(c[0], 6), round(c[1], 6)
        return
    route = geo.get("route") or []
    if not route:
        return
    if trail.get("start_lat") is None or trail.get("start_lon") is None:
        trail["start_lat"], trail["start_lon"] = route[0][0], route[0][1]
    if trail.get("laenge_km") is None:
        trail["laenge_km"] = round(length_km(route), 2)
