# Heide-Erlebnisweg – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `heide-erlebnisweg` |
| Name | Heide-Erlebnisweg |
| typ | `wald` (Katalog; Heide im Namen/Text) |
| Region | Ostprignitz-Ruppin (Pfalzheim / Rossow / Neuglienicke) |
| OSM-Relation | [`12688859`](https://www.openstreetmap.org/relation/12688859) – Amenities/Korridor |
| Route | `tools/osm/heide-erlebnisweg_route.json` (kein naiver OSM-Stitch) |
| Heideturm | Node [`3004806058`](https://www.openstreetmap.org/node/3004806058) |

Nicht parallel: Kunsterspring, Alt Daber, Rel `4062916` (anderer Ort).

## Quellen

- Flyer: https://www.sielmann-stiftung.de/fileadmin/Mediendatenbank/Publikationen/Flyer_Wandern_Heide-Erlebnisweg.pdf
- Stiftung: https://www.sielmann-stiftung.de/natur-erleben/kyritz-ruppiner-heide
- Tour: https://www.sielmann-stiftung.de/tour/kyritz-ruppiner-heide-wanderweg (~15,6 km)
- Reiseland BB: https://www.reiseland-brandenburg.de/poi/ruppiner-seenland/wandertouren/wanderung-auf-dem-heide-erlebnisweg/
- Outdooractive (Themenweg): https://www.outdooractive.com/de/route/wanderung/ruppiner-seenland/erlebnis-kyritz-ruppiner-heide-abseits-der-seenplatte-ein/811825929/

## 11 Stationsthemen (Flyer)

1. Stille und Sterne  
2. Moose und Flechten  
3. Pflanzenfresser  
4. Rote Röhrenspinne  
5. Geschichte(n)  
6. Heinz Sielmann Stiftung  
7. Spezialisten im Wüstensand  
8. Heidekraut  
9. Heide als Kulturlandschaft  
10. Vogelwelt  
11. Aussicht Heideturm  

Stationen ohne feste Reihenfolge laut Flyer; App sortiert nach `km` entlang Neuglienicke → Rossow (Pfalzheim liegt mittig am Turm).

## Arten (Ziel-Dichte wie Moor/Raddusch)

Besenheide, Wiedehopf, Heidelerche, Ziegenmelker, Rote Röhrenspinne, Heidekraut-Seidenbiene, Braunkehlchen, Konik, Kiefer, Neuntöter (kuratiert in Config).

## Go / No-Go

**Go:** Route + ≥3 Stationen mit GPS/Titel/Thema/Kurztext + `validate_seeds.py` grün.  
**No-Go:** Naiver OSM-Stitch als alleinige Route; Rel `4062916`.

## Sicherheit (Pflicht in `beschreibung`)

Ehemaliger Truppenübungsplatz: nur freigegebene, mit rot umrandeten Pollern markierte Wege; Wege nicht verlassen.

## Pipeline

1. Route → `tools/osm/heide-erlebnisweg_route.json`
2. OSM Rel + BBox POIs/Amenities
3. Config `tools/trails/heide-erlebnisweg.json`
4. `python3 tools/build_seed.py tools/trails/heide-erlebnisweg.json`
5. `python3 tools/validate_seeds.py`
6. Seed in `SeedTrailRepository._seedPaths` + optional Supabase
