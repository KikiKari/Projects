// abstraction-provenance: {"artifact_sha256": "f248d358cf6731d8baca1bbef7c371db32c573cb47043fd87ece9406a9f3b6ff", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "cpp"}
// node_health.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <sstream>
#include <chrono>
#include <filesystem>
#include <thread>
#include <cstdlib>
#include <memory>
#include <stdexcept>
#include <algorithm>
#include <iomanip>
#include <cmath>

// Konfiguration
const std::string WORKSPACE = "/home/openclaw/.openclaw/workspace";
const std::string HEALTH_DB = WORKSPACE + "/db/health.db";
const std::string LOG_FILE = WORKSPACE + "/logs/node-health.log";

// Node-Konfiguration
struct NodeConfig {
    std::string name;
    std::string host;
    std::string user = "root";
    std::string ssh_key;
    std::string ssh_opts;
    int port = 0;
    bool critical = false;
    bool optional = false;
    int disk_warning = 85;
};

std::map<std::string, NodeConfig> NODES = {
    {"node1", {"Node 1", "localhost", "openclaw", "", "", 0, true, false, 85}},
    {"node2", {"Node 2", "10.10.0.2", "root", "~/.ssh/id_rsa", "-o ConnectTimeout=10 -o BatchMode=yes", 0, false, false, 85}},
    {"node3", {"Node 3", "localhost", "root", "", "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes", 18794, false, false, 85}},
    {"node5", {"Redmi", "192.168.1.x", "openclaw", "", "", 0, false, true, 85}}
};

struct Metrics {
    std::string timestamp;
    bool available = false;
    double cpu = 0.0;
    double ram = 0.0;
    int disk = 0;
    double load = 0.0;
    std::string gateway_status;
};

struct Alert {
    std::string level;
    std::string message;
};

std::string getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    ss << "." << std::setfill('0') << std::setw(3) << ms.count();
    return ss.str();
}

void log(const std::string& message, const std::string& level = "INFO") {
    std::string timestamp = getCurrentTimestamp();
    std::string entry = "[" + timestamp + "] [" + level + "] " + message;
    std::cout << entry << std::endl;
    
    // Stelle sicher, dass das Log-Verzeichnis existiert
    std::filesystem::create_directories(std::filesystem::path(LOG_FILE).parent_path());
    
    std::ofstream file(LOG_FILE, std::ios::app);
    if (file.is_open()) {
        file << entry << std::endl;
        file.close();
    }
}

bool checkPing(const std::string& host, int timeout = 10) {
    try {
        std::string cmd = "ping -c 1 -W " + std::to_string(timeout) + " " + host + " >/dev/null 2>&1";
        int result = std::system(cmd.c_str());
        return WIFEXITED(result) && WEXITSTATUS(result) == 0;
    } catch (...) {
        return false;
    }
}

bool checkSSH(const NodeConfig& node_config) {
    try {
        std::string cmd = "ssh ";
        
        if (!node_config.ssh_opts.empty()) {
            cmd += node_config.ssh_opts + " ";
        }
        
        if (node_config.port > 0) {
            cmd += "-p " + std::to_string(node_config.port) + " ";
        }
        
        cmd += "-o ConnectTimeout=10 -o BatchMode=yes ";
        cmd += node_config.user + "@" + node_config.host + " echo \"OK\" >/dev/null 2>&1";
        
        int result = std::system(cmd.c_str());
        return WIFEXITED(result) && WEXITSTATUS(result) == 0;
    } catch (...) {
        return false;
    }
}

Metrics getNodeMetrics(const NodeConfig& node_config) {
    Metrics metrics;
    metrics.timestamp = getCurrentTimestamp();
    metrics.available = false;
    
    try {
        std::string cmd = "ssh -o ConnectTimeout=10 " + node_config.user + "@" + node_config.host + " '"
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
            "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\",\\\")\"\n"
            "\n"
            "# Gateway Status\n"
            "if command -v openclaw >/dev/null 2>&1; then\n"
            "    systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"\n"
            "fi\n"
            "' 2>/dev/null";
        
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) {
            return metrics;
        }
        
        char buffer[128];
        std::string result = "";
        while (fgets(buffer, sizeof buffer, pipe) != nullptr) {
            result += buffer;
        }
        
        int exit_code = pclose(pipe);
        if (exit_code != 0) {
            return metrics;
        }
        
        metrics.available = true;
        
        std::istringstream iss(result);
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
        
    } catch (const std::exception& e) {
        log("Error checking " + node_config.name + ": " + e.what(), "ERROR");
    }
    
    return metrics;
}

std::vector<Alert> checkAlerts(const std::string& node_id, const NodeConfig& node_config, const Metrics& metrics) {
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

void sendAlert(const Alert& alert) {
    try {
        std::string cmd = "python3 " + WORKSPACE + "/skills/channel-status-agent/scripts/channel_status.py "
                         "--type alert "
                         "--message \"" + alert.level + ": " + alert.message + "\" >/dev/null 2>&1";
        
        int result = std::system(cmd.c_str());
        log("Alert sent: " + alert.message);
    } catch (const std::exception& e) {
        log("Failed to send alert: " + std::string(e.what()), "ERROR");
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
            log("Unknown node: " + node_arg, "ERROR");
            return 1;
        }
    }
    
    // Health-Checks durchführen
    std::vector<Alert> all_alerts;
    
    for (const auto& pair : nodes_to_check) {
        const std::string& node_id = pair.first;
        const NodeConfig& node_config = pair.second;
        
        log("Checking " + node_config.name + " (" + node_id + ")");
        
        // Ping
        if (check_arg == "ping" || check_arg == "all") {
            if (node_config.host != "localhost") {
                bool ping_ok = checkPing(node_config.host);
                log("  Ping: " + std::string(ping_ok ? "OK" : "FAILED"));
            }
        }
        
        // SSH
        if (check_arg == "ssh" || check_arg == "all") {
            bool ssh_ok = checkSSH(node_config);
            log("  SSH: " + std::string(ssh_ok ? "OK" : "FAILED"));
        }
        
        // Metriken
        if (check_arg == "metrics" || check_arg == "all") {
            Metrics metrics = getNodeMetrics(node_config);
            
            if (metrics.available) {
                log("  CPU: " + (metrics.cpu > 0 ? std::to_string(metrics.cpu) + "%" : "N/A"));
                log("  RAM: " + (metrics.ram > 0 ? std::to_string(metrics.ram) + "%" : "N/A"));
                log("  Disk: " + (metrics.disk > 0 ? std::to_string(metrics.disk) + "%" : "N/A"));
                log("  Load: " + (metrics.load > 0 ? std::to_string(metrics.load) : "N/A"));
            } else {
                log("  Metrics: UNAVAILABLE");
            }
            
            // Alerts prüfen
            std::vector<Alert> alerts = checkAlerts(node_id, node_config, metrics);
            all_alerts.insert(all_alerts.end(), alerts.begin(), alerts.end());
        }
    }
    
    // Alerts senden
    if (alert_flag && !all_alerts.empty()) {
        log("\nSending " + std::to_string(all_alerts.size()) + " alerts...");
        for (const auto& alert : all_alerts) {
            sendAlert(alert);
        }
    } else if (!all_alerts.empty()) {
        log("\n" + std::to_string(all_alerts.size()) + " alerts found (use --alert to send)");
    } else {
        log("\nAll nodes healthy!");
    }
    
    return 0;
}
