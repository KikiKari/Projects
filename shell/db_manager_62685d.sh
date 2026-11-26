#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "156ed953489f6f8824fc9d39d3342c395fc70a2cdbecbbc9fdb61e54cac11cf6", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "shell"}
# db_manager.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
# auch in: OpenClaw@gateway2:scripts/db_manager.py
# auch in: Projects@abstractions:abstractions/db_manager.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Workspace Documentation Database Manager
#
# Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
# Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
#
# Verwendung:
#     ./db_manager.sh
#
# Konfiguration:
#     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

: "${OPENCLAW_WORKSPACE:=/home/openclaw/.openclaw/workspace}"
readonly DB_DIR="$OPENCLAW_WORKSPACE/db"

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
readonly DOCS_EXPORT_TABLES=("documents" "categories" "symlinks" "skills")
readonly TREE_EXPORT_TABLES=("tree_entries" "tree_scans")

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO     | db_manager | $*"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ERROR    | db_manager | $*" >&2
}

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

validate_table_name() {
    local table="$1"
    local -n allowed_array="$2"
    
    for allowed_table in "${allowed_array[@]}"; do
        if [[ "$table" == "$allowed_table" ]]; then
            return 0
        fi
    done
    
    log_error "Ungültiger Tabellenname: '$table'. Erlaubt: ${allowed_array[*]}"
    return 1
}

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

docs_db_path="$DB_DIR/docs.db"

