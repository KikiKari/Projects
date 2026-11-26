// abstraction-provenance: {"artifact_sha256": "aa96a88fa117e913d1b8dcf0e335270584fe7eaa28919ea0b9c5812d41b5fde0", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "cpp"}
// node_health.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <chrono>
#include <ctime>
#include <iomanip>
#include <cstdlib>
#include <thread>
#include <stdexcept>
#include <memory>
#include <algorithm>

// Konfiguration
const std::string WORKSPACE = "/home/openclaw/.openclaw/workspace";
const std::string HEALTH_DB = WORKSPACE + "/db/health.db";
const std::string LOG_FILE = WORKSPACE + "/logs/node-health.log";

// Node-Konfiguration
struct NodeConfig {
    std::string name;
    std::string host;
    std::string user;
    std::string ssh_key;
    bool critical = false;
    bool optional = false;
    int disk_warning = 85;
};

std::map<std::string, NodeConfig> NODES = {
    {"node1", {"Gateway", "localhost", "openclaw", "", true, false, 85}},
    {"node2", {"Worker", "100.92.155.34", "root", "~/.ssh/id_rsa", false, false, 85}},
    {"node3", {"Relay", "185.242.xxx.xxx", "root", "", false, false, 85}},
    {"node5", {"Redmi", "192.168.1.x", "openclaw", "", false, true, 85}}
};

class Logger {
public:
    static void log(const std::string& message, const std::string& level = "INFO") {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        auto local_time = *std::localtime(&time_t);
        
        std::ostringstream timestamp;
        timestamp << std::put_time(&local_time, "%Y-%m-%d %H:%M:%S");
        
        std::string entry = "[" + timestamp.str() + "] [" + level + "] " + message;
        std::cout << entry << std::endl;
        
        // Log-Datei erstellen
        std::filesystem::create_directories(std::filesystem::path(LOG_FILE).parent_path());
        std::ofstream file(LOG_FILE, std::ios::app);
        if (file.is_open()) {
            file << entry << std::endl;
            file.close();
        }
    }
};

class ProcessExecutor {
public:
    static std::pair<int, std::string> execute(const std::vector<std::string>& cmd, int timeout_seconds = 0) {
        std::string command_str;
        for (size_t i = 0; i < cmd.size(); ++i) {
            if (i > 0) command_str += " ";
            command_str += cmd[i];
        }
        
        FILE* pipe = popen(command_str.c_str(), "r");
        if (!pipe) return {-1, ""};
        
        std::string result;
        char buffer[128];
        while (fgets(buffer, sizeof buffer, pipe) != nullptr) {
            result += buffer;
        }
        
        int return_code = pclose(pipe);
        return {return_code, result};
    }
    
    static std::pair<int, std::string> execute_shell(const std::string& cmd, int timeout_seconds = 15) {
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) return {-1, ""};
        
        std::string result;
        char buffer[128];
        while (fgets(buffer, sizeof buffer, pipe) != nullptr) {
            result += buffer;
        }
        
        int return_code = pclose(pipe);
        return {return_code, result};
    }
};

bool check_ping(const std::string& host, int timeout = 5) {
    std::vector<std::string> cmd = {"ping", "-c", "1", "-W", std::to_string(timeout), host};
    auto result = ProcessExecutor::execute(cmd);
    return result.first == 0;
}

bool check_ssh(const NodeConfig& node_config) {
    std::string host = node_config.host;
    std::string user = node_config.user.empty() ? "root" : node_config.user;
    
    std::vector<std::string> cmd = {
        "ssh", "-o", "ConnectTimeout=10", "-o", "BatchMode=yes",
        user + "@" + host, "echo \"OK\""
    };
    
    auto result = ProcessExecutor::execute(cmd);
    return result.first == 0 && result.second.find("OK") != std::string::npos;
}

struct NodeMetrics {
    std::string timestamp;
    bool available = false;
    double cpu = 0.0;
    double ram = 0.0;
    int disk = 0;
    double load = 0.0;
    std::string gateway_status;
};

