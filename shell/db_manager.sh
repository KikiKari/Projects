#!/usr/bin/env bash
# db_manager.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
# auch in: OpenClaw@gateway1:abstraction-manager/db_manager.py
# auch in: OpenClaw@gateway2:scripts/db_manager.py
# auch in: OpenClaw@gateway2:abstraction-manager/db_manager.py
# auch in: 1 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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

WORKSPACE="${OPENCLAW_WORKSPACE:-/home/openclaw/.openclaw/workspace}"
DB_DIR="$WORKSPACE/db"

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
_DOCS_EXPORT_TABLES=("documents" "categories" "symlinks" "skills")
_TREE_EXPORT_TABLES=("tree_entries" "tree_scans")

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local message="$*"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ${level//-8} | db_manager | $message"
}

log_info() {
    log "INFO     " "$@"
}

log_error() {
    log "ERROR    " "$@"
}

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

validate_table_name() {
    local table="$1"
    local -n allowed_ref="$2"
    for allowed in "${allowed_ref[@]}"; do
        if [[ "$table" == "$allowed" ]]; then
            return 0
        fi
    done
    log_error "Ungültiger Tabellenname: '$table'. Erlaubt: ${allowed_ref[*]}"
    return 1
}

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

docs_db_path="$DB_DIR/docs.db"

init_docs_schema() {
    local sql="
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
    "
    sqlite3 "$docs_db_path" "$sql"
    log_info "docs.db Schema initialisiert: $docs_db_path"
}

