# Zweiseitenweg Rambower Moor – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `zweiseitenweg-rambow` |
| Name | Zweiseitenweg rund um das Rambower Moor |
| `typ` | `moor` |
| `form` | `linie` |
| Region | Karstädt OT Boberow / Rambow / Mellen, Prignitz |
| Start | Sportplatz Mellener Weg, 19357 Boberow (alternativ Kirche Rambow, Großsteingrab Mellen) |
| Länge | 12–12,5 km Rundweg, gelber Punkt auf weiß |
| Zugang | frei; Wege nicht verlassen (Störung) |
| Status | **OPEN** – kein Seed in dieser Runde |
| OSM | keine Hiking-Rel unter dem Namen; nicht Rel `7539905` (Oberhavel NOGO) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Zweiseitenweg mit Stationen naturkundlich + historisch | **GO** |
| Geführte Kranichtouren Naturwacht / BUND Burg Lenzen | Buchung, nicht Scope |
| Naturwacht-Themenwanderungen (Tümpeltour, Quellen von Mellen) | Buchung — Bohlenweg an den Quellen selbst frei |
| Rel `7539905` Geheimnisvolle Moore | anderer Kreis / anderer Trail |
| Moorscheune Boberow (Zelten, Kremser) | Amenity / Gastro, kein Trail |

## Geometrie

- `form: linie`, Rundkurs
- OSM-Rel: **fehlt** — Biosphäre bietet Flyer + GPX
- Vor Seed: GPX vom Biosphärenreservat, nicht naiver Rel-Stitch

## Stationen (≥3)

Betreiber/Tourismus (Verlauf + Haltepunkte):

1. Moorblick Boberow — Aussichtsturm, Vogelbeobachtung
2. Moorblick Rambow — Aussichtsturm
3. Moorquellen — Bohlenweg; kalkmoore: Kinder können Rindenboote / Wasserräder (kein Pflicht-Spielgerät)
4. Großsteingrab Mellen
5. Moorscheune Boberow
6. Stationen „zwei Seiten“ (historisch / aktuell) — Einzeltitel im Flyer, nicht vollständig online

GPS: GPX + Flyer vor Seed.

## Arten

Belegt: Kranich, Großer Feuerfalter, Orchideen, Bekassine („Himmelsziege“). Seed nur Namen, die in `species.json` auflösbar sind bzw. nach Spec anlegen.

## Quellen

- https://www.elbe-brandenburg-biosphaerenreservat.de/erleben-lernen/aktiv-in-der-natur/wandern/zweiseitenweg-rund-um-das-rambower-moor/
- https://dieprignitz.de/zweiseitenweg
- http://www.kalkmoore.de/weitere-informationen/fuer-kleine-moorforscher/moorlehrpfade.html (12 km, zwei Türme, Quellen-Bohlenweg Mellen, Moorscheune)

## Pipeline

Nächster Schritt: GPX → Route + Flyer-Stationen → Config. **Nicht** in dieser Runde.
