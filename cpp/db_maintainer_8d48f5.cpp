// abstraction-provenance: {"artifact_sha256": "1d353fbd53a5dccf1bdcfe813f7b086072eccbeaa1f069fef916c4a87984ce6a", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "cpp"}
// db_maintainer.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <filesystem>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <stdexcept>
#include <memory>
#include <cstdio>
#include <openssl/md5.h>

namespace fs = std::filesystem;

/**
 * Database Maintainer Sub-Agent
 * Automated database maintenance with 30min checks, hourly backups (3 days retention),
 * band tree command execution for important/openclaw-tree.txt
 */

// Global constants
const fs::path WORKSPACE = []() {
    const char* env_workspace = std::getenv("OPENCLAW_WORKSPACE");
    if (env_workspace) {
        return fs::path(env_workspace);
    } else {
        return fs::absolute(fs::path(__FILE__)).parent_path().parent_path();
    }
}();

const fs::path DB_DIR = WORKSPACE;
const fs::path BACKUP_DIR = WORKSPACE / "db" / "backups";
const fs::path LOG_DIR = WORKSPACE / "logs" / "db-maintainer";
const fs::path IMPORTANT_DIR = WORKSPACE / "important";

// Create directories
void create_directories() {
    fs::create_directories(BACKUP_DIR);
    fs::create_directories(LOG_DIR);
    fs::create_directories(IMPORTANT_DIR);
}

class Logger {
public:
    /** Einfacher Logger mit Datei-Ausgabe */
    Logger() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::tm tm = *std::localtime(&time_t);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%d");
        log_file = LOG_DIR / (oss.str() + ".log");
    }

    void log(const std::string& level, const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::tm tm = *std::localtime(&time_t);
        std::ostringstream oss;
        oss << "[" << std::put_time(&tm, "%Y-%m-%d %H:%M:%S") << "] [" << level << "] " << message;
        std::string line = oss.str();
        std::cout << line << std::endl;
        std::ofstream f(log_file, std::ios::app);
        f << line << std::endl;
    }

    void info(const std::string& msg) { log("INFO", msg); }
    void warn(const std::string& msg) { log("WARN", msg); }
    void error(const std::string& msg) { log("ERROR", msg); }

private:
    fs::path log_file;
};

class DatabaseMaintainer {
public:
    DatabaseMaintainer() : logger(), state_file(DB_DIR / "maintainer_state.json"), retention_days(3) {}

    void run_cycle() {
        /** Ein kompletter Wartungszyklus */
        logger.info("============================================================");
        logger.info("DB MAINTAINER CYCLE START");
        logger.info("============================================================");

        auto state = load_state();

        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        logger.info("Führe tree -a -L 8 aus...");
        std::string tree_output = run_tree_command();
        if (!tree_output.empty()) {
            update_tree_file(tree_output);
            state["last_tree_update"] = get_current_timestamp();
        }

        // 2. tree.db aktualisieren (intern v2)
        logger.info("Aktualisiere tree.db v2...");
        update_tree_db_v2();

        // 3. Änderungen prüfen
        logger.info("Prüfe auf Dokumentations-Änderungen...");
        std::pair<std::vector<std::string>, std::map<std::string, std::string>> changes_result = check_for_changes();
        std::vector<std::string> changes = changes_result.first;
        std::map<std::string, std::string> current_hashes = changes_result.second;

        if (!changes.empty()) {
            logger.info(std::to_string(changes.size()) + " Änderungen gefunden:");
            int count = 0;
            for (const auto& change : changes) {
                if (count >= 10) {
                    logger.info("  ... und " + std::to_string(changes.size() - 10) + " weitere");
                    break;
                }
                logger.info("  - " + change);
                count++;
            }

            // 4. docs.db aktualisieren
            logger.info("Aktualisiere docs.db...");
            if (update_databases()) {
                state["last_check"] = get_current_timestamp();
                state["file_hashes"] = current_hashes;
            }
        } else {
            logger.info("Keine Dokumentations-Änderungen gefunden");
        }

        // 5. Prüfe ob Backup fällig (stündlich)
        bool do_backup = true;
        if (state.find("last_backup") != state.end() && !state["last_backup"].empty()) {
            auto last_backup_time = parse_timestamp(state["last_backup"]);
            auto now = std::chrono::system_clock::now();
            auto diff = std::chrono::duration_cast<std::chrono::hours>(now - last_backup_time);
            do_backup = diff.count() >= 1;
        }

        if (do_backup) {
            logger.info("Erstelle stündliches Backup...");
            std::string timestamp = create_backup();
            state["last_backup"] = get_current_timestamp();

            // 6. Alte Backups aufräumen (3 Tage Retention)
            logger.info("Räume alte Backups auf (3 Tage Retention)...");
            cleanup_old_backups();
        } else {
            logger.info("Backup nicht nötig (letztes < 1h)");
        }

        save_state(state);

        logger.info("============================================================");
        logger.info("DB MAINTAINER CYCLE END");
        logger.info("============================================================");
    }

private:
    Logger logger;
    fs::path state_file;
    int retention_days;

