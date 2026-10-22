#!/bin/bash
# package_artifacts.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration und Pfade
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(realpath "$SCRIPT_DIR/../..")"
PROJECT_ROOT="$(realpath "$ROOT/..")"
OUTPUT_DIR=""
ANDROID_APK=""
ANDROID_SOURCE="$PROJECT_ROOT/mobile/android"
IOS_SOURCE="$PROJECT_ROOT/mobile/ios"
NATIVE_SHARED_SOURCE="$PROJECT_ROOT/mobile/shared"

# Ausschlussliste fuer Dateien und Verzeichnisse
EXCLUDED_PARTS=("__pycache__" ".gradle" ".kotlin" ".cxx" "build" "DerivedData" "xcuserdata" "Pods")
EXCLUDED_SUFFIXES=(".pyc" ".aar")

# Funktion zum Hinzufuegen eines Verzeichnisbaums zu einem ZIP-Archiv
add_tree() {
  local archive="$1"
  local source="$2"
  local prefix="${3:-}"

  # Finde alle Dateien rekursiv im Quellverzeichnis
  find "$source" -type f | sort | while read -r file; do
    # Pruefe ob Datei in ausgeschlossenen Pfaden liegt
    skip=false
    for part in "${EXCLUDED_PARTS[@]}"; do
      if [[ "$file" == *"/$part/"* ]] || [[ "$file" == *"/$part" ]]; then
        skip=true
        break
      fi
    done

    # Pruefe auf ausgeschlossene Dateiendungen
    if [ "$skip" = false ]; then
      for suffix in "${EXCLUDED_SUFFIXES[@]}"; do
        if [[ "$file" == *"$suffix" ]]; then
          skip=true
          break
        fi
      done
    fi

    if [ "$skip" = true ]; then
      continue
    fi

    # Berechne relativen Pfad
    relative_path="${file#$source/}"
    archive_path="$prefix/$relative_path"

    # Setze Berechtigungen: 755 fuer gradlew, sonst 644
    chmod_value="644"
    if [[ "$(basename "$file")" == "gradlew" ]]; then
      chmod_value="755"
    fi

    # Fuege Datei zum ZIP hinzu mit festem Datum (1980-01-01)
    zip --quiet --compression-method deflate --compression-level 9 \
        --external-attr "0x${chmod_value}0000" \
        --absolute-timestamps=no \
        --timestamp 315532800 \
        "$archive" "$file"
    
    # Umbenennen im Archiv funktioniert nicht direkt mit zip-Befehl,
    # daher verwenden wir eine temporaere Struktur
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    mkdir -p "$temp_dir/$(dirname "$archive_path")"
    cp "$file" "$temp_dir/$archive_path"
    (
      cd "$temp_dir"
      zip --quiet --compression-method deflate --compression-level 9 \
          --external-attr "0x${chmod_value}0000" \
          --absolute-timestamps=no \
          --timestamp 315532800 \
          -u "$archive" "$archive_path"
    )
    rm -rf "$temp_dir"
    trap - EXIT
  done
}

# Argumente parsen
while [[ $# -gt 0 ]]; do
  case $1 in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --android-apk)
      ANDROID_APK="$2"
      shift 2
      ;;
    --android-source)
      ANDROID_SOURCE="$2"
      shift 2
      ;;
    --ios-source)
      IOS_SOURCE="$2"
      shift 2
      ;;
    --native-shared-source)
      NATIVE_SHARED_SOURCE="$2"
      shift 2
      ;;
    *)
      echo "Unbekanntes Argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$OUTPUT_DIR" ]]; then
  echo "--output-dir ist erforderlich" >&2
  exit 1
fi

# Ausgabeverzeichnis erstellen
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"

# Version aus manifest.json lesen
VERSION=$(jq -r '.version' < "$ROOT/browser-extension/manifest.json")

# Artefakte definieren
EXTENSION_ZIP="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION.zip"
PLUGIN_ZIP="$OUTPUT_DIR/tiktok-live-companion-plugin-$VERSION.zip"
SERVICE_ZIP="$OUTPUT_DIR/tiktok-live-companion-service-$VERSION.zip"
IOS_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-ios-$VERSION-source.zip"
ANDROID_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION-source.zip"
ANDROID_APK_FILE="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION.apk"
EXTENSION_DIR="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION"
CHECKSUM_FILE="$OUTPUT_DIR/tiktok-live-companion-$VERSION-SHA256.txt"

# Extension-Verzeichnis vorbereiten
if [[ "$(realpath "$(dirname "$EXTENSION_DIR")")" != "$OUTPUT_DIR" ]]; then
  echo "Refusing to package outside the requested output directory" >&2
  exit 1
fi

rm -rf "$EXTENSION_DIR"
cp -r "$ROOT/browser-extension" "$EXTENSION_DIR"
cp -r "$ROOT/companion-service" "$EXTENSION_DIR/companion-service"

cat > "$EXTENSION_DIR/Sprachdienst-reparieren.cmd" << 'EOF'
@echo off
call "%~dp0companion-service\Sprachdienst-reparieren.cmd"
EOF

jq -n --arg version "$VERSION" '{
  name: "tiktok-live-companion-extension-package",
  private: true,
  version: $version,
  scripts: {
    setup: "npm --prefix companion-service run setup --",
    start: "npm --prefix companion-service start",
    test: "npm --prefix companion-service test"
  }
}' > "$EXTENSION_DIR/package.json"

# Extension ZIP erstellen
zip -rq9 "$EXTENSION_ZIP" "$EXTENSION_DIR"

