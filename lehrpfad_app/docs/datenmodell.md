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
| `kurzbeschreibung` | string | ja | Card / Teaser. ≤ 180 Zeichen, keine Anrede ([`TRAIL_SCAN.md`](../tools/TRAIL_SCAN.md)) |
| `beschreibung` | string | ja | Detail. 400–650 Zeichen, Satz 1 trägt allein ([`TRAIL_SCAN.md`](../tools/TRAIL_SCAN.md)) |
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
| `besuchshinweise` | string? | nein | Fütterung, Streichelzeiten, Ruhetag. ≤ 280 Zeichen, nur was kein Tag zeigt ([`TRAIL_SCAN.md`](../tools/TRAIL_SCAN.md)) |
| `anreise` | string | ja | |
| `startName` | string | ja | |
| `arten` | string[] | ja | Namen/Aliases → Species (inkl. `geraete`) |
| `artenNachweis` | object? | nein | Name → `belegt` \| `typisch`. Fehlt der Key: `belegt`. Nur Seed/Import, keine Anzeige |
| `lebensraeume` | string[] | ja | 0–3 Keys aus `lebensraumKatalog`. Leer nur ohne passenden Lebensraum (Spielplatz, Geopfad) |
| `naturraum` | string | ja | Key aus `naturraumKatalog`, aus der Koordinate |
| `tags` | string[] | nein | redaktionell; plus Auto-Tags |
| `route` | `[lat,lon][]` | bei `linie` | Polyline |
| `area` | `[lat,lon][]` | bei `flaeche` | geschlossenes Polygon (≥3) |
| `stationen` | Station[] | ja | ≥3 |
| `amenities` | Amenity[] | ja | kann leer sein, Soll: gefüllt |
| `bilder` | TrailBild[] | nein | Seed-Hero. Leer → zentraler Pager-Platzhalter (`assets/images/trails/_placeholder.{variant}.avif`), nicht Karte. Manifest: `assets/images/trails/{id}/credits.json` |
| `bilderAsset` | string | nein | Pfad zum Manifest. In der Trail-Config setzen; `build_seed.py` schreibt ihn in den Seed. Runtime lädt das Array nach `bilder` |

### TrailBild (Seed-Hero)

Ordner: `assets/images/trails/{id}/{NN-slug}.{thumb,small,medium}.avif` + `credits.json`. Jeder Trail-Ordner braucht eine eigene `pubspec.yaml`-Zeile (Flutter nimmt Unterordner nicht mit).

**Varianten** (längste Kante, AVIF; Seitenverhältnis bleibt, UI cropt mit `BoxFit.cover`):

| Variante | px | q | Slot |
|---|---|---|---|
| `thumb` | 480 | 35 | Karten-Peek, Station-Strip, Moderation |
| `small` | 900 | 30 | Trail-Header-Slider (`heroFraction`), Community-Carousel |
| `medium` | 2000 | 40 | Fullscreen + Zoom |

Ingest: `dart run tool/ingest_images.dart <trail_id>` (oder `--all`). Nutzt dieselbe Resize-Logik wie der User-Upload (`lib/shared/images/image_variants.dart`), AVIF über `sips`. Liest `credits.json`, schreibt die drei `.avif`, löscht die JPEG/PNG-Quelle. `file` in credits.json bleibt der Slug (z. B. `01-deich-trischendamm.jpg`); die UI hängt `.{variant}.avif` an.

| Feld | Typ | Pflicht | Hinweis |
|---|---|---|---|
| `file` | string | ja | Dateiname oder `assets/…` |
| `caption` | string | nein | Bildunterschrift |
| `credit` | string | nein | Autor, Badge „Foto: …“ |
| `license` | string | nein | `cc-by-sa-4.0` \| `cc-by-sa-3.0` \| `cc-by-sa-2.0` \| `cc-by-4.0` \| `cc-by-3.0` \| `cc-by-2.0` \| `cc0` \| `pd` |
| `licenseUrl` | string | nein | Deeplink Lizenztext |
| `sourceUrl` | string | nein | Quelle (meist Wikimedia-File-Seite) |
| `kind` | string? | nein | `ort` \| `art` \| `placeholder` — UI filtert nur `placeholder` |

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