populate_docs_from_workspace() {
    local categories_sql="
        INSERT OR IGNORE INTO categories (name, description, priority) VALUES
        ('main', 'Hauptverzeichnis Dateien', 1),
        ('memory', 'Memory und Protokolle', 2),
        ('reports', 'Berichte und Analysen', 3),
        ('cluster', 'Cluster und Infrastruktur', 4),
        ('skills', 'Installierte Skills', 5),
        ('websearch', 'WebSearch Dokumentationen', 6),
        ('mcp', 'MCP Integration', 7),
        ('links', 'Symbolische Links', 8);
    "

    local docs_sql="
        INSERT OR REPLACE INTO documents
        (name, path, category, description, type, has_symlink, symlink_path, last_update)
        VALUES
        ('AGENTS.md', '/', 'main', 'Agent-Konfiguration, Memory-Regeln', 'config', 0, NULL, '2026-04-11'),
        ('SOUL.md', '/', 'main', 'Agent-Persönlichkeit und Kernwahrheiten', 'config', 0, NULL, '2026-04-11'),
        ('IDENTITY.md', '/', 'main', 'Agent-Name und Eigenschaften', 'config', 0, NULL, '2026-04-11'),
        ('USER.md', '/', 'main', 'Benutzerinformationen', 'config', 0, NULL, '2026-04-11'),
        ('TOOLS.md', '/', 'main', 'Tool-spezifische Konfigurationen', 'config', 0, NULL, '2026-04-18'),
        ('MEMORY.md', '/', 'main', 'Langzeitspeicher, System-Konfiguration', 'config', 0, NULL, '2026-04-11'),
        ('DOCUMENTATION-INDEX.md', '/', 'main', 'Übersicht aller Dokumentationen', 'doc', 0, NULL, '2026-04-18'),
        ('WORKSPACE-INDEX.md', '/', 'main', 'Symlink zu DOCUMENTATION-INDEX.md', 'symlink', 1, 'DOCUMENTATION-INDEX.md', '2026-04-18'),
        ('WEBSEARCH_README.md', 'websearch/', 'websearch', 'Schnellstart Guide', 'guide', 1, 'websearch/WEBSEARCH_README.md', '2026-04-18'),
        ('WEBSEARCH_MCP_GUIDE.md', 'websearch/', 'websearch', 'Vollständige technische Dokumentation', 'guide', 1, 'websearch/WEBSEARCH_MCP_GUIDE.md', '2026-04-18'),
        ('WEBSEARCH_CONFIG.md', 'websearch/', 'websearch', 'Konfigurations-Referenz', 'config', 1, 'websearch/WEBSEARCH_CONFIG.md', '2026-04-18'),
        ('WEBSEARCH_PRIORITY_CONFIG.md', 'websearch/', 'websearch', 'Provider-Priorität', 'config', 1, 'websearch/WEBSEARCH_PRIORITY_CONFIG.md', '2026-04-18'),
        ('WEBSEARCH_SCRIPTS.md', 'websearch/', 'websearch', 'Automation & Scripting', 'script', 1, 'websearch/WEBSEARCH_SCRIPTS.md', '2026-04-18'),
        ('WEBSEARCH_OPS.md', 'websearch/', 'websearch', 'IT-Operations', 'guide', 1, 'websearch/WEBSEARCH_OPS.md', '2026-04-18'),
        ('MCP_GUIDE.md', 'mcp/', 'mcp', 'Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md', 'symlink', 0, 'websearch/WEBSEARCH_MCP_GUIDE.md', '2026-04-18');
    "

    local skills_sql="
        INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES
        ('json-utils', '1.0.0', 'installed', 'JSON parsing and validation', 'skills/json-utils/'),
        ('scripting-utils', '1.0.0', 'installed', 'Multi-language scripting support', 'skills/scripting-utils/'),
        ('tiktok-live-mon', '1.0.0', 'installed', 'TikTok stream monitoring', 'skills/tiktok-live-mon/'),
        ('cluster-management', '1.0.0', 'installed', 'Cluster topology management', 'skills/cluster-management/'),
        ('worker-node', '-', 'local', 'Worker node configuration', 'skills/worker-node/'),
        ('resource-manager', '-', 'local', 'Resource management', 'skills/resource-manager/'),
        ('git-publish-agent', '1.0.0', 'local', 'Git publishing automation', 'skills/git-publish-agent/');
    "

    local symlinks_sql="
        INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES
        ('openclaw.env', '/home/openclaw/.config/openclaw/env', '/', 'API-Keys Shortcut'),
        ('openclaw.json', '/home/openclaw/.openclaw/openclaw.json', '/', 'Konfig Shortcut'),
        ('links/config/openclaw-env', '/home/openclaw/.config/openclaw/env', 'links/config/', 'API-Keys'),
        ('links/dotfiles/.tavily', '/home/openclaw/.tavily/', 'links/dotfiles/', 'Tavily Config'),
        ('links/dotfiles/.claude', '/home/openclaw/.claude/', 'links/dotfiles/', 'Claude Config'),
        ('links/dotfiles/.mcporter', '/home/openclaw/.mcporter/', 'links/dotfiles/', 'MCPorter Config'),
        ('links/dotfiles/.ssh', '/home/openclaw/.ssh/', 'links/dotfiles/', 'SSH Keys');
    "

    sqlite3 "$docs_db_path" "$categories_sql$docs_sql$skills_sql$symlinks_sql"
    log_info "docs.db befüllt: 15 Dokumente, 7 Skills, 7 Symlinks"
}

