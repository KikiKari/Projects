// abstraction-provenance: {"artifact_sha256": "99552aa337a7756d8caedc6814cea7ebbdb64ef34eea13cbc6c2573231f9288a", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "cpp"}
// install_cron.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <filesystem>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

const std::string CRON_JOB = 
R"(# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1)";

void install() {
    fs::path workspace = "/home/openclaw/.openclaw/workspace";
    fs::path cron_file = workspace / "crons" / "db-maintainer.cron";
    
    // Erstelle das Verzeichnis falls es nicht existiert
    fs::create_directories(cron_file.parent_path());
    
    // Schreibe die Cron-Job-Datei
    std::ofstream file(cron_file);
    if (file.is_open()) {
        file << CRON_JOB << std::endl;
        file.close();
        std::cout << "✅ Cron-Job installiert: " << cron_file << std::endl;
        std::cout << "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron" << std::endl;
    } else {
        std::cerr << "Fehler beim Öffnen der Datei: " << cron_file << std::endl;
        return;
    }
    
    // Auch in OpenClaw cron registrieren
    fs::path jobs_json = workspace / ".openclaw" / "cron" / "jobs.json";
    if (fs::exists(jobs_json)) {
        std::ifstream input_file(jobs_json);
        if (!input_file.is_open()) {
            std::cerr << "Fehler beim Öffnen der Datei: " << jobs_json << std::endl;
            return;
        }
        
        json jobs;
        try {
            input_file >> jobs;
        } catch (const json::exception& e) {
            std::cerr << "Fehler beim Parsen der JSON-Datei: " << e.what() << std::endl;
            return;
        }
        
        // Füge den neuen Job hinzu oder aktualisiere ihn
        jobs["db-maintainer"] = {
            {"schedule", "*/30 * * * *"},
            {"command", "python3 skills/db-maintainer/scripts/db_maintainer.py"},
            {"enabled", true}
        };
        
        input_file.close();
        
        std::ofstream output_file(jobs_json);
        if (output_file.is_open()) {
            output_file << jobs.dump(2) << std::endl;
            output_file.close();
            std::cout << "✅ In OpenClaw cron registriert" << std::endl;
        } else {
            std::cerr << "Fehler beim Öffnen der Datei zum Schreiben: " << jobs_json << std::endl;
        }
    }
}

int main() {
    install();
    return 0;
}
