#!/usr/bin/env bash
# tree_fallback.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:db-maintainer/scripts/tree_fallback.py
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Fallback tree generator for when the `tree` binary is unavailable.
#
# Produces output similar to `tree -a -L <depth>` and writes it to
# important/openclaw-tree.txt with a timestamp header.

WORKSPACE="/workspace"
DEPTH=6
OUT="$WORKSPACE/important/openclaw-tree.txt"

# Skip directories
declare -A SKIP
SKIP[".git"]=1
SKIP["node_modules"]=1
SKIP["__pycache__"]=1
SKIP["venv"]=1
SKIP[".cache"]=1
SKIP[".npm"]=1
SKIP[".local"]=1

# Function to check if item should be skipped
should_skip() {
    local name="$1"
    [[ -n "${SKIP[$name]+isset}" ]]
}

# Recursive function to walk directory tree
walk() {
    local path="$1"
    local prefix="${2:-}"
    local depth="${3:-0}"
    local lines=()

    if (( depth >= DEPTH )); then
        return
    fi

    # Get all entries in the directory, sorted by type (dirs first) then name
    local entries=()
    local entry_paths=()
    while IFS= read -r -d '' entry; do
        local basename_entry="${entry##*/}"
        if ! should_skip "$basename_entry"; then
            entries+=("$basename_entry")
            entry_paths+=("$entry")
        fi
    done < <(find "$path" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | sort -z)

    local i=0
    local total=${#entries[@]}
    while (( i < total )); do
        local entry="${entry_paths[$i]}"
        local entry_name="${entries[$i]}"
        local last=$(( i == total - 1 ))
        local connector="├── "
        local extension="│   "

        if (( last )); then
            connector="└── "
            extension="    "
        fi

        local suffix=""
        if [[ -d "$entry" && ! -L "$entry" ]]; then
            suffix="/"
        fi

        lines+=("${prefix}${connector}${entry_name}${suffix}")

        if [[ -d "$entry" && ! -L "$entry" ]]; then
            walk "$entry" "${prefix}${extension}" $((depth + 1))
        fi

        ((i++))
    done

    printf '%s\n' "${lines[@]}"
}

main() {
    mkdir -p "$(dirname "$OUT")"

    # Header
    local header="# OpenClaw Workspace Tree
# Generiert: $(date --iso-8601=seconds)
# Fallback (tree binary nicht verfuegbar), Tiefe $DEPTH
# Diese Datei wird automatisch von db-maintainer aktualisiert

$WORKSPACE
"

    # Body from walk function
    local body
    body=$(walk "$WORKSPACE")

    # Write to file
    echo -n "$header" > "$OUT"
    echo "$body" >> "$OUT"

    # Count lines (header + body lines)
    local line_count
    line_count=$(echo "$body" | wc -l)
    ((line_count++)) # Add one for the workspace root line
    
    echo "openclaw-tree.txt aktualisiert (Fallback): $OUT ($line_count Eintraege)"
}

main "$@"
