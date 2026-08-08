#!/usr/bin/env bash
# channel_status.js — portiert nach shell
# Quelle: javascript, Projects@abstractions:javascript/channel_status.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# channel_status.sh — portiert nach bash
# Quelle: javascript, channel_status.js
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly LOGS_DB="${WORKSPACE}/db/logs.db"
readonly CONFIG_FILE="${WORKSPACE}/config/channel-status.json"
readonly LOG_FILE="${WORKSPACE}/logs/channel-status.log"

# Log-Funktion
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[${timestamp}] [${level}] ${message}"
    echo "${entry}" | tee -a "${LOG_FILE}"
}

# System-Status sammeln
get_system_status() {
    local status_json="{"
    status_json+="\"timestamp\":\"$(date -Iseconds)\","
    status_json+="\"nodes\":{"
    status_json+="\"node1\":{\"name\":\"Gateway\",\"status\":\"online\"},"
    status_json+="\"node2\":{\"name\":\"Worker\",\"status\":\"online\"},"
    status_json+="\"node3\":{\"name\":\"Relay\",\"status\":\"offline\",\"reason\":\"disk full\"},"
    status_json+="\"node5\":{\"name\":\"Redmi\",\"status\":\"intermittent\"},"
    status_json+="\"node7\":{\"name\":\"Docker\",\"status\":\"planned\"}"
    status_json+="},"
    status_json+="\"agents\":{"

    # Agent-Status aus Cron
    if crontab -l >/dev/null 2>&1; then
        local cron_lines
        cron_lines=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
        status_json+="\"active_crons\":${cron_lines}"
    else
        status_json+="\"active_crons\":\"unknown\""
    fi

    status_json+="},"
    status_json+="\"system\":{"

    # System-Metriken
    local disk_used ram_total ram_used
    disk_used=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    ram_total=$(free -h | awk 'NR==2 {print $2}')
    ram_used=$(free -h | awk 'NR==2 {print $3}')

    status_json+="\"disk_used\":\"${disk_used}%\","
    status_json+="\"ram_total\":\"${ram_total}\","
    status_json+="\"ram_used\":\"${ram_used}\""
    status_json+="}}"

    echo "${status_json}"
}

# Täglichen Status formatieren
format_daily_status() {
    local status_json="$1"
    local message=""
    
    # Datum formatieren
    local date_str
    date_str=$(date '+%d.%m.%Y, %H:%M')
    
    message+="📊 **Täglicher Status-Report**"$'\n'
    message+="🗓️ ${date_str}"$'\n\n'
    
    message+="**🖥️ Nodes ("
    local online_count=0
    if echo "${status_json}" | jq -e '.nodes.node1.status == "online"' >/dev/null; then ((online_count++)); fi
    if echo "${status_json}" | jq -e '.nodes.node2.status == "online"' >/dev/null; then ((online_count++)); fi
    if echo "${status_json}" | jq -e '.nodes.node3.status == "online"' >/dev/null; then ((online_count++)); fi
    if echo "${status_json}" | jq -e '.nodes.node5.status == "online"' >/dev/null; then ((online_count++)); fi
    if echo "${status_json}" | jq -e '.nodes.node7.status == "online"' >/dev/null; then ((online_count++)); fi
    message+="${online_count}/5 online):**"$'\n'
    
    # Nodes auflisten
    local nodes=("node1" "node2" "node3" "node5" "node7")
    local node_names=("Gateway" "Worker" "Relay" "Redmi" "Docker")
    
    for i in "${!nodes[@]}"; do
        local node="${nodes[$i]}"
        local name="${node_names[$i]}"
        local status
        status=$(echo "${status_json}" | jq -r ".nodes.${node}.status")
        local emoji=""
        case "${status}" in
            "online") emoji="🟢" ;;
            "offline") emoji="🔴" ;;
            *) emoji="🟡" ;;
        esac
        message+="${emoji} ${name}: ${status}"
        local reason
        reason=$(echo "${status_json}" | jq -r ".nodes.${node}.reason // empty")
        if [[ -n "${reason}" && "${reason}" != "null" ]]; then
            message+=" (${reason})"
        fi
        message+=$'\n'
    done
    
    message+=$'\n'"**🤖 Agents:**"$'\n'
    local active_crons
    active_crons=$(echo "${status_json}" | jq -r '.agents.active_crons')
    message+="Aktive Cron-Jobs: ${active_crons}"$'\n'
    
    local disk_used
    disk_used=$(echo "${status_json}" | jq -r '.system.disk_used')
    if [[ "${disk_used}" != "null" ]]; then
        message+=$'\n'"**💾 System:**"$'\n'
        message+="Disk: ${disk_used} belegt"$'\n'
        local ram_used ram_total
        ram_used=$(echo "${status_json}" | jq -r '.system.ram_used')
        ram_total=$(echo "${status_json}" | jq -r '.system.ram_total')
        message+="RAM: ${ram_used} / ${ram_total}"$'\n'
    fi
    
    echo "${message}"
}

# Wöchentlichen Status formatieren
format_weekly_status() {
    local now
    now=$(date)
    local week_number
    week_number=$(date +%V)
    local year
    year=$(date +%Y)
    
    cat <<EOF
📈 **Wöchentlicher Report**
📅 Woche ${week_number} - ${year}

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
EOF
}

# Nachricht an Channel senden
send_to_channel() {
    local message="$1"
    local channel_type="${2:-telegram}"
    local channel_id="${3:--1002381931352}"
    
    if [[ "${channel_type}" == "telegram" ]]; then
        # Nachricht escapen
        local escaped_message
        escaped_message=$(printf '%s' "${message}" | sed 's/"/\\"/g')
        local cmd="openclaw message send --target ${channel_id} --message \"${escaped_message}\""
        
        if eval "${cmd}"; then
            log "Message sent to ${channel_type} ${channel_id}"
            return 0
        else
            log "Failed to send message" "ERROR"
            return 1
        fi
    else
        log "Channel type ${channel_type} not implemented" "WARN"
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
            -h|--help)
                echo "Usage: $0 --type [daily|weekly|alert] [options]"
                echo "Options:"
                echo "  --type TYPE       Type of status update (daily|weekly|alert)"
                echo "  --message MSG     Alert message"
                echo "  --channel ID      Channel ID (default: -1002381931352)"
                echo "  --dry-run         Show message without sending"
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    if [[ -z "${type}" ]]; then
        echo "Error: --type is required" >&2
        return 1
    fi
    
    log "Starting ${type} status update"
    
    # Status sammeln
    local status_json
    status_json=$(get_system_status)
    
    # Nachricht formatieren
    local formatted_message=""
    case "${type}" in
        daily)
            formatted_message=$(format_daily_status "${status_json}")
            ;;
        weekly)
            formatted_message=$(format_weekly_status)
            ;;
        alert)
            if [[ -z "${message}" ]]; then
                message="Manual alert"
            fi
            formatted_message="🚨 **ALERT**"$'\n'"${message}"
            ;;
        *)
            echo "Invalid type: ${type}" >&2
            return 1
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

# Log-Verzeichnis erstellen falls nicht vorhanden
mkdir -p "$(dirname "${LOG_FILE}")"

# Hauptfunktion aufrufen
main "$@"
