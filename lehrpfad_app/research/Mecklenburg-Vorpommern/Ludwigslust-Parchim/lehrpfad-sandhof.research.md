# Naturlehrpfad Sandhof – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `lehrpfad-sandhof` |
| Name | Naturlehrpfad Sandhof |
| `typ` | `wald` |
| `form` | `linie` |
| Region | Sandhof / Wooster-Teerofen, Ludwigslust-Parchim, Naturpark Nossentiner/Schwinzer Heide |
| Länge | ca. 8,1 km |
| `dauerMin` | 180 |
| `rundkurs` | true |
| `markierung` | Lehrpfad Sandhof / beschilderte Wanderwege (Paschensee-Runde ist Teil) |
| `betreiber` | Forstamt Sandhof / Naturpark Nossentiner/Schwinzer Heide |
| `website` | https://www.wald-mv.de/static/WALDMV/Inhalte/Landesforst%20MV/Struktur%20und%20Organisation/Forst%C3%A4mter/Sandhof/Waldbesucher%20Sandhof.pdf |
| `startName` | Pavillon auf dem Festplatz Sandhof |
| OSM | Dorf [`573598742`](https://www.openstreetmap.org/node/573598742) · Turm Rothirsch [`142267923`](https://www.openstreetmap.org/way/142267923) · Paschensee [`149614824`](https://www.openstreetmap.org/way/149614824) · Wooster-Teerofen [`1027920040`](https://www.openstreetmap.org/node/1027920040) |
| BBox | 12.186–12.232 / 53.573–53.588 |

Keine Hiking-Relation unter dem Namen gefunden. Stationenliste Forst MV / Ferienwohnung-Sandhof (identischer Stationstext).

## Texte (Config)

**kurzbeschreibung:** Acht Kilometer durch Heidewälder und an Klarwasserseen – Lehrpfad ab Festplatz Sandhof bis zum Aussichtsturm Rothirsch. Frei.

**beschreibung:** Ausgangspunkt ist der Pavillon auf dem Festplatz in Sandhof (Abzweig B 192 zwischen Goldberg und Karow). Beschilderte Stationen: Westufer Damerower See, Westufer Paschensee (eigene Seenrunde ist Teil des Lehrpfads), Wooster Teerofen, Moor und Westufer Langhagensee, NSG Kieferndünen-Wacholderwald, Park Sandhof mit fast 100 Baum- und Straucharten, Aussichtsturm Rothirsch am Großen Serrahn (NSG – nicht verwechseln mit Serrahn im Müritz-NP). Seeadler und Fischadler sind Park-Charakterarten. Heimatstube im Dorfgemeinschaftshaus optional, nicht Scope. Frei, Outdoor. Lang für kleine Kinder – als Ganztag oder Teilstrecke Paschensee planen.

**anreise:** Auto: B 192 Goldberg–Karow, Abzweig Sandhof. Dorf ~53.5733, 12.1933. Parken am Festplatz/Dorf (OSM parking w285091915 bei 53.57x, 12.19x prüfen beim Stitch). ÖPNV dünn.

**tags:** `kinderfreundlich`, `picknick`, `hunde-erlaubt`

## Geometrie

Kuratierte Runde in der Reihenfolge der Stationenliste, OSM-Tracks um Paschensee + Verbindung Sandhof–Rothirsch. Start Festplatz (redaktionell am Dorfkern / Shelter n3041976483 53.5744344, 12.1947004). Nächster Schritt: Overpass highway um Seen + Turm, Dijkstra.

## Stationen

Koordinaten: OSM wo vorhanden, sonst *redaktionell am benannten Ort*.

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| festplatz | 53.5744344 | 12.1947004 | n3041976483 / n3041976490 | Pavillon Festplatz | Start Lehrpfad | tafel | false | Shelter + information Node; Forst-PDF |
| park-sandhof | 53.57330 | 12.19326 | n573598742 | Park Sandhof | ~100 Gehölzarten | tafel, bestimmung | false | Dorf-Node; Park im Ort |
| turm-rothirsch | 53.5743305 | 12.1866557 | w142267923 | Aussichtsturm Rothirsch | NSG Großer Serrahn, Adler | tafel | false | OSM tower |
| paschensee | 53.58549 | 12.23181 | w149614824 | Westufer Paschensee | Klarwassersee | tafel | false | OSM See-Zentrum → beim Seed an Westufer-Weg schieben |
| teerofen | 53.5876949 | 12.2142194 | n1027920040 | Wooster Teerofen | Waldgeschichte, Teer | tafel | false | OSM village |
| damerow | 53.575 | 12.210 | — | Westufer Damerower See | See / Adler | tafel | false | redaktionell; See östlich Sandhof |
| langhagen-moor | 53.580 | 12.200 | — | Moor am Langhagensee | Moor, Ufer | tafel, steg | false | redaktionell; Literatur. Steg nur setzen wenn OSM/Feld `steg` bestätigt – sonst `tafel` |
| duenen | 53.578 | 12.195 | n5423541033 | Kieferndünen und Wacholder | NSG | tafel, bestimmung | false | OSM unnamed board 53.5784532, 12.1979495 als Anker *prüfen* |

Seed-Minimum mit hartem GPS: festplatz, park-sandhof, turm-rothirsch, teerofen, paschensee (Uferpunkt auf Route). Damerow/Moor/Dünen nachziehen wenn Ways da sind.

**kurztexte:**

- festplatz: Pavillon, Dorf, Start. Acht Kilometer sind eine Ansage – Teilstrecke Paschensee ist erlaubt.
- park-sandhof: Arboretum im Kleinen: fast 100 Arten. Schilder lesen, Blätter vergleichen.
- turm-rothirsch: Blick ins NSG Großer Serrahn (Heide, nicht NP-Serrahn). Adler kreisen lassen, nicht rufen.
- paschensee: Klarwasser, Wald bis ans Ufer. Die Seenrunde ist offiziell Teil des Lehrpfads.
- teerofen: Ortsname ist Arbeitsname. Waldglas und Teer brauchen Holz – die Heide erinnert daran.
- damerow: Westufer, weites Wasser. Mit Glück Adler, ohne Glück trotzdem Wind.
- langhagen-moor: Nasse Senke, Moorarten. Weg bleiben, der Rand trägt nicht.
- duenen: Sand, Kiefer, Wacholder. Trockeninsel im Seenland.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w285091915 | — | — | parking | Sandhof |
| n3041976481 | 53.5750007 | 12.1962709 | wc | Sandhof |
| n3041976483 | 53.5744344 | 12.1947004 | shelter | Festplatz |
| n3041976462 | 53.5751607 | 12.1964653 | playground | Dorf (Amenity) |
| w142267923 | 53.57433 | 12.18666 | viewpoint | Aussichtsturm Rothirsch |

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | Dünen, Forst |
| Stieleiche | in `species.json` | Park |
| Fischotter | in `species.json` | Seen/Ufer, Spuren |
| Kranich | in `species.json` | Moor/Ufer |
| Libelle | in `species.json` | Ufer |
| Seeadler | **neu** fauna | Park-Wappenvogel, Turm |
| Fischadler | **neu** fauna | Seen |
| Wacholder | **neu** flora | NSG Kieferndünen |

## Go / No-Go

**Go:** frei, Stationenliste Forst, Turm+Dorf OSM.

**No-Go:** 8 km als Kinder-Pflicht; Wisentgehege Damerower Werder (Zucht, nicht dieser Pfad).

## Pipeline

1. OSM-Ways Paschensee + Sandhof–Turm → `tools/osm/lehrpfad-sandhof_route.json` (kuratiert)
2. Config `tools/trails/lehrpfad-sandhof.json`
3. `build_seed.py` → validate; Uferpunkte auf Polyline snappen
