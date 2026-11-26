// abstraction-provenance: {"artifact_sha256": "e3dbac875bf39ba5ee66635d6151c56ac7ab08457880687939d5d001d7604359", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "cpp"}
// collect_ist_gateway_a.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <ctime>
#include <cstdlib>
#include <cstdio>
#include <memory>
#include <stdexcept>

namespace fs = std::filesystem;

// Helper function to execute command and get output
std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

// Trim whitespace from string
std::string trim(const std::string& str) {
    const auto strBegin = str.find_first_not_of(" \t\n\r");
    if (strBegin == std::string::npos)
        return "";

    const auto strEnd = str.find_last_not_of(" \t\n\r");
    const auto strRange = strEnd - strBegin + 1;

    return str.substr(strBegin, strRange);
}

// Get current time as formatted string
std::string getCurrentTimeUTC() {
    std::time_t t = std::time(nullptr);
    char buffer[21];
    std::strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", std::gmtime(&t));
    return std::string(buffer);
}

std::string getCurrentTimeLocal() {
    std::time_t t = std::time(nullptr);
    char buffer[30];
    std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %Z", std::localtime(&t));
    return std::string(buffer);
}

std::string getTimestamp() {
    std::time_t t = std::time(nullptr);
    char buffer[16];
    std::strftime(buffer, sizeof(buffer), "%Y%m%d-%H%M%S", std::localtime(&t));
    return std::string(buffer);
}

// Check if file exists
bool fileExists(const std::string& path) {
    return fs::exists(path) && fs::is_regular_file(path);
}

// Check if directory exists
bool dirExists(const std::string& path) {
    return fs::exists(path) && fs::is_directory(path);
}

