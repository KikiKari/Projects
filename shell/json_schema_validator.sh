#!/usr/bin/env bash
# json_schema_validator.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
# Erweitert Pydantic mit externen Schema-Dateien.

# Globale Variablen
HAS_JSONSCHEMA=0
JSONSCHEMA_CMD=""

# Prüfe ob jq installiert ist
if ! command -v jq &> /dev/null; then
    echo "jq ist nicht installiert. Bitte installieren: apt-get install jq oder brew install jq" >&2
    exit 1
fi

# Prüfe ob jsonschema validator verfügbar ist
if command -v check-jsonschema &> /dev/null; then
    HAS_JSONSCHEMA=1
    JSONSCHEMA_CMD="check-jsonschema"
elif command -v ajv &> /dev/null; then
    HAS_JSONSCHEMA=1
    JSONSCHEMA_CMD="ajv"
fi

# SchemaValidationError simulieren
schema_validation_error() {
    echo "✗ Schema validation failed: $1" >&2
    exit 1
}

# Lädt ein JSON Schema aus verschiedenen Quellen
load_schema() {
    local schema_source="$1"
    
    # Prüfe ob es eine Datei ist
    if [[ -f "$schema_source" ]]; then
        if jq empty "$schema_source" 2>/dev/null; then
            cat "$schema_source"
            return 0
        else
            schema_validation_error "Invalid JSON in schema file: $schema_source"
        fi
    fi
    
    # Prüfe ob es ein gültiger JSON String ist
    if jq empty <<< "$schema_source" 2>/dev/null; then
        echo "$schema_source"
        return 0
    else
        schema_validation_error "Schema not found or invalid: $schema_source"
    fi
}

# Validiert Daten gegen ein JSON Schema
validate_with_jsonschema() {
    local data_file="$1"
    local schema_source="$2"
    local draft="${3:-auto}"
    
    if [[ $HAS_JSONSCHEMA -eq 0 ]]; then
        schema_validation_error "No JSON schema validator found. Install check-jsonschema or ajv"
    fi
    
    # Lade Schema
    local schema_file
    schema_file=$(mktemp)
    load_schema "$schema_source" > "$schema_file"
    
    # Validiere mit check-jsonschema
    if [[ "$JSONSCHEMA_CMD" == "check-jsonschema" ]]; then
        if ! check-jsonschema --schemafile "$schema_file" "$data_file"; then
            schema_validation_error "Schema validation failed"
        fi
    # Validiere mit ajv
    elif [[ "$JSONSCHEMA_CMD" == "ajv" ]]; then
        if ! ajv validate -s "$schema_file" -d "$data_file"; then
            schema_validation_error "Schema validation failed"
        fi
    fi
    
    rm -f "$schema_file"
    return 0
}

# Parst, repariert und validiert JSON gegen Schema
validate_and_convert() {
    local raw_input="$1"
    local schema="$2"
    local repair="${3:-true}"
    
    local temp_data
    temp_data=$(mktemp)
    
    # Schreibe Input in temporäre Datei
    echo "$raw_input" > "$temp_data"
    
    # Reparaturversuch (jq formatiert und korrigiert automatisch)
    if [[ "$repair" == "true" ]]; then
        local repaired_data
        repaired_data=$(mktemp)
        if jq . "$temp_data" > "$repaired_data" 2>/dev/null; then
            mv "$repaired_data" "$temp_data"
        else
            rm -f "$repaired_data"
            schema_validation_error "Could not repair JSON"
        fi
    fi
    
    # Validierung
    validate_with_jsonschema "$temp_data" "$schema"
    
    # Gebe validiertes JSON aus
    jq . "$temp_data"
    
    rm -f "$temp_data"
}

