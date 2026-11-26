#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "c44c56f508f45bcc50bfcf3d2194e7adff301af86b12b4d4c1d9369527fc9e36", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "shell"}
# node_health.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
WORKSPACE="/home/openclaw/.openclaw/workspace"
HEALTH_DB="$WORKSPACE/db/health.db"
LOG_FILE="$WORKSPACE/logs/node-health.log"

# Node-Definitionen
declare -A NODES=(
    ["node1_name"]="Gateway"
    ["node1_host"]="localhost"
    ["node1_user"]="openclaw"
    ["node1_critical"]="true"
    
    ["node2_name"]="Worker"
    ["node2_host"]="100.92.155.34"
    ["node2_user"]="root"
    ["node2_ssh_key"]="~/.ssh/id_rsa"
    
    ["node3_name"]="Relay"
    ["node3_host"]="185.242.xxx.xxx"
    ["node3_user"]="root"
    ["node3_disk_warning"]="85"
    
    ["node5_name"]="Redmi"
    ["node5_host"]="192.168.1.x"
    ["node5_user"]="openclaw"
    ["node5_optional"]="true"
)

log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $message"
    echo "$entry"
    
    # Stelle sicher, dass das Log-Verzeichnis existiert
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$entry" >> "$LOG_FILE"
}

check_ping() {
    local host="$1"
    local timeout="${2:-5}"
    
    if ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_ssh() {
    local host="$1"
    local user="$2"
    
    local cmd="ssh -o ConnectTimeout=10 -o BatchMode=yes ${user}@${host} echo OK"
    
    if output=$(eval "$cmd" 2>/dev/null) && [[ "$output" == "OK" ]]; then
        return 0
    else
        return 1
    fi
}

get_node_metrics() {
    local host="$1"
    local user="$2"
    local node_name="$3"
    
    # Initialisiere Metriken
    local metrics_available="false"
    local cpu=""
    local ram=""
    local disk=""
    local load=""
    local gateway_status=""
    
    # SSH-Command für alle Metriken
    local cmd="ssh -o ConnectTimeout=10 ${user}@${host} '
        # CPU
        echo \"CPU:\$(top -bn1 | grep \"Cpu(s)\" | awk \"{print \\\$2}\" | cut -d\"%\" -f1)\"
        
        # RAM
        echo \"RAM:\$(free | grep Mem | awk \"{print (\\\$3/\\\$2) * 100.0}\")\"
        
        # Disk
        echo \"DISK:\$(df -h / | tail -1 | awk \"{print \\\$5}\" | tr -d \"%\")\"
        
        # Load
        echo \"LOAD:\$(uptime | awk -F\"load average:\" \"{print \\\$2}\" | awk \"{print \\\$1}\" | tr -d \",\")\"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo \"GATEWAY:inactive\"
        fi
    '"
    
    local output
    if output=$(eval "$cmd" 2>/dev/null) && [[ -n "$output" ]]; then
        metrics_available="true"
        
        while IFS= read -r line; do
            if [[ "$line" == *":"* ]]; then
                local key="${line%%:*}"
                local value="${line#*:}"
                
                case "$key" in
                    "CPU") cpu="$value" ;;
                    "RAM") ram="$value" ;;
                    "DISK") disk="$value" ;;
                    "LOAD") load="$value" ;;
                    "GATEWAY") gateway_status="$value" ;;
                esac
            fi
        done <<< "$output"
    fi
    
    # Gebe Metriken als JSON-ähnlichen String zurück
    echo "available:$metrics_available|cpu:$cpu|ram:$ram|disk:$disk|load:$load|gateway_status:$gateway_status"
}

