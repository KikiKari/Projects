// abstraction-provenance: {"artifact_sha256": "1d7fdf70566bd7e3647f341fe659e1d85c2495cb1d92ebe13ff4d58b9a45157e", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "cpp"}
// fix_gateway_node_path.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <ctime>
#include <sstream>
#include <filesystem>
#include <cstdlib>

int main() {
    const std::string service_file = "/etc/systemd/system/openclaw-gateway.service";
    const std::string old_node_path = "/home/openclaw/.nvm/versions/node/v22.22.2/bin/node";
    const std::string new_node_path = "/usr/bin/node";
    
    // Backup der originalen Service-Datei
    std::time_t now = std::time(nullptr);
    std::tm* local_time = std::localtime(&now);
    std::ostringstream backup_suffix;
    backup_suffix << "-" << (local_time->tm_year + 1900) 
                  << (local_time->tm_mon < 9 ? "0" : "") << (local_time->tm_mon + 1)
                  << (local_time->tm_mday < 10 ? "0" : "") << local_time->tm_mday << "_"
                  << (local_time->tm_hour < 10 ? "0" : "") << local_time->tm_hour
                  << (local_time->tm_min < 10 ? "0" : "") << local_time->tm_min
                  << (local_time->tm_sec < 10 ? "0" : "") << local_time->tm_sec;
    
    std::string backup_file = service_file + ".backup" + backup_suffix.str();
    
    try {
        std::filesystem::copy(service_file, backup_file);
        std::cout << "Backup erstellt: " << backup_file << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Fehler beim Erstellen des Backups: " << e.what() << std::endl;
        return 1;
    }
    
    // Korrektur des Node.js Pfads in der Service-Datei
    std::ifstream input_file(service_file);
    if (!input_file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Service-Datei zum Lesen" << std::endl;
        return 1;
    }
    
    std::string temp_file = service_file + ".tmp";
    std::ofstream output_file(temp_file);
    if (!output_file.is_open()) {
        std::cerr << "Fehler beim Erstellen der temporären Datei" << std::endl;
        return 1;
    }
    
    std::string line;
    while (std::getline(input_file, line)) {
        size_t pos = line.find(old_node_path);
        if (pos != std::string::npos) {
            line.replace(pos, old_node_path.length(), new_node_path);
        }
        output_file << line << "\n";
    }
    
    input_file.close();
    output_file.close();
    
    try {
        std::filesystem::rename(temp_file, service_file);
        std::cout << "Node.js Pfad korrigiert" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Fehler beim Überschreiben der Service-Datei: " << e.what() << std::endl;
        return 1;
    }
    
    // Service neu laden und neu starten
    int result = system("systemctl daemon-reload");
    if (result != 0) {
        std::cerr << "Fehler beim Neuladen der Systemd-Konfiguration" << std::endl;
        return 1;
    }
    
    result = system("systemctl restart openclaw-gateway");
    if (result != 0) {
        std::cerr << "Fehler beim Neustarten des Services" << std::endl;
        return 1;
    }
    
    std::cout << "Service neu geladen und neu gestartet" << std::endl;
    
    // Status prüfen
    system("systemctl status openclaw-gateway --no-pager");
    
    return 0;
}
