#!/usr/bin/env bash
# channel_status.ps1 — portiert nach shell
# Quelle: powershell, Projects@abstractions:powershell/channel_status.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# channel_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
WORKSPACE="$HOME/.openclaw/workspace"
LOGS_DB="$WORKSPACE/db/logs.db"
CONFIG_FILE="$WORKSPACE/config/channel-status.json"
LOG_FILE="$WORKSPACE/logs/channel-status.log"

write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $message"
    echo "$entry"
    echo "$entry" >> "$LOG_FILE"
}

get_system_status() {
    local status_file
    status_file=$(mktemp)
    
    # Create JSON structure manually
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"nodes\": {"
        echo "    \"node1\": {\"name\": \"Gateway\", \"status\": \"online\"},"
        echo "    \"node2\": {\"name\": \"Worker\", \"status\": \"online\"},"
        echo "    \"node3\": {\"name\": \"Relay\", \"status\": \"offline\", \"reason\": \"disk full\"},"
        echo "    \"node5\": {\"name\": \"Redmi\", \"status\": \"intermittent\"},"
        echo "    \"node7\": {\"name\": \"Docker\", \"status\": \"planned\"}"
        echo "  },"
        echo "  \"agents\": {"
        
        # Agent-Status aus Cron
        if command -v crontab >/dev/null 2>&1; then
            local cron_count
            cron_count=$(crontab -l 2>/dev/null | grep -v '^#' | wc -l)
            echo "    \"active_crons\": $cron_count"
        else
            echo "    \"active_crons\": \"unknown\""
        fi
        
        echo "  },"
        echo "  \"system\": {"
        
        # System-Metriken
        if command -v df >/dev/null 2>&1 && command -v free >/dev/null 2>&1; then
            local disk_usage
            disk_usage=$(df -h / | awk 'NR==2 {print $5}')
            echo "    \"disk_used\": \"$disk_usage\","
            
            local ram_info
            ram_info=$(free -h | awk '/^Mem:/ {print $2 "," $3}')
            local ram_total ram_used
            IFS=',' read -r ram_total ram_used <<< "$ram_info"
            echo "    \"ram_total\": \"$ram_total\","
            echo "    \"ram_used\": \"$ram_used\""
        fi
        
        echo "  }"
        echo "}"
    } > "$status_file"
    
    cat "$status_file"
    rm -f "$status_file"
}

format_daily_status() {
    local status_json="$1"
    local message=""
    
    # Count online nodes
    local online_count
    online_count=$(echo "$status_json" | jq -r '.nodes | to_entries[] | select(.value.status == "online")' | wc -l)
    
    message+="📊 **Täglicher Status-Report**\n"
    message+="🗓️ $(date '+%Y-%m-%d %H:%M')\n\n"
    message+="**🖥️ Nodes ($online_count/5 online):**\n"
    
    # Process each node
    local nodes
    nodes=$(echo "$status_json" | jq -c '.nodes | to_entries[]')
    while IFS= read -r node; do
        local key name status reason
        key=$(echo "$node" | jq -r '.key')
        name=$(echo "$node" | jq -r '.value.name')
        status=$(echo "$node" | jq -r '.value.status')
        reason=$(echo "$node" | jq -r '.value.reason // empty')
        
        local emoji
        case "$status" in
            "online") emoji="🟢" ;;
            "offline") emoji="🔴" ;;
            *) emoji="🟡" ;;
        esac
        
        message+="$emoji $name: $status"
        if [[ -n "${reason:-}" ]]; then
            message+=" ($reason)"
        fi
        message+="\n"
    done <<< "$nodes"
    
    message+="\n**🤖 Agents:**\n"
    local active_crons
    active_crons=$(echo "$status_json" | jq -r '.agents.active_crons')
    message+="Aktive Cron-Jobs: $active_crons\n"
    
    # System info if available
    if echo "$status_json" | jq -e '.system.disk_used' >/dev/null 2>&1; then
        message+="\n**💾 System:**\n"
        local disk_used ram_used ram_total
        disk_used=$(echo "$status_json" | jq -r '.system.disk_used')
        ram_used=$(echo "$status_json" | jq -r '.system.ram_used')
        ram_total=$(echo "$status_json" | jq -r '.system.ram_total')
        message+="Disk: $disk_used belegt\n"
        message+="RAM: $ram_used / $ram_total\n"
    fi
    
    echo -e "$message"
}

format_weekly_status() {
    local message=""
    message+="📈 **Wöchentlicher Report**\n"
    message+="📅 Woche $(date '+%Y-\KW%V') - $(date '+%Y')\n\n"
    message+="**Zusammenfassung:**\n"
    message+="- 5 aktive Sub-Agents\n"
    message+="- 11 Skills synchronisiert\n"
    message+="- 3 neue Features implementiert\n\n"
    message+="**Top-Ereignisse:**\n"
    message+="1. ClawHub-Git Sync implementiert ✅\n"
    message+="2. Node 3 Disk voll (95%) ⚠️\n"
    message+="3. Channel-Status-Agent aktiviert 🆕\n\n"
    message+="**Geplante Wartungen:**\n"
    message+="- Node 3: Disk-Cleanup erforderlich\n"
    message+="- Node 7: Docker-Setup ausstehend\n"
    
    echo -e "$message"
}

send_to_channel() {
    local message="$1"
    local channel_type="${2:-telegram}"
    local channel_id="${3:--1002381931352}"
    
    if [[ "$channel_type" == "telegram" ]]; then
        local cmd=(openclaw message send --target "$channel_id" --message "$message")
    else
        write_log "Channel type $channel_type not implemented" "WARN"
        return 1
    fi
    
    if "${cmd[@]}"; then
        write_log "Message sent to $channel_type $channel_id"
        return 0
    else
        write_log "Failed to send message" "ERROR"
        return 1
    fi
}

main() {
    local type="$1"
    local message="${2:-}"
    local channel="${3:--1002381931352}"
    local dry_run="${4:-false}"
    
    write_log "Starting $type status update"
    
    # Status sammeln
    local status_json
    status_json=$(get_system_status)
    
    # Message formatieren
    local formatted_message
    case "$type" in
        daily)
            formatted_message=$(format_daily_status "$status_json")
            ;;
        weekly)
            formatted_message=$(format_weekly_status)
            ;;
        alert)
            formatted_message="🚨 **ALERT**\n${message:-Manual alert}"
            ;;
        *)
            write_log "Unknown type: $type" "ERROR"
            exit 1
            ;;
    esac
    
    # Senden oder Dry-Run
    if [[ "$dry_run" == "true" ]]; then
        echo -e "\n--- DRY RUN ---"
        echo -e "$formatted_message"
        echo -e "--- END ---"
    else
        send_to_channel "$formatted_message" "telegram" "$channel"
    fi
    
    write_log "Status update completed"
}

# Erstelle Log-Verzeichnis falls nicht vorhanden
mkdir -p "$(dirname "$LOG_FILE")"

# Parameter parsen
param_type=""
param_message=""
param_channel="-1002381931352"
dry_run="false"

i=0
while [[ $i -lt $# ]]; do
    case "${!i}" in
        --type)
            ((i++))
            param_type="${!i}"
            ;;
        --message)
            ((i++))
            param_message="${!i}"
            ;;
        --channel)
            ((i++))
            param_channel="${!i}"
            ;;
        --dry-run)
            dry_run="true"
            ;;
    esac
    ((i++))
done

if [[ -z "$param_type" ]]; then
    echo "Parameter --type ist erforderlich" >&2
    exit 1
fi

main "$param_type" "$param_message" "$param_channel" "$dry_run"
