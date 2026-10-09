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

Struktur kopieren, Prosa nie:

- Linie: `tools/trails/waldhusen.json`
- Fläche: `tools/trails/kollhorst.json`

Von den Nachbarn nur Keys und Reihenfolge. Ihre Texte (`kurzbeschreibung`, `beschreibung`, `besuchshinweise`, `hoertext`) nicht lesen, nicht als Muster nehmen: Inventarstil, teils "du". Ziel: `tools/trails/<id>.json`, Textfelder leer starten.

`kurzbeschreibung`, `beschreibung`, `besuchshinweise`: **Skill `scan-trail` ausführen** (Rohstoff, Schreiben, `scan.py`). Einzige Textvorlage ist das Usedom-Gold in `tools/TRAIL_SCAN.md`. Stimme `docs/stimme.md`.

Done: Keys/Reihenfolge wie Nachbar, `id`/`stationen`/`route`-Anker gesetzt, `scan.py <id>` grün.

## 5. Seed

```
python3 tools/build_seed.py tools/trails/<id>.json
```

Done: `assets/seed/<id>.json` existiert.

## 6. Nearby

Orte in der Nähe sind ein globaler Katalog (`assets/seed/pois.json`). Zum Trail gehört ein Ort, wenn die **Auto-Fahrzeit** Trail-Start → Ort **höchstens 20 Min** beträgt (alle Kategorien, auch `camping`), nicht nach Kilometern. Die Zeiten liegen vorberechnet in `assets/seed/nearby_zeiten.json` (nie von Hand), die App routet nie selbst. Ohne Treffer bleibt das Accordion leer. Kuratierung und Felder: `docs/datenmodell.md` → Ort in der Nähe.

1. `python3 tools/nearby_zeiten.py --trail <id> --report` → Treffer mit Minuten lesen. Vorhandene Orte wiederverwenden, nicht duplizieren.
2. Lücken füllen aus Betreiber-Sites, OSM als Hinweis, Karte. Kategorien: `cafe`, `restaurant`, `hofladen`, `baden`, `museum`, `aktivitaet`, `camping`. Shape wie die Nachbarn in `pois.json`, `kurztext`: ein Satz Familien-Nutzen. Kandidaten nur nehmen, wenn die Familie nach dem Trail dort sinnvoll hinfährt (Café 10 km / 25 Min fällt raus).
3. Neue Orte an `pois.json` anhängen, dann `python3 tools/nearby_zeiten.py --trail <id>` (schreibt die Datei). Ein neuer Ort kann auch Nachbar-Trails treffen: bei neuen Orten einmal `python3 tools/nearby_zeiten.py --all`. Ein Ort, der im Report nicht unter 20 Min kommt, ist kein Treffer: nicht aufnehmen oder wieder entfernen.
4. `python3 tools/validate_seeds.py` (prüft auch `nearby_zeiten.json`).

Router: öffentlicher OSRM-Demo-Server (`/table`, gedrosselt, Cache `tools/osm/nearby_cache.json`). Bei Ausfall `OSRM_URL=<eigene Instanz>` setzen.

Done: `nearby_zeiten.json` hat Einträge für `<id>`, jeder neue Ort steht dort mit ≤ 1200 s. Oder Research notiert „keine erreichbare Einkehr in 20 Min" mit Prüfung (leer nur nach Prüfung).

## 7. arten[]

Skill `arten-pool`. Namen gegen `assets/seed/species.json` auflösen. Texte zu Arten und Geräten nicht in diesem Lauf (`audio-art` nur für Hörtext).

