#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "f8a789da5cb0553eb05110d836bae831281c75f56925c48d567930834e54889d", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "shell"}
# gen_tree.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

readonly ROOT="/workspace"
readonly OUT="/workspace/important/openclaw-tree.txt"
readonly MAX_DEPTH=6

# Unicode box drawing characters
readonly LAST_ITEM="└── "
readonly MIDDLE_ITEM="├── "
readonly INDENT_VERTICAL="│   "
readonly INDENT_SPACE="    "

collect() {
    local path="$1"
    local prefix="${2:-}"
    local depth="${3:-1}"
    local lines=()
    
    local entries
    entries=$(find "$path" -maxdepth 1 -mindepth 1 -not -path "$path" -printf '%f\n' 2>/dev/null | sort 2>/dev/null) || return 0
    
    local entry_array=()
    while IFS= read -r line; do
        entry_array+=("$line")
    done <<< "$entries"
    
    local total=${#entry_array[@]}
    local i=0
    
    for name in "${entry_array[@]}"; do
        local is_last=$((i == total - 1))
        local connector
        if (( is_last )); then
            connector="$LAST_ITEM"
        else
            connector="$MIDDLE_ITEM"
        fi
        
        lines+=("${prefix}${connector}${name}")
        
        local full_path="${path}/${name}"
        if [[ $depth -lt $MAX_DEPTH ]] && [[ -d "$full_path" ]] && [[ ! -L "$full_path" ]]; then
            local next_prefix
            if (( is_last )); then
                next_prefix="${prefix}${INDENT_SPACE}"
            else
                next_prefix="${prefix}${INDENT_VERTICAL}"
            fi
            local sublines
            sublines=$(collect "$full_path" "$next_prefix" $((depth + 1)))
            while IFS= read -r line; do
                lines+=("$line")
            done <<< "$sublines"
        fi
        
        ((i++))
    done
    
    printf '%s\n' "${lines[@]}"
}

main() {
    local body_lines
    body_lines=$(collect "$ROOT")
    
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    
    local header="# OpenClaw Workspace Tree
# Generiert: ${timestamp}
# Befehl: tree -a -L 6 ${ROOT} (emuliert via gen_tree.sh)
# Diese Datei wird automatisch von db-maintainer aktualisiert

.
"
    
    local content="${header}${body_lines}"
    if [[ -n "$body_lines" ]]; then
        content="${content}"$'\n'
    fi
    
    echo "$content" > "$OUT"
    
    local line_count=0
    while IFS= read -r _; do
        ((line_count++))
    done <<< "$content"
    
    echo "written ${OUT}: ${line_count} lines, ${#content} bytes"
}

main
