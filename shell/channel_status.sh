#!/usr/bin/env bash
# channel_status.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly LOGS_DB="${WORKSPACE}/db/logs.db"
readonly CONFIG_FILE="${WORKSPACE}/config/channel-status.json"
readonly LOG_FILE="${WORKSPACE}/logs/channel-status.log"

# Logging
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[${timestamp}] [${level}] ${message}"
    echo "${entry}"
    echo "${entry}" >> "${LOG_FILE}"
}

# Sammelt System-Status
get_system_status() {
    local status_json
    status_json="{"
    status_json+="\"timestamp\":\"$(date -Iseconds)\","
    status_json+="\"nodes\":{"
    status_json+="\"node1\":{\"name\":\"Gateway\",\"status\":\"online\"},"
    status_json+="\"node2\":{\"name\":\"Worker\",\"status\":\"online\"},"
    status_json+="\"node3\":{\"name\":\"Relay\",\"status\":\"offline\",\"reason\":\"disk full\"},"
    status_json+="\"node5\":{\"name\":\"Redmi\",\"status\":\"intermittent\"},"
    status_json+="\"node7\":{\"name\":\"Docker\",\"status\":\"planned\"}"
    status_json+="},"
    status_json+="\"agents\":{},"
    status_json+="\"system\":{}"
    status_json+="}"
    
    # Agent-Status aus Cron
    local cron_lines
    cron_lines=$(crontab -l 2>/dev/null | grep -v '^#' | wc -l) || cron_lines="unknown"
    status_json=$(echo "${status_json}" | jq ".agents.active_crons=\"${cron_lines}\"")
    
    # System-Metriken
    local disk_used
    disk_used=$(df -h / | awk 'NR==2 {print $5}')
    status_json=$(echo "${status_json}" | jq ".system.disk_used=\"${disk_used}\"")
    
    local ram_info
    ram_info=$(free -h | awk 'NR==2 {print $2" "$3}')
    local ram_total ram_used
    ram_total=$(echo "${ram_info}" | cut -d' ' -f1)
    ram_used=$(echo "${ram_info}" | cut -d' ' -f2)
    status_json=$(echo "${status_json}" | jq ".system.ram_total=\"${ram_total}\"" | jq ".system.ram_used=\"${ram_used}\"")
    
    echo "${status_json}"
}

# Formatiert täglichen Status
format_daily_status() {
    local status_json="$1"
    local message=""
    message+=$'📊 **Täglicher Status-Report**\n'
    message+=$(date '+🗓️ %Y-%m-%d %H:%M')$'\n\n'
    
    message+=$'**🖥️ Nodes (**'
    local online_nodes
    online_nodes=$(echo "${status_json}" | jq -r '.nodes | to_entries[] | select(.value.status == "online")' | wc -l)
    message+="${online_nodes}/5 online):"$'\n'
    
    local nodes
    nodes=$(echo "${status_json}" | jq -r '.nodes | to_entries[] | "\(.key):\(.value.name):\(.value.status):\(.value.reason // "")"')
    while IFS=':' read -r node_id name status reason; do
        local emoji
        case "${status}" in
            "online") emoji="🟢" ;;
            "offline") emoji="🔴" ;;
            *) emoji="🟡" ;;
        esac
        message+="${emoji} ${name}: ${status}"
        if [[ -n "${reason}" && "${reason}" != "null" ]]; then
            message+=" (${reason})"
        fi
        message+=$'\n'
    done <<< "${nodes}"
    
    message+=$'\n**🤖 Agents:**\n'
    local active_crons
    active_crons=$(echo "${status_json}" | jq -r '.agents.active_crons')
    message+="Aktive Cron-Jobs: ${active_crons}"$'\n'
    
    if echo "${status_json}" | jq -e '.system.disk_used' >/dev/null 2>&1; then
        message+=$'\n**💾 System:**\n'
        local disk_used ram_used ram_total
        disk_used=$(echo "${status_json}" | jq -r '.system.disk_used')
        ram_used=$(echo "${status_json}" | jq -r '.system.ram_used')
        ram_total=$(echo "${status_json}" | jq -r '.system.ram_total')
        message+="Disk: ${disk_used} belegt"$'\n'
        message+="RAM: ${ram_used} / ${ram_total}"$'\n'
    fi
    
    echo -n "${message}"
}

# Formatiert wöchentlichen Status
format_weekly_status() {
    local message=""
    message+=$'📈 **Wöchentlicher Report**\n'
    message+=$(date '+📅 Woche %V - %Y')$'\n\n'
    
    message+=$'**Zusammenfassung:**\n'
    message+=$'- 5 aktive Sub-Agents\n'
    message+=$'- 11 Skills synchronisiert\n'
    message+=$'- 3 neue Features implementiert\n\n'
    
    message+=$'**Top-Ereignisse:**\n'
    message+=$'1. ClawHub-Git Sync implementiert ✅\n'
    message+=$'2. Node 3 Disk voll (95%) ⚠️\n'
    message+=$'3. Channel-Status-Agent aktiviert 🆕\n\n'
    
    message+=$'**Geplante Wartungen:**\n'
    message+=$'- Node 3: Disk-Cleanup erforderlich\n'
    message+=$'- Node 7: Docker-Setup ausstehend\n'
    
    echo -n "${message}"
}

# Sendet Nachricht an Channel
send_to_channel() {
    local message="$1"
    local channel_type="${2:-telegram}"
    local channel_id="${3:--1002381931352}"
    
    if [[ "${channel_type}" == "telegram" ]]; then
        local cmd=(openclaw message send --target "${channel_id}" --message "${message}")
    else
        log "Channel type ${channel_type} not implemented" "WARN"
        return 1
    fi
    
    if "${cmd[@]}"; then
        log "Message sent to ${channel_type} ${channel_id}"
        return 0
    else
        log "Failed to send message" "ERROR"
        return 1
    fi
}

# Hauptfunktion
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
                echo "Unbekannte Option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [[ -z "${type}" ]]; then
        echo "Fehler: --type ist erforderlich" >&2
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
            formatted_message=$'🚨 **ALERT**\n'"${message:-Manual alert}"
            ;;
        *)
            echo "Unbekannter Typ: ${type}" >&2
            exit 1
            ;;
    esac
    
    # Senden oder Dry-Run
    if [[ "${dry_run}" == true ]]; then
        echo
        echo "--- DRY RUN ---"
        echo "${formatted_message}"
        echo "--- END ---"
        echo
    else
        send_to_channel "${formatted_message}" "telegram" "${channel}"
    fi
    
    log "Status update completed"
}

# Sicherstellen, dass das Log-Verzeichnis existiert
mkdir -p "$(dirname "${LOG_FILE}")"

# Hauptfunktion aufrufen
main "$@"
