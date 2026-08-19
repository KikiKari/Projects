#!/bin/bash
# secret-scan.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/secret-scan.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

root="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
declare -A skipped
skipped[node_modules]=1
skipped[.next]=1
skipped[.git]=1
skipped[.pytest_cache]=1
skipped[__pycache__]=1
skipped["media-production/raw"]=1
skipped["media-production/private"]=1

patterns=(
    'sk-\(proj\|svcacct\|ant\|or-v1\|admin\)-[A-Za-z0-9_-]\{20,\}'
    '\(nvapi\|lin_api\|ntn\|vcp\)_[A-Za-z0-9_-]\{20,\}'
    'ELEVENLABS_API_KEY[[:space:]]*=[[:space:]]*["'\'']\{0,1\}[A-Za-z0-9]\{20,\}'
    'WAVESPEED_API_KEY[[:space:]]*=[[:space:]]*["'\'']\{0,1\}[A-Za-z0-9]\{20,\}'
)

findings=()

function walk() {
    local dir="$1"
    local rel_prefix="${2:-}"

    for entry in "$dir"/*; do
        if [[ ! -e "$entry" ]]; then
            continue
        fi

        basename_entry=$(basename "$entry")
        rel_path="${rel_prefix:+$rel_prefix/}$basename_entry"

        if [[ "$basename_entry" == ".env" ]] || \
           ([[ "$basename_entry" == .env.* ]] && [[ "$basename_entry" != ".env.example" ]]) || \
           [[ -n "${skipped[$rel_path]:-}" ]] || \
           [[ -n "${skipped[$basename_entry]:-}" ]] || \
           [[ "$rel_path" =~ ^media-production/(raw|private)(/.*)?$ ]]; then
            continue
        fi

        if [[ -d "$entry" ]]; then
            walk "$entry" "$rel_path"
        elif [[ -f "$entry" ]] && [[ $(stat -c%s "$entry") -lt 2000000 ]]; then
            matched=false
            for pattern in "${patterns[@]}"; do
                if grep -q "$pattern" "$entry"; then
                    findings+=("$rel_path")
                    matched=true
                    break
                fi
            done
        fi
    done
}

walk "$root"

if [[ ${#findings[@]} -gt 0 ]]; then
    unique_findings=($(printf '%s\n' "${findings[@]}" | sort -u))
    IFS=', '
    echo "Secret-Scan fehlgeschlagen: ${unique_findings[*]}" >&2
    exit 1
fi

echo "Secret-Scan bestanden."
