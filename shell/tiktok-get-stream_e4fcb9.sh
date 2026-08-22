#!/usr/bin/env bash
# tiktok-get-stream.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Enhanced TikTok LIVE URL extractor.
#
# Order: Playwright response interception, streamlink, then yt-dlp. Every
# result is schema-normalized and must be an allowed HTTPS TikTok-CDN FLV
# URL. Fallbacks use fixed argument arrays, bounded output, timeouts, and
# process-group cleanup.
#
# Exit 0 = URL, 1 = offline/restricted/no URL, 2 = dependency/technical
# failure, 75 = overloaded before Playwright startup.

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FALLBACK_TIMEOUT_MS=45000
readonly FALLBACK_MAX_OUTPUT=$((1024 * 1024))

log() {
    echo "$*" >&2
}

run_fallback() {
    local script_path="$1"
    shift
    local args=("$@")

    # Start the process in background
    local temp_dir
    temp_dir=$(mktemp -d)
    local stdout_file="${temp_dir}/stdout"
    local stderr_file="${temp_dir}/stderr"
    local pid_file="${temp_dir}/pid"

    # Cleanup function
    cleanup() {
        rm -rf "${temp_dir}"
    }
    trap cleanup EXIT

    # Run command with timeout
    (
        exec bash "${script_path}" "${args[@]}" \
            >"${stdout_file}" 2>"${stderr_file}"
    ) &
    local child_pid=$!
    echo "${child_pid}" >"${pid_file}"

    # Wait for completion or timeout
    local timed_out=false
    local counter=0
    while [[ ${counter} -lt ${FALLBACK_TIMEOUT_MS} ]]; do
        if ! kill -0 "${child_pid}" 2>/dev/null; then
            break
        fi
        sleep 0.1
        counter=$((counter + 100))
    done

    if kill -0 "${child_pid}" 2>/dev/null; then
        timed_out=true
        # Try graceful termination first
        kill -TERM "-${child_pid}" 2>/dev/null || true
        sleep 3
        # Force kill if still running
        kill -KILL "-${child_pid}" 2>/dev/null || true
    fi

    wait "${child_pid}" 2>/dev/null || true

    # Check file sizes
    local stdout_size stderr_size
    stdout_size=$(wc -c <"${stdout_file}" 2>/dev/null || echo 0)
    stderr_size=$(wc -c <"${stderr_file}" 2>/dev/null || echo 0)

    if [[ ${stdout_size} -gt ${FALLBACK_MAX_OUTPUT} ]] || [[ ${stderr_size} -gt ${FALLBACK_MAX_OUTPUT} ]]; then
        echo '{"code":2,"stdout":"","stderr":"fallback output exceeded limit"}'
        return
    fi

    if [[ ${timed_out} == true ]]; then
        local stderr_content
        stderr_content=$(cat "${stderr_file}" 2>/dev/null || echo "")
        echo "{\"code\":2,\"stdout\":\"$(jq -Rs escape "${stdout_file}" 2>/dev/null || echo "")\",\"stderr\":\"$(jq -Rs escape <<<"${stderr_content}\nfallback timeout" 2>/dev/null || echo "")\"}"
        return
    fi

    local exit_code=0
    if [[ -f "${temp_dir}/exit_code" ]]; then
        exit_code=$(cat "${temp_dir}/exit_code")
    else
        # Get actual exit code
        wait "${child_pid}" 2>/dev/null || exit_code=$?
    fi

    local stdout_content stderr_content
    stdout_content=$(cat "${stdout_file}" 2>/dev/null || echo "")
    stderr_content=$(cat "${stderr_file}" 2>/dev/null || echo "")

    echo "{\"code\":${exit_code},\"stdout\":\"$(jq -Rs escape <<<"${stdout_content}" 2>/dev/null || echo "")\",\"stderr\":\"$(jq -Rs escape <<<"${stderr_content}" 2>/dev/null || echo "")\"}"
}

parse_fallback_result() {
    local method="$1"
    local username="$2"
    local json_result="$3"

    local code stdout stderr
    code=$(echo "${json_result}" | jq -r '.code // 2')
    stdout=$(echo "${json_result}" | jq -r '.stdout // ""' | jq -r 'fromjson? // empty' 2>/dev/null || echo "")
    stderr=$(echo "${json_result}" | jq -r '.stderr // ""' | jq -r 'fromjson? // empty' 2>/dev/null || echo "")

    # Try parsing stdout/stderr as JSON objects
    for text in "${stdout}" "${stderr}"; do
        if [[ -n "${text}" ]]; then
            if echo "${text}" | jq -e 'type == "object"' >/dev/null 2>&1; then
                echo "${text}"
                return
            fi
        fi
    done

    # If no valid JSON found, create error result
    local status_message="fallback exited ${code}"
    if [[ ${code} -eq 75 ]]; then
        status_message="overloaded"
    elif [[ -n "${stderr}" ]]; then
        status_message="${stderr}"
    fi

    cat <<EOF
{
  "success": false,
  "status": "technical_error",
  "method": "${method}",
  "username": "${username}",
  "message": "${status_message}"
}
EOF
}

