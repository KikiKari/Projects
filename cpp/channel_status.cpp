// abstraction-provenance: {"artifact_sha256": "1e50edf33ae6ac7fe57aecbd55f956b4dfb33226e36998ffbd58ea37aad54c6f", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "cpp"}
// channel_status.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <sstream>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <ctime>
#include <cstdlib>
#include <memory>
#include <stdexcept>
#include <algorithm>
#include <cstdio>
#include <memory>

// Konfiguration
const std::string WORKSPACE = "/home/openclaw/.openclaw/workspace";
const std::string LOGS_DB = WORKSPACE + "/db/logs.db";
const std::string CONFIG_FILE = WORKSPACE + "/config/channel-status.json";
const std::string LOG_FILE = WORKSPACE + "/logs/channel-status.log";

void log(const std::string& message, const std::string& level = "INFO") {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto local_time = *std::localtime(&time_t);
    
    std::ostringstream timestamp;
    timestamp << std::put_time(&local_time, "%Y-%m-%d %H:%M:%S");
    
    std::string entry = "[" + timestamp.str() + "] [" + level + "] " + message;
    std::cout << entry << std::endl;
    
    std::ofstream file(LOG_FILE, std::ios::app);
    if (file.is_open()) {
        file << entry << std::endl;
        file.close();
    }
}

