#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "229dfe093cc3f758da59031ab89817db1c61eff0b995e7d8867a98027ddc4d11", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "shell"}
# log_collector.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
# auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Log Collector Sub-Agent
# Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly DB_PATH="${WORKSPACE}/db/logs.db"
readonly LOG_DIR="${WORKSPACE}/logs/log-collector"

mkdir -p "${LOG_DIR}"

# Globale Variablen für Logging
declare LOG_FILE

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

info() { log "INFO" "$1"; }
error() { log "ERROR" "$1"; }

# Datenbank Funktionen
connect_db() {
    # Prüfen ob Tabellen existieren
    if ! sqlite3 "${DB_PATH}" "SELECT name FROM sqlite_master WHERE type='table';" >/dev/null 2>&1; then
        local schema_path="${WORKSPACE}/db/logs.db.schema.sql"
        if [[ -f "${schema_path}" ]]; then
            sqlite3 "${DB_PATH}" < "${schema_path}"
        fi
    fi
}

get_nodes() {
    # Gibt JSON mit allen Nodes zurück
    sqlite3 -json "${DB_PATH}" "SELECT * FROM nodes;"
}

check_vpn() {
    local ip="$1"
    ping -c 1 -W 3 "${ip}" >/dev/null 2>&1
}

_log_ssh_connection() {
    local node_id="$1"
    local conn_type="$2"
    local success="$3"
    local error_msg="$4"
    
    sqlite3 "${DB_PATH}" <<EOF
INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
VALUES ('${node_id}', '${conn_type}', ${success}, '${error_msg}');
EOF
}

_insert_logs() {
    local node_id="$1"
    local logs_json="$2"
    local retention
    retention=$(date -d "+30 days" --iso-8601=seconds)
    
    # Parsen des JSON und Einfügen in DB
    local count
    count=$(echo "${logs_json}" | jq -r 'length')
    local i
    for ((i=0; i<count; i++)); do
        local command
        local output
        command=$(echo "${logs_json}" | jq -r ".[${i}].command" | cut -c1-50)
        output=$(echo "${logs_json}" | jq -r ".[${i}].output" | cut -c1-10000)
        local timestamp
        timestamp=$(echo "${logs_json}" | jq -r ".[${i}].timestamp")
        
        sqlite3 "${DB_PATH}" <<EOF
INSERT INTO logs (node_id, log_type, source, content, severity, collected_by, collection_method, retention_until)
VALUES ('${node_id}', 'system', '${command}', '${output}', 'info', 'node1', 'ssh', '${retention}');
EOF
    done
    
    info "${node_id}: ${count} Log-Einträge gespeichert"
}

cleanup_retention() {
    local deleted
    deleted=$(sqlite3 "${DB_PATH}" "DELETE FROM logs WHERE retention_until < datetime('now'); SELECT changes();")
    info "Retention-Cleanup: ${deleted} alte Logs gelöscht"
    echo "${deleted}"
}

ssh_connect_and_collect() {
    local node_json="$1"
    local node_id
    node_id=$(echo "${node_json}" | jq -r '.node_id')
    local vpn_ip
    vpn_ip=$(echo "${node_json}" | jq -r '.vpn_ip // .tailscale_ip // .wireguard_ip')
    
    if [[ -z "${vpn_ip}" || "${vpn_ip}" == "null" ]]; then
        error "${node_id}: Keine VPN-IP konfiguriert"
        echo "null"
        return
    fi
    
    # 1. VPN-Check
    info "${node_id}: Prüfe VPN ${vpn_ip}..."
    if ! check_vpn "${vpn_ip}"; then
        error "${node_id}: VPN nicht erreichbar"
        _log_ssh_connection "${node_id}" "tailscale" 0 "VPN unreachable"
        echo "null"
        return
    fi
    
    # 2. SSH-Verbindung
    info "${node_id}: Verbinde via SSH..."
    
    local logs_collected=""
    local commands=("journalctl -n 500 --no-pager" "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'" "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'")
    local success=1
    local error_msg=""
    
    for cmd in "${commands[@]}"; do
        if result=$(timeout 30 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "openclaw@${vpn_ip}" "${cmd}" 2>/dev/null); then
            local timestamp
            timestamp=$(date --iso-8601=seconds)
            logs_collected+="{\"command\":\"${cmd}\",\"output\":\"$(echo "${result}" | sed 's/"/\\"/g')\",\"timestamp\":\"${timestamp}\"},"
        else
            success=0
            error_msg="SSH command failed: ${cmd}"
            break
        fi
    done
    
    if [[ -n "${logs_collected}" ]]; then
        logs_collected="[${logs_collected%,}]"
        _log_ssh_connection "${node_id}" "ssh" "${success}" "${error_msg}"
        
        if [[ ${success} -eq 1 ]]; then
            _insert_logs "${node_id}" "${logs_collected}"
            echo "$(echo "${logs_collected}" | jq -r 'length')"
        else
            echo "null"
        fi
    else
        echo "null"
    fi
}

run_collection_cycle() {
    info "============================================================"
    info "LOG COLLECTOR CYCLE START"
    info "============================================================"
    
    connect_db
    
    # 1. Nodes holen
    local nodes_json
    nodes_json=$(get_nodes)
    local nodes_count
    nodes_count=$(echo "${nodes_json}" | jq -r 'length')
    info "Gefunden: ${nodes_count} Nodes"
    
    # 2. Collection-Run starten
    local run_id
    run_id=$(sqlite3 "${DB_PATH}" "INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ${nodes_count}); SELECT last_insert_rowid();")
    
    # 3. Für jeden Node sammeln
    local success_count=0
    local failed_count=0
    local total_logs=0
    
    local i
    for ((i=0; i<nodes_count; i++)); do
        local node
        node=$(echo "${nodes_json}" | jq -r ".[${i}]")
        local node_id
        node_id=$(echo "${node}" | jq -r '.node_id')
        
        if [[ "${node_id}" == "node1" ]]; then
            # Lokale Logs (Gateway selbst)
            info "node1: Lokale Collection (Gateway)"
            ((success_count++))
        else
            # Remote-Node abfragen
            local result
            result=$(ssh_connect_and_collect "${node}")
            if [[ "${result}" != "null" ]]; then
                ((success_count++))
                total_logs=$((total_logs + result))
            else
                ((failed_count++))
            fi
        fi
    done
    
    # 4. Run abschließen
    sqlite3 "${DB_PATH}" <<EOF
UPDATE collection_runs SET
    finished_at = CURRENT_TIMESTAMP,
    nodes_success = ${success_count},
    nodes_failed = ${failed_count},
    logs_collected = ${total_logs}
WHERE run_id = ${run_id};
EOF
    
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
