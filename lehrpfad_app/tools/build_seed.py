#!/usr/bin/env python3
"""Baut Trail-Seed-JSON aus OSM-Rohdaten + redaktioneller Trail-Config.

Nutzung:
  python3 tools/build_seed.py tools/trails/von-moor-zu-moor.json

Eingaben (Dateiprefix aus Config-Schluessel "rohdaten", Default = "id"):
  tools/osm/<prefix>_rel.json       OSM-Relation (Route, Ways mit Geometrie)
    ODER tools/osm/<prefix>_route.json  manuelle/GPX-Polyline [[lat,lon], ...]
  tools/osm/<prefix>_pois.json      POI-Nodes (Stationen, Aussichtspunkte)
  tools/osm/<prefix>_amenities.json Amenity-Nodes (WC, Parkplatz, Baenke, ...)

Stationen in der Config: OSM-Node-ID als Key (Koordinaten aus POIs) oder
Key mit lat/lon im Stationsobjekt (Feldcapture ohne OSM-Node).

Ausgabe: assets/seed/<Config "output", Default "<id>.json"> mit Route
(gestitcht), Stationen in Laufrichtung sortiert und Amenities im 150-m-Korridor.
Rohdaten liegen bewusst ausserhalb von assets/, damit sie nicht ins
App-Bundle wandern.
"""
import hashlib
import json
import math
import os
import sys

KORRIDOR_KM = 0.15
SCHLIESS_KM = 0.5
TOOLS_DIR = os.path.dirname(__file__)
RAW_DIR = os.path.join(TOOLS_DIR, "osm")
SEED_DIR = os.path.join(TOOLS_DIR, "..", "assets", "seed")

AMENITY_MAP = {
    ("amenity", "toilets"): "wc",
    ("amenity", "parking"): "parking",
    ("amenity", "bench"): "bench",
    ("amenity", "picnic_table"): "picnic",
    ("amenity", "shelter"): "shelter",
    ("amenity", "restaurant"): "gastro",
    ("amenity", "cafe"): "gastro",
    ("amenity", "biergarten"): "gastro",
    ("amenity", "fast_food"): "gastro",
    ("leisure", "playground"): "playground",
    ("leisure", "picnic_table"): "picnic",
    ("tourism", "viewpoint"): "viewpoint",
    ("tourism", "museum"): "viewpoint",
    ("tourism", "picnic_site"): "picnic",
}


