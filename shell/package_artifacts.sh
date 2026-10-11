#!/bin/bash
# package_artifacts.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(realpath "$SCRIPT_DIR/../..")"
readonly PROJECT_ROOT="$(realpath "$ROOT/..")"
readonly EXCLUDED_PARTS="__pycache__ .gradle .kotlin .cxx build DerivedData xcuserdata Pods"

# Funktion zum Hinzufügen eines Verzeichnisbaums zu einem ZIP-Archiv
add_tree() {
    local archive="$1"
    local source="$2"
    local prefix="${3:-}"

    # Finde alle Dateien im Quellverzeichnis
    find "$source" -type f | sort | while read -r file; do
        # Prüfe ob Datei ausgeschlossen ist
        local exclude=false
        for part in $EXCLUDED_PARTS; do
            if [[ "$file" == */"$part"/* ]] || [[ "$file" == */"$part" ]]; then
                exclude=true
                break
            fi
        done
        
        # Prüfe auf auszuschließende Dateiendungen
        if [[ "$file" == *.pyc ]] || [[ "$file" == *.aar ]]; then
            exclude=true
        fi
        
        if [[ "$exclude" == true ]]; then
            continue
        fi
        
        # Berechne relativen Pfad
        local relative_path="${file#$source/}"
        local archive_path="$relative_path"
        if [[ -n "$prefix" ]]; then
            archive_path="$prefix/$relative_path"
        fi
        
        # Setze Unix-Zeitstempel (1980-01-01 00:00:00)
        TZ=UTC touch -t 198001010000.00 "$file"
        
        # Setze Berechtigungen
        if [[ "$(basename "$file")" == "gradlew" ]]; then
            chmod 755 "$file"
        else
            chmod 644 "$file"
        fi
        
        # Füge zur ZIP hinzu
        zip -q -9 -X -j "$archive" "$file"
    done
}

# Argumente parsen
OUTPUT_DIR=""
ANDROID_APK=""
ANDROID_SOURCE="$PROJECT_ROOT/mobile/android"
IOS_SOURCE="$PROJECT_ROOT/mobile/ios"
NATIVE_SHARED_SOURCE="$PROJECT_ROOT/mobile/shared"

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
    echo "Fehler: --output-dir ist erforderlich" >&2
    exit 1
fi

# Verzeichnisse auflösen
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"

# Version aus manifest.json lesen
VERSION=$(jq -r '.version' "$ROOT/browser-extension/manifest.json")

# Ausgabedateien definieren
EXTENSION_ZIP="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION.zip"
PLUGIN_ZIP="$OUTPUT_DIR/tiktok-live-companion-plugin-$VERSION.zip"
SERVICE_ZIP="$OUTPUT_DIR/tiktok-live-companion-service-$VERSION.zip"
IOS_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-ios-$VERSION-source.zip"
ANDROID_SOURCE_ZIP="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION-source.zip"
ANDROID_APK_FILE="$OUTPUT_DIR/tiktok-live-companion-android-$VERSION.apk"
EXTENSION_DIR="$OUTPUT_DIR/tiktok-live-companion-extension-$VERSION"
CHECKSUM_FILE="$OUTPUT_DIR/tiktok-live-companion-$VERSION-SHA256.txt"

# Sicherheitsprüfung für Extension-Verzeichnis
if [[ "$(realpath "$(dirname "$EXTENSION_DIR")")" != "$OUTPUT_DIR" ]]; then
    echo "Fehler: Refusing to package outside the requested output directory" >&2
    exit 1
fi

# Extension-Verzeichnis vorbereiten
rm -rf "$EXTENSION_DIR"
cp -r "$ROOT/browser-extension" "$EXTENSION_DIR"
cp -r "$ROOT/companion-service" "$EXTENSION_DIR/companion-service"

# Batch-Datei erstellen
cat > "$EXTENSION_DIR/Sprachdienst-reparieren.cmd" << 'EOF'
@echo off
call "%~dp0companion-service\Sprachdienst-reparieren.cmd"
EOF

# package.json erstellen
cat > "$EXTENSION_DIR/package.json" << EOF
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
zip -q -r -9 "$EXTENSION_ZIP" "$EXTENSION_DIR"

# Plugin-ZIP erstellen
cd "$ROOT"
zip -q -r -9 "$PLUGIN_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*/Pods/*"

# Service-ZIP erstellen
cd "$ROOT/companion-service"
zip -q -r -9 "$SERVICE_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*"

