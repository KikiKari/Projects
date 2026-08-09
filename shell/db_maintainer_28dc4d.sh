#!/usr/bin/env bash
# db_maintainer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

# Konfiguration
readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly DB_DIR="${WORKSPACE}/db"
readonly BACKUP_DIR="${DB_DIR}/backups"
readonly LOG_DIR="${WORKSPACE}/logs/db-maintainer"
readonly IMPORTANT_DIR="${WORKSPACE}/important"
readonly STATE_FILE="${DB_DIR}/maintainer_state.json"

# Verzeichnisse erstellen
mkdir -p "${BACKUP_DIR}" "${LOG_DIR}" "${IMPORTANT_DIR}"

# Logger Funktionen
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [${level}] ${message}"
    echo "${line}"
    echo "${line}" >> "${LOG_DIR}/$(date '+%Y-%m-%d').log"
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

# Hilfsfunktionen
get_file_hash() {
    local filepath="$1"
    if [[ -f "${filepath}" ]]; then
        md5sum "${filepath}" | cut -d' ' -f1
    else
        echo "ERROR"
    fi
}

run_tree_command() {
    local output
    output=$(timeout 60 tree -a -L 6 "${WORKSPACE}" 2>&1)
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_info "tree -a -L 6 erfolgreich ausgeführt"
        echo "${output}"
    else
        log_error "tree command fehlgeschlagen: ${output}"
        return 1
    fi
}

update_tree_file() {
    local tree_output="$1"
    if [[ -z "${tree_output}" ]]; then
        return 1
    fi
    
    local tree_file="${IMPORTANT_DIR}/openclaw-tree.txt"
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    
    # Header mit Timestamp
    cat > "${tree_file}" <<EOF
# OpenClaw Workspace Tree
# Generiert: ${timestamp}
# Befehl: tree -a -L 6 ${WORKSPACE}
# Diese Datei wird automatisch von db-maintainer aktualisiert

${tree_output}
EOF
    
    log_info "openclaw-tree.txt aktualisiert: ${tree_file}"
}

scan_documentations() {
    local temp_file
    temp_file=$(mktemp)
    
    # Finde alle .md Dateien außer in Backups und node_modules
    find "${WORKSPACE}" -name "*.md" -type f \
        -not -path "${DB_DIR}/backups/*" \
        -not -path "*/node_modules/*" \
        -exec stat -c "%n|%Y" {} \; > "${temp_file}"
    
    echo "${temp_file}"
}

check_for_changes() {
    local docs_temp="$1"
    local state_file="$2"
    local changes_file
    changes_file=$(mktemp)
    
    # Lade alte Hashes aus State-File
    local old_hashes_temp
    old_hashes_temp=$(mktemp)
    if [[ -f "${state_file}" ]]; then
        jq -r '.file_hashes | to_entries[] | "\(.key)|\(.value)"' "${state_file}" 2>/dev/null > "${old_hashes_temp}" || true
    fi
    
    # Prüfe auf Änderungen
    while IFS='|' read -r filepath mtime; do
        local rel_path
        rel_path=$(realpath --relative-to="${WORKSPACE}" "${filepath}")
        local current_hash
        current_hash=$(get_file_hash "${filepath}")
        
        # Suche nach altem Hash
        local old_hash=""
        if [[ -f "${old_hashes_temp}" ]]; then
            old_hash=$(grep "^${rel_path}|" "${old_hashes_temp}" | cut -d'|' -f2 || echo "")
        fi
        
        if [[ -z "${old_hash}" ]]; then
            echo "NEW: ${rel_path}" >> "${changes_file}"
        elif [[ "${old_hash}" != "${current_hash}" ]]; then
            echo "CHANGED: ${rel_path}" >> "${changes_file}"
        fi
        
        # Speichere aktuellen Hash für State
        echo "${rel_path}|${current_hash}" >> "${changes_file}.current"
    done < "${docs_temp}"
    
    # Prüfe auf gelöschte Dateien
    if [[ -f "${old_hashes_temp}" ]]; then
        while IFS='|' read -r old_path old_hash; do
            if ! grep -q "^${old_path}|" "${changes_file}.current" 2>/dev/null; then
                echo "DELETED: ${old_path}" >> "${changes_file}"
            fi
        done < "${old_hashes_temp}"
    fi
    
    rm -f "${old_hashes_temp}"
    echo "${changes_file}"
}

update_databases() {
    local script="${WORKSPACE}/scripts/update_docs_db.py"
    if [[ -f "${script}" ]]; then
        local output
        output=$(timeout 60 python3 "${script}" 2>&1)
        local exit_code=$?
        
        if [[ ${exit_code} -eq 0 ]]; then
            log_info "docs.db aktualisiert"
            return 0
        else
            log_error "DB-Update fehlgeschlagen: ${output}"
            return 1
        fi
    else
        log_error "DB-Update Script nicht gefunden: ${script}"
        return 1
    fi
}

update_tree_db_v2() {
    local script="${WORKSPACE}/scripts/tree_indexer_v2.py"
    if [[ -f "${script}" ]]; then
        local output
        output=$(timeout 120 python3 "${script}" 2>&1)
        local exit_code=$?
        
        if [[ ${exit_code} -eq 0 ]]; then
            log_info "tree.db v2 aktualisiert"
            return 0
        else
            log_error "Tree-DB v2 fehlgeschlagen: ${output}"
            return 1
        fi
    else
        log_error "Tree-DB v2 Script nicht gefunden: ${script}"
        return 1
    fi
}

