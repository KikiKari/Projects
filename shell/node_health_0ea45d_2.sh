#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "670ca4baec05d214340ba7392b7cfdf1cdb92feacf50018ab6bb215ab5091895", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "shell"}
# node_health.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly HEALTH_DB="${WORKSPACE}/db/health.db"
readonly LOG_FILE="${WORKSPACE}/logs/node-health.log"

# Logging Funktion
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

# Prüft Erreichbarkeit (Timeout seconds)
check_ping() {
    local host="$1"
    local timeout="${2:-10}"
    
    if ping -c 1 -W "${timeout}" "${host}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Prüft SSH-Verbindung
check_ssh() {
    local host="$1"
    local user="$2"
    local ssh_opts="$3"
    local port="$4"
    
    local cmd=("ssh")
    
    if [[ -n "${ssh_opts}" ]]; then
        IFS=' ' read -ra OPTS <<< "${ssh_opts}"
        cmd+=("${OPTS[@]}")
    fi
    
    if [[ -n "${port}" ]]; then
        cmd+=("-p" "${port}")
    fi
    
    cmd+=("-o" "ConnectTimeout=10" "-o" "BatchMode=yes" "${user}@${host}" "echo" "\"OK\"")
    
    if output=$( "${cmd[@]}" 2>/dev/null ) && [[ "${output}" == *"OK"* ]]; then
        return 0
    else
        return 1
    fi
}

# Holt Metriken via SSH
get_node_metrics() {
    local host="$1"
    local user="$2"
    
    local metrics_json=""
    metrics_json+="{"
    metrics_json+="\"timestamp\":\"$(date -Iseconds)\","
    metrics_json+="\"available\":false,"
    metrics_json+="\"cpu\":null,"
    metrics_json+="\"ram\":null,"
    metrics_json+="\"disk\":null,"
    metrics_json+="\"load\":null"
    metrics_json+="}"
    
    # SSH-Command für alle Metriken
    local cmd
    cmd=$(cat <<EOF
ssh -o ConnectTimeout=10 ${user}@${host} '
    # CPU
    echo "CPU:\$(top -bn1 | grep "Cpu(s)" | awk "{print \\\$2}" | cut -d"%" -f1)"
    
    # RAM
    echo "RAM:\$(free | grep Mem | awk "{print (\\\$3/\\\$2) * 100.0}")"
    
    # Disk
    echo "DISK:\$(df -h / | tail -1 | awk "{print \\\$5}" | tr -d "%")"
    
    # Load
    echo "LOAD:\$(uptime | awk -F"load average:" "{print \\\$2}" | awk "{print \\\$1}" | tr -d ",")"
    
    # Gateway Status
    if command -v openclaw >/dev/null 2>&1; then
        systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
    fi
'
EOF
)
    
    local result
    if result=$(timeout 15 bash -c "${cmd}" 2>/dev/null); then
        # Erstelle ein temporäres JSON-ähhnliches Format
        local cpu=null ram=null disk=null load=null gateway_status=null
        while IFS= read -r line; do
            if [[ $line == *"CPU:"* ]]; then
                cpu=$(echo "$line" | cut -d':' -f2)
            elif [[ $line == *"RAM:"* ]]; then
                ram=$(echo "$line" | cut -d':' -f2)
            elif [[ $line == *"DISK:"* ]]; then
                disk=$(echo "$line" | cut -d':' -f2)
            elif [[ $line == *"LOAD:"* ]]; then
                load=$(echo "$line" | cut -d':' -f2)
            elif [[ $line == *"GATEWAY:"* ]]; then
                gateway_status=$(echo "$line" | cut -d':' -f2)
            fi
        done <<< "$result"
        
        # Setze available auf true, da wir Ergebnisse haben
        metrics_json="{\"timestamp\":\"$(date -Iseconds)\",\"available\":true,\"cpu\":${cpu:-null},\"ram\":${ram:-null},\"disk\":${disk:-null},\"load\":${load:-null}"
        if [[ "${gateway_status}" != "null" ]] && [[ -n "${gateway_status}" ]]; then
            metrics_json+=",\"gateway_status\":\"${gateway_status}\""
        fi
        metrics_json+="}"
    else
        # Timeout oder Fehler
        if [[ $? -eq 124 ]]; then
            log "SSH timeout for node" "WARN"
        fi
    fi
    
    echo "${metrics_json}"
}

# Prüft Schwellwerte und generiert Alerts
check_alerts() {
    local node_name="$1"
    local node_critical="$2"
    local node_optional="$3"
    local disk_warning="${4:-85}"
    local metrics_json="$5"
    
    local alerts=()
    
    # Parse JSON mit jq oder manuell
    local available cpu ram disk load gateway_status
    available=$(echo "${metrics_json}" | grep -o '"available":[^,}]*' | cut -d: -f2)
    cpu=$(echo "${metrics_json}" | grep -o '"cpu":[^,}]*' | cut -d: -f2)
    ram=$(echo "${metrics_json}" | grep -o '"ram":[^,}]*' | cut -d: -f2)
    disk=$(echo "${metrics_json}" | grep -o '"disk":[^,}]*' | cut -d: -f2)
    load=$(echo "${metrics_json}" | grep -o '"load":[^,}]*' | cut -d: -f2)
    gateway_status=$(echo "${metrics_json}" | grep -o '"gateway_status":"[^"]*"' | cut -d: -f2 | tr -d '"')
    
    # Verfügbarkeit
    if [[ "${available}" != "true" ]] && [[ "${node_optional}" != "true" ]]; then
        alerts+=("CRITICAL|Node ${node_name} nicht erreichbar!")
    else
        # CPU
        if [[ "${cpu}" != "null" ]] && (( $(echo "${cpu} > 90" | bc -l) )); then
            alerts+=("WARNING|Node ${node_name}: CPU bei ${cpu}%")
        fi
        
        # RAM
        if [[ "${ram}" != "null" ]] && (( $(echo "${ram} > 90" | bc -l) )); then
            alerts+=("WARNING|Node ${node_name}: RAM bei ${ram}%")
        fi
        
        # Disk
        if [[ "${disk}" != "null" ]] && (( disk > disk_warning )); then
            local level="WARNING"
            if (( disk > 95 )); then
                level="CRITICAL"
            fi
            alerts+=("${level}|Node ${node_name}: Disk bei ${disk}%")
        fi
        
        # Gateway
        if [[ "${node_critical}" == "true" ]] && [[ "${gateway_status}" == "inactive" ]]; then
            alerts+=("CRITICAL|Node ${node_name}: OpenClaw Gateway nicht aktiv!")
        fi
    fi
    
    printf '%s\n' "${alerts[@]}"
}

# Sendet Alert via channel-status-agent
send_alert() {
    local alert_line="$1"
    local level message
    
    IFS='|' read -r level message <<< "${alert_line}"
    
    if command -v python3 >/dev/null 2>&1; then
        if python3 "${WORKSPACE}/skills/channel-status-agent/scripts/channel_status.py" \
                  --type alert \
                  --message "${level}: ${message}" >/dev/null 2>&1; then
            log "Alert sent: ${message}"
        else
            log "Failed to send alert: ${message}" "ERROR"
        fi
    else
        log "Python3 not found, cannot send alert: ${message}" "ERROR"
    fi
}

# Hauptfunktion
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
                echo "Unbekannte Option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Node-Konfigurationen (simuliert als Arrays)
    declare -A NODES_NAME NODES_HOST NODES_USER NODES_CRITICAL NODES_OPTIONAL NODES_SSH_KEY NODES_SSH_OPTS NODES_PORT NODES_DISK_WARNING
    
    # Node 1
    NODES_NAME["node1"]="Node 1"
    NODES_HOST["node1"]="localhost"
    NODES_USER["node1"]="openclaw"
    NODES_CRITICAL["node1"]="true"
    NODES_OPTIONAL["node1"]="false"
    
    # Node 2
    NODES_NAME["node2"]="Node 2"
    NODES_HOST["node2"]="10.10.0.2"
    NODES_USER["node2"]="root"
    NODES_SSH_KEY["node2"]="~/.ssh/id_rsa"
    NODES_SSH_OPTS["node2"]="-o ConnectTimeout=10 -o BatchMode=yes"
    NODES_OPTIONAL["node2"]="false"
    
    # Node 3
    NODES_NAME["node3"]="Node 3"
    NODES_HOST["node3"]="localhost"
    NODES_USER["node3"]="root"
    NODES_PORT["node3"]="18794"
    NODES_SSH_OPTS["node3"]="-p 18794 -o ConnectTimeout=10 -o BatchMode=yes"
    NODES_DISK_WARNING["node3"]="85"
    NODES_OPTIONAL["node3"]="false"
    
    # Node 5
    NODES_NAME["node5"]="Redmi"
    NODES_HOST["node5"]="192.168.1.x"
    NODES_USER["node5"]="openclaw"
    NODES_OPTIONAL["node5"]="true"
    
    # Nodes bestimmen
    local nodes_to_check=()
    if [[ "${node}" == "all" ]]; then
        nodes_to_check=("node1" "node2" "node3" "node5")
    else
        if [[ -n "${NODES_NAME[${node}]:-}" ]]; then
            nodes_to_check=("${node}")
        else
            log "Unknown node: ${node}" "ERROR"
            exit 1
        fi
    fi
    
    # Health-Checks durchführen
    local all_alerts=()
    
    for node_id in "${nodes_to_check[@]}"; do
        local node_name="${NODES_NAME[${node_id}]}"
        local host="${NODES_HOST[${node_id}]}"
        local user="${NODES_USER[${node_id}]:-root}"
        local critical="${NODES_CRITICAL[${node_id}]:-false}"
        local optional="${NODES_OPTIONAL[${node_id}]:-false}"
        local ssh_opts="${NODES_SSH_OPTS[${node_id}]:-}"
        local port="${NODES_PORT[${node_id}]:-}"
        local disk_warning="${NODES_DISK_WARNING[${node_id}]:-85}"
        
        log "Checking ${node_name} (${node_id})"
        
        # Ping
        if [[ "${check}" == "ping" ]] || [[ "${check}" == "all" ]]; then
            if [[ "${host}" != "localhost" ]]; then
                if check_ping "${host}"; then
                    log "  Ping: OK"
                else
                    log "  Ping: FAILED"
                fi
            fi
        fi
        
        # SSH
        if [[ "${check}" == "ssh" ]] || [[ "${check}" == "all" ]]; then
            if check_ssh "${host}" "${user}" "${ssh_opts}" "${port}"; then
                log "  SSH: OK"
            else
                log "  SSH: FAILED"
            fi
        fi
        
        # Metriken
        if [[ "${check}" == "metrics" ]] || [[ "${check}" == "all" ]]; then
            local metrics_json
            metrics_json=$(get_node_metrics "${host}" "${user}")
            
            local available
            available=$(echo "${metrics_json}" | grep -o '"available":[^,}]*' | cut -d: -f2)
            
            if [[ "${available}" == "true" ]]; then
                local cpu ram disk load
                cpu=$(echo "${metrics_json}" | grep -o '"cpu":[^,}]*' | cut -d: -f2)
                ram=$(echo "${metrics_json}" | grep -o '"ram":[^,}]*' | cut -d: -f2)
                disk=$(echo "${metrics_json}" | grep -o '"disk":[^,}]*' | cut -d: -f2)
                load=$(echo "${metrics_json}" | grep -o '"load":[^,}]*' | cut -d: -f2)
                
                log "  CPU: ${cpu:-N/A}"
                log "  RAM: ${ram:-N/A}"
                log "  Disk: ${disk:-N/A}"
                log "  Load: ${load:-N/A}"
            else
                log "  Metrics: UNAVAILABLE"
            fi
            
            # Alerts prüfen
            local node_alerts
            mapfile -t node_alerts < <(check_alerts "${node_name}" "${critical}" "${optional}" "${disk_warning}" "${metrics_json}")
            all_alerts+=("${node_alerts[@]}")
        fi
    done
    
    # Alerts senden
    if [[ "${alert}" == true ]] && [[ ${#all_alerts[@]} -gt 0 ]]; then
        log $'\nSending '"${#all_alerts[@]}"' alerts...'
        for alert_line in "${all_alerts[@]}"; do
            send_alert "${alert_line}"
        done
    elif [[ ${#all_alerts[@]} -gt 0 ]]; then
        log $'\n'"${#all_alerts[@]}"' alerts found (use --alert to send)'
    else
        log $'\nAll nodes healthy!'
    fi
}

main "$@"
