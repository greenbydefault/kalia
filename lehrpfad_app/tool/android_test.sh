#!/usr/bin/env bash
# Android-Testbuild (Release-APK, Debug-Key) bauen und per USB aufs Gerät.
#   tool/android_test.sh            bauen + installieren (falls Gerät da)
#   tool/android_test.sh build      nur bauen
#   tool/android_test.sh run        flutter run --release (Logs live)
# Env: lehrpfad_app/.env.android (SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY), nicht im Git.
set -euo pipefail

cd "$(dirname "$0")/.."

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

if [[ ! -f .env.android ]]; then
  echo "lehrpfad_app/.env.android fehlt (siehe .env.example)."
  exit 1
fi
set -a; source .env.android; set +a

DEFINES=(
  "--dart-define=SUPABASE_URL=${SUPABASE_URL}"
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
  "--dart-define=GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
)

mode="${1:-install}"

if [[ "$mode" == "run" ]]; then
  exec flutter run --release "${DEFINES[@]}"
fi

flutter pub get
flutter build apk --release "${DEFINES[@]}"

APK=build/app/outputs/flutter-apk/app-release.apk
echo "APK: $(pwd)/$APK ($(du -h "$APK" | cut -f1))"

if [[ "$mode" == "install" ]]; then
  if adb devices | awk 'NR>1 && $2=="device"' | grep -q .; then
    adb install -r "$APK"
    echo "Installiert. Logs: adb logcat -s flutter"
  else
    echo "Kein Gerät per USB (adb devices). APK liegt oben."
  fi
fi
