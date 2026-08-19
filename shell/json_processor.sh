#!/usr/bin/env bash
# json_processor.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# JSON Processor mit jq und manueller Reparatur.
# Für robuste Verarbeitung von LLM-Outputs.

# Globale Variablen
HAS_JQ=false
TEMP_DIR=""
CLEANUP_DONE=false

# Farbcodes für Ausgaben
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup Funktion
cleanup() {
    if [[ "$CLEANUP_DONE" == false ]]; then
        [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
        CLEANUP_DONE=true
    fi
}
trap cleanup EXIT

# Initialisierung
init() {
    # Prüfe ob jq installiert ist
    if command -v jq >/dev/null 2>&1; then
        HAS_JQ=true
    else
        echo -e "${RED}Error: jq not installed. Please install jq package.${NC}" >&2
        exit 1
    fi
    
    # Erstelle temporäres Verzeichnis
    TEMP_DIR=$(mktemp -d)
}

# Logging Funktionen
log_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Repariere JSON String - einfache manuelle Korrekturen
repair_json_string() {
    local raw_json="$1"
    
    # Entferne führende/trailing Whitespace
    raw_json=$(echo "$raw_json" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Entferne JavaScript-Kommentare (// und /* */)
    raw_json=$(echo "$raw_json" | sed 's|//.*||' | sed ':a;N;$!ba;s|/\*.*\*/||g')
    
    # Entferne trailing commas vor ] oder }
    raw_json=$(echo "$raw_json" | sed 's/,\([[:space:]]*[][]\)/\1/g')
    
    # Ersetze single quotes durch double quotes (einfache Fälle)
    # Achtung: Dies ist sehr rudimentär und kann falsche Ergebnisse liefern
    # In echten Szenarien sollte eine bessere Logik verwendet werden
    
    echo "$raw_json"
}

# Extrahiere JSON aus Markdown Code Blöcken
extract_from_markdown() {
    local input="$1"
    
    # Suche nach ```json ... ``` oder ``` ... ```
    if echo "$input" | grep -q '```'; then
        # Extrahiere JSON aus Code-Blöcken
        local extracted=""
        # Versuche spezifische Muster
        extracted=$(echo "$input" | sed -n '/```json/,/```/p' | sed '1d;$d')
        if [[ -n "$extracted" && "$extracted" != "$input" ]]; then
            echo "$extracted"
            return
        fi
        
        # Allgemeine Objekt-Blöcke
        extracted=$(echo "$input" | sed -n '/```/,/```/p' | sed '1d;$d' | grep -E '^\s*\{.*\}\s*$' | head -1)
        if [[ -n "$extracted" ]]; then
            echo "$extracted"
            return
        fi
        
        # Array-Blöcke
        extracted=$(echo "$input" | sed -n '/```/,/```/p' | sed '1d;$d' | grep -E '^\s*\[.*\]\s*$' | head -1)
        if [[ -n "$extracted" ]]; then
            echo "$extracted"
            return
        fi
    fi
    
    echo "$input"
}

# Parse JSON mit Reparaturversuch
parse_json() {
    local raw_input="$1"
    local repair="${2:-true}"
    
    # Direkter Versuch
    if echo "$raw_input" | jq empty 2>/dev/null; then
        echo "$raw_input"
        return
    fi
    
    # Extrahiere aus Markdown
    local extracted
    extracted=$(extract_from_markdown "$raw_input")
    if [[ "$extracted" != "$raw_input" ]]; then
        if echo "$extracted" | jq empty 2>/dev/null; then
            echo "$extracted"
            return
        fi
    fi
    
    # Reparaturversuch
    if [[ "$repair" == true ]]; then
        local repaired
        repaired=$(repair_json_string "$raw_input")
        if echo "$repaired" | jq empty 2>/dev/null; then
            echo "$repaired"
            return
        fi
    fi
    
    log_error "Could not parse JSON"
    return 1
}

# Validiere als Tool Call
validate_tool_call() {
    local raw_json="$1"
    local expected_tool="${2:-}"
    
    # Parse das JSON
    local parsed
    parsed=$(parse_json "$raw_json" true) || return 1
    
    # Prüfe ob es sich um einen gültigen Tool-Call handelt
    local has_tool
    has_tool=$(echo "$parsed" | jq 'has("tool")' 2>/dev/null) || {
        log_error "Invalid tool call format"
        return 1
    }
    
    if [[ "$has_tool" != "true" ]]; then
        log_error "Missing 'tool' field"
        return 1
    fi
    
    # Prüfe Tool Name falls angegeben
    if [[ -n "$expected_tool" ]]; then
        local actual_tool
        actual_tool=$(echo "$parsed" | jq -r '.tool')
        if [[ "$actual_tool" != "$expected_tool" ]]; then
            log_error "Expected tool '$expected_tool', got '$actual_tool'"
            return 1
        fi
    fi
    
    echo "$parsed"
}

# Sicheres JSON Parsen mit Default
safe_json_loads() {
    local raw_input="$1"
    local default="${2:-null}"
    local repair="${3:-true}"
    
    if parsed=$(parse_json "$raw_input" "$repair" 2>/dev/null); then
        echo "$parsed"
    else
        echo "$default"
    fi
}

# Extrahiere JSON Objekte aus Text
extract_json_from_text() {
    local text="$1"
    local temp_file="$TEMP_DIR/json_extract.txt"
    
    # Schreibe Text in temporäre Datei
    echo "$text" > "$temp_file"
    
    # Finde potentielle JSON-Objekte mit Regex
    local results=()
    
    # Muster für Objekte und Arrays
    # Diese sind stark vereinfacht und funktionieren nur für einfache Fälle
    grep -oE '\{[^{}]*\}' "$temp_file" 2>/dev/null | while read -r obj; do
        if echo "$obj" | jq empty 2>/dev/null; then
            echo "$obj"
        fi
    done
    
    grep -oE '\[[^][]*\]' "$temp_file" 2>/dev/null | while read -r arr; do
        if echo "$arr" | jq empty 2>/dev/null; then
            echo "$arr"
        fi
    done
}

# Hauptprogramm
main() {
    init
    
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
            -*)
                log_error "Unknown option $1"
                exit 1
                ;;
            *)
                if [[ -z "$input" ]]; then
                    input="$1"
                else
                    log_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Prüfe ob Input vorhanden
    if [[ -z "$input" ]]; then
        log_error "No input provided"
        exit 1
    fi
    
    # Lese Input
    local content=""
    if [[ "$is_file" == true ]]; then
        if [[ ! -f "$input" ]]; then
            log_error "File not found: $input"
            exit 1
        fi
        content=$(cat "$input")
    else
        content="$input"
    fi
    
    # Parse JSON
    local result
    result=$(parse_json "$content" "$repair") || exit 1
    
    # Ausgabe formatieren
    if [[ "$pretty" == true ]]; then
        echo "$result" | jq '.'
    else
        echo "$result" | jq -c '.'
    fi
}

# Starte Hauptprogramm wenn direkt aufgerufen
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
