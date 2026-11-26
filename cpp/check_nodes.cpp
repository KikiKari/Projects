// abstraction-provenance: {"artifact_sha256": "06c14be1966d48517517ec8536f6aae4b1ae6e905f119b6e5c203f7fc1ca932f", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "cpp"}
// check_nodes.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <sstream>
#include <fstream>
#include <chrono>
#include <iomanip>
#include <algorithm>
#include <cstdlib>
#include <memory>
#include <stdexcept>

// Node-Konfiguration (sollte aus config file geladen werden)
struct NodeConfig {
    bool always_available;
    std::string capacity;
    int priority;
    std::string description;
    std::string device;
};

struct NodeStatus {
    std::string id;
    bool online;
    bool available;
    std::string response;
};

const std::map<std::string, NodeConfig> NODES = {
    {"node1", {true, "medium", 2, "Gateway-Master", ""}},
    {"node2", {true, "medium", 3, "Stable Worker", ""}},
    {"node3", {false, "medium", 4, "Bald verfügbar (nach Reorganisation)", ""}},
    {"node5", {false, "low", 5, "Mobile (bei Internet verfügbar)", "Redmi Note 11S"}},
    {"node7", {true, "high", 1, "Docker Hauptarbeitspferd (bald verfügbar)", ""}}
};

std::string getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    return ss.str();
}

std::string getISOCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S");
    return ss.str();
}

std::string execCommand(const std::vector<std::string>& cmd, bool& success, int& exit_code) {
    // Konstruiere Kommandozeile
    std::string command_line;
    for (size_t i = 0; i < cmd.size(); ++i) {
        if (i > 0) command_line += " ";
        command_line += cmd[i];
    }
    command_line += " 2>&1";

    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(command_line.c_str(), "r"), pclose);
    if (!pipe) {
        success = false;
        return "popen() failed!";
    }

    std::string result;
    char buffer[128];
    while (fgets(buffer, sizeof buffer, pipe.get()) != nullptr) {
        result += buffer;
    }

    exit_code = pclose(pipe.release());
    success = true;
    return result;
}

NodeStatus checkNodeStatus(const std::string& nodeId) {
    try {
        std::vector<std::string> cmd = {"openclaw", "nodes", "status", nodeId};
        bool success;
        int exit_code;
        std::string output = execCommand(cmd, success, exit_code);

        bool isOnline = false;
        std::string response = "No response";

        if (success) {
            // Entferne Zeilenumbrüche für die Überprüfung
            std::transform(output.begin(), output.end(), output.begin(), ::tolower);
            isOnline = (exit_code == 0) && 
                      (output.find("online") != std::string::npos || 
                       output.find("active") != std::string::npos);
            
            // Begrenze Antwort auf 100 Zeichen
            if (output.length() > 100) {
                response = output.substr(0, 100);
            } else {
                response = output.empty() ? "No response" : output;
            }
        } else {
            response = "Execution failed";
        }

        auto it = NODES.find(nodeId);
        bool available = (it != NODES.end()) ? it->second.always_available : false;

        return {nodeId, isOnline, available, response};
    } catch (const std::exception& e) {
        auto it = NODES.find(nodeId);
        bool available = (it != NODES.end()) ? it->second.always_available : false;
        return {nodeId, false, available, "Error: " + std::string(e.what())};
    }
}

void printTable(const std::vector<NodeStatus>& nodesStatus) {
    std::cout << "\n" << std::string(90, '=') << "\n";
    printf("%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung");
    std::cout << std::string(90, '=') << "\n";
    
    for (const auto& status : nodesStatus) {
        auto it = NODES.find(status.id);
        if (it == NODES.end()) continue;
        
        const auto& config = it->second;
        
        std::string statusIcon = status.online ? "🟢 Online" : "🔴 Offline";
        std::string availIcon = status.available ? "✅ Immer" : "📱 Bedingt";
        std::string capacity = config.capacity;
        std::string priority = std::to_string(config.priority);
        std::string device = config.device.empty() ? config.description : config.device;
        
        printf("%-8s %-12s %-12s %-10s %-10s %s\n", 
               status.id.c_str(), 
               statusIcon.c_str(), 
               availIcon.c_str(), 
               capacity.c_str(), 
               priority.c_str(), 
               device.c_str());
    }
    
    std::cout << std::string(90, '=') << "\n";
    std::cout << "\nGeprüft am: " << getCurrentTimestamp() << "\n";
}

