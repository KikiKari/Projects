#!/usr/bin/env bash
# node_health.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly HEALTH_DB="${WORKSPACE}/db/health.db"
readonly LOG_FILE="${WORKSPACE}/logs/node-health.log"

# Node-Definitionen
declare -A NODES
NODES[node1_name]="Gateway"
NODES[node1_host]="localhost"
NODES[node1_user]="openclaw"
NODES[node1_critical]="true"

NODES[node2_name]="Worker"
NODES[node2_host]="100.92.155.34"
NODES[node2_user]="root"
NODES[node2_ssh_key]="~/.ssh/id_rsa"

NODES[node3_name]="Relay"
NODES[node3_host]="185.242.xxx.xxx"
NODES[node3_user]="root"
NODES[node3_disk_warning]="85"

NODES[node5_name]="Redmi"
NODES[node5_host]="192.168.1.x"
NODES[node5_user]="openclaw"
NODES[node5_optional]="true"

# Logging Funktion
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[${timestamp}] [${level}] ${message}"
    echo "${entry}"
    
    # Erstelle Log-Verzeichnis falls nicht vorhanden
    mkdir -p "$(dirname "${LOG_FILE}")"
    echo "${entry}" >> "${LOG_FILE}"
}

# Ping-Check Funktion
check_ping() {
    local host="$1"
    local timeout="${2:-5}"
    
    if ping -c 1 -W "${timeout}" "${host}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# SSH-Check Funktion
check_ssh() {
    local host="$1"
    local user="$2"
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "${user}@${host}" echo "OK" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Metriken via SSH holen
get_node_metrics() {
    local host="$1"
    local user="$2"
    local node_name="$3"
    
    # Standardwerte setzen
    local metrics_available="false"
    local cpu=""
    local ram=""
    local disk=""
    local load=""
    local gateway_status=""
    
    # SSH-Command für alle Metriken
    local cmd
    cmd=$(cat <<EOF
# CPU
echo "CPU:\$(top -bn1 | grep "Cpu(s)" | awk "{print \\$2}" | cut -d"%" -f1)"

# RAM
echo "RAM:\$(free | grep Mem | awk "{print (\\$3/\\$2) * 100.0}")"

# Disk
echo "DISK:\$(df -h / | tail -1 | awk "{print \\$5}" | tr -d "%")"

# Load
echo "LOAD:\$(uptime | awk -F"load average:" "{print \\$2}" | awk "{print \\$1}" | tr -d ",")"

# Gateway Status
if command -v openclaw >/dev/null 2>&1; then
    systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
fi
EOF
)
    
    # Timeout für SSH-Kommando setzen
    local output
    if output=$(ssh -o ConnectTimeout=10 "${user}@${host}" "${cmd}" 2>/dev/null); then
        metrics_available="true"
        
        # Verarbeite die Ausgabe zeilenweise
        while IFS= read -r line; do
            if [[ $line == *":"* ]]; then
                local key="${line%%:*}"
                local value="${line#*:}"
                
                case "${key}" in
                    "CPU") cpu="${value}" ;;
                    "RAM") ram="${value}" ;;
                    "DISK") disk="${value}" ;;
                    "LOAD") load="${value}" ;;
                    "GATEWAY") gateway_status="${value}" ;;
                esac
            fi
        done <<< "${output}"
    fi
    
    # Gebe die Metriken als assoziatives Array zurück (simuliert)
    echo "available:${metrics_available}"
    echo "cpu:${cpu}"
    echo "ram:${ram}"
    echo "disk:${disk}"
    echo "load:${load}"
    echo "gateway_status:${gateway_status}"
}

# Alerts prüfen
check_alerts() {
    local node_id="$1"
    local node_name="$2"
    local is_critical="$3"
    local is_optional="$4"
    local disk_warning="${5:-85}"
    
    # Metriken übergeben (als Parameter)
    local available="$6"
    local cpu="$7"
    local ram="$8"
    local disk="$9"
    local load="${10}"
    local gateway_status="${11}"
    
    local alerts=()
    
    # Verfügbarkeit
    if [[ "${available}" != "true" ]]; then
        if [[ "${is_optional}" != "true" ]]; then
            alerts+=("CRITICAL:Node ${node_name} nicht erreichbar!")
        fi
    else
        # CPU
        if [[ -n "${cpu}" ]] && (( $(echo "${cpu} > 90" | bc -l) )); then
            alerts+=("WARNING:Node ${node_name}: CPU bei ${cpu}%")
        fi
        
        # RAM
        if [[ -n "${ram}" ]] && (( $(echo "${ram} > 90" | bc -l) )); then
            alerts+=("WARNING:Node ${node_name}: RAM bei ${ram}%")
        fi
        
        # Disk
        if [[ -n "${disk}" ]] && (( disk > disk_warning )); then
            local level="WARNING"
            if (( disk > 95 )); then
                level="CRITICAL"
            fi
            alerts+=("${level}:Node ${node_name}: Disk bei ${disk}%")
        fi
        
        # Gateway
        if [[ "${is_critical}" == "true" ]] && [[ "${gateway_status}" == "inactive" ]]; then
            alerts+=("CRITICAL:Node ${node_name}: OpenClaw Gateway nicht aktiv!")
        fi
    fi
    
    # Gebe Alerts aus (eine pro Zeile)
    printf '%s\n' "${alerts[@]}"
}

