# Harzungspfad Stolpe – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `harzungspfad` |
| Name | Harzungspfad Stolpe |
| Status | **HAVE** – Seed `assets/seed/harzungspfad.json` |
| `typ` / `form` | `walderlebnispfad` / `linie` |
| Region | Stolpe / Hohen Neuendorf, Oberhavel (Revier Berliner Forsten) |
| Länge | OSM-Way [`61318864`](https://www.openstreetmap.org/way/61318864) ~0,2 km Rundweg (Forst: ca. 300 m) |
| OSM | Arbeitsschritt-Nodes [`7999807807`](https://www.openstreetmap.org/node/7999807807)–[`7999807814`](https://www.openstreetmap.org/node/7999807814); Wetterpilz Baumharz [`765936648`](https://www.openstreetmap.org/node/765936648) |
| Anker | ≈ 52.6621, 13.2472 (Stolper Waldstraße, hinter Revierförsterei) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Berliner Forsten (Pfad): https://www.berlin.de/forsten/waldbildung/waldlehrpfade/harzungspfad/
- Berliner Forsten (Wanderung NW03): https://www.berlin.de/forsten/walderlebnis/ausflugstipps/nordwesten/wanderung-zum-harzungspfad-869390.php
- Revier Stolpe: https://www.berlin.de/forsten/ueber-uns/forstaemter-und-reviere/forstamt-tegel/stolpe/
- OSM-Tafeln (Namen = Stationstitel)

Führungen optional (Revierförsterin Alina Dunkel). Pfad selbst ohne Anmeldung.

## Stationen (OSM, ≥3)

Acht Arbeitsschritte am Baum. Seed-Reihenfolge entlang des OSM-Wegs (pädagogisch: Röten vor Tropfrinne):

1. Vorarbeiten — Node 7999807807 (52.66191, 13.24685)
2. Röten — 7999807809 (52.66203, 13.24667)
3. Ziehen der Tropfrinne — 7999807808 (52.66221, 13.24649)
4. Topfhalter und Topf — 7999807810 (52.66221, 13.24675)
5. Reißen — 7999807811 (52.66218, 13.24703)
6. Stimulationsharzung — 7999807812 (52.66208, 13.24722)
7. Schöpfen — 7999807813 (52.66198, 13.24730)
8. Transport — 7999807814 (52.66182, 13.24726)

Zusatztafeln (nicht Pflicht für Go-Bar): Baumharz, Blick in den Waldboden, Die Vogeluhr, Der Baum ein Baum. QR-Videos an den Infotafeln.

Themen laut Forst: Lachten, Terpentin-Balsam, Baumauswahl, Nutzung/Folgeprodukte.

## Arten

Waldkiefer (Harzlachten); weitere Arten erst aus Tafeltexten/Videos kuratieren.

## Go / No-Go

**Go:** Outdoor frei & spontan; 8 benannte OSM-Stationen mit GPS.

**No-Go:** Führungen als Pflicht; 10-km-Wanderung Hohen Neuendorf→Hennigsdorf als Route (nur Anreise-Tipp).

## Pipeline

HAVE: Config `tools/trails/harzungspfad.json` → `python3 tools/build_seed.py` → `assets/seed/harzungspfad.json`. OSM: `tools/osm/harzungspfad_{route,pois,amenities,way}.json`. In `_seedPaths`.