create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')
    
    for db_name in docs.db tree.db; do
        local source="${DB_DIR}/${db_name}"
        if [[ -f "${source}" ]]; then
            local backup_name="${timestamp}_${db_name}.bak"
            local backup_path="${BACKUP_DIR}/${backup_name}"
            cp "${source}" "${backup_path}"
            log_info "Backup erstellt: ${backup_name}"
        fi
    done
    
    echo "${timestamp}"
}

cleanup_old_backups() {
    local retention_days=3
    local cutoff
    cutoff=$(date -d "${retention_days} days ago" '+%Y-%m-%d_%H-%M')
    local deleted=0
    
    for db_name in docs.db tree.db; do
        find "${BACKUP_DIR}" -name "*_${db_name}.bak" -type f | while read -r backup; do
            local backup_name
            backup_name=$(basename "${backup}")
            local date_part
            date_part=$(echo "${backup_name}" | cut -d'_' -f1,2)
            
            # Vergleiche Datum
            if [[ "${date_part}" < "${cutoff}" ]]; then
                rm -f "${backup}"
                deleted=$((deleted + 1))
                log_info "Altes Backup gelöscht: ${backup_name}"
            fi
        done
    done
    
    if [[ ${deleted} -eq 0 ]]; then
        log_info "Keine alten Backups zum Löschen"
    else
        log_info "${deleted} alte Backups gelöscht (< 3 Tage)"
    fi
}

save_state() {
    local state_file="$1"
    local last_check="$2"
    local last_backup="$3"
    local last_tree_update="$4"
    local current_hashes_file="$5"
    
    # Erstelle JSON State-File
    {
        echo "{"
        echo "  \"last_check\": \"${last_check}\","
        echo "  \"last_backup\": \"${last_backup}\","
        echo "  \"last_tree_update\": \"${last_tree_update}\","
        echo "  \"file_hashes\": {"
        
        local first=true
        while IFS='|' read -r path hash; do
            if [[ "${first}" == true ]]; then
                first=false
            else
                echo ","
            fi
            echo "    \"${path}\": \"${hash}\""
        done < "${current_hashes_file}"
        
        echo ""
        echo "  }"
        echo "}"
    } > "${state_file}"
}

run_cycle() {
    log_info "============================================================"
    log_info "DB MAINTAINER CYCLE START"
    log_info "============================================================"
    
    # Lade State
    local last_check=""
    local last_backup=""
    local last_tree_update=""
    
    if [[ -f "${STATE_FILE}" ]]; then
        last_check=$(jq -r '.last_check // ""' "${STATE_FILE}" 2>/dev/null || echo "")
        last_backup=$(jq -r '.last_backup // ""' "${STATE_FILE}" 2>/dev/null || echo "")
        last_tree_update=$(jq -r '.last_tree_update // ""' "${STATE_FILE}" 2>/dev/null || echo "")
    fi
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    log_info "Führe tree -a -L 8 aus..."
    local tree_output
    tree_output=$(run_tree_command 2>&1) && {
        update_tree_file "${tree_output}"
        last_tree_update=$(date --iso-8601=seconds)
    } || true
    
    # 2. tree.db aktualisieren (intern v2)
    log_info "Aktualisiere tree.db v2..."
    update_tree_db_v2 >/dev/null 2>&1 || true
    
    # 3. Änderungen prüfen
    log_info "Prüfe auf Dokumentations-Änderungen..."
    local docs_temp
    docs_temp=$(scan_documentations)
    local changes_file
    changes_file=$(check_for_changes "${docs_temp}" "${STATE_FILE}")
    
    if [[ -s "${changes_file}" ]]; then
        local change_count
        change_count=$(wc -l < "${changes_file}" | tr -d ' ')
        log_info "${change_count} Änderungen gefunden:"
        
        # Zeige erste 10 Änderungen
        head -10 "${changes_file}" | while read -r change; do
            log_info "  - ${change}"
        done
        
        if [[ ${change_count} -gt 10 ]]; then
            local remaining
            remaining=$((change_count - 10))
            log_info "  ... und ${remaining} weitere"
        fi
        
        # 4. docs.db aktualisieren
        log_info "Aktualisiere docs.db..."
        if update_databases; then
            last_check=$(date --iso-8601=seconds)
        fi
    else
        log_info "Keine Dokumentations-Änderungen gefunden"
    fi
    
    # 5. Prüfe ob Backup fällig (stündlich)
    local do_backup=false
    if [[ -z "${last_backup}" ]]; then
        do_backup=true
    else
        local last_backup_time
        last_backup_time=$(date -d "${last_backup}" +%s 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local time_diff
        time_diff=$((current_time - last_backup_time))
        
        if [[ ${time_diff} -ge 3600 ]]; then  # 3600 Sekunden = 1 Stunde
            do_backup=true
        fi
    fi
    
    if [[ "${do_backup}" == true ]]; then
        log_info "Erstelle stündliches Backup..."
        local timestamp
        timestamp=$(create_backup)
        last_backup=$(date --iso-8601=seconds)
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        log_info "Räume alte Backups auf (3 Tage Retention)..."
        cleanup_old_backups
    else
        log_info "Backup nicht nötig (letztes < 1h)"
    fi
    
    # Speichere State
    local current_hashes_file="${changes_file}.current"
    save_state "${STATE_FILE}" "${last_check}" "${last_backup}" "${last_tree_update}" "${current_hashes_file}"
    
    # Aufräumen
    rm -f "${docs_temp}" "${changes_file}" "${current_hashes_file}"
    
    log_info "============================================================"
    log_info "DB MAINTAINER CYCLE END"
    log_info "============================================================"
}

# Hauptfunktion
main() {
    run_cycle
}

# Skript ausführen
main "$@"
