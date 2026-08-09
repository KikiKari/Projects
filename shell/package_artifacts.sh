#!/bin/bash
# package_artifacts.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Globale Variablen
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT/.." && pwd)"
EXCLUDED_PARTS="__pycache__ .gradle .kotlin build DerivedData xcuserdata"
EXCLUDED_SUFFIXES=".pyc .aar"

# Funktionen
add_tree() {
    local archive="$1"
    local source="$2"
    local prefix="${3:-}"

    # Finde alle Dateien im Quellverzeichnis
    find "$source" -type f | while read -r file; do
        # Prüfe auf ausgeschlossene Teile
        local exclude=0
        for part in $EXCLUDED_PARTS; do
            if [[ "$file" == *"/$part/"* ]] || [[ "$file" == *"/$part" ]]; then
                exclude=1
                break
            fi
        done

        # Prüfe auf ausgeschlossene Suffixe
        for suffix in $EXCLUDED_SUFFIXES; do
            if [[ "$file" == *"$suffix" ]]; then
                exclude=1
                break
            fi
        done

        if [[ $exclude -eq 1 ]]; then
            continue
        fi

        # Erstelle relativen Pfad
        local relative_path="${file#$source/}"
        local archive_path="$prefix/$relative_path"

        # Füge Datei zum ZIP-Archiv hinzu mit festem Datum
        zip --quiet --junk-paths --compression-method deflate --compression-level 9 --mtime "1980-01-01 00:00" "$archive" "$file"
        # Setze den Namen im Archiv
        local temp_zip="$(mktemp)"
        zip --quiet --copy "$archive" "$archive_path" -O "$temp_zip"
        mv "$temp_zip" "$archive"
    done
}

# Argumente parsen
OUTPUT_DIR=""
ANDROID_APK=""
ANDROID_SOURCE="$PROJECT_ROOT/mobile/android"
IOS_SOURCE="$PROJECT_ROOT/mobile/ios"

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

# Ausgabeverzeichnis erstellen
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
ANDROID_APK_TARGET="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION.apk"
EXTENSION_DIR="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION"
CHECKSUM_FILE="$OUTPUT_DIR/tiktok-live-companion-$VERSION-SHA256.txt"

# Prüfen, ob Extension-Verzeichnis außerhalb des Ausgabeverzeichnisses liegt
if [[ "$(cd "$(dirname "$EXTENSION_DIR")" && pwd)" != "$OUTPUT_DIR" ]]; then
    echo "Fehler: Refusing to package outside the requested output directory" >&2
    exit 1
fi

# Extension-Verzeichnis bereinigen und kopieren
rm -rf "$EXTENSION_DIR"
mkdir -p "$EXTENSION_DIR"
cp -r "$ROOT/browser-extension"/* "$EXTENSION_DIR/"
cp -r "$ROOT/companion-service" "$EXTENSION_DIR/companion-service"

# package.json erstellen
cat > "$EXTENSION_DIR/package.json" <<EOF
{
  "name": "tiktok-live-companion-extension-package",
  "private": true,
  "version": "$VERSION",
  "scripts": {
    "setup": "npm --prefix companion-service run setup --",
    "start": "npm --prefix companion-service start",
    "test": "npm --prefix companion-service test"
  }
}
EOF

# ZIP-Dateien erstellen
zip --quiet -r "$EXTENSION_ZIP" "$EXTENSION_DIR" -j
zip --quiet -r "$PLUGIN_ZIP" "$ROOT" -j
zip --quiet -r "$SERVICE_ZIP" "$ROOT/companion-service" -j

# iOS und Android Quellcode ZIPs erstellen
if [[ ! -d "$IOS_SOURCE" ]] || [[ ! -d "$ANDROID_SOURCE" ]]; then
    echo "Fehler: --ios-source und --android-source müssen auf existierende Verzeichnisse zeigen" >&2
    exit 1
fi

zip --quiet -r "$IOS_SOURCE_ZIP" "$IOS_SOURCE" -j
zip --quiet -r "$ANDROID_SOURCE_ZIP" "$ANDROID_SOURCE" -j

# Android APK kopieren, falls angegeben
if [[ -n "$ANDROID_APK" ]]; then
    if [[ ! -f "$ANDROID_APK" ]] || [[ "${ANDROID_APK##*.}" != "apk" ]]; then
        echo "Fehler: --android-apk muss auf eine existierende APK-Datei zeigen" >&2
        exit 1
    fi
    cp "$ANDROID_APK" "$ANDROID_APK_TARGET"
fi

# Prüfsummen berechnen
ARTIFACTS=("$EXTENSION_ZIP" "$PLUGIN_ZIP" "$SERVICE_ZIP" "$IOS_SOURCE_ZIP" "$ANDROID_SOURCE_ZIP")
if [[ -f "$ANDROID_APK_TARGET" ]]; then
    ARTIFACTS+=("$ANDROID_APK_TARGET")
fi

CHECKSUMS=""
for artifact in "${ARTIFACTS[@]}"; do
    digest=$(sha256sum "$artifact" | cut -d' ' -f1)
    filename=$(basename "$artifact")
    CHECKSUMS+="$digest  $filename"$'\n'
done
echo -n "$CHECKSUMS" > "$CHECKSUM_FILE"

# JSON-Ausgabe erstellen
ANDROID_APK_JSON="null"
if [[ -f "$ANDROID_APK_TARGET" ]]; then
    ANDROID_APK_JSON="\"$(realpath "$ANDROID_APK_TARGET")\""
fi

jq -n --arg extension_dir "$(realpath "$EXTENSION_DIR")" \
       --arg extension_zip "$(realpath "$EXTENSION_ZIP")" \
       --arg plugin_zip "$(realpath "$PLUGIN_ZIP")" \
       --arg service_zip "$(realpath "$SERVICE_ZIP")" \
       --arg ios_source_zip "$(realpath "$IOS_SOURCE_ZIP")" \
       --arg android_source_zip "$(realpath "$ANDROID_SOURCE_ZIP")" \
       --arg android_apk "$ANDROID_APK_JSON" \
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