    std::map<std::string, std::string> load_state() {
        /** Lädt letzten Check-Zustand */
        std::map<std::string, std::string> state;
        if (fs::exists(state_file)) {
            std::ifstream file(state_file);
            std::string line;
            while (std::getline(file, line)) {
                size_t pos = line.find('=');
                if (pos != std::string::npos) {
                    std::string key = line.substr(0, pos);
                    std::string value = line.substr(pos + 1);
                    state[key] = value;
                }
            }
        }
        return state;
    }

    void save_state(const std::map<std::string, std::string>& state) {
        /** Speichert aktuellen Zustand */
        std::ofstream file(state_file);
        for (const auto& pair : state) {
            file << pair.first << "=" << pair.second << std::endl;
        }
    }

    std::string get_file_hash(const fs::path& filepath) {
        /** Berechnet MD5-Hash einer Datei */
        std::ifstream file(filepath, std::ios::binary);
        if (!file) {
            return "";
        }

        MD5_CTX ctx;
        MD5_Init(&ctx);

        char buffer[4096];
        while (file.read(buffer, sizeof(buffer))) {
            MD5_Update(&ctx, buffer, sizeof(buffer));
        }
        MD5_Update(&ctx, buffer, file.gcount());

        unsigned char digest[MD5_DIGEST_LENGTH];
        MD5_Final(digest, &ctx);

        std::ostringstream oss;
        for (int i = 0; i < MD5_DIGEST_LENGTH; ++i) {
            oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(digest[i]);
        }
        return oss.str();
    }

    std::string _python_tree_fallback(int max_depth = 8) {
        /** Reiner Python-Fallback, falls das 'tree'-Binary fehlt (z.B. Sandbox). */
        // This is a simplified version of the tree command
        std::ostringstream oss;
        oss << WORKSPACE.string() << "\n";
        walk_directory(WORKSPACE, "", 1, max_depth, oss);
        return oss.str();
    }

    void walk_directory(const fs::path& dirpath, const std::string& prefix, int depth, int max_depth, std::ostringstream& oss) {
        if (depth > max_depth) {
            return;
        }

        std::vector<fs::path> entries;
        try {
            for (const auto& entry : fs::directory_iterator(dirpath)) {
                entries.push_back(entry.path());
            }
            std::sort(entries.begin(), entries.end(), [](const fs::path& a, const fs::path& b) {
                bool a_is_dir = fs::is_directory(a);
                bool b_is_dir = fs::is_directory(b);
                if (a_is_dir != b_is_dir) {
                    return a_is_dir > b_is_dir;
                }
                return a.filename() < b.filename();
            });
        } catch (...) {
            return;
        }

        for (size_t i = 0; i < entries.size(); ++i) {
            const auto& entry = entries[i];
            std::string connector = (i == entries.size() - 1) ? "└── " : "├── ";
            oss << prefix << connector << entry.filename().string() << "\n";
            if (fs::is_directory(entry) && !fs::is_symlink(entry)) {
                std::string extension = (i == entries.size() - 1) ? "    " : "│   ";
                walk_directory(entry, prefix + extension, depth + 1, max_depth, oss);
            }
        }
    }

