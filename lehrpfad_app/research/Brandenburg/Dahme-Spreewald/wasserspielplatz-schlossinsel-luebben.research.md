# Wasserspielplatz Schlossinsel Lübben – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wasserspielplatz-schlossinsel-luebben` |
| Name | Wasserspielplatz Schlossinsel Lübben |
| typ | `wasserspielplatz` |
| `form` | **`flaeche`** |
| Region | Lübben (Spreewald), Dahme-Spreewald |
| Zugang | Schlossinsel 6–22 Uhr frei, kein Ticket |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- https://www.burgimspreewald.de/de/winter/erleben/ferienangebote/ausflugstipps/artikel-schlossinsel-luebben.html
- Biosphäre (Quiz-Pfad, ohne Stationsliste): https://www.spreewald-biosphaerenreservat.de/themen/routen-touren/naturerlebnispfad-mit-wissensquiz-auf-der-schlossinsel-in-luebben/

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Wasserspielplatz (Wasserfall, Flöße, Schleusen, Bagger) | **GO** |
| Klanggarten, Labyrinth | Amenity / ggf. Tag, kein Extra-Trail |
| Naturerlebnispfad mit Wissensquiz | **MAYBE** — keine Titel+Thema |
| Minigolf, Kahnabfahrt | nicht Scope |

## Geometrie

- `form: flaeche`, `rundkurs: false`, `laengeKm: 0`
- Marker = Wasserspielbereich Schlossinsel (nicht das Schloss/Museum)

## Geräte (`kategorie: geraete`)

| Gerät | Thema |
|---|---|
| Künstlicher Wasserfall mit Rutsche | Wasser/Motorik |
| Holzflöße | Wasser |
| Wasserläufe | Rinnen |
| Schleusen | Stauen/Umleiten |
| Kleiner Bagger | Matsch/Sand am Wasser |

## Stationen (≥3)

1. Wasserfall + Rutsche  
2. Holzflöße  
3. Wasserläufe + Schleusen  
4. Bagger  

## Go / No-Go

**Go:** frei, Outdoor, ≥3 Wassergeräte.

**No-Go:** Quiz-Pfad als gleicher Seed ohne Stationstexte; OSL-Lehde verwechseln.