std::string exec_command(const std::vector<std::string>& cmd) {
    std::string command_str;
    for (size_t i = 0; i < cmd.size(); ++i) {
        if (i > 0) command_str += " ";
        command_str += cmd[i];
    }
    
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(command_str.c_str(), "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    
    std::string result;
    char buffer[128];
    while (fgets(buffer, sizeof buffer, pipe.get()) != nullptr) {
        result += buffer;
    }
    return result;
}

struct NodeInfo {
    std::string name;
    std::string status;
    std::string reason;
};

struct SystemStatus {
    std::string timestamp;
    std::map<std::string, NodeInfo> nodes;
    std::map<std::string, std::string> agents;
    std::map<std::string, std::string> system;
};

SystemStatus get_system_status() {
    SystemStatus status;
    
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto local_time = *std::localtime(&time_t);
    
    std::ostringstream timestamp_stream;
    timestamp_stream << std::put_time(&local_time, "%Y-%m-%dT%H:%M:%S");
    status.timestamp = timestamp_stream.str();
    
    // Node-Status (vereinfacht)
    status.nodes["node1"] = {"Gateway", "online", ""};
    status.nodes["node2"] = {"Worker", "online", ""};
    status.nodes["node3"] = {"Relay", "offline", "disk full"};
    status.nodes["node5"] = {"Redmi", "intermittent", ""};
    status.nodes["node7"] = {"Docker", "planned", ""};
    
    // Agent-Status aus Cron
    try {
        std::string crontab_output = exec_command({"crontab", "-l"});
        int cron_lines = 0;
        size_t pos = 0;
        while ((pos = crontab_output.find('\n', pos)) != std::string::npos) {
            ++cron_lines;
            ++pos;
        }
        
        // Count comment lines
        int comment_lines = 0;
        pos = 0;
        while ((pos = crontab_output.find('#', pos)) != std::string::npos) {
            ++comment_lines;
            ++pos;
        }
        
        status.agents["active_crons"] = std::to_string(cron_lines - comment_lines);
    } catch (...) {
        status.agents["active_crons"] = "unknown";
    }
    
    // System-Metriken
    try {
        // Disk usage
        std::string df_output = exec_command({"df", "-h", "/"});
        std::istringstream iss(df_output);
        std::string line;
        std::getline(iss, line); // Header skip
        
        while (std::getline(iss, line)) {
            if (line.find('/') != std::string::npos && line.find('%') != std::string::npos) {
                std::istringstream line_iss(line);
                std::string part;
                std::vector<std::string> parts;
                while (line_iss >> part) {
                    parts.push_back(part);
                }
                if (parts.size() >= 5) {
                    status.system["disk_used"] = parts[4];
                }
                break;
            }
        }
        
        // RAM usage
        std::string free_output = exec_command({"free", "-h"});
        std::istringstream free_iss(free_output);
        std::getline(free_iss, line); // Header skip
        
        while (std::getline(free_iss, line)) {
            if (line.find("Mem:") != std::string::npos) {
                std::istringstream line_iss(line);
                std::string part;
                std::vector<std::string> parts;
                while (line_iss >> part) {
                    parts.push_back(part);
                }
                if (parts.size() >= 3) {
                    status.system["ram_total"] = parts[1];
                    status.system["ram_used"] = parts[2];
                }
                break;
            }
        }
    } catch (...) {
        // Ignore errors
    }
    
    return status;
}

std::string format_daily_status(const SystemStatus& status) {
    int online = 0;
    for (const auto& pair : status.nodes) {
        if (pair.second.status == "online") {
            ++online;
        }
    }
    
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto local_time = *std::localtime(&time_t);
    
    std::ostringstream oss;
    oss << "📊 **Täglicher Status-Report**\n";
    oss << "🗓️ " << std::put_time(&local_time, "%Y-%m-%d %H:%M") << "\n\n";
    oss << "**🖥️ Nodes (" << online << "/5 online):**\n";
    
    for (const auto& pair : status.nodes) {
        const auto& node_id = pair.first;
        const auto& info = pair.second;
        
        std::string emoji;
        if (info.status == "online") {
            emoji = "🟢";
        } else if (info.status == "offline") {
            emoji = "🔴";
        } else {
            emoji = "🟡";
        }
        
        oss << emoji << " " << info.name << ": " << info.status;
        if (!info.reason.empty()) {
            oss << " (" << info.reason << ")";
        }
        oss << "\n";
    }
    
    oss << "\n**🤖 Agents:**\n";
    oss << "Aktive Cron-Jobs: " << status.agents.at("active_crons") << "\n";
    
    if (status.system.find("disk_used") != status.system.end()) {
        oss << "\n**💾 System:**\n";
        oss << "Disk: " << status.system.at("disk_used") << " belegt\n";
        oss << "RAM: " << status.system.at("ram_used") << " / " << status.system.at("ram_total") << "\n";
    }
    
    return oss.str();
}

std::string format_weekly_status(const SystemStatus& status) {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto local_time = *std::localtime(&time_t);
    
    std::ostringstream oss;
    oss << "📈 **Wöchentlicher Report**\n";
    oss << "📅 Woche " << std::put_time(&local_time, "%V") << " - " << std::put_time(&local_time, "%Y") << "\n\n";
    oss << "**Zusammenfassung:**\n";
    oss << "- 5 aktive Sub-Agents\n";
    oss << "- 11 Skills synchronisiert\n";
    oss << "- 3 neue Features implementiert\n\n";
    oss << "**Top-Ereignisse:**\n";
    oss << "1. ClawHub-Git Sync implementiert ✅\n";
    oss << "2. Node 3 Disk voll (95%) ⚠️\n";
    oss << "3. Channel-Status-Agent aktiviert 🆕\n\n";
    oss << "**Geplante Wartungen:**\n";
    oss << "- Node 3: Disk-Cleanup erforderlich\n";
    oss << "- Node 7: Docker-Setup ausstehend\n";
    
    return oss.str();
}

bool send_to_channel(const std::string& message, const std::string& channel_type = "telegram", const std::string& channel_id = "-1002381931352") {
    if (channel_type == "telegram") {
        std::string cmd = "openclaw message send --target " + channel_id + " --message \"" + message + "\"";
        
        try {
            int result = std::system(cmd.c_str());
            if (result == 0) {
                log("Message sent to " + channel_type + " " + channel_id);
                return true;
            } else {
                log("Failed to send message", "ERROR");
                return false;
            }
        } catch (const std::exception& e) {
            log("Send error: " + std::string(e.what()), "ERROR");
            return false;
        }
    } else {
        log("Channel type " + channel_type + " not implemented", "WARN");
        return false;
    }
}

int main(int argc, char* argv[]) {
    std::string type;
    std::string message;
    std::string channel = "-1002381931352";
    bool dry_run = false;
    
    // Simple argument parsing
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--type" && i + 1 < argc) {
            type = argv[++i];
        } else if (arg == "--message" && i + 1 < argc) {
            message = argv[++i];
        } else if (arg == "--channel" && i + 1 < argc) {
            channel = argv[++i];
        } else if (arg == "--dry-run") {
            dry_run = true;
        }
    }
    
    if (type.empty() || (type != "daily" && type != "weekly" && type != "alert")) {
        std::cerr << "Usage: " << argv[0] << " --type [daily|weekly|alert] [--message <msg>] [--channel <id>] [--dry-run]" << std::endl;
        return 1;
    }
    
    // Create log directory if needed
    std::filesystem::create_directories(std::filesystem::path(LOG_FILE).parent_path());
    
    log("Starting " + type + " status update");
    
    // Status sammeln
    SystemStatus status = get_system_status();
    
    // Message formatieren
    std::string formatted_message;
    if (type == "daily") {
        formatted_message = format_daily_status(status);
    } else if (type == "weekly") {
        formatted_message = format_weekly_status(status);
    } else if (type == "alert") {
        formatted_message = "🚨 **ALERT**\n" + (message.empty() ? "Manual alert" : message);
    }
    
    // Senden oder Dry-Run
    if (dry_run) {
        std::cout << "\n--- DRY RUN ---" << std::endl;
        std::cout << formatted_message << std::endl;
        std::cout << "--- END ---" << std::endl;
    } else {
        send_to_channel(formatted_message, "telegram", channel);
    }
    
    log("Status update completed");
    
    return 0;
}