export_docs_csv() {
    local table="$1"
    validate_table_name "$table" _DOCS_EXPORT_TABLES || return 1

    local csv_path="$WORKSPACE/export_${table}.csv"
    local query="SELECT * FROM $table;"
    local header
    header=$(sqlite3 -header -separator ',' "$docs_db_path" ".schema $table" | grep -E '^CREATE TABLE' | sed -E 's/.*\((.*)\).*/\1/' | sed -E 's/"//g' | tr -d ' ' | tr ',' '\n' | head -n -1 | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$header" ]]; then
        header=$(sqlite3 -header -separator ',' "$docs_db_path" "$query" | head -1)
    fi

    local data
    data=$(sqlite3 -header -separator ',' "$docs_db_path" "$query")

    if [[ "$(echo "$data" | wc -l)" -le 1 ]]; then
        log_info "Tabelle '$table' ist leer — kein CSV erzeugt"
        return 0
    fi

    echo "$data" > "$csv_path"
    log_info "CSV exportiert: $csv_path ($(($(wc -l < "$csv_path") - 1)) Zeilen)"
}

export_docs_json() {
    local table="$1"
    validate_table_name "$table" _DOCS_EXPORT_TABLES || return 1

    local json_path="$WORKSPACE/export_${table}.json"
    local query="SELECT * FROM $table;"
    local data
    data=$(sqlite3 -header "$docs_db_path" "$query")

    if [[ "$(echo "$data" | wc -l)" -le 1 ]]; then
        log_info "Tabelle '$table' ist leer — kein JSON erzeugt"
        return 0
    fi

    # Konvertiere CSV-Daten zu JSON (vereinfacht)
    {
        echo "["
        echo "$data" | awk -F'|' '
        NR==1 {
            for(i=1;i<=NF;i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i);
                headers[i] = $i;
            }
            next
        }
        {
            if(NR==2) printf "  {"
            else printf ",\n  {"
            for(i=1;i<=NF;i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i);
                if(i>1) printf ","
                printf "\"%s\":\"%s\"", headers[i], $i
            }
            printf "}"
        }
        END {print "\n]"}' | sed 's/\\"/\\\\"/g'
    } > "$json_path"

    log_info "JSON exportiert: $json_path ($(($(wc -l < "$json_path") - 2)) Einträge)"
}

# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

tree_db_path="$DB_DIR/tree.db"

init_tree_schema() {
    local sql="
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
    "
    sqlite3 "$tree_db_path" "$sql"
    log_info "tree.db Schema initialisiert: $tree_db_path"
}

add_tree_entry() {
    local root_path="$1"
    local relative_path="$2"
    local name="$3"
    local entry_type="$4"
    local depth="$5"
    local parent_path="$6"
    local size="${7:-0}"

    local sql="
        INSERT INTO tree_entries
        (root_path, relative_path, name, type, depth, parent_path, size)
        VALUES ('$root_path', '$relative_path', '$name', '$entry_type', $depth, '$parent_path', $size);
    "
    sqlite3 "$tree_db_path" "$sql"
}

export_tree_csv() {
    local root_path_filter="${1:-}"
    local suffix
    if [[ -n "$root_path_filter" ]]; then
        suffix="_${root_path_filter//\//_}"
    else
        suffix="_all"
    fi
    local csv_path="$WORKSPACE/export_tree${suffix}.csv"
    local query
    if [[ -n "$root_path_filter" ]]; then
        query="SELECT * FROM tree_entries WHERE root_path = '$root_path_filter';"
    else
        query="SELECT * FROM tree_entries;"
    fi

    local data
    data=$(sqlite3 -header -separator ',' "$tree_db_path" "$query")

    if [[ "$(echo "$data" | wc -l)" -le 1 ]]; then
        log_info "Keine Tree-Einträge vorhanden — kein CSV erzeugt"
        return 0
    fi

    echo "$data" > "$csv_path"
    log_info "Tree-CSV exportiert: $csv_path ($(($(wc -l < "$csv_path") - 1)) Einträge)"
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

main() {
    echo "============================================================"
    echo "WORKSPACE DATABASE MANAGER"
    echo "============================================================"

    # DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    if ! mkdir -p "$DB_DIR"; then
        log_error "DB-Verzeichnis konnte nicht erstellt werden: $DB_DIR"
        exit 1
    fi
    log_info "DB-Verzeichnis: $DB_DIR"

    # docs.db aufbauen
    init_docs_schema
    populate_docs_from_workspace

    # Exporte
    echo
    echo "--- Exporte docs.db ---"
    for table in "documents" "skills" "symlinks"; do
        export_docs_csv "$table"
    done
    export_docs_json "documents"

    # tree.db aufbauen (Daten kommen via tree.py)
    echo
    echo "--- tree.db Initialisierung ---"
    init_tree_schema
    log_info "Tree-Daten werden via tree.py Script befüllt"

    echo
    echo "============================================================"
    echo "DATENBANKEN BEREIT"
    echo "============================================================"
    echo
    echo "Datenbanken: $DB_DIR/"
    echo "Exporte:     $WORKSPACE/"
}

main "$@"
