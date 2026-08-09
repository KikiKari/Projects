#!/usr/bin/env bash
# db_maintainer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

# Konfiguration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE="${OPENCLAW_WORKSPACE:-$(dirname "$SCRIPT_DIR")}"
readonly DB_DIR="$WORKSPACE"
readonly BACKUP_DIR="$WORKSPACE/db/backups"
readonly LOG_DIR="$WORKSPACE/logs/db-maintainer"
readonly IMPORTANT_DIR="$WORKSPACE/important"
readonly STATE_FILE="$DB_DIR/maintainer_state.json"

# Verzeichnisse erstellen
mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$IMPORTANT_DIR"

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

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }

# Status laden/ speichern
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"last_check": null, "last_backup": null, "last_tree_update": null, "file_hashes": {}}'
    fi
}

save_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE"
}

# Datei-Hash berechnen
get_file_hash() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        md5sum "$filepath" 2>/dev/null | cut -d' ' -f1 || echo ""
    else
        echo ""
    fi
}

# Reiner Bash-Fallback für tree
python_tree_fallback() {
    local max_depth="${1:-8}"
    local root="$WORKSPACE"
    echo "$root"
    
    walk() {
        local dirpath="$1"
        local prefix="$2"
        local depth="$3"
        
        if (( depth > max_depth )); then
            return
        fi
        
        local entries
        entries=$(find "$dirpath" -maxdepth 1 -mindepth 1 2>/dev/null | sort)
        local entry_count
        entry_count=$(echo "$entries" | wc -l)
        local i=0
        
        while IFS= read -r entry; do
            ((i++))
            local connector
            if (( i == entry_count )); then
                connector="└── "
            else
                connector="├── "
            fi
            
            local basename_entry
            basename_entry=$(basename "$entry")
            echo "${prefix}${connector}${basename_entry}"
            
            if [[ -d "$entry" ]] && [[ ! -L "$entry" ]]; then
                local extension
                if (( i == entry_count )); then
                    extension="    "
                else
                    extension="│   "
                fi
                walk "$entry" "${prefix}${extension}" $((depth + 1))
            fi
        done <<< "$entries"
    }
    
    walk "$root" "" 1
}

# Tree-Befehl ausführen
run_tree_command() {
    local output
    local result
    
    if command -v tree >/dev/null 2>&1; then
        output=$(timeout 60 tree -a -L 8 "$WORKSPACE" 2>&1)
        result=$?
        if [[ $result -eq 0 ]]; then
            info "tree -a -L 8 erfolgreich ausgeführt"
            echo "$output"
            return 0
        else
            warn "tree command fehlgeschlagen: $output – nutze Bash-Fallback"
            python_tree_fallback
            return 0
        fi
    else
        warn "tree-Binary nicht installiert – nutze Bash-Fallback"
        python_tree_fallback
        return 0
    fi
}

# Tree-Datei aktualisieren
update_tree_file() {
    local tree_output="$1"
    if [[ -z "$tree_output" ]]; then
        return 1
    fi
    
    local tree_file="$IMPORTANT_DIR/openclaw-tree.txt"
    local header="# OpenClaw Workspace Tree
# Generiert: $(date --iso-8601=seconds)
# Befehl: tree -a -L 8 $WORKSPACE
# Diese Datei wird automatisch von db-maintainer aktualisiert

"
    
    {
        echo "$header"
        echo "$tree_output"
    } > "$tree_file"
    
    info "openclaw-tree.txt aktualisiert: $tree_file"
    return 0
}

