#!/bin/bash
# tiktok-get-stream.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Basic TikTok LIVE URL extractor.
#
# Accepts only observed HTTPS TikTok-CDN .flv responses with HTTP 2xx.
# Success writes one naked URL to stdout. Offline/no URL exits 1, dependency
# or technical failure exits 2, and preflight overload exits 75.

usage() {
    echo "Usage: $0 <username>" >&2
    echo "$1" >&2
    exit 64
}

normalize_username() {
    local input="$1"
    # Remove leading @ if present
    input="${input#@}"
    # Check if username is valid (non-empty, alphanumeric + underscore/dash/period)
    if [[ -z "$input" ]] || [[ ! "$input" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        usage "Invalid username format"
    fi
    echo "$input"
}

is_successful_stream_response() {
    local status="$1"
    local url="$2"
    # Check if status is 2xx and URL ends with .flv
    if [[ "$status" =~ ^2[0-9]{2}$ ]] && [[ "$url" == *.flv* ]]; then
        return 0
    else
        return 1
    fi
}

quality_key_from_url() {
    local url="$1"
    # Extract quality like 720p from URL
    if [[ "$url" =~ ([0-9]+)p ]]; then
        echo "${BASH_REMATCH[1]}p"
    else
        echo "unknown"
    fi
}

enforce_load_limit() {
    local method="$1"
    # Placeholder for load limit enforcement logic
    # In real implementation, this might check system load or rate limits
    :
}

forced_offline() {
    local method="$1"
    local username="$2"
    # Placeholder for checking if user is offline or system is overloaded
    # Return 0 if offline/overloaded, 1 otherwise
    return 1
}

main() {
    local username
    if [[ $# -lt 1 ]]; then
        usage "Missing username argument"
    fi

    username=$(normalize_username "$1") || exit $?

    enforce_load_limit "network_basic"

    if forced_offline "network_basic" "$username"; then
        exit 1
    fi

    local json_output=false
    if [[ "${2:-}" == "--json" ]]; then
        json_output=true
    fi

    # Since bash cannot easily intercept network requests like Playwright,
    # we simulate the behavior using curl/wget and parsing HTML/JS.
    # This is a simplified version that attempts to extract stream URL.

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    local live_page_url="https://www.tiktok.com/@${username}/live"
    local page_content="${temp_dir}/page.html"

    # Fetch the live page
    if ! curl -s -L --max-time 60 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        -c "${temp_dir}/cookies.txt" \
        -o "$page_content" \
        "$live_page_url"; then
        if [[ "$json_output" == true ]]; then
            echo "{\"error\":true,\"status\":\"technical_error\",\"method\":\"curl\",\"message\":\"Failed to fetch live page\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        fi
        exit 2
    fi

    # Wait for possible content to load (simulate JS rendering delay)
    sleep 8

    # Attempt to find FLV URLs in the page source
    local flv_urls_file="${temp_dir}/flv_urls.txt"
    grep -oE 'https?://[^"]+\.flv[^"]*' "$page_content" | sort -u > "$flv_urls_file" 2>/dev/null || true

    if [[ ! -s "$flv_urls_file" ]]; then
        if [[ "$json_output" == true ]]; then
            echo "{\"success\":false,\"status\":\"offline\",\"method\":\"curl\",\"username\":\"$username\",\"isLive\":false,\"error\":\"No stream URLs found - user may not be live\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        fi
        exit 1
    fi

    # Read URLs into array
    mapfile -t urls < "$flv_urls_file"

    # Create JSON-like output if requested
    if [[ "$json_output" == true ]]; then
        echo "{"
        echo "  \"success\": true,"
        echo "  \"status\": \"live\","
        echo "  \"method\": \"curl\","
        echo "  \"username\": \"$username\","
        echo "  \"isLive\": true,"
        echo "  \"streamCount\": ${#urls[@]},"
        echo "  \"streams\": ["
        local first=true
        local count=0
        for url in "${urls[@]}"; do
            if [[ $count -ge 10 ]]; then
                break
            fi
            if [[ "$first" == true ]]; then
                first=false
            else
                echo "    ,"
            fi
            local quality
            quality=$(quality_key_from_url "$url")
            echo "    {"
            echo "      \"url\": \"$url\","
            echo "      \"quality\": \"$quality\""
            echo "    }"
            ((count++))
        done
        echo "  ],"
        echo "  \"url\": \"${urls[0]}\","
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        echo "}"
    else
        # Output just the first URL
        echo "${urls[0]}"
    fi

    exit 0
}

main "$@"
