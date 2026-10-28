# ADR 0004: Content-Import-Pipeline

## Status

Accepted. Ergänzt ADR 0002 und ADR 0003.

## Context

Neue Pfade kommen als Dossier (Vorlage v3, ZIP je Pfad) mit Quellen, Bildern und optional GPX. Von Hand ins Seed-JSON zu übertragen ist langsam und fehleranfällig. Die Redaktion (Marc) soll prüfen und freigeben, ohne Repo.

## Decision

1. **Parser statt KI.** Das Dossier wird deterministisch über die Spalte „Supabase“ gelesen (Anker = Feldname). KI nur als Rückfall (`normalize_with_ai`, Kürzungsvorschlag), Default `claude-haiku-5-5`, abschaltbar.
2. **Worker außerhalb der App.** Python-Prozess mit `service_role` (`import_worker/`), pollt `import_jobs`. Der Key kommt nie in die App.
3. **Entwurf = `sichtbar=false`.** Der Worker schreibt den Trail unsichtbar. „Anlegen“ im CMS ruft `import_publish` (setzt `sichtbar=true`), 10 s Rückgängig im UI, später `import_unpublish`.
4. **Meldungen mit Schweregrad.** `hart` (blockiert), `uebersteuerbar` (blockiert bis Override mit Begründung), `warnung`. Texte in `messages.json` (was / warum / wie), geteilt zwischen Worker und Flutter.
5. **Review im Trails-Editor.** Split-Screen (Quelle links, Editor rechts, unter 1000 px Tabs). Jedes Feld zeigt seinen Zustand (Fehler, Warnung, Sperre, ok). Änderungen werden nach dem Autosave neu geprüft (Job `validate`, 1,8 s Debounce).
6. **Re-Import sperrt, überschreibt nicht.** Felder, die das CMS geändert hat, stehen in `locked_fields`. Ein erneuter Import erzeugt einen `vorschlag`-Job; die Redaktion übernimmt Felder einzeln oder gesamt.
7. **Duplikate.** Gleicher Slug/Name im Katalog → Dialog (Ist neu / Zusammenführen / Verwerfen). „Zusammenführen“ ist vorerst: Import verwerfen (mit Grund) und den bestehenden Trail öffnen. Kein Feld-Merge.

## Consequences

- Lehrpfade mit vielen Halten gehen 0,3 bis 4,7 km/h. Die Tempo-Plausibilität liegt deshalb bei 0,2 bis 8,0 km/h (Pilot, 85 Seeds).
- `lebensraeume` leer ist Warnung, kein Fehler (Spielplatz, Geopfad).
- `markierung` ist hart Pflicht. Flächen ohne Markierung brauchen einen Eintrag wie „keine“, oder die Regel wird gelockert.
- Der Worker braucht auf dem Host `tools/osm/` (OSM-Rückfall) und `SUPABASE_SERVICE_KEY`.
- Karte: Position wird per Klick gesetzt, kein Pin-Drag.