1. `lebensraeume` (1–3 Keys) und `naturraum` am Trail. Wasserspielplatz, Geo- und Steinpfad: `lebensraeume` leer.
2. `python3 tools/arten_vorschlag.py --trail <id>` — Pool-Treffer, Katalog-Lücken, optional `--gbif` (25 km, nur Plausibilität).
3. Ortsbelege aus Research/Tafel bleiben `belegt` und werden nicht vom Cap gestrichen. Stationsthema zählt als `belegt` (Amphibien-Station → Frosch aus dem passenden Pool).
4. Ziel Flora ≥ 4, Fauna ≥ 6, weich 14, hart 16. Validator warnt darunter, blockiert nicht. Nacht-Arten nur bei Thema Fledermaus/Nacht/Eule.
5. Lücke (Art im Pool, nicht im Katalog) → `tools/art_anlegen.py`, nicht von Hand. Typisch nur über den Pool, nie freihändig.

Inventar der Ortsbelege: `lehrpfad_app/docs/arten-luecken.md`.

Done: `arten[]` löst auf, `lebensraeume` und `naturraum` gesetzt, `artenNachweis` belegt|typisch, `validate_seeds.py` Exit 0.

## 8. hoertext

**Skill `audio-trail` ausführen** (Spec `tools/TRAIL_HOERTEXT.md`, Prüfung `klang.py`). `hoertext` in die Config, Seed neu bauen. Der Lesetext aus Schritt 4 ist Rohstoff, nicht Vorlage: kein Satz wörtlich übernehmen (`scan.py` prüft Wortfolgen).

Done: Feld gesetzt, `klang.py` und `scan.py <id>` grün.

## 9. Validate

```
python3 tools/validate_seeds.py
```

Exit 0. Rot → Seed/Config/`arten[]`, nicht das Script.

## 10. Hero

`credits.json`-Shape: `assets/images/trails/waldhusen/credits.json`.

Ziel: `assets/images/trails/<id>/credits.json` + Quell-JPGs.

```
dart run tool/ingest_images.dart <id>
```

Done: drei `.avif` pro File, `file` in credits bleibt der Slug.

## 11. Registry

- `lib/features/trail/data/seed_trail_repository.dart` → `_seedPaths`
- `pubspec.yaml` → `- assets/images/trails/<id>/`

Done: beide Zeilen da.

## 12. Supabase

`SUPABASE_URL` + `SUPABASE_SERVICE_KEY` gesetzt → `python3 tools/seed_supabase.py assets/seed/<id>.json`.

Sonst: `Read tools/seed_supabase.py`, gleicher Upsert über MCP `user-supabase-ako`.

`pois.json` oder `nearby_zeiten.json` geändert (Schritt 6) → zusätzlich `python3 tools/seed_pois.py --trail <id>` (bei neuen Orten ohne `--trail`): Upsert `pois`, dann `trail_pois` des Trails löschen und neu setzen. Ohne Service-Key: gleicher Ablauf über MCP `user-supabase-ako` (`delete from trail_pois where trail_id = …`, dann insert).

Done: Trail-Row + Stationen + amenities + trail_species; bei neuen Orten auch `pois`, immer `trail_pois` für `<id>`.

## 13. Trello

- Regionen: Item **HAVE**
- Audio: 1 Karte = 1 Seed, Checkliste Hörtext · Sound. Haken nach Commit.
- Arbeit: `[Kalia · Trails] <id>` ist die HAVE-Karte, vorher suchen, keine zweite anlegen. Marketing-Datei nur bei erstem Pin im Bundesland oder wenn User es sagt.

Done: Regionen + Audio stehen. Checks ungehabt bis Commit.

## 14. Live

Push auf `github` laut `docs/golive/vercel.md`. Nicht dieser Skill’s Job, außer User sagt push.

## Branch

- Go-Bar unklar → `docs/traumdatensatz.md`
- Lizenzfeld nach Nachbar-credits unklar → `docs/datenmodell.md` TrailBild
- Stimme, Wortliste (Lese- und Hörtext) → `docs/stimme.md`; Ohr-Form → `docs/audio/GRUND.md`
- Arten-Vorkommen / Lücken → `docs/arten-luecken.md`
