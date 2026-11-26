// abstraction-provenance: {"artifact_sha256": "0884eca87e8a8aa9d641b39dfa49130f61bb2c5255dda88a2a6c68ceb671a08c", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "cpp"}
// db_manager.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <memory>
#include <stdexcept>
#include <chrono>
#include <iomanip>
#include <algorithm>
#include <sqlite3.h>

namespace fs = std::filesystem;

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

const fs::path WORKSPACE = []() {
    const char* env = std::getenv("OPENCLAW_WORKSPACE");
    return env ? fs::path(env) : fs::path("/home/openclaw/.openclaw/workspace");
}();
const fs::path DB_DIR = WORKSPACE / "db";

const std::set<std::string> DOCS_EXPORT_TABLES = {"documents", "categories", "symlinks", "skills"};
const std::set<std::string> TREE_EXPORT_TABLES = {"tree_entries", "tree_scans"};

// ---------------------------------------------------------------------------
// Logger (vereinfacht)
// ---------------------------------------------------------------------------

class Logger {
public:
    enum Level { INFO, WARNING, ERROR };
    
    static void log(Level level, const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::cout << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S") 
                  << " | ";
        
        switch(level) {
            case INFO: std::cout << "INFO    "; break;
            case WARNING: std::cout << "WARNING "; break;
            case ERROR: std::cout << "ERROR   "; break;
        }
        
        std::cout << "| db_manager | " << message << std::endl;
    }
};

// ---------------------------------------------------------------------------
// SQLite Helper
// ---------------------------------------------------------------------------

class SQLiteConnection {
private:
    sqlite3* db_;
    
public:
    SQLiteConnection(const fs::path& db_path) : db_(nullptr) {
        int rc = sqlite3_open(db_path.string().c_str(), &db_);
        if (rc) {
            throw std::runtime_error("Can't open database: " + std::string(sqlite3_errmsg(db_)));
        }
        sqlite3_exec(db_, "PRAGMA foreign_keys = ON;", nullptr, nullptr, nullptr);
    }
    
    ~SQLiteConnection() {
        if (db_) {
            sqlite3_close(db_);
        }
    }
    
    sqlite3* get() { return db_; }
    
    void execute(const std::string& sql) {
        char* errMsg = nullptr;
        int rc = sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &errMsg);
        if (rc != SQLITE_OK) {
            std::string error = "SQL error: " + std::string(errMsg);
            sqlite3_free(errMsg);
            throw std::runtime_error(error);
        }
    }
    
    sqlite3_stmt* prepare(const std::string& sql) {
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr);
        if (rc != SQLITE_OK) {
            throw std::runtime_error("Failed to prepare statement: " + std::string(sqlite3_errmsg(db_)));
        }
        return stmt;
    }
};

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

class DocsDatabase {
private:
    fs::path db_path_;

public:
    DocsDatabase() : db_path_(DB_DIR / "docs.db") {}

    DocsDatabase& init_schema() {
        SQLiteConnection conn(db_path_);
        
        conn.execute(R"(
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
            )
        )");
        
        conn.execute(R"(
            CREATE TABLE IF NOT EXISTS categories (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    UNIQUE NOT NULL,
                description TEXT,
                priority    INTEGER DEFAULT 0
            )
        )");
        
        conn.execute(R"(
            CREATE TABLE IF NOT EXISTS symlinks (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                target      TEXT    NOT NULL,
                source_path TEXT    NOT NULL,
                description TEXT,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        )");
        
        conn.execute(R"(
            CREATE TABLE IF NOT EXISTS skills (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                version     TEXT,
                status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                description TEXT,
                path        TEXT
            )
        )");
        
        Logger::log(Logger::INFO, "docs.db Schema initialisiert: " + db_path_.string());
        return *this;
    }

