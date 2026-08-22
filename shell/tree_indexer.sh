#!/bin/bash
# tree_indexer.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/tree_indexer.py
# auch in: OpenClaw@gateway2:scripts/tree_indexer.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Tree Indexer - Scannt Verzeichnisbäume und speichert in tree.db

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly DB_DIR="${WORKSPACE}/db"
readonly DB_PATH="${DB_DIR}/tree.db"

# Globale Variablen
declare -a ENTRIES=()

# Initialisiert das Skript
init() {
    mkdir -p "${DB_DIR}"
}

# Stellt Verbindung zur Datenbank her und erstellt Tabellen falls nötig
connect_and_setup_db() {
    sqlite3 "${DB_PATH}" <<EOF
CREATE TABLE IF NOT EXISTS tree_scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    root_path TEXT NOT NULL,
    max_depth INTEGER NOT NULL,
    total_files INTEGER DEFAULT 0,
    total_dirs INTEGER DEFAULT 0,
    total_symlinks INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tree_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    root_path TEXT NOT NULL,
    relative_path TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('file', 'directory', 'symlink')),
    depth INTEGER NOT NULL,
    parent_path TEXT NOT NULL,
    size INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
}

# Führt tree -a -L {depth} aus und gibt Ausgabe zurück
run_tree() {
    local root_path="$1"
    local max_depth="$2"
    local output
    
    if output=$(timeout 30 tree -a -L "${max_depth}" "${root_path}" 2>/dev/null); then
        echo "$output"
    else
        echo "❌ Fehler bei tree ${root_path}" >&2
        return 1
    fi
}

# Parst tree-Ausgabe und extrahiert Einträge
parse_tree_output() {
    local tree_output="$1"
    local root_path="$2"
    local line
    local name
    local entry_type
    local depth
    
    # Leeren Array initialisieren
    ENTRIES=()
    
    while IFS= read -r line; do
        # Pattern matching für Zeilen wie "├── .bash_history" oder "│   ├── bin"
        if [[ $line =~ ^[│\ ]*[├└]──\ (.+)$ ]]; then
            name="${BASH_REMATCH[1]}"
            
            # Tiefe bestimmen durch Zählen von │ und Leerzeichenblöcken
            depth=$(echo "$line" | grep -o '│' | wc -l)
            local space_blocks
            space_blocks=$(echo "$line" | grep -o '    ' | wc -l)
            depth=$((depth + space_blocks))
            
            # Typ bestimmen
            if [[ $name == */ ]]; then
                entry_type="directory"
                name="${name%/}"
            elif [[ $name == *" -> "* ]]; then
                entry_type="symlink"
                name="${name%% -> *}"
            else
                entry_type="file"
            fi
            
            ENTRIES+=("${name}|${entry_type}|${depth}|${line}")
        fi
    done <<< "$(echo -e "$tree_output")"
}

# Speichert Einträge in tree.db
save_to_db() {
    local root_path="$1"
    local max_depth="$2"
    local total_files=0
    local total_dirs=0
    local total_symlinks=0
    local entry
    local IFS_backup="$IFS"
    
    # Statistiken sammeln
    for entry in "${ENTRIES[@]}"; do
        IFS='|'
        read -ra parts <<< "$entry"
        case "${parts[1]}" in
            file) ((total_files++)) ;;
            directory) ((total_dirs++)) ;;
            symlink) ((total_symlinks++)) ;;
        esac
    done
    IFS="$IFS_backup"
    
    # Scan-Metadaten einfügen
    local scan_id
    scan_id=$(sqlite3 "${DB_PATH}" <<EOF
INSERT INTO tree_scans 
(root_path, max_depth, total_files, total_dirs, total_symlinks)
VALUES ('${root_path}', ${max_depth}, ${total_files}, ${total_dirs}, ${total_symlinks});
SELECT last_insert_rowid();
EOF
)
    
    # Einträge speichern
    local insert_sql=""
    for entry in "${ENTRIES[@]}"; do
        IFS='|'
        read -ra parts <<< "$entry"
        local name="${parts[0]}"
        local type="${parts[1]}"
        local depth="${parts[2]}"
        
        insert_sql+="INSERT INTO tree_entries (root_path, relative_path, name, type, depth, parent_path, size) VALUES ('${root_path}', '${name}', '${name}', '${type}', ${depth}, '${root_path}', 0);\n"
    done
    IFS="$IFS_backup"
    
    if [ -n "$insert_sql" ]; then
        printf "%b" "$insert_sql" | sqlite3 "${DB_PATH}"
    fi
    
    echo "✅ ${#ENTRIES[@]} Einträge gespeichert für ${root_path}"
    echo "$scan_id"
}

# Komplette Indexierung eines Verzeichnisses
index_directory() {
    local root_path="$1"
    local max_depth="$2"
    local tree_output
    
    echo
    echo "--- Indexiere: ${root_path} (Depth: ${max_depth}) ---"
    
    if tree_output=$(run_tree "$root_path" "$max_depth"); then
        parse_tree_output "$tree_output" "$root_path"
        if [ ${#ENTRIES[@]} -gt 0 ]; then
            save_to_db "$root_path" "$max_depth"
            return 0
        fi
    fi
    
    return 1
}

# Exportiert alle Tree-Einträge als CSV
export_csv() {
    local csv_path="${WORKSPACE}/export_tree_all.csv"
    local count
    
    count=$(sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM tree_entries;")
    
    if [ "$count" -eq 0 ]; then
        echo "⚠️ Keine Tree-Daten vorhanden"
        return 1
    fi
    
    sqlite3 -header -csv "${DB_PATH}" "SELECT * FROM tree_entries ORDER BY root_path, depth, name;" > "${csv_path}"
    
    echo "✅ Tree CSV exportiert: ${csv_path} (${count} Einträge)"
    echo "${csv_path}"
}

# Exportiert getrennt nach root_path
export_by_root() {
    local roots
    local root_path
    local safe_name
    local csv_path
    local count
    
    mapfile -t roots < <(sqlite3 "${DB_PATH}" "SELECT DISTINCT root_path FROM tree_entries;")
    
    for root_path in "${roots[@]}"; do
        safe_name="${root_path//\//_}"
        safe_name="${safe_name//./}"
        csv_path="${WORKSPACE}/export_tree${safe_name}.csv"
        
        sqlite3 -header -csv "${DB_PATH}" "SELECT * FROM tree_entries WHERE root_path = '${root_path}' ORDER BY depth, name;" > "${csv_path}"
        
        count=$(sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM tree_entries WHERE root_path = '${root_path}';")
        echo "✅ Export ${root_path}: ${csv_path} (${count} Einträge)"
    done
}

# Hauptfunktion
main() {
    echo "============================================================"
    echo "TREE INDEXER"
    echo "============================================================"
    
    init
    connect_and_setup_db
    
    # 1. /home/openclaw/ mit depth 3
    index_directory "/home/openclaw/" 3 || true
    
    # 2. Workspace mit depth 6
    index_directory "/home/openclaw/.openclaw/workspace/" 6 || true
    
    # Exporte erstellen
    echo
    echo "--- Exporte ---"
    export_csv || true
    export_by_root
    
    echo
    echo "============================================================"
    echo "TREE INDEXIERUNG ABGESCHLOSSEN"
    echo "============================================================"
}

# Skript ausführen
main "$@"
