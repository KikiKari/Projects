#!/usr/bin/env bash
# update_docs_db.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Scan documentation files and refresh docs.db for the mounted workspace.

WORKSPACE="${OPENCLAW_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DB_PATH="$WORKSPACE/docs.db"

# Function to find all markdown files
iter_docs() {
    find "$WORKSPACE" -type f -name '*.md' ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/backups/*'
}

# Function to calculate MD5 hash of a file
file_hash() {
    local path="$1"
    md5sum < "$path" | cut -d' ' -f1
}

# Function to count words in a file
word_count() {
    local path="$1"
    if [[ -r "$path" ]]; then
        wc -w < "$path" || echo 0
    else
        echo 0
    fi
}

# Function to build rows for database insertion
build_rows() {
    local indexed
    indexed=$(date +%s.%N)
    
    while IFS= read -r md_file; do
        local rel_path
        rel_path="${md_file#$WORKSPACE/}"
        echo "$rel_path,$(file_hash "$md_file"),$indexed,$(word_count "$md_file")"
    done < <(iter_docs)
}

# Function to ensure database schema exists
ensure_schema() {
    sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS documents (
    path TEXT PRIMARY KEY,
    content_hash TEXT,
    last_indexed REAL,
    word_count INTEGER
);
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT,
    tag TEXT
);
EOF
}

# Function to update database with new data
update_database() {
    ensure_schema
    
    # Clear existing documents
    sqlite3 "$DB_PATH" "DELETE FROM documents;"
    
    # Insert new data
    while IFS=',' read -r path content_hash last_indexed word_count; do
        sqlite3 "$DB_PATH" "INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES ('$path', '$content_hash', $last_indexed, $word_count);"
    done < <(build_rows)
}

# Function to export table to JSON and CSV
export_table() {
    local table="$1"
    local json_path="$WORKSPACE/db_${table}.json"
    local csv_path="$WORKSPACE/db_${table}.csv"
    
    # Export to JSON
    sqlite3 -json "$DB_PATH" "SELECT * FROM $table;" > "$json_path"
    
    # Export to CSV
    sqlite3 -header -csv "$DB_PATH" "SELECT * FROM $table;" > "$csv_path"
}

# Main function
main() {
    printf '%.0s=' {1..60}
    echo
    echo 'DOCS.DB UPDATER'
    printf '%.0s=' {1..60}
    echo
    
    # Count documents
    local doc_count
    doc_count=$(iter_docs | wc -l)
    echo "Gefunden: $doc_count Dokumente"
    
    update_database
    echo "✅ $doc_count Dokumente in docs.db aktualisiert"
    
    export_table documents
    export_table tags
    echo '✅ Exporte aktualisiert'
    
    echo
    printf '%.0s=' {1..60}
    echo
    echo 'DOCS.DB AKTUALISIERT'
    printf '%.0s=' {1..60}
    echo
}

main "$@"
