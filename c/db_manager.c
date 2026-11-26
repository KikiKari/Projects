// abstraction-provenance: {"artifact_sha256": "9511ff9c687eeb199bf25a4de515c87dc6abad8256f86627d098b038e6e75c3e", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "c"}
// db_manager.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

#define DEFAULT_WORKSPACE "/home/openclaw/.openclaw/workspace"
#define MAX_PATH 1024

char WORKSPACE[MAX_PATH];
char DB_DIR[MAX_PATH];

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
const char* DOCS_EXPORT_TABLES[] = {"documents", "categories", "symlinks", "skills"};
const int DOCS_EXPORT_TABLES_COUNT = 4;
const char* TREE_EXPORT_TABLES[] = {"tree_entries", "tree_scans"};
const int TREE_EXPORT_TABLES_COUNT = 2;

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

void log_message(const char* level, const char* format, ...) {
    time_t now;
    time(&now);
    char* date = ctime(&now);
    date[strlen(date) - 1] = '\0'; // Entferne das Zeilenumbruchzeichen
    
    printf("%s | %-8s | db_manager | ", date, level);
    
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
    printf("\n");
}

#define LOG_INFO(fmt, ...) log_message("INFO", fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) log_message("ERROR", fmt, ##__VA_ARGS__)

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

int create_directory(const char* path) {
    struct stat st = {0};
    if (stat(path, &st) == -1) {
        return mkdir(path, 0700);
    }
    return 0;
}

