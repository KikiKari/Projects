#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "2318de113c3fca7a9b48a4790d019c2f8772f0148273a9145feab0577ad772a9", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "shell"}
# json_batch_processor.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

# Globale Variablen
declare -a INPUTS=()
JSONL_MODE=false
REPAIR=true
WORKERS=4
OUTPUT_FILE=""
SUMMARY_ONLY=false
HAS_PYDANTIC=false

# Prüfe ob jq installiert ist
if ! command -v jq &>/dev/null; then
    echo "jq ist nicht installiert. Bitte installieren." >&2
    exit 1
fi

# Prüfe ob pydantic verfügbar ist (simuliert)
if python3 -c "import pydantic" 2>/dev/null; then
    HAS_PYDANTIC=true
fi

# Hilfsfunktionen
log_error() {
    echo "ERROR: $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

# Liest eine JSON-Lines Datei zeilenweise
read_jsonl() {
    local file="$1"
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$line" ]] && continue
        echo "$line_num|$line"
    done < "$file"
}

# Repariert einfache JSON-Fehler (sehr rudimentär)
repair_json() {
    local json_str="$1"
    # Entferne trailing Kommas vor } oder ]
    echo "$json_str" | sed -E 's/,([[:space:]]*[}\]])/\1/g'
}

# Parst JSON mit Fehlerbehandlung
parse_json() {
    local content="$1"
    local repair="${2:-false}"

    if [[ "$repair" == true ]]; then
        content=$(repair_json "$content")
    fi

    if echo "$content" | jq empty 2>/dev/null; then
        echo "$content"
        return 0
    else
        die "Invalid JSON"
    fi
}

# Verarbeitet eine einzelne Datei
process_single_file() {
    local file="$1"
    local index="$2"
    local repair="${3:-true}"

    if [[ ! -f "$file" ]]; then
        echo "{\"index\":$index,\"source\":\"$file\",\"success\":false,\"error\":\"File not found\"}"
        return 0
    fi

    local content
    content=$(cat "$file" 2>/dev/null) || {
        echo "{\"index\":$index,\"source\":\"$file\",\"success\":false,\"error\":\"Cannot read file\"}"
        return 0
    }

    local parsed_data
    if parsed_data=$(parse_json "$content" "$repair" 2>/dev/null); then
        echo "{\"index\":$index,\"source\":\"$file\",\"success\":true,\"data\":$(echo "$parsed_data" | jq -c .)}"
    else
        echo "{\"index\":$index,\"source\":\"$file\",\"success\":false,\"error\":\"JSON parsing failed\"}"
    fi
}

# Verarbeitet eine JSONL-Datei zeilenweise
process_jsonl_file() {
    local file="$1"
    local repair="${2:-true}"

    local temp_results
    temp_results=$(mktemp)

    while IFS='|' read -r line_num line_content; do
        local source="${file}:${line_num}"
        local parsed_data

        if parsed_data=$(parse_json "$line_content" "$repair" 2>/dev/null); then
            echo "{\"index\":$line_num,\"source\":\"$source\",\"success\":true,\"data\":$(echo "$parsed_data" | jq -c .)}" >> "$temp_results"
        else
            echo "{\"index\":$line_num,\"source\":\"$source\",\"success\":false,\"error\":\"JSON parsing failed\"}" >> "$temp_results"
        fi
    done < <(read_jsonl "$file")

    cat "$temp_results"
    rm -f "$temp_results"
}

# Schreibt Ergebnisse als JSONL
write_jsonl() {
    local results_file="$1"
    local output_path="$2"
    local only_successful="${3:-true}"

    if [[ "$only_successful" == true ]]; then
        jq 'select(.success == true)' "$results_file" > "$output_path"
    else
        cat "$results_file" > "$output_path"
    fi
}

# Zeigt Zusammenfassung an
show_summary() {
    local results_file="$1"
    local total success failed

    total=$(wc -l < "$results_file")
    success=$(jq -r 'select(.success == true) | .success' "$results_file" | wc -l)
    failed=$((total - success))

    echo "Processed: $total"
    echo "Successful: $success"
    echo "Failed: $failed"
}

# Hauptverarbeitungsfunktion
main() {
    local OPTIND opt

    while getopts "lrw:o:s-:" opt; do
        case $opt in
            l)
                JSONL_MODE=true
                ;;
            r)
                REPAIR=true
                ;;
            w)
                WORKERS="$OPTARG"
                ;;
            o)
                OUTPUT_FILE="$OPTARG"
                ;;
            s)
                SUMMARY_ONLY=true
                ;;
            -)
                case "${OPTARG}" in
                    jsonl)
                        JSONL_MODE=true
                        ;;
                    repair)
                        REPAIR=true
                        ;;
                    workers=*)
                        WORKERS="${OPTARG#*=}"
                        ;;
                    output=*)
                        OUTPUT_FILE="${OPTARG#*=}"
                        ;;
                    summary)
                        SUMMARY_ONLY=true
                        ;;
                    *)
                        die "Unbekannte Option --${OPTARG}"
                        ;;
                esac
                ;;
            \?)
                die "Ungültige Option: -$OPTARG"
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $# -eq 0 ]]; then
        die "Keine Eingabedateien angegeben."
    fi

    INPUTS=("$@")

    local temp_results
    temp_results=$(mktemp)

    if [[ "$JSONL_MODE" == true ]]; then
        # JSON-Lines Modus
        for input in "${INPUTS[@]}"; do
            process_jsonl_file "$input" "$REPAIR" >> "$temp_results"
        done
    else
        # Standard JSON Batch Modus
        local index=0
        for input in "${INPUTS[@]}"; do
            process_single_file "$input" "$index" "$REPAIR" >> "$temp_results"
            ((index++))
        done
    fi

    # Ausgabe
    local success_count=0
    local fail_count=0

    while IFS= read -r line; do
        if [[ $(echo "$line" | jq -r '.success') == "true" ]]; then
            ((success_count++))
            if [[ "$SUMMARY_ONLY" == false ]]; then
                echo "$line" | jq -r '.data'
            fi
        else
            ((fail_count++))
            if [[ "$SUMMARY_ONLY" == false ]]; then
                local source error
                source=$(echo "$line" | jq -r '.source')
                error=$(echo "$line" | jq -r '.error')
                echo "ERROR [$source]: $error" >&2
            fi
        fi
    done < "$temp_results"

    if [[ "$SUMMARY_ONLY" == true ]]; then
        show_summary "$temp_results"
    fi

    # Optional: JSONL Output
    if [[ -n "$OUTPUT_FILE" ]]; then
        write_jsonl "$temp_results" "$OUTPUT_FILE" "false"
        echo "Results written to: $OUTPUT_FILE" >&2
    fi

    rm -f "$temp_results"

    # Exit code
    if [[ $fail_count -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Starte Hauptprogramm
main "$@"
