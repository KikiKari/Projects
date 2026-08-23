#!/bin/bash
# db_maintainer_run.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer_run.py
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

readonly WORKSPACE="/workspace"
readonly DB_DIR="${WORKSPACE}/db"
readonly BACKUP_DIR="${DB_DIR}/backups"
readonly LOG_DIR="${WORKSPACE}/logs/db-maintainer"
readonly IMPORTANT_DIR="${WORKSPACE}/important"
readonly STATE_FILE="${DB_DIR}/maintainer_state.json"
readonly RETENTION_DAYS=3

# Create directories
mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"

# Simple logger function
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [${level}] ${message}"
    echo "${line}"
    local log_file="${LOG_DIR}/$(date '+%Y-%m-%d').log"
    echo "${line}" >> "${log_file}"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }

# Load state from JSON file
load_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}"
    else
        echo '{"last_check": null, "last_backup": null, "last_tree_update": null, "file_hashes": {}}'
    fi
}

# Save state to JSON file
save_state() {
    local state="$1"
    echo "${state}" | jq '.' > "${STATE_FILE}"
}

# Calculate MD5 hash of a file
get_file_hash() {
    local filepath="$1"
    if [[ -f "${filepath}" ]]; then
        md5sum "${filepath}" | cut -d' ' -f1
    else
        echo "null"
    fi
}

# Run tree command on workspace
run_tree_command() {
    local output
    output=$(timeout 60 tree -a -L 6 "${WORKSPACE}" 2>&1)
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        info "tree -a -L 6 erfolgreich ausgeführt"
        echo "${output}"
    else
        error "tree command fehlgeschlagen: ${output}"
        echo "null"
    fi
}

# Write tree output to important/openclaw-tree.txt
update_tree_file() {
    local tree_output="$1"
    
    if [[ "${tree_output}" == "null" ]] || [[ -z "${tree_output}" ]]; then
        return 1
    fi
    
    local tree_file="${IMPORTANT_DIR}/openclaw-tree.txt"
    
    # Header with timestamp
    local header="# OpenClaw Workspace Tree
# Generiert: $(date -Iseconds)
# Befehl: tree -a -L 6 ${WORKSPACE}
# Diese Datei wird automatisch von db-maintainer aktualisiert

"
    
    {
        echo "${header}"
        echo "${tree_output}"
    } > "${tree_file}"
    
    info "openclaw-tree.txt aktualisiert: ${tree_file}"
    return 0
}

# Scan all .md files for changes
scan_documentations() {
    local temp_json=$(mktemp)
    echo '{"docs": []}' > "${temp_json}"
    
    while IFS= read -r -d '' md_file; do
        if [[ ! -L "${md_file}" ]]; then
            local rel_path
            rel_path=$(realpath --relative-to="${WORKSPACE}" "${md_file}")
            
            # Skip backups and node_modules
            if [[ "${rel_path}" != *"db/backups"* ]] && [[ "${rel_path}" != *"node_modules"* ]]; then
                local hash
                hash=$(get_file_hash "${md_file}")
                local mtime
                mtime=$(stat -c %Y "${md_file}")
                
                # Add to JSON array
                jq -c ".docs |= .+ [{\"path\": \"${rel_path}\", \"hash\": \"${hash}\", \"mtime\": ${mtime}}]" "${temp_json}" > "${temp_json}.tmp" && mv "${temp_json}.tmp" "${temp_json}"
            fi
        fi
    done < <(find "${WORKSPACE}" -name "*.md" -type f -print0 2>/dev/null || true)
    
    cat "${temp_json}"
    rm -f "${temp_json}"
}

