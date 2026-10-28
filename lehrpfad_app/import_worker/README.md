# import_worker

Liest Pfad-Dossiers (Vorlage v2/v3, ZIP je Pfad), prueft sie und legt den Pfad als Entwurf
(`trails.sichtbar = false`) in Supabase an. Review und „Anlegen“ im Admin-CMS (Trails, Split-Screen).

Spec: „Content-Import-Pipeline (Pfade aus Master-Template)“. Plan: Cursor-Plan `content-import-pipeline`.

## Einrichten

```bash
python3 -m venv ~/.venvs/kalia-import          # ausserhalb von Dropbox
~/.venvs/kalia-import/bin/pip install -r import_worker/requirements.txt
export SUPABASE_URL="https://<projekt>.supabase.co"
export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App
export ANTHROPIC_API_KEY="..."                      # optional, nur fuer den KI-Rueckfall
```

Alle Befehle aus `lehrpfad_app/`:

```bash
python3 -m import_worker check  <ordner|zip>        # nur parsen und pruefen, schreibt nichts
python3 -m import_worker enqueue <ordner|zip> ...   # Batch + Jobs anlegen, Original nach imports/
python3 -m import_worker run [--once]                # Poll-Schleife (Parallelitaet 5)
python3 -m import_worker candidates research/Länder  # trail_candidates aus _kandidaten.md
python3 -m import_worker stats <batch-id>            # Meldungen x Haeufigkeit
python3 -m import_worker dossier <seed.json> <out.docx>   # Dossier aus einem Seed (Round-Trip, Tests)
python3 -m pytest import_worker/tests                # Tests
```

## Aufbau

| Datei | Aufgabe |
|---|---|
| `parse_dossier.py` | Dossier (`.docx`) → `Dossier`-Struktur, Anker = Spalte „Supabase“ |
| `lists.py` | Anhang A (feste Wertelisten) |
| `slug.py` | Slug-Regel |
| `geometry.py` | GPX/GeoJSON → `route`/`area`, Laenge, Start |
| `images.py` | `bilder/` → AVIF 480/900/2000, Hash, uuid5 |
| `rules.py` + `messages.json` | Pruefregeln mit Schweregrad, Meldungstexte (was / warum / wie) |
| `matching.py` | Arten-Abgleich, Duplikate |
| `ai.py` | `normalize_with_ai`, Kuerzungsvorschlag (nur Rueckfall) |
| `db.py` | REST/RPC/Storage mit `service_role` (nur Stdlib) |
| `pipeline.py` | Stufen eines Jobs |
| `write.py` | Entwurf schreiben, Re-Import mit Sperren |
| `worker.py` | Queue, Retries |
| `__main__.py` | CLI |

`messages.json` liest auch das Admin-CMS (Asset in `pubspec.yaml`), die Codes stehen nur dort.

## Helfer aus tools/

`tools/` ist in `.gitignore`. Diese Dateien sind per Whitelist getrackt, weil der Worker sie importiert:
`gebiet.py`, `naturraum.py`, `resolve_arten.py`, `validate_seeds.py`, `backfill_hoertext.py`
(plus die schon getrackten `seed_*.py`, `export_catalog.py`, `upload_catalog_media.py`).

## Voraussetzungen vor dem Pilot (Stand 22.10.2026, Ako-DB)

| Punkt | Stand | Befehl |
|---|---|---|
| Hoertext-Backfill | 74 von 105 Seeds haben `hoertext`, in der DB fehlen 31. Diese 31 haben auch im Seed keinen Text (kein Backfill moeglich, Texte schreibt `audio-trail`) | `python3 tools/backfill_hoertext.py` |
| Arten-Pools (`lebensraeume` leer) | offen, braucht Service-Key | `python3 tools/seed_pools.py` |
| Hero-Bilder (0 `official`-Bilder in `images`) | offen, braucht Service-Key und die Bilddateien | `python3 tools/upload_catalog_media.py` |
| Migration 0035 + 0036 | angewendet (Ako-DB) | `supabase/migrations/0035_import.sql`, `0036_import_ack.sql` |
| `trail_candidates` | 164 Zeilen aus `_kandidaten.md` | `python3 -m import_worker candidates research/Länder` |
| Worker live | **noch nie gegen die DB gelaufen**, braucht `SUPABASE_SERVICE_KEY` | `python3 -m import_worker run --once` |
| ADR 0003 | [Geometrie aus GPX](../docs/adr/0003-geometrie-optional-aus-gpx.md) | – |
| ADR 0004 | [Import-Pipeline](../docs/adr/0004-import-pipeline.md) | – |

## Pilot (offline)

```bash
python3 -m import_worker pilot -n 10      # die ersten 10 Seeds
python3 -m import_worker pilot            # alle 105
```

Jeder Seed wird zum Dossier gerendert, geparst und durch die Regeln geschickt (kein DB-Zugriff).
Stand 22.10.2026, 105 Seeds, alle ohne Absturz, Parse+Regeln 0,03 s je Seed.

| Meldung | Anteil | Einordnung |
|---|---|---|
| `BILD_FEHLT`, `QUELLE_FEHLT` | 100 % | Seeds kennen kein `images`/`trail_sources`. Kein Befund, nur Offline-Artefakt |
| `TEXT_LAENGE` | 76 % | Alt-Texte ausserhalb der Limits aus `tools/TRAIL_SCAN.md`. Hier greift der Kuerzungsvorschlag |
| `HOERTEXT_FEHLT` | 30 % | die 31 Trails ohne Hoertext (Audio-Board) |
| `LAENGE_ABWEICHUNG` | 10 % | `laengeKm` gegen Route. 11 Seeds, einzeln pruefen |
| `LEBENSRAUM_LEER` | 10 % | Spielplatz/Geopfad, laut `datenmodell.md` erlaubt, daher Warnung |
| `PFLICHT markierung` | 1 % | `plansche-plaenterwald` hat keine Markierung. Bleibt hart (Vorlage-Pflichtfeld) |

Gelernt aus dem Pilot (in Regeln eingearbeitet):

- `lebensraeume` leer war zuerst hart. `datenmodell.md` erlaubt leer, jetzt Warnung `LEBENSRAUM_LEER`.
- Tempo-Plausibilitaet (`DAUER_KMH_MIN`) lag bei 1,0 km/h und blockierte 19 von 85 Seeds. Echte Lehrpfade
  (Dauer inkl. Stationenhalte) liegen bei 0,3 bis 4,7 km/h. Jetzt 0,2 bis 8,0.

Ein Live-Pilot (10, dann 50 echte Dossiers) steht aus: keine echten Dossier-ZIPs im Repo, kein Service-Key hier.