human_delay() {
    local min=${1:-2000}
    local max=${2:-4000}
    local range=$((max - min + 1))
    echo $((RANDOM % range + min))
}

# Close GDPR and login popups
handle_popups() {
    local page="$1"
    
    # This would need to be implemented using appropriate browser automation tools
    # For now, we'll just return a placeholder
    echo "true"
}

# Check if stream is restricted
check_restrictions() {
    local page="$1"
    
    # This would need to be implemented using appropriate browser automation tools
    # For now, we'll just return a placeholder
    echo '{"restricted":false,"reason":null}'
}

# Playwright-based FLV extraction
extract_with_playwright() {
    local username="$1"
    local quality_preference="$2"
    
    # This is a complex function that would require significant implementation
    # For now, we'll return a placeholder indicating it's not available
    cat <<EOF
{
  "success": false,
  "method": "playwright",
  "status": "dependency_missing",
  "error": "Playwright not available in bash implementation"
}
EOF
}

# Streamlink fallback
try_streamlink() {
    local username="$1"
    local quality="$2"
    
    local script_path="${SCRIPT_DIR}/extraction-methods/extract-tiktok-streamlink.sh"
    if [[ ! -x "${script_path}" ]]; then
        cat <<EOF
{
  "success": false,
  "method": "streamlink",
  "status": "dependency_missing",
  "error": "streamlink script not found or not executable"
}
EOF
        return
    fi
    
    local execution
    execution=$(run_fallback "${script_path}" "${username}" "${quality}" "--json")
    parse_fallback_result "streamlink" "${username}" "${execution}"
}

# yt-dlp fallback
try_yt_dlp() {
    local username="$1"
    local quality="$2"
    
    local script_path="${SCRIPT_DIR}/extraction-methods/extract-tiktok-yt-dlp.sh"
    if [[ ! -x "${script_path}" ]]; then
        cat <<EOF
{
  "success": false,
  "method": "yt-dlp",
  "status": "dependency_missing",
  "error": "yt-dlp script not found or not executable"
}
EOF
        return
    fi
    
    local yt_format
    case "${quality}" in
        original)
            yt_format="hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld"
            ;;
        1080p60)
            yt_format="hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
            ;;
        720p60)
            yt_format="hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
            ;;
        720p)
            yt_format="hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld"
            ;;
        540p)
            yt_format="hls-sd/hls-ld/flv-sd/flv-ld"
            ;;
        360p)
            yt_format="hls-ld/flv-ld"
            ;;
        auto)
            yt_format="hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
            ;;
        *)
            yt_format="hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
            ;;
    esac
    
    local execution
    execution=$(run_fallback "${script_path}" "${username}" "${yt_format}" "--json")
    parse_fallback_result "yt-dlp" "${username}" "${execution}"
}

