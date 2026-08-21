# Naturlehrpfad Groß Schauen – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `gross-schauen` |
| Name | Naturlehrpfad Sielmanns Naturlandschaft Groß Schauen |
| typ | `naturerlebnis` |
| Region | Storkow (Mark) OT Groß Schauen, Oder-Spree |
| Länge | 1,5 km Uferpfad; inkl. Rückweg ≈ 2,9 km (Sielmann) |
| Start | Groß Schauener Hauptstraße 31 (Fischerei Köllnitz / Eingangstafel) |
| Ziel-Anker | Aussichtsturm Selchow am Großen Wochowsee — **Turm seit 2026-05-20 gesperrt**, Pfad offen |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Naturpark Dahme-Heideseen: https://www.dahme-heideseen-naturpark.de/themen/routen-touren/naturlehrpfad-sielmanns-naturlandschaft-gross-schauen/
- Sielmann-Tour: https://www.sielmann-stiftung.de/tour/naturlehrpfad-gross-schauen
- Eröffnung 2017 (10 Tafeln): https://www.sielmann-stiftung.de/news/detail/neuer-naturlehrpfad-in-gross-schauen
- Gebiet: https://www.sielmann-stiftung.de/natur-erleben/erholungsorte/gross-schauener-seen

**Zugang:** Fischerei Köllnitz insolvent (Stiftung: endgültig geschlossen 2026-08-08) → Ausstellung zu. Uferpfad laut Naturpark weiter beschrieben. Vor Seed klären, ob der Start über das ehem. Fischerei-Gelände noch öffentlich ist oder ein seitlicher Einstieg reicht.

## Stationsthemen (Betreiber, ≥3)

Zehn Infotafeln „Lebensräume oder Arten nahe ihres Standorts“ (keine öffentlichen Einzeltitel). Für Config redaktionell aus Erstquelle, GPS im Feld:

1. Eingangstafel Projektgebiet Heinz Sielmann Stiftung
2. Erlenbrüche
3. Röhrichte
4. Fischotter
5. Moorfrosch
6. Rotbauchunke
7. Blaukehlchen
8. Große Rohrdommel
9. Biber (Wiederausbreitung)
10. Seevögel vom Turm-Standort (Kormoran, Rohrweihe, Seeadler, Fischadler, Kranich — Beobachtung, Turm nicht besteigen)

## Arten

Fischotter, Fischadler, Moorfrosch, Rotbauchunke, Blaukehlchen, Große Rohrdommel, Biber, Seeadler.

## Go / No-Go

**Go:** Outdoor-Pfad frei gedacht; 10 Tafeln + benannte Lebensräume/Arten.

**No-Go:** Ausstellung/Aquarien; Turmbesteigung; 25-km-Seenkette als Route.

## Pipeline

1. Zugang Start prüfen (Parkplatz/Ufer ohne Fischerei-Hof)
2. Route Ufer Groß Schauener See → Wochowsee
3. Config `tools/trails/gross-schauen.json`
4. Seed + Validator; Turm als Amenity `access=no` bis Sanierung
