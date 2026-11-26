// abstraction-provenance: {"artifact_sha256": "28ddc17c3d32ff060bf8b9b43a322bbbed5ff11e0e017e1cb77593a4fffb7608", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "cpp"}
// openclaw-node-autostart-termux.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <ctime>
#include <thread>
#include <chrono>
#include <sstream>

// OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
// Installiert nach: ~/.termux/boot/openclaw-node.sh
// Getestet mit: Termux + Android + OpenClaw

const std::string SESSION = "openclaw-node";
const std::string LOGFILE = std::getenv("HOME") + std::string("/.openclaw/node.log");
const std::string GATEWAY = "10.10.0.1";
const std::string PORT = "18789";

void logMessage(const std::string& message) {
    std::ofstream logfile(LOGFILE, std::ios_base::app);
    if (logfile.is_open()) {
        std::time_t now = std::time(nullptr);
        char buffer[100];
        std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
        logfile << "[" << buffer << "] " << message << std::endl;
    }
}

bool isTmuxSessionRunning(const std::string& sessionName) {
    std::string command = "tmux has-session -t " + sessionName + " 2>/dev/null";
    return std::system(command.c_str()) == 0;
}

bool pingGateway(const std::string& gateway) {
    std::string command = "ping -c 1 -W 3 " + gateway + " >/dev/null 2>&1";
    return std::system(command.c_str()) == 0;
}

std::string getCurrentDateTime() {
    std::time_t now = std::time(nullptr);
    char buffer[100];
    std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
    return std::string(buffer);
}

int main() {
    // Log-Verzeichnis erstellen
    std::filesystem::create_directories(std::getenv("HOME") + std::string("/.openclaw"));

    // Prüfen ob tmux Session bereits läuft
    if (isTmuxSessionRunning(SESSION)) {
        logMessage("OpenClaw Node läuft bereits in tmux Session '" + SESSION + "'");
        return 0;
    }

    // Neue tmux Session erstellen und OpenClaw starten
    std::string tmuxCommand = "tmux new-session -d -s " + SESSION + " -n node '";
    tmuxCommand += "while true; do ";
    tmuxCommand += "echo \"[" + getCurrentDateTime() + "] Starting OpenClaw Node Mode...\" | tee -a " + LOGFILE + "; ";

    // Prüfe WireGuard Verbindung
    tmuxCommand += "if ! ping -c 1 -W 3 " + GATEWAY + " >/dev/null 2>&1; then ";
    tmuxCommand += "echo \"[" + getCurrentDateTime() + "] FEHLER: WireGuard Gateway " + GATEWAY + " nicht erreichbar!\" | tee -a " + LOGFILE + "; ";
    tmuxCommand += "echo \"[" + getCurrentDateTime() + "] Warte 10 Sekunden...\" | tee -a " + LOGFILE + "; ";
    tmuxCommand += "sleep 10; ";
    tmuxCommand += "continue; ";
    tmuxCommand += "fi; ";

    // OpenClaw Node Mode starten
    tmuxCommand += "openclaw node run --host " + GATEWAY + " --port " + PORT + " 2>&1 | tee -a " + LOGFILE + "; ";

    // Wenn der Prozess endet, warte und neustarten
    tmuxCommand += "echo \"[" + getCurrentDateTime() + "] OpenClaw beendet. Neustart in 5 Sekunden...\" | tee -a " + LOGFILE + "; ";
    tmuxCommand += "sleep 5; ";
    tmuxCommand += "done'";

    int result = std::system(tmuxCommand.c_str());
    
    if (result == 0) {
        logMessage("OpenClaw Node Autostart aktiviert (tmux Session: " + SESSION + ")");
        
        // Optional: tmux attach Hinweis falls interaktiv gestartet
        if (isatty(STDOUT_FILENO)) {
            std::cout << "OpenClaw Node Mode gestartet in tmux Session '" << SESSION << "'" << std::endl;
            std::cout << "Zum Anschauen: tmux attach -t " << SESSION << std::endl;
            std::cout << "Log-Datei: " << LOGFILE << std::endl;
        }
    }

    return 0;
}
