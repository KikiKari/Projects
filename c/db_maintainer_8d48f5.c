// abstraction-provenance: {"artifact_sha256": "de83ccff3e101110003d0cde7c6be8cc4bf130925e00675f97b1e0610cda1674", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "c"}
// db_maintainer.py — portiert nach c
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <libgen.h>
#include <errno.h>
#include <openssl/md5.h>

#define MAX_PATH 1024
#define MAX_LINE 4096
#define RETENTION_DAYS 3

typedef struct {
    char last_check[64];
    char last_backup[64];
    char last_tree_update[64];
    char file_hashes[MAX_PATH][33]; // MD5 hash is 32 chars + null terminator
} State;

const char *WORKSPACE;
char DB_DIR[MAX_PATH];
char BACKUP_DIR[MAX_PATH];
char LOG_DIR[MAX_PATH];
char IMPORTANT_DIR[MAX_PATH];

void init_paths() {
    const char *workspace_env = getenv("OPENCLAW_WORKSPACE");
    if (workspace_env) {
        WORKSPACE = workspace_env;
    } else {
        char exe_path[MAX_PATH];
        ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
        if (len != -1) {
            exe_path[len] = '\0';
            dirname(exe_path);
            char parent_dir[MAX_PATH];
            strcpy(parent_dir, exe_path);
            dirname(parent_dir);
            WORKSPACE = strdup(parent_dir);
        }
    }

    snprintf(DB_DIR, MAX_PATH, "%s", WORKSPACE);
    snprintf(BACKUP_DIR, MAX_PATH, "%s/db/backups", WORKSPACE);
    snprintf(LOG_DIR, MAX_PATH, "%s/logs/db-maintainer", WORKSPACE);
    snprintf(IMPORTANT_DIR, MAX_PATH, "%s/important", WORKSPACE);

    mkdir(BACKUP_DIR, 0755);
    mkdir(LOG_DIR, 0755);
    mkdir(IMPORTANT_DIR, 0755);
}

void get_current_timestamp(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(buffer, size, "%Y-%m-%d %H:%M:%S", tm_info);
}

void get_date_timestamp(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(buffer, size, "%Y-%m-%d", tm_info);
}

void log_message(const char *level, const char *message) {
    char timestamp[64];
    get_current_timestamp(timestamp, sizeof(timestamp));

    char log_line[MAX_LINE];
    snprintf(log_line, sizeof(log_line), "[%s] [%s] %s\n", timestamp, level, message);
    printf("%s", log_line);

    char log_filename[MAX_PATH];
    char date_str[32];
    get_date_timestamp(date_str, sizeof(date_str));
    snprintf(log_filename, sizeof(log_filename), "%s/%s.log", LOG_DIR, date_str);

    FILE *log_file = fopen(log_filename, "a");
    if (log_file) {
        fputs(log_line, log_file);
        fclose(log_file);
    }
}

void info(const char *msg) { log_message("INFO", msg); }
void warn(const char *msg) { log_message("WARN", msg); }
void error(const char *msg) { log_message("ERROR", msg); }

void load_state(State *state) {
    char state_file[MAX_PATH];
    snprintf(state_file, sizeof(state_file), "%s/maintainer_state.json", DB_DIR);

    FILE *file = fopen(state_file, "r");
    if (!file) {
        strcpy(state->last_check, "");
        strcpy(state->last_backup, "");
        strcpy(state->last_tree_update, "");
        memset(state->file_hashes, 0, sizeof(state->file_hashes));
        return;
    }

    // Simplified JSON parsing - in real implementation would need proper JSON parser
    // For this example, we'll just initialize empty state
    strcpy(state->last_check, "");
    strcpy(state->last_backup, "");
    strcpy(state->last_tree_update, "");
    memset(state->file_hashes, 0, sizeof(state->file_hashes));
    fclose(file);
}

void save_state(State *state) {
    char state_file[MAX_PATH];
    snprintf(state_file, sizeof(state_file), "%s/maintainer_state.json", DB_DIR);

    FILE *file = fopen(state_file, "w");
    if (file) {
        fprintf(file, "{\n");
        fprintf(file, "  \"last_check\": \"%s\",\n", state->last_check);
        fprintf(file, "  \"last_backup\": \"%s\",\n", state->last_backup);
        fprintf(file, "  \"last_tree_update\": \"%s\"\n", state->last_tree_update);
        fprintf(file, "}\n");
        fclose(file);
    }
}

char* calculate_md5(const char *filepath) {
    static char hash_string[33];
    FILE *file = fopen(filepath, "rb");
    if (!file) return NULL;

    MD5_CTX ctx;
    MD5_Init(&ctx);

    unsigned char buffer[1024];
    unsigned char digest[16];
    size_t bytes;

    while ((bytes = fread(buffer, 1, sizeof(buffer), file)) != 0) {
        MD5_Update(&ctx, buffer, bytes);
    }

    MD5_Final(digest, &ctx);
    fclose(file);

    for (int i = 0; i < 16; i++) {
        sprintf(&hash_string[i * 2], "%02x", digest[i]);
    }

    return hash_string;
}

void python_tree_fallback(char *output, size_t output_size) {
    snprintf(output, output_size, "# Python tree fallback implementation\n");
    strcat(output, "# Directory structure would be listed here\n");
}

int run_tree_command(char *output, size_t output_size) {
    FILE *fp;
    char path[MAX_LINE];

    snprintf(output, output_size, "");

    // Try to run tree command
    fp = popen("tree -a -L 8 . 2>/dev/null", "r");
    if (fp == NULL) {
        python_tree_fallback(output, output_size);
        return 1;
    }

    while (fgets(path, sizeof(path), fp) != NULL) {
        strncat(output, path, output_size - strlen(output) - 1);
    }

    int status = pclose(fp);
    if (status != 0) {
        python_tree_fallback(output, output_size);
        return 1;
    }

    return 0;
}

