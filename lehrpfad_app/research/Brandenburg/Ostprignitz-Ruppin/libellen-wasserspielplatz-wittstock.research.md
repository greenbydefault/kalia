# Libellen-Wasserspielplatz Wittstock – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `libellen-wasserspielplatz-wittstock` |
| Name | Wasserspielplatz Wittstock (Libellen) |
| `typ` | `wasserspielplatz` |
| `form` | **`flaeche`** (kein Fake-Rundkurs) |
| Region | Wittstock/Dosse, Ostprignitz-Ruppin |
| Adresse / Anker | Friedrich-Ebert-Park / Glinzmauer / Kyritzer Straße, 16909 Wittstock/Dosse |
| Zugang | freizügängig, LaGa-Folgefläche |
| Status | **HAVE** – Seed `assets/seed/libellen-wasserspielplatz-wittstock.json` |

## Filter / Abgrenzung

Charakter-Regel: [`README.md`](../../../README.md). Kreis: [`_kandidaten.md`](_kandidaten.md).

| Ort | Einstufung |
|---|---|
| Wasserspielplatz Glinze (Quellsteine, Rinne, Wehre, Matschtisch, Libellen) | **GO** / HAVE |
| Spielplatz Am Kyritzer Tor / Park am Bleichwall | **NOGO** — anderer Ort, falscher Nav-Anker |
| Biber-Spielplatz (Park am Bleichwall / Amtshof) | **NOGO** — Stadtspielplatz-Charakter |

Nicht als `geraete`: Schaukel, Standard-Rutsche, Federwippe, Sandkasten allein.

## Geometrie

- `form: flaeche`, `area[]` = OSM-Way 98447026 (Glinze-/FEP-Spielplatz, grenzt an den Wasserspielbereich)
- `rundkurs: false`, `laengeKm: 0`
- Marker = Centroid der Area (~53.16019, 12.48391)
- Keine `route[]`
- Nicht Way 1262139861 (Biber-Spielplatz am Bleichwall)

## Geräte (`kategorie: geraete`)

| Species-`id` | nameDe |
|---|---|
| `quellsteine-wasserdueisen` | Quellsteine mit Wasserdüsen |
| `gepflasterte-wasserrinne` | Gepflasterte Wasserrinne |
| `stauehre-wehr` | Wehre und Stauelemente |
| `wasser-matschtisch-pumpe` | Wasser- und Matschtisch mit Pumpe |
| `libellen-installation` | Libellen-Installation |

## Arten (Fauna)

| Species | Rolle |
|---|---|
| Libelle | thematisch (Feuchtgebiet / Installation) |
| Biber | Glinze/Dosse — **nicht** Biber-Spielplatz |

## Stationen (≥3)

1. Quellsteine  
2. Rinne und Wehre  
3. Matschtisch mit Pumpe  
4. Libellen-Installation  

## Quellen

- User-Korrektur: Nav/Koordinaten lagen am Bleichwall / Kyritzer Tor, 2026-08
- Playground@Landscape 4/2019 (Wasserspiel = Ergänzung Glinzespielplatz, FEP)
- KUULA: Wasserspielbereich an der Glinze
- Stadt Wittstock (Libellen am Wasserspielplatz)
- Reiseland Brandenburg (Friedrich-Ebert-Park)
- OSM Way 98447026

## Pipeline

Seed liegt direkt unter `assets/seed/…` (Fläche, kein `build_seed`-Routen-Stitch). Eintrag in `SeedTrailRepository._seedPaths`. Validator: `form=flaeche`.
