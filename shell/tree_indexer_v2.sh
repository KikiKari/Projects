#!/usr/bin/env bash
# tree_indexer_v2.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

readonly WORKSPACE="/workspace"
readonly DB_DIR="$WORKSPACE"

# Globale Variablen
declare db_path

# Initialisiert die Datenbankverbindung
connect() {
    : # In Bash wird die SQLite-Datenbank direkt über Befehle angesprochen
}

# Erstellt erweiterte Tabellenstruktur
init_schema_v2() {
    local schema_sql="
        CREATE TABLE IF NOT EXISTS tree_entries_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT UNIQUE,
            root_path TEXT NOT NULL,
            relative_path TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT CHECK(type IN ('file', 'directory', 'symlink')),
            depth INTEGER,
            parent_path TEXT,
            
            size_bytes INTEGER,
            previous_size_bytes INTEGER,
            size_change_bytes INTEGER,
            
            mtime_timestamp REAL,
            mtime_iso TEXT,
            first_seen_timestamp REAL,
            last_seen_timestamp REAL,
            
            change_type TEXT CHECK(change_type IN ('NEW', 'MODIFIED', 'MOVED', 'RENAMED', 'UNCHANGED', 'DELETED')),
            
            original_name TEXT,
            original_path TEXT,
            previous_path TEXT,
            
            content_hash TEXT,
            
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS file_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            change_type TEXT NOT NULL,
            old_path TEXT,
            new_path TEXT,
            old_size INTEGER,
            new_size INTEGER,
            FOREIGN KEY (file_id) REFERENCES tree_entries_v2(file_id)
        );
        
        CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id);
        CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path);
        CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp);
        CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type);
    "
    
    sqlite3 "$db_path" "$schema_sql"
    echo "✅ tree.db Schema v2 erstellt/aktualisiert"
}

