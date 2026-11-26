// abstraction-provenance: {"artifact_sha256": "1d2178d7da937bf29d5c453ee1c8d21f8e38262e6abe72d1a9d82a9284c51973", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "c"}
// openclaw-node-autostart-termux.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <fcntl.h>

#define SESSION "openclaw-node"
#define LOGFILE "%s/.openclaw/node.log"
#define GATEWAY "10.10.0.1"
#define PORT "18789"

void log_message(const char *message) {
    char log_path[256];
    char timestamp[64];
    time_t now;
    struct tm *timeinfo;
    
    snprintf(log_path, sizeof(log_path), LOGFILE, getenv("HOME"));
    
    FILE *log_file = fopen(log_path, "a");
    if (log_file == NULL) {
        return;
    }
    
    time(&now);
    timeinfo = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "[%Y-%m-%d %H:%M:%S]", timeinfo);
    
    fprintf(log_file, "%s %s\n", timestamp, message);
    fclose(log_file);
}

int session_exists() {
    // Prüfe ob tmux Session existiert (vereinfacht durch ps Befehl)
    char command[256];
    snprintf(command, sizeof(command), "pgrep -f \"tmux.*%s\" > /dev/null 2>&1", SESSION);
    return system(command) == 0;
}

int ping_gateway(const char *gateway) {
    char command[256];
    snprintf(command, sizeof(command), "ping -c 1 -W 3 %s > /dev/null 2>&1", gateway);
    return system(command) == 0;
}

void create_tmux_session() {
    char command[1024];
    char full_command[2048];
    
    snprintf(command, sizeof(command),
        "while true; do "
        "echo \"[$(date)] Starting OpenClaw Node Mode...\" | tee -a '%s/.openclaw/node.log'; "
        "if ! ping -c 1 -W 3 %s > /dev/null 2>&1; then "
        "echo \"[$(date)] FEHLER: WireGuard Gateway %s nicht erreichbar!\" | tee -a '%s/.openclaw/node.log'; "
        "echo \"[$(date)] Warte 10 Sekunden...\" | tee -a '%s/.openclaw/node.log'; "
        "sleep 10; "
        "continue; "
        "fi; "
        "openclaw node run --host %s --port %s 2>&1 | tee -a '%s/.openclaw/node.log'; "
        "echo \"[$(date)] OpenClaw beendet. Neustart in 5 Sekunden...\" | tee -a '%s/.openclaw/node.log'; "
        "sleep 5; "
        "done",
        getenv("HOME"), GATEWAY, GATEWAY, getenv("HOME"), 
        getenv("HOME"), GATEWAY, PORT, getenv("HOME"), getenv("HOME"));
    
    snprintf(full_command, sizeof(full_command), 
        "tmux new-session -d -s \"%s\" -n \"node\" \"%s\"", SESSION, command);
    
    system(full_command);
}

int main() {
    char log_dir[256];
    char message[512];
    
    // Log-Verzeichnis erstellen
    snprintf(log_dir, sizeof(log_dir), "%s/.openclaw", getenv("HOME"));
    mkdir(log_dir, 0755);
    
    // Prüfen ob Session bereits läuft
    if (session_exists()) {
        snprintf(message, sizeof(message), 
                "OpenClaw Node läuft bereits in tmux Session '%s'", SESSION);
        log_message(message);
        return 0;
    }
    
    // Neue tmux Session erstellen und OpenClaw starten
    create_tmux_session();
    
    snprintf(message, sizeof(message), 
            "OpenClaw Node Autostart aktiviert (tmux Session: %s)", SESSION);
    log_message(message);
    
    // Optional: tmux attach Hinweis falls interaktiv gestartet
    if (isatty(STDOUT_FILENO)) {
        printf("OpenClaw Node Mode gestartet in tmux Session '%s'\n", SESSION);
        printf("Zum Anschauen: tmux attach -t %s\n", SESSION);
        printf("Log-Datei: %s/.openclaw/node.log\n", getenv("HOME"));
    }
    
    return 0;
}
