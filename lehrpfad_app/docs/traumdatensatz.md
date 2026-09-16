# Traumdatensatz

Qualitäts-Referenz für einen auslieferbaren Trail-Datensatz. Kein Backlog — Kandidaten nach Landkreis unter [`research/`](../research/README.md) / [`research/STATUS.md`](../research/STATUS.md).

Schema-Details: [`datenmodell.md`](datenmodell.md).

## Zweck

Ein Datensatz muss genug Route, Stationen, Amenities, Tags und Arten enthalten, damit die App Karte, Detail-Sheet, Eignung und Arten-Carousel sinnvoll füllt — ohne Placeholder-Lücken.

## Referenz

**Goldstandard:** [`assets/seed/trail.json`](../assets/seed/trail.json) — *Von Moor zu Moor* (`typ: moor`).

Weitere HAVE-Seeds (gleiche Pipeline):

| Seed | ID | `typ` |
|---|---|---|
| `trail.json` | `von-moor-zu-moor` | `moor` |
| `heide-erlebnisweg.json` | … | `wald` |
| `naturerlebnisraum-spo.json` | `naturerlebnisraum-spo` | `kueste` |
| `erlebnisrundweg-friedrichskoog.json` | `erlebnisrundweg-friedrichskoog` | `kueste` |
| `raddusch.json` | … | `moor` |
| `rauener-berge.json` | … | `wald` |
| `lehde.json` | … | `spreewald` |
| `ravensberge.json` | … | `wald` |
| `wupatz.json` | … | `wald` |
| `libellen-wasserspielplatz-wittstock.json` | `libellen-wasserspielplatz-wittstock` | `wasserspielplatz` (`form: flaeche`) |
| `harzungspfad.json` | `harzungspfad` | `walderlebnispfad` |
| `kinderwald-maerkisch-buchholz.json` | `kinderwald-maerkisch-buchholz` | `waldspielplatz` (`form: flaeche`) |
| `kinderbauernhof-pinke-panke.json` | `kinderbauernhof-pinke-panke` | `kinderbauernhof` (`form: flaeche`) |
| `arboretum-dreetz.json` | `arboretum-dreetz` | `naturerlebnis` (`form: flaeche`) |
| `natter-pfad-goyatz.json` | `natter-pfad-goyatz` | `walderlebnispfad` |
| `erlebe-bruder-wald.json` | `erlebe-bruder-wald` | `walderlebnispfad` |
| `baumkronenpfad-hainich.json` | `baumkronenpfad-hainich` | `erlebniswald` (`eintritt: true`) |
| `archaeologischer-wanderpfad-fischbek.json` | `archaeologischer-wanderpfad-fischbek` | `wald` |
| `rittbrookpfad.json` | `rittbrookpfad` | `walderlebnispfad` |
| `naturwaldpfad.json` | `naturwaldpfad` | `walderlebnispfad` |
| `waldhusen.json` | `waldhusen` | `wald` |
| `schwartautal.json` | `schwartautal` | `walderlebnispfad` |
| `oher-graeberfeld.json` | `oher-graeberfeld` | `wald` |
| `naturerlebnis-grabau.json` | `naturerlebnis-grabau` | `walderlebnispfad` |
| `naturerlebnispfad-eutin.json` | `naturerlebnispfad-eutin` | `naturerlebnis` |
| `kollhorst.json` | `kollhorst` | `naturerlebnis` (`form: flaeche`) |
| `untereider.json` | `untereider` | `naturerlebnis` |
| `baumwipfelpfad-saarschleife.json` | `baumwipfelpfad-saarschleife` | `erlebniswald` (`eintritt: true`) |
| `baumwipfelpfad-schwarzwald.json` | `baumwipfelpfad-schwarzwald` | `erlebniswald` (`eintritt: true`) |
| `everstorfer-forst.json` | `everstorfer-forst` | `wald` |
| `moislinger-aue.json` | `moislinger-aue` | `naturerlebnis` (`form: flaeche`) |
| `lehrpfad-pflanzenschutz-schwentinental.json` | `lehrpfad-pflanzenschutz-schwentinental` | `naturerlebnis` |
| `naturerlebnispfad-ellerbek.json` | `naturerlebnispfad-ellerbek` | `naturerlebnis` |
| `naturerlebnisweg-ploener-seeufer.json` | `naturerlebnisweg-ploener-seeufer` | `naturerlebnis` |
| `waldlehrpfad-silberbergen.json` | `waldlehrpfad-silberbergen` | `wald` |