void printJson(const std::vector<NodeStatus>& nodesStatus) {
    std::cout << "{\n";
    std::cout << "  \"timestamp\": \"" << getISOCurrentTimestamp() << "\",\n";
    std::cout << "  \"nodes\": {\n";
    
    for (size_t i = 0; i < nodesStatus.size(); ++i) {
        const auto& status = nodesStatus[i];
        auto it = NODES.find(status.id);
        if (it == NODES.end()) continue;
        
        const auto& config = it->second;
        
        std::cout << "    \"" << status.id << "\": {\n";
        std::cout << "      \"status\": {\n";
        std::cout << "        \"id\": \"" << status.id << "\",\n";
        std::cout << "        \"online\": " << (status.online ? "true" : "false") << ",\n";
        std::cout << "        \"available\": " << (status.available ? "true" : "false") << ",\n";
        std::cout << "        \"response\": \"" << status.response << "\"\n";
        std::cout << "      },\n";
        std::cout << "      \"config\": {\n";
        std::cout << "        \"always_available\": " << (config.always_available ? "true" : "false") << ",\n";
        std::cout << "        \"capacity\": \"" << config.capacity << "\",\n";
        std::cout << "        \"priority\": " << config.priority;
        if (!config.device.empty()) {
            std::cout << ",\n        \"device\": \"" << config.device << "\"";
        }
        if (!config.description.empty()) {
            std::cout << ",\n        \"description\": \"" << config.description << "\"";
        }
        std::cout << "\n      }\n";
        std::cout << "    }";
        if (i < nodesStatus.size() - 1) std::cout << ",";
        std::cout << "\n";
    }
    
    std::cout << "  }\n";
    std::cout << "}\n";
}

int main(int argc, char* argv[]) {
    std::string format = "table";
    std::string saveFile = "";
    
    // Einfacher Argumentparser
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if ((arg == "--format" || arg == "-f") && i + 1 < argc) {
            format = argv[++i];
        } else if ((arg == "--save" || arg == "-s") && i + 1 < argc) {
            saveFile = argv[++i];
        }
    }
    
    std::cout << "🔍 Prüfe Node-Status...\n";
    
    // Prüfe alle Nodes
    std::vector<NodeStatus> nodesStatus;
    std::vector<std::string> nodeIds;
    for (const auto& pair : NODES) {
        nodeIds.push_back(pair.first);
    }
    std::sort(nodeIds.begin(), nodeIds.end());
    
    for (const auto& nodeId : nodeIds) {
        std::cout << "  → " << nodeId << "... ";
        std::cout.flush();
        NodeStatus status = checkNodeStatus(nodeId);
        nodesStatus.push_back(status);
        std::cout << (status.online ? "✓" : "✗") << "\n";
    }
    
    // Ausgabe
    if (format == "table") {
        printTable(nodesStatus);
    } else {
        printJson(nodesStatus);
    }
    
    // Speichern
    if (!saveFile.empty()) {
        std::ofstream file(saveFile);
        if (file.is_open()) {
            file << "{\n";
            file << "  \"timestamp\": \"" << getISOCurrentTimestamp() << "\",\n";
            file << "  \"nodes\": {\n";
            
            for (size_t i = 0; i < nodesStatus.size(); ++i) {
                const auto& status = nodesStatus[i];
                file << "    \"" << status.id << "\": {\n";
                file << "      \"id\": \"" << status.id << "\",\n";
                file << "      \"online\": " << (status.online ? "true" : "false") << ",\n";
                file << "      \"available\": " << (status.available ? "true" : "false") << ",\n";
                file << "      \"response\": \"" << status.response << "\"\n";
                file << "    }";
                if (i < nodesStatus.size() - 1) file << ",";
                file << "\n";
            }
            
            file << "  }\n";
            file << "}\n";
            file.close();
            std::cout << "\n💾 Gespeichert: " << saveFile << "\n";
        }
    }
    
    // Zusammenfassung
    int onlineCount = 0;
    for (const auto& status : nodesStatus) {
        if (status.online) onlineCount++;
    }
    std::cout << "\n📊 Zusammenfassung: " << onlineCount << "/" << nodesStatus.size() << " Nodes online\n";
    
    return 0;
}
