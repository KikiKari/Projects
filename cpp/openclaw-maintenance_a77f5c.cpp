// abstraction-provenance: {"artifact_sha256": "325e69cd41255a9c549ddc038e7a331c77588f8b59225fef7641f0212a19d367", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "cpp"}
// openclaw-maintenance.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <unistd.h>

namespace fs = std::filesystem;

void executeCommand(const std::string& command) {
    int result = std::system(command.c_str());
    if (result != 0) {
        std::cerr << "Command failed: " << command << std::endl;
        std::exit(1);
    }
}

std::string getEnvVar(const std::string& key, const std::string& defaultValue) {
    const char* envValue = std::getenv(key.c_str());
    return envValue ? envValue : defaultValue;
}

bool isExecutable(const std::string& path) {
    return fs::exists(path) && (fs::status(path).permissions() & fs::perms::owner_exec) != fs::perms::none;
}

int main() {
    std::string OPENCLAW_BIN = getEnvVar("OPENCLAW_BIN", 
        (fs::path(std::getenv("HOME")) / ".local/bin/openclaw").string());

    if (!isExecutable(OPENCLAW_BIN)) {
        std::cerr << "ERROR: OpenClaw binary not found: " << OPENCLAW_BIN << std::endl;
        return 1;
    }

    // Display version
    std::cout << "Using OpenClaw: ";
    executeCommand(OPENCLAW_BIN + " --version");

    // === 1. Service-/Config-Drift ===
    executeCommand(OPENCLAW_BIN + " doctor");

    // === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
    executeCommand(OPENCLAW_BIN + " plugins registry --refresh");
    
    std::string runPluginUpdate = getEnvVar("RUN_PLUGIN_UPDATE", "0");
    if (runPluginUpdate == "1") {
        executeCommand(OPENCLAW_BIN + " plugins update --all");
    } else {
        std::cout << "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable." << std::endl;
    }

    // === 3. Tasks ===
    executeCommand(OPENCLAW_BIN + " tasks maintenance --apply");

    // === 4. Sessions – alle Agents auf einmal ===
    executeCommand(OPENCLAW_BIN + " sessions cleanup --enforce --all-agents");

    // === 5. Memory – status/index decken alle Agents ab ===
    executeCommand(OPENCLAW_BIN + " memory status --deep --fix");
    executeCommand(OPENCLAW_BIN + " memory index --force");

    // === 6. Memory promote – MUSS pro Agent ===
    std::vector<std::string> agents = {"main", "knecht", "docs", "ops-hub", "cron"};
    for (const auto& agent : agents) {
        executeCommand(OPENCLAW_BIN + " memory promote --apply --agent " + agent);
    }

    // === 7. Secrets ===
    executeCommand(OPENCLAW_BIN + " secrets reload");

    return 0;
}
