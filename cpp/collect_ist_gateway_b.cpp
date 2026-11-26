// abstraction-provenance: {"artifact_sha256": "9b2c3a819ff77e2ce39694295246fe78c7aeacce550f4a8b8061d909166ad3a3", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "cpp"}
// collect_ist_gateway_b.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <chrono>
#include <ctime>
#include <iomanip>
#include <cstdlib>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <unistd.h>
#include <sys/utsname.h>

namespace fs = std::filesystem;

class GatewayBCollector {
private:
    std::string HOME;
    std::string BASE_DIR;
    std::string OUT_DIR;
    std::string NOW_UTC;
    std::string NOW_LOCAL;
    std::string TS;

    // Dateipfade
    std::string IST_FILE;
    std::string INV_FILE;
    std::string CFG_FILE;
    std::string ENV_FILE;
    std::string RUN_FILE;

    // Konfigurationspfade
    std::string OPENCLAW_JSON;
    std::string ENV_DOT;
    std::string ENV_SYSTEMD;
    std::string VSCODE_DIR;

    // Systeminformationen
    std::string HOSTNAME_FQDN;
    std::string HOSTNAME_SHORT;
    std::string ARCH;
    std::string KERNEL;
    std::string OS_PRETTY;
    std::string IPV4_ALL;
    std::string PUBLIC_IP;
    std::string TAILSCALE_IP;
    std::string OPENCLAW_VER;
    std::string NODE_VER;

public:
    GatewayBCollector() {
        initializePaths();
        initializeTimestamps();
        gatherSystemInfo();
    }

    void run() {
        createOutputDirectory();
        writeIstFile();
        writeInventoryFile();
        writeConfigSnapshotFile();
        writeEnvStatusFile();
        writeRunFile();
        printSummary();
    }

private:
    void initializePaths() {
        HOME = getenv("HOME");
        BASE_DIR = HOME + "/.openclaw";
        OUT_DIR = BASE_DIR + "/workspace/vscode";

        OPENCLAW_JSON = BASE_DIR + "/openclaw.json";
        ENV_DOT = BASE_DIR + "/.env";
        ENV_SYSTEMD = BASE_DIR + "/gateway.systemd.env";
        VSCODE_DIR = BASE_DIR + "/.vscode";
    }

    void initializeTimestamps() {
        auto now = std::chrono::system_clock::now();
        auto time_t_now = std::chrono::system_clock::to_time_t(now);
        
        std::tm utc_tm = *std::gmtime(&time_t_now);
        std::tm local_tm = *std::localtime(&time_t_now);

        std::ostringstream utc_ss, local_ss, ts_ss;
        
        utc_ss << std::put_time(&utc_tm, "%Y-%m-%dT%H:%M:%SZ");
        NOW_UTC = utc_ss.str();
        
        local_ss << std::put_time(&local_tm, "%Y-%m-%d %H:%M:%S %Z");
        NOW_LOCAL = local_ss.str();
        
        ts_ss << std::put_time(&local_tm, "%Y%m%d-%H%M%S");
        TS = ts_ss.str();

        IST_FILE = OUT_DIR + "/IST-ZUSTAND_GATEWAY-B_NODE7.md";
        INV_FILE = OUT_DIR + "/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md";
        CFG_FILE = OUT_DIR + "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md";
        ENV_FILE = OUT_DIR + "/ENV-STATUS_GATEWAY-B_NODE7.md";
        RUN_FILE = OUT_DIR + "/RUN-" + TS + ".md";
    }

