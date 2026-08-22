#!/usr/bin/env bash
# tree_indexer_v2.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

# Konfiguration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE="${OPENCLAW_WORKSPACE:-$(realpath "$SCRIPT_DIR/../..")}"
readonly DB_PATH="$WORKSPACE/tree.db"

# Farben für Ausgabe
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging Funktionen
log_info() {
    echo -e "${GREEN}INFO${NC}: $1"
}

log_warn() {
    echo -e "${YELLOW}WARN${NC}: $1"
}

log_error() {
    echo -e "${RED}ERROR${NC}: $1" >&2
}

# Initialisierung der Datenbank
init_schema_v2() {
    local sql="
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
    
    sqlite3 "$DB_PATH" "$sql"
    log_info "tree.db Schema v2 erstellt/aktualisiert"
}

# Generiert eine eindeutige ID aus dem Pfad
generate_file_id() {
    local path="$1"
    printf "%s" "$path" | md5sum | cut -d' ' -f1 | head -c16
}

# Extrahiert Metadaten einer Datei
get_file_metadata() {
    local filepath="$1"
    if [[ -e "$filepath" ]]; then
        local size mtime
        size=$(stat -c%s "$filepath" 2>/dev/null || echo "0")
        mtime=$(stat -c%Y "$filepath" 2>/dev/null || echo "0")
        local mtime_iso=""
        if [[ "$mtime" != "0" ]]; then
            mtime_iso=$(date -d "@$mtime" -Iseconds 2>/dev/null || echo "")
        fi
        echo "$size|$mtime|$mtime_iso"
    else
        echo "0|0|"
    fi
}

