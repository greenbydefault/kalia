#!/usr/bin/env bash
# Flutter-Web-Build für Vercel.
# Env (Vercel Project Settings, alle Environments):
#   SUPABASE_URL
#   SUPABASE_PUBLISHABLE_KEY
# Optional: FLUTTER_VERSION (Default: 3.44.9)
#
# Origin → Vercel (Pro/Team, Hobby geht nicht):
#   1. https://vercel.com/new → Continue with Origin
#   2. oder Origin-Repo → Apps → Vercel
#   3. Env-Vars setzen, Deploy
set -euo pipefail

cd "$(dirname "$0")"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.9}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter-sdk}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics --enable-web
flutter precache --web
flutter pub get

defines=()
if [[ -n "${SUPABASE_URL:-}" ]]; then
  defines+=(--dart-define="SUPABASE_URL=${SUPABASE_URL}")
fi
if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  defines+=(--dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}")
fi

flutter build web --release --base-href / "${defines[@]}"
