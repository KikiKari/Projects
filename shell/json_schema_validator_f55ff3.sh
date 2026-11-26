#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "b1dcfab35e5eb88108212d17ccfad2332baee5551cd780106fd9b9cb807eeffd", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "shell"}
# json_schema_validator.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
# Erweitert Pydantic mit externen Schema-Dateien.

# Globale Variablen
HAS_JSONSCHEMA=0
TEMP_DIR=""
CLEANUP_REGISTERED=0

# Cleanup-Funktion für temporäre Dateien
cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Cleanup registrieren
register_cleanup() {
    if [[ $CLEANUP_REGISTERED -eq 0 ]]; then
        trap cleanup EXIT
        CLEANUP_REGISTERED=1
    fi
}

# Temporäres Verzeichnis erstellen
create_temp_dir() {
    if [[ -z "${TEMP_DIR:-}" ]]; then
        TEMP_DIR=$(mktemp -d)
        register_cleanup
    fi
}

# Fehlerbehandlung
error() {
    echo "✗ Error: $*" >&2
    exit 1
}

# JSON parsen mit jq
parse_json() {
    local raw_input="$1"
    local repair="${2:-false}"
    
    if [[ "$repair" == "true" ]]; then
        # Versuche, beschädigtes JSON zu reparieren (einfache Fälle)
        raw_input=$(echo "$raw_input" | sed 's/\b\(true\|false\|null\)\b/"\1"/g')
    fi
    
    if ! echo "$raw_input" | jq -e . >/dev/null 2>&1; then
        error "Invalid JSON input"
    fi
    
    echo "$raw_input"
}

# Schema laden
load_schema() {
    local schema_source="$1"
    
    # Prüfe ob es eine Datei ist
    if [[ -f "$schema_source" ]]; then
        if ! jq -e . <"$schema_source" >/dev/null 2>&1; then
            error "Invalid JSON in schema file: $schema_source"
        fi
        cat "$schema_source"
        return
    fi
    
    # Versuche als JSON-String zu parsen
    if echo "$schema_source" | jq -e . >/dev/null 2>&1; then
        echo "$schema_source"
        return
    fi
    
    error "Schema not found or invalid: $schema_source"
}

# Validiere mit jsonschema (Python-Bibliothek)
validate_with_jsonschema() {
    local data_file="$1"
    local schema_file="$2"
    
    if ! command -v python3 &>/dev/null; then
        error "Python3 not found"
    fi
    
    # Prüfe ob jsonschema verfügbar ist
    if ! python3 -c "import jsonschema" 2>/dev/null; then
        error "jsonschema not installed. Run: pip install jsonschema"
    fi
    
    # Validierung durchführen
    if ! python3 -c "
import json
import sys
from jsonschema import validate, ValidationError

with open('$data_file') as f:
    data = json.load(f)

with open('$schema_file') as f:
    schema = json.load(f)

try:
    validate(instance=data, schema=schema)
except ValidationError as e:
    print(f'Schema validation failed: {e.message} at {list(e.path)}', file=sys.stderr)
    sys.exit(1)
"; then
        error "Schema validation failed"
    fi
}

# Schema Builder Funktionen
schema_object() {
    local properties="$1"
    local required="${2:-}"
    
    local schema='{"type":"object","properties":'"$properties"'}'
    
    if [[ -n "$required" ]]; then
        schema=$(echo "$schema" | jq --argjson req "$required" '. + {"required":$req}')
    fi
    
    echo "$schema"
}

schema_string() {
    local enum="${1:-}"
    local pattern="${2:-}"
    local min_length="${3:-}"
    
    local schema='{"type":"string"}'
    
    if [[ -n "$enum" ]]; then
        schema=$(echo "$schema" | jq --argjson e "$enum" '. + {"enum":$e}')
    fi
    
    if [[ -n "$pattern" ]]; then
        schema=$(echo "$schema" | jq --arg p "$pattern" '. + {"pattern":$p}')
    fi
    
    if [[ -n "$min_length" ]]; then
        schema=$(echo "$schema" | jq --arg len "$min_length" '. + {"minLength":($len|tonumber)}')
    fi
    
    echo "$schema"
}

schema_integer() {
    local minimum="${1:-}"
    local maximum="${2:-}"
    
    local schema='{"type":"integer"}'
    
    if [[ -n "$minimum" ]]; then
        schema=$(echo "$schema" | jq --arg min "$minimum" '. + {"minimum":($min|tonumber)}')
    fi
    
    if [[ -n "$maximum" ]]; then
        schema=$(echo "$schema" | jq --arg max "$maximum" '. + {"maximum":($max|tonumber)}')
    fi
    
    echo "$schema"
}

schema_array() {
    local items="$1"
    local min_items="${2:-}"
    
    local schema='{"type":"array","items":'"$items"'}'
    
    if [[ -n "$min_items" ]]; then
        schema=$(echo "$schema" | jq --arg mi "$min_items" '. + {"minItems":($mi|tonumber)}')
    fi
    
    echo "$schema"
}

# Hauptvalidierungsfunktion
validate_and_convert() {
    local raw_input="$1"
    local schema_source="$2"
    local repair="${3:-true}"
    
    create_temp_dir
    
    # Parse JSON
    local parsed_data
    parsed_data=$(parse_json "$raw_input" "$repair") || error "Failed to parse JSON"
    
    # Speichere geparste Daten in temporärer Datei
    local data_file="$TEMP_DIR/data.json"
    echo "$parsed_data" >"$data_file"
    
    # Lade Schema
    local schema_file="$TEMP_DIR/schema.json"
    load_schema "$schema_source" >"$schema_file"
    
    # Validiere
    validate_with_jsonschema "$data_file" "$schema_file"
    
    # Gebe validierte Daten aus
    cat "$data_file"
}

# Hauptprogramm
main() {
    local input=""
    local schema=""
    local is_file=0
    local repair=1
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --schema|-s)
                schema="$2"
                shift 2
                ;;
            --file|-f)
                is_file=1
                shift
                ;;
            --repair|-r)
                repair=1
                shift
                ;;
            --no-repair)
                repair=0
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS] INPUT"
                echo "Options:"
                echo "  --schema, -s SCHEMA    Schema file or JSON string"
                echo "  --file, -f             Treat INPUT as file path"
                echo "  --repair, -r           Attempt to repair JSON (default)"
                echo "  --no-repair            Do not attempt to repair JSON"
                echo "  --help, -h             Show this help"
                exit 0
                ;;
            *)
                if [[ -z "$input" ]]; then
                    input="$1"
                else
                    error "Unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$input" ]]; then
        error "Missing input. Use --help for usage information."
    fi
    
    if [[ -z "$schema" ]]; then
        error "Schema is required. Use --schema or -s option."
    fi
    
    # Lade Input (Auto-detect file vs string)
    local raw_input=""
    if [[ $is_file -eq 1 || (-f "$input" && -r "$input") ]]; then
        raw_input=$(cat "$input")
    else
        raw_input="$input"
    fi
    
    # Validiere und konvertiere
    if result=$(validate_and_convert "$raw_input" "$schema" "$repair" 2>"$TEMP_DIR/error.log"); then
        echo "$result" | jq .
        echo "✓ Validation passed" >&2
    else
        echo "✗ Validation failed: $(cat "$TEMP_DIR/error.log")" >&2
        exit 1
    fi
}

# Wenn das Skript direkt aufgerufen wird
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