NodeMetrics get_node_metrics(const NodeConfig& node_config) {
    NodeMetrics metrics;
    
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto local_time = *std::localtime(&time_t);
    
    std::ostringstream timestamp_stream;
    timestamp_stream << std::put_time(&local_time, "%Y-%m-%dT%H:%M:%S");
    metrics.timestamp = timestamp_stream.str();
    
    std::string host = node_config.host;
    std::string user = node_config.user.empty() ? "root" : node_config.user;
    
    std::string cmd = "ssh -o ConnectTimeout=10 " + user + "@" + host + " '"
        "# CPU\n"
        "echo \"CPU:$(top -bn1 | grep \\\"Cpu(s)\\\" | awk \\\"{print \\\\\\$2}\\\" | cut -d\\\"%\\\" -f1)\"\n"
        "\n"
        "# RAM\n"
        "echo \"RAM:$(free | grep Mem | awk \\\"{print (\\\\\$3/\\\\\$2) * 100.0}\\\")\"\n"
        "\n"
        "# Disk\n"
        "echo \"DISK:$(df -h / | tail -1 | awk \\\"{print \\\\\\$5}\\\" | tr -d \\\"%\\\")\"\n"
        "\n"
        "# Load\n"
        "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\"\\\")\"\n"
        "\n"
        "# Gateway Status\n"
        "if command -v openclaw >/dev/null 2>&1; then\n"
        "    systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"\n"
        "fi\n"
        "'";
    
    try {
        auto result = ProcessExecutor::execute_shell(cmd, 15);
        
        if (result.first == 0) {
            metrics.available = true;
            
            std::istringstream iss(result.second);
            std::string line;
            while (std::getline(iss, line)) {
                size_t colon_pos = line.find(':');
                if (colon_pos != std::string::npos) {
                    std::string key = line.substr(0, colon_pos);
                    std::string value = line.substr(colon_pos + 1);
                    
                    if (key == "CPU" && !value.empty()) {
                        try {
                            metrics.cpu = std::stod(value);
                        } catch (...) {}
                    } else if (key == "RAM" && !value.empty()) {
                        try {
                            metrics.ram = std::stod(value);
                        } catch (...) {}
                    } else if (key == "DISK" && !value.empty()) {
                        try {
                            metrics.disk = std::stoi(value);
                        } catch (...) {}
                    } else if (key == "LOAD" && !value.empty()) {
                        try {
                            metrics.load = std::stod(value);
                        } catch (...) {}
                    } else if (key == "GATEWAY") {
                        metrics.gateway_status = value;
                    }
                }
            }
        }
    } catch (const std::exception& e) {
        Logger::log("Error checking " + node_config.name + ": " + e.what(), "ERROR");
    }
    
    return metrics;
}

struct Alert {
    std::string level;
    std::string message;
};

std::vector<Alert> check_alerts(const std::string& node_id, const NodeConfig& node_config, const NodeMetrics& metrics) {
    std::vector<Alert> alerts;
    
    // Verfügbarkeit
    if (!metrics.available) {
        if (!node_config.optional) {
            alerts.push_back({"CRITICAL", "Node " + node_config.name + " nicht erreichbar!"});
        }
    } else {
        // CPU
        if (metrics.cpu > 90) {
            alerts.push_back({"WARNING", "Node " + node_config.name + ": CPU bei " + std::to_string(metrics.cpu) + "%"});
        }
        
        // RAM
        if (metrics.ram > 90) {
            alerts.push_back({"WARNING", "Node " + node_config.name + ": RAM bei " + std::to_string(metrics.ram) + "%"});
        }
        
        // Disk
        int disk_threshold = node_config.disk_warning;
        if (metrics.disk > disk_threshold) {
            std::string level = metrics.disk > 95 ? "CRITICAL" : "WARNING";
            alerts.push_back({level, "Node " + node_config.name + ": Disk bei " + std::to_string(metrics.disk) + "%"});
        }
        
        // Gateway
        if (node_config.critical && metrics.gateway_status == "inactive") {
            alerts.push_back({"CRITICAL", "Node " + node_config.name + ": OpenClaw Gateway nicht aktiv!"});
        }
    }
    
    return alerts;
}

