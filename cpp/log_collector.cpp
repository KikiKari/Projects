// abstraction-provenance: {"artifact_sha256": "b3e6af49408c227ea3581dcc14e5ffb91f2397a2e3df2de4dcc7f5ade43b1043", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "cpp"}
// log_collector.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <memory>
#include <chrono>
#include <filesystem>
#include <sqlite3.h>
#include <cstdlib>
#include <cstdio>
#include <stdexcept>
#include <sstream>
#include <iomanip>
#include <thread>
#include <future>
#include <algorithm>

namespace fs = std::filesystem;

const fs::path WORKSPACE = "/home/openclaw/.openclaw/workspace";
const fs::path DB_PATH = WORKSPACE / "db" / "logs.db";
const fs::path LOG_DIR = WORKSPACE / "logs" / "log-collector";

struct Node {
    std::string node_id;
    std::string vpn_ip;
    std::string tailscale_ip;
    std::string wireguard_ip;
};

struct LogEntry {
    std::string command;
    std::string output;
    std::string timestamp;
};

class Logger {
private:
    fs::path log_file;

    std::string getCurrentTimestamp() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()) % 1000;

        std::stringstream ss;
        ss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
        ss << '.' << std::setfill('0') << std::setw(3) << ms.count();
        return ss.str();
    }

public:
    Logger() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::stringstream date_ss;
        date_ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d");
        
        fs::create_directories(LOG_DIR);
        log_file = LOG_DIR / (date_ss.str() + ".log");
    }

    void log(const std::string& level, const std::string& msg) {
        std::string ts = getCurrentTimestamp();
        std::string line = "[" + ts + "] [" + level + "] " + msg;
        
        std::cout << line << std::endl;
        
        std::ofstream file(log_file, std::ios::app);
        if (file.is_open()) {
            file << line << std::endl;
        }
    }

    void info(const std::string& msg) { log("INFO", msg); }
    void error(const std::string& msg) { log("ERROR", msg); }
};

class LogCollector {
private:
    std::unique_ptr<Logger> logger;
    sqlite3* conn;

    static int callback(void* data, int argc, char** argv, char** azColName) {
        // Dummy callback for SQLite
        return 0;
    }

    void initSchema() {
        char* errMsg = nullptr;
        
        // Check if tables exist
        std::string checkQuery = "SELECT name FROM sqlite_master WHERE type='table'";
        int rc = sqlite3_exec(conn, checkQuery.c_str(), callback, nullptr, &errMsg);
        
        if (rc != SQLITE_OK) {
            logger->error("Failed to check schema: " + std::string(errMsg));
            sqlite3_free(errMsg);
            return;
        }
        
        // For simplicity, we'll assume the schema needs initialization
        fs::path schemaPath = WORKSPACE / "db" / "logs.db.schema.sql";
        if (fs::exists(schemaPath)) {
            std::ifstream schemaFile(schemaPath);
            std::stringstream buffer;
            buffer << schemaFile.rdbuf();
            std::string schemaSql = buffer.str();
            
            rc = sqlite3_exec(conn, schemaSql.c_str(), nullptr, nullptr, &errMsg);
            if (rc != SQLITE_OK) {
                logger->error("Failed to initialize schema: " + std::string(errMsg));
                sqlite3_free(errMsg);
            } else {
                logger->info("Schema initialized successfully");
            }
        }
    }

    bool checkVpn(const std::string& ip) {
        std::string cmd = "ping -c 1 -W 3 " + ip + " >/dev/null 2>&1";
        int result = std::system(cmd.c_str());
        return (result == 0);
    }

    std::string execCommand(const std::string& cmd) {
        std::array<char, 128> buffer;
        std::string result;
        std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
        
        if (!pipe) {
            throw std::runtime_error("popen() failed!");
        }
        
        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            result += buffer.data();
        }
        
