#!/usr/bin/env python3
"""Baut trail.json (Seed fuer die Lehrpfad-App) aus den OSM-Rohdaten in /tmp.

Quellen:
  /tmp/moor_rel.json       OSM-Relation 19440967 (Route, 45 Ways mit Geometrie)
  /tmp/moor_pois.json      POI-Nodes (Stationen, Aussichtspunkte)
  /tmp/moor_amenities.json Amenity-Nodes (WC, Parkplatz, Baenke, ...)

Ausgabe: trail.json mit Route (gestitcht), 8 Stationen in Laufrichtung
sortiert und Amenities im 150-m-Korridor.
"""
import json
import math
import sys

KORRIDOR_KM = 0.15

STATIONEN = {
    886115799: {
        "titel": "Grubitzwisch",
        "thema": "Aufbruch – ein Moor kehrt zurück",
        "kurztext": "In einem spannenden Quiz erfahren wir, wie ein Moor entsteht, "
                    "wie das „Laacher Seetuffband“ hilft, die Entstehungszeit des "
                    "Grubitzwisch zu bestimmen und wie sich Flora und Fauna allmählich "
                    "auf die sich verändernden Bedingungen einstellen.",
        "erlebnisse": ["quiz", "steg", "tafel"],
        "barrierefrei": False,
        "steckbrief": {
            "groesseHa": 3.8,
            "alterJahre": 13000,
            "tiefeM": 4.25,
            "lebenselixier": "Wasser",
            "werdegang": "vom See – zum Verlandungsmoor – zur Wiese und wieder zum Moor?",
        },
    },
    427675476: {
        "titel": "Schleusenwiese",
        "thema": "Vielfalt – blühende Feuchtwiese",
        "kurztext": "Die durch Entwässerung entstandenen Feuchtwiesen werden im Spätsommer "
                    "gemäht. Durch diese schonende Nutzung kann dieser artenreiche, "
                    "deutschlandweit gefährdete Biotoptyp erhalten werden.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": {
            "groesseHa": 2.7,
            "alterJahre": None,
            "tiefeM": 7.0,
            "lebenselixier": "hohe Feuchte, 1-mal Mahd im August",
            "werdegang": "vom See – zum Verlandungsmoor – zur Wiese",
        },
    },
    886115730: {
        "titel": "Kesselmoor",
        "thema": "Ein Kessel Saures – Torfentwicklung",
        "kurztext": "Wir lernen an dieser Station, wie Torf entsteht. Auf den sauren "
                    "Standorten wachsen überwiegend Torfmoose, die enorme Wassermengen "
                    "speichern können und sich wie ein Schwamm ausdrücken lassen.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": {
            "groesseHa": 0.25,
            "alterJahre": None,
            "tiefeM": 3.45,
            "lebenselixier": "Regenwasser",
            "werdegang": "vom Kleinsee – zum Verlandungsmoor – und zum Kesselmoor",
        },
    },
    886115569: {
        "titel": "Großer Barschsee",
        "thema": "Harmonie – Zusammenspiel der Lebewesen",
        "kurztext": "Ein weit in das Moor ragender Steg macht es möglich, Annette von "
                    "Droste-Hülshoffs Zeilen „O, schaurig ist‘s übers Moor zu gehn“ "
                    "nachzuempfinden. Ein Bohrkernmodell lässt uns tief in den 12.000 Jahre "
                    "alten Moorboden hineinschauen.",
        "erlebnisse": ["steg", "bohrkernmodell", "tafel"],
        "barrierefrei": True,
        "steckbrief": {
            "groesseHa": 5.8,
            "alterJahre": 12000,
            "tiefeM": 8.2,
            "lebenselixier": "nährstoffarmes Wasser",
            "werdegang": "vom See – zum Verlandungsmoor – zum echten Kesselmoor",
        },
    },
    427675478: {
        "titel": "Bruch am Roofensee",
        "thema": "Geheimnis – Erlen im Wasser",
        "kurztext": "Der Erlenwald am Ende des Roofensees scheint auf Stelzen zu stehen. "
                    "Schwarzerlen gehören zu den wenigen heimischen Baumarten, die sich "
                    "unter solchen Extrembedingungen behaupten können.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": {
            "groesseHa": None,
            "alterJahre": None,
            "tiefeM": 8.0,
            "lebenselixier": "mal mehr, mal weniger Wasser",
            "werdegang": "vom See – zum Verlandungsmoor",
        },
    },
    13034916580: {
        "titel": "Dietrichs Teerofen",
        "thema": "Leben der Teerofenbewohner",
        "kurztext": "Am ehemaligen Standort von Dietrichs Teerofen am Teufelssee informiert "
                    "eine Tafel über das Leben der Teerofenbewohner.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": None,
    },
    7196045988: {
        "titel": "Gewusst wie – leben mit dem Biber",
        "thema": "Die Rückkehr des Bibers",
        "kurztext": "Infotafel über die Rückkehr des Bibers in die Region und das "
                    "Zusammenleben mit ihm.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": None,
    },
    7196045996: {
        "titel": "Vom Riss zum Harz",
        "thema": "Vom Riss zum Harz",
        "kurztext": "Infotafel zur Entstehung von Harz und Pech – vom Riss in der "
                    "Baumrinde bis zum fertigen Produkt.",
        "erlebnisse": ["tafel"],
        "barrierefrei": False,
        "steckbrief": None,
    },
}

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
    ("tourism", "viewpoint"): "viewpoint",
}


