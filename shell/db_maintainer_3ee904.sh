#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "8acdeeeb828fa0a46151eab014c9684d6ec36bfe98b6893c6ef557c0bd1480c0", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "shell"}
# db_maintainer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly DB_DIR="${WORKSPACE}/db"
readonly BACKUP_DIR="${DB_DIR}/backups"
readonly LOG_DIR="${WORKSPACE}/logs/db-maintainer"
readonly IMPORTANT_DIR="${WORKSPACE}/important"

# Create directories
mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"

# Global variables
declare LOG_FILE=""
declare STATE_FILE="${DB_DIR}/maintainer_state.json"
declare RETENTION_DAYS=3

# Logger functions
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [${level}] ${message}"
    echo "${line}"
    echo "${line}" >> "${LOG_FILE}"
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
    echo "${state}" > "${STATE_FILE}"
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
    output=$(timeout 60 tree -a -L 8 "${WORKSPACE}" 2>/dev/null) || {
        error "tree command failed or timed out"
        return 1
    }
    info "tree -a -L 8 successfully executed"
    echo "${output}"
}

# Write tree output to important/openclaw-tree.txt
update_tree_file() {
    local tree_output="$1"
    if [[ -z "${tree_output}" ]]; then
        return 1
    fi
    
    local tree_file="${IMPORTANT_DIR}/openclaw-tree.txt"
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    
    local header="# OpenClaw Workspace Tree
# Generated: ${timestamp}
# Command: tree -a -L 8 ${WORKSPACE}
# This file is automatically updated by db-maintainer

"
    
    {
        echo "${header}"
        echo "${tree_output}"
    } > "${tree_file}" || {
        error "Failed to write to openclaw-tree.txt"
        return 1
    }
    
    info "openclaw-tree.txt updated: ${tree_file}"
    return 0
}

# Scan all .md files for changes
scan_documentations() {
    local temp_file
    temp_file=$(mktemp)
    
    find "${WORKSPACE}" -name "*.md" -type f ! -path "*/db/backups/*" ! -path "*/node_modules/*" | while read -r md_file; do
        local rel_path
        rel_path=${md_file#"${WORKSPACE}"/}
        local hash
        hash=$(get_file_hash "${md_file}")
        local mtime
        mtime=$(stat -c %Y "${md_file}")
        echo "{\"path\":\"${rel_path}\",\"hash\":\"${hash}\",\"mtime\":${mtime}}"
    done > "${temp_file}"
    
    echo "${temp_file}"
}

# Check for changes since last run
check_for_changes() {
    local temp_docs="$1"
    local state="$2"
    
    local changes_file
    changes_file=$(mktemp)
    
    # Get previous hashes from state
    local prev_hashes
    prev_hashes=$(echo "${state}" | jq -r '.file_hashes | to_entries[] | "\(.key):\(.value)"' 2>/dev/null || echo "")
    
    # Check for new/changed files
    while IFS= read -r line; do
        local path
        path=$(echo "${line}" | jq -r '.path')
        local hash
        hash=$(echo "${line}" | jq -r '.hash')
        
        # Check if file is new or changed
        local prev_hash
        prev_hash=$(echo "${prev_hashes}" | grep "^${path}:" | cut -d':' -f2 || echo "")
        
        if [[ -z "${prev_hash}" ]]; then
            echo "NEW: ${path}" >> "${changes_file}"
        elif [[ "${prev_hash}" != "${hash}" ]]; then
            echo "CHANGED: ${path}" >> "${changes_file}"
        fi
    done < "${temp_docs}"
    
    # Check for deleted files
    local current_paths
    current_paths=$(jq -r '.path' "${temp_docs}" 2>/dev/null || echo "")
    
    while IFS= read -r old_entry; do
        local old_path
        old_path=$(echo "${old_entry}" | cut -d':' -f1)
        if ! echo "${current_paths}" | grep -q "^${old_path}$"; then
            echo "DELETED: ${old_path}" >> "${changes_file}"
        fi
    done <<< "$(echo "${prev_hashes}" | grep .)"
    
    echo "${changes_file}"
}

# Update databases by running scripts
update_databases() {
    local script="${WORKSPACE}/scripts/update_docs_db.py"
    if [[ -f "${script}" ]]; then
        if timeout 60 python3 "${script}" >/dev/null 2>&1; then
            info "docs.db updated"
            return 0
        else
            error "DB update failed"
            return 1
        fi
    else
        error "Update script not found: ${script}"
        return 1
    fi
}

# Update tree database v2
update_tree_db_v2() {
    local script="${WORKSPACE}/scripts/tree_indexer_v2.py"
    if [[ -f "${script}" ]]; then
        if timeout 120 python3 "${script}" >/dev/null 2>&1; then
            info "tree.db v2 updated"
            return 0
        else
            error "Tree-DB v2 failed"
            return 1
        fi
    else
        error "Tree indexer script not found: ${script}"
        return 1
    fi
}

# Create backup of both databases
create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')
    
    for db_name in "docs.db" "tree.db"; do
        local source="${DB_DIR}/${db_name}"
        if [[ -f "${source}" ]]; then
            local backup_name="${timestamp}_${db_name}.bak"
            local backup_path="${BACKUP_DIR}/${backup_name}"
            cp "${source}" "${backup_path}" && info "Backup created: ${backup_name}"
        fi
    done
    
    echo "${timestamp}"
}