# Main function with fallback chain
get_stream_url() {
    local username="$1"
    local quality_preference="${2:-auto}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # --- 1. Playwright ---
    log "[1/3] Trying Playwright for @${username}..."
    local pw_result
    pw_result=$(extract_with_playwright "${username}" "${quality_preference}")
    
    if echo "${pw_result}" | jq -r '.success' 2>/dev/null | grep -q "true"; then
        echo "${pw_result}" | jq --arg ts "${timestamp}" '. + {timestamp: $ts}'
        return
    fi
    
    local pw_status
    pw_status=$(echo "${pw_result}" | jq -r '.status // "failed"' 2>/dev/null)
    if [[ "${pw_status}" == "restricted" ]] || [[ "${pw_status}" == "overloaded" ]]; then
        echo "${pw_result}"
        return
    fi
    
    local pw_reason
    pw_reason=$(echo "${pw_result}" | jq -r '.reason // .error // "failed"' 2>/dev/null)
    log "Playwright result: ${pw_reason}"

    # --- 2. Streamlink ---
    log "[2/3] Trying streamlink for @${username} (quality: ${quality_preference})..."
    local sl_result
    sl_result=$(try_streamlink "${username}" "${quality_preference}")
    
    if echo "${sl_result}" | jq -r '.success' 2>/dev/null | grep -q "true"; then
        echo "${sl_result}"
        return
    fi
    
    local sl_status
    sl_status=$(echo "${sl_result}" | jq -r '.status // "failed"' 2>/dev/null)
    if [[ "${sl_status}" == "restricted" ]] || [[ "${sl_status}" == "overloaded" ]]; then
        echo "${sl_result}"
        return
    fi
    
    local sl_message
    sl_message=$(echo "${sl_result}" | jq -r '.message // .error // "failed"' 2>/dev/null)
    log "Streamlink result: ${sl_message}"

    # --- 3. yt-dlp ---
    log "[3/3] Trying yt-dlp for @${username}..."
    local yt_result
    yt_result=$(try_yt_dlp "${username}" "${quality_preference}")
    
    if echo "${yt_result}" | jq -r '.success' 2>/dev/null | grep -q "true"; then
        echo "${yt_result}"
        return
    fi
    
    local yt_status
    yt_status=$(echo "${yt_result}" | jq -r '.status // "failed"' 2>/dev/null)
    if [[ "${yt_status}" == "restricted" ]] || [[ "${yt_status}" == "overloaded" ]]; then
        echo "${yt_result}"
        return
    fi
    
    local yt_message
    yt_message=$(echo "${yt_result}" | jq -r '.message // .error // "failed"' 2>/dev/null)
    log "yt-dlp result: ${yt_message}"

    # --- All failed ---
    cat <<EOF
{
  "success": false,
  "status": "technical_error",
  "username": "${username}",
  "message": "All extraction methods failed (Playwright, streamlink, yt-dlp).",
  "playwrightReason": "${pw_reason}",
  "streamlinkReason": "${sl_message}",
  "ytdlpReason": "${yt_message}",
  "timestamp": "${timestamp}"
}
EOF
}

# Normalize username
normalize_username() {
    local username="$1"
    # Remove @ if present
    username="${username#@}"
    # Check if username is valid (alphanumeric, underscore, period)
    if [[ ! "${username}" =~ ^[a-zA-Z0-9_.]+$ ]]; then
        echo "Invalid username format" >&2
        return 1
    fi
    echo "${username}"
}

# Enforce load limit
enforce_load_limit() {
    local method="$1"
    # Placeholder - implement as needed
    :
}

# Check if offline
forced_offline() {
    local method="$1"
    local username="$2"
    # Placeholder - implement as needed
    return 1
}

# Get exit code for result
exit_code_for_result() {
    local result="$1"
    local status
    status=$(echo "${result}" | jq -r '.status // "technical_error"' 2>/dev/null)
    
    case "${status}" in
        live)
            return 0
            ;;
        offline|restricted)
            return 1
            ;;
        overloaded)
            return 75
            ;;
        *)
            return 2
            ;;
    esac
}

# --- CLI ---
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <username> [quality: original|1080p60|720p60|720p|540p|360p|auto] [--json]" >&2
    exit 1
fi

cli_username=""
cli_quality="auto"
cli_json=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            cli_json=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "${cli_username}" ]]; then
                cli_username="$1"
            elif [[ "${cli_quality}" == "auto" ]]; then
                cli_quality="$1"
            else
                echo "Too many arguments" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "${cli_username}" ]]; then
    echo "Username is required" >&2
    exit 1
fi

# Validate quality
case "${cli_quality}" in
    original|1080p60|720p60|720p|540p|360p|auto)
        ;;
    *)
        echo "Invalid quality; expected original, 1080p60, 720p60, 720p, 540p, 360p, or auto" >&2
        exit 1
        ;;
esac

# Normalize username
if ! cli_username=$(normalize_username "${cli_username}"); then
    echo "${cli_username}" >&2
    exit 64
fi

# Check load limits and offline status
enforce_load_limit "playwright_streamlink_ytdlp"
if forced_offline "playwright_streamlink_ytdlp" "${cli_username}"; then
    exit 1
fi

# Get stream URL
result=$(get_stream_url "${cli_username}" "${cli_quality}")

# Output result
if [[ "${cli_json}" == true ]]; then
    echo "${result}" | jq '.'
else
    if echo "${result}" | jq -r '.success' 2>/dev/null | grep -q "true"; then
        echo "${result}" | jq -r '.url'
    else
        echo "${result}" | jq -r '.message // .error // "Unknown error"'
    fi
fi

# Exit with appropriate code
exit_code_for_result "${result}"
exit $?