# Dokumentationen scannen
scan_documentations() {
    local docs_json="[]"
    local temp_file
    temp_file=$(mktemp)
    
    while IFS= read -r -d '' md_file; do
        local rel_path
        rel_path="${md_file#$WORKSPACE/}"
        
        # Ausschlusskriterien prüfen
        if [[ "$rel_path" != db/backups/* ]] && [[ "$rel_path" != */node_modules/* ]]; then
            local hash
            hash=$(get_file_hash "$md_file")
            local mtime
            mtime=$(stat -c %Y "$md_file" 2>/dev/null || echo "0")
            
            docs_json=$(echo "$docs_json" | jq --arg path "$rel_path" --arg hash "$hash" --argjson mtime "$mtime" \
                '. += [{"path": $path, "hash": $hash, "mtime": $mtime}]')
        fi
    done < <(find "$WORKSPACE" -name "*.md" -type f -not -path "$WORKSPACE/db/backups/*" -print0 2>/dev/null || true)
    
    echo "$docs_json"
    rm -f "$temp_file"
}

# Auf Änderungen prüfen
check_for_changes() {
    local state="$1"
    local current_docs="$2"
    
    local changes="[]"
    local current_hashes="{}"
    
    # Aktuelle Hashes sammeln und Änderungen erkennen
    local doc_count
    doc_count=$(echo "$current_docs" | jq 'length')
    
    for ((i=0; i<doc_count; i++)); do
        local doc
        doc=$(echo "$current_docs" | jq -r ".[$i]")
        local path
        path=$(echo "$doc" | jq -r '.path')
        local hash
        hash=$(echo "$doc" | jq -r '.hash')
        
        current_hashes=$(echo "$current_hashes" | jq --arg path "$path" --arg hash "$hash" '. + {($path): $hash}')
        
        local old_hash
        old_hash=$(echo "$state" | jq -r --arg p "$path" '.file_hashes[$p] // empty')
        
        if [[ -z "$old_hash" ]]; then
            changes=$(echo "$changes" | jq --arg path "$path" '. += ["NEW: " + $path]')
        elif [[ "$old_hash" != "$hash" ]]; then
            changes=$(echo "$changes" | jq --arg path "$path" '. += ["CHANGED: " + $path]')
        fi
    done
    
    # Auf gelöschte Dateien prüfen
    local old_paths
    old_paths=$(echo "$state" | jq -r '.file_hashes | keys[]')
    
    while IFS= read -r old_path; do
        if [[ -n "$old_path" ]]; then
            local exists
            exists=$(echo "$current_hashes" | jq -r --arg p "$old_path" 'has($p)')
            if [[ "$exists" != "true" ]]; then
                changes=$(echo "$changes" | jq --arg path "$old_path" '. += ["DELETED: " + $path]')
            fi
        fi
    done <<< "$old_paths"
    
    echo "$changes"
    echo "$current_hashes"
}

# Datenbanken aktualisieren
update_databases() {
    local result
    result=$(timeout 60 python3 "$WORKSPACE/scripts/update_docs_db.py" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        info "docs.db aktualisiert"
        return 0
    else
        error "DB-Update fehlgeschlagen: $result"
        return 1
    fi
}

# Tree-DB v2 aktualisieren
update_tree_db_v2() {
    local result
    result=$(timeout 120 python3 "$WORKSPACE/scripts/tree_indexer_v2.py" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        info "tree.db v2 aktualisiert"
        return 0
    else
        error "Tree-DB v2 fehlgeschlagen: $result"
        return 1
    fi
}

# Backup erstellen
create_backup() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')
    
    for db_name in docs.db tree.db; do
        local source="$DB_DIR/$db_name"
        if [[ -f "$source" ]]; then
            local backup_name="${timestamp}_${db_name}.bak"
            local backup_path="$BACKUP_DIR/$backup_name"
            cp "$source" "$backup_path"
            info "Backup erstellt: $backup_name"
        fi
    done
    
    echo "$timestamp"
}

# Alte Backups aufräumen
cleanup_old_backups() {
    local retention_days=3
    local cutoff
    cutoff=$(date -d "$retention_days days ago" '+%Y-%m-%d_%H-%M')
    local deleted=0
    
    for db_name in docs.db tree.db; do
        while IFS= read -r backup; do
            local backup_name
            backup_name=$(basename "$backup")
            
            # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
            local date_part time_part backup_time
            IFS='_' read -r date_part time_part <<< "$backup_name"
            backup_time="${date_part}_${time_part}"
            
            if [[ -n "$backup_time" ]] && [[ "$backup_time" < "$cutoff" ]]; then
                rm -f "$backup"
                ((deleted++))
                info "Altes Backup gelöscht: $backup_name"
            fi
        done < <(find "$BACKUP_DIR" -name "*_${db_name}.bak" -type f 2>/dev/null || true)
    done
    
    if [[ $deleted -eq 0 ]]; then
        info "Keine alten Backups zum Löschen"
    else
        info "$deleted alte Backups gelöscht (< 3 Tage)"
    fi
}

# Hauptwartungszyklus
run_cycle() {
    info "============================================================"
    info "DB MAINTAINER CYCLE START"
    info "============================================================"
    
    local state
    state=$(load_state)
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    info "Führe tree -a -L 8 aus..."
    local tree_output
    tree_output=$(run_tree_command)
    if [[ -n "$tree_output" ]]; then
        update_tree_file "$tree_output"
        state=$(echo "$state" | jq --arg time "$(date --iso-8601=seconds)" '.last_tree_update = $time')
    fi
    
    # 2. tree.db aktualisieren (intern v2)
    info "Aktualisiere tree.db v2..."
    update_tree_db_v2 >/dev/null 2>&1 || true
    
    # 3. Änderungen prüfen
    info "Prüfe auf Dokumentations-Änderungen..."
    local current_docs
    current_docs=$(scan_documentations)
    local changes_and_hashes
    changes_and_hashes=$(check_for_changes "$state" "$current_docs")
    local changes
    changes=$(echo "$changes_and_hashes" | head -n1)
    local current_hashes
    current_hashes=$(echo "$changes_and_hashes" | tail -n1)
    
    local change_count
    change_count=$(echo "$changes" | jq 'length')
    
    if [[ $change_count -gt 0 ]]; then
        info "$change_count Änderungen gefunden:"
        local i=0
        while IFS= read -r change; do
            if [[ $i -lt 10 ]]; then
                info "  - $change"
            fi
            ((i++))
        done < <(echo "$changes" | jq -r '.[]')
        
        if [[ $change_count -gt 10 ]]; then
            info "  ... und $((change_count-10)) weitere"
        fi
        
        # 4. docs.db aktualisieren
        info "Aktualisiere docs.db..."
        if update_databases; then
            state=$(echo "$state" | jq --arg time "$(date --iso-8601=seconds)" '.last_check = $time')
            state=$(echo "$state" | jq --argjson hashes "$current_hashes" '.file_hashes = $hashes')
        fi
    else
        info "Keine Dokumentations-Änderungen gefunden"
    fi
    
    # 5. Prüfe ob Backup fällig (stündlich)
    local last_backup
    last_backup=$(echo "$state" | jq -r '.last_backup // empty')
    local do_backup=false
    
    if [[ -n "$last_backup" ]]; then
        local last_backup_time
        last_backup_time=$(date -d "$last_backup" +%s 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local diff_hours
        diff_hours=$(( (current_time - last_backup_time) / 3600 ))
        
        if [[ $diff_hours -ge 1 ]]; then
            do_backup=true
        fi
    else
        do_backup=true
    fi
    
    if [[ "$do_backup" == true ]]; then
        info "Erstelle stündliches Backup..."
        local timestamp
        timestamp=$(create_backup)
        state=$(echo "$state" | jq --arg time "$(date --iso-8601=seconds)" '.last_backup = $time')
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        info "Räume alte Backups auf (3 Tage Retention)..."
        cleanup_old_backups
    else
        info "Backup nicht nötig (letztes < 1h)"
    fi
    
    save_state "$state"
    
    info "============================================================"
    info "DB MAINTAINER CYCLE END"
    info "============================================================"
}

# Hauptfunktion
main() {
    cd "$LOG_DIR" || exit 1
    
    {
        run_cycle
    } 2>&1 | tee -a "$(date '+%Y-%m-%d').log"
}

# Skript ausführen
main "$@"
