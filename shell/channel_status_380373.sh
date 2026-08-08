#!/bin/bash
# channel_status.pl — portiert nach shell
# Quelle: perl5, Projects@abstractions:perl5/channel_status.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Konfiguration
WORKSPACE="/home/openclaw/.openclaw/workspace"
LOGS_DB="$WORKSPACE/db/logs.db"
CONFIG_FILE="$WORKSPACE/config/channel-status.json"
LOG_FILE="$WORKSPACE/logs/channel-status.log"

# Erstelle Log-Verzeichnis falls nicht vorhanden
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $message"
    echo "$entry"
    echo "$entry" >> "$LOG_FILE"
}

get_system_status() {
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    
    # Erstelle temporäre Datei für JSON-Ausgabe
    local temp_json
    temp_json=$(mktemp)
    
    cat > "$temp_json" <<EOF
{
  "timestamp": "$timestamp",
  "nodes": {
    "node1": {"name": "Gateway", "status": "online"},
    "node2": {"name": "Worker", "status": "online"},
    "node3": {"name": "Relay", "status": "offline", "reason": "disk full"},
    "node5": {"name": "Redmi", "status": "intermittent"},
    "node7": {"name": "Docker", "status": "planned"}
  },
  "agents": {},
  "system": {}
}
EOF

    # Agent-Status aus Cron
    if command -v crontab >/dev/null 2>&1; then
        local cron_count
        cron_count=$(crontab -l 2>/dev/null | grep -v '^\s*#' | grep -v '^\s*$' | wc -l)
        jq ".agents.active_crons = $cron_count" "$temp_json" > "$temp_json.tmp" && mv "$temp_json.tmp" "$temp_json"
    else
        jq '.agents.active_crons = "unknown"' "$temp_json" > "$temp_json.tmp" && mv "$temp_json.tmp" "$temp_json"
    fi

    # System-Metriken
    if command -v df >/dev/null 2>&1; then
        local disk_usage
        disk_usage=$(df -h / | awk 'NR==2 {print $5}')
        jq ".system.disk_used = \"$disk_usage\"" "$temp_json" > "$temp_json.tmp" && mv "$temp_json.tmp" "$temp_json"
    fi

    if command -v free >/dev/null 2>&1; then
        local ram_info
        ram_info=$(free -h | awk '/^Mem:/ {print $2 " " $3}')
        local ram_total ram_used
        ram_total=$(echo "$ram_info" | awk '{print $1}')
        ram_used=$(echo "$ram_info" | awk '{print $2}')
        jq ".system.ram_total = \"$ram_total\" | .system.ram_used = \"$ram_used\"" "$temp_json" > "$temp_json.tmp" && mv "$temp_json.tmp" "$temp_json"
    fi

    cat "$temp_json"
    rm -f "$temp_json"
}

format_daily_status() {
    local status_file="$1"
    local message=""

    message+="📊 **Täglicher Status-Report**\n"
    message+="🗓️ $(date '+%Y-%m-%d %H:%M')\n\n"
    message+="**🖥️ Nodes ("
    
    local online_count=0
    local total_nodes=0
    
    # Zähle Nodes
    total_nodes=$(jq -r '.nodes | length' "$status_file")
    online_count=$(jq -r '[.nodes[].status] | map(select(. == "online")) | length' "$status_file")
    
    message+="$online_count/$total_nodes online):**\n"
    
    # Durchlaufe Nodes
    local node_ids
    node_ids=$(jq -r 'keys[]' "$status_file" | grep "^node")
    for node_id in $node_ids; do
        local name status reason
        name=$(jq -r ".nodes.$node_id.name" "$status_file")
        status=$(jq -r ".nodes.$node_id.status" "$status_file")
        reason=$(jq -r ".nodes.$node_id.reason // empty" "$status_file")
        
        local emoji
        case "$status" in
            "online") emoji="🟢" ;;
            "offline") emoji="🔴" ;;
            *) emoji="🟡" ;;
        esac
        
        message+="$emoji $name: $status"
        if [[ -n "$reason" ]]; then
            message+=" ($reason)"
        fi
        message+="\n"
    done
    
    message+="\n**🤖 Agents:**\n"
    local active_crons
    active_crons=$(jq -r '.agents.active_crons' "$status_file")
    message+="Aktive Cron-Jobs: $active_crons\n"
    
    if jq -e '.system.disk_used' "$status_file" >/dev/null 2>&1; then
        message+="\n**💾 System:**\n"
        local disk_used ram_used ram_total
        disk_used=$(jq -r '.system.disk_used' "$status_file")
        ram_used=$(jq -r '.system.ram_used' "$status_file")
        ram_total=$(jq -r '.system.ram_total' "$status_file")
        message+="Disk: $disk_used belegt\n"
        message+="RAM: $ram_used / $ram_total\n"
    fi
    
    echo -e "$message"
}

format_weekly_status() {
    local message=""
    message+="📈 **Wöchentlicher Report**\n"
    message+="📅 Woche $(date '+%V') - $(date '+%Y')\n\n"
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
        if command -v openclaw >/dev/null 2>&1; then
            if ! openclaw message send --target "$channel_id" --message "$message"; then
                log_message "Failed to send message" "ERROR"
                return 1
            else
                log_message "Message sent to $channel_type $channel_id"
                return 0
            fi
        else
            log_message "openclaw command not found" "ERROR"
            return 1
        fi
    else
        log_message "Channel type $channel_type not implemented" "WARN"
        return 1
    fi
}

main() {
    local type=""
    local message=""
    local channel="-1002381931352"
    local dry_run=0
    
    # Parse Kommandozeilenargumente
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
                dry_run=1
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$type" ]]; then
        echo "Type is required" >&2
        exit 1
    fi
    
    if [[ ! "$type" =~ ^(daily|weekly|alert)$ ]]; then
        echo "Invalid type: $type" >&2
        exit 1
    fi
    
    log_message "Starting $type status update"
    
    # Status sammeln
    local status_file
    status_file=$(mktemp)
    get_system_status > "$status_file"
    
    # Message formatieren
    local formatted_message=""
    case "$type" in
        daily)
            formatted_message=$(format_daily_status "$status_file")
            ;;
        weekly)
            formatted_message=$(format_weekly_status)
            ;;
        alert)
            formatted_message="🚨 **ALERT**\n${message:-Manual alert}"
            ;;
    esac
    
    # Sende oder Dry-Run
    if [[ $dry_run -eq 1 ]]; then
        echo -e "\n--- DRY RUN ---"
        echo -e "$formatted_message"
        echo -e "--- END ---\n"
    else
        send_to_channel "$formatted_message" "telegram" "$channel"
    fi
    
    rm -f "$status_file"
    log_message "Status update completed"
}

main "$@"
