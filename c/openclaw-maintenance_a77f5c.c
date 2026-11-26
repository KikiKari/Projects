// abstraction-provenance: {"artifact_sha256": "44697610bcc5c53968f74751d1d1c3cadaa92ebfa4b759eb740751fe04fa08d6", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "c"}
// openclaw-maintenance.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#define DEFAULT_OPENCLAW_BIN "%s/.local/bin/openclaw", getenv("HOME")

void run_command(const char* command) {
    int result = system(command);
    if (result != 0) {
        fprintf(stderr, "Command failed: %s\n", command);
        exit(1);
    }
}

int file_exists_and_executable(const char* path) {
    struct stat st;
    return (stat(path, &st) == 0) && (st.st_mode & S_IXUSR);
}

int main() {
    char* openclaw_bin_env = getenv("OPENCLAW_BIN");
    char openclaw_bin[1024];
    
    if (openclaw_bin_env != NULL) {
        strcpy(openclaw_bin, openclaw_bin_env);
    } else {
        snprintf(openclaw_bin, sizeof(openclaw_bin), DEFAULT_OPENCLAW_BIN);
    }

    if (!file_exists_and_executable(openclaw_bin)) {
        fprintf(stderr, "ERROR: OpenClaw binary not found: %s\n", openclaw_bin);
        return 1;
    }

    char version_cmd[1024];
    snprintf(version_cmd, sizeof(version_cmd), "%s --version", openclaw_bin);
    printf("Using OpenClaw: ");
    fflush(stdout);
    system(version_cmd);

    // === 1. Service-/Config-Drift ===
    char cmd1[1024];
    snprintf(cmd1, sizeof(cmd1), "%s doctor", openclaw_bin);
    run_command(cmd1);

    // === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
    char cmd2[1024];
    snprintf(cmd2, sizeof(cmd2), "%s plugins registry --refresh", openclaw_bin);
    run_command(cmd2);

    char* run_plugin_update = getenv("RUN_PLUGIN_UPDATE");
    if (run_plugin_update != NULL && strcmp(run_plugin_update, "1") == 0) {
        char cmd3[1024];
        snprintf(cmd3, sizeof(cmd3), "%s plugins update --all", openclaw_bin);
        run_command(cmd3);
    } else {
        printf("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.\n");
    }

    // === 3. Tasks ===
    char cmd4[1024];
    snprintf(cmd4, sizeof(cmd4), "%s tasks maintenance --apply", openclaw_bin);
    run_command(cmd4);

    // === 4. Sessions – alle Agents auf einmal ===
    char cmd5[1024];
    snprintf(cmd5, sizeof(cmd5), "%s sessions cleanup --enforce --all-agents", openclaw_bin);
    run_command(cmd5);

    // === 5. Memory – status/index decken alle Agents ab ===
    char cmd6[1024];
    snprintf(cmd6, sizeof(cmd6), "%s memory status --deep --fix", openclaw_bin);
    run_command(cmd6);

    char cmd7[1024];
    snprintf(cmd7, sizeof(cmd7), "%s memory index --force", openclaw_bin);
    run_command(cmd7);

    // === 6. Memory promote – MUSS pro Agent ===
    const char* agents[] = {"main", "knecht", "docs", "ops-hub", "cron"};
    for (int i = 0; i < 5; i++) {
        char cmd8[1024];
        snprintf(cmd8, sizeof(cmd8), "%s memory promote --apply --agent %s", openclaw_bin, agents[i]);
        run_command(cmd8);
    }

    // === 7. Secrets ===
    char cmd9[1024];
    snprintf(cmd9, sizeof(cmd9), "%s secrets reload", openclaw_bin);
    run_command(cmd9);

    return 0;
}