    DocsDatabase& populate_from_workspace() {
        std::vector<std::tuple<std::string, std::string, int>> categories = {
            {"main",      "Hauptverzeichnis Dateien",        1},
            {"memory",    "Memory und Protokolle",           2},
            {"reports",   "Berichte und Analysen",           3},
            {"cluster",   "Cluster und Infrastruktur",       4},
            {"skills",    "Installierte Skills",             5},
            {"websearch", "WebSearch Dokumentationen",       6},
            {"mcp",       "MCP Integration",                 7},
            {"links",     "Symbolische Links",               8},
        };

        std::vector<std::tuple<std::string, std::string, std::string, std::string, std::string, bool, std::string, std::string>> docs = {
            {"AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  false, "",                          "2026-04-11"},
            {"SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  false, "",                          "2026-04-11"},
            {"IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  false, "",                          "2026-04-11"},
            {"USER.md",               "/", "main", "Benutzerinformationen",                   "config",  false, "",                          "2026-04-11"},
            {"TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  false, "",                          "2026-04-18"},
            {"MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  false, "",                          "2026-04-11"},
            {"DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     false, "",                          "2026-04-18"},
            {"WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", true,  "DOCUMENTATION-INDEX.md",      "2026-04-18"},
            {"WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  true, "websearch/WEBSEARCH_README.md",          "2026-04-18"},
            {"WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  true, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18"},
            {"WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", true, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18"},
            {"WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"},
            {"WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", true, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18"},
            {"WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  true, "websearch/WEBSEARCH_OPS.md",             "2026-04-18"},
            {"MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",false,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18"},
        };

        std::vector<std::tuple<std::string, std::string, std::string, std::string, std::string>> skills = {
            {"json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"},
            {"scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"},
            {"tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"},
            {"cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"},
            {"worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"},
            {"resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"},
            {"git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"},
        };

        std::vector<std::tuple<std::string, std::string, std::string, std::string>> symlinks = {
            {"openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"},
            {"openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"},
            {"links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"},
            {"links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"},
            {"links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"},
            {"links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"},
            {"links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"},
        };

        SQLiteConnection conn(db_path_);
        
        sqlite3_stmt* stmt;
        
        // Insert categories
        stmt = conn.prepare("INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)");
        for (const auto& cat : categories) {
            sqlite3_bind_text(stmt, 1, std::get<0>(cat).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, std::get<1>(cat).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 3, std::get<2>(cat));
            sqlite3_step(stmt);
            sqlite3_reset(stmt);
        }
        sqlite3_finalize(stmt);
        
        // Insert documents
        stmt = conn.prepare("INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES (?,?,?,?,?,?,?,?)");
        for (const auto& doc : docs) {
            sqlite3_bind_text(stmt, 1, std::get<0>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, std::get<1>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 3, std::get<2>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 4, std::get<3>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 5, std::get<4>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 6, std::get<5>(doc) ? 1 : 0);
            sqlite3_bind_text(stmt, 7, std::get<6>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 8, std::get<7>(doc).c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
            sqlite3_reset(stmt);
        }
        sqlite3_finalize(stmt);
        
        // Insert skills
        stmt = conn.prepare("INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)");
        for (const auto& skill : skills) {
            sqlite3_bind_text(stmt, 1, std::get<0>(skill).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, std::get<1>(skill).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 3, std::get<2>(skill).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 4, std::get<3>(skill).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 5, std::get<4>(skill).c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
            sqlite3_reset(stmt);
        }
        sqlite3_finalize(stmt);
        
        // Insert symlinks
        stmt = conn.prepare("INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)");
        for (const auto& link : symlinks) {
            sqlite3_bind_text(stmt, 1, std::get<0>(link).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, std::get<1>(link).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 3, std::get<2>(link).c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 4, std::get<3>(link).c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
            sqlite3_reset(stmt);
        }
        sqlite3_finalize(stmt);
        
        Logger::log(Logger::INFO, "docs.db befüllt: " + std::to_string(docs.size()) + " Dokumente, " + 
                                   std::to_string(skills.size()) + " Skills, " + std::to_string(symlinks.size()) + " Symlinks");
        return *this;
    }

    void validate_table_name(const std::string& table, const std::set<std::string>& allowed) {
        if (allowed.find(table) == allowed.end()) {
            std::string allowed_str;
            for (const auto& t : allowed) {
                if (!allowed_str.empty()) allowed_str += ", ";
                allowed_str += "'" + t + "'";
            }
            throw std::invalid_argument("Ungültiger Tabellenname: '" + table + "'. Erlaubt: [" + allowed_str + "]");
        }
    }

    std::optional<fs::path> export_csv(const std::string& table) {
        validate_table_name(table, DOCS_EXPORT_TABLES);
        
        SQLiteConnection conn(db_path_);
        sqlite3_stmt* stmt = conn.prepare("SELECT * FROM " + table);
        
        std::vector<std::vector<std::string>> rows;
        std::vector<std::string> column_names;
        
        int cols = sqlite3_column_count(stmt);
        for (int i = 0; i < cols; i++) {
            column_names.push_back(sqlite3_column_name(stmt, i));
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::vector<std::string> row;
            for (int i = 0; i < cols; i++) {
                const char* text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, i));
                row.push_back(text ? text : "");
            }
            rows.push_back(row);
        }
        sqlite3_finalize(stmt);
        
        if (rows.empty()) {
            Logger::log(Logger::INFO, "Tabelle '" + table + "' ist leer — kein CSV erzeugt");
            return std::nullopt;
        }
        
        fs::path csv_path = WORKSPACE / ("export_" + table + ".csv");
        std::ofstream file(csv_path);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot open file for writing: " + csv_path.string());
        }
        
        for (size_t i = 0; i < column_names.size(); ++i) {
            if (i > 0) file << ",";
            file << "\"" << column_names[i] << "\"";
        }
        file << "\n";
        
        for (const auto& row : rows) {
            for (size_t i = 0; i < row.size(); ++i) {
                if (i > 0) file << ",";
                file << "\"" << row[i] << "\"";
            }
            file << "\n";
        }
        
        Logger::log(Logger::INFO, "CSV exportiert: " + csv_path.string() + " (" + std::to_string(rows.size()) + " Zeilen)");
        return csv_path;
    }

    std::optional<fs::path> export_json(const std::string& table) {
        validate_table_name(table, DOCS_EXPORT_TABLES);
        
        SQLiteConnection conn(db_path_);
        sqlite3_stmt* stmt = conn.prepare("SELECT * FROM " + table);
        
        std::vector<std::map<std::string, std::string>> data;
        std::vector<std::string> column_names;
        
        int cols = sqlite3_column_count(stmt);
        for (int i = 0; i < cols; i++) {
            column_names.push_back(sqlite3_column_name(stmt, i));
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::map<std::string, std::string> row;
            for (int i = 0; i < cols; i++) {
                const char* text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, i));
                row[column_names[i]] = text ? text : "";
            }
            data.push_back(row);
        }
        sqlite3_finalize(stmt);
        
        if (data.empty()) {
            Logger::log(Logger::INFO, "Tabelle '" + table + "' ist leer — kein JSON erzeugt");
            return std::nullopt;
        }
        
        fs::path json_path = WORKSPACE / ("export_" + table + ".json");
        std::ofstream file(json_path);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot open file for writing: " + json_path.string());
        }
        
        file << "[\n";
        for (size_t i = 0; i < data.size(); ++i) {
            file << "  {\n";
            size_t j = 0;
            for (const auto& pair : data[i]) {
                file << "    \"" << pair.first << "\": \"" << pair.second << "\"";
                if (++j < data[i].size()) file << ",";
                file << "\n";
            }
            file << "  }";
            if (i + 1 < data.size()) file << ",";
            file << "\n";
        }
        file << "]\n";
        
        Logger::log(Logger::INFO, "JSON exportiert: " + json_path.string() + " (" + std::to_string(data.size()) + " Einträge)");
        return json_path;
    }
};

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

class TreeDatabase {
private:
    fs::path db_path_;

public:
    TreeDatabase() : db_path_(DB_DIR / "tree.db") {}

    TreeDatabase& init_schema() {
        SQLiteConnection conn(db_path_);
        
        conn.execute(R"(
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
            )
        )");
        
        conn.execute(R"(
            CREATE TABLE IF NOT EXISTS tree_scans (
                id             INTEGER PRIMARY KEY AUTOINCREMENT,
                root_path      TEXT    NOT NULL,
                max_depth      INTEGER,
                total_files    INTEGER,
                total_dirs     INTEGER,
                total_symlinks INTEGER,
                scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        )");
        
        Logger::log(Logger::INFO, "tree.db Schema initialisiert: " + db_path_.string());
        return *this;
    }

    void add_entry(
        const std::string& root_path,
        const std::string& relative_path,
        const std::string& name,
        const std::string& entry_type,
        int depth,
        const std::string& parent_path,
        int size = 0
    ) {
        SQLiteConnection conn(db_path_);
        sqlite3_stmt* stmt = conn.prepare(R"(
            INSERT INTO tree_entries
            (root_path, relative_path, name, type, depth, parent_path, size)
            VALUES (?,?,?,?,?,?,?)
        )");
        
        sqlite3_bind_text(stmt, 1, root_path.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, relative_path.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, name.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 4, entry_type.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 5, depth);
        sqlite3_bind_text(stmt, 6, parent_path.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 7, size);
        
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    std::optional<fs::path> export_csv(const std::optional<std::string>& root_path_filter = std::nullopt) {
        SQLiteConnection conn(db_path_);
        sqlite3_stmt* stmt;
        
        std::vector<std::vector<std::string>> rows;
        std::vector<std::string> column_names;
        
        if (root_path_filter.has_value()) {
            stmt = conn.prepare("SELECT * FROM tree_entries WHERE root_path = ?");
            sqlite3_bind_text(stmt, 1, root_path_filter->c_str(), -1, SQLITE_STATIC);
        } else {
            stmt = conn.prepare("SELECT * FROM tree_entries");
        }
        
        int cols = sqlite3_column_count(stmt);
        for (int i = 0; i < cols; i++) {
            column_names.push_back(sqlite3_column_name(stmt, i));
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::vector<std::string> row;
            for (int i = 0; i < cols; i++) {
                const char* text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, i));
                row.push_back(text ? text : "");
            }
            rows.push_back(row);
        }
        sqlite3_finalize(stmt);
        
        if (rows.empty()) {
            Logger::log(Logger::INFO, "Keine Tree-Einträge vorhanden — kein CSV erzeugt");
            return std::nullopt;
        }
        
        std::string suffix = root_path_filter ? "_" + root_path_filter.value() : "_all";
        std::replace(suffix.begin(), suffix.end(), '/', '_');
        fs::path csv_path = WORKSPACE / ("export_tree" + suffix + ".csv");
        std::ofstream file(csv_path);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot open file for writing: " + csv_path.string());
        }
        
        for (size_t i = 0; i < column_names.size(); ++i) {
            if (i > 0) file << ",";
            file << "\"" << column_names[i] << "\"";
        }
        file << "\n";
        
        for (const auto& row : rows) {
            for (size_t i = 0; i < row.size(); ++i) {
                if (i > 0) file << ",";
                file << "\"" << row[i] << "\"";
            }
            file << "\n";
        }
        
        Logger::log(Logger::INFO, "Tree-CSV exportiert: " + csv_path.string() + " (" + std::to_string(rows.size()) + " Einträge)");
        return csv_path;
    }
};

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

void main_function() {
    std::cout << "============================================================\n";
    std::cout << "WORKSPACE DATABASE MANAGER\n";
    std::cout << "============================================================\n";

    try {
        fs::create_directories(DB_DIR);
        Logger::log(Logger::INFO, "DB-Verzeichnis: " + DB_DIR.string());
    } catch (const std::exception& e) {
        Logger::log(Logger::ERROR, "DB-Verzeichnis konnte nicht erstellt werden: " + std::string(e.what()));
        exit(1);
    }

    // docs.db aufbauen
    DocsDatabase docs_db;
    docs_db.init_schema();
    docs_db.populate_from_workspace();

    // Exporte
    std::cout << "\n--- Exporte docs.db ---\n";
    for (const auto& table : {"documents", "skills", "symlinks"}) {
        docs_db.export_csv(table);
    }
    docs_db.export_json("documents");

    // tree.db aufbauen (Daten kommen via tree.py)
    std::cout << "\n--- tree.db Initialisierung ---\n";
    TreeDatabase tree_db;
    tree_db.init_schema();
    Logger::log(Logger::INFO, "Tree-Daten werden via tree.py Script befüllt");

    std::cout << "\n============================================================\n";
    std::cout << "DATENBANKEN BEREIT\n";
    std::cout << "============================================================\n";
    std::cout << "\nDatenbanken: " << DB_DIR << "/\n";
    std::cout << "Exporte:     " << WORKSPACE << "/\n";
}

int main() {
    main_function();
    return 0;
}
