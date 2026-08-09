#!/bin/bash
# package_artifacts.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Globale Variablen
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$(dirname "$ROOT")"
EXCLUDED_PARTS="__pycache__ .gradle .kotlin build DerivedData xcuserdata"

# Funktionen
add_tree() {
    local archive="$1"
    local source="$2"
    local prefix="${3:-}"

    # Finde alle Dateien im Quellverzeichnis
    find "$source" -type f | while IFS= read -r path; do
        # Prüfe auf ausgeschlossene Teile oder Dateiendungen
        local exclude=false
        for part in $EXCLUDED_PARTS; do
            if [[ "$path" == *"$part"* ]]; then
                exclude=true
                break
            fi
        done
        if [[ "$exclude" == true ]] || [[ "${path##*.}" == "pyc" ]] || [[ "${path##*.}" == "aar" ]]; then
            continue
        fi

        # Berechne relativen Pfad
        local relative_path="${path#$source/}"
        if [[ -n "$prefix" ]]; then
            zip --quiet "$archive" "$path" -j "$prefix/$relative_path"
        else
            zip --quiet "$archive" "$path" -j "$relative_path"
        fi
    done
}

# Argumente parsen
OUTPUT_DIR=""
ANDROID_APK=""

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
        *)
            echo "Unbekanntes Argument: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Fehler: --output-dir ist erforderlich" >&2
    exit 1
fi

# Verzeichnisse erstellen
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Version aus manifest.json lesen
VERSION=$(jq -r '.version' "$ROOT/browser-extension/manifest.json")

# Dateinamen definieren
EXTENSION_ZIP="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION.zip"
PLUGIN_ZIP="$OUTPUT_DIR/tiktok-live-companion-plugin-$VERSION.zip"
SERVICE_ZIP="$OUTPUT_DIR/tiktok-live-companion-service-$VERSION.zip"
IOS_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-ios-$VERSION-source.zip"
ANDROID_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION-source.zip"
ANDROID_APK_FILE="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION.apk"
EXTENSION_DIR="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION"
CHECKSUM_FILE="$OUTPUT_DIR/tiktok-live-companion-$VERSION-SHA256.txt"

# Extension-Verzeichnis vorbereiten
if [[ "$(dirname "$EXTENSION_DIR")" != "$OUTPUT_DIR" ]]; then
    echo "Fehler: Refusing to package outside the requested output directory" >&2
    exit 1
fi

if [[ -d "$EXTENSION_DIR" ]]; then
    rm -rf "$EXTENSION_DIR"
fi

cp -r "$ROOT/browser-extension" "$EXTENSION_DIR"

# ZIP-Archive erstellen
zip -r "$EXTENSION_ZIP" "$ROOT/browser-extension" -x "*/__pycache__/*" "*/.gradle/*" "*/.kotlin/*" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*.pyc" "*.aar"

zip -r "$PLUGIN_ZIP" "$ROOT" -x "*/__pycache__/*" "*/.gradle/*" "*/.kotlin/*" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*.pyc" "*.aar"

zip -r "$SERVICE_ZIP" "$ROOT/companion-service" -x "*/__pycache__/*" "*/.gradle/*" "*/.kotlin/*" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*.pyc" "*.aar"

zip -r "$IOS_SOURCE_ZIP" "$PROJECT_ROOT/mobile/ios" -x "*/__pycache__/*" "*/.gradle/*" "*/.kotlin/*" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*.pyc" "*.aar"

zip -r "$ANDROID_SOURCE_ZIP" "$PROJECT_ROOT/mobile/android" -x "*/__pycache__/*" "*/.gradle/*" "*/.kotlin/*" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*.pyc" "*.aar"

# Android APK kopieren, falls angegeben
if [[ -n "$ANDROID_APK" ]]; then
    if [[ ! -f "$ANDROID_APK" ]] || [[ "${ANDROID_APK##*.}" != "apk" ]]; then
        echo "Fehler: --android-apk must point to an existing APK" >&2
        exit 1
    fi
    cp "$ANDROID_APK" "$ANDROID_APK_FILE"
fi

# Prüfsummen berechnen
ARTIFACTS=("$EXTENSION_ZIP" "$PLUGIN_ZIP" "$SERVICE_ZIP" "$IOS_SOURCE_ZIP" "$ANDROID_SOURCE_ZIP")
if [[ -f "$ANDROID_APK_FILE" ]]; then
    ARTIFACTS+=("$ANDROID_APK_FILE")
fi

CHECKSUMS=""
for artifact in "${ARTIFACTS[@]}"; do
    digest=$(sha256sum "$artifact" | cut -d' ' -f1)
    filename=$(basename "$artifact")
    CHECKSUMS+="$digest  $filename"$'\n'
done

echo -n "$CHECKSUMS" > "$CHECKSUM_FILE"

# JSON-Ausgabe erstellen
ANDROID_APK_OUTPUT=null
if [[ -f "$ANDROID_APK_FILE" ]]; then
    ANDROID_APK_OUTPUT="\"$(realpath "$ANDROID_APK_FILE")\""
fi

jq -n --arg extension_dir "$(realpath "$EXTENSION_DIR")" \
       --arg extension_zip "$(realpath "$EXTENSION_ZIP")" \
       --arg plugin_zip "$(realpath "$PLUGIN_ZIP")" \
       --arg service_zip "$(realpath "$SERVICE_ZIP")" \
       --arg ios_source_zip "$(realpath "$IOS_SOURCE_ZIP")" \
       --arg android_source_zip "$(realpath "$ANDROID_SOURCE_ZIP")" \
       --arg android_apk "$ANDROID_APK_OUTPUT" \
       --arg checksum_file "$(realpath "$CHECKSUM_FILE")" \
       --arg version "$VERSION" \
       '{
           extension_dir: $extension_dir,
           extension_zip: $extension_zip,
           plugin_zip: $plugin_zip,
           service_zip: $service_zip,
           ios_source_zip: $ios_source_zip,
           android_source_zip: $android_source_zip,
           android_apk: ($android_apk | fromjson),
           checksum_file: $checksum_file,
           version: $version
       }'
