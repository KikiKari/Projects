#!/usr/bin/env bash
# db_maintainer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

# Konfiguration
WORKSPACE="/home/openclaw/.openclaw/workspace"
DB_DIR="$WORKSPACE/db"
BACKUP_DIR="$DB_DIR/backups"
LOG_DIR="$WORKSPACE/logs/db-maintainer"
IMPORTANT_DIR="$WORKSPACE/important"
STATE_FILE="$DB_DIR/maintainer_state.json"
RETENTION_DAYS=3

# Verzeichnisse erstellen
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Logger Funktionen
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] [$level] $message"
    echo "$line"
    echo "$line" >> "$(date '+%Y-%m-%d').log"
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

# Hilfsfunktionen
get_file_hash() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        md5sum "$filepath" | cut -d' ' -f1
    else
        echo ""
    fi
}

run_tree_command() {
    local output
    output=$(timeout 60 tree -a -L 8 "$WORKSPACE" 2>/dev/null) && {
        log_info "tree -a -L 8 erfolgreich ausgeführt"
        echo "$output"
    } || {
        log_error "tree command fehlgeschlagen"
        echo ""
    }
}

update_tree_file() {
    local tree_output="$1"
    if [[ -n "$tree_output" ]]; then
        local tree_file="$IMPORTANT_DIR/openclaw-tree.txt"
        local timestamp
        timestamp=$(date --iso-8601=seconds)
        
        cat > "$tree_file" <<EOF
# OpenClaw Workspace Tree
# Generiert: $timestamp
# Befehl: tree -a -L 8 $WORKSPACE
# Diese Datei wird automatisch von db-maintainer aktualisiert

$tree_output
EOF
        log_info "openclaw-tree.txt aktualisiert: $tree_file"
        return 0
    fi
    return 1
}

