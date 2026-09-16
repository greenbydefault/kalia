---
name: have-trail
description: >-
  Ships a HAVE trail from Trello OPEN-GO to a Vercel-ready seed (OSM, config, photos, Supabase, Audio card).
  Use when the user asks to pick, prepare, or make live a Track/Trail/Pfad from Trello, or to add a HAVE-Seed.
---

# HAVE

cwd: `lehrpfad_app/`. `research/` und `tools/` (Configs, OSM, `build_seed.py`) sind gitignored — Glob leer. `Read`/`ls` auf den Pfad.

Store-Launch ist `docs/golive/GRUND.md`. Dieser Skill ist Katalog-HAVE, Live = `git push github` laut `docs/golive/vercel.md`.

## 1. Auswahl

Regionen-Karte der genannten Region. Nimm **OPEN-GO**. Pool = Regionen, nicht Arbeit-Inbox.

Done: `<id>` + Blatt-Pfad, Status OPEN, nicht HAVE/MAYBE.

## 2. Research

Read:

- `lehrpfad_app/research/README.md`
- `lehrpfad_app/research/Länder/…/<Blatt>/_kandidaten.md`
- `lehrpfad_app/research/Länder/…/<Blatt>/<id>.research.md`

Done: Rel-ID oder „keine Rel“, `typ`/`form`, Stationstitel ≥3.

## 3. OSM

Rel-ID in Research → `Read lehrpfad_app/tools/fetch_osm.sh`, gleiches Rel-Muster (`_rel.json`, `_pois.json`, `_amenities.json`).

Keine Rel → `_route.json` + BBox-POIs wie `tools/osm/everstorfer-forst_*.json` / `oher-graeberfeld_*.json`.

Done: Dateien unter `tools/osm/<id>_*.json`.

## 4. Config

Shape kopieren, Inhalt neu:

- Linie: `tools/trails/waldhusen.json`
- Fläche: `tools/trails/kollhorst.json`

Ziel: `tools/trails/<id>.json`.

Done: Keys/Reihenfolge wie Nachbar, `id`/`stationen`/`route`-Anker gesetzt.

## 5. Seed

```
python3 tools/build_seed.py tools/trails/<id>.json
```

Done: `assets/seed/<id>.json` existiert.

## 6. arten[]

Namen gegen `assets/seed/species.json` auflösen (Aliases). Neue Art nur wenn der Name fehlt — dann `Read tools/SPECIES_CONTENT.md` (Gerät: `GERAETE_CONTENT.md`).

Done: jeder Eintrag löst auf.

## 7. hoertext

`Read tools/TRAIL_HOERTEXT.md`. Dann `hoertext` in die Config, Seed neu bauen wenn nötig.

Done: Feld gesetzt, Spec-Limit.

## 8. Validate

```
python3 tools/validate_seeds.py
```

Exit 0. Rot → Seed/Config/`arten[]`, nicht das Script.

## 9. Hero

`credits.json`-Shape: `assets/images/trails/waldhusen/credits.json`.

Ziel: `assets/images/trails/<id>/credits.json` + Quell-JPGs.

```
dart run tool/ingest_images.dart <id>
```

Done: drei `.avif` pro File, `file` in credits bleibt der Slug.

## 10. Registry

- `lib/features/trail/data/seed_trail_repository.dart` → `_seedPaths`
- `pubspec.yaml` → `- assets/images/trails/<id>/`

Done: beide Zeilen da.

## 11. Supabase

`SUPABASE_URL` + `SUPABASE_SERVICE_KEY` gesetzt → `python3 tools/seed_supabase.py assets/seed/<id>.json`.

Sonst: `Read tools/seed_supabase.py`, gleicher Upsert über MCP `user-supabase-ako`.

Done: Trail-Row + Stationen + amenities + trail_species.

## 12. Trello

- Regionen: Item **HAVE**
- Audio: 1 Karte = 1 Seed, Checkliste Hörtext · Sound. Haken nach Commit.
- Arbeit: `[Kalia · Trails] <id>`. Marketing-Datei nur bei erstem Pin im Bundesland oder wenn User es sagt.

Done: Regionen + Audio stehen. Checks ungehabt bis Commit.

## 13. Live

Push auf `github` laut `docs/golive/vercel.md`. Nicht dieser Skill’s Job, außer User sagt push.

## Branch

- Nearby 20 km (Camping 5 km) → `assets/seed/pois.json` + `python3 tools/seed_pois.py`
- Go-Bar unklar → `docs/traumdatensatz.md`
- Lizenzfeld nach Nachbar-credits unklar → `docs/datenmodell.md` TrailBild
- Stimme nach TRAIL_HOERTEXT unklar → `docs/audio/GRUND.md`
