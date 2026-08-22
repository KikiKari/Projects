#!/usr/bin/env bash
# validate_tool_output.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/validate_tool_output.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/validate_tool_output.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Validiert Tool-Outputs gegen ein JSON-Schema.
# Für OpenClaw Tool-Call-Validierung.

# Funktion zur Ausgabe von Fehlermeldungen
error() {
    echo "Error: $*" >&2
    exit 1
}

# Funktion zur Ausgabe von Hilfetexten
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] JSON_INPUT

Validate tool output against schema

Arguments:
  JSON_INPUT                  JSON string or file path

Options:
  --schema, -s SCHEMA_FILE   JSON schema file (required)
  --file, -f                  Input is a file
  --repair, -r                Repair mode (default true)
  --strict                    Strict validation
  --help, -h                  Show this help message and exit
EOF
}

# Standardwerte setzen
SCHEMA_FILE=""
INPUT_IS_FILE=false
REPAIR=true
STRICT=false
JSON_INPUT=""

# Argumente parsen
while [[ $# -gt 0 ]]; do
    case "$1" in
        --schema|-s)
            SCHEMA_FILE="$2"
            shift 2
            ;;
        --file|-f)
            INPUT_IS_FILE=true
            shift
            ;;
        --repair|-r)
            REPAIR=true
            shift
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            if [[ -z "$JSON_INPUT" ]]; then
                JSON_INPUT="$1"
            else
                error "Multiple inputs provided"
            fi
            shift
            ;;
    esac
done

# Prüfen ob Pflichtargumente vorhanden sind
if [[ -z "$SCHEMA_FILE" ]]; then
    error "--schema/-s ist erforderlich"
fi

if [[ -z "$JSON_INPUT" ]]; then
    error "JSON_INPUT ist erforderlich"
fi

# Schema laden
if ! SCHEMA_JSON=$(<"$SCHEMA_FILE"); then
    error "Fehler beim Laden des Schemas: $SCHEMA_FILE"
fi

# Eingabe laden
if [[ "$INPUT_IS_FILE" == true ]]; then
    if ! RAW_INPUT=$(<"$JSON_INPUT"); then
        error "Fehler beim Laden der Eingabedatei: $JSON_INPUT"
    fi
else
    RAW_INPUT="$JSON_INPUT"
fi

# jq-basierte Validierungsfunktion
validate_with_jq() {
    local input_json="$1"
    local schema_json="$2"
    local strict_mode="$3"

    # Extrahiere Eigenschaften aus dem Schema
    local properties
    properties=$(echo "$schema_json" | jq -r '.properties // {} | keys[]')

    # Baue dynamisch eine jq-Abfrage zusammen
    local jq_filter=""
    local required_fields
    required_fields=$(echo "$schema_json" | jq -r '.required // [] | .[]')

    while IFS= read -r key; do
        [[ -z "$key" ]] && continue

        local prop_def
        prop_def=$(echo "$schema_json" | jq -r ".properties[\"$key\"]")

        local field_type
        field_type=$(echo "$prop_def" | jq -r '.type // "string"')

        local is_required
        is_required=false
        if echo "$required_fields" | grep -Fxq "$key"; then
            is_required=true
        fi

        # Typvalidierung hinzufügen
        case "$field_type" in
            string)
                jq_filter+="$key: .[\"$key\"] | if type==\"string\" or type==\"null\" then . else error(\"Invalid type for $key\") end, "
                ;;
            integer|number)
                jq_filter+="$key: .[\"$key\"] | if type==\"number\" or type==\"null\" then . else error(\"Invalid type for $key\") end, "
                ;;
            boolean)
                jq_filter+="$key: .[\"$key\"] | if type==\"boolean\" or type==\"null\" then . else error(\"Invalid type for $key\") end, "
                ;;
            array)
                jq_filter+="$key: .[\"$key\"] | if type==\"array\" or type==\"null\" then . else error(\"Invalid type for $key\") end, "
                ;;
            object)
                jq_filter+="$key: .[\"$key\"] | if type==\"object\" or type==\"null\" then . else error(\"Invalid type for $key\") end, "
                ;;
            *)
                jq_filter+="$key: .[\"$key\"], "
                ;;
        esac

        # Bei nicht benötigten Feldern Standardwert setzen falls nötig
        if [[ "$is_required" == false ]]; then
            local has_default
            has_default=$(echo "$prop_def" | jq 'has("default")')
            if [[ "$has_default" == "true" ]]; then
                local default_val
                default_val=$(echo "$prop_def" | jq -c '.default')
                jq_filter+="if has(\"$key\") then . else . + {\"$key\": $default_val} end | "
            fi
        fi
    done <<< "$properties"

    # Entferne das letzte Komma und Leerzeichen
    jq_filter=${jq_filter%, }

    # Führe Validierung durch
    if [[ "$strict_mode" == true ]]; then
        echo "$input_json" | jq "{$jq_filter}"
    else
        echo "$input_json" | jq "if type==\"object\" then {$jq_filter} else . end"
    fi
}

# Versuche Validierung mit jq
if ! RESULT=$(validate_with_jq "$RAW_INPUT" "$SCHEMA_JSON" "$STRICT" 2>&1); then
    error "Validierungsfehler: $RESULT"
fi

# Gebe Ergebnis formatiert aus
echo "$RESULT" | jq '.' >/dev/null || error "Ausgabe ist kein gültiges JSON"

echo "$RESULT" | jq '.' -M

exit 0
