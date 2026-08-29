# DEV-SERVER – Lehrpfad-App lokal starten & testen

Kurz-Trigger im Chat: **„Server starten“** → diesen Workflow befolgen.

Das ist eine **Flutter**-App (kein `npm run dev`). Equivalent: `flutter run`.

## Arbeitsverzeichnis

```bash
cd lehrpfad_app
```

Absoluter Pfad:

`/Users/olivermackeldanz/Dropbox/greenbydefault/Gewerbe/Kunden/Ako/lehrpfad_app`

## Vor dem Start

1. Prüfen, ob schon ein `flutter run` läuft oder Port 8080/8081 belegt ist.
2. Wenn ja: im alten Terminal `q` (Quit) oder anderen Port nutzen (z. B. `--web-port=8081`).

## Standard-Start (Browser-URL)

```bash
cd lehrpfad_app
flutter run -d web-server --web-port=8080
```

Im Browser öffnen: **http://localhost:8080**

Warten bis im Terminal steht: `lib/main.dart is being served at http://localhost:…`

## Chrome direkt

```bash
cd lehrpfad_app
flutter run -d chrome
```

## Mit Supabase (Live-Daten)

Dieselben Befehle, plus Dart-Defines:

```bash
flutter run -d web-server --web-port=8080 \
  --dart-define=SUPABASE_URL=<URL> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<KEY>
```

- Keys **nicht** in Dateien hardcoden.
- Agent holt sie bei Bedarf über Supabase MCP **`user-supabase-ako`** (`get_project_url`, `get_publishable_keys`).
- **Ohne** Defines: App läuft gegen lokalen Seed (Offline-Entwicklung).

## Änderungen sichtbar machen

Im **selben Terminal**, in dem `flutter run` läuft:

| Taste | Wirkung |
|-------|---------|
| `r` | Hot Reload (kleine UI-Änderungen) |
| `R` | Hot Restart (größere Änderungen, State neu) |
| `q` | Server stoppen |

**Wichtig:** Browser-Hard-Refresh (`Cmd+R`) ersetzt **nicht** Flutter Hot Reload / Hot Restart.

## Agent-Checkliste bei „Server starten“

1. `DEV-SERVER.md` befolgen.
2. Arbeitsverzeichnis: `lehrpfad_app/`.
3. Alten Prozess/Port prüfen.
4. Standard: `flutter run -d web-server --web-port=8080` (mit Supabase-Defines, wenn Live-Daten gebraucht werden).
5. URL nennen (`http://localhost:8080` bzw. gewählter Port).

## Handy / öffentlich (GitHub → Vercel Hobby)

Gratis-Weg: GitHub (persönlicher Account) → Vercel Hobby. Origin bleibt nur Backup.

Klick-für-Klick: [`lehrpfad_app/docs/golive/vercel.md`](lehrpfad_app/docs/golive/vercel.md)

Kurz: Repo auf GitHub pushen → [vercel.com/new](https://vercel.com/new) **Continue with GitHub** → Env aus `.env.vercel` → Deploy.