# Extrahiert Metadaten einer Datei
get_file_metadata() {
    local full_path="$1"
    local size mtime mtime_iso
    
    if [[ -e "$full_path" ]]; then
        size=$(stat -c%s "$full_path" 2>/dev/null || echo "0")
        mtime=$(stat -c%Y "$full_path" 2>/dev/null || echo "0")
        if [[ "$mtime" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            mtime_iso=$(date -d "@$mtime" -u +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "")
        else
            mtime_iso=""
        fi
    else
        size="0"
        mtime="0"
        mtime_iso=""
    fi
    
    echo "$size|$mtime|$mtime_iso"
}

# Generiert eindeutige ID aus Pfad
generate_file_id() {
    local relative_path="$1"
    printf "%s" "$relative_path" | md5sum | cut -d' ' -f1 | head -c16
}

# Detailliertes Scanning mit Metadaten
scan_directory_detailed() {
    local root_path="$1"
    local max_depth="${2:-8}"
    local entries=()
    
    while IFS= read -r -d '' file; do
        local rel_path="${file#$root_path/}"
        local depth=$(echo "$rel_path" | tr '/' '\n' | wc -l)
        
        if (( depth <= max_depth )); then
            local file_id name type parent_path metadata size mtime mtime_iso
            
            file_id=$(generate_file_id "$rel_path")
            name=$(basename "$file")
            
            if [[ -d "$file" ]]; then
                type="directory"
            elif [[ -L "$file" ]]; then
                type="symlink"
            else
                type="file"
            fi
            
            parent_path=$(dirname "$rel_path")
            if [[ "$parent_path" == "." ]]; then
                parent_path=""
            fi
            
            metadata=$(get_file_metadata "$file")
            IFS='|' read -r size mtime mtime_iso <<< "$metadata"
            
            entries+=("$file_id|$root_path|$rel_path|$name|$type|$depth|$parent_path|$size|$mtime|$mtime_iso")
        fi
    done < <(find "$root_path" -print0)
    
    printf '%s\n' "${entries[@]}"
}

# Aktualisiert DB mit Änderungs-Erkennung
update_database() {
    local entries_file="$1"
    local now_timestamp now stats_new=0 stats_modified=0 stats_unchanged=0 stats_moved=0 stats_deleted=0
    
    now=$(date +%s)
    now_timestamp="$now"
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    sqlite3 "$db_path" "UPDATE tree_entries_v2 SET change_type = NULL"
    
    while IFS='|' read -r file_id root_path relative_path name type depth parent_path size_bytes mtime_timestamp mtime_iso; do
        local existing_query result old_mtime old_size old_path size_change change_type
        
        existing_query=$(sqlite3 "$db_path" "SELECT mtime_timestamp, size_bytes, relative_path FROM tree_entries_v2 WHERE file_id = '$file_id'")
        
        if [[ -n "$existing_query" ]]; then
            IFS='|' read -r old_mtime old_size old_path <<< "$existing_query"
            
            # Größenänderung berechnen
            size_change=$((size_bytes - old_size))
            
            # Änderungstyp bestimmen
            if [[ "$old_path" != "$relative_path" ]]; then
                change_type="MOVED"
                ((stats_moved++))
            elif [[ "$old_mtime" != "$mtime_timestamp" ]] || [[ "$old_size" != "$size_bytes" ]]; then
                change_type="MODIFIED"
                ((stats_modified++))
            else
                change_type="UNCHANGED"
                ((stats_unchanged++))
            fi
            
            # Update
            sqlite3 "$db_path" "
                UPDATE tree_entries_v2 SET
                    size_bytes = $size_bytes,
                    previous_size_bytes = $old_size,
                    size_change_bytes = $size_change,
                    mtime_timestamp = $mtime_timestamp,
                    mtime_iso = '$mtime_iso',
                    last_seen_timestamp = $now_timestamp,
                    change_type = '$change_type',
                    previous_path = '$old_path',
                    original_path = COALESCE(original_path, '$old_path'),
                    updated_at = CURRENT_TIMESTAMP
                WHERE file_id = '$file_id'
            "
            
            # Änderung in Historie loggen
            if [[ "$change_type" == "MODIFIED" ]] || [[ "$change_type" == "MOVED" ]]; then
                sqlite3 "$db_path" "
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES ('$file_id', $now_timestamp, '$change_type', '$old_path', '$relative_path', $old_size, $size_bytes)
                "
            fi
        else
            # Neue Datei
            ((stats_new++))
            sqlite3 "$db_path" "
                INSERT INTO tree_entries_v2
                (file_id, root_path, relative_path, name, type, depth, parent_path,
                 size_bytes, previous_size_bytes, size_change_bytes,
                 mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                 change_type, content_hash)
                VALUES ('$file_id', '$root_path', '$relative_path', '$name', '$type', $depth, '$parent_path',
                        $size_bytes, $size_bytes, 0,
                        $mtime_timestamp, '$mtime_iso',
                        $now_timestamp, $now_timestamp,
                        'NEW', NULL)
            "
        fi
    done < "$entries_file"
    
    # Markiere nicht aktualisierte Einträge als DELETED
    local deleted_query deleted_count=0
    deleted_query=$(sqlite3 "$db_path" "
        SELECT file_id FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < ($now_timestamp - 3600)
    ")
    
    while IFS= read -r file_id; do
        if [[ -n "$file_id" ]]; then
            sqlite3 "$db_path" "
                UPDATE tree_entries_v2 
                SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
                WHERE file_id = '$file_id'
            "
            ((deleted_count++))
        fi
    done <<< "$deleted_query"
    
    stats_deleted=$deleted_count
    
    echo "new:$stats_new"
    echo "modified:$stats_modified"
    echo "unchanged:$stats_unchanged"
    echo "moved:$stats_moved"
    echo "deleted:$stats_deleted"
}

# Exportiert Änderungen der letzten X Stunden
export_changes() {
    local since_hours="${1:-24}"
    local since export_file data
    
    since=$(($(date +%s) - (since_hours * 3600)))
    export_file="$WORKSPACE/tree_changes_last_${since_hours}h.json"
    
    data=$(sqlite3 -json "$db_path" "
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since
        ORDER BY last_seen_timestamp DESC
    ")
    
    echo "$data" | jq '.' > "$export_file"
    echo "✅ Änderungen exportiert: $export_file ($(echo "$data" | jq 'length')) Einträge)"
    echo "$export_file"
}

main() {
    echo "============================================================"
    echo "TREE INDEXER v2 - Erweitertes Tracking"
    echo "============================================================"
    
    db_path="$DB_DIR/db/tree.db"
    
    # Sicherstellen, dass das DB-Verzeichnis existiert
    mkdir -p "$(dirname "$db_path")"
    
    init_schema_v2
    
    echo
    echo "--- Scanning Workspace ---"
    local temp_entries="/tmp/tree_entries.txt"
    scan_directory_detailed "$WORKSPACE" 8 > "$temp_entries"
    local count=$(wc -l < "$temp_entries")
    echo "Gefunden: $count Einträge"
    
    echo
    echo "--- Aktualisiere Datenbank ---"
    local stats_output
    stats_output=$(update_database "$temp_entries")
    
    local stats_new stats_modified stats_unchanged stats_moved stats_deleted
    while IFS=':' read -r key value; do
        case "$key" in
            new) stats_new="$value" ;;
            modified) stats_modified="$value" ;;
            unchanged) stats_unchanged="$value" ;;
            moved) stats_moved="$value" ;;
            deleted) stats_deleted="$value" ;;
        esac
    done <<< "$stats_output"
    
    echo "Statistiken:"
    echo "  NEU:        ${stats_new:-0}"
    echo "  MODIFIED:   ${stats_modified:-0}"
    echo "  MOVED:      ${stats_moved:-0}"
    echo "  UNCHANGED:  ${stats_unchanged:-0}"
    echo "  DELETED:    ${stats_deleted:-0}"
    
    echo
    echo "--- Exportiere Änderungen (24h) ---"
    export_changes 24
    
    echo
    echo "============================================================"
    echo "TREE INDEXING ABGESCHLOSSEN"
    echo "============================================================"
    
    # Temporäre Datei aufräumen
    rm -f "$temp_entries"
}

main "$@"