docs_init_schema() {
    sqlite3 "$docs_db_path" <<'EOF'
CREATE TABLE IF NOT EXISTS documents (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    path        TEXT    NOT NULL,
    category    TEXT,
    description TEXT,
    type        TEXT    CHECK(type IN ('config', 'doc', 'guide', 'script', 'symlink')),
    has_symlink BOOLEAN DEFAULT FALSE,
    symlink_path TEXT,
    last_update TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    UNIQUE NOT NULL,
    description TEXT,
    priority    INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS symlinks (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    target      TEXT    NOT NULL,
    source_path TEXT    NOT NULL,
    description TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS skills (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    version     TEXT,
    status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
    description TEXT,
    path        TEXT
);
EOF
    log_info "docs.db Schema initialisiert: $docs_db_path"
}

docs_populate_from_workspace() {
    local categories_sql=""
    local docs_sql=""
    local skills_sql=""
    local symlinks_sql=""
    
    # Kategorien
    categories_sql+=$(cat <<'EOF'
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('main', 'Hauptverzeichnis Dateien', 1);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('memory', 'Memory und Protokolle', 2);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('reports', 'Berichte und Analysen', 3);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('cluster', 'Cluster und Infrastruktur', 4);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('skills', 'Installierte Skills', 5);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('websearch', 'WebSearch Dokumentationen', 6);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('mcp', 'MCP Integration', 7);
INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('links', 'Symbolische Links', 8);
EOF
)
    
    # Dokumente
    docs_sql+=$(cat <<'EOF'
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('AGENTS.md', '/', 'main', 'Agent-Konfiguration, Memory-Regeln', 'config', 0, NULL, '2026-04-11');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('SOUL.md', '/', 'main', 'Agent-Persönlichkeit und Kernwahrheiten', 'config', 0, NULL, '2026-04-11');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('IDENTITY.md', '/', 'main', 'Agent-Name und Eigenschaften', 'config', 0, NULL, '2026-04-11');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('USER.md', '/', 'main', 'Benutzerinformationen', 'config', 0, NULL, '2026-04-11');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('TOOLS.md', '/', 'main', 'Tool-spezifische Konfigurationen', 'config', 0, NULL, '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('MEMORY.md', '/', 'main', 'Langzeitspeicher, System-Konfiguration', 'config', 0, NULL, '2026-04-11');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('DOCUMENTATION-INDEX.md', '/', 'main', 'Übersicht aller Dokumentationen', 'doc', 0, NULL, '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WORKSPACE-INDEX.md', '/', 'main', 'Symlink zu DOCUMENTATION-INDEX.md', 'symlink', 1, 'DOCUMENTATION-INDEX.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_README.md', 'websearch/', 'websearch', 'Schnellstart Guide', 'guide', 1, 'websearch/WEBSEARCH_README.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_MCP_GUIDE.md', 'websearch/', 'websearch', 'Vollständige technische Dokumentation', 'guide', 1, 'websearch/WEBSEARCH_MCP_GUIDE.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_CONFIG.md', 'websearch/', 'websearch', 'Konfigurations-Referenz', 'config', 1, 'websearch/WEBSEARCH_CONFIG.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_PRIORITY_CONFIG.md', 'websearch/', 'websearch', 'Provider-Priorität', 'config', 1, 'websearch/WEBSEARCH_PRIORITY_CONFIG.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_SCRIPTS.md', 'websearch/', 'websearch', 'Automation & Scripting', 'script', 1, 'websearch/WEBSEARCH_SCRIPTS.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('WEBSEARCH_OPS.md', 'websearch/', 'websearch', 'IT-Operations', 'guide', 1, 'websearch/WEBSEARCH_OPS.md', '2026-04-18');
INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('MCP_GUIDE.md', 'mcp/', 'mcp', 'Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md', 'symlink', 0, 'websearch/WEBSEARCH_MCP_GUIDE.md', '2026-04-18');
EOF
)
    
    # Skills
    skills_sql+=$(cat <<'EOF'
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('json-utils', '1.0.0', 'installed', 'JSON parsing and validation', 'skills/json-utils/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('scripting-utils', '1.0.0', 'installed', 'Multi-language scripting support', 'skills/scripting-utils/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('tiktok-live-mon', '1.0.0', 'installed', 'TikTok stream monitoring', 'skills/tiktok-live-mon/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('cluster-management', '1.0.0', 'installed', 'Cluster topology management', 'skills/cluster-management/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('worker-node', '-', 'local', 'Worker node configuration', 'skills/worker-node/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('resource-manager', '-', 'local', 'Resource management', 'skills/resource-manager/');
INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('git-publish-agent', '1.0.0', 'local', 'Git publishing automation', 'skills/git-publish-agent/');
EOF
)
    
    # Symlinks
    symlinks_sql+=$(cat <<'EOF'
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('openclaw.env', '/home/openclaw/.config/openclaw/env', '/', 'API-Keys Shortcut');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('openclaw.json', '/home/openclaw/.openclaw/openclaw.json', '/', 'Konfig Shortcut');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('links/config/openclaw-env', '/home/openclaw/.config/openclaw/env', 'links/config/', 'API-Keys');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('links/dotfiles/.tavily', '/home/openclaw/.tavily/', 'links/dotfiles/', 'Tavily Config');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('links/dotfiles/.claude', '/home/openclaw/.claude/', 'links/dotfiles/', 'Claude Config');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('links/dotfiles/.mcporter', '/home/openclaw/.mcporter/', 'links/dotfiles/', 'MCPorter Config');
INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('links/dotfiles/.ssh', '/home/openclaw/.ssh/', 'links/dotfiles/', 'SSH Keys');
EOF
)
    
    sqlite3 "$docs_db_path" <<<"${categories_sql}${docs_sql}${skills_sql}${symlinks_sql}"
    
    log_info "docs.db befüllt: 15 Dokumente, 7 Skills, 7 Symlinks"
}

docs_export_csv() {
    local table="$1"
    validate_table_name "$table" DOCS_EXPORT_TABLES || return 1
    
    local query="SELECT * FROM ${table}"
    local csv_path="$OPENCLAW_WORKSPACE/export_${table}.csv"
    
    # Header extrahieren
    local header
    header=$(sqlite3 -header -separator ',' "$docs_db_path" ".schema $table" | grep -E "^CREATE TABLE" | sed -E 's/.*\((.*)\).*/\1/' | tr -d '[:space:]' | tr ',' '\n' | cut -d' ' -f1 | paste -sd ',')
    
    # Daten abrufen
    local data
    data=$(sqlite3 -header -separator ',' "$docs_db_path" "$query")
    
    if [[ -z "$data" ]]; then
        log_info "Tabelle '$table' ist leer — kein CSV erzeugt"
        return 0
    fi
    
    # Header und Daten in CSV-Datei schreiben
    {
        echo "$header"
        echo "$data" | tail -n +2
    } > "$csv_path"
    
    local row_count
    row_count=$(wc -l < "$csv_path")
    log_info "CSV exportiert: $csv_path ($((row_count - 1)) Zeilen)"
}

docs_export_json() {
    local table="$1"
    validate_table_name "$table" DOCS_EXPORT_TABLES || return 1
    
    local json_path="$OPENCLAW_WORKSPACE/export_${table}.json"
    
    # SQLite-Abfrage mit JSON-Formatierung
    sqlite3 "$docs_db_path" <<EOF > "$json_path"
.headers on
.mode json
.output $json_path
SELECT * FROM ${table};
EOF
    
    if [[ ! -s "$json_path" ]]; then
        log_info "Tabelle '$table' ist leer — kein JSON erzeugt"
        rm -f "$json_path"
        return 0
    fi
    
    local entry_count
    entry_count=$(jq length "$json_path" 2>/dev/null || echo "0")
    log_info "JSON exportiert: $json_path ($entry_count Einträge)"
}

# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

tree_db_path="$DB_DIR/tree.db"

tree_init_schema() {
    sqlite3 "$tree_db_path" <<'EOF'
CREATE TABLE IF NOT EXISTS tree_entries (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    root_path     TEXT    NOT NULL,
    relative_path TEXT    NOT NULL,
    name          TEXT    NOT NULL,
    type          TEXT    CHECK(type IN ('file', 'directory', 'symlink')),
    depth         INTEGER,
    parent_path   TEXT,
    size          INTEGER,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tree_scans (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    root_path      TEXT    NOT NULL,
    max_depth      INTEGER,
    total_files    INTEGER,
    total_dirs     INTEGER,
    total_symlinks INTEGER,
    scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
    log_info "tree.db Schema initialisiert: $tree_db_path"
}

tree_add_entry() {
    local root_path="$1"
    local relative_path="$2"
    local name="$3"
    local entry_type="$4"
    local depth="$5"
    local parent_path="$6"
    local size="${7:-0}"
    
    sqlite3 "$tree_db_path" <<EOF
INSERT INTO tree_entries (root_path, relative_path, name, type, depth, parent_path, size) VALUES ('$root_path', '$relative_path', '$name', '$entry_type', $depth, '$parent_path', $size);
EOF
}

tree_export_csv() {
    local root_path_filter="${1:-}"
    local suffix=""
    local query=""
    local csv_path=""
    
    if [[ -n "$root_path_filter" ]]; then
        suffix="_${root_path_filter//\//_}"
        query="SELECT * FROM tree_entries WHERE root_path = '$root_path_filter'"
    else
        suffix="_all"
        query="SELECT * FROM tree_entries"
    fi
    
    csv_path="$OPENCLAW_WORKSPACE/export_tree${suffix}.csv"
    
    # Header extrahieren
    local header
    header=$(sqlite3 -header -separator ',' "$tree_db_path" ".schema tree_entries" | grep -E "^CREATE TABLE" | sed -E 's/.*\((.*)\).*/\1/' | tr -d '[:space:]' | tr ',' '\n' | cut -d' ' -f1 | paste -sd ',')
    
    # Daten abrufen
    local data
    data=$(sqlite3 -header -separator ',' "$tree_db_path" "$query")
    
    if [[ -z "$data" ]]; then
        log_info "Keine Tree-Einträge vorhanden — kein CSV erzeugt"
        return 0
    fi
    
    # Header und Daten in CSV-Datei schreiben
    {
        echo "$header"
        echo "$data" | tail -n +2
    } > "$csv_path"
    
    local row_count
    row_count=$(wc -l < "$csv_path")
    log_info "Tree-CSV exportiert: $csv_path ($((row_count - 1)) Einträge)"
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

main() {
    echo "============================================================"
    echo "WORKSPACE DATABASE MANAGER"
    echo "============================================================"
    
    # DB-Verzeichnis anlegen
    if ! mkdir -p "$DB_DIR"; then
        log_error "DB-Verzeichnis konnte nicht erstellt werden: $DB_DIR"
        exit 1
    fi
    log_info "DB-Verzeichnis: $DB_DIR"
    
    # docs.db aufbauen
    docs_init_schema
    docs_populate_from_workspace
    
    # Exporte
    echo
    echo "--- Exporte docs.db ---"
    docs_export_csv "documents"
    docs_export_csv "skills"
    docs_export_csv "symlinks"
    docs_export_json "documents"
    
    # tree.db aufbauen (Daten kommen via tree.py)
    echo
    echo "--- tree.db Initialisierung ---"
    tree_init_schema
    log_info "Tree-Daten werden via tree.py Script befüllt"
    
    echo
    echo "============================================================"
    echo "DATENBANKEN BEREIT"
    echo "============================================================"
    echo
    echo "Datenbanken: $DB_DIR/"
    echo "Exporte:     $OPENCLAW_WORKSPACE/"
}

main "$@"
