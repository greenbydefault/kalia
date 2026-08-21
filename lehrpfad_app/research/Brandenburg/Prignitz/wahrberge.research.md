# Waldlehrpark Wahrberge – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wahrberge` |
| Name | Waldlehrpark Wahrberge |
| typ | `naturerlebnis` |
| Region | Groß Pankow OT Groß Woltersdorf, Prignitz |
| Länge | Betreiber ~3,5 km Wegenetz; App-Route ~1,5 km Hauptschleife (OSM-Park + Picknick-Spur; Innenwege lückenhaft gemappt) |
| OSM | Node [`1937127902`](https://www.openstreetmap.org/node/1937127902) (Waldlehrpark) · Way [`183343169`](https://www.openstreetmap.org/way/183343169) (leisure=park); Footway [`418038329`](https://www.openstreetmap.org/way/418038329); Picnic [`1937127899`](https://www.openstreetmap.org/node/1937127899); keine Hiking-Relation |
| Route | `tools/osm/wahrberge_route.json` (kuratierte Park-Runde + Picnic-Site, Start Park-Node) |
| Schutzhütte / WC / Grill | optional kostenpflichtig – **nicht Scope** für Spontanbesuch; Outdoor-Gelände frei |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Wahrberge e. V.: https://www.wahrberge.de/waldlehrpark.html
- Reiseland Brandenburg: https://www.reiseland-brandenburg.de/poi/prignitz/gaerten-und-parkanlagen/waldlehrpfad-gross-pankow/
- Fachliche Begleitung: Landesbetrieb Forst Brandenburg (Oberförsterei Bad Wilsnack, Revier Langnow)
- Angebot: ~70.000 m², ~3,5 km Wege, Lehrtafeln, Arboretum (>200 Arten), Balancierstämme, Waldmoorspiel, Zapfenzielweitwurf, zentrale Schutzhütte, Waldbühne (Märchentage)

## Stationen (redaktionell, ≥3)

Keine öffentlichen GPS der Einzeltafeln; Positionen entlang der kuratierten Route (Slug + lat/lon).

1. Eingang Waldlehrpark – Start am Park-Node / Am Märchenwald
2. Arboretum & Lehrtafeln – Baumvielfalt / bewusste Wahrnehmung
3. Erlebnisstationen – Balancierstämme / Geschicklichkeit
4. Schutzhütte & Waldbühne – Zentrum / Verweilen (Miete optional, Spontanbesuch frei)

## Arten

Kiefer, Stieleiche, Bergahorn, Rote Waldameise, Igel, Hummel (alle in `species.json`).

## Go / No-Go

**Go:** Outdoor-Gelände frei & unentgeltlich; Route + ≥3 Stationen + Validator; `typ: naturerlebnis`.

**No-Go:** Führungen/Miete Schutzhütte/WC/Grill als Pflicht; Märchentage-Ticketlogik; Rodelbahn/Naturbad als Trail-Scope (nur Nähe-Hinweis).

## Pipeline

1. OSM-BBox → `wahrberge_route.json` + `_pois` / `_amenities`
2. Config `tools/trails/wahrberge.json`
3. `python3 tools/build_seed.py tools/trails/wahrberge.json`
4. `python3 tools/validate_seeds.py`
5. Seed in `SeedTrailRepository._seedPaths`
6. Status HAVE in `STATUS.md` + `_kandidaten.md`
