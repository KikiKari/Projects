#!/usr/bin/env bash
# verify-downloads.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:site/scripts/verify-downloads.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/scripts/verify-downloads.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Verify the candidate's actual HTTP downloads against committed files.

usage() {
    echo "Usage: $0 --base-url BASE_URL --report REPORT_FILE" >&2
    exit 1
}

base_url=""
report=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url)
            base_url="$2"
            shift 2
            ;;
        --report)
            report="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z "$base_url" ]] || [[ -z "$report" ]]; then
    usage
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$script_dir")
checksum="$root/public/downloads/tiktok-live-companion-0.8.2-SHA256.txt"

if [[ ! -f "$checksum" ]]; then
    echo "Checksum file not found: $checksum" >&2
    exit 1
fi

results=()

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
        continue
    fi

    expected="${line%%  *}"
    name="${line#*  }"

    url="${base_url%/}/downloads/$name"
    
    # Download file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' EXIT
    
    if ! curl -s -L --max-time 30 -o "$temp_file" "$url"; then
        echo "Failed to download: $url" >&2
        exit 1
    fi

    # Calculate SHA256
    actual=$(sha256sum "$temp_file" | cut -d' ' -f1)

    # Compare with expected hash
    if [[ "$actual" != "$expected" ]]; then
        echo "HTTP artifact hash mismatch: $name" >&2
        exit 1
    fi

    # Compare with local file
    local_file="$root/public/downloads/$name"
    if [[ ! -f "$local_file" ]]; then
        echo "Local file not found: $local_file" >&2
        exit 1
    fi

    local_hash=$(sha256sum "$local_file" | cut -d' ' -f1)
    if [[ "$actual" != "$local_hash" ]]; then
        echo "HTTP artifact mismatch: $name" >&2
        exit 1
    fi

    # Test ZIP integrity
    if ! unzip -tqq "$temp_file" >/dev/null 2>&1; then
        echo "Corrupt archive: $name" >&2
        exit 1
    fi

    # Check extension version if it's an extension
    if [[ "$name" == *-extension-* ]]; then
        manifest_version=$(unzip -p "$temp_file" manifest.json | jq -r '.version')
        if [[ "$manifest_version" != "0.8.2" ]]; then
            echo "Wrong extension version: $manifest_version" >&2
            exit 1
        fi

        # Check source files
        plugin_source_dir="$root/../plugin-source/browser-extension"
        for source in background.js content.js sidepanel.js sidepanel.html; do
            if ! diff -q <(unzip -p "$temp_file" "$source") "$plugin_source_dir/$source" >/dev/null 2>&1; then
                echo "Extension source mismatch: $source" >&2
                exit 1
            fi
        done
    fi

    # Get file size
    bytes=$(stat -c%s "$temp_file")

    # Add to results
    results+=("{\"name\": \"$name\", \"sha256\": \"$actual\", \"bytes\": $bytes, \"verified\": true}")
done < "$checksum"

# Create JSON output
result_json="{\"base_url\": \"$base_url\", \"artifacts\": [$(IFS=,; echo "${results[*]}")]}"
echo "$result_json" | jq . > "$report"

# Print results
echo "["
first=true
for result in "${results[@]}"; do
    if [[ "$first" == true ]]; then
        echo "$result"
        first=false
    else
        echo ",$result"
    fi
done
echo "]"
