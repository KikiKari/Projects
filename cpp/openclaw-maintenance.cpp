// abstraction-provenance: {"artifact_sha256": "9176bd2a88080b933a6a1fc78ff9b986cbecbe04941535bc90b124910f91efdb", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "cpp"}
// openclaw-maintenance.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <cstdlib>
#include <iostream>
#include <vector>
#include <string>

int main() {
    int result = 0;

    // === 1. Service-/Config-Drift ===
    result = std::system("openclaw doctor");
    if (result != 0) return result;

    // === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
    result = std::system("openclaw plugins registry --refresh");
    if (result != 0) return result;
    
    result = std::system("openclaw plugins update --all");
    if (result != 0) return result;

    // === 3. Tasks ===
    result = std::system("openclaw tasks maintenance --apply");
    if (result != 0) return result;

    // === 4. Sessions – alle Agents auf einmal ===
    result = std::system("openclaw sessions cleanup --enforce --all-agents");
    if (result != 0) return result;

    // === 5. Memory – status/index decken alle Agents ab ===
    result = std::system("openclaw memory status --deep --fix");
    if (result != 0) return result;
    
    result = std::system("openclaw memory index --force");
    if (result != 0) return result;

    // === 6. Memory promote – MUSS pro Agent ===
    std::vector<std::string> agents = {"main", "knecht", "docs", "ops-hub", "cron"};
    for (const auto& agent : agents) {
        std::string command = "openclaw memory promote --apply --agent " + agent;
        result = std::system(command.c_str());
        if (result != 0) return result;
    }

    // === 7. Secrets ===
    result = std::system("openclaw secrets reload");
    if (result != 0) return result;

    return 0;
}
