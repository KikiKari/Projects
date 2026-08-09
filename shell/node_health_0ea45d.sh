#!/usr/bin/env bash
# node_health.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly HEALTH_DB="${WORKSPACE}/db/health.db"
readonly LOG_FILE="${WORKSPACE}/logs/node-health.log"

# Node-Definitionen
declare -A NODES=(
    [node1]="name:Node 1,host:localhost,user:openclaw,critical:true"
    [node2]="name:Node 2,host:10.10.0.2,user:root,ssh_key:~/.ssh/id_rsa,ssh_opts:-o ConnectTimeout=10 -o BatchMode=yes"
    [node3]="name:Node 3,host:localhost,user:root,port:18794,ssh_opts:-p 18794 -o ConnectTimeout=10 -o BatchMode=yes,disk_warning:85"
    [node5]="name:Redmi,host:192.168.1.x,user:openclaw,optional:true"
)

# Globale Variablen für Metriken
declare -A METRICS
declare -a ALERTS

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

check_ping() {
    local host="$1"
    local timeout="${2:-10}"
    
    if ping -c 1 -W "${timeout}" "${host}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_ssh() {
    local node_config="$1"
    
    # Parse Konfiguration
    local host user ssh_opts port
    host=$(echo "${node_config}" | grep -o 'host:[^,]*' | cut -d: -f2)
    user=$(echo "${node_config}" | grep -o 'user:[^,]*' | cut -d: -f2 || echo "root")
    ssh_opts=$(echo "${node_config}" | grep -o 'ssh_opts:[^,]*' | cut -d: -f2 || echo "")
    port=$(echo "${node_config}" | grep -o 'port:[^,]*' | cut -d: -f2 || echo "")
    
    local cmd=("ssh")
    if [[ -n "${ssh_opts}" ]]; then
        IFS=' ' read -ra OPTS <<< "${ssh_opts}"
        cmd+=("${OPTS[@]}")
    fi
    if [[ -n "${port}" ]]; then
        cmd+=("-p" "${port}")
    fi
    cmd+=("-o" "ConnectTimeout=10" "-o" "BatchMode=yes" "${user}@${host}" "echo" '"OK"')
    
    if output=$( "${cmd[@]}" 2>/dev/null ) && [[ "${output}" == *"OK"* ]]; then
        return 0
    else
        return 1
    fi
}

get_node_metrics() {
    local node_config="$1"
    local node_name
    node_name=$(echo "${node_config}" | grep -o 'name:[^,]*' | cut -d: -f2)
    
    # Initialisierung
    METRICS=()
    METRICS[timestamp]=$(date -Iseconds)
    METRICS[available]="false"
    METRICS[cpu]=""
    METRICS[ram]=""
    METRICS[disk]=""
    METRICS[load]=""
    METRICS[gateway_status]=""
    
    # Parse Konfiguration
    local host user
    host=$(echo "${node_config}" | grep -o 'host:[^,]*' | cut -d: -f2)
    user=$(echo "${node_config}" | grep -o 'user:[^,]*' | cut -d: -f2 || echo "root")
    
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
    
    # Ausführung mit Timeout
    local result
    if result=$(timeout 15 bash -c "${cmd}" 2>/dev/null); then
        METRICS[available]="true"
        
        while IFS= read -r line; do
            if [[ "${line}" == *":"* ]]; then
                local key value
                key=$(echo "${line}" | cut -d: -f1)
                value=$(echo "${line}" | cut -d: -f2)
                
                case "${key}" in
                    "CPU") METRICS[cpu]="${value}" ;;
                    "RAM") METRICS[ram]="${value}" ;;
                    "DISK") METRICS[disk]="${value}" ;;
                    "LOAD") METRICS[load]="${value}" ;;
                    "GATEWAY") METRICS[gateway_status]="${value}" ;;
                esac
            fi
        done <<< "${result}"
    else
        log "SSH timeout for ${node_name}" "WARN"
    fi
}