# Alert senden
send_alert() {
    local alert_message="$1"
    
    # Extrahiere Level und Message
    local level="${alert_message%%:*}"
    local message="${alert_message#*:}"
    
    local script="${WORKSPACE}/skills/channel-status-agent/scripts/channel_status.py"
    
    if [[ -f "${script}" ]]; then
        if python3 "${script}" --type alert --message "${alert_message}" >/dev/null 2>&1; then
            log "Alert sent: ${message}"
        else
            log "Failed to send alert: ${alert_message}" "ERROR"
        fi
    else
        log "Alert script not found: ${script}" "ERROR"
    fi
}

# Hauptfunktion
main() {
    local node_to_check="all"
    local check_type="all"
    local send_alerts="false"
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            --node)
                node_to_check="$2"
                shift 2
                ;;
            --check)
                check_type="$2"
                shift 2
                ;;
            --alert)
                send_alerts="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--node NODE] [--check {ping,ssh,metrics,all}] [--alert]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Sammle alle Nodes für den Check
    local nodes_to_check=()
    
    if [[ "${node_to_check}" == "all" ]]; then
        # Alle Nodes hinzufügen
        for key in "${!NODES[@]}"; do
            if [[ "${key}" == *_name ]]; then
                local node_id="${key%_name}"
                nodes_to_check+=("${node_id}")
            fi
        done
    else
        # Prüfe ob Node existiert
        if [[ -n "${NODES[${node_to_check}_name]+isset}" ]]; then
            nodes_to_check=("${node_to_check}")
        else
            log "Unknown node: ${node_to_check}" "ERROR"
            exit 1
        fi
    fi
    
    # Health-Checks durchführen
    local all_alerts=()
    
    for node_id in "${nodes_to_check[@]}"; do
        # Node-Konfiguration laden
        local node_name="${NODES[${node_id}_name]:-}"
        local host="${NODES[${node_id}_host]:-}"
        local user="${NODES[${node_id}_user]:-root}"
        local is_critical="${NODES[${node_id}_critical]:-false}"
        local is_optional="${NODES[${node_id}_optional]:-false}"
        local disk_warning="${NODES[${node_id}_disk_warning]:-85}"
        
        if [[ -z "${node_name}" ]] || [[ -z "${host}" ]]; then
            continue
        fi
        
        log "Checking ${node_name} (${node_id})"
        
        # Ping
        if [[ "${check_type}" == "ping" ]] || [[ "${check_type}" == "all" ]]; then
            if [[ "${host}" != "localhost" ]]; then
                if check_ping "${host}"; then
                    log "  Ping: OK"
                else
                    log "  Ping: FAILED"
                fi
            fi
        fi
        
        # SSH
        if [[ "${check_type}" == "ssh" ]] || [[ "${check_type}" == "all" ]]; then
            if check_ssh "${host}" "${user}"; then
                log "  SSH: OK"
            else
                log "  SSH: FAILED"
            fi
        fi
        
        # Metriken
        if [[ "${check_type}" == "metrics" ]] || [[ "${check_type}" == "all" ]]; then
            # Hole Metriken
            local metrics_output
            metrics_output=$(get_node_metrics "${host}" "${user}" "${node_name}")
            
            # Parse Metriken
            local available="false"
            local cpu=""
            local ram=""
            local disk=""
            local load=""
            local gateway_status=""
            
            while IFS=: read -r key value; do
                case "${key}" in
                    "available") available="${value}" ;;
                    "cpu") cpu="${value}" ;;
                    "ram") ram="${value}" ;;
                    "disk") disk="${value}" ;;
                    "load") load="${value}" ;;
                    "gateway_status") gateway_status="${value}" ;;
                esac
            done <<< "${metrics_output}"
            
            if [[ "${available}" == "true" ]]; then
                log "  CPU: ${cpu:-N/A}"
                log "  RAM: ${ram:-N/A}"
                log "  Disk: ${disk:-N/A}"
                log "  Load: ${load:-N/A}"
            else
                log "  Metrics: UNAVAILABLE"
            fi
            
            # Alerts prüfen
            local node_alerts
            node_alerts=$(check_alerts "${node_id}" "${node_name}" "${is_critical}" "${is_optional}" "${disk_warning}" \
                "${available}" "${cpu}" "${ram}" "${disk}" "${load}" "${gateway_status}")
            
            if [[ -n "${node_alerts}" ]]; then
                while IFS= read -r alert; do
                    if [[ -n "${alert}" ]]; then
                        all_alerts+=("${alert}")
                    fi
                done <<< "${node_alerts}"
            fi
        fi
    done
    
    # Alerts senden
    if [[ "${send_alerts}" == "true" ]] && [[ ${#all_alerts[@]} -gt 0 ]]; then
        log "Sending ${#all_alerts[@]} alerts..."
        for alert in "${all_alerts[@]}"; do
            send_alert "${alert}"
        done
    elif [[ ${#all_alerts[@]} -gt 0 ]]; then
        log "${#all_alerts[@]} alerts found (use --alert to send)"
    else
        log "All nodes healthy!"
    fi
}

# Skript ausführen
main "$@"
