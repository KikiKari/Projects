// abstraction-provenance: {"artifact_sha256": "e477b43848edc911c9481a4620d3ce9892ae01e34a75ff9f8b417f1806878849", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "c"}
// db_maintainer.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <openssl/md5.h>
#include <jansson.h>

#define WORKSPACE "/home/openclaw/.openclaw/workspace"
#define DB_DIR WORKSPACE "/db"
#define BACKUP_DIR DB_DIR "/backups"
#define LOG_DIR WORKSPACE "/logs/db-maintainer"
#define IMPORTANT_DIR WORKSPACE "/important"

#define STATE_FILE DB_DIR "/maintainer_state.json"
#define RETENTION_DAYS 3

typedef struct {
    char log_file[256];
} Logger;

typedef struct {
    time_t last_check;
    time_t last_backup;
    time_t last_tree_update;
    json_t *file_hashes;
} MaintainerState;

void logger_init(Logger* logger) {
    time_t now = time(NULL);
    struct tm *tm_now = localtime(&now);
    strftime(logger->log_file, sizeof(logger->log_file), LOG_DIR "/%Y-%m-%d.log", tm_now);
}

void logger_log(Logger* logger, const char* level, const char* message) {
    time_t now = time(NULL);
    struct tm *tm_now = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_now);
    
    char line[1024];
    snprintf(line, sizeof(line), "[%s] [%s] %s\n", timestamp, level, message);
    printf("%s", line);
    
    FILE* f = fopen(logger->log_file, "a");
    if (f) {
        fputs(line, f);
        fclose(f);
    }
}

void logger_info(Logger* logger, const char* msg) { logger_log(logger, "INFO", msg); }
void logger_warn(Logger* logger, const char* msg) { logger_log(logger, "WARN", msg); }
void logger_error(Logger* logger, const char* msg) { logger_log(logger, "ERROR", msg); }

void ensure_directories() {
    mkdir(BACKUP_DIR, 0755);
    mkdir(LOG_DIR, 0755);
}

char* get_file_hash(const char* filepath) {
    FILE* file = fopen(filepath, "rb");
    if (!file) return NULL;
    
    MD5_CTX ctx;
    MD5_Init(&ctx);
    
    unsigned char buffer[8192];
    size_t bytes;
    while ((bytes = fread(buffer, 1, sizeof(buffer), file)) > 0) {
        MD5_Update(&ctx, buffer, bytes);
    }
    fclose(file);
    
    unsigned char digest[MD5_DIGEST_LENGTH];
    MD5_Final(digest, &ctx);
    
    char* hash = malloc(33);
    for (int i = 0; i < MD5_DIGEST_LENGTH; i++) {
        sprintf(hash + (i * 2), "%02x", digest[i]);
    }
    hash[32] = '\0';
    
    return hash;
}

char* run_tree_command(Logger* logger) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "tree -a -L 8 %s 2>/dev/null", WORKSPACE);
    
    FILE* pipe = popen(cmd, "r");
    if (!pipe) {
        logger_error(logger, "Failed to run tree command");
        return NULL;
    }
    
    char* output = malloc(65536);
    size_t len = 0;
    char buffer[4096];
    
    while (fgets(buffer, sizeof(buffer), pipe)) {
        size_t buf_len = strlen(buffer);
        if (len + buf_len >= 65535) break;
        strcpy(output + len, buffer);
        len += buf_len;
    }
    output[len] = '\0';
    
    int status = pclose(pipe);
    if (status == 0) {
        logger_info(logger, "tree -a -L 8 executed successfully");
        return output;
    } else {
        logger_error(logger, "tree command failed");
        free(output);
        return NULL;
    }
}

int update_tree_file(Logger* logger, const char* tree_output) {
    if (!tree_output) return 0;
    
    char filepath[512];
    snprintf(filepath, sizeof(filepath), IMPORTANT_DIR "/openclaw-tree.txt");
    
    FILE* f = fopen(filepath, "w");
    if (!f) {
        logger_error(logger, "Failed to write openclaw-tree.txt");
        return 0;
    }
    
    time_t now = time(NULL);
    struct tm *tm_now = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%S", tm_now);
    
    fprintf(f, "# OpenClaw Workspace Tree\n");
    fprintf(f, "# Generated: %s\n", timestamp);
    fprintf(f, "# Command: tree -a -L 8 %s\n", WORKSPACE);
    fprintf(f, "# This file is automatically updated by db-maintainer\n\n");
    fprintf(f, "%s", tree_output);
    
    fclose(f);
    logger_info(logger, "openclaw-tree.txt updated");
    return 1;
}

