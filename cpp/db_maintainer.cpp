// abstraction-provenance: {"artifact_sha256": "1c0d9c41d18fab07fdb26940c4a9c4b49fc1ab41dfe3f64e4da5574ef708254a", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "cpp"}
// db_maintainer.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <nlohmann/json.hpp>
#include <openssl/md5.h>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <algorithm>
#include <map>

using json = nlohmann::json;
namespace fs = std::filesystem;
using namespace std::chrono;

const fs::path WORKSPACE = "/home/openclaw/.openclaw/workspace";
const fs::path DB_DIR = WORKSPACE / "db";
const fs::path BACKUP_DIR = DB_DIR / "backups";
const fs::path LOG_DIR = WORKSPACE / "logs" / "db-maintainer";
const fs::path IMPORTANT_DIR = WORKSPACE / "important";

struct DocInfo {
    std::string path;
    std::string hash;
    long mtime;
};

class Logger {
private:
    fs::path log_file;

public:
    Logger() {
        auto now = system_clock::now();
        auto today = duration_cast<days>(now.time_since_epoch());
        auto date = std::chrono::system_clock::to_time_t(std::chrono::system_clock::time_point(today));
        std::ostringstream oss;
        oss << std::put_time(std::localtime(&date), "%Y-%m-%d");
        log_file = LOG_DIR / (oss.str() + ".log");
    }

    void log(const std::string& level, const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = duration_cast<milliseconds>(now.time_since_epoch()) % 1000;
        
        std::ostringstream oss;
        oss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
        oss << "." << std::setfill('0') << std::setw(3) << ms.count();
        
        std::string line = "[" + oss.str() + "] [" + level + "] " + message;
        std::cout << line << std::endl;
        
        std::ofstream file(log_file, std::ios::app);
        if (file.is_open()) {
            file << line << std::endl;
        }
    }

    void info(const std::string& msg) { log("INFO", msg); }
    void warn(const std::string& msg) { log("WARN", msg); }
    void error(const std::string& msg) { log("ERROR", msg); }
};

class DatabaseMaintainer {
private:
    Logger logger;
    fs::path state_file;
    int retention_days = 3;

public:
    DatabaseMaintainer() : state_file(DB_DIR / "maintainer_state.json") {}

    json load_state() {
        if (fs::exists(state_file)) {
            std::ifstream file(state_file);
            if (file.is_open()) {
                json state;
                file >> state;
                return state;
            }
        }
        return {
            {"last_check", nullptr},
            {"last_backup", nullptr},
            {"last_tree_update", nullptr},
            {"file_hashes", json::object()}
        };
    }

    void save_state(const json& state) {
        std::ofstream file(state_file);
        if (file.is_open()) {
            file << state.dump(2);
        }
    }

    std::string get_file_hash(const fs::path& filepath) {
        std::ifstream file(filepath, std::ios::binary);
        if (!file.is_open()) {
            return "";
        }

        MD5_CTX md5_ctx;
        MD5_Init(&md5_ctx);

        char buffer[4096];
        while (file.good()) {
            file.read(buffer, sizeof(buffer));
            MD5_Update(&md5_ctx, buffer, file.gcount());
        }

        unsigned char digest[MD5_DIGEST_LENGTH];
        MD5_Final(digest, &md5_ctx);

        std::ostringstream oss;
        for (int i = 0; i < MD5_DIGEST_LENGTH; ++i) {
            oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(digest[i]);
        }
        return oss.str();
    }

