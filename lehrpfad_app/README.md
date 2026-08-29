# Lehrpfad-App

Digitale Begleit-App für Naturlehrpfade: interaktive Karte mit Trails und Stationen,
GPS-geführtes Walk-Tracking mit Auto-Abschluss, Arten-Sammlung („Gesehen"-Markierungen
mit Audio-Steckbriefen), persönliche Listen und Community-Bilder/-Bewertungen.

Offline-first: Bookmarks, Completions, Walks, Listen und Sichtungen funktionieren ohne
Login und Netz; eine Sync-Engine (`lib/core/sync/`) gleicht bei Login mit Supabase ab.

## Lokal starten

Siehe [DEV-SERVER.md](../DEV-SERVER.md). Kurzfassung:

```bash
flutter run -d web-server --web-port=8080
```

Ohne Defines läuft die App im Seed-/Offline-Modus. Mit Live-Daten:

```bash
flutter run -d web-server --web-port=8080 \
  --dart-define=SUPABASE_URL=… \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=…
```

## Tests & Analyse

```bash
flutter test
flutter analyze
```