json_t* scan_documentations(Logger* logger) {
    json_t* docs = json_array();
    
    // Simple implementation scanning only top-level .md files
    DIR* dir = opendir(WORKSPACE);
    if (!dir) return docs;
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, ".md")) {
            char filepath[512];
            snprintf(filepath, sizeof(filepath), WORKSPACE "/%s", entry->d_name);
            
            char* hash = get_file_hash(filepath);
            if (hash) {
                json_t* doc = json_object();
                json_object_set_new(doc, "path", json_string(entry->d_name));
                json_object_set_new(doc, "hash", json_string(hash));
                json_array_append_new(docs, doc);
                free(hash);
            }
        }
    }
    closedir(dir);
    
    return docs;
}

MaintainerState load_state() {
    MaintainerState state = {0, 0, 0, NULL};
    
    FILE* f = fopen(STATE_FILE, "r");
    if (!f) return state;
    
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    char* content = malloc(fsize + 1);
    fread(content, 1, fsize, f);
    content[fsize] = '\0';
    
    json_error_t error;
    json_t* root = json_loads(content, 0, &error);
    free(content);
    
    if (!root) {
        fclose(f);
        return state;
    }
    
    json_t* val;
    if ((val = json_object_get(root, "last_check"))) {
        const char* str = json_string_value(val);
        if (str) state.last_check = strtotime(str);
    }
    if ((val = json_object_get(root, "last_backup"))) {
        const char* str = json_string_value(val);
        if (str) state.last_backup = strtotime(str);
    }
    if ((val = json_object_get(root, "last_tree_update"))) {
        const char* str = json_string_value(val);
        if (str) state.last_tree_update = strtotime(str);
    }
    if ((val = json_object_get(root, "file_hashes"))) {
        state.file_hashes = json_incref(val);
    }
    
    json_decref(root);
    fclose(f);
    return state;
}

void save_state(MaintainerState* state) {
    json_t* root = json_object();
    
    char time_str[64];
    if (state->last_check) {
        strftime(time_str, sizeof(time_str), "%Y-%m-%dT%H:%M:%S", localtime(&state->last_check));
        json_object_set_new(root, "last_check", json_string(time_str));
    }
    if (state->last_backup) {
        strftime(time_str, sizeof(time_str), "%Y-%m-%dT%H:%M:%S", localtime(&state->last_backup));
        json_object_set_new(root, "last_backup", json_string(time_str));
    }
    if (state->last_tree_update) {
        strftime(time_str, sizeof(time_str), "%Y-%m-%dT%H:%M:%S", localtime(&state->last_tree_update));
        json_object_set_new(root, "last_tree_update", json_string(time_str));
    }
    if (state->file_hashes) {
        json_object_set(root, "file_hashes", state->file_hashes);
    }
    
    FILE* f = fopen(STATE_FILE, "w");
    if (f) {
        char* dump = json_dumps(root, JSON_INDENT(2));
        fputs(dump, f);
        fclose(f);
        free(dump);
    }
    
    json_decref(root);
}

int update_databases(Logger* logger) {
    int result = system("python3 " WORKSPACE "/scripts/update_docs_db.py >/dev/null 2>&1");
    if (result == 0) {
        logger_info(logger, "docs.db updated");
        return 1;
    } else {
        logger_error(logger, "DB update failed");
        return 0;
    }
}

int update_tree_db_v2(Logger* logger) {
    int result = system("python3 " WORKSPACE "/scripts/tree_indexer_v2.py >/dev/null 2>&1");
    if (result == 0) {
        logger_info(logger, "tree.db v2 updated");
        return 1;
    } else {
        logger_error(logger, "Tree-DB v2 failed");
        return 0;
    }
}

