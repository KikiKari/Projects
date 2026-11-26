#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "cf8a3c6286753db928c1c85bf4dcdb37e1cdc13e793362106f6cd4f312348b08", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "shell"}
# db_maintainer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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

# Globale Variablen für Logging
declare LOG_FILE=""

# Logger Funktionen
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${timestamp}] [${level}] ${message}"
    echo "$line"
    echo "$line" >> "$LOG_FILE"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }

# Initialisiere Log-Datei
init_logger() {
    local today
    today=$(date '+%Y-%m-%d')
    LOG_FILE="$LOG_DIR/${today}.log"
}

# Lade Zustand
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"last_check": null, "last_backup": null, "last_tree_update": null, "file_hashes": {}}'
    fi
}

# Speichere Zustand
save_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE"
}

# Berechne MD5 Hash einer Datei
get_file_hash() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        md5sum "$filepath" 2>/dev/null | cut -d' ' -f1 || echo ""
    else
        echo ""
    fi
}

# Reiner Bash-Fallback für tree, falls das Binary fehlt
python_tree_fallback() {
    local max_depth=${1:-8}
    local root="$WORKSPACE"
    local output=""
    output+="$root"$'\n'

    walk() {
        local dirpath="$1"
        local prefix="$2"
        local depth="$3"
        local entries
        local entry
        local i
        local connector
        local extension

        if (( depth > max_depth )); then
            return
        fi

        # Liste alle Einträge im Verzeichnis auf
        mapfile -t entries < <(find "$dirpath" -maxdepth 1 -mindepth 1 2>/dev/null | sort)

        for (( i=0; i<${#entries[@]}; i++ )); do
            entry="${entries[$i]}"
            if (( i == ${#entries[@]} - 1 )); then
                connector="└── "
            else
                connector="├── "
            fi
            output+="${prefix}${connector}$(basename "$entry")"$'\n'

            if [[ -d "$entry" ]] && [[ ! -L "$entry" ]]; then
                if (( i == ${#entries[@]} - 1 )); then
                    extension="    "
                else
                    extension="│   "
                fi
                walk "$entry" "${prefix}${extension}" $((depth + 1))
            fi
        done
    }

    walk "$root" "" 1
    echo -n "$output"
}

# Führe tree -a -L 8 aus
run_tree_command() {
    local output
    local ret_code

    if command -v tree >/dev/null 2>&1; then
        output=$(timeout 60 tree -a -L 8 "$WORKSPACE" 2>&1)
        ret_code=$?
        if [[ $ret_code -eq 0 ]]; then
            info "tree -a -L 8 erfolgreich ausgeführt"
            echo "$output"
        else
            warn "tree command fehlgeschlagen: $(echo "$output" | tr '\n' ' ') – nutze Bash-Fallback"
            python_tree_fallback
        fi
    else
        warn "tree-Binary nicht installiert – nutze Bash-Fallback"
        python_tree_fallback
    fi
}

# Aktualisiere important/openclaw-tree.txt
update_tree_file() {
    local tree_output="$1"
    if [[ -z "$tree_output" ]]; then
        return 1
    fi

    local tree_file="$IMPORTANT_DIR/openclaw-tree.txt"
    local timestamp
    timestamp=$(date --iso-8601=seconds)

    {
        echo "# OpenClaw Workspace Tree"
        echo "# Generiert: $timestamp"
        echo "# Befehl: tree -a -L 8 $WORKSPACE"
        echo "# Diese Datei wird automatisch von db-maintainer aktualisiert"
        echo ""
        echo "$tree_output"
    } > "$tree_file"

    info "openclaw-tree.txt aktualisiert: $tree_file"
    return 0
}

# Scanne alle .md Dateien auf Änderungen
scan_documentations() {
    local docs_json="{"
    local first=true
    local file_path
    local rel_path
    local hash
    local mtime

    while IFS= read -r -d '' file; do
        file_path="$file"
        rel_path="${file_path#$WORKSPACE/}"
        
        # Überspringe Backups und node_modules
        if [[ "$rel_path" == *"db/backups"* ]] || [[ "$rel_path" == *"node_modules"* ]]; then
            continue
        fi

        hash=$(get_file_hash "$file_path")
        mtime=$(stat -c %Y "$file_path" 2>/dev/null || echo "0")

        if [[ "$first" == false ]]; then
            docs_json+=","
        fi
        first=false
        docs_json+="\"$rel_path\":{\"hash\":\"$hash\",\"mtime\":$mtime}"
    done < <(find "$WORKSPACE" -type f -name "*.md" -print0 2>/dev/null)

    docs_json+="}"
    echo "$docs_json"
}

# Prüfe auf Änderungen seit letztem Lauf
check_for_changes() {
    local state="$1"
    local current_docs_json="$2"
    local changes=()
    local current_hashes=()

    # Parse JSON mit jq (falls verfügbar) oder rudimentär mit sed/grep
    if command -v jq >/dev/null 2>&1; then
        # Neue oder geänderte Dateien
        while IFS= read -r file; do
            local current_hash
            current_hash=$(echo "$current_docs_json" | jq -r ".\"$file\".hash")
            local old_hash
            old_hash=$(echo "$state" | jq -r ".file_hashes.\"$file\"" 2>/dev/null || echo "null")

            if [[ "$old_hash" == "null" ]]; then
                changes+=("NEW: $file")
            elif [[ "$current_hash" != "$old_hash" ]]; then
                changes+=("CHANGED: $file")
            fi
            current_hashes["$file"]="$current_hash"
        done < <(echo "$current_docs_json" | jq -r 'keys[]')

        # Gelöschte Dateien
        while IFS= read -r file; do
            if [[ ! -v current_hashes["$file"] ]]; then
                changes+=("DELETED: $file")
            fi
        done < <(echo "$state" | jq -r '.file_hashes | keys[]' 2>/dev/null || true)
    else
        # Fallback ohne jq - einfache Implementierung
        # Extrahiere Keys aus current_docs_json
        local files_current
        files_current=$(echo "$current_docs_json" | grep -o '"[^"]*":{' | sed 's/"//g' | sed 's/:{//g')
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                local current_hash
                current_hash=$(echo "$current_docs_json" | grep "\"$file\":" | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p')
                local old_hash
                old_hash=$(echo "$state" | grep "\"$file\":" | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p' || echo "")

                if [[ -z "$old_hash" ]]; then
                    changes+=("NEW: $file")
                elif [[ "$current_hash" != "$old_hash" ]]; then
                    changes+=("CHANGED: $file")
                fi
                current_hashes["$file"]="$current_hash"
            fi
        done <<< "$files_current"

        # Gelöschte Dateien erkennen (vereinfacht)
        # Ohne jq schwer umsetzbar - überspringen wir hier
        :
    fi

    # Rückgabe als JSON-kompatibler String
    echo "${changes[*]}"
}

# Aktualisiere docs.db via Python-Skript
update_databases() {
    local script="$WORKSPACE/scripts/update_docs_db.py"
    if [[ -f "$script" ]]; then
        if timeout 60 python3 "$script"; then
            info "docs.db aktualisiert"
            return 0
        else
            error "DB-Update fehlgeschlagen"
            return 1
        fi
    else
        error "DB-Update-Skript nicht gefunden: $script"
        return 1
    fi
}

# Aktualisiere tree.db v2 via Python-Skript
update_tree_db_v2() {
    local script="$WORKSPACE/scripts/tree_indexer_v2.py"
    if [[ -f "$script" ]]; then
        if timeout 120 python3 "$script"; then
            info "tree.db v2 aktualisiert"
            return 0
        else
            error "Tree-DB v2 fehlgeschlagen"
            return 1
        fi
    else
        error "Tree-DB-v2-Skript nicht gefunden: $script"
        return 1
    fi
}

# Erstelle Backup beider Datenbanken
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

# Lösche alte Backups (> 3 Tage)
cleanup_old_backups() {
    local cutoff_timestamp
    cutoff_timestamp=$(date -d '3 days ago' +%s)
    local deleted=0

    for db_name in docs.db tree.db; do
        for backup in "$BACKUP_DIR"/*_"$db_name".bak; do
            if [[ -f "$backup" ]]; then
                local filename
                filename=$(basename "$backup")
                local date_part
                date_part=$(echo "$filename" | cut -d'_' -f1)
                local time_part
                time_part=$(echo "$filename" | cut -d'_' -f2)
                
                if [[ -n "$date_part" ]] && [[ -n "$time_part" ]]; then
                    local backup_date="${date_part}_${time_part}"
                    local backup_timestamp
                    backup_timestamp=$(date -d "$backup_date" +%s 2>/dev/null || echo "0")
                    
                    if [[ "$backup_timestamp" -lt "$cutoff_timestamp" ]]; then
                        rm -f "$backup"
                        deleted=$((deleted + 1))
                        info "Altes Backup gelöscht: $filename"
                    fi
                else
                    warn "Konnte Backup-Datum nicht parsen: $filename"
                fi
            fi
        done
    done

    if [[ $deleted -eq 0 ]]; then
        info "Keine alten Backups zum Löschen"
    else
        info "$deleted alte Backups gelöscht (< 3 Tage)"
    fi
}

# Ein kompletter Wartungszyklus
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
        state=$(echo "$state" | jq -r ".last_tree_update=\"$(date --iso-8601=seconds)\"" 2>/dev/null || echo "$state")
    fi

    # 2. tree.db aktualisieren (intern v2)
    info "Aktualisiere tree.db v2..."
    update_tree_db_v2

    # 3. Änderungen prüfen
    info "Prüfe auf Dokumentations-Änderungen..."
    local current_docs_json
    current_docs_json=$(scan_documentations)
    local changes_str
    changes_str=$(check_for_changes "$state" "$current_docs_json")
    local changes=($changes_str)

    if [[ ${#changes[@]} -gt 0 ]]; then
        info "$((${#changes[@]})) Änderungen gefunden:"
        local i
        for (( i=0; i<${#changes[@]} && i<10; i++ )); do
            info "  - ${changes[$i]}"
        done
        if [[ ${#changes[@]} -gt 10 ]]; then
            info "  ... und $((${#changes[@]}-10)) weitere"
        fi

        # 4. docs.db aktualisieren
        info "Aktualisiere docs.db..."
        if update_databases; then
            state=$(echo "$state" | jq -r ".last_check=\"$(date --iso-8601=seconds)\"" 2>/dev/null || echo "$state")
            
            # Aktualisiere file_hashes
            if command -v jq >/dev/null 2>&1; then
                local new_hashes
                new_hashes=$(echo "$current_docs_json" | jq -r '. | to_entries[] | "\(.key)=\(.value.hash)"')
                while IFS='=' read -r key value; do
                    state=$(echo "$state" | jq -r ".file_hashes.\"$key\"=\"$value\"" 2>/dev/null || echo "$state")
                done <<< "$new_hashes"
            fi
        fi
    else
        info "Keine Dokumentations-Änderungen gefunden"
    fi

    # 5. Prüfe ob Backup fällig (stündlich)
    local last_backup
    last_backup=$(echo "$state" | jq -r '.last_backup // empty' 2>/dev/null || echo "")
    local do_backup=false

    if [[ -z "$last_backup" ]]; then
        do_backup=true
    else
        local last_backup_timestamp
        last_backup_timestamp=$(date -d "$last_backup" +%s 2>/dev/null || echo "0")
        local now_timestamp
        now_timestamp=$(date +%s)
        local diff_hours
        diff_hours=$(( (now_timestamp - last_backup_timestamp) / 3600 ))

        if [[ $diff_hours -ge 1 ]]; then
            do_backup=true
        fi
    fi

    if [[ "$do_backup" == true ]]; then
        info "Erstelle stündliches Backup..."
        local timestamp
        timestamp=$(create_backup)
        state=$(echo "$state" | jq -r ".last_backup=\"$(date --iso-8601=seconds)\"" 2>/dev/null || echo "$state")

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
    init_logger
    run_cycle
}

# Starte das Skript
main "$@"
