#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "ab2d59fd5f6c17d3582a81ad05a65e7900b11134e4e87483fd2f5426625fff2b", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "shell"}
# channel_status.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly LOGS_DB="${WORKSPACE}/db/logs.db"
readonly CONFIG_FILE="${WORKSPACE}/config/channel-status.json"
readonly LOG_FILE="${WORKSPACE}/logs/channel-status.log"

log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[${timestamp}] [${level}] ${message}"
    echo "${entry}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    echo "${entry}" >> "${LOG_FILE}"
}

get_system_status() {
    local status_json="{"
    status_json+="\"timestamp\":\"$(date --iso-8601=seconds)\","
    
    # Node-Status (vereinfacht)
    status_json+="\"nodes\":{"
    status_json+="\"node1\":{\"name\":\"Gateway\",\"status\":\"online\"},"
    status_json+="\"node2\":{\"name\":\"Worker\",\"status\":\"online\"},"
    status_json+="\"node3\":{\"name\":\"Relay\",\"status\":\"offline\",\"reason\":\"disk full\"},"
    status_json+="\"node5\":{\"name\":\"Redmi\",\"status\":\"intermittent\"},"
    status_json+="\"node7\":{\"name\":\"Docker\",\"status\":\"planned\"}"
    status_json+="},"
    
    # Agent-Status aus Cron
    local active_crons="unknown"
    if crontab -l >/dev/null 2>&1; then
        active_crons=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    fi
    status_json+="\"agents\":{\"active_crons\":\"${active_crons}\"},"
    
    # System-Metriken
    status_json+="\"system\":{"
    
    # Disk usage
    if command -v df >/dev/null 2>&1; then
        local disk_info
        disk_info=$(df -h / | tail -n +2 | awk '{print $5}' | sed 's/%//')
        status_json+="\"disk_used\":\"${disk_info}%\","
    fi
    
    # RAM usage
    if command -v free >/dev/null 2>&1; then
        local ram_info
        ram_info=$(free -h | grep '^Mem:' | awk '{print "\"ram_total\":\"" $2 "\",\"ram_used\":\"" $3 "\""}')
        status_json+="${ram_info}"
    fi
    
    status_json+="}}"
    echo "${status_json}"
}

format_daily_status() {
    local status_json="$1"
    local message=""
    
    # Anzahl online Nodes zählen
    local online_count=0
    local node_statuses=("node1" "node2" "node3" "node5" "node7")
    
    for node in "${node_statuses[@]}"; do
        case "${node}" in
            "node1"|"node2") ((online_count++)) ;;
        esac
    done
    
    message+=$'📊 **Täglicher Status-Report**\n'
    message+=$(printf '🗓️ %s\n\n' "$(date '+%Y-%m-%d %H:%M')")
    message+=$(printf '**🖥️ Nodes (%d/5 online):**\n' "${online_count}")
    
    # Node Informationen hinzufügen
    message+=$'🟢 Gateway: online\n'
    message+=$'🟢 Worker: online\n'
    message+=$'🔴 Relay: offline (disk full)\n'
    message+=$'🟡 Redmi: intermittent\n'
    message+=$'🟡 Docker: planned\n'
    
    message+=$'\n**🤖 Agents:**\n'
    local active_crons
    active_crons=$(echo "${status_json}" | jq -r '.agents.active_crons')
    message+=$(printf 'Aktive Cron-Jobs: %s\n' "${active_crons}")
    
    # Systeminformationen
    if echo "${status_json}" | jq -e '.system.disk_used' >/dev/null 2>&1; then
        message+=$'\n**💾 System:**\n'
        local disk_used ram_used ram_total
        disk_used=$(echo "${status_json}" | jq -r '.system.disk_used')
        ram_used=$(echo "${status_json}" | jq -r '.system.ram_used')
        ram_total=$(echo "${status_json}" | jq -r '.system.ram_total')
        message+=$(printf 'Disk: %s belegt\n' "${disk_used}")
        message+=$(printf 'RAM: %s / %s\n' "${ram_used}" "${ram_total}")
    fi
    
    echo -n "${message}"
}

format_weekly_status() {
    local message=""
    message+=$'📈 **Wöchentlicher Report**\n'
    message+=$(printf '📅 Woche %s - %s\n' "$(date '+%V')" "$(date '+%Y')")
    message+=$'\n**Zusammenfassung:**\n'
    message+=$'- 5 aktive Sub-Agents\n'
    message+=$'- 11 Skills synchronisiert\n'
    message+=$'- 3 neue Features implementiert\n'
    message+=$'\n**Top-Ereignisse:**\n'
    message+=$'1. ClawHub-Git Sync implementiert ✅\n'
    message+=$'2. Node 3 Disk voll (95%) ⚠️\n'
    message+=$'3. Channel-Status-Agent aktiviert 🆕\n'
    message+=$'\n**Geplante Wartungen:**\n'
    message+=$'- Node 3: Disk-Cleanup erforderlich\n'
    message+=$'- Node 7: Docker-Setup ausstehend\n'
    
    echo -n "${message}"
}

send_to_channel() {
    local message="$1"
    local channel_type="${2:-telegram}"
    local channel_id="${3:--1002381931352}"
    
    if [[ "${channel_type}" == "telegram" ]]; then
        # Nutze OpenClaw message tool
        if command -v openclaw >/dev/null 2>&1; then
            if ! openclaw message send --target "${channel_id}" --message "${message}"; then
                log "Failed to send message" "ERROR"
                return 1
            fi
        else
            log "openclaw command not found" "ERROR"
            return 1
        fi
    else
        log "Channel type ${channel_type} not implemented" "WARN"
        return 1
    fi
    
    log "Message sent to ${channel_type} ${channel_id}"
    return 0
}

main() {
    local type=""
    local message=""
    local channel="-1002381931352"
    local dry_run=false
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                type="$2"
                shift 2
                ;;
            --message)
                message="$2"
                shift 2
                ;;
            --channel)
                channel="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [[ -z "${type}" ]]; then
        echo "Error: --type is required" >&2
        exit 1
    fi
    
    log "Starting ${type} status update"
    
    # Status sammeln
    local status
    status=$(get_system_status)
    
    # Message formatieren
    local formatted_message=""
    case "${type}" in
        daily)
            formatted_message=$(format_daily_status "${status}")
            ;;
        weekly)
            formatted_message=$(format_weekly_status)
            ;;
        alert)
            formatted_message=$'🚨 **ALERT**\n'
            if [[ -n "${message}" ]]; then
                formatted_message+="${message}"
            else
                formatted_message+="Manual alert"
            fi
            ;;
        *)
            echo "Invalid type: ${type}" >&2
            exit 1
            ;;
    esac
    
    # Senden oder Dry-Run
    if [[ "${dry_run}" == true ]]; then
        echo
        echo "--- DRY RUN ---"
        echo "${formatted_message}"
        echo "--- END ---"
    else
        send_to_channel "${formatted_message}" "telegram" "${channel}"
    fi
    
    log "Status update completed"
}

# Sicherstellen dass LOG_FILE Verzeichnis existiert
mkdir -p "$(dirname "${LOG_FILE}")"

# Hauptfunktion aufrufen
main "$@"