scan_documentations() {
    local temp_file=$(mktemp)
    find "$WORKSPACE" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/db/backups/*" | while read -r file; do
        local rel_path="${file#$WORKSPACE/}"
        local hash
        hash=$(get_file_hash "$file")
        local mtime
        mtime=$(stat -c %Y "$file")
        echo "$rel_path|$hash|$mtime"
    done > "$temp_file"
    echo "$temp_file"
}

check_for_changes() {
    local temp_docs="$1"
    local changes_file=$(mktemp)
    
    # Neue und geänderte Dateien
    while IFS='|' read -r path hash mtime; do
        if ! jq -e --arg p "$path" '.file_hashes[$p]' "$STATE_FILE" >/dev/null 2>&1; then
            echo "NEW: $path" >> "$changes_file"
        elif [[ "$(jq -r --arg p "$path" '.file_hashes[$p]' "$STATE_FILE")" != "$hash" ]]; then
            echo "CHANGED: $path" >> "$changes_file"
        fi
    done < "$temp_docs"
    
    # Gelöschte Dateien
    if [[ -f "$STATE_FILE" ]]; then
        jq -r '.file_hashes | keys[]' "$STATE_FILE" | while read -r old_path; do
            if ! grep -q "^$old_path|" "$temp_docs"; then
                echo "DELETED: $old_path" >> "$changes_file"
            fi
        done
    fi
    
    echo "$changes_file"
}

update_databases() {
    timeout 60 python3 "$WORKSPACE/scripts/update_docs_db.py" >/dev/null 2>&1 && {
        log_info "docs.db aktualisiert"
        return 0
    } || {
        log_error "DB-Update fehlgeschlagen"
        return 1
    }
}

update_tree_db_v2() {
    timeout 120 python3 "$WORKSPACE/scripts/tree_indexer_v2.py" >/dev/null 2>&1 && {
        log_info "tree.db v2 aktualisiert"
        return 0
    } || {
        log_error "Tree-DB v2 fehlgeschlagen"
        return 1
    }
}

create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')
    
    for db in docs.db tree.db; do
        if [[ -f "$DB_DIR/$db" ]]; then
            local backup_name="${timestamp}_${db}.bak"
            cp "$DB_DIR/$db" "$BACKUP_DIR/$backup_name"
            log_info "Backup erstellt: $backup_name"
        fi
    done
    
    echo "$timestamp"
}

cleanup_old_backups() {
    local cutoff
    cutoff=$(date -d "$RETENTION_DAYS days ago" +%s)
    local deleted=0
    
    for db in docs.db tree.db; do
        find "$BACKUP_DIR" -name "*_${db}.bak" -type f | while read -r backup; do
            local backup_name
            backup_name=$(basename "$backup")
            local date_part
            date_part=$(echo "$backup_name" | cut -d'_' -f1-2)
            local backup_time
            backup_time=$(date -d "${date_part/_/ }" +%s 2>/dev/null) || continue
            
            if [[ $backup_time -lt $cutoff ]]; then
                rm "$backup"
                deleted=$((deleted + 1))
                log_info "Altes Backup gelöscht: $backup_name"
            fi
        done
    done
    
    if [[ $deleted -eq 0 ]]; then
        log_info "Keine alten Backups zum Löschen"
    else
        log_info "$deleted alte Backups gelöscht (< 3 Tage)"
    fi
}

run_cycle() {
    log_info "============================================================"
    log_info "DB MAINTAINER CYCLE START"
    log_info "============================================================"
    
    # Initialisiere State-Datei falls nicht vorhanden
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"last_check": null, "last_backup": null, "last_tree_update": null, "file_hashes": {}}' > "$STATE_FILE"
    fi
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    log_info "Führe tree -a -L 8 aus..."
    local tree_output
    tree_output=$(run_tree_command)
    if [[ -n "$tree_output" ]]; then
        update_tree_file "$tree_output"
        jq '.last_tree_update = "'"$(date --iso-8601=seconds)"'"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
    
    # 2. tree.db aktualisieren (intern v2)
    log_info "Aktualisiere tree.db v2..."
    update_tree_db_v2
    
    # 3. Änderungen prüfen
    log_info "Prüfe auf Dokumentations-Änderungen..."
    local temp_docs
    temp_docs=$(scan_documentations)
    local changes_file
    changes_file=$(check_for_changes "$temp_docs")
    local changes_count
    changes_count=$(wc -l < "$changes_file" | tr -d ' ')
    
    if [[ $changes_count -gt 0 ]]; then
        log_info "$changes_count Änderungen gefunden:"
        head -10 "$changes_file" | while read -r change; do
            log_info "  - $change"
        done
        if [[ $changes_count -gt 10 ]]; then
            local remaining
            remaining=$((changes_count - 10))
            log_info "  ... und $remaining weitere"
        fi
        
        # 4. docs.db aktualisieren
        log_info "Aktualisiere docs.db..."
        if update_databases; then
            # Aktualisiere State mit neuen Hashes
            local new_state
            new_state=$(jq '.last_check = "'"$(date --iso-8601=seconds)"'"' "$STATE_FILE")
            while IFS='|' read -r path hash _; do
                new_state=$(echo "$new_state" | jq --arg p "$path" --arg h "$hash" '.file_hashes[$p] = $h')
            done < "$temp_docs"
            echo "$new_state" > "$STATE_FILE"
        fi
    else
        log_info "Keine Dokumentations-Änderungen gefunden"
    fi
    
    # 5. Prüfe ob Backup fällig (stündlich)
    local last_backup
    last_backup=$(jq -r '.last_backup // "null"' "$STATE_FILE")
    local do_backup=false
    
    if [[ "$last_backup" == "null" ]]; then
        do_backup=true
    else
        local last_backup_seconds
        last_backup_seconds=$(date -d "$last_backup" +%s)
        local current_seconds
        current_seconds=$(date +%s)
        local diff_hours
        diff_hours=$(( (current_seconds - last_backup_seconds) / 3600 ))
        
        if [[ $diff_hours -ge 1 ]]; then
            do_backup=true
        fi
    fi
    
    if [[ "$do_backup" == true ]]; then
        log_info "Erstelle stündliches Backup..."
        local timestamp
        timestamp=$(create_backup)
        jq '.last_backup = "'"$(date --iso-8601=seconds)"'"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        log_info "Räume alte Backups auf (3 Tage Retention)..."
        cleanup_old_backups
    else
        log_info "Backup nicht nötig (letztes < 1h)"
    fi
    
    # Aufräumen
    rm -f "$temp_docs" "$changes_file"
    
    log_info "============================================================"
    log_info "DB MAINTAINER CYCLE END"
    log_info "============================================================"
}

main() {
    cd "$LOG_DIR" || exit 1
    
    run_cycle
}

main "$@"
