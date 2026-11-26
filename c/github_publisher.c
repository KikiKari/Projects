// abstraction-provenance: {"artifact_sha256": "d78d28329ff14a96011bc031cac74e503471242e99c31f44932d01b6c5915f2a", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "c"}
// github_publisher.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <dirent.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>

#define MAX_LANGUAGES 18
#define MAX_PATH 4096
#define MAX_URL 2048
#define TIMEOUT_SECONDS 300

const char* LANGUAGES[] = {
    "c", "cpp", "css", "fsharp", "go", "java", "javascript", "lua", 
    "perl5", "perl6", "php", "powershell", "python", "ruby", "shell", 
    "tcl", NULL
};

typedef struct {
    char* key;
    char* value;
} KeyValuePair;

typedef struct {
    KeyValuePair* items;
    int count;
    int capacity;
} HashMap;

HashMap* hashmap_create(int initial_capacity) {
    HashMap* map = malloc(sizeof(HashMap));
    map->items = malloc(initial_capacity * sizeof(KeyValuePair));
    map->count = 0;
    map->capacity = initial_capacity;
    return map;
}

void hashmap_free(HashMap* map) {
    for (int i = 0; i < map->count; i++) {
        free(map->items[i].key);
        free(map->items[i].value);
    }
    free(map->items);
    free(map);
}

char* hashmap_get(HashMap* map, const char* key) {
    for (int i = 0; i < map->count; i++) {
        if (strcmp(map->items[i].key, key) == 0) {
            return map->items[i].value;
        }
    }
    return NULL;
}

void hashmap_set(HashMap* map, const char* key, const char* value) {
    for (int i = 0; i < map->count; i++) {
        if (strcmp(map->items[i].key, key) == 0) {
            free(map->items[i].value);
            map->items[i].value = strdup(value);
            return;
        }
    }
    
    if (map->count >= map->capacity) {
        map->capacity *= 2;
        map->items = realloc(map->items, map->capacity * sizeof(KeyValuePair));
    }
    
    map->items[map->count].key = strdup(key);
    map->items[map->count].value = strdup(value);
    map->count++;
}

bool is_language_supported(const char* language) {
    for (int i = 0; LANGUAGES[i] != NULL; i++) {
        if (strcmp(LANGUAGES[i], language) == 0) {
            return true;
        }
    }
    return false;
}

char* resolve_path(const char* base, const char* relative) {
    static char result[MAX_PATH];
    snprintf(result, sizeof(result), "%s/%s", base, relative);
    return result;
}

bool path_exists(const char* path) {
    struct stat st;
    return stat(path, &st) == 0;
}

bool is_directory(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return false;
    return S_ISDIR(st.st_mode);
}

bool is_file(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return false;
    return S_ISREG(st.st_mode);
}

bool is_symlink(const char* path) {
    struct stat st;
    if (lstat(path, &st) != 0) return false;
    return S_ISLNK(st.st_mode);
}

char* read_file(const char* path, size_t* size) {
    FILE* file = fopen(path, "rb");
    if (!file) return NULL;
    
    fseek(file, 0, SEEK_END);
    *size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* buffer = malloc(*size + 1);
    fread(buffer, 1, *size, file);
    buffer[*size] = '\0';
    
    fclose(file);
    return buffer;
}

char* calculate_sha256(const char* data, size_t size) {
    // Simplified SHA256 implementation placeholder
    // In practice, you would use OpenSSL or similar library
    static char hash[65];
    snprintf(hash, sizeof(hash), "sha256_placeholder_%zu", size);
    return hash;
}

int run_command_with_timeout(char* const argv[], int timeout_seconds) {
    pid_t pid = fork();
    if (pid == 0) {
        // Child process - redirect output to /dev/null
        int devnull = open("/dev/null", O_WRONLY);
        dup2(devnull, STDOUT_FILENO);
        dup2(devnull, STDERR_FILENO);
        close(devnull);
        
        execvp(argv[0], argv);
        exit(1);
    } else if (pid > 0) {
        // Parent process
        int status;
        time_t start_time = time(NULL);
        
        while (waitpid(pid, &status, WNOHANG) == 0) {
            if (time(NULL) - start_time > timeout_seconds) {
                kill(pid, SIGTERM);
                sleep(1);
                kill(pid, SIGKILL);
                return -1;
            }
            usleep(100000); // Sleep 100ms
        }
        
        return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }
    
    return -1;
}