# Plugin ZIP erstellen
TEMP_PLUGIN_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_PLUGIN_DIR"' EXIT
mkdir -p "$TEMP_PLUGIN_DIR/tiktok-live-companion"
cp -r "$ROOT"/* "$TEMP_PLUGIN_DIR/tiktok-live-companion/"
(
  cd "$TEMP_PLUGIN_DIR"
  zip -rq9 "$PLUGIN_ZIP" .
)
rm -rf "$TEMP_PLUGIN_DIR"
trap - EXIT

# Service ZIP erstellen
zip -rq9 "$SERVICE_ZIP" "$ROOT/companion-service"

# Quellpfade validieren
IOS_SOURCE_REALPATH="$(realpath "$IOS_SOURCE")"
ANDROID_SOURCE_REALPATH="$(realpath "$ANDROID_SOURCE")"
if [[ ! -d "$IOS_SOURCE_REALPATH" ]] || [[ ! -d "$ANDROID_SOURCE_REALPATH" ]]; then
  echo "--ios-source and --android-source must point to existing source directories" >&2
  exit 1
fi

NATIVE_SHARED_REALPATH="$(realpath "$NATIVE_SHARED_SOURCE")"
if [[ ! -f "$NATIVE_SHARED_REALPATH/native/tlc_peak_limiter.h" ]]; then
  echo "Shared native limiter source is required for both mobile source packages" >&2
  exit 1
fi

# iOS Source ZIP erstellen
TEMP_IOS_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_IOS_DIR"' EXIT
mkdir -p "$TEMP_IOS_DIR/TikTokLiveCompanion-iOS"
cp -r "$IOS_SOURCE_REALPATH"/* "$TEMP_IOS_DIR/TikTokLiveCompanion-iOS/"
mkdir -p "$TEMP_IOS_DIR/shared"
cp -r "$NATIVE_SHARED_REALPATH"/* "$TEMP_IOS_DIR/shared/"
(
  cd "$TEMP_IOS_DIR"
  zip -rq9 "$IOS_SOURCE_ZIP" .
)
rm -rf "$TEMP_IOS_DIR"
trap - EXIT

# Android Source ZIP erstellen
TEMP_ANDROID_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_ANDROID_DIR"' EXIT
mkdir -p "$TEMP_ANDROID_DIR/TikTokLiveCompanion-Android"
cp -r "$ANDROID_SOURCE_REALPATH"/* "$TEMP_ANDROID_DIR/TikTokLiveCompanion-Android/"
mkdir -p "$TEMP_ANDROID_DIR/shared"
cp -r "$NATIVE_SHARED_REALPATH"/* "$TEMP_ANDROID_DIR/shared/"
(
  cd "$TEMP_ANDROID_DIR"
  zip -rq9 "$ANDROID_SOURCE_ZIP" .
)
rm -rf "$TEMP_ANDROID_DIR"
trap - EXIT

# Android APK kopieren falls angegeben
if [[ -n "$ANDROID_APK" ]]; then
  ANDROID_APK_RESOLVED="$(realpath "$ANDROID_APK")"
  if [[ ! -f "$ANDROID_APK_RESOLVED" ]] || [[ "${ANDROID_APK_RESOLVED##*.}" != "apk" ]]; then
    echo "--android-apk must point to an existing APK" >&2
    exit 1
  fi
  if [[ "$ANDROID_APK_RESOLVED" != "$(realpath "$ANDROID_APK_FILE")" ]]; then
    cp "$ANDROID_APK_RESOLVED" "$ANDROID_APK_FILE"
  fi
fi

# Checksummen berechnen
ARTIFACTS=(
  "$EXTENSION_ZIP"
  "$PLUGIN_ZIP"
  "$SERVICE_ZIP"
  "$IOS_SOURCE_ZIP"
  "$ANDROID_SOURCE_ZIP"
)

if [[ -f "$ANDROID_APK_FILE" ]]; then
  ARTIFACTS+=("$ANDROID_APK_FILE")
fi

CHECKSUM_LINES=()
for artifact in "${ARTIFACTS[@]}"; do
  digest=$(sha256sum "$artifact" | cut -d' ' -f1)
  filename=$(basename "$artifact")
  CHECKSUM_LINES+=("$digest  $filename")
done

printf '%s\n' "${CHECKSUM_LINES[@]}" > "$CHECKSUM_FILE"

# JSON-Ausgabe generieren
jq -n \
  --arg extension_dir "$(realpath "$EXTENSION_DIR")" \
  --arg extension_zip "$(realpath "$EXTENSION_ZIP")" \
  --arg plugin_zip "$(realpath "$PLUGIN_ZIP")" \
  --arg service_zip "$(realpath "$SERVICE_ZIP")" \
  --arg ios_source_zip "$(realpath "$IOS_SOURCE_ZIP")" \
  --arg android_source_zip "$(realpath "$ANDROID_SOURCE_ZIP")" \
  --arg android_apk "$([[ -f "$ANDROID_APK_FILE" ]] && realpath "$ANDROID_APK_FILE" || echo null)" \
  --arg checksum_file "$(realpath "$CHECKSUM_FILE")" \
  --arg version "$VERSION" \
  '{
    extension_dir: $extension_dir,
    extension_zip: $extension_zip,
    plugin_zip: $plugin_zip,
    service_zip: $service_zip,
    ios_source_zip: $ios_source_zip,
    android_source_zip: $android_source_zip,
    android_apk: $android_apk,
    checksum_file: $checksum_file,
    version: $version
  }'