// Read file content
std::string readFile(const std::string& path) {
    std::ifstream file(path);
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

// Get OS pretty name from /etc/os-release
std::string getOSPrettyName() {
    std::ifstream file("/etc/os-release");
    std::string line;
    while (std::getline(file, line)) {
        if (line.substr(0, 11) == "PRETTY_NAME") {
            size_t start = line.find('"');
            size_t end = line.rfind('"');
            if (start != std::string::npos && end != std::string::npos && end > start) {
                return line.substr(start+1, end-start-1);
            }
        }
    }
    return "";
}

int main() {
    try {
        // Environment variables
        const char* homeDir = std::getenv("HOME");
        if (!homeDir) {
            std::cerr << "ERROR: HOME environment variable not set\n";
            return 1;
        }

        std::string BASE_DIR = std::string(homeDir) + "/.openclaw";
        std::string OUT_DIR = BASE_DIR + "/workspace/vscode";
        std::string NOW_UTC = getCurrentTimeUTC();
        std::string NOW_LOCAL = getCurrentTimeLocal();
        std::string TS = getTimestamp();

        // Create output directory
        fs::create_directories(OUT_DIR);

        // File paths
        std::string IST_FILE = OUT_DIR + "/IST-ZUSTAND_GATEWAY-A_NODE1.md";
        std::string INV_FILE = OUT_DIR + "/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md";
        std::string CFG_FILE = OUT_DIR + "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md";
        std::string ENV_FILE = OUT_DIR + "/ENV-STATUS_GATEWAY-A_NODE1.md";
        std::string RUN_FILE = OUT_DIR + "/RUN-" + TS + ".md";

        std::string OPENCLAW_JSON = BASE_DIR + "/openclaw.json";
        std::string ENV_DOT = BASE_DIR + "/.env";
        std::string ENV_SYSTEMD = BASE_DIR + "/gateway.systemd.env";
        std::string VSCODE_DIR = BASE_DIR + "/.vscode";

        // System information
        std::string HOSTNAME_FQDN = trim(exec("hostname -f 2>/dev/null || hostname"));
        std::string HOSTNAME_SHORT = trim(exec("hostname"));
        std::string ARCH = trim(exec("uname -m"));
        std::string KERNEL = trim(exec("uname -r"));
        std::string OS_PRETTY = getOSPrettyName();
        std::string IPV4_ALL = trim(exec("hostname -I 2>/dev/null | xargs"));
        std::string PUBLIC_IP = trim(exec("curl -4 -s --max-time 4 ifconfig.me 2>/dev/null"));
        std::string TAILSCALE_IP = trim(exec("tailscale ip -4 2>/dev/null | head -n1"));
        std::string OPENCLAW_VER = trim(exec("openclaw --version 2>/dev/null"));
        std::string NODE_VER = trim(exec("node -v 2>/dev/null"));

        if (PUBLIC_IP.empty()) PUBLIC_IP = "(nicht ermittelt)";
        if (TAILSCALE_IP.empty()) TAILSCALE_IP = "(nicht ermittelt)";
        if (OPENCLAW_VER.empty()) OPENCLAW_VER = "(nicht ermittelt)";
        if (NODE_VER.empty()) NODE_VER = "(nicht ermittelt)";

        // Write IST file
        {
            std::ofstream file(IST_FILE);
            file << "# IST-Zustand: Gateway A / Node 1\n\n";
            file << "Stand (lokal): " << NOW_LOCAL << "  \n";
            file << "Stand (UTC): " << NOW_UTC << "\n\n";
            file << "## 1) Identitaet & System\n\n";
            file << "- Gateway: **A**\n";
            file << "- Node: **1**\n";
            file << "- Hostname (short): `" << HOSTNAME_SHORT << "`\n";
            file << "- Hostname (FQDN): `" << HOSTNAME_FQDN << "`\n";
            file << "- Architektur: `" << ARCH << "`\n";
            file << "- Kernel: `" << KERNEL << "`\n";
            file << "- OS: `" << OS_PRETTY << "`\n";
            file << "- IPv4 (lokal): `" << IPV4_ALL << "`\n";
            file << "- Public IPv4: `" << PUBLIC_IP << "`\n";
            file << "- Tailscale IPv4: `" << TAILSCALE_IP << "`\n";
            file << "- OpenClaw Version: `" << OPENCLAW_VER << "`\n";
            file << "- Node.js Version: `" << NODE_VER << "`\n\n";
            file << "## 2) Arbeitsverzeichnisse\n\n";
            file << "- Basis: `" << BASE_DIR << "`\n";
            file << "- Funktionell VSCode: `" << VSCODE_DIR << "`\n";
            file << "- Workspace Doku: `" << OUT_DIR << "`\n\n";
            file << "## 3) Kernartefakte (Existenz)\n\n";
            file << "- `" << OPENCLAW_JSON << "`: " << (fileExists(OPENCLAW_JSON) ? "vorhanden" : "fehlt") << "\n";
            file << "- `" << ENV_DOT << "`: " << (fileExists(ENV_DOT) ? "vorhanden" : "fehlt") << "\n";
            file << "- `" << ENV_SYSTEMD << "`: " << (fileExists(ENV_SYSTEMD) ? "vorhanden" : "fehlt") << "\n";
            file << "- `" << BASE_DIR << "/plugins/installs.json`: " << (fileExists(BASE_DIR + "/plugins/installs.json") ? "vorhanden" : "fehlt") << "\n";
            file << "- `" << BASE_DIR << "/plugin-skills`: " << (dirExists(BASE_DIR + "/plugin-skills") ? "vorhanden" : "fehlt") << "\n";
        }

        // Write inventory file
        {
            std::ofstream file(INV_FILE);
            file << "# Artefakt-Inventar: Gateway A / Node 1\n\n";
            file << "Stand: " << NOW_LOCAL << "\n\n";
            file << "## Top-Level in ~/.openclaw\n\n";
            file << "```text\n";
            
            if (dirExists(BASE_DIR)) {
                for (const auto& entry : fs::directory_iterator(BASE_DIR)) {
                    file << entry.path().filename().string() << "\n";
                }
            }
            
            file << "```\n\n";
            file << "## ~/.openclaw/.vscode\n\n";
            file << "```text\n";
            
            if (dirExists(VSCODE_DIR)) {
                for (const auto& entry : fs::directory_iterator(VSCODE_DIR)) {
                    file << entry.path().filename().string() << " ";
                    file << (fs::is_directory(entry) ? "d" : "f") << "\n";
                }
            } else {
                file << "(nicht vorhanden)\n";
            }
            
            file << "```\n\n";
            file << "## plugin-skills/\n\n";
            file << "```text\n";
            
            if (dirExists(BASE_DIR + "/plugin-skills")) {
                for (const auto& entry : fs::directory_iterator(BASE_DIR + "/plugin-skills")) {
                    file << entry.path().filename().string() << "\n";
                }
            } else {
                file << "(nicht vorhanden)\n";
            }
            
            file << "```\n\n";
            file << "## openclaw.json Backups\n\n";
            file << "```text\n";
            
            bool found = false;
            if (dirExists(BASE_DIR)) {
                for (const auto& entry : fs::directory_iterator(BASE_DIR)) {
                    if (entry.path().filename().string().substr(0, 19) == "openclaw.json.bak") {
                        file << entry.path().filename().string() << "\n";
                        found = true;
                    }
                }
            }
            
            if (!found) {
                file << "(keine gefunden)\n";
            }
            
            file << "```\n";
        }

        // Write config snapshot file
        {
            std::ofstream file(CFG_FILE);
            file << "# OpenClaw Config Snapshot: Gateway A / Node 1\n\n";
            file << "Stand: " << NOW_LOCAL << "\n\n";
            file << "## Schluesselpositionen (grep)\n\n";
            file << "```text\n";
            
            if (fileExists(OPENCLAW_JSON)) {
                std::string cmd = "grep -nE '\"gateway\"|\\\"session\\\"|\\\"dmScope\\\"|\\\"auth\\\"|\\\"secrets\\\"|\\\"tools\\\"|\\\"plugins\\\"|\\\"profile\\\"|\\\"alsoAllow\\\"|\\\"denyCommands\\\"' \"" + OPENCLAW_JSON + "\"";
                file << exec(cmd.c_str());
            } else {
                file << "openclaw.json fehlt\n";
            }
            
            file << "```\n\n";
            file << "## Ausschnitt gateway/session/auth\n\n";
            file << "```json\n";
            
            if (fileExists(OPENCLAW_JSON)) {
                std::ifstream jsonFile(OPENCLAW_JSON);
                std::string line;
                int lineNumber = 0;
                while (std::getline(jsonFile, line) && lineNumber < 780) {
                    lineNumber++;
                    if (lineNumber >= 580) {
                        file << line << "\n";
                    }
                }
            } else {
                file << "{ \"error\": \"openclaw.json fehlt\" }\n";
            }
            
            file << "```\n";
        }

        // Write env status file
        {
            std::ofstream file(ENV_FILE);
            file << "# ENV-Status: Gateway A / Node 1\n\n";
            file << "Stand: " << NOW_LOCAL << "\n\n";
            file << "## Dateien\n\n";
            file << "```text\n";
            
            if (fileExists(ENV_DOT) || fileExists(ENV_SYSTEMD)) {
                if (fileExists(ENV_DOT)) {
                    file << fs::last_write_time(ENV_DOT) << " " << ENV_DOT << "\n";
                }
                if (fileExists(ENV_SYSTEMD)) {
                    file << fs::last_write_time(ENV_SYSTEMD) << " " << ENV_SYSTEMD << "\n";
                }
            }
            
            file << "```\n\n";
            file << "## .env (vollstaendig)\n\n";
            file << "```dotenv\n";
            
            if (fileExists(ENV_DOT)) {
                file << readFile(ENV_DOT);
            } else {
                file << "# .env fehlt\n";
            }
            
            file << "```\n\n";
            file << "## gateway.systemd.env (vollstaendig)\n\n";
            file << "```dotenv\n";
            
            if (fileExists(ENV_SYSTEMD)) {
                file << readFile(ENV_SYSTEMD);
            } else {
                file << "# gateway.systemd.env fehlt\n";
            }
            
            file << "```\n";
        }

        // Write run file
        {
            std::ofstream file(RUN_FILE);
            file << "# Laufprotokoll Gateway A / Node 1\n\n";
            file << "- Zeit (lokal): " << NOW_LOCAL << "\n";
            file << "- Zeit (UTC): " << NOW_UTC << "\n";
            file << "- Script: collect_ist_gateway_a.sh\n\n"; // Simplified since we don't have argv[0] equivalent
            file << "## Erzeugte Dateien\n\n";
            file << "- " << fs::path(IST_FILE).filename().string() << "\n";
            file << "- " << fs::path(INV_FILE).filename().string() << "\n";
            file << "- " << fs::path(CFG_FILE).filename().string() << "\n";
            file << "- " << fs::path(ENV_FILE).filename().string() << "\n";
        }

        // Output success message
        std::cout << "OK: IST-Zustand erfasst.\n";
        
        // List files in output directory
        if (dirExists(OUT_DIR)) {
            for (const auto& entry : fs::directory_iterator(OUT_DIR)) {
                std::cout << "- " << entry.path().filename().string() << "\n";
            }
        }

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
