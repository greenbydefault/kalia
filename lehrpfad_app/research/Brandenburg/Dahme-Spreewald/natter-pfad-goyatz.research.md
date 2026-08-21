# Natter-Pfad Goyatz – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `natter-pfad-goyatz` |
| Name | Naturlehr- und Erlebnispfad Natter-Pfad |
| Status | **HAVE** – Seed `assets/seed/natter-pfad-goyatz.json` |
| `typ` / `form` | `walderlebnispfad` / `linie` |
| Region | Goyatz / Schwielochsee, Dahme-Spreewald |
| Länge | OSM-Rel [`4082598`](https://www.openstreetmap.org/relation/4082598) 2,1 km Rundweg (`alt_name=Natterpfad`) |
| Start | Tafel Naturlehrpfad Node [`2975055277`](https://www.openstreetmap.org/node/2975055277); Bahnhof Am Bahnhof 27 ca. 150 m nordwestlich |
| Zugang | frei, ohne Anmeldung |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Natter-Pfad 2 km Familie | **GO** |
| Reh / Biber / Otter / Kranich / Wildnis (bis 8 km, Gesamt ~32 km) | nicht in diesem Seed; eigene MAYBE |
| Museum Bahnwagon | Indoor |
| Leichhardt-Hütte Events | Buchung |
| Radweg Ludwig Leichhardt Trail | anderer Weg |

## Geometrie

- Rel 4082598: `roundtrip=yes`, 15 Ways, nur die Natter-Schleife (keine Reh-Members)
- Roh: [`tools/osm/natter-pfad-goyatz_{rel,pois,amenities}.json`](../../../tools/osm/natter-pfad-goyatz_rel.json)
- StartAm Node 2975055277; Richtung `[2975055277, 3129486544]` (Ostseite / Wiesen zuerst)
- Markierung: Schlangensymbol / grüne Schilder (OSM `alt_symbol`)

## Stationen (≥3)

1. Spreewaldbahnhof Goyatz — Node 2975055277 (52.01068, 14.18325), Tafel `Naturlehrpfad`
2. Feuchtwiesen — Board [`3129486544`](https://www.openstreetmap.org/node/3129486544) (52.00737, 14.18618); Tafeln/Exponate Kriechtiere, Amphibien, Insekten
3. Holzbank an der Orchideenwiese — Bench [`3108319131`](https://www.openstreetmap.org/node/3108319131) (52.00709, 14.18650)
4. Stamm in Ringelnatter-Form — Landschaftsanker auf der Rel-Geometrie (52.00614, 14.18658); kein OSM-Exponat-Node
5. Hecken am Weg — Rel-Punkt (52.00500, 14.18578); Betreiber nennt Heckenrose, Liguster, Traubenkirsche, Salweide, Haselnuss

Abzweig Rehpfad (südlichster Guidepost [`3108319829`](https://www.openstreetmap.org/node/3108319829)) nicht als Station.

## Arten

`Ringelnatter` (Katalog). Neu `Heckenrose`, `Haselnuss` — Betreiber listet beide in der Hecke. Liguster / Traubenkirsche / Salweide nicht extra. `Knabenkraut` nicht geseedet (Orchideenwiese nur Blick, kein Artname).

## Quellen

- https://www.naturwelt-lieberose.de/highlights/naturlehrpfad-ludwig-leichhardt
- https://www.reiseland-brandenburg.de/poi/spreewald/wandertouren/naturlehr-und-erlebnispfad-natter-pfad/
- https://teg-lds.de/de/urlaub-im-leichhardt-land/naturlehrpfad-ludwig-leichhardt.html
- OSM Rel 4082598

## Pipeline

HAVE: Config `tools/trails/natter-pfad-goyatz.json` → `python3 tools/build_seed.py` → `assets/seed/natter-pfad-goyatz.json`. OSM: `tools/osm/natter-pfad-goyatz_{rel,pois,amenities}.json`. In `_seedPaths`.
