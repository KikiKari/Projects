#!/bin/bash
# update_docs_db.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Arbeitsverzeichnis
WORKSPACE="/home/openclaw/.openclaw/workspace"
DB_PATH="$WORKSPACE/db/docs.db"

# Temporäre Datei für SQL-Befehle
SQL_TEMP=$(mktemp)

# Funktion zum Extrahieren der Beschreibung aus einer Markdown-Datei
get_description() {
    local file="$1"
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null || echo "Dokumentation")
    
    # Entferne führende #
    if [[ $first_line == \#* ]]; then
        first_line="${first_line#\#}"
        first_line="${first_line#"${first_line%%[![:space:]]*}"}"  # Trim leading whitespace
    fi
    
    # Kürze auf 50 Zeichen
    if [ ${#first_line} -gt 50 ]; then
        echo "${first_line:0:50}..."
    else
        echo "$first_line"
    fi
}

# Funktion zum Holen des Änderungsdatums
get_mtime() {
    local file="$1"
    if stat -c %y "$file" >/dev/null 2>&1; then
        stat -c %y "$file" | cut -d' ' -f1
    else
        echo "2026-04-18"
    fi
}

# Funktion zum Erstellen der Datenbank-Tabelle (falls nicht existent)
init_db() {
    sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS documents (
    name TEXT,
    path TEXT,
    category TEXT,
    description TEXT,
    type TEXT,
    has_symlink INTEGER,
    symlink_path TEXT,
    last_update TEXT
);
EOF
}

# Scannt alle .md Dateien im Workspace
scan_documentations() {
    local docs=()
    
    # Hauptverzeichnis
    while IFS= read -r -d '' file; do
        if [[ ! -L "$file" ]]; then
            local name basename desc mtime
            basename=$(basename "$file")
            desc=$(get_description "$file")
            mtime=$(get_mtime "$file")
            
            docs+=("$basename|/|main|$desc|doc|0||$mtime")
        fi
    done < <(find "$WORKSPACE" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)
    
    # WebSearch Verzeichnis
    if [[ -d "$WORKSPACE/websearch" ]]; then
        while IFS= read -r -d '' file; do
            local name basename desc mtime type
            basename=$(basename "$file")
            desc=$(get_description "$file")
            mtime=$(get_mtime "$file")
            if [[ $basename == *"GUIDE"* ]]; then
                type="guide"
            else
                type="config"
            fi
            
            docs+=("$basename|websearch/|websearch|$desc|$type|1|websearch/$basename|$mtime")
        done < <(find "$WORKSPACE/websearch" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    # MCP Verzeichnis
    if [[ -d "$WORKSPACE/mcp" ]]; then
        while IFS= read -r -d '' file; do
            local name basename desc mtime type has_symlink symlink_path
            basename=$(basename "$file")
            desc=$(get_description "$file")
            mtime=$(get_mtime "$file")
            
            if [[ -L "$file" ]]; then
                type="symlink"
                has_symlink=1
                symlink_path=$(readlink "$file")
            else
                type="guide"
                has_symlink=0
                symlink_path=""
            fi
            
            docs+=("$basename|mcp/|mcp|$desc|$type|$has_symlink|$symlink_path|$mtime")
        done < <(find "$WORKSPACE/mcp" -maxdepth 1 -name "*.md" -type f,l -print0 2>/dev/null || true)
    fi
    
    # Docs-Unterverzeichnisse
    if [[ -d "$WORKSPACE/docs" ]]; then
        while IFS= read -r dir; do
            if [[ -d "$dir" ]]; then
                local subdir_name
                subdir_name=$(basename "$dir")
                
                while IFS= read -r -d '' file; do
                    local name basename desc mtime
                    basename=$(basename "$file")
                    desc=$(get_description "$file")
                    mtime=$(get_mtime "$file")
                    
                    docs+=("$basename|docs/$subdir_name/|$subdir_name|$desc|doc|0||$mtime")
                done < <(find "$dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)
            fi
        done < <(find "$WORKSPACE/docs" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    fi
    
    # Cluster, Memory, Reports, Skills
    for category in cluster memory reports skills; do
        if [[ -d "$WORKSPACE/$category" ]]; then
            while IFS= read -r -d '' file; do
                local name basename desc mtime
                basename=$(basename "$file")
                desc=$(get_description "$file")
                mtime=$(get_mtime "$file")
                
                docs+=("$basename|$category/|$category|$desc|doc|0||$mtime")
            done < <(find "$WORKSPACE/$category" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)
        fi
    done
    
    printf '%s\n' "${docs[@]}"
}

# Aktualisiert docs.db mit allen gefundenen Dokumenten
update_database() {
    local docs_data="$1"
    local count=0
    
    # Lösche alte Einträge (außer config)
    echo "DELETE FROM documents WHERE category != 'config';" > "$SQL_TEMP"
    
    # Füge neue ein
    while IFS='|' read -r name path category description type has_symlink symlink_path last_update; do
        # Maskiere einfache Anführungszeichen
        description=${description//\'\'}
        symlink_path=${symlink_path//\'\'}
        
        echo "INSERT INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('$name', '$path', '$category', '$description', '$type', $has_symlink, '$symlink_path', '$last_update');" >> "$SQL_TEMP"
        ((count++))
    done <<< "$docs_data"
    
    sqlite3 "$DB_PATH" < "$SQL_TEMP"
    rm -f "$SQL_TEMP"
    
    echo "$count"
}

# Erstellt alle Exporte
export_all() {
    local tables=("documents" "skills" "symlinks")
    
    for table in "${tables[@]}"; do
        # JSON Export
        local json_path="$WORKSPACE/db_${table}.json"
        sqlite3 -json "$DB_PATH" "SELECT * FROM $table;" > "$json_path"
        echo "✅ $json_path"
        
        # CSV Export
        local csv_path="$WORKSPACE/db_${table}.csv"
        sqlite3 -header -csv "$DB_PATH" "SELECT * FROM $table;" > "$csv_path"
        echo "✅ $csv_path"
    done
}

main() {
    echo "============================================================"
    echo "DOCS.DB UPDATER"
    echo "============================================================"
    
    echo ""
    echo "--- Scanne Dokumentationen ---"
    local docs
    docs=$(scan_documentations)
    local doc_count
    doc_count=$(echo "$docs" | grep -c . || echo "0")
    echo "Gefunden: $doc_count Dokumente"
    
    echo ""
    echo "--- Aktualisiere docs.db ---"
    init_db
    local inserted
    inserted=$(update_database "$docs")
    echo "✅ $inserted Dokumente in docs.db aktualisiert"
    
    echo ""
    echo "--- Erstelle Exporte ---"
    export_all
    
    echo ""
    echo "============================================================"
    echo "DOCS.DB AKTUALISIERT"
    echo "============================================================"
}

main "$@"
