# Datenmodell

Ist-Schema aus Domain (`lib/features/trail/domain/`, `lib/features/species/domain/`), Seed-JSON und Supabase. Katalog-Keys: [`icon_catalog.dart`](../lib/shared/catalogs/icon_catalog.dart). Qualitätsbar: [`traumdatensatz.md`](traumdatensatz.md).

## Entitäten

### Trail

| Feld | Typ | Pflicht | Hinweis |
|---|---|---|---|
| `id` | string | ja | stabil, snake-case |
| `name` | string | ja | |
| `typ` | string | ja | Key aus `typKatalog` |
| `form` | `linie` \| `flaeche` | nein | Default: `linie`; Typen `wasserspielplatz`/`waldspielplatz`/`waldspazierplatz`/`kinderbauernhof` → `flaeche` |
| `kurzbeschreibung` | string | ja | Card / Teaser |
| `beschreibung` | string | ja | Detail |
| `laengeKm` | number | ja | Weglänge; bei `flaeche` = **0** |
| `dauerMin` | int | ja | Gehzeit bzw. Aufenthaltsdauer |
| `rundkurs` | bool | ja | bei `flaeche` immer **false** |
| `markierung` | string | ja | |
| `betreiber` | string | ja | |
| `region` | string | ja | |
| `website` | string? | nein | Accordion Anreise & Infos |
| `eintritt` | bool | nein | Default `false`; `true` → Header-Chip „Eintritt“ |
| `eintrittPreise` | string? | nein | z. B. `1,50 € ab 2 Jahren` / `frei, Spende willkommen` |
| `oeffnungszeiten` | string? | nein | Freitext Sommer/Winter |
| `besuchshinweise` | string? | nein | Fütterung, Streichelzeiten, Ruhetag |
| `anreise` | string | ja | |
| `startName` | string | ja | |
| `arten` | string[] | ja | Namen/Aliases → Species (inkl. `geraete`) |
| `tags` | string[] | nein | redaktionell; plus Auto-Tags |
| `route` | `[lat,lon][]` | bei `linie` | Polyline |
| `area` | `[lat,lon][]` | bei `flaeche` | geschlossenes Polygon (≥3) |
| `stationen` | Station[] | ja | ≥3 |
| `amenities` | Amenity[] | ja | kann leer sein, Soll: gefüllt |

Abgeleitet: `isFlaeche` / `isLinie`, `mapPoints`, `start` (Centroid bei Fläche), `autoTags`, Eignungs-Scores.

**Fläche vs. Linie:** Spiel-/Erlebnisplätze ohne Wegnetz (`form: flaeche`) zeichnen auf der Karte ein Polygon, keine Route. Kein Fake-Rundkurs.

### Station

| Feld | Typ | Pflicht |
|---|---|---|
| `id` | int? | nur Supabase |
| `osmId` | int | ja (Seed; synthetisch ok) |
| `lat` / `lon` | number | ja |
| `km` | number | ja |
| `reihenfolge` | int | ja |
| `titel` | string | ja |
| `thema` | string | ja |
| `kurztext` | string | ja |
| `erlebnisse` | string[] | ja | Keys aus `erlebnisKatalog` |
| `barrierefrei` | bool | ja | Default false |
| `steckbrief` | object? | nein | siehe `Steckbrief` |

### Amenity

| Feld | Typ | Pflicht |
|---|---|---|
| `osmId` | int | ja |
| `lat` / `lon` | number | ja |
| `kategorie` | string | ja | Keys aus `amenityKatalog` |
| `name` | string? | nein |

### Species

Katalog in `assets/seed/species.json` / Tabelle `species`.

| Feld | Typ | Pflicht |
|---|---|---|
| `id` | string | ja |
| `nameDe` | string | ja |
| `nameLat` | string | nein |
| `kategorie` | `flora` \| `fauna` \| `geraete` | ja |
| `kurztext` | string | ja (Fallback-Hook) |
| `content` | object | ja für Go | Spec: `tools/SPECIES_CONTENT.md` / bei `geraete`: `tools/GERAETE_CONTENT.md` |
| `iconKey` | string? | nein | nur `geraete`; Key aus `geraeteKatalog` (IconData nie im JSON) |
| `aliases` | string[] | nein |
| `imagePath` / `imageCredit` / `audioPath` | | nein |

