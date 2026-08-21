# Wasserspielplatz Eliaspark Cottbus – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wasserspielplatz-eliaspark` |
| Name | Wasserspielplatz Eliaspark |
| `typ` | `wasserspielplatz` |
| `form` | **`flaeche`** (kein Fake-Rundkurs) |
| Region | Cottbus (kreisfrei), Eliaspark |
| Adresse / Anker | Am Eliaspark, 03042 Cottbus |
| Zugang | frei, ohne Ticket; Wasser Mai–Sep; Gelände laut Tourismus 24/7 im Sommer, Quellen-Intervalle 9:30–17 Uhr |
| Status | **OPEN** – noch kein Seed |

## Filter / Abgrenzung

Charakter-Regel: [`README.md`](../../../README.md). Kreis: [`_kandidaten.md`](_kandidaten.md).

Analog Wittstock: Wassergeräte + Thema, nicht Standard-Stadtspielplatz.

| Ort | Einstufung |
|---|---|
| Wasserspielplatz (Quellen, Kanäle, Wehre) | **GO** |
| Spreeauenpark / Tertiärwald | **NOGO** — 1 € Ticket |
| Naturerlebnispfad bis Tierpark | **MAYBE** — keine Stationen, Zoo-Ende, Ticket-Park |
| Branitz inklusiver Spielplatz | **NOGO** — Stadtspielplatz |
| Spielhaus Eliaspark | Amenity / Treff, kein Trail |

Nicht als `geraete`: Schaukel, Standard-Rutsche allein.

## Geometrie

- `form: flaeche`, `area[]` um den Wasserspielbereich
- `rundkurs: false`, `laengeKm: 0`
- Marker = Centroid
- Keine `route[]`

## Geräte (`kategorie: geraete`)

| Species-`id` (Vorschlag) | nameDe |
|---|---|
| `quellen-der-spree` | Drei Quellen der Spree |
| `spreelauf-kanaele` | Künstlicher Spreelauf / Kanäle |
| `stauehre-wehr` | Wehre |
| `kletterfelsen-eliaspark` | Kletterfelsen (Aug 2026 zwei Felsen zu — vor Seed prüfen) |

## Stationen (≥3)

1. Drei Quellen der Spree  
2. Kanäle / künstlicher Spreelauf  
3. Wehre  
4. Kletterfelsen (optional, wenn wieder offen)

Thema: „Die Spree – von der Quelle zur Mündung“ (Heimat / Lausitz).

## Quellen

- CMT Cottbus, Saisonstart 6. Juni 2026: https://cottbus-tourismus.de/de/sommer/cottbus-fuer-familien/freizeit-und-kultur/artikel-wasserspielplatz-im-eliaspark.html
- Brandenburg Tourism (frei Mai–Sep, drei Quellen, Wehre): https://www.brandenburg-tourism.com/poi/spreewald/lidos-and-outdoor-pools/aquatic-playground-in-eliaspark/
- Eliaspark (Stiftung 1902, BuGa 1995, öffentlich): https://cottbus.de/kultur-und-tourismus/parke/elias-park/

## Pipeline

Wie Wittstock: Seed direkt `assets/seed/…` (`form=flaeche`), kein Routen-Stitch. Area vor Ort/OSM-Playground-Polygon. Nicht in diesem Sweep.
