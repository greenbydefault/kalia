# Oberspreewald-Lausitz – Kandidaten

Stand: 2026-08-13.
Filter: [`README.md`](../../../README.md).
Kreis-Sweep: OSM + Senftenberg, Lübbenau Rest, Calau, Großräschen, Schwarzheide, Naturpark Niederlausitzer Landrücken.

HAVE aus der Brandenburg-OSM-26er-Liste. Keine neuen klaren GOs (≥3 Stationen aus Quellen). Config unter `tools/trails/`.

## GO

### lehde — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** |
| Config | `tools/trails/lehde.json` |
| OSM | Rel [`3652856`](https://www.openstreetmap.org/relation/3652856) Naturlehrpfad Rund um Lehde |
| `typ` | `spreewald` |
| Region | Lübbenau/Spreewald |

### raddusch — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** |
| Config | `tools/trails/raddusch.json` |
| OSM | Rel [`3687015`](https://www.openstreetmap.org/relation/3687015) Moorlehrpfad Raddusch |
| `typ` | `moor` |
| Region | Vetschau/Spreewald OT Raddusch |

## MAYBE

| Ort | Grund |
|---|---|
| Rel [`5538943`](https://www.openstreetmap.org/relation/5538943) **Naturlehrpfad durch Burg Kauper** | 29 Ways, **0 Stations-Nodes**. Lange markierte Hiking-Runde, keine Stationstexte. Gemeinde **Burg (Spreewald) = Spree-Neiße**, nicht OSL (Drei-Kreis-Ecke am Waldhotel Eiche). → nach SPN schieben. |
| **Hupatz-Pfad** (Burg/Kauper, Polenzweg) | Echter Mitmach-Pfad (~1 km): Libelle-Facette, Wiesenwispern, Spreewaldtiere, Baumtelefon, Greifvogel-Silhouetten, Wiedehopf-Ruf. ≥3 Stationen, frei, barrierefrei. **Falscher Kreis (SPN)** — nicht hier seeden. Quellen: http://www.spreewald.de/aktivitaeten-karte/wandern/wandertouren/familientouren/natur-erlebnis-pfad-hupatz |
| Rel [`19375282`](https://www.openstreetmap.org/relation/19375282) **Lehrpfad Welkmühle** | Lauchhammer OT Grünewalde, ≈ 51.5084, 13.7147; OSM nur 2 Ways. Wikipedia: 600 m Natur- und Geologielehrpfad + Gesteinslehrpfad (Findlinge, 2000). Keine Stationstitel. Mühlenhofmuseum = Anmeldung, raus. |
| **Baumlehrpfad Senftenberger See** | Zweckverband LSB 2022: 12 heimische Bäume an Stümpfen mit Steckbrief. Artenliste öffentlich nicht genannt → kein GO. |
| **Geologie- und Naturlehrpfad Luttchensberg** (Calau OT Zinnitz, ≈ 51.8013, 13.8541) | Blutana: Infos zu Geologie/Tieren/Pflanzen; **eingezäuntes** Waldstück auf Kippe Schlabendorf-Nord. Stationen unbenannt, Zugang unklar. |

## NOGO

| Ort | Grund |
|---|---|
| Heedekornweg Calauer Schweiz | 15 km Themenwanderung (Buchweizen), kein Stationen-Lehrpfad |
| Calauer Witzerundweg | Stadt/Kultur, nicht Natur-Lehrpfad |
| Mühlenhofmuseum / Heimatstube Grünewalde | Besuch nach Anmeldung |
| Slawenburg Raddusch (Museum) | Eintritt; Outdoor-Moorpfad separat HAVE |
| IBA-Terrassen / Rostiger Nagel Großräschen | Industriekultur/Aussicht, kein Lehrpfad |
| Adler- und Falknerhof Calauer Schweiz | Show/Buchung |
| Stadtspielplätze Senftenberg/Lübbenau/Schwarzheide | Standard-Sets |

Weitere OSM-OPEN ohne Kreis: [`../_unzugeordnet.md`](../_unzugeordnet.md).

## Kreis-Sweep

OSM + Ortsliste 2026-08-13. Lübbenau Rest außer Lehde: leer. Naturpark Landrücken: Heedekornweg/Wiedehopfweg = Wanderungen; Luttchensberg/Welkmühle = MAYBE.

## Onboarding (noch keine neuen Seeds)

1. ~~lehde / raddusch~~ — HAVE
2. Welkmühle / Luttchensberg / Baumlehrpfad Senftenberg — erst nach Stationstiteln
3. Hupatz + Rel 5538943 — in **Spree-Neiße**, nicht hier
