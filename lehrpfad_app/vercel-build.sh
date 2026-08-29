#!/usr/bin/env bash
# Flutter-Web-Build für Vercel.
# Env (Vercel Project Settings, alle Environments):
#   SUPABASE_URL
#   SUPABASE_PUBLISHABLE_KEY
# Optional: FLUTTER_VERSION (Default: 3.44.9)
#
# GitHub → Vercel Hobby (persönlicher Account, kein Org-Repo):
#   1. https://vercel.com/new → Continue with GitHub
#   2. Env-Vars setzen, Deploy
# Checkliste: lehrpfad_app/docs/golive/vercel.md
set -euo pipefail

cd "$(dirname "$0")"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "Fehlende Env-Vars. Vercel → Settings → Environment Variables:"
  echo "  SUPABASE_URL"
  echo "  SUPABASE_PUBLISHABLE_KEY"
  echo "Werte lokal in .env.vercel (nicht im Git)."
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
flutter pub get

flutter build web --release --base-href / \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