**Stadtspielplatz vs. Motorik-/Wasserspielplatz:** reine Standard-Sets (Schaukel/Rutsche/Klettergerüst) nicht als eigener Trail/`wasserspielplatz`-Seed. Filter: [`research/README.md`](../research/README.md). Beispiele: [`research/Brandenburg/Ostprignitz-Ruppin/_kandidaten.md`](../research/Brandenburg/Ostprignitz-Ruppin/_kandidaten.md).

### trail_species (Supabase)

Join `trail_id` ↔ `species_id` (Migration `0007_species.sql`). Im Seed: Trail-Feld `arten[]` wird beim Import aufgelöst.

### Steckbrief (optional an Station)

`groesseHa`, `alterJahre`, `tiefeM`, `lebenselixier`, `werdegang` — alles optional.

## Kataloge

### Erlebnisse (`erlebnisKatalog`)

`tafel`, `quiz`, `steg`, `bohrkernmodell`, `mitmach-modell`, `memory`, `bestimmung`, `audio`, `barfusspfad`

### Amenities (`amenityKatalog`)

`wc`, `parking`, `bench`, `picnic`, `shelter`, `playground`, `viewpoint`, `gastro`

### Tags (`tagKatalog`)

Redaktionell: `kinderfreundlich`, `kinderwagentauglich`, `rollstuhltauglich`, `hunde-erlaubt`, `einkehr`, `spielplatz`, `picknick`, `barfusspfad`

Auto (aus Amenities): `parkplatz-nahe`, `wc-am-weg`, (+ `spielplatz` wenn Playground)

### Trail-Typen (`typKatalog`)

Stabile Keys (snake_case). Source of Truth: `icon_catalog.dart` → Validator `TYP`.

| Key | Label (UI) | Bedeutung |
|---|---|---|
| `wald` | Naturlehrpfad | klassischer Natur-/Waldlehrpfad |
| `moor` | Moorlehrpfad | Moor-Schwerpunkt |
| `spreewald` | Spreewald-Lehrpfad | Spreewald-Charakter |
| `walderlebnispfad` | Walderlebnispfad | interaktiver Wald-Pfad (Stationen/Aufgaben) |
| `erlebniswald` | Erlebniswald | Erlebniswald / Erlebnis-Area als Ort |
| `naturerlebnis` | Naturerlebnisraum | Kurzkey (= gestalteter Naturerlebnisraum); auch Arboretum / beschilderter Baumgarten, dann meist `form: flaeche` |
| `naturerlebnisraum` | Naturerlebnisraum | Alias zum gleichen Konzept |
| `waldspielplatz` | Waldspielplatz | Spiel-/Bewegungsangebote im Wald (Motorik-Fokus, kein reines Standard-Set) |
| `wasserspielplatz` | Wasserspielplatz | Ort *ist* Wasserspiel-/Motorik-Wasserort (Pumpe/Rinne/Matschen o. Ä.) |
| `waldspazierplatz` | Waldspazierplatz | kurzer Spazier-/Aufenthaltsort im Wald |
| `sinnespfad` | Sinnespfad | Sinnespfad / Sinnesfahrt |
| `barfusspfad` | Barfußpfad | gesamter Trail als Barfußpfad; Tag/Erlebnis `barfusspfad` bleibt parallel für Stationen/Ausstattung |
| `kinderbauernhof` | Kinderbauernhof | pädagogischer Hof, `form: flaeche`; GO-Bar in [`research/README.md`](../research/README.md) |

`typ` ist in der DB freier String — keine Migration nötig. Neue Keys nur hier + Validator spiegeln. Besuchsfelder (`eintritt` …) brauchen eine `trails`-Migration.

### Species-Kategorien (`speciesKategorieKatalog`)

`flora`, `fauna`, `geraete` — Icons/Labels zentral in `icon_catalog.dart`.

### Geräte-Icons (`geraeteKatalog`)

Keys (z. B. `geraet`) → Icon + Label. Species-Feld `iconKey` verweist darauf; unbekannter/leerer Key → Fallback `geraet`.

## Validierung

`tools/validate_seeds.py` prüft Pflichtfelder, Katalog-Keys (inkl. `typ`), Stationsreihenfolge, Geometrie-Sprünge, Rundkurs und Arten-Auflösung.