Infrastruktur *am Weg* (WC, Bank, Parkplatz, `gastro`). Nicht für kuratierte Orte im Umfeld — siehe [Ort in der Nähe](#ort-in-der-nähe).

| Feld | Typ | Pflicht |
|---|---|---|
| `osmId` | int | ja |
| `lat` / `lon` | number | ja |
| `kategorie` | string | ja | Keys aus `amenityKatalog` |
| `name` | string? | nein |

### Ort in der Nähe

Katalog in `assets/seed/pois.json` / Tabelle `pois`. Kuratierte Cafés, Restaurants, Hofläden, Bäder, Museen, Aktivitäten und Campingplätze im Umfeld.

**Zuordnung zum Trail = Auto-Fahrzeit vom Trail-Start, höchstens 20 Min (1200 s), alle Kategorien** (Familien rechnen Erreichbarkeit, nicht Kilometer: Café 10 km / 25 Min fällt raus). Kein Join am Trail im Katalog; die Zuordnung steht in `nearby_zeiten.json` / `trail_pois` (unten). Anzeige max. 8 pro Trail (erst max. 2 pro Kategorie, Rest nach Fahrzeit), sortiert nach Fahrzeit, Anzeige „12 Min Auto“.

Kuratierung: keine Supermärkte, keine Hotels/Pensionen (nur Camping), keine Standard-Spielplätze (besondere Spielplätze sind Trail-Typen).

| Feld | Typ | Pflicht | Hinweis |
|---|---|---|---|
| `id` | string | ja | slug, snake-case |
| `name` | string | ja | |
| `kategorie` | string | ja | Key aus `poiKategorieKatalog` |
| `kurztext` | string | ja | 1 Satz, Familien-Nutzen |
| `lat` / `lon` | number | ja | |
| `website` | string? | nein | |
| `oeffnungszeiten` | string? | nein | Anzeige-Freitext |
| `opening_hours` | string? | nein | OSM-Subset für „Jetzt geöffnet“-Badge |
| `telefon` | string? | nein | |

#### Fahrzeiten Trail → Ort (`nearby_zeiten.json` / `trail_pois`)

Berechnet von `tools/nearby_zeiten.py` (OSRM-Table, Luftlinie 25 km nur als Vorfilter). Die App routet nie selbst (offline), sie liest nur diese Daten. Datei nie von Hand editieren.

```json
{ "<trailId>": [ { "poi": "<poiId>", "sek": 612 } ] }
```

- Nur Paare mit `sek` ≤ 1200, je Trail nach `sek` sortiert; Trail ohne Treffer → `[]`.
- Start wie `Trail.startOrNull` (Fläche: Schwerpunkt, Linie: erster Routenpunkt, sonst erste Station).
- Supabase: Tabelle `trail_pois (trail_id, poi_id → pois.id, sek)`, Public Read (Migration `0025_trail_pois.sql`). `tools/seed_pois.py` ersetzt pro Trail alle Zeilen. Fällt die Tabelle leer oder aus, nimmt die App Cache, dann Seed.
- Ein neuer oder verschobener Ort ändert Zuordnungen auch bei Nachbar-Trails: danach `python3 tools/nearby_zeiten.py --all`. `validate_seeds.py` prüft Ort-IDs, Grenze und Sortierung.

### Species

Katalog in `assets/seed/species.json` / Tabelle `species`.

| Feld | Typ | Pflicht |
|---|---|---|
| `id` | string | ja |
| `nameDe` | string | ja |
| `nameLat` | string | nein |
| `kategorie` | `flora` \| `fauna` \| `geraete` | ja |
| `kurztext` | string | ja (Fallback-Hook) |
| `content` | object | ja für Go | Spec: `tools/SPECIES_CONTENT.md` / bei `geraete`: `tools/GERAETE_CONTENT.md`. `content.tiefe`: `voll` (Default, mit `hoertext`) oder `kurz` (ohne `hoertext`) |
| `iconKey` | string? | nein | nur `geraete`; Key aus `geraeteKatalog` (IconData nie im JSON) |
| `aliases` | string[] | nein |
| `imagePath` / `imageCredit` / `audioPath` | | nein |
| `gruppe` | string | flora/fauna | Key aus `speciesGruppeKatalog` |
| `seltenheit` | string | flora/fauna | Key aus `seltenheitKatalog` |
| `gefahr` | int 1–5 | flora/fauna | |
| `nahrung` | string[] | flora/fauna | |
| `taxonomie` | object | flora/fauna | `reich`/`stamm`/`klasse`/`ordnung`/`familie` |
| `masse` | object[] | flora/fauna | `[{key, wert}]`, Keys aus `masseKatalog` |
| `merkmale` | string[] | flora/fauna | IDs aus `assets/seed/merkmale.json` |
| `beziehungen` | object[] | flora/fauna | `[{typ, toSpeciesId?, nameDe?, nameLat?, kurztext?}]` (Alias `speciesId`) |

### Merkmale

Katalog in `assets/seed/merkmale.json` / Tabelle `merkmale`. Geteilte Badges (Aussehen / Verhalten / Rolle / Lebensraum); viele Arten tragen dasselbe Merkmal. Icon über `iconKey` in `merkmaleKatalog` — Phosphor-Platzhalter, kein Snappit-Schild-Look.

| Feld | Typ | Pflicht |
|---|---|---|
| `id` | string | ja |
| `nameDe` | string | ja |
| `beschreibung` | string | ja | 1 Satz, Kinder, kein Lexikon |
| `iconKey` | string | ja | Key aus `merkmaleKatalog` |
| `gruppe` | string | ja | `aussehen` \| `verhalten` \| `rolle` \| `lebensraum` |
| `sortierung` | int | ja | |

### species_beziehungen (Supabase)

Ökologische Beziehungen: `from_id` → `typ` (`frisst` | `bestaeubt` | `wohnt_an`) → optional `to_species_id` (Katalog-Art, tippbar) oder Freitext (`name_de`, z. B. „Mücke“, „Uhu“). `kurztext` ≤ 12 Wörter.

**Stadtspielplatz vs. Motorik-/Wasserspielplatz:** reine Standard-Sets (Schaukel/Rutsche/Klettergerüst) nicht als eigener Trail/`wasserspielplatz`-Seed. Filter: [`research/README.md`](../research/README.md). Beispiele: [`research/Länder/Deutschland/Brandenburg/Ostprignitz-Ruppin/_kandidaten.md`](../research/Länder/Deutschland/Brandenburg/Ostprignitz-Ruppin/_kandidaten.md).

### trail_species (Supabase)

Join `trail_id` ↔ `species_id` (Migration `0007_species.sql`), plus `nachweis` `belegt` \| `typisch` (Migration `0026_arten_pool.sql`). Im Seed: `arten[]` wird aufgelöst, `artenNachweis` setzt die Stufe. Die App zeigt die Stufe nicht.

`belegt`: Tafel, Betreiber, Stationsthema dieses Pfads. `typisch`: Art steht im Pool [`assets/seed/art_pools.json`](../assets/seed/art_pools.json) für `lebensraeume` × `naturraum` und eine Familie kann sie dort antreffen. Pool-Quelle ist der Lebensraumtyp, nicht ein Fundpunkt.

### Lebensräume (`lebensraumKatalog`)

`kuestenwald-kiefer`, `buchenwald`, `eichen-mischwald`, `kiefernforst`, `auwald`, `moor`, `heide`, `streuobst-hecke`, `teich-tuempel`, `fliessgewaesser`, `see-ufer`, `salzwiese-watt`, `duene-strand`, `trockenrasen`, `nadelforst`, `hof-nutztier`, `mediterraner-wald`, `alpen-wald`

### Naturräume (`naturraumKatalog`)

`nordsee`, `ostsee`, `norddt-tiefland`, `mittelgebirge`, `alpenvorland`, `katalonien`, `daenemark`

### Steckbrief (optional an Station)

`groesseHa`, `alterJahre`, `tiefeM`, `lebenselixier`, `werdegang` — alles optional.

## Kataloge

### Erlebnisse (`erlebnisKatalog`)

`tafel`, `quiz`, `steg`, `bohrkernmodell`, `mitmach-modell`, `memory`, `bestimmung`, `audio`, `barfusspfad`

### Amenities (`amenityKatalog`)

`wc`, `parking`, `bench`, `picnic`, `shelter`, `playground`, `viewpoint`, `gastro`

### Orte in der Nähe (`poiKategorieKatalog`)

`cafe`, `restaurant`, `hofladen`, `baden`, `museum`, `aktivitaet`, `camping`

Anzeige-Reihenfolge = Katalog-Reihenfolge. Zuordnung zum Trail: Auto-Fahrzeit ≤ 20 Min ab `Trail.start`, alle Kategorien (siehe [Ort in der Nähe](#ort-in-der-nähe)).

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
| `kueste` | Küstenpfad | Kliff / Watt / Strand mit Stationen; Outdoor frei, Center-Ticket optional |
| `kinderbauernhof` | Kinderbauernhof | pädagogischer Hof, `form: flaeche`; GO-Bar in [`research/README.md`](../research/README.md) |

`typ` ist in der DB freier String — keine Migration nötig. Neue Keys nur hier + Validator spiegeln. Besuchsfelder (`eintritt` …) brauchen eine `trails`-Migration.

### Species-Kategorien (`speciesKategorieKatalog`)

`flora`, `fauna`, `geraete` — Icons/Labels zentral in `icon_catalog.dart`.

### Geräte-Icons (`geraeteKatalog`)

Keys (z. B. `geraet`) → Icon + Label. Species-Feld `iconKey` verweist darauf; unbekannter/leerer Key → Fallback `geraet`.

## Validierung

`tools/validate_seeds.py` prüft Pflichtfelder, Katalog-Keys (inkl. `typ`), Stationsreihenfolge, Geometrie-Sprünge, Rundkurs und Arten-Auflösung.
