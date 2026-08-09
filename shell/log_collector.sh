#!/usr/bin/env bash
# log_collector.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
# auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Log Collector Sub-Agent
# Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly DB_PATH="${WORKSPACE}/db/logs.db"
readonly LOG_DIR="${WORKSPACE}/logs/log-collector"

mkdir -p "${LOG_DIR}"

# Globale Variablen für Logging
LOG_FILE=""

# Logger Funktionen
init_logger() {
    local today
    today=$(date '+%Y-%m-%d')
    LOG_FILE="${LOG_DIR}/${today}.log"
}

log() {
    local level="$1"
    local msg="$2"
    local ts
    ts=$(date --iso-8601=seconds)
    local line="[${ts}] [${level}] ${msg}"
    echo "${line}"
    echo "${line}" >> "${LOG_FILE}"
}

info() {
    log "INFO" "$1"
}

error() {
    log "ERROR" "$1"
}

# Datenbank Funktionen
connect_db() {
    # Prüfen ob DB existiert, wenn nicht erstellen
    if [[ ! -f "${DB_PATH}" ]]; then
        sqlite3 "${DB_PATH}" "VACUUM;"
    fi
    
    # Schema initialisieren falls leer
    init_schema
}

init_schema() {
    local table_count
    table_count=$(sqlite3 "${DB_PATH}" "SELECT count(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
    
    if [[ "${table_count}" -eq 0 ]]; then
        local schema_path="${WORKSPACE}/db/logs.db.schema.sql"
        if [[ -f "${schema_path}" ]]; then
            sqlite3 "${DB_PATH}" < "${schema_path}"
        fi
    fi
}

get_nodes() {
    # Gibt alle Nodes als JSON-ähnlichen String zurück (jede Zeile ein Node)
    sqlite3 -separator $'\x1e' "${DB_PATH}" "SELECT node_id, vpn_ip, tailscale_ip, wireguard_ip FROM nodes;" | \
    while IFS=$'\x1e' read -r node_id vpn_ip tailscale_ip wireguard_ip; do
        echo "node_id=${node_id}|vpn_ip=${vpn_ip}|tailscale_ip=${tailscale_ip}|wireguard_ip=${wireguard_ip}"
    done
}

check_vpn() {
    local ip="$1"
    if ping -c 1 -W 3 "${ip}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

ssh_connect_and_collect() {
    local node_data="$1"
    
    # Parse node data
    local node_id vpn_ip
    node_id=$(echo "${node_data}" | cut -d'|' -f1 | cut -d'=' -f2)
    vpn_ip=$(echo "${node_data}" | cut -d'|' -f2 | cut -d'=' -f2)
    
    # Fallback IPs
    if [[ -z "${vpn_ip}" ]] || [[ "${vpn_ip}" == "NULL" ]]; then
        vpn_ip=$(echo "${node_data}" | cut -d'|' -f3 | cut -d'=' -f2)
    fi
    if [[ -z "${vpn_ip}" ]] || [[ "${vpn_ip}" == "NULL" ]]; then
        vpn_ip=$(echo "${node_data}" | cut -d'|' -f4 | cut -d'=' -f2)
    fi
    
    if [[ -z "${vpn_ip}" ]] || [[ "${vpn_ip}" == "NULL" ]]; then
        error "${node_id}: Keine VPN-IP konfiguriert"
        return 1
    fi
    
    # 1. VPN-Check
    info "${node_id}: Prüfe VPN ${vpn_ip}..."
    if ! check_vpn "${vpn_ip}"; then
        error "${node_id}: VPN nicht erreichbar"
        log_ssh_connection "${node_id}" "tailscale" "false" "VPN unreachable"
        return 1
    fi
    
    # 2. SSH-Verbindung
    info "${node_id}: Verbinde via SSH..."
    
    local logs_collected=()
    local log_index=0
    
    # Logs abholen
    local log_commands=(
        "journalctl -n 500 --no-pager"
        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'"
        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
    )
    
    for cmd in "${log_commands[@]}"; do
        if output=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "openclaw@${vpn_ip}" "${cmd}" 2>/dev/null); then
            logs_collected[${log_index}]="command=${cmd}|output=${output}|timestamp=$(date --iso-8601=seconds)"
            ((log_index++))
        fi
    done
    
    # Erfolg loggen
    log_ssh_connection "${node_id}" "ssh" "true" "NULL"
    
    # In DB speichern
    insert_logs "${node_id}" "${logs_collected[@]}"
    
    echo "${log_index}"
    return 0
}

log_ssh_connection() {
    local node_id="$1"
    local conn_type="$2"
    local success="$3"
    local error_msg="$4"
    
    if [[ "${error_msg}" == "NULL" ]]; then
        sqlite3 "${DB_PATH}" "INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES ('${node_id}', '${conn_type}', ${success}, NULL);"
    else
        sqlite3 "${DB_PATH}" "INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES ('${node_id}', '${conn_type}', ${success}, '${error_msg}');"
    fi
}

insert_logs() {
    local node_id="$1"
    shift
    local logs=("$@")
    
    local retention
    retention=$(date --iso-8601=seconds -d "+30 days")
    
    for log_entry in "${logs[@]}"; do
        local cmd output
        cmd=$(echo "${log_entry}" | cut -d'|' -f1 | cut -d'=' -f2)
        output=$(echo "${log_entry}" | cut -d'|' -f2 | cut -d'=' -f2)
        
        # Begrenze Länge der Felder
        cmd=${cmd:0:50}
        output=${output:0:10000}
        
        sqlite3 "${DB_PATH}" "INSERT INTO logs (node_id, log_type, source, content, severity, collected_by, collection_method, retention_until) VALUES ('${node_id}', 'system', '${cmd}', '${output}', 'info', 'node1', 'ssh', '${retention}');"
    done
    
    info "${node_id}: ${#logs[@]} Log-Einträge gespeichert"
}

cleanup_retention() {
    local deleted
    deleted=$(sqlite3 "${DB_PATH}" "DELETE FROM logs WHERE retention_until < datetime('now'); SELECT changes();")
    info "Retention-Cleanup: ${deleted} alte Logs gelöscht"
    echo "${deleted}"
}

run_collection_cycle() {
    info "============================================================"
    info "LOG COLLECTOR CYCLE START"
    info "============================================================"
    
    connect_db
    
    # 1. Nodes holen
    local nodes=()
    local node_count=0
    
    while IFS= read -r line; do
        nodes+=("${line}")
        ((node_count++))
    done < <(get_nodes)
    
    info "Gefunden: ${node_count} Nodes"
    
    # 2. Collection-Run starten
    sqlite3 "${DB_PATH}" "INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ${node_count});"
    local run_id
    run_id=$(sqlite3 "${DB_PATH}" "SELECT last_insert_rowid();")
    
    # 3. Für jeden Node sammeln
    local success_count=0
    local failed_count=0
    local total_logs=0
    
    for node_data in "${nodes[@]}"; do
        local node_id
        node_id=$(echo "${node_data}" | cut -d'|' -f1 | cut -d'=' -f2)
        
        if [[ "${node_id}" == "node1" ]]; then
            # Lokale Logs (Gateway selbst)
            info "node1: Lokale Collection (Gateway)"
            ((success_count++))
        else
            # Remote-Node abfragen
            if result=$(ssh_connect_and_collect "${node_data}" 2>/dev/null); then
                ((success_count++))
                total_logs=$((total_logs + result))
            else
                ((failed_count++))
            fi
        fi
    done
    
    # 4. Run abschließen
    sqlite3 "${DB_PATH}" "UPDATE collection_runs SET finished_at = CURRENT_TIMESTAMP, nodes_success = ${success_count}, nodes_failed = ${failed_count}, logs_collected = ${total_logs} WHERE run_id = ${run_id};"
    
    # 5. Retention-Cleanup
    info "Retention-Cleanup (30 Tage)..."
    cleanup_retention >/dev/null
    
    info "============================================================"
    info "SUMMARY: ${success_count} OK, ${failed_count} Failed, ${total_logs} Logs"
    info "============================================================"
}

main() {
    echo "============================================================"
    echo "LOG COLLECTOR"
    echo "============================================================"
    
    init_logger
    
    if ! run_collection_cycle; then
        error "CRITICAL ERROR during collection cycle"
        exit 1
    fi
}

main "$@"
