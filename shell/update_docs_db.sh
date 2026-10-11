#!/usr/bin/env bash
# update_docs_db.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Scan documentation files and refresh docs.db for the mounted workspace.

WORKSPACE="/workspace"
DB_PATH="$WORKSPACE/db/docs.db"

# Ensure db directory exists
mkdir -p "$(dirname "$DB_PATH")"

iter_docs() {
    find "$WORKSPACE" -type f -name '*.md' ! -lname '*' \
        -not -path '*/node_modules/*' \
        -not -path '*/.git/*' \
        -not -path '*/backups/*'
}

file_hash() {
    local path="$1"
    md5sum < "$path" | cut -d' ' -f1
}

word_count() {
    local path="$1"
    if [[ -r "$path" ]]; then
        wc -w < "$path" | tr -d ' '
    else
        echo 0
    fi
}

build_rows() {
    local indexed
    indexed=$(date +%s.%N)
    while IFS= read -r md_file; do
        local rel_path
        rel_path="${md_file#$WORKSPACE/}"
        echo "$rel_path|$(file_hash "$md_file")|$indexed|$(word_count "$md_file")"
    done < <(iter_docs)
}

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

update_database() {
    local temp_sql
    temp_sql=$(mktemp)
    cat > "$temp_sql" <<EOF
DELETE FROM documents;
EOF

    while IFS='|' read -r path content_hash last_indexed word_count; do
        echo "INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES ('$path', '$content_hash', $last_indexed, $word_count);" >> "$temp_sql"
    done < <(build_rows)

    sqlite3 "$DB_PATH" < "$temp_sql"
    rm -f "$temp_sql"
}

export_table() {
    local table="$1"
    local json_path="$WORKSPACE/db_${table}.json"
    local csv_path="$WORKSPACE/db_${table}.csv"

    # Export to JSON
    sqlite3 -json "$DB_PATH" "SELECT * FROM $table;" > "$json_path"

    # Export to CSV
    sqlite3 -header -csv "$DB_PATH" "SELECT * FROM $table;" > "$csv_path"
}

main() {
    printf '%.0s=' $(seq 1 60); echo
    echo 'DOCS.DB UPDATER'
    printf '%.0s=' $(seq 1 60); echo

    ensure_schema
    local rows
    rows=$(build_rows)
    local count
    count=$(echo "$rows" | wc -l)
    if [[ "$count" -eq 1 && -z "${rows//[$'\n']/}" ]]; then
        count=0
    fi
    echo "Gefunden: $count Dokumente"
    echo "$rows" | update_database
    echo "✅ $count Dokumente in docs.db aktualisiert"
    export_table "documents"
    export_table "tags"
    echo '✅ Exporte aktualisiert'
    echo
    printf '%.0s=' $(seq 1 60); echo
    echo 'DOCS.DB AKTUALISIERT'
    printf '%.0s=' $(seq 1 60); echo
}

main "$@"