Build: Config unter `tools/trails/<id>.json` → `tools/build_seed.py` → Seed (Linien) bzw. direkter Flächen-Seed mit `area[]`. Optional Supabase via `tools/seed_supabase.py` / `seed_sql.py`.

## Pflicht / Soll

### Pflicht (Go-Bar)

| Feld / Regel | Quelle |
|---|---|
| Trail-Metadaten: `id`, `name`, `typ`, Kurz-/Langtext, Länge, Dauer, Rundkurs, Markierung, Betreiber, Region, Anreise, `startName` | Domain `Trail` |
| Geometrie: `form: linie` → `route[]` ohne kaputte Sprünge; `form: flaeche` → `area[]` ≥3, `laengeKm=0`, `rundkurs=false` | `validate_seeds.py` |
| ≥ **3** Stationen mit GPS + `titel` + `thema` + `kurztext` | `build_seed.py` / Research-Go |
| Stationen: `reihenfolge`, `km`, `erlebnisse[]` (Katalog-Keys), `barrierefrei` | Domain `Station` |
| `amenities[]` im Korridor der Route (Katalog-`kategorie`) | Amenity-Katalog |
| `tags[]` redaktionell (Katalog); Auto-Tags aus Amenities ok | `tagKatalog` |
| `arten[]` auflösbar gegen `assets/seed/species.json` | `resolve_arten` / Validator |
| Species-`content` gemäß [`tools/SPECIES_CONTENT.md`](../tools/SPECIES_CONTENT.md) | Validator |

### Soll (App-Qualität)

- Steckbrief an relevanten Stationen (`Steckbrief`)
- Website / Betreiber-Flyer als Quellenanker
- Amenities: mindestens Parkplatz oder WC wenn real vorhanden (nicht erfinden)
- Erlebnisse pro Station, wo physisch vorhanden (`tafel`, `quiz`, `steg`, …)
- Rundkurs: Schluss nahe Start (Validator warnt)

## Go / No-Go

| | |
|---|---|
| **Go** | Route + ≥3 Stationen (GPS/Titel/Thema/Kurztext) + `python3 tools/validate_seeds.py` grün + Arten auflösbar |
| **No-Go** | Nur OSM-Name ohne Stationstexte; naiver Rel-Stitch als alleinige Wahrheit ohne Betreiber-Abgleich; Validator rot; Species ohne Spec-`content` |

Pipeline-Gates:

1. `tools/build_seed.py` — bricht ab bei &lt;3 Stationen mit Koordinaten
2. `tools/validate_seeds.py` — Schema, Kataloge (`typ`/`tags`/`erlebnisse`/`amenities`), Geometrie, Arten, Species-Content
3. Research-Go-Bar (pro Trail-Research, z. B. `research/Länder/<Land>/<Unterland>/<Blatt>/*.research.md`)

## Drei-Ebenen-Strategie

```
OSM (Relation / Ways / POIs)
    → Betreiber-PDF / Website / Flyer (Stationsnamen, Themen, Reihenfolge)
        → Feldcapture (GPS, Fotos, Barriere, fehlende Tafeln)
```

1. **OSM** — Geometrie, Amenities, ggf. Information-Boards (`tools/osm/`, Overpass / OSM API).
2. **Betreiber** — verbindliche Stationenliste und Texte; PDF oft besser als OSM-POIs allein.
3. **Feld** — Lücken schließen, wenn OSM+PDF nicht reichen (Capture-Workflow im Repo).

## Quellen im Repo

| Was | Wo |
|---|---|
| Seeds | `assets/seed/*.json`, `species.json` |
| Trail-Configs | `tools/trails/*.json` |
| Research / Kandidaten | [`research/`](../research/README.md), [`research/STATUS.md`](../research/STATUS.md) |
| OSM-Roh | `tools/osm/<id>_*.json` |
| Build / Validate | `tools/build_seed.py`, `tools/validate_seeds.py` |
| Species-Spec | `tools/SPECIES_CONTENT.md` |
| Domain | `lib/features/trail/domain/`, `lib/features/species/domain/` |
| Kataloge | `lib/shared/catalogs/icon_catalog.dart` |
| Datenmodell | [`docs/datenmodell.md`](datenmodell.md) |