    std::string run_tree_command() {
        /** Führt tree -a -L 8 auf workspace aus und gibt Ergebnis zurück */
        FILE* pipe = popen("which tree", "r");
        if (!pipe) {
            logger.warn("tree-Binary nicht installiert – nutze Python-Fallback");
            return _python_tree_fallback();
        }
        char buffer[128];
        if (!fgets(buffer, sizeof(buffer), pipe)) {
            pclose(pipe);
            logger.warn("tree-Binary nicht installiert – nutze Python-Fallback");
            return _python_tree_fallback();
        }
        pclose(pipe);

        std::string cmd = "tree -a -L 8 " + WORKSPACE.string();
        pipe = popen(cmd.c_str(), "r");
        if (!pipe) {
            logger.warn("tree command fehlgeschlagen – nutze Python-Fallback");
            return _python_tree_fallback();
        }

        std::ostringstream oss;
        while (fgets(buffer, sizeof(buffer), pipe)) {
            oss << buffer;
        }
        int status = pclose(pipe);
        if (status == 0) {
            logger.info("tree -a -L 8 erfolgreich ausgeführt");
            return oss.str();
        } else {
            logger.warn("tree command fehlgeschlagen – nutze Python-Fallback");
            return _python_tree_fallback();
        }
    }

    void update_tree_file(const std::string& tree_output) {
        /** Schreibt tree-output in important/openclaw-tree.txt */
        if (tree_output.empty()) {
            return;
        }

        fs::path tree_file = IMPORTANT_DIR / "openclaw-tree.txt";

        // Header mit Timestamp
        std::ostringstream header;
        header << "# OpenClaw Workspace Tree\n";
        header << "# Generiert: " << get_current_timestamp() << "\n";
        header << "# Befehl: tree -a -L 8 " << WORKSPACE.string() << "\n";
        header << "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

        try {
            std::ofstream f(tree_file);
            f << header.str();
            f << tree_output;
            logger.info("openclaw-tree.txt aktualisiert: " + tree_file.string());
        } catch (const std::exception& e) {
            logger.error("Fehler beim Schreiben von openclaw-tree.txt: " + std::string(e.what()));
        }
    }

    std::vector<std::map<std::string, std::string>> scan_documentations() {
        /** Scannt alle .md Dateien auf Änderungen */
        std::vector<std::map<std::string, std::string>> docs;

        for (const auto& entry : fs::recursive_directory_iterator(WORKSPACE)) {
            if (entry.is_regular_file() && entry.path().extension() == ".md") {
                std::string relative_path = fs::relative(entry.path(), WORKSPACE).string();
                if (relative_path.find("db/backups") == std::string::npos &&
                    relative_path.find("node_modules") == std::string::npos) {
                    std::map<std::string, std::string> doc;
                    doc["path"] = relative_path;
                    doc["hash"] = get_file_hash(entry.path());
                    doc["mtime"] = std::to_string(entry.last_write_time().time_since_epoch().count());
                    docs.push_back(doc);
                }
            }
        }

        return docs;
    }

    std::pair<std::vector<std::string>, std::map<std::string, std::string>> check_for_changes() {
        /** Prüft auf Änderungen seit letztem Lauf */
        auto state = load_state();
        auto current_docs = scan_documentations();

        std::vector<std::string> changes;
        std::map<std::string, std::string> current_hashes;

        for (const auto& doc : current_docs) {
            std::string path = doc.at("path");
            std::string hash = doc.at("hash");
            current_hashes[path] = hash;

            if (state.find(path) == state.end()) {
                changes.push_back("NEW: " + path);
            } else if (state[path] != hash) {
                changes.push_back("CHANGED: " + path);
            }
        }

        // Prüfe auf gelöschte Dateien
        for (const auto& pair : state) {
            if (current_hashes.find(pair.first) == current_hashes.end()) {
                changes.push_back("DELETED: " + pair.first);
            }
        }

        return std::make_pair(changes, current_hashes);
    }

    bool update_databases() {
        /** Führt DB-Update-Scripts aus */
        try {
            std::string cmd = "python3 " + (WORKSPACE / "scripts" / "update_docs_db.py").string();
            int result = std::system(cmd.c_str());
            if (result == 0) {
                logger.info("docs.db aktualisiert");
                return true;
            } else {
                logger.error("DB-Update fehlgeschlagen");
                return false;
            }
        } catch (const std::exception& e) {
            logger.error("DB-Update Exception: " + std::string(e.what()));
            return false;
        }
    }