        return result;
    }

    void logSshConnection(const std::string& nodeId, const std::string& connType, 
                         bool success, const std::string& error) {
        std::string sql = "INSERT INTO ssh_connections (node_id, connection_type, success, error_message) "
                         "VALUES (?, ?, ?, ?)";
        
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(conn, sql.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, nodeId.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, connType.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 3, success ? 1 : 0);
            sqlite3_bind_text(stmt, 4, error.c_str(), -1, SQLITE_STATIC);
            
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void insertLogs(const std::string& nodeId, const std::vector<LogEntry>& logs) {
        std::string sql = "INSERT INTO logs (node_id, log_type, source, content, severity, "
                         "collected_by, collection_method, retention_until) "
                         "VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', datetime('now', '+30 days'))";
        
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(conn, sql.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            for (const auto& logEntry : logs) {
                std::string source = logEntry.command.substr(0, 50);
                std::string content = logEntry.output.substr(0, 10000);
                
                sqlite3_bind_text(stmt, 1, nodeId.c_str(), -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 2, source.c_str(), -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 3, content.c_str(), -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 4, "node1", -1, SQLITE_STATIC);
                
                sqlite3_step(stmt);
                sqlite3_reset(stmt);
            }
            sqlite3_finalize(stmt);
        }
        
        logger->info(nodeId + ": " + std::to_string(logs.size()) + " Log-Einträge gespeichert");
    }

public:
    LogCollector() : conn(nullptr) {
        logger = std::make_unique<Logger>();
    }

    ~LogCollector() {
        if (conn) {
            sqlite3_close(conn);
        }
    }

    bool connectDb() {
        int rc = sqlite3_open(DB_PATH.c_str(), &conn);
        if (rc) {
            logger->error("Can't open database: " + std::string(sqlite3_errmsg(conn)));
            return false;
        }
        
        initSchema();
        return true;
    }

    std::vector<Node> getNodes() {
        std::vector<Node> nodes;
        std::string query = "SELECT node_id, vpn_ip, tailscale_ip, wireguard_ip FROM nodes";
        
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(conn, query.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                Node node;
                node.node_id = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
                
                const char* vpn_ip = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
                if (vpn_ip) node.vpn_ip = vpn_ip;
                
                const char* tailscale_ip = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
                if (tailscale_ip) node.tailscale_ip = tailscale_ip;
                
                const char* wireguard_ip = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));
                if (wireguard_ip) node.wireguard_ip = wireguard_ip;
                
                nodes.push_back(node);
            }
            sqlite3_finalize(stmt);
        }
        
        return nodes;
    }

    int sshConnectAndCollect(const Node& node) {
        std::string nodeId = node.node_id;
        std::string vpnIp = node.vpn_ip.empty() ? 
                           (node.tailscale_ip.empty() ? node.wireguard_ip : node.tailscale_ip) : 
                           node.vpn_ip;
        
        if (vpnIp.empty()) {
            logger->error(nodeId + ": Keine VPN-IP konfiguriert");
            return -1;
        }
        
        // 1. VPN-Check
        logger->info(nodeId + ": Prüfe VPN " + vpnIp + "...");
        if (!checkVpn(vpnIp)) {
            logger->error(nodeId + ": VPN nicht erreichbar");
            logSshConnection(nodeId, "tailscale", false, "VPN unreachable");
            return -1;
        }
        
        // 2. SSH-Verbindung
        logger->info(nodeId + ": Verbinde via SSH...");
        try {
            std::vector<std::string> logCommands = {
                "journalctl -n 500 --no-pager",
                "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
                "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
            };
            
            std::vector<LogEntry> logsCollected;
            
            for (const auto& cmd : logCommands) {
                std::string sshCmd = "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw@" + 
                                    vpnIp + " '" + cmd + "'";
                
                try {
                    std::string output = execCommand(sshCmd);
                    
                    auto now = std::chrono::system_clock::now();
                    auto time_t = std::chrono::system_clock::to_time_t(now);
                    std::stringstream timestamp;
                    timestamp << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
                    
                    LogEntry entry;
                    entry.command = cmd;
                    entry.output = output;
                    entry.timestamp = timestamp.str();
                    
                    logsCollected.push_back(entry);
                } catch (...) {
                    // Continue with next command
                }
            }
            
            // Erfolg loggen
            logSshConnection(nodeId, "ssh", true, "");
            
            // In DB speichern
            insertLogs(nodeId, logsCollected);
            
            return logsCollected.size();
            
        } catch (const std::exception& e) {
            logger->error(nodeId + ": SSH Fehler: " + std::string(e.what()));
            logSshConnection(nodeId, "ssh", false, e.what());
            return -1;
        }
    }

    int cleanupRetention() {
        std::string sql = "DELETE FROM logs WHERE retention_until < datetime('now')";
        char* errMsg = nullptr;
        
        int rc = sqlite3_exec(conn, sql.c_str(), nullptr, nullptr, &errMsg);
        if (rc != SQLITE_OK) {
            logger->error("Retention cleanup failed: " + std::string(errMsg));
            sqlite3_free(errMsg);
            return 0;
        }
        
        int deleted = sqlite3_changes(conn);
        logger->info("Retention-Cleanup: " + std::to_string(deleted) + " alte Logs gelöscht");
        return deleted;
    }

    void runCollectionCycle() {
        logger->info("============================================================");
        logger->info("LOG COLLECTOR CYCLE START");
        logger->info("============================================================");
        
        if (!connectDb()) {
            return;
        }
        
        // 1. Nodes holen
        auto nodes = getNodes();
        logger->info("Gefunden: " + std::to_string(nodes.size()) + " Nodes");
        
        // 2. Collection-Run starten
        std::string insertSql = "INSERT INTO collection_runs (started_at, nodes_total) "
                               "VALUES (datetime('now'), ?)";
        
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(conn, insertSql.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, nodes.size());
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
        
        int runId = sqlite3_last_insert_rowid(conn);
        
        // 3. Für jeden Node sammeln
        int successCount = 0;
        int failedCount = 0;
        int totalLogs = 0;
        
        for (const auto& node : nodes) {
            if (node.node_id == "node1") {
                // Lokale Logs (Gateway selbst)
                logger->info("node1: Lokale Collection (Gateway)");
                successCount++;
            } else {
                // Remote-Node abfragen
                int result = sshConnectAndCollect(node);
                if (result >= 0) {
                    successCount++;
                    totalLogs += result;
                } else {
                    failedCount++;
                }
            }
        }
        
        // 4. Run abschließen
        std::string updateSql = "UPDATE collection_runs SET "
                               "finished_at = datetime('now'), "
                               "nodes_success = ?, "
                               "nodes_failed = ?, "
                               "logs_collected = ? "
                               "WHERE run_id = ?";
                               
        rc = sqlite3_prepare_v2(conn, updateSql.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, successCount);
            sqlite3_bind_int(stmt, 2, failedCount);
            sqlite3_bind_int(stmt, 3, totalLogs);
            sqlite3_bind_int64(stmt, 4, runId);
            
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
        
        // 5. Retention-Cleanup
        logger->info("Retention-Cleanup (30 Tage)...");
        cleanupRetention();
        
        logger->info("============================================================");
        logger->info("SUMMARY: " + std::to_string(successCount) + " OK, " + 
                    std::to_string(failedCount) + " Failed, " + 
                    std::to_string(totalLogs) + " Logs");
        logger->info("============================================================");
    }
};

void mainFunction() {
    std::cout << "============================================================" << std::endl;
    std::cout << "LOG COLLECTOR" << std::endl;
    std::cout << "============================================================" << std::endl;
    
    try {
        LogCollector collector;
        collector.runCollectionCycle();
    } catch (const std::exception& e) {
        std::cerr << "CRITICAL ERROR: " << e.what() << std::endl;
        exit(1);
    }
}

int main() {
    mainFunction();
    return 0;
}
