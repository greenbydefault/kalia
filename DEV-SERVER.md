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

## Admin-CMS

Eigener Einstieg `lib/admin/admin_main.dart`, **immer mit Supabase-Defines** (ohne sie zeigt die Seite nur einen Hinweis):

```bash
cd lehrpfad_app
flutter run -d chrome -t lib/admin/admin_main.dart --web-port=8081 \
  --dart-define=SUPABASE_URL=<URL> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<KEY>
```

- Port 8081, damit die App parallel auf 8080 läuft.
- Login: Admin-Konto, danach TOTP (Schreiben braucht `aal2`). Beim ersten Mal führt die Seite durch die Einrichtung.
- Schreibt in die **Live-DB**. Migrationen `0028`–`0030` müssen eingespielt sein, sonst scheitern Speichern, Pool und Upload.
- Build/Deploy: `bash lehrpfad_app/vercel-build-admin.sh`, Vercel-Projekt mit Root Directory `lehrpfad_app/admin_deploy` ([`lehrpfad_app/docs/golive/vercel.md`](lehrpfad_app/docs/golive/vercel.md)).

## Android-Testgerät (USB)

Einmalig (Mac): `openjdk@17` + `android-commandlinetools` via Homebrew, SDK in `/opt/homebrew/share/android-commandlinetools`, `flutter doctor` muss Android grün zeigen. Das Skript setzt `JAVA_HOME`/`ANDROID_HOME` selbst.

Einmalig (Handy): Einstellungen → Über das Telefon → 7x auf Build-Nummer tippen → Entwickleroptionen → USB-Debugging an → Kabel, Dialog „Diesem Computer vertrauen“ bestätigen. Prüfen: `adb devices` zeigt `device`.

Supabase-Werte: `lehrpfad_app/.env.android` (gitignored, Vorlage `.env.example`).

```bash
cd lehrpfad_app
tool/android_test.sh          # Release-APK bauen + per adb installieren
tool/android_test.sh build    # nur bauen
tool/android_test.sh run      # flutter run --release mit Live-Logs
adb logcat -s flutter         # Logs der installierten App
```

- APK: `lehrpfad_app/build/app/outputs/flutter-apk/app-release.apk`, auch per AirDrop/Drive aufs Handy ziehbar (Installation aus unbekannter Quelle erlauben).
- `android/build.gradle.kts` patcht `flutter_avif_android` (doppelte Plugin-Klasse, compileSdk 31). Beim Plugin-Update prüfen, ob der Patch noch nötig ist.
- Build braucht mehrere GB freien Platz (`lehrpfad_app/build` liegt in Dropbox, ruhig mit `flutter clean` aufräumen). Bei „Cannot lock execution history“: `cd android && ./gradlew --stop`.
- Signiert mit Debug-Key, **nicht** für den Play Store.
- Die Trail-Bilder (~211 MB) sind gebündelt, der APK ist entsprechend groß, erster Build dauert.
- Launcher-Icon ist ein Platzhalter (`tool/make_placeholder_icon.py`). Echtes Logo: `assets/icons/app/icon_placeholder.png` und `icon_placeholder_fg.png` ersetzen, dann `dart run flutter_launcher_icons`.

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