# Hilfsfunktionen für Schema Builder
schema_object() {
    local properties="$1"
    local required="${2:-}"
    
    local schema='{"type": "object"}'
    
    if [[ -n "$properties" ]]; then
        schema=$(jq --argjson props "$properties" '.properties = $props' <<< "$schema")
    fi
    
    if [[ -n "$required" ]]; then
        schema=$(jq --argjson req "$required" '.required = $req' <<< "$schema")
    fi
    
    echo "$schema"
}

schema_string() {
    local enum="${1:-}"
    local pattern="${2:-}"
    local min_length="${3:-}"
    
    local schema='{"type": "string"}'
    
    if [[ -n "$enum" && "$enum" != "null" ]]; then
        schema=$(jq --argjson e "$enum" '.enum = $e' <<< "$schema")
    fi
    
    if [[ -n "$pattern" && "$pattern" != "null" ]]; then
        schema=$(jq --arg p "$pattern" '.pattern = $p' <<< "$schema")
    fi
    
    if [[ -n "$min_length" && "$min_length" != "null" ]]; then
        schema=$(jq --argjson ml "$min_length" '.minLength = $ml' <<< "$schema")
    fi
    
    echo "$schema"
}

schema_integer() {
    local minimum="${1:-}"
    local maximum="${2:-}"
    
    local schema='{"type": "integer"}'
    
    if [[ -n "$minimum" && "$minimum" != "null" ]]; then
        schema=$(jq --argjson min "$minimum" '.minimum = $min' <<< "$schema")
    fi
    
    if [[ -n "$maximum" && "$maximum" != "null" ]]; then
        schema=$(jq --argjson max "$maximum" '.maximum = $max' <<< "$schema")
    fi
    
    echo "$schema"
}

schema_array() {
    local items="$1"
    local min_items="${2:-}"
    
    local schema
    schema=$(jq --argjson i "$items" '{"type": "array", "items": $i}' <<< "{}")
    
    if [[ -n "$min_items" && "$min_items" != "null" ]]; then
        schema=$(jq --argjson mi "$min_items" '.minItems = $mi' <<< "$schema")
    fi
    
    echo "$schema"
}

# Hauptfunktion
main() {
    local input=""
    local schema=""
    local is_file=false
    local repair=true
    
    # Parse Argumente
    while [[ $# -gt 0 ]]; do
        case $1 in
            --schema|-s)
                schema="$2"
                shift 2
                ;;
            --file|-f)
                is_file=true
                shift
                ;;
            --repair|-r)
                repair=true
                shift
                ;;
            --no-repair)
                repair=false
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS] INPUT"
                echo "JSON Schema Validator"
                echo ""
                echo "Arguments:"
                echo "  INPUT                    JSON file or string"
                echo ""
                echo "Options:"
                echo "  --schema, -s SCHEMA      Schema file"
                echo "  --file, -f               Input is file"
                echo "  --repair, -r             Repair JSON (default)"
                echo "  --no-repair              Don't repair JSON"
                echo "  -h, --help               Show this message and exit"
                exit 0
                ;;
            *)
                input="$1"
                shift
                ;;
        esac
    done
    
    # Prüfe ob Schema angegeben
    if [[ -z "$schema" ]]; then
        echo "✗ Schema is required" >&2
        exit 1
    fi
    
    # Prüfe ob Input angegeben
    if [[ -z "$input" ]]; then
        echo "✗ Input is required" >&2
        exit 1
    fi
    
    # Lade Input (Auto-detect file vs string)
    local raw_input
    if [[ "$is_file" == true ]] || [[ -f "$input" ]]; then
        if [[ -f "$input" ]]; then
            raw_input=$(cat "$input")
        else
            echo "✗ File not found: $input" >&2
            exit 1
        fi
    else
        raw_input="$input"
    fi
    
    # Validiere und konvertiere
    if validate_and_convert "$raw_input" "$schema" "$repair"; then
        echo "✓ Validation passed" >&2
    else
        echo "✗ Validation failed" >&2
        exit 1
    fi
}

# Starte Hauptfunktion
main "$@"