    bool update_tree_db_v2() {
        /** Führt tree_indexer_v2.py aus */
        try {
            std::string cmd = "python3 " + (WORKSPACE / "scripts" / "tree_indexer_v2.py").string();
            int result = std::system(cmd.c_str());
            if (result == 0) {
                logger.info("tree.db v2 aktualisiert");
                return true;
            } else {
                logger.error("Tree-DB v2 fehlgeschlagen");
                return false;
            }
        } catch (const std::exception& e) {
            logger.error("Tree-DB v2 Exception: " + std::string(e.what()));
            return false;
        }
    }

    std::string create_backup() {
        /** Erstellt Backup beider Datenbanken */
        std::string timestamp = get_current_timestamp_formatted();
        timestamp.erase(std::remove(timestamp.begin(), timestamp.end(), ':'), timestamp.end());
        timestamp.erase(std::remove(timestamp.begin(), timestamp.end(), '-'), timestamp.end());
        timestamp.replace(8, 1, "_");

        for (const std::string& db_name : {"docs.db", "tree.db"}) {
            fs::path source = DB_DIR / db_name;
            if (fs::exists(source)) {
                std::string backup_name = timestamp + "_" + db_name + ".bak";
                fs::path backup_path = BACKUP_DIR / backup_name;
                fs::copy_file(source, backup_path, fs::copy_options::overwrite_existing);
                logger.info("Backup erstellt: " + backup_name);
            }
        }

        return timestamp;
    }

    void cleanup_old_backups() {
        /** Löscht Backups älter als 3 Tage */
        auto cutoff = std::chrono::system_clock::now() - std::chrono::hours(24 * retention_days);
        int deleted = 0;

        for (const std::string& db_name : {"docs.db", "tree.db"}) {
            for (const auto& entry : fs::directory_iterator(BACKUP_DIR)) {
                if (entry.is_regular_file() && entry.path().extension() == ".bak") {
                    std::string filename = entry.path().filename().string();
                    if (filename.find(db_name) != std::string::npos) {
                        // Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                        try {
                            std::string date_str = filename.substr(0, 10);
                            std::string time_str = filename.substr(11, 5);
                            std::string datetime_str = date_str + " " + time_str;
                            std::istringstream iss(datetime_str);
                            std::tm tm = {};
                            iss >> std::get_time(&tm, "%Y-%m-%d %H-%M");
                            if (iss.fail()) {
                                logger.warn("Konnte Backup-Datum nicht parsen: " + filename);
                                continue;
                            }
                            auto backup_time = std::chrono::system_clock::from_time_t(std::mktime(&tm));
                            if (backup_time < cutoff) {
                                fs::remove(entry.path());
                                deleted++;
                                logger.info("Altes Backup gelöscht: " + filename);
                            }
                        } catch (...) {
                            logger.warn("Konnte Backup-Datum nicht parsen: " + filename);
                        }
                    }
                }
            }
        }

        if (deleted == 0) {
            logger.info("Keine alten Backups zum Löschen");
        } else {
            logger.info(std::to_string(deleted) + " alte Backups gelöscht (< 3 Tage)");
        }
    }

    std::string get_current_timestamp() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::tm tm = *std::localtime(&time_t);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
        return oss.str();
    }

    std::string get_current_timestamp_formatted() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::tm tm = *std::localtime(&time_t);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%d_%H-%M");
        return oss.str();
    }

    std::chrono::system_clock::time_point parse_timestamp(const std::string& timestamp) {
        std::istringstream iss(timestamp);
        std::tm tm = {};
        iss >> std::get_time(&tm, "%Y-%m-%d %H:%M:%S");
        if (iss.fail()) {
            throw std::runtime_error("Failed to parse timestamp");
        }
        return std::chrono::system_clock::from_time_t(std::mktime(&tm));
    }
};

void main_function() {
    /** Hauptfunktion */
    DatabaseMaintainer maintainer;

    try {
        maintainer.run_cycle();
    } catch (const std::exception& e) {
        maintainer.logger.error("CRITICAL ERROR: " + std::string(e.what()));
        std::exit(1);
    }
}

int main() {
    create_directories();
    main_function();
    return 0;
}