void send_alert(const Alert& alert) {
    try {
        std::string script_path = WORKSPACE + "/skills/channel-status-agent/scripts/channel_status.py";
        std::string cmd = "python3 " + script_path + " --type alert --message \"" + alert.level + ": " + alert.message + "\"";
        
        auto result = ProcessExecutor::execute_shell(cmd);
        Logger::log("Alert sent: " + alert.message);
    } catch (const std::exception& e) {
        Logger::log("Failed to send alert: " + std::string(e.what()), "ERROR");
    }
}

int main(int argc, char* argv[]) {
    std::string node_arg = "all";
    std::string check_arg = "all";
    bool alert_flag = false;
    
    // Einfache Argumentverarbeitung
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--node" && i + 1 < argc) {
            node_arg = argv[++i];
        } else if (arg == "--check" && i + 1 < argc) {
            check_arg = argv[++i];
        } else if (arg == "--alert") {
            alert_flag = true;
        }
    }
    
    // Nodes bestimmen
    std::vector<std::pair<std::string, NodeConfig>> nodes_to_check;
    
    if (node_arg == "all") {
        for (const auto& pair : NODES) {
            nodes_to_check.push_back(pair);
        }
    } else {
        auto it = NODES.find(node_arg);
        if (it != NODES.end()) {
            nodes_to_check.push_back(*it);
        } else {
            Logger::log("Unknown node: " + node_arg, "ERROR");
            return 1;
        }
    }
    
    // Health-Checks durchführen
    std::vector<Alert> all_alerts;
    
    for (const auto& node_pair : nodes_to_check) {
        const std::string& node_id = node_pair.first;
        const NodeConfig& node_config = node_pair.second;
        
        Logger::log("Checking " + node_config.name + " (" + node_id + ")");
        
        // Ping
        if (check_arg == "ping" || check_arg == "all") {
            if (node_config.host != "localhost") {
                bool ping_ok = check_ping(node_config.host);
                Logger::log("  Ping: " + std::string(ping_ok ? "OK" : "FAILED"));
            }
        }
        
        // SSH
        if (check_arg == "ssh" || check_arg == "all") {
            bool ssh_ok = check_ssh(node_config);
            Logger::log("  SSH: " + std::string(ssh_ok ? "OK" : "FAILED"));
        }
        
        // Metriken
        if (check_arg == "metrics" || check_arg == "all") {
            NodeMetrics metrics = get_node_metrics(node_config);
            
            if (metrics.available) {
                if (metrics.cpu > 0) {
                    Logger::log("  CPU: " + std::to_string(metrics.cpu) + "%");
                } else {
                    Logger::log("  CPU: N/A");
                }
                
                if (metrics.ram > 0) {
                    Logger::log("  RAM: " + std::to_string(metrics.ram) + "%");
                } else {
                    Logger::log("  RAM: N/A");
                }
                
                if (metrics.disk > 0) {
                    Logger::log("  Disk: " + std::to_string(metrics.disk) + "%");
                } else {
                    Logger::log("  Disk: N/A");
                }
                
                if (metrics.load > 0) {
                    Logger::log("  Load: " + std::to_string(metrics.load));
                } else {
                    Logger::log("  Load: N/A");
                }
            } else {
                Logger::log("  Metrics: UNAVAILABLE");
            }
            
            // Alerts prüfen
            std::vector<Alert> alerts = check_alerts(node_id, node_config, metrics);
            all_alerts.insert(all_alerts.end(), alerts.begin(), alerts.end());
        }
    }
    
    // Alerts senden
    if (alert_flag && !all_alerts.empty()) {
        Logger::log("\nSending " + std::to_string(all_alerts.size()) + " alerts...");
        for (const auto& alert : all_alerts) {
            send_alert(alert);
        }
    } else if (!all_alerts.empty()) {
        Logger::log("\n" + std::to_string(all_alerts.size()) + " alerts found (use --alert to send)");
    } else {
        Logger::log("\nAll nodes healthy!");
    }
    
    return 0;
}