    std::string run_tree_command() {
        try {
            std::string cmd = "tree -a -L 8 " + WORKSPACE.string() + " 2>&1";
            std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
            if (!pipe) {
                logger.error("popen() failed!");
                return "";
            }

            std::string result;
            char buffer[128];
            while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
                result += buffer;
            }

            logger.info("tree -a -L 8 erfolgreich ausgeführt");
            return result;
        } catch (const std::exception& e) {
            logger.error("tree command Exception: " + std::string(e.what()));
            return "";
        }
    }

    bool update_tree_file(const std::string& tree_output) {
        if (tree_output.empty()) {
            return false;
        }

        fs::path tree_file = IMPORTANT_DIR / "openclaw-tree.txt";
        
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        
        std::ostringstream oss;
        oss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
        
        std::string header = "# OpenClaw Workspace Tree\n";
        header += "# Generiert: " + oss.str() + "\n";
        header += "# Befehl: tree -a -L 8 " + WORKSPACE.string() + "\n";
        header += "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

        try {
            std::ofstream file(tree_file);
            if (file.is_open()) {
                file << header << tree_output;
                logger.info("openclaw-tree.txt aktualisiert: " + tree_file.string());
                return true;
            }
        } catch (const std::exception& e) {
            logger.error("Fehler beim Schreiben von openclaw-tree.txt: " + std::string(e.what()));
        }
        return false;
    }

    std::vector<DocInfo> scan_documentations() {
        std::vector<DocInfo> docs;
        
        for (const auto& entry : fs::recursive_directory_iterator(WORKSPACE)) {
            if (entry.is_regular_file() && entry.path().extension() == ".md") {
                std::string path_str = entry.path().string();
                if (path_str.find("db/backups") == std::string::npos && 
                    path_str.find("node_modules") == std::string::npos) {
                    
                    DocInfo doc;
                    doc.path = fs::relative(entry.path(), WORKSPACE).string();
                    doc.hash = get_file_hash(entry.path());
                    doc.mtime = std::chrono::duration_cast<std::chrono::seconds>(
                        entry.last_write_time().time_since_epoch()).count();
                    docs.push_back(doc);
                }
            }
        }
        
        return docs;
    }

    std::pair<std::vector<std::string>, std::map<std::string, std::string>> check_for_changes() {
        json state = load_state();
        std::vector<DocInfo> current_docs = scan_documentations();
        
        std::vector<std::string> changes;
        std::map<std::string, std::string> current_hashes;
        
        for (const auto& doc : current_docs) {
            current_hashes[doc.path] = doc.hash;
            
            if (!state["file_hashes"].contains(doc.path)) {
                changes.push_back("NEW: " + doc.path);
            } else if (state["file_hashes"][doc.path] != doc.hash) {
                changes.push_back("CHANGED: " + doc.path);
            }
        }
        
        // Prüfe auf gelöschte Dateien
        for (const auto& [old_path, _] : state["file_hashes"].items()) {
            if (current_hashes.find(old_path) == current_hashes.end()) {
                changes.push_back("DELETED: " + old_path);
            }
        }
        
        return std::make_pair(changes, current_hashes);
    }

    bool update_databases() {
        try {
            std::string cmd = "python3 " + (WORKSPACE / "scripts" / "update_docs_db.py").string() + " 2>&1";
            std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
            if (!pipe) {
                logger.error("popen() failed!");
                return false;
            }

            std::string result;
            char buffer[128];
            while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
                result += buffer;
            }

            int return_code = pclose(pipe.release());
            if (return_code == 0) {
                logger.info("docs.db aktualisiert");
                return true;
            } else {
                logger.error("DB-Update fehlgeschlagen: " + result);
                return false;
            }
        } catch (const std::exception& e) {
            logger.error("DB-Update Exception: " + std::string(e.what()));
            return false;
        }
    }

    bool update_tree_db_v2() {
        try {
            std::string cmd = "python3 " + (WORKSPACE / "scripts" / "tree_indexer_v2.py").string() + " 2>&1";
            std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
            if (!pipe) {
                logger.error("popen() failed!");
                return false;
            }

            std::string result;
            char buffer[128];
            while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
                result += buffer;
            }

            int return_code = pclose(pipe.release());
            if (return_code == 0) {
                logger.info("tree.db v2 aktualisiert");
                return true;
            } else {
                logger.error("Tree-DB v2 fehlgeschlagen: " + result);
                return false;
            }
        } catch (const std::exception& e) {
            logger.error("Tree-DB v2 Exception: " + std::string(e.what()));
            return false;
        }
    }

    std::string create_backup() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::ostringstream oss;
        oss << std::put_time(std::localtime(&time_t), "%Y-%m-%d_%H-%M");
        std::string timestamp = oss.str();
        
        std::vector<std::string> db_names = {"docs.db", "tree.db"};
        
        for (const auto& db_name : db_names) {
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
        auto now = std::chrono::system_clock::now();
        auto cutoff = now - std::chrono::hours(24 * retention_days);
        int deleted = 0;
        
        std::vector<std::string> db_names = {"docs.db", "tree.db"};
        
        for (const auto& db_name : db_names) {
            for (const auto& entry : fs::directory_iterator(BACKUP_DIR)) {
                if (entry.is_regular_file() && 
                    entry.path().extension() == ".bak" && 
                    entry.path().string().find("_" + db_name + ".bak") != std::string::npos) {
                    
                    std::string filename = entry.path().filename().string();
                    try {
                        std::string date_part = filename.substr(0, 16); // YYYY-MM-DD_HH-MM
                        std::tm tm = {};
                        std::istringstream ss(date_part);
                        ss >> std::get_time(&tm, "%Y-%m-%d_%H-%M");
                        
                        if (ss.fail()) {
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
        
        if (deleted == 0) {
            logger.info("Keine alten Backups zum Löschen");
        } else {
            logger.info(std::to_string(deleted) + " alte Backups gelöscht (< 3 Tage)");
        }
    }

    void run_cycle() {
        logger.info("============================================================");
        logger.info("DB MAINTAINER CYCLE START");
        logger.info("============================================================");
        
        json state = load_state();
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        logger.info("Führe tree -a -L 8 aus...");
        std::string tree_output = run_tree_command();
        if (!tree_output.empty()) {
            update_tree_file(tree_output);
            
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::ostringstream oss;
            oss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
            state["last_tree_update"] = oss.str();
        }
        
        // 2. tree.db aktualisieren (intern v2)
        logger.info("Aktualisiere tree.db v2...");
        update_tree_db_v2();
        
        // 3. Änderungen prüfen
        logger.info("Prüfe auf Dokumentations-Änderungen...");
        auto [changes, current_hashes] = check_for_changes();
        
        if (!changes.empty()) {
            logger.info(std::to_string(changes.size()) + " Änderungen gefunden:");
            int count = 0;
            for (const auto& change : changes) {
                if (count++ < 10) {
                    logger.info("  - " + change);
                } else {
                    break;
                }
            }
            if (changes.size() > 10) {
                logger.info("  ... und " + std::to_string(changes.size()-10) + " weitere");
            }
            
            // 4. docs.db aktualisieren
            logger.info("Aktualisiere docs.db...");
            if (update_databases()) {
                auto now = std::chrono::system_clock::now();
                auto time_t = std::chrono::system_clock::to_time_t(now);
                std::ostringstream oss;
                oss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
                state["last_check"] = oss.str();
                
                state["file_hashes"] = json::object();
                for (const auto& [path, hash] : current_hashes) {
                    state["file_hashes"][path] = hash;
                }
            }
        } else {
            logger.info("Keine Dokumentations-Änderungen gefunden");
        }
        
        // 5. Prüfe ob Backup fällig (stündlich)
        bool do_backup = true;
        if (state.contains("last_backup") && !state["last_backup"].is_null()) {
            std::string last_backup_str = state["last_backup"];
            std::tm tm = {};
            std::istringstream ss(last_backup_str);
            ss >> std::get_time(&tm, "%Y-%m-%dT%H:%M:%S");
            if (!ss.fail()) {
                auto last_backup_time = std::chrono::system_clock::from_time_t(std::mktime(&tm));
                auto now = std::chrono::system_clock::now();
                do_backup = (now - last_backup_time) >= std::chrono::hours(1);
            }
        }
        
        if (do_backup) {
            logger.info("Erstelle stündliches Backup...");
            std::string timestamp = create_backup();
            
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::ostringstream oss;
            oss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
            state["last_backup"] = oss.str();
            
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
};

void main_function() {
    DatabaseMaintainer maintainer;
    
    try {
        maintainer.run_cycle();
    } catch (const std::exception& e) {
        Logger logger;
        logger.error("CRITICAL ERROR: " + std::string(e.what()));
        exit(1);
    }
}

int main() {
    // Verzeichnisse erstellen
    fs::create_directories(BACKUP_DIR);
    fs::create_directories(LOG_DIR);
    
    main_function();
    return 0;
}