def haversine_km(lat1, lon1, lat2, lon2):
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def interpolate(a, b, max_km=KORRIDOR_KM):
    """Zwischenpunkte a→b, damit keine Sprünge > max_km bleiben."""
    dist = haversine_km(*a, *b)
    n = max(1, int(dist // max_km))
    out = []
    for i in range(1, n + 1):
        t = i / n
        out.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
    return out


def stitch_route(rel):
    """Verkettet die Way-Geometrien der Relation zu einer Punktliste.

    Ways mit Sonderrollen (alternative/approach/excursion) gehoeren nicht zum
    Hauptverlauf und werden uebersprungen.
    """
    ways = [m["geometry"] for m in rel["members"]
            if m.get("geometry") and m.get("role", "") in ("", "route")]
    route = list(ways.pop(0))
    while ways:
        end = route[-1]
        for i, w in enumerate(ways):
            if w[0] == end:
                route.extend(w[1:])
                ways.pop(i)
                break
            if w[-1] == end:
                route.extend(list(reversed(w))[1:])
                ways.pop(i)
                break
        else:
            # Kein exakter Anschluss: naechstbesten Way anhaengen (Rundkurs-Relation
            # kann Luecken/Umwege enthalten), damit nichts verloren geht.
            naechster = min(
                ways,
                key=lambda w: min(
                    haversine_km(end["lat"], end["lon"], w[0]["lat"], w[0]["lon"]),
                    haversine_km(end["lat"], end["lon"], w[-1]["lat"], w[-1]["lon"]),
                ),
            )
            ways.remove(naechster)
            if haversine_km(end["lat"], end["lon"], naechster[0]["lat"], naechster[0]["lon"]) <= \
               haversine_km(end["lat"], end["lon"], naechster[-1]["lat"], naechster[-1]["lon"]):
                route.extend(naechster)
            else:
                route.extend(reversed(naechster))
            print(f"WARN: Way-Luecke geschlossen bei {end['lat']:.5f},{end['lon']:.5f}", file=sys.stderr)
    return [(p["lat"], p["lon"]) for p in route]


def load_rohdaten(prefix, suffix, required=True):
    path = os.path.join(RAW_DIR, f"{prefix}_{suffix}.json")
    if not os.path.isfile(path):
        if required:
            sys.exit(f"Fehlt: {path}")
        return []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    return data.get("elements", data)


def load_route(prefix, cfg):
    """Manuelle/GPX-Polyline (*_route.json) oder OSM-Relation (*_rel.json).

    *_route.json hat Vorrang: bei Netz-Relationen (linear=no) ist der Stitch
    unzuverlässig; redaktionell kuratierte Polylines (GPX/Dijkstra) gewinnen.
    """
    rel_path = os.path.join(RAW_DIR, f"{prefix}_rel.json")
    route_path = os.path.join(RAW_DIR, f"{prefix}_route.json")
    tags = {}
    if os.path.isfile(rel_path):
        tags = load_rohdaten(prefix, "rel")[0].get("tags", {})

    raw = cfg.get("route")
    if raw is None and os.path.isfile(route_path):
        with open(route_path, encoding="utf-8") as f:
            raw = json.load(f)
    if raw is not None:
        route = []
        for p in raw:
            if isinstance(p, (list, tuple)) and len(p) >= 2:
                route.append((float(p[0]), float(p[1])))
            elif isinstance(p, dict):
                route.append((float(p["lat"]), float(p["lon"])))
            else:
                sys.exit(f"Ungültiger Routenpunkt: {p!r}")
        if len(route) < 2:
            sys.exit("Route braucht mindestens 2 Punkte (nach Feldcapture/GPX)")
        return route, tags

    if os.path.isfile(rel_path):
        rel = load_rohdaten(prefix, "rel")[0]
        return stitch_route(rel), rel.get("tags", {})

    sys.exit(
        f"Keine Route: weder {route_path} noch {rel_path} "
        f"(oder Config-Key \"route\") mit Punkten"
    )


def station_coords(osm_id_str, inhalt, pois_by_id):
    """Koordinaten aus POI-Lookup oder lat/lon im Stationsobjekt (Feldcapture)."""
    if "lat" in inhalt and "lon" in inhalt:
        lat, lon = float(inhalt["lat"]), float(inhalt["lon"])
        try:
            osm_id = int(osm_id_str)
        except ValueError:
            # Stabile ID aus Key, negativ = manuell (kein OSM-Node)
            digest = hashlib.sha1(osm_id_str.encode()).hexdigest()[:8]
            osm_id = -int(digest, 16)
        return osm_id, lat, lon
    try:
        osm_id = int(osm_id_str)
    except ValueError:
        return None, None, None
    e = pois_by_id.get(osm_id)
    if not e:
        return None, None, None
    return osm_id, e["lat"], e["lon"]


def main():
    if len(sys.argv) < 2:
        sys.exit("Nutzung: build_seed.py <trail-config.json>")
    with open(sys.argv[1], encoding="utf-8") as f:
        cfg = json.load(f)

    prefix = cfg.get("rohdaten", cfg["id"])
    pois = load_rohdaten(prefix, "pois", required=False)
    amenities_raw = load_rohdaten(prefix, "amenities", required=False)
    if not cfg.get("stationen"):
        sys.exit("Config \"stationen\" ist leer – erst Feldcapture eintragen")

    route, tags = load_route(prefix, cfg)
    pois_by_id = {e["id"]: e for e in pois if "id" in e and "lat" in e}

    def routen_index(lat, lon):
        return min(range(len(route)), key=lambda i: haversine_km(lat, lon, *route[i]))

    # Rundkurs: Richtung optional an zwei Stations-IDs ausrichten
    # (Config "richtung": [erste, zweite] – erste muss vor zweiter liegen)
    richtung = cfg.get("richtung") or []
    if richtung and all(str(i) in cfg["stationen"] for i in richtung):
        coords = []
        for i in richtung:
            _oid, lat, lon = station_coords(str(i), cfg["stationen"][str(i)], pois_by_id)
            if lat is None:
                coords = []
                break
            coords.append((lat, lon))
        if len(coords) == 2:
            if routen_index(*coords[0]) > routen_index(*coords[1]):
                route.reverse()

    # Rundkurs nur, wenn die Route auch geschlossen ist – die Datenlage
    # schlaegt im Zweifel Config und Relations-Tag.
    roundtrip = tags.get("roundtrip")
    rundkurs_wunsch = (roundtrip == "yes") if roundtrip is not None else cfg.get("rundkurs", False)
    geschlossen = haversine_km(*route[0], *route[-1]) <= KORRIDOR_KM
    if rundkurs_wunsch and not geschlossen:
        gap = haversine_km(*route[0], *route[-1])
        if gap <= SCHLIESS_KM:
            print(f"WARN: OSM-Lücke {gap * 1000:.0f} m – schließe Rundkurs", file=sys.stderr)
            route = route + interpolate(route[-1], route[0])
            geschlossen = True
        else:
            print("WARN: Route nicht geschlossen – rundkurs wird auf false gesetzt", file=sys.stderr)
    rundkurs = rundkurs_wunsch and geschlossen

    # Rundkurs: Route optional zum offiziellen Startpunkt rotieren
    # (Config "startAm": Stations-OSM-ID, z. B. Eingangstafel/Parkplatz)
    start_am = cfg.get("startAm")
    if start_am and rundkurs:
        _oid, slat, slon = station_coords(
            str(start_am), cfg["stationen"].get(str(start_am), {}), pois_by_id
        )
        if slat is not None:
            if route[0] == route[-1]:
                route = route[:-1]
            i0 = routen_index(slat, slon)
            route = route[i0:] + route[:i0] + [route[i0]]

    # Streckenkilometer pro Routenpunkt (kumulativ)
    km = [0.0]
    for i in range(1, len(route)):
        km.append(km[-1] + haversine_km(*route[i - 1], *route[i]))
    laenge_km = round(km[-1], 1)

    # Stationen auf Route projizieren -> Reihenfolge in Laufrichtung
    stationen = []
    for osm_id_str, inhalt in cfg["stationen"].items():
        osm_id, lat, lon = station_coords(osm_id_str, inhalt, pois_by_id)
        if lat is None:
            print(f"WARN: Station {osm_id_str} ({inhalt.get('titel')}) ohne Koordinaten", file=sys.stderr)
            continue
        # lat/lon nicht doppelt in Seed schreiben, wenn nur für Lookup in Config
        payload = {k: v for k, v in inhalt.items() if k not in ("lat", "lon")}
        best_i = min(range(len(route)), key=lambda i: haversine_km(lat, lon, *route[i]))
        stationen.append({
            "osmId": osm_id,
            "lat": lat,
            "lon": lon,
            "km": round(km[best_i], 2),
            **payload,
        })
    if len(stationen) < 3:
        sys.exit(f"Nur {len(stationen)} Stationen mit Koordinaten – Go-Kriterium ist ≥3")
    stationen.sort(key=lambda s: s["km"])
    for i, s in enumerate(stationen, 1):
        s["reihenfolge"] = i

    # Amenities im Korridor (aus beiden Quellen)
    amenities = []
    for e in amenities_raw + pois:
        if "lat" not in e:
            continue
        e_tags = e.get("tags", {})
        kat = next((v for (k, val), v in AMENITY_MAP.items() if e_tags.get(k) == val), None)
        if not kat:
            continue
        dist = min(haversine_km(e["lat"], e["lon"], *p) for p in route[::3])
        if dist <= KORRIDOR_KM:
            amenities.append({
                "osmId": e["id"],
                "lat": e["lat"],
                "lon": e["lon"],
                "kategorie": kat,
                "name": e_tags.get("name"),
            })
    # POIs und Amenities-Rohdaten können dieselben Nodes liefern
    seen_amenity = set()
    unique_amenities = []
    for a in amenities:
        if a["osmId"] in seen_amenity:
            continue
        seen_amenity.add(a["osmId"])
        unique_amenities.append(a)
    amenities = unique_amenities

    trail = {
        "id": cfg["id"],
        # Config-Name hat Vorrang: OSM-Relationen heissen oft anders als der
        # redaktionelle Produktname (z. B. „… Südroute“ vs. „Heide-Erlebnisweg“).
        "name": cfg.get("name") or tags.get("name"),
        "typ": cfg["typ"],
        "kurzbeschreibung": cfg["kurzbeschreibung"],
        "beschreibung": cfg["beschreibung"],
        "laengeKm": laenge_km,
        "dauerMin": cfg.get("dauerMin") or int(round(laenge_km / 4.0 * 60 / 5) * 5),
        "rundkurs": rundkurs,
        "markierung": cfg.get("markierung") or tags.get("symbol:de", ""),
        "betreiber": cfg["betreiber"],
        "region": cfg["region"],
        "website": cfg.get("website") or tags.get("website"),
        "anreise": cfg["anreise"],
        "startName": cfg["startName"],
        "arten": cfg["arten"],
        # Redaktionelle Ausstattungs-Tags (Katalog in der App: icon_catalog.dart).
        # Auto-Tags (parkplatz-nahe, wc-am-weg) leitet die App aus amenities ab.
        "tags": cfg.get("tags", []),
        "form": cfg.get("form") or "linie",
        "route": [[round(lat, 6), round(lon, 6)] for lat, lon in route],
        "area": cfg.get("area") or [],
        "stationen": stationen,
        "amenities": amenities,
    }

    out = os.path.join(SEED_DIR, cfg.get("output", cfg["id"] + ".json"))
    with open(out, "w", encoding="utf-8") as f:
        json.dump(trail, f, ensure_ascii=False, indent=1)
    print(f"OK: {out}")
    print(f"  Route: {len(route)} Punkte, {laenge_km} km")
    print(f"  Stationen: {len(stationen)} -> " + ", ".join(f"{s['reihenfolge']}. {s['titel']}" for s in stationen))
    kat_count = {}
    for a in amenities:
        kat_count[a["kategorie"]] = kat_count.get(a["kategorie"], 0) + 1
    print(f"  Amenities: {len(amenities)} {kat_count}")


if __name__ == "__main__":
    main()