# Scannt das Verzeichnis rekursiv mit Metadaten
scan_directory_detailed() {
    local root_path="$1"
    local max_depth="${2:-8}"
    local temp_scan_file
    temp_scan_file=$(mktemp)
    
    find "$root_path" -type f,d,l -printf '%P\n' 2>/dev/null | while read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        
        # Tiefe berechnen
        local depth
        depth=$(echo "$rel_path" | tr '/' '\n' | wc -l)
        [[ "$rel_path" != */* ]] && depth=1
        
        # Max depth check
        if (( depth > max_depth )); then
            continue
        fi
        
        local full_path="$root_path/$rel_path"
        local name
        name=$(basename "$rel_path")
        local parent_path
        parent_path=$(dirname "$rel_path")
        [[ "$parent_path" == "." ]] && parent_path=""
        
        local file_id
        file_id=$(generate_file_id "$rel_path")
        
        local metadata
        metadata=$(get_file_metadata "$full_path")
        IFS='|' read -r size mtime mtime_iso <<< "$metadata"
        
        local type
        if [[ -d "$full_path" ]]; then
            type="directory"
        elif [[ -L "$full_path" ]]; then
            type="symlink"
        else
            type="file"
        fi
        
        echo "$file_id|$root_path|$rel_path|$name|$type|$depth|$parent_path|$size|$mtime|$mtime_iso"
    done > "$temp_scan_file"
    
    cat "$temp_scan_file"
    rm -f "$temp_scan_file"
}

# Aktualisiert die Datenbank mit Änderungserkennung
update_database() {
    local scan_data="$1"
    local now_timestamp
    now_timestamp=$(date +%s)
    
    # Temporäre Datei für aktuelle Scan-Daten
    local current_scan_temp
    current_scan_temp=$(mktemp)
    echo "$scan_data" > "$current_scan_temp"
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    sqlite3 "$DB_PATH" "UPDATE tree_entries_v2 SET change_type = NULL;"
    
    # Statistiken initialisieren
    local new_count=0
    local modified_count=0
    local moved_count=0
    local unchanged_count=0
    
    # Verarbeite jeden Eintrag im Scan
    while IFS='|' read -r file_id root_path rel_path name type depth parent_path size mtime mtime_iso; do
        # Prüfe ob Datei bereits bekannt
        local existing_entry
        existing_entry=$(sqlite3 "$DB_PATH" "SELECT mtime_timestamp,size_bytes,relative_path FROM tree_entries_v2 WHERE file_id='$file_id';" 2>/dev/null || echo "")
        
        if [[ -n "$existing_entry" ]]; then
            IFS='|' read -r old_mtime old_size old_path <<< "$existing_entry"
            
            # Größenänderung berechnen
            local size_change=$((size - old_size))
            
            # Änderungstyp bestimmen
            local change_type="UNCHANGED"
            if [[ "$old_path" != "$rel_path" ]]; then
                change_type="MOVED"
                moved_count=$((moved_count + 1))
            elif [[ "$old_mtime" != "$mtime" ]] || [[ "$old_size" != "$size" ]]; then
                change_type="MODIFIED"
                modified_count=$((modified_count + 1))
            else
                unchanged_count=$((unchanged_count + 1))
            fi
            
            # Update
            sqlite3 "$DB_PATH" "
                UPDATE tree_entries_v2 SET
                    size_bytes=$size,
                    previous_size_bytes=$old_size,
                    size_change_bytes=$size_change,
                    mtime_timestamp=$mtime,
                    mtime_iso='$mtime_iso',
                    last_seen_timestamp=$now_timestamp,
                    change_type='$change_type',
                    previous_path=$( [[ "$change_type" == "MOVED" ]] && echo "'$old_path'" || echo "NULL" ),
                    original_path=COALESCE(original_path, $( [[ "$change_type" == "MOVED" ]] && echo "'$old_path'" || echo "NULL" )),
                    updated_at=CURRENT_TIMESTAMP
                WHERE file_id='$file_id';
            "
            
            # Änderung in Historie loggen
            if [[ "$change_type" == "MODIFIED" ]] || [[ "$change_type" == "MOVED" ]]; then
                sqlite3 "$DB_PATH" "
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES ('$file_id', $now_timestamp, '$change_type', '$old_path', '$rel_path', $old_size, $size);
                "
            fi
        else
            # Neue Datei
            new_count=$((new_count + 1))
            sqlite3 "$DB_PATH" "
                INSERT INTO tree_entries_v2
                (file_id, root_path, relative_path, name, type, depth, parent_path,
                 size_bytes, previous_size_bytes, size_change_bytes,
                 mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                 change_type, content_hash)
                VALUES ('$file_id', '$root_path', '$rel_path', '$name', '$type', $depth, '$parent_path',
                        $size, $size, 0,
                        $mtime, '$mtime_iso', $now_timestamp, $now_timestamp,
                        'NEW', NULL);
            "
        fi
    done < "$current_scan_temp"
    
    # Markiere nicht aktualisierte Einträge als DELETED
    local deleted_count
    deleted_count=$(sqlite3 "$DB_PATH" "
        SELECT COUNT(*) FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < ($now_timestamp - 3600);
    ")
    
    sqlite3 "$DB_PATH" "
        UPDATE tree_entries_v2 
        SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
        WHERE change_type IS NULL OR last_seen_timestamp < ($now_timestamp - 3600);
    "
    
    # Ausgabe der Statistiken
    echo "new:$new_count"
    echo "modified:$modified_count"
    echo "moved:$moved_count"
    echo "unchanged:$unchanged_count"
    echo "deleted:$deleted_count"
    
    rm -f "$current_scan_temp"
}

# Exportiert Änderungen der letzten X Stunden
export_changes() {
    local since_hours="${1:-24}"
    local since
    since=$(( $(date +%s) - (since_hours * 3600) ))
    
    local export_file="$WORKSPACE/tree_changes_last_${since_hours}h.json"
    
    # Hole die Änderungen aus der Datenbank
    sqlite3 -separator '|' "$DB_PATH" "
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since
        ORDER BY last_seen_timestamp DESC;
    " > /tmp/export_data.txt
    
    # Konvertiere zu JSON (vereinfacht)
    {
        echo "["
        local first=true
        while IFS='|' read -r id file_id root_path relative_path name type depth parent_path \
                          size_bytes previous_size_bytes size_change_bytes mtime_timestamp \
                          mtime_iso first_seen_timestamp last_seen_timestamp change_type \
                          original_name original_path previous_path content_hash created_at updated_at; do
            if [[ "$first" == true ]]; then
                first=false
            else
                echo ","
            fi
            
            # JSON-Eintrag erstellen
            echo "  {"
            echo "    \"id\": $id,"
            echo "    \"file_id\": \"$file_id\","
            echo "    \"root_path\": \"$root_path\","
            echo "    \"relative_path\": \"$relative_path\","
            echo "    \"name\": \"$name\","
            echo "    \"type\": \"$type\","
            echo "    \"depth\": $depth,"
            echo "    \"parent_path\": \"$parent_path\","
            echo "    \"size_bytes\": $size_bytes,"
            echo "    \"previous_size_bytes\": $previous_size_bytes,"
            echo "    \"size_change_bytes\": $size_change_bytes,"
            echo "    \"mtime_timestamp\": $mtime_timestamp,"
            echo "    \"mtime_iso\": \"$mtime_iso\","
            echo "    \"first_seen_timestamp\": $first_seen_timestamp,"
            echo "    \"last_seen_timestamp\": $last_seen_timestamp,"
            echo "    \"change_type\": \"$change_type\","
            echo "    \"original_name\": \"$original_name\","
            echo "    \"original_path\": \"$original_path\","
            echo "    \"previous_path\": \"$previous_path\","
            echo "    \"content_hash\": \"$content_hash\","
            echo "    \"created_at\": \"$created_at\","
            echo "    \"updated_at\": \"$updated_at\""
            echo "  }"
        done < /tmp/export_data.txt
        echo "]"
    } > "$export_file"
    
    local count
    count=$(wc -l < /tmp/export_data.txt)
    log_info "Änderungen exportiert: $export_file ($((count))) Einträge)"
    
    rm -f /tmp/export_data.txt
}

# Hauptfunktion
main() {
    echo "============================================================"
    echo "TREE INDEXER v2 - Erweitertes Tracking"
    echo "============================================================"
    
    init_schema_v2
    
    echo
    echo "--- Scanning Workspace ---"
    local scan_data
    scan_data=$(scan_directory_detailed "$WORKSPACE" 8)
    local entry_count
    entry_count=$(echo "$scan_data" | wc -l)
    echo "Gefunden: $entry_count Einträge"
    
    echo
    echo "--- Aktualisiere Datenbank ---"
    local stats_output
    stats_output=$(update_database "$scan_data")
    
    # Parse Statistiken
    local new=0 modified=0 moved=0 unchanged=0 deleted=0
    while IFS=':' read -r key value; do
        case "$key" in
            new) new=$value ;;
            modified) modified=$value ;;
            moved) moved=$value ;;
            unchanged) unchanged=$value ;;
            deleted) deleted=$value ;;
        esac
    done <<< "$stats_output"
    
    echo "Statistiken:"
    echo "  NEU:        $new"
    echo "  MODIFIED:   $modified"
    echo "  MOVED:      $moved"
    echo "  UNCHANGED:  $unchanged"
    echo "  DELETED:    $deleted"
    
    echo
    echo "--- Exportiere Änderungen (24h) ---"
    export_changes 24
    
    echo
    echo "============================================================"
    echo "TREE INDEXING ABGESCHLOSSEN"
    echo "============================================================"
}

# Skript ausführen
main "$@"
