# Fledermauspfad Bossow – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `fledermauspfad-bossow` |
| Name | Fledermauspfad Bossow |
| `typ` | `walderlebnispfad` |
| `form` | `linie` |
| Region | Bossow, Krakow am See, Naturpark Nossentiner/Schwinzer Heide |
| Länge | 1,3 km (befestigte Wege, ehem. Militärgelände) |
| `dauerMin` | 45 |
| `rundkurs` | true |
| `markierung` | Fledermauspfad / Stationstafeln |
| `betreiber` | Naturpark Nossentiner/Schwinzer Heide |
| `website` | https://www.naturpark-nossentiner-schwinzer-heide.de/fledermaus-lehrpfad |
| `startName` | Parkplatz / Kartentafel an der Straße Bossow–Schwinz |
| OSM | Attraction Way [`1297781141`](https://www.openstreetmap.org/way/1297781141) · Parking [`1297781127`](https://www.openstreetmap.org/way/1297781127) · Map-Board [`12023732700`](https://www.openstreetmap.org/node/12023732700) · Board Lichtverschmutzung [`12023732699`](https://www.openstreetmap.org/node/12023732699) |
| BBox | 12.226–12.233 / 53.607–53.611 |

Bunker-Winterquartier (~600 Tiere): **nur Führung**. Outdoor-Pfad laut Sternenpark „jederzeit besuchbar“, ausgewählte Stationen ohne Guide.

## Texte (Config)

**kurzbeschreibung:** 1,3 km Lehrpfad auf dem ehemaligen Militärgelände Bossow – Fledermäuse verstehen, auch ohne Führung. Bunker extra.

**beschreibung:** Auf befestigten Wegen zwischen alten Bunkern stehen 12 interaktive Stationen: Orientierung im Dunkeln, Gedränge im Kasten, Schall und Tonhöhe. Der Outdoor-Pfad ist frei und ohne Anmeldung nutzbar. Volle Interaktivität und Blick ins Winterquartier nur mit gebuchter Führung (Naturpark / ZNL Andreas Breuer) – das ist nicht Scope, analog Hainholz-Außenraum. Daneben Sternenbeobachtungsplatz und Tafel Lichtverschmutzung (Sternenpark). ELER-gefördert. Hunde: Gelände militärisch/naturnah, Leine sinnvoll; Regel vor Ort beachten.

**anreise:** Bossow, Straße nach Schwinz, ca. 400 m nach Bahnübergang links (Naturpark-QR). Parkplatz Way 1297781127 (~53.61083, 12.23211).

**tags:** `kinderfreundlich`, `hunde-erlaubt`

## Geometrie

Attraction-Way 1297781141 umreißt das Gelände (first 53.61082, 12.23259 → mid 53.60711, 12.22650). Keine Hiking-Relation gefunden. Route: Parkplatz → Map-Tafel → Lichtverschmutzung → Schleife auf befestigten Wegen entlang des Attraction-Polygons, zurück zum Parkplatz. `rundkurs: true`, Länge 1,3 km. Feldcapture für exakte Path-Ways empfohlen; Seed-Route entlang OSM-highway im Polygon.

## Stationen

Nur 2 OSM-Tafeln namentlich. Weitere ≥1 redaktionell auf der dokumentierten Schleife (Themen aus Betreibertext, nicht als Fake-OSM-IDs).

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| start-karte | 53.6100875 | 12.2315048 | n12023732700 | Stationen auf dem Fledermauspfad | Übersicht 12 Stationen | tafel | false | OSM map |
| lichtverschmutzung | 53.6098888 | 12.2307353 | n12023732699 | Die Lichtverschmutzung | Nacht, Sterne, Fledermaus | tafel | false | OSM Board |
| dunkel-orientierung | 53.60863 | 12.23066 | — | Orientierung im Dunkeln | Echoortung nachfühlen | tafel, mitmach-modell | false | redaktionell; Betreiber: „Wie fühlt es sich an, sich im Dunkeln zu orientieren?“ Zentrum Attraction-Way |
| gedraenge | 53.6080 | 12.2285 | — | Dicht an dicht | Winterquartier-Metapher | tafel, mitmach-modell | false | redaktionell; Betreiber: Kasten-hängen; *nicht* Bunker-Innen |
| schall | 53.6092 | 12.2295 | — | Schall und Tonhöhe | Reichweite | tafel, quiz | false | redaktionell; Betreiber |

GPS der drei redaktionellen Punkte beim Seed auf die tatsächliche Path-Geometrie ziehen (Dijkstra im Polygon). Nicht als OSM-Wahrheit verkaufen.

**kurztexte:**

- start-karte: Parken, Karte der 12 Stationen. Draußen kannst du mehrere mitnehmen – den Bunker nur mit Führung.
- lichtverschmutzung: Nacht wird hell, Fledermäuse verlieren Insektenstraßen. Der Sternenpark fängt hier thematisch an.
- dunkel-orientierung: Augen zu, Ohren auf. Die Station spielt Echoortung nach, ohne dass du eine Fledermaus brauchst.
- gedraenge: Im Winter hängen sie eng. Die Outdoor-Station zeigt das Prinzip – das Quartier selbst bleibt zu.
- schall: Hohe Töne tragen anders. Quiz am Kasten, dann weiter auf dem befestigten Weg.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w1297781127 | 53.61083 | 12.23211 | parking | Fledermauspfad |
| n12023732697 | 53.6098758 | 12.2307618 | bench | — |
| n12023732698 | 53.6098649 | 12.230803 | bench | — |

WC nicht belegt. Tower n5766309552 ohne Freigabe als Aussicht – nicht als Amenity `viewpoint` ohne Tag.

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | Wald um Bunker |
| Igel | in `species.json` | Nacht, Geländerand |
| Hummel | in `species.json` | Tag, Blütenrand |
| Fledermaus | **neu** fauna | Thema; Artenmix im Quartier, Outdoor über Stationen |

Keine `geraete`-Bunker-Innenausstattung.

## Go / No-Go

**Go:** Outdoor frei (Sternenpark + Naturpark); ≥3 Stationen (2 OSM + redaktionell aus Betreibertext).

**No-Go:** Führungspflicht; Bunkerinnenraum; „12 Stationen“ als GPS erfinden.

## Pipeline

1. Highway im Attraction-Polygon → `tools/osm/fledermauspfad-bossow_route.json`
2. Config `tools/trails/fledermauspfad-bossow.json`
3. `build_seed.py` → validate; Fledermaus-Species-Content beim Seed