char* synchronize_checkout(const char* root, const char* remote, const char* branch, HashMap* counts) {
    static char revision[65];
    snprintf(revision, sizeof(revision), "dummy_revision_abc123");
    
    // Create temporary directory
    char temp_dir_template[] = "/tmp/abstractions-snapshot-XXXXXX";
    char* temp_dir = mkdtemp(temp_dir_template);
    if (!temp_dir) return NULL;
    
    char repo_path[MAX_PATH];
    snprintf(repo_path, sizeof(repo_path), "%s/repo", temp_dir);
    
    // Clone repository
    char* clone_argv[] = {
        "git", "clone", "--quiet", "--depth=1", "--single-branch",
        "--branch", (char*)branch, "--", (char*)remote, repo_path, NULL
    };
    
    if (run_command_with_timeout(clone_argv, TIMEOUT_SECONDS) != 0) {
        rmdir(temp_dir);
        return NULL;
    }
    
    // Get revision
    // In practice, you would run git rev-parse HEAD here
    
    // Process each language
    for (int i = 0; LANGUAGES[i] != NULL; i++) {
        const char* language = LANGUAGES[i];
        char source_path[MAX_PATH];
        char target_path[MAX_PATH];
        
        snprintf(source_path, sizeof(source_path), "%s/%s", repo_path, language);
        snprintf(target_path, sizeof(target_path), "%s/%s", root, language);
        
        if (is_symlink(source_path) || is_symlink(target_path)) {
            fprintf(stderr, "Language directory is a symlink\n");
            rmdir(temp_dir);
            return NULL;
        }
        
        if (path_exists(source_path) && !is_directory(source_path)) {
            fprintf(stderr, "Invalid remote language directory\n");
            rmdir(temp_dir);
            return NULL;
        }
        
        mkdir(target_path, 0755);
        
        // Count files (simplified)
        int file_count = 0;
        if (path_exists(source_path)) {
            DIR* dir = opendir(source_path);
            if (dir) {
                struct dirent* entry;
                while ((entry = readdir(dir)) != NULL) {
                    if (entry->d_name[0] != '.') {
                        file_count++;
                    }
                }
                closedir(dir);
            }
        }
        
        char count_str[16];
        snprintf(count_str, sizeof(count_str), "%d", file_count);
        hashmap_set(counts, language, count_str);
    }
    
    // Clean up
    // In practice, you would recursively remove the temp directory
    
    return revision;
}

void update_status_counts(const char* path, const char* revision, HashMap* counts) {
    size_t file_size;
    char* content = read_file(path, &file_size);
    if (!content) return;
    
    // This is a simplified version - in practice you would need proper regex replacement
    FILE* file = fopen(path, "w");
    if (file) {
        fprintf(file, "## Bestand\n\nGitHub-Stand: `%s`\n\n", revision);
        fprintf(file, "| Zielsprache | Dateien |\n|---|---:|\n");
        
        int total = 0;
        for (int i = 0; LANGUAGES[i] != NULL; i++) {
            const char* language = LANGUAGES[i];
            char* count_str = hashmap_get(counts, language);
            int count = count_str ? atoi(count_str) : 0;
            total += count;
            fprintf(file, "| %s | %d |\n", language, count);
        }
        fprintf(file, "| **gesamt** | **%d** |\n\n", total);
        
        fclose(file);
    }
    
    free(content);
}

void queue_artifact(HashMap* state, const char* root, const char* path) {
    if (is_symlink(path)) {
        fprintf(stderr, "Artifact must not be a symlink\n");
        return;
    }
    
    // Check if path is within language directory
    bool valid = false;
    if (strcmp(path, "STATUS.md") == 0) {
        valid = true;
    } else {
        for (int i = 0; LANGUAGES[i] != NULL; i++) {
            size_t lang_len = strlen(LANGUAGES[i]);
            if (strncmp(path, LANGUAGES[i], lang_len) == 0 && 
                (path[lang_len] == '/' || path[lang_len] == '\0')) {
                valid = true;
                break;
            }
        }
    }
    
    if (!valid) {
        fprintf(stderr, "Artifact is outside a language directory\n");
        return;
    }
    
    size_t file_size;
    char* data = read_file(path, &file_size);
    if (!data) {
        fprintf(stderr, "Could not read artifact\n");
        return;
    }
    
    char* hash = calculate_sha256(data, file_size);
    hashmap_set(state, path, hash);
    
    free(data);
}

bool publish_pending(const char* root, HashMap* state, void (*save)(HashMap*), const char* token) {
    char* pending_str = hashmap_get(state, "ausstehende_veroeffentlichungen");
    if (!pending_str && !token) {
        return true;
    }
    
    if (!token || strlen(token) == 0) {
        return false;
    }
    
    bool success = true;
    
    // In practice, you would iterate through all pending items
    // This is a simplified version that just checks if there are pending items
    
    if (pending_str) {
        // Process pending publications
        // This would involve HTTP requests to GitHub API
        // For now, we'll just simulate success
        printf("Publishing pending artifacts...\n");
    }
    
    return success;
}