    void gatherSystemInfo() {
        char hostname[1024];
        hostname[1023] = '\0';
        gethostname(hostname, 1023);
        HOSTNAME_SHORT = std::string(hostname);

        HOSTNAME_FQDN = executeCommand("hostname -f 2>/dev/null || hostname");

        struct utsname unameData;
        if (uname(&unameData) == 0) {
            ARCH = std::string(unameData.machine);
            KERNEL = std::string(unameData.release);
        }

        OS_PRETTY = executeCommand("grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"' || echo ''");
        if (OS_PRETTY.empty()) OS_PRETTY = "";

        IPV4_ALL = executeCommand("hostname -I 2>/dev/null | xargs || echo ''");
        if (IPV4_ALL.empty()) IPV4_ALL = "";

        PUBLIC_IP = executeCommand("curl -4 -s --max-time 4 ifconfig.me 2>/dev/null || echo ''");
        if (PUBLIC_IP.empty()) PUBLIC_IP = "(nicht ermittelt)";

        TAILSCALE_IP = executeCommand("tailscale ip -4 2>/dev/null | head -n1 || echo ''");
        if (TAILSCALE_IP.empty()) TAILSCALE_IP = "(nicht ermittelt)";

        OPENCLAW_VER = executeCommand("openclaw --version 2>/dev/null || echo ''");
        if (OPENCLAW_VER.empty()) OPENCLAW_VER = "(nicht ermittelt)";

        NODE_VER = executeCommand("node -v 2>/dev/null || echo ''");
        if (NODE_VER.empty()) NODE_VER = "(nicht ermittelt)";
    }

    std::string executeCommand(const std::string& cmd) {
        std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
        if (!pipe) {
            return "";
        }
        
        std::string result;
        char buffer[128];
        while (fgets(buffer, sizeof buffer, pipe.get()) != nullptr) {
            result += buffer;
        }
        
        // Entferne trailing newline
        if (!result.empty() && result.back() == '\n') {
            result.pop_back();
        }
        
        return result;
    }

    void createOutputDirectory() {
        fs::create_directories(OUT_DIR);
    }

    bool fileExists(const std::string& path) {
        return fs::exists(path) && fs::is_regular_file(path);
    }

    bool directoryExists(const std::string& path) {
        return fs::exists(path) && fs::is_directory(path);
    }

    void writeIstFile() {
        std::ofstream file(IST_FILE);
        file << "# IST-Zustand: Gateway B / Node 7\n\n";
        file << "Stand (lokal): " << NOW_LOCAL << "  \n";
        file << "Stand (UTC): " << NOW_UTC << "\n\n";
        file << "## 1) Identität & System\n\n";
        file << "- Gateway: **B**\n";
        file << "- Node: **7**\n";
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
        file << "- funktionell VSCode: `" << VSCODE_DIR << "`\n";
        file << "- Workspace Doku: `" << OUT_DIR << "`\n\n";
        file << "## 3) Kernartefakte (Existenz)\n\n";
        file << "- `" << OPENCLAW_JSON << "`: " << (fileExists(OPENCLAW_JSON) ? "vorhanden" : "fehlt") << "\n";
        file << "- `" << ENV_DOT << "`: " << (fileExists(ENV_DOT) ? "vorhanden" : "fehlt") << "\n";
        file << "- `" << ENV_SYSTEMD << "`: " << (fileExists(ENV_SYSTEMD) ? "vorhanden" : "fehlt") << "\n";
        file << "- `" << BASE_DIR << "/plugins/installs.json`: " << (fileExists(BASE_DIR + "/plugins/installs.json") ? "vorhanden" : "fehlt") << "\n";
        file << "- `" << BASE_DIR << "/plugin-skills`: " << (directoryExists(BASE_DIR + "/plugin-skills") ? "vorhanden" : "fehlt") << "\n\n";
        file << "## 4) Hinweis\n\n";
        file << "Diese Datei wird bei jedem Lauf neu geschrieben.\n";
        file << "Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.\n";
    }

    void writeInventoryFile() {
        std::ofstream file(INV_FILE);
        file << "# Artefakt-Inventar: Gateway B / Node 7\n\n";
        file << "Stand: " << NOW_LOCAL << "\n\n";
        file << "## Top-Level in ~/.openclaw\n\n";
        file << "```text\n";
        
        if (directoryExists(BASE_DIR)) {
            for (const auto& entry : fs::directory_iterator(BASE_DIR)) {
                file << entry.path().filename().string() << "\n";
            }
        }
        
        file << "```\n\n";
        file << "## ~/.openclaw/.vscode\n\n";
        file << "```text\n";
        
        if (directoryExists(VSCODE_DIR)) {
            file << executeCommand("ls -la \"" + VSCODE_DIR + "\"");
        } else {
            file << "(nicht vorhanden)\n";
        }
        
        file << "```\n\n";
        file << "## plugin-skills/\n\n";
        file << "```text\n";
        
        if (directoryExists(BASE_DIR + "/plugin-skills")) {
            for (const auto& entry : fs::directory_iterator(BASE_DIR + "/plugin-skills")) {
                file << entry.path().filename().string() << "\n";
            }
        } else {
            file << "(nicht vorhanden)\n";
        }
        
        file << "```\n\n";
        file << "## openclaw.json Backups\n\n";
        file << "```text\n";
        
        try {
            for (const auto& entry : fs::directory_iterator(BASE_DIR)) {
                if (entry.path().filename().string().find("openclaw.json.bak") == 0) {
                    file << entry.path().filename().string() << "\n";
                }
            }
        } catch (...) {
            file << "(keine gefunden)\n";
        }
        
        file << "```\n";
    }

    void writeConfigSnapshotFile() {
        std::ofstream file(CFG_FILE);
        file << "# OpenClaw Config Snapshot: Gateway B / Node 7\n\n";
        file << "Stand: " << NOW_LOCAL << "\n\n";
        file << "## Schlüsselpositionen (grep)\n\n";
        file << "```text\n";
        
        if (fileExists(OPENCLAW_JSON)) {
            file << executeCommand("grep -nE '\"gateway\"|\\\"session\\\"|\\\"dmScope\\\"|\\\"auth\\\"|\\\"secrets\\\"|\\\"tools\\\"|\\\"plugins\\\"|\\\"profile\\\"|\\\"alsoAllow\\\"|\\\"denyCommands\\\"' \"" + OPENCLAW_JSON + "\" 2>/dev/null || true");
        } else {
            file << "openclaw.json fehlt\n";
        }
        
        file << "```\n\n";
        file << "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)\n\n";
        file << "```json\n";
        
        if (fileExists(OPENCLAW_JSON)) {
            file << executeCommand("sed -n '580,780p' \"" + OPENCLAW_JSON + "\" 2>/dev/null || true");
        } else {
            file << "{ \"error\": \"openclaw.json fehlt\" }\n";
        }
        
        file << "```\n";
    }

    void writeEnvStatusFile() {
        std::ofstream file(ENV_FILE);
        file << "# ENV-Status: Gateway B / Node 7\n\n";
        file << "Stand: " << NOW_LOCAL << "\n\n";
        file << "## Dateien\n\n";
        file << "```text\n";
        file << executeCommand("ls -la \"" + ENV_DOT + "\" \"" + ENV_SYSTEMD + "\" 2>/dev/null || true");
        file << "```\n\n";
        file << "## .env (vollständig, ungefiltert)\n\n";
        file << "```dotenv\n";
        
        if (fileExists(ENV_DOT)) {
            std::ifstream envFile(ENV_DOT);
            std::string line;
            while (std::getline(envFile, line)) {
                file << line << "\n";
            }
        } else {
            file << "# .env fehlt\n";
        }
        
        file << "```\n\n";
        file << "## gateway.systemd.env (vollständig, ungefiltert)\n\n";
        file << "```dotenv\n";
        
        if (fileExists(ENV_SYSTEMD)) {
            std::ifstream systemdFile(ENV_SYSTEMD);
            std::string line;
            while (std::getline(systemdFile, line)) {
                file << line << "\n";
            }
        } else {
            file << "# gateway.systemd.env fehlt\n";
        }
        
        file << "```\n";
    }

    void writeRunFile() {
        std::ofstream file(RUN_FILE);
        file << "# Laufprotokoll Gateway B / Node 7\n\n";
        file << "- Zeit (lokal): " << NOW_LOCAL << "\n";
        file << "- Zeit (UTC): " << NOW_UTC << "\n";
        file << "- Script: " << fs::current_path() / "collect_ist_gateway_b" << "\n\n";
        file << "## Erzeugte Dateien\n\n";
        file << "- " << fs::path(IST_FILE).filename().string() << "\n";
        file << "- " << fs::path(INV_FILE).filename().string() << "\n";
        file << "- " << fs::path(CFG_FILE).filename().string() << "\n";
        file << "- " << fs::path(ENV_FILE).filename().string() << "\n";
    }

    void printSummary() {
        std::cout << "OK: IST-Zustand erfasst.\n";
        std::cout << "Ausgabeordner: " << OUT_DIR << "\n";
        std::cout << "Dateien:\n";
        
        if (directoryExists(OUT_DIR)) {
            for (const auto& entry : fs::directory_iterator(OUT_DIR)) {
                std::cout << "- " << entry.path().filename().string() << "\n";
            }
        }
    }
};

int main() {
    try {
        GatewayBCollector collector;
        collector.run();
    } catch (const std::exception& e) {
        std::cerr << "Fehler: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
