// abstraction-provenance: {"artifact_sha256": "b118df069bbcd9623dc2a2851bbea8ca87a1599c131be592498785b31235509f", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "cpp"}
// collect_compare_bundle.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <map>
#include <algorithm>
#include <memory>
#include <stdexcept>

namespace fs = std::filesystem;

class CollectCompareBundle {
private:
    const std::string ROOT = "/home/openclaw/.openclaw";
    const std::string OUT_DIR;
    const std::string TRANSFER_DIR;
    const std::string MD_FILE;
    const std::string TREE_FILE;
    const std::string BACKUP_FILE;
    const std::string NOW_LOCAL;
    const std::string NOW_UTC;
    const std::string HOST;

    const std::string OPENCLAW_JSON;
    const std::string EXEC_APPROVALS_JSON;
    const std::string GATEWAY_SYSTEMD_ENV;
    const std::string DOT_ENV;
    const std::string CONFIG_DIR;
    const std::string AGENTS_DIR;

public:
    CollectCompareBundle() : 
        OUT_DIR(ROOT + "/workspace/vscode/compare"),
        TRANSFER_DIR(OUT_DIR + "/transfer"),
        MD_FILE(OUT_DIR + "/local-gateway-config.md"),
        TREE_FILE(OUT_DIR + "/tree.txt"),
        BACKUP_FILE("/home/openclaw/openclaw-backup.tar.gz"),
        NOW_LOCAL(getCurrentTimeLocal()),
        NOW_UTC(getCurrentTimeUTC()),
        HOST(getHostname()),
        OPENCLAW_JSON(ROOT + "/openclaw.json"),
        EXEC_APPROVALS_JSON(ROOT + "/exec-approvals.json"),
        GATEWAY_SYSTEMD_ENV(ROOT + "/gateway.systemd.env"),
        DOT_ENV(ROOT + "/.env"),
        CONFIG_DIR(ROOT + "/.config"),
        AGENTS_DIR(ROOT + "/agents") {
    }

    void run() {
        createDirectories();
        checkTreeCommand();
        generateMarkdownFile();
        generateTreeFile();
        createBackup();
        copyBackup();
        printSuccess();
    }

private:
    std::string getCurrentTimeLocal() {
        auto now = std::time(nullptr);
        auto tm = *std::localtime(&now);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S %Z");
        return oss.str();
    }

    std::string getCurrentTimeUTC() {
        auto now = std::time(nullptr);
        auto tm = *std::gmtime(&now);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
        return oss.str();
    }

    std::string getHostname() {
        char buffer[256];
        if (gethostname(buffer, sizeof(buffer)) == 0) {
            return std::string(buffer);
        }
        return "unknown";
    }

    void createDirectories() {
        fs::create_directories(OUT_DIR);
        fs::create_directories(TRANSFER_DIR);
    }

    void checkTreeCommand() {
        if (system("which tree > /dev/null 2>&1") != 0) {
            std::cerr << "Fehler: 'tree' ist nicht installiert." << std::endl;
            exit(1);
        }
    }

    void appendFileVerbatim(std::ofstream& mdFile, const std::string& label, 
                           const std::string& path, const std::string& lang = "text") {
        mdFile << std::endl;
        mdFile << "## " << label << std::endl;
        mdFile << std::endl;
        mdFile << "Pfad: `" << path << "`" << std::endl;
        mdFile << std::endl;
        mdFile << "```" << lang << std::endl;
        
        if (fs::exists(path)) {
            std::ifstream file(path);
            if (file.is_open()) {
                std::string line;
                while (std::getline(file, line)) {
                    mdFile << line << std::endl;
                }
            }
        } else {
            mdFile << "[FEHLT] " << path << std::endl;
        }
        
        mdFile << std::endl;
        mdFile << "```" << std::endl;
    }

