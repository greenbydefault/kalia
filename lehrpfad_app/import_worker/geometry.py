"""Geometrie: GPX/GeoJSON lesen, Laenge, Abstaende, Vereinfachung.

Alle Punkte sind [lat, lon] (wie trails.route/area), 6 Nachkommastellen.
"""
from __future__ import annotations

import json
import math
import xml.etree.ElementTree as ET
from typing import Any, Dict, List, Optional, Sequence, Tuple

from . import config

Punkt = List[float]
EARTH_M = 6371008.8


class GeometrieFehler(Exception):
    pass


def haversine_m(a: Sequence[float], b: Sequence[float]) -> float:
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp = p2 - p1
    dl = math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_M * math.asin(math.sqrt(h))


def length_km(route: Sequence[Sequence[float]]) -> float:
    return sum(haversine_m(route[i - 1], route[i]) for i in range(1, len(route))) / 1000.0


def centroid(area: Sequence[Sequence[float]]) -> Punkt:
    pts = area[:-1] if len(area) > 1 and list(area[0]) == list(area[-1]) else area
    return [sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)]


def _xy(p: Sequence[float], lat0: float) -> Tuple[float, float]:
    return (math.radians(p[1]) * EARTH_M * math.cos(math.radians(lat0)), math.radians(p[0]) * EARTH_M)


def _dist_point_segment_m(p, a, b) -> float:
    lat0 = p[0]
    px, py = _xy(p, lat0)
    ax, ay = _xy(a, lat0)
    bx, by = _xy(b, lat0)
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def distance_to_polyline_m(p: Sequence[float], line: Sequence[Sequence[float]]) -> Optional[float]:
    if not line:
        return None
    if len(line) == 1:
        return haversine_m(p, line[0])
    return min(_dist_point_segment_m(p, line[i - 1], line[i]) for i in range(1, len(line)))


def point_in_polygon(p: Sequence[float], poly: Sequence[Sequence[float]]) -> bool:
    x, y = p[1], p[0]
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i][1], poly[i][0]
        xj, yj = poly[j][1], poly[j][0]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-12) + xi:
            inside = not inside
        j = i
    return inside


def distance_to_area_m(p: Sequence[float], area: Sequence[Sequence[float]]) -> Optional[float]:
    if len(area) < 3:
        return None
    if point_in_polygon(p, area):
        return 0.0
    ring = list(area) + [area[0]]
    return distance_to_polyline_m(p, ring)


def distance_to_trail_m(p: Sequence[float], route, area) -> Optional[float]:
    if area and len(area) >= 3:
        return distance_to_area_m(p, area)
    if route:
        return distance_to_polyline_m(p, route)
    return None


def simplify(route: List[Punkt], tol_m: float = config.ROUTE_SIMPLIFY_M) -> List[Punkt]:
    """Douglas-Peucker, iterativ."""
    n = len(route)
    if n < 3:
        return route
    keep = [False] * n
    keep[0] = keep[-1] = True
    stack = [(0, n - 1)]
    while stack:
        i0, i1 = stack.pop()
        dmax, idx = 0.0, -1
        for i in range(i0 + 1, i1):
            d = _dist_point_segment_m(route[i], route[i0], route[i1])
            if d > dmax:
                dmax, idx = d, i
        if idx != -1 and dmax > tol_m:
            keep[idx] = True
            stack.append((i0, idx))
            stack.append((idx, i1))
    return [p for p, k in zip(route, keep) if k]


def _valid(lat: float, lon: float) -> bool:
    return -90 <= lat <= 90 and -180 <= lon <= 180


def read_gpx(path: str) -> List[Punkt]:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        raise GeometrieFehler("GPX ist kein gueltiges XML: %s" % e)

    def pts(tag: str) -> List[Punkt]:
        out: List[Punkt] = []
        for el in root.iter():
            if el.tag.split("}")[-1] == tag and "lat" in el.attrib and "lon" in el.attrib:
                la, lo = float(el.attrib["lat"]), float(el.attrib["lon"])
                if _valid(la, lo):
                    out.append([round(la, 6), round(lo, 6)])
        return out

    route = pts("trkpt") or pts("rtept")
    if len(route) < 2:
        raise GeometrieFehler("GPX enthaelt weniger als 2 Track- oder Routenpunkte")
    return _clean(route)


def _clean(route: List[Punkt]) -> List[Punkt]:
    out: List[Punkt] = []
    for p in route:
        if not out or p != out[-1]:
            out.append(p)
    if len(out) > config.ROUTE_MAX_PUNKTE:
        out = simplify(out)
    return out


def _ring(coords: Sequence) -> List[Punkt]:
    pts = [[round(c[1], 6), round(c[0], 6)] for c in coords if len(c) >= 2 and _valid(c[1], c[0])]
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]
    return pts


def read_geojson(path: str) -> Dict[str, Any]:
    """-> {"area": [[lat,lon],...]} bei Polygon, {"route": ...} bei LineString."""
    try:
        with open(path, encoding="utf-8") as f:
            gj = json.load(f)
    except (OSError, ValueError) as e:
        raise GeometrieFehler("GeoJSON nicht lesbar: %s" % e)

    geoms: List[Dict[str, Any]] = []

    def collect(o: Any) -> None:
        if not isinstance(o, dict):
            return
        t = o.get("type")
        if t == "FeatureCollection":
            for f in o.get("features") or []:
                collect(f)
        elif t == "Feature":
            collect(o.get("geometry"))
        elif t == "GeometryCollection":
            for g in o.get("geometries") or []:
                collect(g)
        elif t in ("Polygon", "MultiPolygon", "LineString", "MultiLineString"):
            geoms.append(o)

    collect(gj)
    polys: List[List[Punkt]] = []
    lines: List[List[Punkt]] = []
    for g in geoms:
        t, c = g["type"], g.get("coordinates") or []
        if t == "Polygon" and c:
            polys.append(_ring(c[0]))
        elif t == "MultiPolygon":
            polys.extend(_ring(poly[0]) for poly in c if poly)
        elif t == "LineString":
            lines.append([[round(p[1], 6), round(p[0], 6)] for p in c])
        elif t == "MultiLineString":
            lines.extend([[round(p[1], 6), round(p[0], 6)] for p in ln] for ln in c)
    polys = [p for p in polys if len(p) >= 3]
    if polys:
        biggest = max(polys, key=lambda r: _area_m2(r))
        return {"area": biggest}
    lines = [ln for ln in lines if len(ln) >= 2]
    if lines:
        joined: List[Punkt] = []
        for ln in lines:
            joined.extend(ln)
        return {"route": _clean(joined)}
    raise GeometrieFehler("GeoJSON enthaelt kein Polygon und keine Linie")


def _area_m2(ring: Sequence[Sequence[float]]) -> float:
    lat0 = ring[0][0]
    pts = [_xy(p, lat0) for p in ring]
    s = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % len(pts)]
        s += x1 * y2 - x2 * y1
    return abs(s) / 2


def max_jump_m(route: Sequence[Sequence[float]]) -> float:
    return max((haversine_m(route[i - 1], route[i]) for i in range(1, len(route))), default=0.0)