# Check for changes since last run
check_for_changes() {
    local state="$1"
    local current_docs_json="$2"
    local changes_file="$3"
    
    : > "${changes_file}"
    
    # Get current hashes
    local current_hashes_json=$(mktemp)
    echo '{}' > "${current_hashes_json}"
    
    local docs_count
    docs_count=$(echo "${current_docs_json}" | jq '.docs | length')
    
    for (( i=0; i<docs_count; i++ )); do
        local path
        path=$(echo "${current_docs_json}" | jq -r ".docs[${i}].path")
        local hash
        hash=$(echo "${current_docs_json}" | jq -r ".docs[${i}].hash")
        
        # Add to current hashes
        jq -c ".\"${path}\" = \"${hash}\"" "${current_hashes_json}" > "${current_hashes_json}.tmp" && mv "${current_hashes_json}.tmp" "${current_hashes_json}"
        
        # Check if file is new or changed
        local old_hash
        old_hash=$(echo "${state}" | jq -r ".file_hashes.\"${path}\" // \"null\"")
        
        if [[ "${old_hash}" == "null" ]]; then
            echo "NEW: ${path}" >> "${changes_file}"
        elif [[ "${old_hash}" != "${hash}" ]]; then
            echo "CHANGED: ${path}" >> "${changes_file}"
        fi
    done
    
    # Check for deleted files
    local old_paths
    old_paths=$(echo "${state}" | jq -r '.file_hashes | keys[]')
    
    while IFS= read -r old_path; do
        if [[ -n "${old_path}" ]]; then
            # Check if path exists in current hashes
            if ! jq -e ".\"${old_path}\"" "${current_hashes_json}" >/dev/null 2>&1; then
                echo "DELETED: ${old_path}" >> "${changes_file}"
            fi
        fi
    done <<< "${old_paths}"
    
    cat "${current_hashes_json}"
    rm -f "${current_hashes_json}"
}

# Update docs database
update_databases() {
    local output
    output=$(timeout 60 python3 "${WORKSPACE}/scripts/update_docs_db.py" 2>&1)
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        info "docs.db aktualisiert"
        return 0
    else
        error "DB-Update fehlgeschlagen: ${output}"
        return 1
    fi
}

# Update tree database v2
update_tree_db_v2() {
    local output
    output=$(timeout 120 python3 "${WORKSPACE}/scripts/tree_indexer_v2.py" 2>&1)
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        info "tree.db v2 aktualisiert"
        return 0
    else
        error "Tree-DB v2 fehlgeschlagen: ${output}"
        return 1
    fi
}

# Create backup of databases
create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')
    
    for db_name in docs.db tree.db; do
        local source="${DB_DIR}/${db_name}"
        if [[ -f "${source}" ]]; then
            local backup_name="${timestamp}_${db_name}.bak"
            local backup_path="${BACKUP_DIR}/${backup_name}"
            cp "${source}" "${backup_path}"
            info "Backup erstellt: ${backup_name}"
        fi
    done
    
    echo "${timestamp}"
}

# Cleanup old backups (older than 3 days)
cleanup_old_backups() {
    local cutoff_timestamp
    cutoff_timestamp=$(date -d "${RETENTION_DAYS} days ago" +%s)
    local deleted=0
    
    for db_name in docs.db tree.db; do
        while IFS= read -r backup; do
            if [[ -f "${backup}" ]]; then
                # Extract date from filename (Format: YYYY-MM-DD_HH-MM)
                local basename
                basename=$(basename "${backup}")
                local date_part
                date_part=$(echo "${basename}" | cut -d'_' -f1)
                local time_part
                time_part=$(echo "${basename}" | cut -d'_' -f2)
                
                if [[ -n "${date_part}" ]] && [[ -n "${time_part}" ]]; then
                    local backup_date="${date_part}_${time_part}"
                    local backup_timestamp
                    backup_timestamp=$(date -d "${backup_date}" +%s 2>/dev/null || echo "0")
                    
                    if [[ "${backup_timestamp}" -lt "${cutoff_timestamp}" ]]; then
                        rm "${backup}"
                        deleted=$((deleted + 1))
                        info "Altes Backup gelöscht: $(basename "${backup}")"
                    fi
                else
                    warn "Konnte Backup-Datum nicht parsen: $(basename "${backup}")"
                fi
            fi
        done < <(find "${BACKUP_DIR}" -name "*_${db_name}.bak" 2>/dev/null || true)
    done
    
    if [[ ${deleted} -eq 0 ]]; then
        info "Keine alten Backups zum Löschen"
    else
        info "${deleted} alte Backups gelöscht (< 3 Tage)"
    fi
}