# Mobile Source ZIPs erstellen
IOS_SOURCE_ABS="$(realpath "$IOS_SOURCE")"
ANDROID_SOURCE_ABS="$(realpath "$ANDROID_SOURCE")"

if [[ ! -d "$IOS_SOURCE_ABS" ]] || [[ ! -d "$ANDROID_SOURCE_ABS" ]]; then
    echo "Fehler: --ios-source und --android-source müssen auf existierende Verzeichnisse zeigen" >&2
    exit 1
fi

NATIVE_SHARED_ABS="$(realpath "$NATIVE_SHARED_SOURCE")"
if [[ ! -f "$NATIVE_SHARED_ABS/native/tlc_peak_limiter.h" ]]; then
    echo "Fehler: Shared native limiter source ist für beide mobile Source-Pakete erforderlich" >&2
    exit 1
fi

# iOS Source ZIP
cd "$IOS_SOURCE_ABS"
zip -q -r -9 "$IOS_SOURCE_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*/Pods/*"
cd "$NATIVE_SHARED_ABS"
zip -q -r -9 "$IOS_SOURCE_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*"

# Android Source ZIP
cd "$ANDROID_SOURCE_ABS"
zip -q -r -9 "$ANDROID_SOURCE_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*" "*/DerivedData/*" "*/xcuserdata/*" "*/Pods/*"
cd "$NATIVE_SHARED_ABS"
zip -q -r -9 "$ANDROID_SOURCE_ZIP" . -x "*/.*" "*/*.pyc" "*/*.aar" "*/build/*"

# Android APK kopieren falls angegeben
if [[ -n "$ANDROID_APK" ]]; then
    ANDROID_APK_ABS="$(realpath "$ANDROID_APK")"
    if [[ ! -f "$ANDROID_APK_ABS" ]] || [[ "${ANDROID_APK_ABS##*.}" != "apk" ]]; then
        echo "Fehler: --android-apk muss auf eine existierende APK zeigen" >&2
        exit 1
    fi
    
    if [[ "$(realpath "$ANDROID_APK_ABS")" != "$(realpath "$ANDROID_APK_FILE")" ]]; then
        cp "$ANDROID_APK_ABS" "$ANDROID_APK_FILE"
    fi
fi

# Checksummen berechnen
ARTIFACTS=("$EXTENSION_ZIP" "$PLUGIN_ZIP" "$SERVICE_ZIP" "$IOS_SOURCE_ZIP" "$ANDROID_SOURCE_ZIP")
if [[ -f "$ANDROID_APK_FILE" ]]; then
    ARTIFACTS+=("$ANDROID_APK_FILE")
fi

CHECKSUM_LINES=()
for artifact in "${ARTIFACTS[@]}"; do
    if [[ -f "$artifact" ]]; then
        digest=$(sha256sum "$artifact" | cut -d' ' -f1)
        filename=$(basename "$artifact")
        CHECKSUM_LINES+=("$digest  $filename")
    fi
done

printf '%s\n' "${CHECKSUM_LINES[@]}" > "$CHECKSUM_FILE"

# JSON-Ausgabe erstellen
JSON_OUTPUT="{"
JSON_OUTPUT+="\"extension_dir\":\"$(realpath "$EXTENSION_DIR")\","
JSON_OUTPUT+="\"extension_zip\":\"$(realpath "$EXTENSION_ZIP")\","
JSON_OUTPUT+="\"plugin_zip\":\"$(realpath "$PLUGIN_ZIP")\","
JSON_OUTPUT+="\"service_zip\":\"$(realpath "$SERVICE_ZIP")\","
JSON_OUTPUT+="\"ios_source_zip\":\"$(realpath "$IOS_SOURCE_ZIP")\","
JSON_OUTPUT+="\"android_source_zip\":\"$(realpath "$ANDROID_SOURCE_ZIP")\","
if [[ -f "$ANDROID_APK_FILE" ]]; then
    JSON_OUTPUT+="\"android_apk\":\"$(realpath "$ANDROID_APK_FILE")\","
else
    JSON_OUTPUT+="\"android_apk\":null,"
fi
JSON_OUTPUT+="\"checksum_file\":\"$(realpath "$CHECKSUM_FILE")\","
JSON_OUTPUT+="\"version\":\"$VERSION\""
JSON_OUTPUT+="}"

echo "$JSON_OUTPUT"
