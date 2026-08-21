# Walderlebnispfad Stendenitz – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `stendenitz` |
| Name | Walderlebnispfad Stendenitz |
| typ | `walderlebnispfad` |
| Region | Neuruppin OT Stendenitz, Ostprignitz-Ruppin |
| Länge | App-Route aus OSM-Wegenetz (Schleife Museum → Norden → Kellen → Museum) |
| OSM | Way [`1181157366`](https://www.openstreetmap.org/way/1181157366) + [`1181465951`](https://www.openstreetmap.org/way/1181465951) (Nordast); Rückweg [`289005116`](https://www.openstreetmap.org/way/289005116); Kellen [`141543677`](https://www.openstreetmap.org/way/141543677) / [`1417913011`](https://www.openstreetmap.org/way/1417913011) Naturlehrpfad; Lücke ~50 m vor [`1072243612`](https://www.openstreetmap.org/way/1072243612) interpoliert |
| Route | `tools/osm/stendenitz_route.json` (kuratiert nach Starttafel, kein Out-and-back) |
| Museum | Node [`2697495552`](https://www.openstreetmap.org/node/2697495552) – **nicht Scope** (separater Besuch) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Forst BB: https://forst.brandenburg.de/lfb/de/waldmuseum-stendenitz/
- Wikipedia: https://de.wikipedia.org/wiki/Waldmuseum_Stendenitz
- Vorgänger-Naturlehrpfad 1960/61 (Vollrath/Neumann); Walderlebnispfad neu 2013 (Ingenieurbüro „Natur und Bildung“, Oberförsterei Neuruppin)
- **Starttafel vor Ort** (Feld 2026-08-16): 9 Stationen, Suchauftrag, Barfuß-Tipp, Kartenverlauf an die Kellen
- Stationen 2–3: Tafelfotos Rätselbuche / Waldauge. 4–9: nur Legende + Lage auf der Tafelkarte, GPS georeferenziert (kein OSM-Board)

## Stationen (Tafel)

1. Vorstellung (Hier stehst du!) – Starttafel am Waldmuseum
2. Rätselbuche – Klapptafel-Rätsel (Foto)
3. Waldauge – 6 Tiere in den Kronen (Foto)
4. Baum-Bandolino – Nordkreuzung (Tafelkarte)
5. Spurenpfütze – Westseite (Tafelkarte)
6. Spechtholz – westlich vor den Kellen (Tafelkarte)
7. Wasserliebe – Nordufer Die Kellen (Tafelkarte)
8. Pilztopf – zurück zur Straße (Tafelkarte)
9. Waldgeschichte – zurück am Museum (Tafelkarte)

## Arten

Kiefer, Stieleiche, Rotbuche, Biber, Kranich, Rote Waldameise, Igel (alle in `species.json`). Waldauge-Tiere (Kolkrabe, Waldohreule, …) nicht im Katalog – nicht als Fake-Arten.

## Go / No-Go

**Go:** Outdoor-Pfad frei & spontan; Route + 9 Stationen (3 mit Tafeltext, 6 Lage-only) + Validator.

**No-Go:** Museum/Eintritt/Öffnungszeiten als Pflicht; Waldschul-Programme; erfundene Dialoge an Stationen 4–9; erfundene Einzeltafeln als OSM-Wahrheit.

## Pipeline

1. OSM-Ways + Tafelkarte → `stendenitz_route.json` + `_pois` / `_amenities`
2. Config `tools/trails/stendenitz.json`
3. `python3 tools/build_seed.py tools/trails/stendenitz.json`
4. `python3 tools/validate_seeds.py`
5. Seed in `SeedTrailRepository._seedPaths`
6. Status HAVE in `STATUS.md` + `_kandidaten.md`
