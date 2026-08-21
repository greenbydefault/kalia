# Arboretum Lüttgen Dreetz – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `arboretum-dreetz` |
| Name | Arboretum Lüttgen Dreetz |
| `typ` | `naturerlebnis` |
| `form` | `flaeche` |
| Region | Dreetz, Ostprignitz-Ruppin |
| Adresse | Bartschendorfer Str. 13, 16845 Dreetz |
| Zugang | ganzjährig, Eintritt frei, ohne Anmeldung |
| Status | **HAVE** – Seed `assets/seed/arboretum-dreetz.json` |
| OSM | Way [`636975365`](https://www.openstreetmap.org/way/636975365) (`leisure=garden`, `garden:type=arboretum`) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Waldgarten 8 ha, beschilderte Bäume, Obstwiesen | **GO** |
| Barfußpfad | **kein** eigener Trail — 2024 nur Sekundärquellen, nicht auf arboretum-dreetz.de / Reiseland. Nicht als Tag geseedet |
| Veranstaltungen (Ostern, Fest, Hubertus, Weihnachtsmarkt, Lehmbackofen) | nicht Scope |

## Geometrie

- `form: flaeche`, `area[]` = OSM-Way 636975365 (Note: Ausdehnung geschätzt), `laengeKm: 0`, `rundkurs: false`
- Roh: [`tools/osm/arboretum-dreetz_way.json`](../../../tools/osm/arboretum-dreetz_way.json)
- Adresse: Way [`745418461`](https://www.openstreetmap.org/way/745418461) Bartschendorfer Straße 13
- Obstwiese West: Way [`971322405`](https://www.openstreetmap.org/way/971322405) `landuse=orchard` (Zentrum als Stationsanker)
- Interne Pfade sind Erschließung, kein Fake-Rundkurs-Seed
- Pavillon: Gemeinde nennt ihn, OSM hat keinen `shelter` → nicht als Amenity

## Stationen (≥3)

1. Waldgarten / Baumpaten — Laub-, Nadel- und Strauchgewächse, >100 Arten, Holzschilder
2. Eichenquartier — rund 15 Eichenarten (Quercus), Fagaceae
3. Obstbaumwiesen Süd/West — alte Sorten und Beeren, Namensschilder

## Arten

`Stieleiche` (Katalog), neu `Rotbuche`, `Edelkastanie` — Betreiber nennt Eiche/Buche/Kastanie. Scheinkastanie kein eigener Steckbrief. Keine der 15 Eichen einzeln erfunden.

## Quellen

- https://arboretum-dreetz.de/
- https://www.reiseland-brandenburg.de/poi/prignitz/gaerten-und-parkanlagen/arboretum-luettgen-dreetz/
- https://www.gemeinde-dreetz.de/index.php/tourismus/arboretum-luettgen-dreetz

## Seed (HAVE)

Flächen-Seed direkt `assets/seed/arboretum-dreetz.json`. In `_seedPaths`. Validator: `form=flaeche`.
