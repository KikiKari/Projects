// abstraction-provenance: {"artifact_sha256": "c62d60ff2a8c763a7c9ee829fd1abdb4fe67bebd91d9d8a746bb099e7d86e161", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "c"}
// openclaw-maintenance.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_CMD_LEN 1024

// Funktion zum Ausführen eines Kommandos
int execute_command(const char* cmd) {
    printf("Executing: %s\n", cmd);
    int result = system(cmd);
    if (result != 0) {
        fprintf(stderr, "Command failed with exit code %d: %s\n", result, cmd);
        return result;
    }
    return 0;
}

// Funktion zum Ausführen eines Openclaw-Kommandos
int run_openclaw(const char* args) {
    char cmd[MAX_CMD_LEN];
    snprintf(cmd, sizeof(cmd), "openclaw %s", args);
    return execute_command(cmd);
}

int main() {
    int result = 0;
    
    // === 1. Service-/Config-Drift ===
    printf("# === 1. Service-/Config-Drift ===\n");
    result = run_openclaw("doctor");
    if (result != 0) return result;
    
    // === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
    printf("\n# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===\n");
    result = run_openclaw("plugins registry --refresh");
    if (result != 0) return result;
    
    result = run_openclaw("plugins update --all");
    if (result != 0) return result;
    
    // === 3. Tasks ===
    printf("\n# === 3. Tasks ===\n");
    result = run_openclaw("tasks maintenance --apply");
    if (result != 0) return result;
    
    // === 4. Sessions – alle Agents auf einmal ===
    printf("\n# === 4. Sessions – alle Agents auf einmal ===\n");
    result = run_openclaw("sessions cleanup --enforce --all-agents");
    if (result != 0) return result;
    
    // === 5. Memory – status/index decken alle Agents ab ===
    printf("\n# === 5. Memory – status/index decken alle Agents ab ===\n");
    result = run_openclaw("memory status --deep --fix");
    if (result != 0) return result;
    
    result = run_openclaw("memory index --force");
    if (result != 0) return result;
    
    // === 6. Memory promote – MUSS pro Agent ===
    printf("\n# === 6. Memory promote – MUSS pro Agent ===\n");
    const char* agents[] = {"main", "knecht", "docs", "ops-hub", "cron"};
    int num_agents = sizeof(agents) / sizeof(agents[0]);
    
    for (int i = 0; i < num_agents; i++) {
        char cmd[MAX_CMD_LEN];
        snprintf(cmd, sizeof(cmd), "memory promote --apply --agent \"%s\"", agents[i]);
        result = run_openclaw(cmd);
        if (result != 0) return result;
    }
    
    // === 7. Secrets ===
    printf("\n# === 7. Secrets ===\n");
    result = run_openclaw("secrets reload");
    if (result != 0) return result;
    
    printf("\nAll maintenance tasks completed successfully.\n");
    return 0;
}
