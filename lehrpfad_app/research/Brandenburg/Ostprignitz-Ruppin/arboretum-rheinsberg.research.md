# Arboretum Rheinsberg – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `arboretum-rheinsberg` |
| Name | Arboretum Rheinsberg |
| `typ` | `naturerlebnis` |
| `form` | `flaeche` |
| Region | Rheinsberg, Ostprignitz-Ruppin |
| Adresse | Revier Boberow, 16831 Rheinsberg (Böbereckensee) |
| Zugang | Outdoor, Erholungswald, Landesforst; Spontanbesuch |
| Status | **OPEN** – kein Seed in dieser Runde |
| OSM | Geometrie unklar (Park/Garten, keine Hiking-Rel) |
| Koordinaten | ≈ 53.1059, 12.8754 |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Baumgarten Erholungswald Boberow, beschilderte Gehölze | **GO** (Konzept) |
| Schlosspark Rheinsberg / Gartenreich Boberow (Denkmal) | **nicht** dieser Ort |
| Stationstitel / Artenliste öffentlich | **fehlen** → kein Seed |

Landesforst: Einblick in heimische Bäume und Sträucher. Outdooractive zählt 52 Laubbäume, 34 Nadelbäume, 76 Sträucher — Zählung reicht nicht für `arten[]`.

## Geometrie

- `form: flaeche`, `area[]` um den Baumgarten, `laengeKm: 0`, `rundkurs: false`
- OSM-Polygon: **fehlt** bzw. nicht zugeordnet — vor Seed Overpass `leisure=garden` / `garden:type=arboretum` um Böbereckensee
- Interne Pfade = Erschließung, kein Fake-Rundkurs

## Stationen (≥3)

Muster wie Dreetz (Cluster, keine Einzelbäume), sobald vor Ort oder Betreiberliste da:

1. Laubquartier
2. Nadelquartier
3. Sträucher

GPS: Geländepunkte vor Seed. Seeufer/Bank = Amenity `bench`/`picnic`, keine Extra-Station ohne Beleg.

## Arten

Keine Einzelarten öffentlich genannt. Nicht aus der Zählung 52/34/76 erfinden.

## Quellen

- https://www.outdooractive.com/de/poi/ruppiner-seenland/arboretum-rheinsberg/16865073/
- https://www.wanderfeeling.de/fotoarchiv/bilder/liegebank-im-arboretum-am-boebereckensee-bei-rheinsberg-ruppiner-seenland-brandenburg-deutschland-202508110-11

## Pipeline

Nächster Schritt: Flächen-Polygon + 3 Stationspunkte + belegte Artnamen → direkter Flächen-Seed (wie Dreetz). **Nicht** in dieser Runde.
