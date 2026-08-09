#!/usr/bin/env bash
# json_batch_processor.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

# Globale Variablen
declare -a INPUTS=()
JSONL_MODE=false
REPAIR=true
WORKERS=4
OUTPUT=""
SUMMARY=false
HAS_PYDANTIC=false

# Prüfe ob jq installiert ist
if ! command -v jq &>/dev/null; then
    echo "jq ist nicht installiert. Bitte installieren Sie jq." >&2
    exit 1
fi

# Prüfe ob pydantic verfügbar ist (durch python)
if python3 -c "import pydantic" &>/dev/null; then
    HAS_PYDANTIC=true
fi

# Lese Kommandozeilenargumente
while [[ $# -gt 0 ]]; do
    case $1 in
        --jsonl|-l)
            JSONL_MODE=true
            shift
            ;;
        --repair|-r)
            REPAIR=true
            shift
            ;;
        --no-repair)
            REPAIR=false
            shift
            ;;
        --workers|-w)
            WORKERS="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT="$2"
            shift 2
            ;;
        --summary|-s)
            SUMMARY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] INPUTS..."
            echo "Batch JSON Processor"
            echo ""
            echo "Arguments:"
            echo "  INPUTS...                 JSON files to process"
            echo ""
            echo "Options:"
            echo "  --jsonl, -l               Treat inputs as JSON-Lines files"
            echo "  --repair, -r              Enable JSON repair (default: true)"
            echo "  --no-repair               Disable JSON repair"
            echo "  --workers, -w WORKERS     Parallel workers (default: 4)"
            echo "  --output, -o OUTPUT       Output JSON-Lines file"
            echo "  --summary, -s             Show summary only"
            echo "  --help, -h                Show this message and exit"
            exit 0
            ;;
        *)
            INPUTS+=("$1")
            shift
            ;;
    esac
done

# Prüfe ob Eingaben vorhanden sind
if [[ ${#INPUTS[@]} -eq 0 ]]; then
    echo "Keine Eingabedateien angegeben." >&2
    exit 1
fi

# Repariere JSON (einfache Methode)
repair_json() {
    local content="$1"
    # Entferne führende/trailing Whitespace und versuche grundlegende Reparaturen
    echo "$content" | sed -e 's/,\s*}/}/g' -e 's/,\s*]/]/g'
}

# Parse JSON mit Reparatur
parse_json() {
    local content="$1"
    local repair="$2"
    
    if [[ "$repair" == true ]]; then
        content=$(repair_json "$content")
    fi
    
    if echo "$content" | jq empty 2>/dev/null; then
        echo "$content"
    else
        echo "JSON decode error" >&2
        return 1
    fi
}

# Verarbeite eine einzelne Datei
process_file() {
    local file_path="$1"
    local idx="$2"
    local repair="$3"
    
    if [[ ! -f "$file_path" ]]; then
        echo "{\"index\":$idx,\"source\":\"$file_path\",\"success\":false,\"error\":\"File not found\"}"
        return 0
    fi
    
    local content
    content=$(cat "$file_path" 2>/dev/null) || {
        echo "{\"index\":$idx,\"source\":\"$file_path\",\"success\":false,\"error\":\"Cannot read file\"}"
        return 0
    }
    
    local parsed
    if parsed=$(parse_json "$content" "$repair"); then
        echo "{\"index\":$idx,\"source\":\"$file_path\",\"success\":true,\"data\":$(echo "$parsed" | jq -c .)}"
    else
        echo "{\"index\":$idx,\"source\":\"$file_path\",\"success\":false,\"error\":\"JSON decode error\"}"
    fi
}

# Verarbeite JSONL-Datei
process_jsonl_file() {
    local file_path="$1"
    local repair="$2"
    local idx=0
    local results=()
    
    if [[ ! -f "$file_path" ]]; then
        echo "{\"index\":0,\"source\":\"$file_path\",\"success\":false,\"error\":\"File not found\"}"
        return 0
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((idx++))
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local source="$file_path:$idx"
        local parsed
        if parsed=$(parse_json "$line" "$repair"); then
            echo "{\"index\":$idx,\"source\":\"$source\",\"success\":true,\"data\":$(echo "$parsed" | jq -c .)}"
        else
            echo "{\"index\":$idx,\"source\":\"$source\",\"success\":false,\"error\":\"JSON decode error\"}"
        fi
    done < "$file_path"
}

# Schreibe Ergebnisse als JSONL
write_jsonl() {
    local results=("$@")
    local output_file="$OUTPUT"
    local only_successful=true
    
    if [[ -n "$output_file" ]]; then
        {
            for result in "${results[@]}"; do
                if [[ "$only_successful" == true ]]; then
                    if echo "$result" | jq -r '.success' 2>/dev/null | grep -q true; then
                        echo "$result"
                    fi
                else
                    echo "$result"
                fi
            done
        } > "$output_file"
        echo "Results written to: $output_file" >&2
    fi
}

# Hauptverarbeitung
main() {
    local all_results=()
    local successful=0
    local failed=0
    
    if [[ "$JSONL_MODE" == true ]]; then
        # JSON-Lines Modus
        for input_path in "${INPUTS[@]}"; do
            while IFS= read -r result; do
                all_results+=("$result")
                if echo "$result" | jq -r '.success' 2>/dev/null | grep -q true; then
                    ((successful++))
                else
                    ((failed++))
                fi
            done < <(process_jsonl_file "$input_path" "$REPAIR")
        done
    else
        # Standard JSON Batch
        local temp_dir
        temp_dir=$(mktemp -d)
        trap 'rm -rf "$temp_dir"' EXIT
        
        local idx=0
        local pids=()
        for input_path in "${INPUTS[@]}"; do
            (
                result=$(process_file "$input_path" "$idx" "$REPAIR")
                echo "$result" > "$temp_dir/result_$idx"
            ) &
            pids+=($!)
            ((idx++))
            
            # Begrenze parallele Prozesse
            if [[ ${#pids[@]} -ge $WORKERS ]]; then
                for pid in "${pids[@]}"; do
                    wait "$pid"
                done
                pids=()
            fi
        done
        
        # Warte auf alle verbleibenden Prozesse
        for pid in "${pids[@]}"; do
            wait "$pid"
        done
        
        # Sammle Ergebnisse
        for ((i=0; i<idx; i++)); do
            if [[ -f "$temp_dir/result_$i" ]]; then
                result=$(cat "$temp_dir/result_$i")
                all_results+=("$result")
                if echo "$result" | jq -r '.success' 2>/dev/null | grep -q true; then
                    ((successful++))
                else
                    ((failed++))
                fi
            fi
        done
    fi
    
    # Ausgabe
    if [[ "$SUMMARY" == true ]]; then
        echo "Processed: $((successful + failed))"
        echo "Successful: $successful"
        echo "Failed: $failed"
    else
        for result in "${all_results[@]}"; do
            if echo "$result" | jq -r '.success' 2>/dev/null | grep -q true; then
                echo "$result" | jq -r '.data'
            else
                echo "ERROR [$(echo "$result" | jq -r '.source')]: $(echo "$result" | jq -r '.error')" >&2
            fi
        done
    fi
    
    # Optional: JSONL Output
    if [[ -n "$OUTPUT" ]]; then
        write_jsonl "${all_results[@]}"
    fi
    
    # Exit code
    if [[ $failed -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main
