# Wasserspielplatz Seglerhafen Röbel – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wasserspielplatz-roebel` |
| Name | Wasserspielplatz Seglerhafen Röbel |
| `typ` | `wasserspielplatz` |
| `form` | **`flaeche`** |
| Region | Röbel/Müritz, Mecklenburgische Seenplatte |
| `laengeKm` | 0 |
| `dauerMin` | 40 |
| `rundkurs` | false |
| `markierung` | — (Platz, keine Wegmarke) |
| `betreiber` | Stadt Röbel / Röbeler Segler-Verein Müritz e. V. (Marina-Gelände) |
| `website` | https://www.mecklenburgische-seenplatte.de/reiseziele/wasserspielplatz-am-seglerhafen |
| `startName` | Wasserspielplatz am Seglerhafen |
| Adresse | Müritzpromenade, 17207 Röbel/Müritz |
| OSM | Playground [`56449511`](https://www.openstreetmap.org/way/56449511) (~53.38655, 12.61612) · Playground [`1353974444`](https://www.openstreetmap.org/way/1353974444) (~53.3889, 12.6155) · Infotafel [`3839884042`](https://www.openstreetmap.org/node/3839884042) |
| BBox | 12.615–12.619 / 53.386–53.389 |

Kein Museumsticket (anders als Müritzeum). Marina-Website: Kinderspielplatz und Spielwiese am Hafen. Destinationsportale: **Wasserpumpe und Wasserhindernisse** → Charakter-GO.

Zweiter OSM-Playground nördlich: beim Seed prüfen, welcher der Wasserbereich ist; der andere höchstens Amenity, nicht zweiter Trail.

## Texte (Config)

**kurzbeschreibung:** Kleiner Wasserspielplatz am Röbeler Seglerhafen – Pumpe, Hindernisse, Müritz daneben. Frei, ohne Ticket.

**beschreibung:** Am Westufer der Müritz, an der Müritzpromenade, liegt ein kleiner Wasserspielplatz mit Pumpe und Wasserhindernissen. Öffentlich, kein Eintritt, kein Müritzeum. Wechselkleidung sinnvoll. Der Platz ist kein Waldlehrpfad und kein Stadt-Standardset allein: das hydrologische Spiel (Pumpe, stauen, Hindernisse) trägt den Ort – analog Wittstock, nur kleiner. Marina-Gastro, WC und Wohnmobilstellplatz gehören zum Hafenbetrieb (Öffnung/Nutzung können saisonal sein); Spontan-Wasserplatz ist das Outdoor-Spiel. Hunde: typisch Spielplatz-Verbot oder Leine – vor Ort; Tag `hunde-erlaubt` nur setzen wenn belegt.

**anreise:** Adresse: Müritzpromenade, 17207 Röbel/Müritz. Auto: Marina Röbel, Parkplätze OSM w217310420, w380664363. Fuß/Rad: 5–10 min vom Stadtzentrum Röbel die Promenade entlang nach Norden zum Seglerhafen (nicht Marktplatz-Spielplatz). Hausnummer 20/20a = Marina, nicht der Spielplatz.

**tags:** `kinderfreundlich`, `spielplatz`

## Geometrie

`form: flaeche`, `area[]` = Ring um Way 56449511 (10 Nodes, Mid 53.3866395, 12.6160832). `laengeKm: 0`, kein Fake-Rundkurs. Marker = Centroid. Zweiten Playground 1353974444 nur einbeziehen, wenn Vor-Ort Wassergeräte dort liegen – sonst weglassen.

Vorschlag Polygon (aus Way-first/mid, beim Seed volle Nodes ziehen):

```
[53.38646, 12.61616], [53.38664, 12.61608], [53.38670, 12.61620], [53.38650, 12.61628], [53.38646, 12.61616]
```

Fein-Nodes: OSM API way 56449511 full.

## Stationen (≥3, Fläche)

Geräte analog Wittstock – keine Schaukel-Steckbriefe.

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| pumpe | 53.38655 | 12.61610 | w56449511 | Wasserpumpe | Muskelkraft, Fließen | mitmach-modell | false | Destinationsportal; Position im Polygon *redaktionell* |
| hindernisse | 53.38662 | 12.61614 | w56449511 | Wasserhindernisse | Stauen, Umleiten | mitmach-modell | false | Destinationsportal; Offset im Polygon *redaktionell* |
| ufer-mueritz | 53.3870663 | 12.6180106 | n3839884042 | Müritz am Hafen | See als Wasserquelle | tafel | false | OSM Infotafel |

**kurztexte:**

- pumpe: Ohne Pumpen kein Bach. Hier entsteht der Fluss mit Armkraft – wie am Wittstocker Matschtisch, nur am großen See.
- hindernisse: Wehre im Kleinen. Stau setzen, umleiten, zuschauen wie das Wasser den Weg sucht.
- ufer-mueritz: Hinter dem Platz die Müritz. Dieselbe Physik, anderer Maßstab. Infotafel am Hafen, nicht ins Wasser.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w217310420 / w380664363 | ~53.387 | ~12.618 | parking | Marina |
| n4090312313 | 53.3880339 | 12.6179022 | wc | Marina (Hafenbetrieb, Öffnung prüfen) |
| w56449511 | 53.38655 | 12.61612 | playground | Wasserspiel (dieser Ort) |

Gastro am Hafen/Regattahaus: nur `gastro` wenn OSM-Name und öffentlich ohne Liegeplatzpflicht – beim Seed prüfen, sonst weglassen.

## Arten / Geräte

| nameDe | Status | vor Ort |
|---|---|---|
| Libelle | in `species.json` | Ufer, Sommer |
| Eisvogel | in `species.json` | Hafen/Ufer, Glück |
| Wasserpumpe | **neu** `geraete` | Kernangebot; ggf. Alias zu bestehendem Pumpen-Gerät wenn Seed Wittstock-Pumpe thematisch teilt – **nicht** zwingend neue ID wenn `wasser-matschtisch-pumpe` zu spezifisch Matschtisch ist → eigene `hafen-wasserpumpe` |
| Wasserhindernisse | **neu** `geraete` | Stau/Parcours |

Nicht als `geraete`: Schaukel, Rutsche, Sandkasten.

## Go / No-Go

**Go:** öffentlich, Pumpe+Hindernisse dokumentiert, Fläche ohne Ticket.

**No-Go:** Müritzeum-Garten; Stadtspielplatz Markt/Promenade ohne Wasser; Marina-Spielwiese nur DIN-Geräte (dann Charakter kippt – Vor-Ort-Check beim Seed).

## Pipeline

Flächen-Seed direkt `assets/seed/wasserspielplatz-roebel.json` (wie Wittstock), kein `build_seed`-Stitch. `area[]` aus Way 56449511. Validator `form=flaeche`.
