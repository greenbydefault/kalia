# Eichwerder Moorwiesen (BB-Stege) – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `eichwerder-moorwiesen` |
| Name | Moorlehrpfad Eichwerder Moorwiesen |
| `typ` | `moor` |
| `form` | `linie` |
| Region | Glienicke/Nordbahn / Schildow, Oberhavel, Naturpark Barnim |
| Start | Alte Schildower Straße ↔ Eichwerder ↔ Jungbornstraße (zwei Stege, ehemaliger Mauerverlauf) |
| Zugang | frei & spontan |
| Status | **OPEN** – kein Seed in dieser Runde |
| OSM | Hiking-Rel fehlt — Stege vor Seed Overpass Glienicke/Schildow (~52.63, 13.33). **Nicht** den Berliner Eichwerder-Steg (Lübars) mitziehen |

Quelle: [`_kandidaten.md`](_kandidaten.md). Querschnitt: [`../_kalkmoore.md`](../_kalkmoore.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Zwei LIFE-Moorstege + Plattformen + Lehrtafeln (BB) | **GO** |
| Berliner Eichwerder-Steg (NABU, ~50 Tafeln) | **Berlin-Reinickendorf**, eigener Trail |
| Ranger-/Naturwacht-Touren um die Moorwiesen | Buchung, nicht Scope |
| 7-km-Rundwanderung Lübars–Schildow (Naturpark) | Wandergerüst, Kern = BB-Stege + Werder-Tafel |

## Geometrie

- `form: linie`, Out-and-back / Verbindungsstege, kein 7-km-Rundkurs
- Eröffnung 11.3.2015 (Stiftung + Gemeinde Glienicke)
- Je Steg zwei Plattformen mit Bänken/Tafeln
- Gegenbeleg 2021 Foto Moorsteg Jungbornstraße; 2026 Touren nennen Holzstege. OSM-Ways vor Seed.

## Stationen (≥3)

LIFE-Tafelset [informationstafeln.html](http://www.kalkmoore.de/weitere-informationen/infomaterial/informationstafeln.html) (2015):

1. Zeitmaschine Moor
2. Die Pflanzen im Moor
3. Die Tiere im Moor
4. Moorschutz und Renaturierung

Zusatz: Schautafel auf dem Eichwerder (Kalkniedermoor + Maßnahmen 2013) — Naturpark Barnim nennt sie aktuell. Vor Seed: ob alle vier Plattform-Titel noch stehen (Archiv 2015; Naturpark spricht nur von „einer Schautafel“ am Werder).

GPS: Overpass Stege/Plattformen + Tafel-PDFs.

## Arten

Belegt (Naturpark / Natura 2000 / kalkmoore): Ringelnatter, Krebsschere, Sumpfschwertlilie, Kranich, Eisvogel, Prachtlibelle, Schlangen-Knöterich, Sumpf-Baldrian. Seed nur Namen in `species.json` bzw. nach Spec anlegen.

## Quellen

- http://www.kalkmoore.de/weitere-informationen/fuer-kleine-moorforscher/moorlehrpfade.html
- http://www.kalkmoore.de/projektgebiete/eichwerder-moorwiesen.html
- http://www.kalkmoore.de/weitere-informationen/infomaterial/informationstafeln.html
- https://www.barnim-naturpark.de/themen/routen-touren/rundwanderung-durch-die-eichwerder-moorwiesen/
- https://www.natura2000-brandenburg.de/projektgebiete/barnim/eichwerder-moorwiesen

## Pipeline

Overpass Stege + Tafelbestand vor Ort/PDF → Config. **Nicht** in dieser Runde.