check_alerts() {
    local node_id="$1"
    local node_name="$2"
    local node_critical="$3"
    local node_optional="$4"
    local node_disk_warning="${5:-85}"
    local metrics_str="$6"
    
    local alerts=()
    
    # Parse metrics string
    local available cpu ram disk load gateway_status
    IFS='|' read -r available cpu ram disk load gateway_status <<< "$(echo "$metrics_str" | sed 's/[^:]*://g' | paste -sd'|')"
    
    # Verfügbarkeit
    if [[ "${available##*:}" != "true" ]]; then
        if [[ "$node_optional" != "true" ]]; then
            alerts+=("CRITICAL:Node $node_name nicht erreichbar!")
        fi
    else
        # CPU
        if [[ -n "${cpu##*:}" ]] && (( $(echo "${cpu##*:} > 90" | bc -l) )); then
            alerts+=("WARNING:Node $node_name: CPU bei ${cpu##*:}%")
        fi
        
        # RAM
        if [[ -n "${ram##*:}" ]] && (( $(echo "${ram##*:} > 90" | bc -l) )); then
            alerts+=("WARNING:Node $node_name: RAM bei ${ram##*:}%")
        fi
        
        # Disk
        if [[ -n "${disk##*:}" ]] && (( ${disk##*:} > node_disk_warning )); then
            local level="WARNING"
            if (( ${disk##*:} > 95 )); then
                level="CRITICAL"
            fi
            alerts+=("$level:Node $node_name: Disk bei ${disk##*:}%")
        fi
        
        # Gateway
        if [[ "$node_critical" == "true" ]] && [[ "${gateway_status##*:}" == "inactive" ]]; then
            alerts+=("CRITICAL:Node $node_name: OpenClaw Gateway nicht aktiv!")
        fi
    fi
    
    # Gebe Alerts aus
    printf '%s\n' "${alerts[@]}"
}

send_alert() {
    local alert_msg="$1"
    
    local script_path="$WORKSPACE/skills/channel-status-agent/scripts/channel_status.py"
    
    if [[ -f "$script_path" ]]; then
        if python3 "$script_path" --type alert --message "$alert_msg" >/dev/null 2>&1; then
            log "Alert sent: $alert_msg"
        else
            log "Failed to send alert: $alert_msg" "ERROR"
        fi
    else
        log "Channel status agent script not found: $script_path" "ERROR"
    fi
}

main() {
    local node="all"
    local check="all"
    local alert=false
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --node)
                node="$2"
                shift 2
                ;;
            --check)
                check="$2"
                shift 2
                ;;
            --alert)
                alert=true
                shift
                ;;
            *)
                echo "Unbekannte Option: $1"
                exit 1
                ;;
        esac
    done
    
    # Sammle zu prüfende Nodes
    local nodes_to_check=()
    
    if [[ "$node" == "all" ]]; then
        for key in "${!NODES[@]}"; do
            if [[ "$key" == *_name ]]; then
                local node_id="${key%_name}"
                nodes_to_check+=("$node_id")
            fi
        done
    else
        # Prüfe ob Node existiert
        if [[ -n "${NODES[${node}_name]:-}" ]]; then
            nodes_to_check=("$node")
        else
            log "Unknown node: $node" "ERROR"
            exit 1
        fi
    fi
    
    # Health-Checks durchführen
    local all_alerts=()
    
    for node_id in "${nodes_to_check[@]}"; do
        local node_name="${NODES[${node_id}_name]:-}"
        local host="${NODES[${node_id}_host]:-}"
        local user="${NODES[${node_id}_user]:-root}"
        local critical="${NODES[${node_id}_critical]:-false}"
        local optional="${NODES[${node_id}_optional]:-false}"
        local disk_warning="${NODES[${node_id}_disk_warning]:-85}"
        
        log "Checking $node_name ($node_id)"
        
        # Ping
        if [[ "$check" == "ping" || "$check" == "all" ]]; then
            if [[ "$host" != "localhost" ]]; then
                if check_ping "$host"; then
                    log "  Ping: OK"
                else
                    log "  Ping: FAILED"
                fi
            fi
        fi
        
        # SSH
        if [[ "$check" == "ssh" || "$check" == "all" ]]; then
            if check_ssh "$host" "$user"; then
                log "  SSH: OK"
            else
                log "  SSH: FAILED"
            fi
        fi
        
        # Metriken
        if [[ "$check" == "metrics" || "$check" == "all" ]]; then
            local metrics
            metrics=$(get_node_metrics "$host" "$user" "$node_name")
            
            # Parse metrics für Anzeige
            local available cpu ram disk load
            IFS='|' read -r available cpu ram disk load _ <<< "$metrics"
            
            if [[ "${available##*:}" == "true" ]]; then
                log "  CPU: ${cpu##*:}%" 
                log "  RAM: ${ram##*:}%" 
                log "  Disk: ${disk##*:}%" 
                log "  Load: ${load##*:}" 
            else
                log "  Metrics: UNAVAILABLE"
            fi
            
            # Alerts prüfen
            local node_alerts
            node_alerts=$(check_alerts "$node_id" "$node_name" "$critical" "$optional" "$disk_warning" "$metrics")
            
            if [[ -n "$node_alerts" ]]; then
                while IFS= read -r alert_line; do
                    if [[ -n "$alert_line" ]]; then
                        all_alerts+=("$alert_line")
                    fi
                done <<< "$node_alerts"
            fi
        fi
    done
    
    # Alerts senden
    if [[ "$alert" == true ]] && [[ ${#all_alerts[@]} -gt 0 ]]; then
        log "Sending ${#all_alerts[@]} alerts..."
        for alert_msg in "${all_alerts[@]}"; do
            send_alert "$alert_msg"
        done
    elif [[ ${#all_alerts[@]} -gt 0 ]]; then
        log "${#all_alerts[@]} alerts found (use --alert to send)"
    else
        log "All nodes healthy!"
    fi
}

main "$@"
