# Wolfspfad Zwenzow – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wolfspfad-zwenzow` |
| Name | Wolfspfad Zwenzow |
| `typ` | `walderlebnispfad` |
| `form` | `linie` |
| Region | Zwenzow / Userin, Mecklenburgische Seenplatte, NP Müritz |
| Länge | 2 km Rundweg (OSM Rel `distance=2 km`) |
| `dauerMin` | 50 |
| `rundkurs` | true |
| `markierung` | Wolfspfad / lokale NP-Wegweisung |
| `betreiber` | Nationalparkamt Müritz |
| `website` | https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wolfspfad-zwenzow |
| `startName` | Parkplatz am Wolfsfang |
| OSM | Rel [`13685079`](https://www.openstreetmap.org/relation/13685079) · Parkplatz Node [`7861640472`](https://www.openstreetmap.org/node/7861640472) · Board [`9342668313`](https://www.openstreetmap.org/node/9342668313) · Historic Wolfsfang [`440603232`](https://www.openstreetmap.org/node/440603232) |
| BBox | 12.932–12.938 / 53.303–53.310 |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Texte (Config)

**kurzbeschreibung:** Zwei Kilometer Waldpfad bei Zwenzow – Wolfswissen zum Mitmachen, historische Fanggrube und eine Märchenhütte. Frei, ohne Ticket.

**beschreibung:** Südlich von Zwenzow, an der Straße nach Wesenberg, liegt der Wolfspfad des Müritz-Nationalparks. Auf rund zwei Kilometern erzählen die fiktiven Junior Ranger Lotta und Lars, seit wann Wölfe wieder hier leben, wo sie jagen und wie man sich ihnen gegenüber verhält. Stationen verlangen Köpfchen und Körpereinsatz: Wolfsquiz, Sprache der Wölfe, Spurenlesen. Die historische Wolfsfanggrube (1710, nach einem Schafsriss bei Userin) ist als Modell und Relikt präsent. In der Märchenhütte werden Mythen vom Wolf aufgegriffen. Ein Glöckchenspiel sitzt am Pfad. Der Outdoor-Besuch ist frei – ohne Ticket, ohne Anmeldung. Führungen (z. B. ZNL Otto Woit) sind optional und nicht Scope. Hunde im Nationalpark an der Leine. Der 5 km-Windwurf-Rundweg (Sturm Ela 2014) tangiert den Pfad, ist aber ein eigener Weg – nicht in diese Route mischen.

**anreise:** Auto: Parkplatz am Wolfsfang, Straße Zwenzow–Wesenberg, ca. 2 km südlich Zwenzow (nicht den oft vollen Parkplatz am Familotel Rookhus südlich des Pfades nutzen). ÖPNV dünn; Fahrrad von Wesenberg/Userin.

**tags:** `kinderfreundlich`, `spielplatz`, `hunde-erlaubt`

## Geometrie

Rundkurs Rel 13685079, Ways u. a. `1021974868`, `725164478`, `725164477`, `165346509`, `708605667`, `1456431365`, `1021975379`, `1021978997`, `129749992`. Start Parkplatz-Node 7861640472 (53.309104, 12.9373113) → Wolfsfang → Märchenhütte → Südschleife Wolfswissen → zurück. Nächster Schritt: OSM-Ways zu `tools/osm/wolfspfad-zwenzow_route.json` stitchen (kein naiver Rel-Stitch ohne Abgleich).

## Stationen

GPS = OSM `tourism=information` / Attraction. Reihenfolge grob Nord (Parkplatz) → West → Süd → zurück.

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| start-parkplatz | 53.3092791 | 12.9373789 | n9342668313 | Willkommen am Wolfspfad | Start am Parkplatz Wolfsfang | tafel | false | OSM Board „Wolfspfad“ |
| wolfsfang | 53.3093819 | 12.9354615 | n13063385736 / historic n440603232 | Die Wolfsfanggrube | Historische Falle von 1710 | tafel, mitmach-modell | false | OSM + NP-Text |
| verhaeltnis-wolf | 53.309292 | 12.9334639 | n13063382108 | Unser Verhältnis zum Wolf | Mythen und Angst | tafel | false | OSM Board |
| maerchenhuette | 53.3093979 | 12.9334684 | n7861589443 | Märchenhütte | Geschichten vom Wolf | tafel, quiz | false | OSM Attraction |
| wolfsspuren | 53.3083818 | 12.9330806 | n13063380141 | Wolfsspuren | Spuren lesen | tafel, bestimmung | false | OSM Board |
| woelfe-mv | 53.3078403 | 12.9329462 | n13063355120 | Wölfe in Mecklenburg-Vorpommern | Rückkehr der Art | tafel | false | OSM Board |
| wolfspirsch | 53.3076564 | 12.9330068 | n13063345240 | Auf Wolfspirsch | Verhalten verstehen | tafel, quiz | false | OSM Board |
| gloeckchenspiel | 53.3076409 | 12.9331045 | n7861619955 | Glöckchenspiel | Mitmachen | mitmach-modell | false | OSM leisure=playground |
| verstaendigung | 53.3046502 | 12.9326769 | n13063310491 | Wie verständigen sich Wölfe? | Körpersprache / Laut | tafel, quiz | false | OSM Board |
| wolfswissen | 53.3037528 | 12.932747 | n13063322912 | Wolfswissen | Quiz / Abschluss Südschleife | tafel, quiz | false | OSM Board |

**kurztexte (Config):**

- start-parkplatz: Hier beginnt der freie Rundweg. Zwei Kilometer Wald, Stationen von Lotta und Lars – ohne Ticket. Parke am nördlichen Wolfsfang-Platz, nicht am Familotel.
- wolfsfang: 1710 rissen Wölfe bei Userin Schafe. Die Leute bauten eine Fanggrube. Reste und ein Modell stehen hier. Schau in die Grube – und denk nach, warum der Wolf damals Feind war.
- verhaeltnis-wolf: Angst, Märchen, Bewunderung. Diese Tafel stellt die Beziehung Mensch–Wolf gerade. Was weißt du wirklich – und was ist Geschichte?
- maerchenhuette: In der Hütte werden Mythen vom bösen Wolf aufgegriffen. Setz dich, lies, widersprich. Draußen wartet der echte Wald, in dem heute wieder Wölfe leben.
- wolfsspuren: Trittsiegel, Losung, Riss – so wird der Wolf sichtbar, ohne dass du ihn siehst. Vergleich die Größe. Bleib auf dem Weg.
- woelfe-mv: Rudel gibt es wieder in Mecklenburg-Vorpommern, auch im Nationalpark. Die Tafel sagt, seit wann und wo. Abstand halten ist die Regel, nicht die Ausnahme.
- wolfspirsch: Köpfchen und Körpereinsatz: Wie pirscht ein Wolf? Station zum Nachmachen, nicht zum Nachjagen.
- gloeckchenspiel: Kleines Spielgerät am Pfad. Klang im Wald – und Pause für kürzere Beine.
- verstaendigung: Heulen, Mimik, Rute. Wölfe sprechen, ohne Wörter. Probier die Haltung, die die Tafel zeigt.
- wolfswissen: Südlicher Wendepunkt. Quiz und Fakten, bevor es zurück zum Parkplatz geht.

Seed kann 6–8 Stationen kuratieren (mindestens Start, Wolfsfang, Märchenhütte, Spuren, Verständigung, Wolfswissen). Alle GPS belegt.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| n7861640472 | 53.309104 | 12.9373113 | parking | Parkplatz Wolfsfang |
| n11482280654 | 53.3093091 | 12.9336596 | bench | — |
| n7861619955 | 53.3076409 | 12.9331045 | playground | Glöckchenspiel |

Kein WC am Pfad belegt – nicht erfinden. Familotel-Gastro nicht Scope.

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | Kiefernwald, Windwurf-Kontext |
| Stieleiche | in `species.json` | Mischwald |
| Rote Waldameise | in `species.json` | Waldboden |
| Igel | in `species.json` | Waldrand, Nacht |
| Wolf | **neu** fauna | Thema des Pfads; Sicht selten, Spuren/Tafeln |

## Go / No-Go

**Go:** frei, Stationen OSM-vollständig, Rel + Parkplatz, ≥3 GPS.

**No-Go:** Führungen als Pflicht; Windwurf-Rundweg in dieselbe Route; Familotel-Parkplatz als Start.

## Pipeline

1. Rel-Ways → `tools/osm/wolfspfad-zwenzow_route.json` + `_pois` / `_amenities`
2. Config `tools/trails/wolfspfad-zwenzow.json`
3. `python3 tools/build_seed.py tools/trails/wolfspfad-zwenzow.json`
4. `python3 tools/validate_seeds.py`
5. Seed in `_seedPaths`; Wolf-Species-Content nach `SPECIES_CONTENT.md`