# Clean up old backups (older than 3 days)
cleanup_old_backups() {
    local cutoff
    cutoff=$(date -d "-${RETENTION_DAYS} days" '+%s')
    local deleted=0
    
    for db_name in "docs.db" "tree.db"; do
        for backup in "${BACKUP_DIR}"/*_"${db_name}".bak; do
            if [[ -f "${backup}" ]]; then
                local filename
                filename=$(basename "${backup}")
                local date_part
                date_part=$(echo "${filename}" | cut -d'_' -f1-2)
                
                if [[ "${date_part}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$ ]]; then
                    local backup_time
                    backup_time=$(date -d "${date_part/_/ }" '+%s' 2>/dev/null || echo "0")
                    
                    if [[ "${backup_time}" -lt "${cutoff}" ]] && [[ "${backup_time}" -ne 0 ]]; then
                        rm -f "${backup}"
                        deleted=$((deleted + 1))
                        info "Deleted old backup: ${filename}"
                    fi
                else
                    warn "Could not parse backup date: ${filename}"
                fi
            fi
        done
    done
    
    if [[ ${deleted} -eq 0 ]]; then
        info "No old backups to delete"
    else
        info "${deleted} old backups deleted (< 3 days)"
    fi
}

# Main maintenance cycle
run_cycle() {
    local today
    today=$(date '+%Y-%m-%d')
    LOG_FILE="${LOG_DIR}/${today}.log"
    
    info "============================================================"
    info "DB MAINTAINER CYCLE START"
    info "============================================================"
    
    local state
    state=$(load_state)
    
    # 1. Run tree command and write to openclaw-tree.txt
    info "Running tree -a -L 8..."
    local tree_output
    tree_output=$(run_tree_command) || tree_output=""
    if [[ -n "${tree_output}" ]]; then
        update_tree_file "${tree_output}"
        state=$(echo "${state}" | jq ".last_tree_update=\"$(date --iso-8601=seconds)\"")
    fi
    
    # 2. Update tree.db v2
    info "Updating tree.db v2..."
    update_tree_db_v2 >/dev/null 2>&1 || true
    
    # 3. Check for documentation changes
    info "Checking for documentation changes..."
    local temp_docs
    temp_docs=$(scan_documentations)
    
    local changes_file
    changes_file=$(check_for_changes "${temp_docs}" "${state}")
    local changes_count
    changes_count=$(wc -l < "${changes_file}" | tr -d ' ')
    
    if [[ ${changes_count} -gt 0 ]]; then
        info "${changes_count} changes found:"
        head -10 "${changes_file}" | while read -r change; do
            info "  - ${change}"
        done
        
        if [[ ${changes_count} -gt 10 ]]; then
            local remaining
            remaining=$((changes_count - 10))
            info "  ... and ${remaining} more"
        fi
        
        # 4. Update docs.db
        info "Updating docs.db..."
        if update_databases; then
            state=$(echo "${state}" | jq ".last_check=\"$(date --iso-8601=seconds)\"")
            
            # Update file hashes in state
            local new_hashes="{"
            local first=true
            while IFS= read -r line; do
                local path
                path=$(echo "${line}" | jq -r '.path')
                local hash
                hash=$(echo "${line}" | jq -r '.hash')
                
                if [[ "${first}" == true ]]; then
                    first=false
                else
                    new_hashes+=","
                fi
                new_hashes+="\"${path}\":\"${hash}\""
            done < "${temp_docs}"
            new_hashes+="}"
            
            state=$(echo "${state}" | jq ".file_hashes=${new_hashes}")
        fi
    else
        info "No documentation changes found"
    fi
    
    # Clean up temp files
    rm -f "${temp_docs}" "${changes_file}"
    
    # 5. Check if backup is due (hourly)
    local last_backup
    last_backup=$(echo "${state}" | jq -r '.last_backup // "null"')
    local do_backup=false
    
    if [[ "${last_backup}" == "null" ]]; then
        do_backup=true
    else
        local last_backup_time
        last_backup_time=$(date -d "${last_backup}" '+%s' 2>/dev/null || echo "0")
        local now
        now=$(date '+%s')
        local diff_hours
        diff_hours=$(( (now - last_backup_time) / 3600 ))
        
        if [[ ${diff_hours} -ge 1 ]]; then
            do_backup=true
        fi
    fi
    
    if [[ "${do_backup}" == true ]]; then
        info "Creating hourly backup..."
        local timestamp
        timestamp=$(create_backup)
        state=$(echo "${state}" | jq ".last_backup=\"$(date --iso-8601=seconds)\"")
        
        # 6. Clean up old backups (3 days retention)
        info "Cleaning up old backups (3 days retention)..."
        cleanup_old_backups
    else
        info "Backup not needed (last < 1h)"
    fi
    
    save_state "${state}"
    
    info "============================================================"
    info "DB MAINTAINER CYCLE END"
    info "============================================================"
}

# Main function
main() {
    trap 'error "CRITICAL ERROR: $?"' ERR
    
    run_cycle
}

# Run main function
main "$@"
