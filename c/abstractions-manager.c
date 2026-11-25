// abstraction-provenance: {"artifact_sha256": "bf1ccdd2e7b82cc3887e8521051463f69023aab079350e270663ba1064880e59", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "c"}
// abstractions-manager.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    // Setze Umgebung und führe das eigentliche Skript aus
    char *const args[argc + 2];
    args[0] = "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh";
    for (int i = 1; i < argc; i++) {
        args[i] = argv[i];
    }
    args[argc] = NULL;

    execv("/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh", args);

    // Wenn execv fehlschlägt
    perror("execv failed");
    return 1;
}
