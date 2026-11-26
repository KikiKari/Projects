// abstraction-provenance: {"artifact_sha256": "19aaa231f46e9d00d45cbbdd6281c97044c4885aa107892580e8f18e05940e43", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "c"}
// openclaw-audit.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/utsname.h>

#define MAX_CMD_LEN 1024
#define MAX_PATH_LEN 1024

void get_date_stamp(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm *tm_now = localtime(&now);
    strftime(buffer, size, "%Y-%m-%d", tm_now);
}

void get_iso_timestamp(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm *tm_now = localtime(&now);
    strftime(buffer, size, "%Y-%m-%dT%H:%M:%S%z", tm_now);
}

void get_hostname(char *buffer, size_t size) {
    if (gethostname(buffer, size) != 0) {
        strcpy(buffer, "unknown");
    }
}

void run_cmd(const char *title, const char *cmd, FILE *out_file) {
    char timestamp[64];
    int rc;
    
    fprintf(out_file, "\n");
    fprintf(out_file, "----------------------------------------------------------------\n");
    fprintf(out_file, "### %s\n", title);
    fprintf(out_file, "### $ %s\n", cmd);
    get_iso_timestamp(timestamp, sizeof(timestamp));
    fprintf(out_file, "### %s\n", timestamp);
    fprintf(out_file, "----------------------------------------------------------------\n");
    
    rc = system(cmd);
    if (rc == -1) {
        rc = 127; // command not found
    } else if (WIFEXITED(rc)) {
        rc = WEXITSTATUS(rc);
    } else {
        rc = 1; // abnormal termination
    }
    
    fprintf(out_file, "[exit: %d]\n", rc);
}

int main(int argc, char *argv[]) {
    char script_dir[MAX_PATH_LEN];
    char date_stamp[32];
    char out_path[MAX_PATH_LEN];
    char hostname[256];
    char username[256];
    char timestamp[64];
    FILE *out_file;
    char cmd_buffer[MAX_CMD_LEN];
    
    // Get script directory (use current working directory)
    if (getcwd(script_dir, sizeof(script_dir)) == NULL) {
        strcpy(script_dir, ".");
    }
    
    // Get date stamp
    get_date_stamp(date_stamp, sizeof(date_stamp));
    
    // Build output path
    snprintf(out_path, sizeof(out_path), "%s/openclaw-audit-%s.log", script_dir, date_stamp);
    
    // Open output file
    out_file = fopen(out_path, "w");
    if (!out_file) {
        perror("Failed to open output file");
        return 1;
    }
    
    // Get system information
    get_hostname(hostname, sizeof(hostname));
    if (getlogin_r(username, sizeof(username)) != 0) {
        strcpy(username, "unknown");
    }
    
    // Write header
    fprintf(out_file, "================================================================\n");
    fprintf(out_file, "OpenClaw audit run\n");
    fprintf(out_file, "Started:  ");
    get_iso_timestamp(timestamp, sizeof(timestamp));
    fprintf(out_file, "%s\n", timestamp);
    fprintf(out_file, "Host:     %s\n", hostname);
    fprintf(out_file, "User:     %s\n", username);
    fprintf(out_file, "Version:  ");
    fflush(out_file);
    if (system("openclaw --version >/dev/null 2>&1") == 0) {
        system("openclaw --version 2>/dev/null");
    } else {
        fprintf(out_file, "unknown\n");
    }
    fprintf(out_file, "Output:   %s\n", out_path);
    fprintf(out_file, "================================================================\n");
    
    // Run all commands
    run_cmd("tasks audit --severity error", "openclaw --no-color tasks audit --severity error", out_file);
    run_cmd("secrets audit", "openclaw --no-color secrets audit", out_file);
    run_cmd("security audit", "openclaw --no-color security audit", out_file);
    run_cmd("plugins doctor", "openclaw --no-color plugins doctor", out_file);
    run_cmd("plugins deps", "openclaw --no-color plugins deps", out_file);
    run_cmd("plugins registry", "openclaw --no-color plugins registry", out_file);
    run_cmd("skills check", "openclaw --no-color skills check", out_file);
    run_cmd("hooks check", "openclaw --no-color hooks check", out_file);
    run_cmd("gateway status --deep", "openclaw --no-color gateway status --deep", out_file);
    run_cmd("channels status --probe", "openclaw --no-color channels status --probe", out_file);
    run_cmd("memory status --deep", "openclaw --no-color memory status --deep", out_file);
    run_cmd("sessions --all-agents", "openclaw --no-color sessions --all-agents", out_file);
    run_cmd("tasks list", "openclaw --no-color tasks list", out_file);
    run_cmd("cron list", "openclaw --no-color cron list", out_file);
    
    // Write footer
    fprintf(out_file, "\n");
    fprintf(out_file, "================================================================\n");
    fprintf(out_file, "Audit complete: ");
    get_iso_timestamp(timestamp, sizeof(timestamp));
    fprintf(out_file, "%s\n", timestamp);
    fprintf(out_file, "================================================================\n");
    
    fclose(out_file);
    
    printf("Audit complete. Output: %s\n", out_path);
    
    return 0;
}
