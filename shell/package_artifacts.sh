#!/bin/bash
# package_artifacts.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(realpath "$SCRIPT_DIR/../..")"
readonly PROJECT_ROOT="$(realpath "$ROOT/..")"
readonly EXCLUDED_PARTS="__pycache__ .gradle .kotlin build DerivedData xcuserdata"

# Funktionen
add_tree() {
    local archive="$1"
    local source="$2"
    local prefix="${3:-}"

    # Finde alle Dateien im Quellverzeichnis
    find "$source" -type f | while IFS= read -r file; do
        # Prüfe ob Datei ausgeschlossen ist
        local exclude=false
        for part in $EXCLUDED_PARTS; do
            if [[ "$file" == */"$part"/* ]] || [[ "$file" == */"$part" ]]; then
                exclude=true
                break
            fi
        done
        
        # Prüfe Dateiendungen
        if [[ "$file" == *.pyc ]] || [[ "$file" == *.aar ]]; then
            exclude=true
        fi
        
        if [[ "$exclude" == true ]]; then
            continue
        fi

        # Berechne relativen Pfad
        local relative_path="${file#$source/}"
        local archive_path="$prefix/$relative_path"
        
        # Entferne führende Schrägstriche
        archive_path="${archive_path#/}"
        
        # Füge Datei zum ZIP-Archiv hinzu
        zip -9 -j "$archive" "$file" 2>/dev/null || true
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
            echo "Unbekanntes Argument: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$OUTPUT_DIR" ]]; then
    echo "--output-dir ist erforderlich"
    exit 1
fi

# Ausgabeverzeichnis erstellen
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"

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
if [[ "$(realpath "$(dirname "$EXTENSION_DIR")")" != "$OUTPUT_DIR" ]]; then
    echo "Ablehnen des Packens außerhalb des angeforderten Ausgabeverzeichnisses"
    exit 1
fi

if [[ -d "$EXTENSION_DIR" ]]; then
    rm -rf "$EXTENSION_DIR"
fi

cp -r "$ROOT/browser-extension" "$EXTENSION_DIR"
cp -r "$ROOT/companion-service" "$EXTENSION_DIR/companion-service"

# Batch-Datei erstellen
cat > "$EXTENSION_DIR/Sprachdienst-reparieren.cmd" << 'EOF'
@echo off
call "%~dp0companion-service\Sprachdienst-reparieren.cmd"
EOF

# package.json erstellen
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

# ZIP-Dateien erstellen
zip -r "$EXTENSION_ZIP" "$EXTENSION_DIR" >/dev/null
zip -r "$PLUGIN_ZIP" "$ROOT" >/dev/null
zip -r "$SERVICE_ZIP" "$ROOT/companion-service" >/dev/null

# Mobile Quellen verarbeiten
IOS_SOURCE_REALPATH="$(realpath "$IOS_SOURCE")"
ANDROID_SOURCE_REALPATH="$(realpath "$ANDROID_SOURCE")"

if [[ ! -d "$IOS_SOURCE_REALPATH" ]] || [[ ! -d "$ANDROID_SOURCE_REALPATH" ]]; then
    echo "--ios-source und --android-source müssen auf vorhandene Quellverzeichnisse zeigen"
    exit 1
fi

zip -r "$IOS_SOURCE_ZIP" "$IOS_SOURCE_REALPATH" >/dev/null
zip -r "$ANDROID_SOURCE_ZIP" "$ANDROID_SOURCE_REALPATH" >/dev/null

# APK kopieren falls angegeben
if [[ -n "$ANDROID_APK" ]]; then
    ANDROID_APK_REALPATH="$(realpath "$ANDROID_APK")"
    
    if [[ ! -f "$ANDROID_APK_REALPATH" ]] || [[ "${ANDROID_APK_REALPATH##*.}" != "apk" ]]; then
        echo "--android-apk muss auf eine vorhandene APK zeigen"
        exit 1
    fi
    
    if [[ "$(realpath "$ANDROID_APK_REALPATH")" != "$(realpath "$ANDROID_APK_FILE")" ]]; then
        cp "$ANDROID_APK_REALPATH" "$ANDROID_APK_FILE"
    fi
fi

# Prüfsummen berechnen
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

CHECKSUMS=()
for artifact in "${ARTIFACTS[@]}"; do
    if [[ -f "$artifact" ]]; then
        digest=$(sha256sum "$artifact" | cut -d' ' -f1)
        filename=$(basename "$artifact")
        CHECKSUMS+=("$digest  $filename")
    fi
done

printf '%s\n' "${CHECKSUMS[@]}" > "$CHECKSUM_FILE"

# JSON-Ausgabe erstellen
ANDROID_APK_PATH=null
if [[ -f "$ANDROID_APK_FILE" ]]; then
    ANDROID_APK_PATH="$(realpath "$ANDROID_APK_FILE")"
fi

jq -n \
    --arg extension_dir "$(realpath "$EXTENSION_DIR")" \
    --arg extension_zip "$(realpath "$EXTENSION_ZIP")" \
    --arg plugin_zip "$(realpath "$PLUGIN_ZIP")" \
    --arg service_zip "$(realpath "$SERVICE_ZIP")" \
    --arg ios_source_zip "$(realpath "$IOS_SOURCE_ZIP")" \
    --arg android_source_zip "$(realpath "$ANDROID_SOURCE_ZIP")" \
    --arg android_apk "$ANDROID_APK_PATH" \
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