check_alerts() {
    local node_id="$1"
    local node_config="$2"
    
    local node_name critical optional
    node_name=$(echo "${node_config}" | grep -o 'name:[^,]*' | cut -d: -f2)
    critical=$(echo "${node_config}" | grep -o 'critical:[^,]*' | cut -d: -f2 || echo "false")
    optional=$(echo "${node_config}" | grep -o 'optional:[^,]*' | cut -d: -f2 || echo "false")
    
    # Verfügbarkeit
    if [[ "${METRICS[available]}" != "true" ]]; then
        if [[ "${optional}" != "true" ]]; then
            ALERTS+=("CRITICAL:Node ${node_name} nicht erreichbar!")
        fi
    else
        # CPU
        if [[ -n "${METRICS[cpu]}" ]] && (( $(echo "${METRICS[cpu]} > 90" | bc -l) )); then
            ALERTS+=("WARNING:Node ${node_name}: CPU bei ${METRICS[cpu]}%")
        fi
        
        # RAM
        if [[ -n "${METRICS[ram]}" ]] && (( $(echo "${METRICS[ram]} > 90" | bc -l) )); then
            ALERTS+=("WARNING:Node ${node_name}: RAM bei ${METRICS[ram]}%")
        fi
        
        # Disk
        local disk_warning
        disk_warning=$(echo "${node_config}" | grep -o 'disk_warning:[^,]*' | cut -d: -f2 || echo "85")
        if [[ -n "${METRICS[disk]}" ]] && (( METRICS[disk] > disk_warning )); then
            local level="WARNING"
            if (( METRICS[disk] > 95 )); then
                level="CRITICAL"
            fi
            ALERTS+=("${level}:Node ${node_name}: Disk bei ${METRICS[disk]}%")
        fi
        
        # Gateway
        if [[ "${critical}" == "true" ]] && [[ "${METRICS[gateway_status]}" == "inactive" ]]; then
            ALERTS+=("CRITICAL:Node ${node_name}: OpenClaw Gateway nicht aktiv!")
        fi
    fi
}

send_alert() {
    local alert="$1"
    local level message
    level=$(echo "${alert}" | cut -d: -f1)
    message=$(echo "${alert}" | cut -d: -f2-)
    
    local cmd
    cmd=(
        "python3"
        "${WORKSPACE}/skills/channel-status-agent/scripts/channel_status.py"
        "--type" "alert"
        "--message" "${level}: ${message}"
    )
    
    if ! "${cmd[@]}" >/dev/null 2>&1; then
        log "Failed to send alert: ${alert}" "ERROR"
    else
        log "Alert sent: ${message}"
    fi
}

main() {
    local node="all"
    local check="all"
    local alert_flag="false"
    
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
                alert_flag="true"
                shift
                ;;
            *)
                log "Unbekannte Option: $1" "ERROR"
                exit 1
                ;;
        esac
    done
    
    # Nodes bestimmen
    local nodes_to_check=()
    if [[ "${node}" == "all" ]]; then
        for key in "${!NODES[@]}"; do
            nodes_to_check+=("${key}")
        done
    else
        if [[ -n "${NODES[${node}]:-}" ]]; then
            nodes_to_check+=("${node}")
        else
            log "Unknown node: ${node}" "ERROR"
            exit 1
        fi
    fi
    
    # Health-Checks durchführen
    ALERTS=()
    
    for node_id in "${nodes_to_check[@]}"; do
        local node_config="${NODES[${node_id}]}"
        local node_name
        node_name=$(echo "${node_config}" | grep -o 'name:[^,]*' | cut -d: -f2)
        
        log "Checking ${node_name} (${node_id})"
        
        # Ping
        if [[ "${check}" == "ping" ]] || [[ "${check}" == "all" ]]; then
            local host
            host=$(echo "${node_config}" | grep -o 'host:[^,]*' | cut -d: -f2)
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
            if check_ssh "${node_config}"; then
                log "  SSH: OK"
            else
                log "  SSH: FAILED"
            fi
        fi
        
        # Metriken
        if [[ "${check}" == "metrics" ]] || [[ "${check}" == "all" ]]; then
            get_node_metrics "${node_config}"
            
            if [[ "${METRICS[available]}" == "true" ]]; then
                if [[ -n "${METRICS[cpu]}" ]]; then
                    log "  CPU: ${METRICS[cpu]}%"
                else
                    log "  CPU: N/A"
                fi
                if [[ -n "${METRICS[ram]}" ]]; then
                    log "  RAM: ${METRICS[ram]}%"
                else
                    log "  RAM: N/A"
                fi
                if [[ -n "${METRICS[disk]}" ]]; then
                    log "  Disk: ${METRICS[disk]}%"
                else
                    log "  Disk: N/A"
                fi
                if [[ -n "${METRICS[load]}" ]]; then
                    log "  Load: ${METRICS[load]}"
                else
                    log "  Load: N/A"
                fi
            else
                log "  Metrics: UNAVAILABLE"
            fi
            
            # Alerts prüfen
            check_alerts "${node_id}" "${node_config}"
        fi
    done
    
    # Alerts senden
    if [[ "${alert_flag}" == "true" ]] && [[ ${#ALERTS[@]} -gt 0 ]]; then
        log $'\nSending '"${#ALERTS[@]}"' alerts...'
        for alert in "${ALERTS[@]}"; do
            send_alert "${alert}"
        done
    elif [[ ${#ALERTS[@]} -gt 0 ]]; then
        log $'\n'"${#ALERTS[@]}"' alerts found (use --alert to send)'
    else
        log $'\nAll nodes healthy!'
    fi
}

main "$@"