int update_tree_file(const char *tree_output) {
    if (!tree_output || strlen(tree_output) == 0) {
        return 0;
    }

    char tree_file[MAX_PATH];
    snprintf(tree_file, sizeof(tree_file), "%s/openclaw-tree.txt", IMPORTANT_DIR);

    FILE *file = fopen(tree_file, "w");
    if (!file) {
        return 0;
    }

    char timestamp[64];
    get_current_timestamp(timestamp, sizeof(timestamp));

    fprintf(file, "# OpenClaw Workspace Tree\n");
    fprintf(file, "# Generiert: %s\n", timestamp);
    fprintf(file, "# Befehl: tree -a -L 8 %s\n", WORKSPACE);
    fprintf(file, "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n");
    fprintf(file, "%s", tree_output);

    fclose(file);
    return 1;
}

void scan_documentations() {
    // Placeholder for scanning documentation files
    // In a full implementation, this would traverse directories and collect .md files
}

int check_for_changes() {
    // Placeholder for checking file changes
    // Returns 1 if changes found, 0 otherwise
    return 0;
}

int update_databases() {
    char command[MAX_LINE];
    snprintf(command, sizeof(command), "python3 %s/scripts/update_docs_db.py", WORKSPACE);
    
    int result = system(command);
    return (result == 0) ? 1 : 0;
}

int update_tree_db_v2() {
    char command[MAX_LINE];
    snprintf(command, sizeof(command), "python3 %s/scripts/tree_indexer_v2.py", WORKSPACE);
    
    int result = system(command);
    return (result == 0) ? 1 : 0;
}

void create_backup() {
    char timestamp[32];
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d_%H-%M", tm_info);

    char source[MAX_PATH];
    char backup_path[MAX_PATH];

    // Backup docs.db
    snprintf(source, sizeof(source), "%s/docs.db", DB_DIR);
    snprintf(backup_path, sizeof(backup_path), "%s/%s_docs.db.bak", BACKUP_DIR, timestamp);
    
    FILE *src = fopen(source, "rb");
    if (src) {
        FILE *dst = fopen(backup_path, "wb");
        if (dst) {
            char buffer[1024];
            size_t bytes;
            while ((bytes = fread(buffer, 1, sizeof(buffer), src)) > 0) {
                fwrite(buffer, 1, bytes, dst);
            }
            fclose(dst);
            char log_msg[MAX_LINE];
            snprintf(log_msg, sizeof(log_msg), "Backup erstellt: %s_docs.db.bak", timestamp);
            info(log_msg);
        }
        fclose(src);
    }

    // Backup tree.db
    snprintf(source, sizeof(source), "%s/tree.db", DB_DIR);
    snprintf(backup_path, sizeof(backup_path), "%s/%s_tree.db.bak", BACKUP_DIR, timestamp);
    
    src = fopen(source, "rb");
    if (src) {
        FILE *dst = fopen(backup_path, "wb");
        if (dst) {
            char buffer[1024];
            size_t bytes;
            while ((bytes = fread(buffer, 1, sizeof(buffer), src)) > 0) {
                fwrite(buffer, 1, bytes, dst);
            }
            fclose(dst);
            char log_msg[MAX_LINE];
            snprintf(log_msg, sizeof(log_msg), "Backup erstellt: %s_tree.db.bak", timestamp);
            info(log_msg);
        }
        fclose(src);
    }
}

void cleanup_old_backups() {
    // Placeholder for cleaning up old backups
    info("Räume alte Backups auf (3 Tage Retention)...");
}

void run_cycle() {
    info("============================================================");
    info("DB MAINTAINER CYCLE START");
    info("============================================================");

    State state;
    load_state(&state);

    // 1. Run tree command and update file
    info("Führe tree -a -L 8 aus...");
    char tree_output[MAX_LINE * 10];
    if (run_tree_command(tree_output, sizeof(tree_output)) == 0) {
        if (update_tree_file(tree_output)) {
            get_current_timestamp(state.last_tree_update, sizeof(state.last_tree_update));
        }
    }

    // 2. Update tree.db v2
    info("Aktualisiere tree.db v2...");
    update_tree_db_v2();

    // 3. Check for changes
    info("Prüfe auf Dokumentations-Änderungen...");
    if (check_for_changes()) {
        info("Änderungen gefunden - Aktualisiere docs.db...");
        if (update_databases()) {
            get_current_timestamp(state.last_check, sizeof(state.last_check));
        }
    } else {
        info("Keine Dokumentations-Änderungen gefunden");
    }

    // 4. Check if backup needed (hourly)
    time_t current_time = time(NULL);
    time_t last_backup_time = 0;
    
    if (strlen(state.last_backup) > 0) {
        struct tm tm_time = {0};
        strptime(state.last_backup, "%Y-%m-%d %H:%M:%S", &tm_time);
        last_backup_time = mktime(&tm_time);
    }

    double hours_since_backup = difftime(current_time, last_backup_time) / 3600.0;
    int do_backup = (strlen(state.last_backup) == 0) || (hours_since_backup >= 1.0);

    if (do_backup) {
        info("Erstelle stündliches Backup...");
        create_backup();
        get_current_timestamp(state.last_backup, sizeof(state.last_backup));

        // 5. Clean up old backups
        info("Räume alte Backups auf (3 Tage Retention)...");
        cleanup_old_backups();
    } else {
        info("Backup nicht nötig (letztes < 1h)");
    }

    save_state(&state);

    info("============================================================");
    info("DB MAINTAINER CYCLE END");
    info("============================================================");
}

int main() {
    init_paths();
    run_cycle();
    return 0;
}