# Run one complete maintenance cycle
run_cycle() {
    info "============================================================"
    info "DB MAINTAINER CYCLE START"
    info "============================================================"
    
    local state
    state=$(load_state)
    
    # 1. Run tree command and write to openclaw-tree.txt
    info "Führe tree -a -L 8 aus..."
    local tree_output
    tree_output=$(run_tree_command)
    
    if [[ "${tree_output}" != "null" ]]; then
        update_tree_file "${tree_output}"
        state=$(echo "${state}" | jq ".last_tree_update = \"$(date -Iseconds)\"")
    fi
    
    # 2. Update tree.db (internal v2)
    info "Aktualisiere tree.db v2..."
    update_tree_db_v2
    
    # 3. Check for changes
    info "Prüfe auf Dokumentations-Änderungen..."
    
    local temp_docs
    temp_docs=$(mktemp)
    scan_documentations > "${temp_docs}"
    
    local changes_file
    changes_file=$(mktemp)
    
    local current_hashes_json
    current_hashes_json=$(check_for_changes "${state}" "$(cat "${temp_docs}")" "${changes_file}")
    
    local changes_count
    changes_count=$(wc -l < "${changes_file}" | tr -d ' ')
    
    if [[ ${changes_count} -gt 0 ]]; then
        info "${changes_count} Änderungen gefunden:"
        head -10 "${changes_file}" | while read -r change; do
            [[ -n "${change}" ]] && info "  - ${change}"
        done
        
        if [[ ${changes_count} -gt 10 ]]; then
            info "  ... und $((changes_count - 10)) weitere"
        fi
        
        # 4. Update docs.db
        info "Aktualisiere docs.db..."
        if update_databases; then
            state=$(echo "${state}" | jq ".last_check = \"$(date -Iseconds)\"")
            
            # Update file hashes in state
            state=$(echo "${state}" | jq ".file_hashes = ${current_hashes_json}")
        fi
    else
        info "Keine Dokumentations-Änderungen gefunden"
    fi
    
    rm -f "${temp_docs}" "${changes_file}"
    
    # 5. Check if backup is due (hourly)
    local last_backup
    last_backup=$(echo "${state}" | jq -r '.last_backup // "null"')
    local do_backup=false
    
    if [[ "${last_backup}" == "null" ]]; then
        do_backup=true
    else
        local last_backup_timestamp
        last_backup_timestamp=$(date -d "${last_backup}" +%s 2>/dev/null || echo "0")
        local current_timestamp
        current_timestamp=$(date +%s)
        local diff_hours
        diff_hours=$(( (current_timestamp - last_backup_timestamp) / 3600 ))
        
        if [[ ${diff_hours} -ge 1 ]]; then
            do_backup=true
        fi
    fi
    
    if [[ "${do_backup}" == "true" ]]; then
        info "Erstelle stündliches Backup..."
        local timestamp
        timestamp=$(create_backup)
        state=$(echo "${state}" | jq ".last_backup = \"$(date -Iseconds)\"")
        
        # 6. Clean up old backups (3 days retention)
        info "Räume alte Backups auf (3 Tage Retention)..."
        cleanup_old_backups
    else
        info "Backup nicht nötig (letztes < 1h)"
    fi
    
    save_state "${state}"
    
    info "============================================================"
    info "DB MAINTAINER CYCLE END"
    info "============================================================"
}

# Main function
main() {
    run_cycle
}

# Run main function
main "$@"