char* create_backup(Logger* logger) {
    static char timestamp[32];
    time_t now = time(NULL);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d_%H-%M", localtime(&now));
    
    char source[256], dest[256];
    snprintf(source, sizeof(source), DB_DIR "/docs.db");
    snprintf(dest, sizeof(dest), BACKUP_DIR "/%s_docs.db.bak", timestamp);
    
    if (access(source, F_OK) == 0) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s\"", source, dest);
        system(cmd);
        logger_info(logger, "Backup created: docs.db");
    }
    
    snprintf(source, sizeof(source), DB_DIR "/tree.db");
    snprintf(dest, sizeof(dest), BACKUP_DIR "/%s_tree.db.bak", timestamp);
    
    if (access(source, F_OK) == 0) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s\"", source, dest);
        system(cmd);
        logger_info(logger, "Backup created: tree.db");
    }
    
    return timestamp;
}

void cleanup_old_backups(Logger* logger) {
    time_t cutoff = time(NULL) - (RETENTION_DAYS * 24 * 60 * 60);
    int deleted = 0;
    
    DIR* dir = opendir(BACKUP_DIR);
    if (!dir) return;
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, ".bak")) {
            char filepath[512];
            snprintf(filepath, sizeof(filepath), BACKUP_DIR "/%s", entry->d_name);
            
            struct stat st;
            if (stat(filepath, &st) == 0 && st.st_mtime < cutoff) {
                unlink(filepath);
                deleted++;
                char msg[256];
                snprintf(msg, sizeof(msg), "Deleted old backup: %s", entry->d_name);
                logger_info(logger, msg);
            }
        }
    }
    closedir(dir);
    
    if (deleted == 0) {
        logger_info(logger, "No old backups to delete");
    } else {
        char msg[64];
        snprintf(msg, sizeof(msg), "%d old backups deleted (< 3 days)", deleted);
        logger_info(logger, msg);
    }
}

void run_cycle(Logger* logger) {
    logger_info(logger, "============================================================");
    logger_info(logger, "DB MAINTAINER CYCLE START");
    logger_info(logger, "============================================================");
    
    MaintainerState state = load_state();
    
    // 1. Run tree command and update file
    logger_info(logger, "Running tree -a -L 8...");
    char* tree_output = run_tree_command(logger);
    if (tree_output) {
        update_tree_file(logger, tree_output);
        state.last_tree_update = time(NULL);
        free(tree_output);
    }
    
    // 2. Update tree.db v2
    logger_info(logger, "Updating tree.db v2...");
    update_tree_db_v2(logger);
    
    // 3. Check for changes
    logger_info(logger, "Checking for documentation changes...");
    json_t* current_docs = scan_documentations(logger);
    
    // Simplified change detection
    int has_changes = json_array_size(current_docs) > 0;
    if (has_changes) {
        char msg[64];
        snprintf(msg, sizeof(msg), "%ld changes found", json_array_size(current_docs));
        logger_info(logger, msg);
        
        // 4. Update docs.db
        logger_info(logger, "Updating docs.db...");
        if (update_databases(logger)) {
            state.last_check = time(NULL);
        }
    } else {
        logger_info(logger, "No documentation changes found");
    }
    
    json_decref(current_docs);
    
    // 5. Check if backup needed (hourly)
    int do_backup = 0;
    if (state.last_backup == 0) {
        do_backup = 1;
    } else {
        time_t now = time(NULL);
        if (difftime(now, state.last_backup) >= 3600) {
            do_backup = 1;
        }
    }
    
    if (do_backup) {
        logger_info(logger, "Creating hourly backup...");
        create_backup(logger);
        state.last_backup = time(NULL);
        
        // 6. Cleanup old backups
        logger_info(logger, "Cleaning up old backups (3 day retention)...");
        cleanup_old_backups(logger);
    } else {
        logger_info(logger, "Backup not needed (last < 1h)");
    }
    
    save_state(&state);
    
    logger_info(logger, "============================================================");
    logger_info(logger, "DB MAINTAINER CYCLE END");
    logger_info(logger, "============================================================");
}

int main() {
    ensure_directories();
    
    Logger logger;
    logger_init(&logger);
    
    run_cycle(&logger);
    
    return 0;
}