def haversine_km(lat1, lon1, lat2, lon2):
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def stitch_route(rel):
    """Verkettet die Way-Geometrien der Relation zu einer Punktliste."""
    ways = [m["geometry"] for m in rel["members"] if m.get("geometry")]
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


def main():
    with open("/tmp/moor_rel.json") as f:
        rel = json.load(f)["elements"][0]
    with open("/tmp/moor_pois.json") as f:
        pois = json.load(f)["elements"]
    with open("/tmp/moor_amenities.json") as f:
        amenities_raw = json.load(f)["elements"]

    route = stitch_route(rel)

    # Rundkurs: Richtung an der offiziellen Stationsnummerierung ausrichten
    # (Grubitzwisch = 1. Station muss vor Schleusenwiese = 2. Station liegen)
    pois_by_id = {e["id"]: e for e in pois}

    def routen_index(lat, lon):
        return min(range(len(route)), key=lambda i: haversine_km(lat, lon, *route[i]))

    if routen_index(pois_by_id[886115799]["lat"], pois_by_id[886115799]["lon"]) > \
       routen_index(pois_by_id[427675476]["lat"], pois_by_id[427675476]["lon"]):
        route.reverse()

    # Streckenkilometer pro Routenpunkt (kumulativ)
    km = [0.0]
    for i in range(1, len(route)):
        km.append(km[-1] + haversine_km(*route[i - 1], *route[i]))
    laenge_km = round(km[-1], 1)

    # Stationen auf Route projizieren -> Reihenfolge in Laufrichtung
    stationen = []
    pois_by_id = {e["id"]: e for e in pois}
    for osm_id, inhalt in STATIONEN.items():
        e = pois_by_id.get(osm_id)
        if not e:
            print(f"WARN: Station {osm_id} ({inhalt['titel']}) nicht in POIs gefunden", file=sys.stderr)
            continue
        best_i = min(range(len(route)), key=lambda i: haversine_km(e["lat"], e["lon"], *route[i]))
        stationen.append({
            "osmId": osm_id,
            "lat": e["lat"],
            "lon": e["lon"],
            "km": round(km[best_i], 2),
            **inhalt,
        })
    stationen.sort(key=lambda s: s["km"])
    for i, s in enumerate(stationen, 1):
        s["reihenfolge"] = i

    # Amenities im Korridor (aus beiden Quellen)
    amenities = []
    for e in amenities_raw + pois:
        tags = e.get("tags", {})
        kat = next((v for (k, val), v in AMENITY_MAP.items() if tags.get(k) == val), None)
        if not kat:
            continue
        dist = min(haversine_km(e["lat"], e["lon"], *p) for p in route[::3])
        if dist <= KORRIDOR_KM:
            amenities.append({
                "osmId": e["id"],
                "lat": e["lat"],
                "lon": e["lon"],
                "kategorie": kat,
                "name": tags.get("name"),
            })

    tags = rel.get("tags", {})
    trail = {
        "id": "von-moor-zu-moor",
        "name": tags.get("name", "Von Moor zu Moor"),
        "typ": "moor",
        "kurzbeschreibung": "Rundweg durch schattige Kiefern- und Buchenwälder zu fünf "
                            "Moortypen – mit Stegen, Quiz und Bohrkernmodell.",
        "beschreibung": "Neben dem Seenreichtum ist auch eine Vielzahl von Mooren "
                        "charakteristisch für die eiszeitliche Landschaft dieser Region. "
                        "Der Rundweg kann in beide Richtungen, aber auch in einzelnen Etappen, "
                        "zu Fuß oder mit dem Rad erlebt werden. Station 4 (Großer Barschsee) "
                        "ist auch mit dem Rollstuhl erreichbar. Idealer Ausgangspunkt ist das "
                        "NaturParkHaus Stechlin in Menz. Einkehrmöglichkeiten gibt es nur in "
                        "Menz – Verpflegung mitnehmen.",
        "laengeKm": laenge_km,
        "dauerMin": int(round(laenge_km / 4.0 * 60 / 5) * 5),
        "rundkurs": tags.get("roundtrip") == "yes",
        "markierung": tags.get("symbol:de", "Grün-blauer Punkt auf weißem Grund"),
        "betreiber": "Naturpark Stechlin-Ruppiner Land",
        "region": "Menz, Stechlin, Landkreis Oberhavel, Brandenburg",
        "website": tags.get("website"),
        "anreise": "RE 5 ab Berlin Hbf nach Gransee oder Fürstenberg/Havel, weiter mit Bus "
                   "836 bzw. 847 nach Menz, Am Friedensplatz. Auto: B 96 bis Gransee/"
                   "Fürstenberg bzw. B 122 nach Rheinsberg, Ausschilderung NaturParkHaus "
                   "Stechlin folgen.",
        "startName": "NaturParkHaus Stechlin, Menz",
        "arten": ["Torfmoos", "Wollgras", "Ringelnatter", "Sumpf-Iris", "Sumpfblutauge",
                  "Kleiner Fuchs", "Knabenkraut", "Sumpfschrecke", "Distelfalter",
                  "Moosjungfer", "Schwarzerle"],
        "route": [[round(lat, 6), round(lon, 6)] for lat, lon in route],
        "stationen": stationen,
        "amenities": amenities,
    }

    out = sys.argv[1] if len(sys.argv) > 1 else "trail.json"
    with open(out, "w") as f:
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