    void appendEnvVerbatim(std::ofstream& mdFile) {
        mdFile << std::endl;
        mdFile << "## Umgebungsvariablen (env)" << std::endl;
        mdFile << std::endl;
        mdFile << "```text" << std::endl;
        
        // Get environment variables
        for (char** env = environ; *env != nullptr; ++env) {
            mdFile << *env << std::endl;
        }
        
        mdFile << "```" << std::endl;
    }

    void appendDirFilesVerbatim(std::ofstream& mdFile, const std::string& section, 
                               const std::string& dir) {
        mdFile << std::endl;
        mdFile << "## " << section << std::endl;
        mdFile << std::endl;
        
        if (!fs::exists(dir) || !fs::is_directory(dir)) {
            mdFile << "[FEHLT] " << dir << std::endl;
            return;
        }
        
        mdFile << "Basisverzeichnis: `" << dir << "`" << std::endl;

        std::vector<std::string> files;
        for (const auto& entry : fs::recursive_directory_iterator(dir)) {
            if (fs::is_regular_file(entry)) {
                files.push_back(entry.path().string());
            }
        }
        
        std::sort(files.begin(), files.end());
        
        for (const auto& file : files) {
            mdFile << std::endl;
            mdFile << "### Datei: `" << file << "`" << std::endl;
            mdFile << std::endl;
            mdFile << "```text" << std::endl;
            
            std::ifstream f(file);
            if (f.is_open()) {
                std::string line;
                while (std::getline(f, line)) {
                    mdFile << line << std::endl;
                }
            }
            
            mdFile << std::endl;
            mdFile << "```" << std::endl;
        }
    }

    void generateMarkdownFile() {
        std::ofstream mdFile(MD_FILE);
        if (!mdFile.is_open()) {
            throw std::runtime_error("Cannot create markdown file");
        }

        mdFile << "# Lokaler Gateway-Konfigurationsstand" << std::endl;
        mdFile << std::endl;
        mdFile << "Generiert: " << NOW_LOCAL << std::endl;
        mdFile << "UTC: " << NOW_UTC << std::endl;
        mdFile << "Host: " << HOST << std::endl;
        mdFile << std::endl;
        mdFile << "Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten." << std::endl;

        appendFileVerbatim(mdFile, "openclaw.json", OPENCLAW_JSON, "json");
        appendFileVerbatim(mdFile, "exec-approvals.json", EXEC_APPROVALS_JSON, "json");
        appendFileVerbatim(mdFile, "gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv");
        appendFileVerbatim(mdFile, ".env", DOT_ENV, "dotenv");
        appendEnvVerbatim(mdFile);
        appendDirFilesVerbatim(mdFile, ".config (alle Dateien rekursiv)", CONFIG_DIR);
        appendDirFilesVerbatim(mdFile, "agents (alle Dateien rekursiv)", AGENTS_DIR);
    }

    void generateTreeFile() {
        std::string command = "tree -a -L 6 \"" + ROOT + "\" > \"" + TREE_FILE + "\"";
        if (system(command.c_str()) != 0) {
            throw std::runtime_error("Failed to execute tree command");
        }
    }

    void createBackup() {
        std::string command = "openclaw backup create --output \"" + BACKUP_FILE + "\" --verify";
        if (system(command.c_str()) != 0) {
            throw std::runtime_error("Failed to create backup");
        }
    }

    void copyBackup() {
        fs::copy_file(BACKUP_FILE, OUT_DIR + "/" + fs::path(BACKUP_FILE).filename().string(),
                      fs::copy_options::overwrite_existing);
    }

    void printSuccess() {
        std::cout << "OK" << std::endl;
        std::cout << "Erzeugt:" << std::endl;
        std::cout << "- " << MD_FILE << std::endl;
        std::cout << "- " << TREE_FILE << std::endl;
        std::cout << "- " << BACKUP_FILE << std::endl;
        std::cout << "- " << TRANSFER_DIR << " (leer)" << std::endl;
    }
};

// External declaration for environ
extern char **environ;

int main() {
    try {
        CollectCompareBundle app;
        app.run();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
