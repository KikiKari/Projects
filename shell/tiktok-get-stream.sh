#!/usr/bin/env bash
# tiktok-get-stream.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# TikTok Stream URL Extractor
# Führt zuerst den profilgebundenen Status-Checker aus.
# Nur bei bestätigtem Live-Status werden FLV-Netzwerk-URLs erfasst.
# Offline wird keine Stream-URL ausgegeben.

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly USERNAME_RAW="${1:-}"
readonly USERNAME="${USERNAME_RAW#@}"

if [[ -z "$USERNAME" ]]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi

reject_busy_node() {
    local limit="${TIKTOK_MAX_LOAD_PER_CPU:-}"
    if [[ ! "$limit" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$limit <= 0" | bc -l) )); then
        return
    fi

    local cpu_count
    cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
    cpu_count=$((cpu_count > 0 ? cpu_count : 1))

    local load_avg
    load_avg=$(uptime | awk -F'average:|load average:' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | cut -d',' -f1)

    local normalized_load
    normalized_load=$(echo "scale=2; $load_avg / $cpu_count" | bc -l)

    local limit_bc
    limit_bc=$(echo "$limit" | bc -l)

    if (( $(echo "$normalized_load > $limit_bc" | bc -l) )); then
        echo "NODE_BUSY normalizedLoad=$normalized_load limit=$limit" >&2
        exit 75
    fi
}

verify_live_status() {
    local username="$1"
    local checker_path="$SCRIPT_DIR/tiktok-check-profile.js"
    local output
    local exit_code=0

    if ! output=$(timeout 60s node "$checker_path" "$username" 2>&1); then
        exit_code=$?
    fi

    if [[ $exit_code -eq 124 ]]; then
        echo "{\"isLive\":false,\"error\":\"Timeout checking live status\"}" >&2
        return 1
    fi

    if [[ -n "$output" ]]; then
        if echo "$output" | jq -e '.isLive == true' >/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

get_stream_url() {
    local username="$1"

    if ! verify_live_status "$username"; then
        echo "{\"username\":\"$username\",\"isLive\":false,\"error\":\"User is not currently live.\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        return 1
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    local log_file="$temp_dir/network_log.txt"
    local har_file="$temp_dir/recording.har"

    # Start browser with network logging
    local browser_pid
    local cdp_port=9222

    google-chrome \
        --headless=new \
        --disable-gpu \
        --no-sandbox \
        --remote-debugging-port=$cdp_port \
        --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        --enable-logging \
        --log-level=0 \
        --v=1 \
        --log-file="$log_file" \
        about:blank &> "$temp_dir/browser.log" &
    browser_pid=$!

    # Give browser time to start
    sleep 3

    # Check if browser started successfully
    if ! curl -s "http://localhost:$cdp_port/json/version" >/dev/null; then
        kill $browser_pid 2>/dev/null || true
        rm -rf "$temp_dir"
        echo "{\"error\":true,\"message\":\"Failed to start browser\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        return 1
    fi

    # Create new tab and navigate to live page
    local tab_json
    if ! tab_json=$(curl -s "http://localhost:$cdp_port/json/new?https://www.tiktok.com/@$username/live"); then
        kill $browser_pid 2>/dev/null || true
        rm -rf "$temp_dir"
        echo "{\"error\":true,\"message\":\"Failed to create browser tab\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        return 1
    fi

    local tab_id
    tab_id=$(echo "$tab_json" | jq -r '.id')

    # Enable network monitoring
    curl -s -X POST "http://localhost:$cdp_port/json/$tab_id" -d '{"method":"Network.enable","params":{}}' >/dev/null

    # Wait for page to load
    sleep 3

    # Accept cookies if present
    curl -s -X POST "http://localhost:$cdp_port/json/$tab_id" -d '{"method":"Runtime.evaluate","params":{"expression":"document.querySelector(\"button[data-e2e=\\\"cookie-banner-accept\\\"]\").click()"}}' >/dev/null 2>&1

    # Wait for stream to load
    sleep 18

    # Get network logs
    local network_log
    network_log=$(curl -s "http://localhost:$cdp_port/json/$tab_id" -d '{"method":"Network.getAllCookies","params":{}}' 2>/dev/null || echo "")

    # Kill browser
    kill $browser_pid 2>/dev/null || true
    wait $browser_pid 2>/dev/null || true

    # Parse logs for FLV URLs
    local flv_urls=()
    local log_content=""
    
    if [[ -f "$log_file" ]]; then
        log_content=$(cat "$log_file")
    fi
    
    # Simple grep-based extraction of FLV URLs
    while IFS= read -r line; do
        if [[ "$line" =~ (https?://[^[:space:]\"\'\)]*\.flv[^[:space:]\"\'\)]*) ]]; then
            flv_urls+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ (https?://[^[:space:]\"\'\)]*pull-flv[^[:space:]\"\'\)]*) ]]; then
            flv_urls+=("${BASH_REMATCH[1]}")
        fi
    done < <(echo "$log_content")

    # Remove duplicates
    local unique_urls=($(printf '%s\n' "${flv_urls[@]}" | sort -u))

    if [[ ${#unique_urls[@]} -gt 0 ]]; then
        # Create JSON output manually
        local json_streams="["
        local first=true
        for url in "${unique_urls[@]}"; do
            if [[ "$first" == true ]]; then
                first=false
            else
                json_streams+=","
            fi
            json_streams+="{\"url\":\"$url\",\"type\":\"flv\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
        done
        json_streams+="]"

        # Sort by quality (simple implementation)
        local sorted_streams=()
        for url in "${unique_urls[@]}"; do
            sorted_streams+=("$url")
        done

        # Output result
        echo "{"
        echo "  \"username\": \"$username\","
        echo "  \"isLive\": true,"
        echo "  \"streamCount\": ${#unique_urls[@]},"
        echo "  \"streams\": $json_streams,"
        echo "  \"vlcCommand\": \"vlc \\\"${unique_urls[0]}\\\"\","
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        echo "}"
        rm -rf "$temp_dir"
        return 0
    else
        rm -rf "$temp_dir"
        echo "{\"username\":\"$username\",\"isLive\":false,\"error\":\"No stream URLs found - user may not be live\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >&2
        return 1
    fi
}

main() {
    reject_busy_node
    if get_stream_url "$USERNAME"; then
        exit 0
    else
        exit 1
    fi
}

main
