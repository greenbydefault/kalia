# ADR 0002 — DB ist Master, Admin-CMS schreibt

## Status

Accepted

## Context

Der Katalog (Trails, Arten, Merkmale, Orte, Hero-Bilder, Audio) entstand aus Seed-JSON im Repo (`tools/trails/*.json` → `build_seed.py` → `assets/seed/*.json` → `seed_supabase.py`). Inhalte lassen sich so nur in Cursor oder direkt in der DB bearbeiten. ADR 0001 hält den Katalog für die App read-only; das gilt weiter für die App, nicht für das CMS.

## Decision

1. **Die Datenbank ist Master.** Seed-JSON bleibt Erstimport und Fallback (Offline, Tests). `seed_supabase.py` legt standardmäßig nur neue Trails, Arten und Merkmale an und überschreibt nichts (`--force` für bewusstes Überschreiben). `export_catalog.py` zieht den DB-Stand zurück in `assets/seed/*.json`.
2. **Schreiben nur über `is_catalog_editor()`**: Rolle Admin **und** Session-Level `aal2` (TOTP). Der Repo ist öffentlich und der Test-Admin hat ein bekanntes Passwort; Passwort allein darf nichts schreiben. Kein `service_role` im Client.
3. **Admin-CMS ist ein eigenes Web-Target** (`lib/admin/admin_main.dart`, eigenes Vercel-Projekt, `X-Robots-Tag: noindex`). Es teilt Theme, Supabase-Client und Community-Provider mit der App, wird aber separat gebaut und deployt. Später zieht es in eine eigene Flutter-App um; `lib/admin/` hat dafür keine Abhängigkeit auf App-Navigation.
4. **Generischer Editor**: `CollectionSpec` / `FieldSpec` / `EditorBlock` beschreiben einen Katalog-Ordner; Beziehungen laufen über `RelationBackend` (Join-Tabelle, Array vorwärts, Array rückwärts). Neues Feld = Eintrag in der Spec.
5. **`trail_species` ist Master für Trail ↔ Art.** Ein Trigger leitet `trails.arten` (Namen) daraus ab, weil `SpeciesResolver` noch über Namen auflöst.
6. **Medien**: Hero-Bilder als `images`-Zeilen (`source=official`) im Bucket `trail-images`; Art-Bild und Audio im Bucket `catalog-media`, in `species.image_path` / `audio_path` als `storage:`-Pfad. Die App löst `storage:` über `MediaUrl` auf; gebündelte Assets bleiben Fallback.

## Consequences

- Rollout-Reihenfolge: Migrationen 0028–0030 → Admin deployen und Konto mit TOTP einrichten → App-Release mit Remote-Hero/-Audio → erst dann `upload_catalog_media.py`. Die App fragt neue `images`-Spalten defensiv ab (Fallback bei fehlender Migration).
- Seeds und DB können auseinanderlaufen; vor jedem `build_seed.py`-Lauf `export_catalog.py` ausführen.
- Geometrie (OSM-Route, Stationskoordinaten) und Fahrzeiten (`trail_pois`) bleiben Pipeline; das CMS legt keine Trails an und zeigt `trail_pois` nur lesend.
- Jede neue Katalog-Tabelle braucht Editor-Policies analog `0028_catalog_write.sql`.
