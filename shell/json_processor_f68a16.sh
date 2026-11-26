#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "af1e37036265731d7b42146e5f498373063b15e03cc80d653d3a9296dc5f8707", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "shell"}
# json_processor.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# JSON Processor mit jq und manueller Reparatur.
# Für robuste Verarbeitung von LLM-Outputs.

# Farbcodes für Fehlermeldungen
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Prüfe ob jq installiert ist
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq not installed. Install with: apt-get install jq or brew install jq" >&2
    exit 1
fi

# Globale Variablen
HAS_JSON_REPAIR=false
TEMP_DIR=""
CLEANUP_REGISTERED=false

# Temporäres Verzeichnis erstellen und aufräumen
setup_temp_dir() {
    if [[ -z "$TEMP_DIR" ]]; then
        TEMP_DIR=$(mktemp -d)
        if [[ "$CLEANUP_REGISTERED" = false ]]; then
            trap cleanup_temp_dir EXIT
            CLEANUP_REGISTERED=true
        fi
    fi
}

cleanup_temp_dir() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        TEMP_DIR=""
    fi
}

# JSON reparieren (manuell)
repair_json_string() {
    local raw_json="$1"
    local temp_file="${TEMP_DIR}/repaired.json"

    # Entferne führende/trailende Leerzeichen
    local cleaned
    cleaned=$(echo "$raw_json" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Entferne JavaScript-Kommentare
    cleaned=$(echo "$cleaned" | sed -E 's|//[^\n]*||g' | sed -E '/\/\*/,/\*\//d')

    # Entferne trailing commas vor ] oder }
    cleaned=$(echo "$cleaned" | sed -E 's/,([[:space:]]*[\}\]])/\1/g')

    # Ersetze einfache durch doppelte Anführungszeichen um Keys herum
    cleaned=$(echo "$cleaned" | sed -E "s/'([^']+)':/\"\1\":/g")

    # Entferne unescapte Zeilenumbrüche innerhalb von Strings (vereinfacht)
    cleaned=$(echo "$cleaned" | tr '\n' ' ')

    echo "$cleaned" > "$temp_file"

    if jq . "$temp_file" &>/dev/null; then
        cat "$temp_file"
        return 0
    else
        echo "$raw_json" # fallback
        return 1
    fi
}

# JSON parsen mit optionaler Reparatur
parse_json() {
    local raw_input="$1"
    local repair="${2:-true}"
    local temp_file="${TEMP_DIR}/parsed.json"

    setup_temp_dir

    echo "$raw_input" > "$temp_file"

    # Direktes Parsen versuchen
    if jq . "$temp_file" &>/dev/null; then
        cat "$temp_file"
        return 0
    fi

    # Extrahiere JSON aus Markdown-Code-Blöcken
    local extracted
    extracted=$(grep -oP '```json\s*\K.*?(?=\s*```)' "$temp_file" | head -1)
    if [[ -n "$extracted" ]] && jq . <(echo "$extracted") &>/dev/null; then
        echo "$extracted"
        return 0
    fi

    extracted=$(grep -oP '```\s*\K\{.*?\}(?=\s*```)' "$temp_file" | head -1)
    if [[ -n "$extracted" ]] && jq . <(echo "$extracted") &>/dev/null; then
        echo "$extracted"
        return 0
    fi

    extracted=$(grep -oP '```\s*\K\[.*?\](?=\s*```)' "$temp_file" | head -1)
    if [[ -n "$extracted" ]] && jq . <(echo "$extracted") &>/dev/null; then
        echo "$extracted"
        return 0
    fi

    # Reparaturversuch
    if [[ "$repair" == true ]]; then
        local repaired
        repaired=$(repair_json_string "$raw_input")
        if jq . <(echo "$repaired") &>/dev/null; then
            echo "$repaired"
            return 0
        fi
    fi

    echo "Could not parse JSON" >&2
    return 1
}

# Sicheres JSON-Parsing mit Default-Wert
safe_json_loads() {
    local raw_input="$1"
    local default="${2:-null}"
    local repair="${3:-true}"

    if result=$(parse_json "$raw_input" "$repair"); then
        echo "$result"
    else
        echo "$default"
    fi
}

# Alle JSON-Objekte aus Text extrahieren
extract_json_from_text() {
    local text="$1"
    local temp_file="${TEMP_DIR}/text.txt"
    local json_file="${TEMP_DIR}/json_matches.txt"

    setup_temp_dir
    echo "$text" > "$temp_file"

    # Regex für JSON-Objekte und Arrays finden
    grep -oE '\{[^{}]*(\{[^{}]*\}[^{}]*)*\}' "$temp_file" > "$json_file" 2>/dev/null || true
    grep -oE '\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\]' "$temp_file" >> "$json_file" 2>/dev/null || true

    local results="["
    local first=true
    while IFS= read -r line; do
        if [[ -n "$line" ]] && jq . <(echo "$line") &>/dev/null; then
            if [[ "$first" == true ]]; then
                results="$results$line"
                first=false
            else
                results="$results,$line"
            fi
        fi
    done < "$json_file"
    results="$results]"

    echo "$results"
}

# CLI Interface
main() {
    local input=""
    local is_file=false
    local repair=true
    local pretty=false

    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
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
            --pretty|-p)
                pretty=true
                shift
                ;;
            *)
                input="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        echo -e "${RED}Error:${NC} Missing input argument" >&2
        exit 1
    fi

    local content
    if [[ "$is_file" == true ]]; then
        if [[ ! -f "$input" ]]; then
            echo -e "${RED}Error:${NC} File '$input' does not exist" >&2
            exit 1
        fi
        content=$(cat "$input")
    else
        content="$input"
    fi

    local result
    if ! result=$(parse_json "$content" "$repair"); then
        echo -e "${RED}Error:${NC} Could not parse JSON" >&2
        exit 1
    fi

    if [[ "$pretty" == true ]]; then
        echo "$result" | jq .
    else
        echo "$result"
    fi
}

# Hauptprogramm starten
main "$@"
