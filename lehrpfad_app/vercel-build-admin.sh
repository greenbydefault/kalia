#!/usr/bin/env bash
# Flutter-Web-Build des Admin-CMS (zweites Vercel-Projekt).
# Entrypoint: lib/admin/admin_main.dart. Env-Vars (Vercel Project Settings, alle Environments):
#   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
# Optional: FLUTTER_VERSION (Default: 3.44.9)
#
# Vercel-Projekt: Root Directory = lehrpfad_app/admin_deploy
# (dort liegt die vercel.json; Output = admin_deploy/public).
# Die gebündelten Trail-Fotos (~200 MB) braucht das CMS nicht, sie werden
# für den Build aus der pubspec.yaml genommen (Datei wird danach restauriert).
set -euo pipefail

cd "$(dirname "$0")"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "Fehlende Env-Vars: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY"
  exit 1
fi

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.9}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter-sdk}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  echo "Flutter $FLUTTER_VERSION nach $FLUTTER_DIR…"
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics --enable-web
flutter precache --web

cp pubspec.yaml pubspec.yaml.bak
restore() { mv -f pubspec.yaml.bak pubspec.yaml; }
trap restore EXIT

# Trail-Ordner raus, Platzhalter bleibt.
grep -v -E '^\s*- assets/images/trails/[a-z0-9-]+/\s*$' pubspec.yaml.bak > pubspec.yaml

flutter pub get
flutter build web --release --base-href / -t lib/admin/admin_main.dart \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"

rm -rf admin_deploy/public
cp -R build/web admin_deploy/public
