# Naturlehrpfad am Planfließ – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `planfliess` |
| Name | Naturlehrpfad am Planfließ |
| typ | `wald` |
| Region | Schlaubetal OT Bremsdorf, Oder-Spree |
| Länge | 5,5 km Rundweg (Naturpark / Reiseland) |
| Start | Parkplatz Jugendherberge Bremsdorfer Mühle; erste Schautafel hinter Bushaltestelle am Schlaubetal-Wanderweg |
| Markierung | diagonale braune Linie auf weißem Quadrat |
| Koordinaten-Anker | ≈ 52.1363, 14.4635 (Outdooractive Parkplatz) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

Nicht: Heidelehrpfad Rel `19906514` (DROP); Schlaubetal-Fernwanderweg als eigener Seed.

## Quellen

- Naturpark Schlaubetal: https://www.schlaubetal-naturpark.de/themen/routen-touren/naturlehrpfad-am-planfliess/
- Reiseland BB: https://www.reiseland-brandenburg.de/poi/seenland-oder-spree/wandertouren/planfliess-rundwanderweg/
- Natur Brandenburg (gleiche Texte): https://www.natur-brandenburg.de/themen/routen-touren/naturlehrpfad-am-planfliess/

Lehrpfad Mai 2017 von der Naturparkverwaltung erneuert. **11 Thementafeln.**

## Stationsthemen (Naturpark-Text, ≥3)

Einzelne Tafel-Titel nicht nummeriert; Themen aus der Betreiberseite, für Config entlang der Route zu verorten (Feldcapture/GPX):

1. Pferdeplan — Namensgebung (ehem. Pferdewaldweide)
2. Eisenhaltige Quellen — rostrot, Geschmack
3. Mäander / Altarme / Feuchtgebiete — 40 m Gefälle auf 6 km
4. Kloster Neuzelle — Wassernetz, Fischteiche, Fasten (Biber/Sumpfschildkröte als „Fisch“)
5. Schneidemühle (im 30-jährigen Krieg zerstört)
6. Heutige Teich-Regulation / Rote-Liste-Arten
7. Bachflohkrebse, Eisvogel
8. Orchideenwiese / Knabenkraut an der Schutzhütte
9. Otter, Biber
10. Großer Treppelsee / Mündung
11. (11. Tafel vor Ort — Titel im Feld)

Abstecher Findling Treppelstein (Outdooractive) = Amenity, kein Muss-Station.

## Arten

Eisvogel, Biber, Fischotter, Bachflohkrebs, Knabenkraut; Sumpfschildkröte historisch.

## Go / No-Go

**Go:** frei, Outdoor, 11 Tafeln vom Naturpark, Themen ≥3 aus Erstquelle.

**No-Go:** Schlaubetal-Etappen Kupferhammer/Schlaubemühle als Route; Heidelehrpfad.

## Pipeline

1. GPX/OSM entlang Markierung → `tools/osm/planfliess_route.json`
2. Tafeln vor Ort oder aus Naturpark-Material mappen
3. Config `tools/trails/planfliess.json`
4. `python3 tools/build_seed.py` → `validate_seeds.py`
5. Seed + STATUS HAVE
