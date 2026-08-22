#!/bin/bash
# tiktok-common.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Shared TikTok LIVE safety contract: handle normalization, per-CPU load
# preflight, exact account LIVE selectors, strict HTTPS TikTok-CDN FLV
# validation, and normalized extractor statuses.

DEFAULT_MAX_LOAD_PER_CPU="1.5"
USERNAME_PATTERN='^[A-Za-z0-9._]{1,24}$'

FAILURE_STATUSES=("offline" "restricted" "overloaded" "dependency_missing" "technical_error")

# Helper function to check if array contains element
contains_element() {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

normalize_username() {
    local raw="$1"
    local username="${raw#@}"
    username="$(echo "$username" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    
    if ! [[ "$username" =~ $USERNAME_PATTERN ]]; then
        echo "Invalid TikTok username; expected 1-24 letters, digits, dots, or underscores" >&2
        return 1
    fi
    
    echo "$username"
}

load_state() {
    local cpu_count
    cpu_count=$(nproc 2>/dev/null || echo "1")
    cpu_count=$((cpu_count < 1 ? 1 : cpu_count))
    
    local observed_load
    if [ -n "${TIKTOK_TEST_LOAD_PER_CPU:-}" ]; then
        observed_load="$TIKTOK_TEST_LOAD_PER_CPU"
    else
        # Get 1-minute load average and divide by CPU count
        local load_avg
        load_avg=$(cut -d ' ' -f1 /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        observed_load=$(awk "BEGIN {print $load_avg/$cpu_count}")
    fi
    
    local max_load="${TIKTOK_MAX_LOAD_PER_CPU:-$DEFAULT_MAX_LOAD_PER_CPU}"
    
    # Validate numbers
    if ! awk "BEGIN {exit ($observed_load == $observed_load && $max_load == $max_load && $max_load > 0)}" 2>/dev/null; then
        echo "Invalid TikTok load configuration" >&2
        return 1
    fi
    
    local is_overloaded
    if awk "BEGIN {exit ($observed_load > $max_load)}"; then
        is_overloaded=true
    else
        is_overloaded=false
    fi
    
    echo "$is_overloaded|$observed_load|$max_load"
}

enforce_load_limit() {
    local method="$1"
    local state_result
    state_result=$(load_state) || return $?
    local is_overloaded over_load_per_cpu over_maximum
    IFS='|' read -r is_overloaded over_load_per_cpu over_maximum <<< "$state_result"
    
    if [ "$is_overloaded" = "false" ]; then
        return 0
    fi
    
    # Format to 3 decimal places
    local formatted_load
    formatted_load=$(printf "%.3f" "$over_load_per_cpu")
    
    cat >&2 <<EOF
{"status":"overloaded","method":"$method","loadPerCpu":$formatted_load,"maximum":$over_maximum,"message":"Host is overloaded; retry on another node or later"}
EOF
    exit 75
}

live_href_selectors() {
    local username="$1"
    local href="/@$username/live"
    echo "a[href=\"$href\"] a[href^=\"$href?\"]"
}

is_allowed_stream_url() {
    local value="$1"
    
    # Basic URL parsing using bash regex
    if ! [[ "$value" =~ ^https://([^/]+)(.*)$ ]]; then
        return 1
    fi
    
    local hostname="${BASH_REMATCH[1],,}"  # lowercase
    local pathname="${BASH_REMATCH[2],,}" # lowercase
    
    # Check if path includes .flv
    if [[ "$pathname" != *.flv* ]]; then
        return 1
    fi
    
    # Check hostname against pattern
    if [[ "$hostname" =~ (^|\.)tiktokcdn(-[a-z0-9-]+)?\.com$ ]]; then
        return 0
    fi
    
    return 1
}

is_successful_stream_response() {
    local status="$1"
    local value="$2"
    
    # Check if status is integer between 200 and 299
    if ! [[ "$status" =~ ^[0-9]+$ ]] || [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
        return 1
    fi
    
    is_allowed_stream_url "$value"
}

quality_key_from_url() {
    local value="$1"
    
    # Extract pathname from URL (basic approach)
    if [[ "$value" =~ https?://[^/]+(/.*) ]]; then
        local pathname="${BASH_REMATCH[1],,}"
        
        # Match quality patterns in order of precedence
        if [[ "$pathname" =~ _uhd_60\.(flv|m3u8) ]]; then
            echo "uhd_60"
            return 0
        elif [[ "$pathname" =~ _hd_60\.(flv|m3u8) ]]; then
            echo "hd_60"
            return 0
        elif [[ "$pathname" =~ _origin\.(flv|m3u8) ]]; then
            echo "origin"
            return 0
        elif [[ "$pathname" =~ _hd\.(flv|m3u8) ]]; then
            echo "hd"
            return 0
        elif [[ "$pathname" =~ _sd\.(flv|m3u8) ]]; then
            echo "sd"
            return 0
        elif [[ "$pathname" =~ _ld\.(flv|m3u8) ]]; then
            echo "ld"
            return 0
        elif [[ "$pathname" =~ _ao\.(flv|m3u8) ]]; then
            echo "ao"
            return 0
        fi
    fi
    
    echo ""
    return 0
}

normalize_extractor_result() {
    local json_input="$1"
    local method="$2"
    local username="$3"
    
    # Technical error template
    local technical_error="{\"success\":false,\"status\":\"technical_error\",\"method\":\"$method\",\"username\":\"$username\",\"message\":\"invalid extractor result\"}"
    
    # Check if input is valid JSON object
    if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$json_input"; then
        echo "$technical_error"
        return 0
    fi
    
    # Check success case
    if jq -e '.success == true' >/dev/null 2>&1 <<<"$json_input"; then
        local status url
        status=$(jq -r '.status // empty' <<<"$json_input")
        url=$(jq -r '.url // empty' <<<"$json_input")
        
        if [ "$status" = "live" ] && is_allowed_stream_url "$url"; then
            jq '. + {"success":true,"status":"live"}' <<<"$json_input"
            return 0
        else
            echo "$technical_error"
            return 0
        fi
    fi
    
    # Check explicit failure case
    if jq -e '.success == false' >/dev/null 2>&1 <<<"$json_input"; then
        local result_status result_method result_username
        
        result_status=$(jq -r '.status // ""' <<<"$json_input")
        result_method=$(jq -r ".method // \"$method\"" <<<"$json_input")
        result_username=$(jq -r ".username // \"$username\"" <<<"$json_input")
        
        # Validate status
        if ! contains_element "$result_status" "${FAILURE_STATUSES[@]}"; then
            result_status="technical_error"
        fi
        
        # Build result without url, streams, allUrls
        local base_result
        base_result=$(jq -n \
            --arg success "false" \
            --arg status "$result_status" \
            --arg method "$result_method" \
            --arg username "$result_username" \
            '{"success":$success,"status":$status,"method":$method,"username":$username}')
            
        # Merge with original data but exclude unwanted fields
        jq -s '.[0] * .[1]' \
           <(echo "$base_result") \
           <(jq 'del(.url,.streams,.allUrls)' <<<"$json_input")
        return 0
    fi
    
    echo "$technical_error"
    return 0
}

classify_final_failure() {
    local results_json="$1"
    
    # Extract unique statuses that are in FAILURE_STATUSES
    local statuses=()
    while IFS= read -r status; do
        if contains_element "$status" "${FAILURE_STATUSES[@]}"; then
            if ! contains_element "$status" "${statuses[@]}"; then
                statuses+=("$status")
            fi
        fi
    done < <(jq -r '.[] | select(. != null) | .status // empty' <<<"$results_json")
    
    # Priority order checking
    if contains_element "overloaded" "${statuses[@]}"; then
        echo "overloaded"
        return 0
    elif contains_element "restricted" "${statuses[@]}"; then
        echo "restricted"
        return 0
    elif contains_element "technical_error" "${statuses[@]}"; then
        echo "technical_error"
        return 0
    elif contains_element "offline" "${statuses[@]}"; then
        echo "offline"
        return 0
    elif contains_element "dependency_missing" "${statuses[@]}"; then
        echo "dependency_missing"
        return 0
    fi
    
    echo "technical_error"
    return 0
}

exit_code_for_result() {
    local result_json="$1"
    
    if jq -e '.success == true and .status == "live"' >/dev/null 2>&1 <<<"$result_json"; then
        return 0
    elif jq -e '.status == "overloaded"' >/dev/null 2>&1 <<<"$result_json"; then
        return 75
    elif jq -e '.status == "offline" or .status == "restricted"' >/dev/null 2>&1 <<<"$result_json"; then
        return 1
    fi
    
    return 2
}

classify_direct_live_state() {
    local username="$1"
    local current_path="$2"
    local title="$3"
    local body_text="$4"
    local successful_stream_response="$5"
    
    local expected_path="/@$username/live"
    
    if [ "$current_path" != "$expected_path" ]; then
        echo "{\"status\":\"offline\",\"reason\":\"target live page redirected\"}"
        return 0
    fi
    
    if [ "$successful_stream_response" = "true" ]; then
        echo "{\"status\":\"live\",\"reason\":\"successful TikTok CDN stream response\"}"
        return 0
    fi
    
    # Normalize text
    local normalized_body normalized_title account_live_title
    normalized_body=$(echo "$body_text" | tr -s '[:space:]' ' ' | tr '[:upper:]' '[:lower:]')
    normalized_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
    account_live_title=$(echo "$normalized_title" | grep -q "(@$(echo "$username" | tr '[:upper:]' '[:lower:]')) is live" && echo "true" || echo "false")
    
    # Check for ended markers
    local ended_markers=(
        "live has ended"
        "das live ist beendet"
        "live wurde beendet"
        "dieses live ist beendet"
        "stream has ended"
    )
    
    for marker in "${ended_markers[@]}"; do
        if [[ "$normalized_body" == *"$marker"* ]]; then
            echo "{\"status\":\"offline\",\"reason\":\"target live page reports ended stream\"}"
            return 0
        fi
    done
    
    # Check for restriction markers
    local restriction_markers=(
        "dieses live enthält themen, die von einigen als unangenehm empfunden werden könnten"
        "melde dich an, um das beste aus deiner tiktok-erfahrung herauszuholen"
        "bei tiktok anmelden"
        "melde dich an für das volle live-erlebnis"
        "melde dich an für das vollständige erlebnis"
        "this live may contain content that could be uncomfortable"
        "log in to tiktok"
        "log in for the full live experience"
        "mature content"
        "age-restricted"
        "viewer discretion"
    )
    
    if [ "$account_live_title" = "true" ]; then
        for marker in "${restriction_markers[@]}"; do
            if [[ "$normalized_body" == *"$marker"* ]]; then
                echo "{\"status\":\"restricted\",\"reason\":\"target live page requires authentication\"}"
                return 0
            fi
        done
        
        echo "{\"status\":\"restricted\",\"reason\":\"target is live but no accessible media response was available\"}"
        return 0
    fi
    
    echo "{\"status\":\"offline\",\"reason\":\"no account-specific live signal\"}"
    return 0
}

forced_offline() {
    local method="$1"
    local username="$2"
    
    if [ "${TIKTOK_TEST_OFFLINE:-}" != "1" ]; then
        echo "false"
        return 0
    fi
    
    cat >&2 <<EOF
{"success":false,"status":"offline","method":"$method","username":"$username","message":"forced offline test mode"}
EOF
    echo "true"
    return 0
}