int validate_table_name(const char* table, const char** allowed, int count) {
    for (int i = 0; i < count; i++) {
        if (strcmp(table, allowed[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

typedef struct {
    char db_path[MAX_PATH];
} DocsDatabase;

void docs_database_init(DocsDatabase* db) {
    snprintf(db->db_path, sizeof(db->db_path), "%s/docs.db", DB_DIR);
}

int docs_get_connection(DocsDatabase* db, sqlite3** conn) {
    int rc = sqlite3_open(db->db_path, conn);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Kann Datenbank nicht öffnen: %s", sqlite3_errmsg(*conn));
        sqlite3_close(*conn);
        return rc;
    }
    sqlite3_exec(*conn, "PRAGMA foreign_keys = ON;", 0, 0, 0);
    return SQLITE_OK;
}

int docs_init_schema(DocsDatabase* db) {
    sqlite3* conn;
    int rc = docs_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    const char* schema_sql = 
        "CREATE TABLE IF NOT EXISTS documents ("
        "    id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name        TEXT    NOT NULL,"
        "    path        TEXT    NOT NULL,"
        "    category    TEXT,"
        "    description TEXT,"
        "    type        TEXT    CHECK(type IN ('config', 'doc', 'guide', 'script', 'symlink')),"
        "    has_symlink BOOLEAN DEFAULT FALSE,"
        "    symlink_path TEXT,"
        "    last_update TEXT,"
        "    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE TABLE IF NOT EXISTS categories ("
        "    id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name        TEXT    UNIQUE NOT NULL,"
        "    description TEXT,"
        "    priority    INTEGER DEFAULT 0"
        ");"
        "CREATE TABLE IF NOT EXISTS symlinks ("
        "    id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name        TEXT    NOT NULL,"
        "    target      TEXT    NOT NULL,"
        "    source_path TEXT    NOT NULL,"
        "    description TEXT,"
        "    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE TABLE IF NOT EXISTS skills ("
        "    id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name        TEXT    NOT NULL,"
        "    version     TEXT,"
        "    status      TEXT    CHECK(status IN ('installed', 'local', 'published')),"
        "    description TEXT,"
        "    path        TEXT"
        ");";
        
    char* err_msg = 0;
    rc = sqlite3_exec(conn, schema_sql, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        LOG_ERROR("SQL error: %s", err_msg);
        sqlite3_free(err_msg);
    } else {
        LOG_INFO("docs.db Schema initialisiert: %s", db->db_path);
    }
    
    sqlite3_close(conn);
    return rc;
}

int docs_populate_from_workspace(DocsDatabase* db) {
    sqlite3* conn;
    int rc = docs_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    // Kategorien einfügen
    const char* insert_categories_sql = 
        "INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?, ?, ?);";
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(conn, insert_categories_sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Kategorie-Anweisung: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    typedef struct {
        const char* name;
        const char* description;
        int priority;
    } Category;
    
    Category categories[] = {
        {"main", "Hauptverzeichnis Dateien", 1},
        {"memory", "Memory und Protokolle", 2},
        {"reports", "Berichte und Analysen", 3},
        {"cluster", "Cluster und Infrastruktur", 4},
        {"skills", "Installierte Skills", 5},
        {"websearch", "WebSearch Dokumentationen", 6},
        {"mcp", "MCP Integration", 7},
        {"links", "Symbolische Links", 8}
    };
    
    for (int i = 0; i < 8; i++) {
        sqlite3_bind_text(stmt, 1, categories[i].name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, categories[i].description, -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 3, categories[i].priority);
        
        rc = sqlite3_step(stmt);
        if (rc != SQLITE_DONE && rc != SQLITE_CONSTRAINT) {
            LOG_ERROR("Fehler beim Einfügen der Kategorie: %s", sqlite3_errmsg(conn));
        }
        
        sqlite3_reset(stmt);
    }
    
    sqlite3_finalize(stmt);
    
    // Dokumente einfügen
    const char* insert_docs_sql = 
        "INSERT OR REPLACE INTO documents "
        "(name, path, category, description, type, has_symlink, symlink_path, last_update) "
        "VALUES (?,?,?,?,?,?,?,?);";
        
    rc = sqlite3_prepare_v2(conn, insert_docs_sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Dokument-Anweisung: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    typedef struct {
        const char* name;
        const char* path;
        const char* category;
        const char* description;
        const char* type;
        int has_symlink;
        const char* symlink_path;
        const char* last_update;
    } Document;
    
    Document docs[] = {
        {"AGENTS.md", "/", "main", "Agent-Konfiguration, Memory-Regeln", "config", 0, NULL, "2026-04-11"},
        {"SOUL.md", "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config", 0, NULL, "2026-04-11"},
        {"IDENTITY.md", "/", "main", "Agent-Name und Eigenschaften", "config", 0, NULL, "2026-04-11"},
        {"USER.md", "/", "main", "Benutzerinformationen", "config", 0, NULL, "2026-04-11"},
        {"TOOLS.md", "/", "main", "Tool-spezifische Konfigurationen", "config", 0, NULL, "2026-04-18"},
        {"MEMORY.md", "/", "main", "Langzeitspeicher, System-Konfiguration", "config", 0, NULL, "2026-04-11"},
        {"DOCUMENTATION-INDEX.md", "/", "main", "Übersicht aller Dokumentationen", "doc", 0, NULL, "2026-04-18"},
        {"WORKSPACE-INDEX.md", "/", "main", "Symlink zu DOCUMENTATION-INDEX.md", "symlink", 1, "DOCUMENTATION-INDEX.md", "2026-04-18"},
        {"WEBSEARCH_README.md", "websearch/", "websearch", "Schnellstart Guide", "guide", 1, "websearch/WEBSEARCH_README.md", "2026-04-18"},
        {"WEBSEARCH_MCP_GUIDE.md", "websearch/", "websearch", "Vollständige technische Dokumentation", "guide", 1, "websearch/WEBSEARCH_MCP_GUIDE.md", "2026-04-18"},
        {"WEBSEARCH_CONFIG.md", "websearch/", "websearch", "Konfigurations-Referenz", "config", 1, "websearch/WEBSEARCH_CONFIG.md", "2026-04-18"},
        {"WEBSEARCH_PRIORITY_CONFIG.md", "websearch/", "websearch", "Provider-Priorität", "config", 1, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"},
        {"WEBSEARCH_SCRIPTS.md", "websearch/", "websearch", "Automation & Scripting", "script", 1, "websearch/WEBSEARCH_SCRIPTS.md", "2026-04-18"},
        {"WEBSEARCH_OPS.md", "websearch/", "websearch", "IT-Operations", "guide", 1, "websearch/WEBSEARCH_OPS.md", "2026-04-18"},
        {"MCP_GUIDE.md", "mcp/", "mcp", "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md", "symlink", 0, "websearch/WEBSEARCH_MCP_GUIDE.md", "2026-04-18"}
    };
    
    for (int i = 0; i < 15; i++) {
        sqlite3_bind_text(stmt, 1, docs[i].name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, docs[i].path, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, docs[i].category, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 4, docs[i].description, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 5, docs[i].type, -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 6, docs[i].has_symlink);
        sqlite3_bind_text(stmt, 7, docs[i].symlink_path, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 8, docs[i].last_update, -1, SQLITE_STATIC);
        
        rc = sqlite3_step(stmt);
        if (rc != SQLITE_DONE) {
            LOG_ERROR("Fehler beim Einfügen des Dokuments: %s", sqlite3_errmsg(conn));
        }
        
        sqlite3_reset(stmt);
    }
    
    sqlite3_finalize(stmt);
    
    // Skills einfügen
    const char* insert_skills_sql = 
        "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?);";
        
    rc = sqlite3_prepare_v2(conn, insert_skills_sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Skills-Anweisung: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    typedef struct {
        const char* name;
        const char* version;
        const char* status;
        const char* description;
        const char* path;
    } Skill;
    
    Skill skills[] = {
        {"json-utils", "1.0.0", "installed", "JSON parsing and validation", "skills/json-utils/"},
        {"scripting-utils", "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"},
        {"tiktok-live-mon", "1.0.0", "installed", "TikTok stream monitoring", "skills/tiktok-live-mon/"},
        {"cluster-management", "1.0.0", "installed", "Cluster topology management", "skills/cluster-management/"},
        {"worker-node", "-", "local", "Worker node configuration", "skills/worker-node/"},
        {"resource-manager", "-", "local", "Resource management", "skills/resource-manager/"},
        {"git-publish-agent", "1.0.0", "local", "Git publishing automation", "skills/git-publish-agent/"}
    };
    
    for (int i = 0; i < 7; i++) {
        sqlite3_bind_text(stmt, 1, skills[i].name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, skills[i].version, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, skills[i].status, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 4, skills[i].description, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 5, skills[i].path, -1, SQLITE_STATIC);
        
        rc = sqlite3_step(stmt);
        if (rc != SQLITE_DONE) {
            LOG_ERROR("Fehler beim Einfügen des Skills: %s", sqlite3_errmsg(conn));
        }
        
        sqlite3_reset(stmt);
    }
    
    sqlite3_finalize(stmt);
    
    // Symlinks einfügen
    const char* insert_symlinks_sql = 
        "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?);";
        
    rc = sqlite3_prepare_v2(conn, insert_symlinks_sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Symlinks-Anweisung: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    typedef struct {
        const char* name;
        const char* target;
        const char* source_path;
        const char* description;
    } Symlink;
    
    Symlink symlinks[] = {
        {"openclaw.env", "/home/openclaw/.config/openclaw/env", "/", "API-Keys Shortcut"},
        {"openclaw.json", "/home/openclaw/.openclaw/openclaw.json", "/", "Konfig Shortcut"},
        {"links/config/openclaw-env", "/home/openclaw/.config/openclaw/env", "links/config/", "API-Keys"},
        {"links/dotfiles/.tavily", "/home/openclaw/.tavily/", "links/dotfiles/", "Tavily Config"},
        {"links/dotfiles/.claude", "/home/openclaw/.claude/", "links/dotfiles/", "Claude Config"},
        {"links/dotfiles/.mcporter", "/home/openclaw/.mcporter/", "links/dotfiles/", "MCPorter Config"},
        {"links/dotfiles/.ssh", "/home/openclaw/.ssh/", "links/dotfiles/", "SSH Keys"}
    };
    
    for (int i = 0; i < 7; i++) {
        sqlite3_bind_text(stmt, 1, symlinks[i].name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, symlinks[i].target, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, symlinks[i].source_path, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 4, symlinks[i].description, -1, SQLITE_STATIC);
        
        rc = sqlite3_step(stmt);
        if (rc != SQLITE_DONE) {
            LOG_ERROR("Fehler beim Einfügen des Symlinks: %s", sqlite3_errmsg(conn));
        }
        
        sqlite3_reset(stmt);
    }
    
    sqlite3_finalize(stmt);
    
    sqlite3_close(conn);
    
    LOG_INFO("docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks", 15, 7, 7);
    return SQLITE_OK;
}

int docs_export_csv(DocsDatabase* db, const char* table) {
    if (!validate_table_name(table, DOCS_EXPORT_TABLES, DOCS_EXPORT_TABLES_COUNT)) {
        LOG_ERROR("Ungültiger Tabellenname: '%s'", table);
        return SQLITE_ERROR;
    }
    
    sqlite3* conn;
    int rc = docs_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    char query[256];
    snprintf(query, sizeof(query), "SELECT * FROM %s", table);
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(conn, query, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Abfrage: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    // Prüfen ob Ergebnisse vorhanden sind
    rc = sqlite3_step(stmt);
    if (rc == SQLITE_DONE) {
        LOG_INFO("Tabelle '%s' ist leer — kein CSV erzeugt", table);
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_OK;
    }
    
    // Spaltenanzahl bestimmen
    int cols = sqlite3_column_count(stmt);
    
    // CSV-Datei öffnen
    char csv_path[MAX_PATH];
    snprintf(csv_path, sizeof(csv_path), "%s/export_%s.csv", WORKSPACE, table);
    FILE* file = fopen(csv_path, "w");
    if (!file) {
        LOG_ERROR("Kann CSV-Datei nicht öffnen: %s", csv_path);
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_ERROR;
    }
    
    // Header schreiben
    for (int i = 0; i < cols; i++) {
        fprintf(file, "%s%s", sqlite3_column_name(stmt, i), (i < cols - 1) ? "," : "\n");
    }
    
    // Erste Zeile schreiben
    int rows = 0;
    do {
        for (int i = 0; i < cols; i++) {
            const char* text = (const char*)sqlite3_column_text(stmt, i);
            fprintf(file, "%s%s", text ? text : "", (i < cols - 1) ? "," : "\n");
        }
        rows++;
    } while ((rc = sqlite3_step(stmt)) == SQLITE_ROW);
    
    fclose(file);
    sqlite3_finalize(stmt);
    sqlite3_close(conn);
    
    LOG_INFO("CSV exportiert: %s (%d Zeilen)", csv_path, rows);
    return SQLITE_OK;
}

int docs_export_json(DocsDatabase* db, const char* table) {
    if (!validate_table_name(table, DOCS_EXPORT_TABLES, DOCS_EXPORT_TABLES_COUNT)) {
        LOG_ERROR("Ungültiger Tabellenname: '%s'", table);
        return SQLITE_ERROR;
    }
    
    sqlite3* conn;
    int rc = docs_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    char query[256];
    snprintf(query, sizeof(query), "SELECT * FROM %s", table);
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(conn, query, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Abfrage: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    // Prüfen ob Ergebnisse vorhanden sind
    rc = sqlite3_step(stmt);
    if (rc == SQLITE_DONE) {
        LOG_INFO("Tabelle '%s' ist leer — kein JSON erzeugt", table);
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_OK;
    }
    
    // JSON-Datei öffnen
    char json_path[MAX_PATH];
    snprintf(json_path, sizeof(json_path), "%s/export_%s.json", WORKSPACE, table);
    FILE* file = fopen(json_path, "w");
    if (!file) {
        LOG_ERROR("Kann JSON-Datei nicht öffnen: %s", json_path);
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_ERROR;
    }
    
    // JSON-Array beginnen
    fprintf(file, "[\n");
    
    // Daten schreiben
    int first_row = 1;
    int cols = sqlite3_column_count(stmt);
    int entries = 0;
    
    do {
        if (!first_row) {
            fprintf(file, ",\n");
        }
        first_row = 0;
        
        fprintf(file, "  {\n");
        for (int i = 0; i < cols; i++) {
            const char* name = sqlite3_column_name(stmt, i);
            const char* value = (const char*)sqlite3_column_text(stmt, i);
            fprintf(file, "    \"%s\": \"%s\"", name, value ? value : "");
            if (i < cols - 1) {
                fprintf(file, ",\n");
            } else {
                fprintf(file, "\n");
            }
        }
        fprintf(file, "  }");
        entries++;
    } while ((rc = sqlite3_step(stmt)) == SQLITE_ROW);
    
    // JSON-Array beenden
    fprintf(file, "\n]\n");
    
    fclose(file);
    sqlite3_finalize(stmt);
    sqlite3_close(conn);
    
    LOG_INFO("JSON exportiert: %s (%d Einträge)", json_path, entries);
    return SQLITE_OK;
}

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

typedef struct {
    char db_path[MAX_PATH];
} TreeDatabase;

void tree_database_init(TreeDatabase* db) {
    snprintf(db->db_path, sizeof(db->db_path), "%s/tree.db", DB_DIR);
}

int tree_get_connection(TreeDatabase* db, sqlite3** conn) {
    int rc = sqlite3_open(db->db_path, conn);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Kann Datenbank nicht öffnen: %s", sqlite3_errmsg(*conn));
        sqlite3_close(*conn);
        return rc;
    }
    sqlite3_exec(*conn, "PRAGMA foreign_keys = ON;", 0, 0, 0);
    return SQLITE_OK;
}

int tree_init_schema(TreeDatabase* db) {
    sqlite3* conn;
    int rc = tree_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    const char* schema_sql = 
        "CREATE TABLE IF NOT EXISTS tree_entries ("
        "    id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    root_path     TEXT    NOT NULL,"
        "    relative_path TEXT    NOT NULL,"
        "    name          TEXT    NOT NULL,"
        "    type          TEXT    CHECK(type IN ('file', 'directory', 'symlink')),"
        "    depth         INTEGER,"
        "    parent_path   TEXT,"
        "    size          INTEGER,"
        "    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE TABLE IF NOT EXISTS tree_scans ("
        "    id             INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    root_path      TEXT    NOT NULL,"
        "    max_depth      INTEGER,"
        "    total_files    INTEGER,"
        "    total_dirs     INTEGER,"
        "    total_symlinks INTEGER,"
        "    scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ");";
        
    char* err_msg = 0;
    rc = sqlite3_exec(conn, schema_sql, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        LOG_ERROR("SQL error: %s", err_msg);
        sqlite3_free(err_msg);
    } else {
        LOG_INFO("tree.db Schema initialisiert: %s", db->db_path);
    }
    
    sqlite3_close(conn);
    return rc;
}

int tree_add_entry(
    TreeDatabase* db,
    const char* root_path,
    const char* relative_path,
    const char* name,
    const char* entry_type,
    int depth,
    const char* parent_path,
    int size
) {
    sqlite3* conn;
    int rc = tree_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    const char* insert_sql = 
        "INSERT INTO tree_entries "
        "(root_path, relative_path, name, type, depth, parent_path, size) "
        "VALUES (?,?,?,?,?,?,?);";
        
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(conn, insert_sql, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        LOG_ERROR("Fehler beim Vorbereiten der Anweisung: %s", sqlite3_errmsg(conn));
        sqlite3_close(conn);
        return rc;
    }
    
    sqlite3_bind_text(stmt, 1, root_path, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, relative_path, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 3, name, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 4, entry_type, -1, SQLITE_STATIC);
    sqlite3_bind_int(stmt, 5, depth);
    sqlite3_bind_text(stmt, 6, parent_path, -1, SQLITE_STATIC);
    sqlite3_bind_int(stmt, 7, size);
    
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        LOG_ERROR("Fehler beim Einfügen des Eintrags: %s", sqlite3_errmsg(conn));
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(conn);
    return rc == SQLITE_DONE ? SQLITE_OK : SQLITE_ERROR;
}

int tree_export_csv(TreeDatabase* db, const char* root_path_filter) {
    sqlite3* conn;
    int rc = tree_get_connection(db, &conn);
    if (rc != SQLITE_OK) return rc;
    
    sqlite3_stmt* stmt;
    if (root_path_filter != NULL) {
        const char* query = "SELECT * FROM tree_entries WHERE root_path = ?";
        rc = sqlite3_prepare_v2(conn, query, -1, &stmt, 0);
        if (rc != SQLITE_OK) {
            LOG_ERROR("Fehler beim Vorbereiten der Abfrage: %s", sqlite3_errmsg(conn));
            sqlite3_close(conn);
            return rc;
        }
        sqlite3_bind_text(stmt, 1, root_path_filter, -1, SQLITE_STATIC);
    } else {
        const char* query = "SELECT * FROM tree_entries";
        rc = sqlite3_prepare_v2(conn, query, -1, &stmt, 0);
        if (rc != SQLITE_OK) {
            LOG_ERROR("Fehler beim Vorbereiten der Abfrage: %s", sqlite3_errmsg(conn));
            sqlite3_close(conn);
            return rc;
        }
    }
    
    // Prüfen ob Ergebnisse vorhanden sind
    rc = sqlite3_step(stmt);
    if (rc == SQLITE_DONE) {
        LOG_INFO("Keine Tree-Einträge vorhanden — kein CSV erzeugt");
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_OK;
    }
    
    // Spaltenanzahl bestimmen
    int cols = sqlite3_column_count(stmt);
    
    // CSV-Datei öffnen
    char csv_path[MAX_PATH];
    if (root_path_filter != NULL) {
        char safe_filter[MAX_PATH];
        strncpy(safe_filter, root_path_filter, sizeof(safe_filter) - 1);
        safe_filter[sizeof(safe_filter) - 1] = '\0';
        // Ersetze '/' durch '_'
        for (int i = 0; safe_filter[i]; i++) {
            if (safe_filter[i] == '/') {
                safe_filter[i] = '_';
            }
        }
        snprintf(csv_path, sizeof(csv_path), "%s/export_tree_%s.csv", WORKSPACE, safe_filter);
    } else {
        snprintf(csv_path, sizeof(csv_path), "%s/export_tree_all.csv", WORKSPACE);
    }
    
    FILE* file = fopen(csv_path, "w");
    if (!file) {
        LOG_ERROR("Kann CSV-Datei nicht öffnen: %s", csv_path);
        sqlite3_finalize(stmt);
        sqlite3_close(conn);
        return SQLITE_ERROR;
    }
    
    // Header schreiben
    for (int i = 0; i < cols; i++) {
        fprintf(file, "%s%s", sqlite3_column_name(stmt, i), (i < cols - 1) ? "," : "\n");
    }
    
    // Daten schreiben
    int entries = 0;
    do {
        for (int i = 0; i < cols; i++) {
            const char* text = (const char*)sqlite3_column_text(stmt, i);
            fprintf(file, "%s%s", text ? text : "", (i < cols - 1) ? "," : "\n");
        }
        entries++;
    } while ((rc = sqlite3_step(stmt)) == SQLITE_ROW);
    
    fclose(file);
    sqlite3_finalize(stmt);
    sqlite3_close(conn);
    
    LOG_INFO("Tree-CSV exportiert: %s (%d Einträge)", csv_path, entries);
    return SQLITE_OK;
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

int main() {
    printf("============================================================\n");
    printf("WORKSPACE DATABASE MANAGER\n");
    printf("============================================================\n");
    
    // Umgebungsvariable setzen oder Standardwert verwenden
    const char* workspace_env = getenv("OPENCLAW_WORKSPACE");
    if (workspace_env) {
        strncpy(WORKSPACE, workspace_env, sizeof(WORKSPACE) - 1);
        WORKSPACE[sizeof(WORKSPACE) - 1] = '\0';
    } else {
        strncpy(WORKSPACE, DEFAULT_WORKSPACE, sizeof(WORKSPACE) - 1);
        WORKSPACE[sizeof(WORKSPACE) - 1] = '\0';
    }
    
    snprintf(DB_DIR, sizeof(DB_DIR), "%s/db", WORKSPACE);
    
    // DB-Verzeichnis anlegen
    if (create_directory(DB_DIR) != 0) {
        LOG_ERROR("DB-Verzeichnis konnte nicht erstellt werden: %s", DB_DIR);
        return 1;
    }
    LOG_INFO("DB-Verzeichnis: %s", DB_DIR);
    
    // docs.db aufbauen
    DocsDatabase docs_db;
    docs_database_init(&docs_db);
    docs_init_schema(&docs_db);
    docs_populate_from_workspace(&docs_db);
    
    // Exporte
    printf("\n--- Exporte docs.db ---\n");
    docs_export_csv(&docs_db, "documents");
    docs_export_csv(&docs_db, "skills");
    docs_export_csv(&docs_db, "symlinks");
    docs_export_json(&docs_db, "documents");
    
    // tree.db aufbauen (Daten kommen via tree.py)
    printf("\n--- tree.db Initialisierung ---\n");
    TreeDatabase tree_db;
    tree_database_init(&tree_db);
    tree_init_schema(&tree_db);
    LOG_INFO("Tree-Daten werden via tree.py Script befüllt");
    
    printf("\n============================================================\n");
    printf("DATENBANKEN BEREIT\n");
    printf("============================================================\n");
    printf("\nDatenbanken: %s/\n", DB_DIR);
    printf("Exporte:     %s/\n", WORKSPACE);
    
    return 0;
}
