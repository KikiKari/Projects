// abstraction-provenance: {"artifact_sha256": "7ff5ceb5def172eb766f65fca67eb42366a4593f268b5cb126920221bafc7725", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "c"}
// browser-session.mjs — portiert nach c
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <dirent.h>
#include <libgen.h>
#include <errno.h>

#define MAX_PATH 4096
#define MAX_LINE 8192

char *REPO;
char *PROFILE;
char *CHROME_PATHS[] = {"/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"};
int NUM_CHROME_PATHS = sizeof(CHROME_PATHS) / sizeof(char *);

typedef struct {
    char **args;
    int count;
} ArgList;

void error_exit(const char *msg) {
    fprintf(stderr, "%s\n", msg);
    exit(EXIT_FAILURE);
}

char* get_repo_path() {
    static char repo[MAX_PATH];
    ssize_t len = readlink("/proc/self/exe", repo, sizeof(repo) - 1);
    if (len == -1) {
        perror("readlink");
        exit(EXIT_FAILURE);
    }
    repo[len] = '\0';
    
    char *dir = dirname(repo);
    snprintf(repo, sizeof(repo), "%s/../", dir);
    return realpath(repo, NULL);
}

char* get_profile_dir() {
    char *profile_env = getenv("BROWSER_PROFILE_DIR");
    if (profile_env) {
        return strdup(profile_env);
    }
    
    static char profile[MAX_PATH];
    snprintf(profile, sizeof(profile), "%s/.browser-profile", REPO);
    return profile;
}

int file_exists(const char *path) {
    return access(path, F_OK) == 0;
}

char* find_chrome() {
    for (int i = 0; i < NUM_CHROME_PATHS; i++) {
        if (file_exists(CHROME_PATHS[i])) {
            return CHROME_PATHS[i];
        }
    }
    return NULL;
}

char* get_flag_value(int argc, char **argv, const char *flag_name, const char *default_val) {
    static char result[MAX_LINE];
    result[0] = '\0';
    
    for (int i = 0; i < argc - 1; i++) {
        if (strcmp(argv[i], flag_name) == 0) {
            strncpy(result, argv[i + 1], sizeof(result) - 1);
            result[sizeof(result) - 1] = '\0';
            return result;
        }
    }
    
    if (default_val) {
        strncpy(result, default_val, sizeof(result) - 1);
        result[sizeof(result) - 1] = '\0';
    }
    
    return result;
}

int has_flag(int argc, char **argv, const char *flag_name) {
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], flag_name) == 0) {
            return 1;
        }
    }
    return 0;
}

void create_profile_dir() {
    struct stat st = {0};
    if (stat(PROFILE, &st) == -1) {
        if (mkdir(PROFILE, 0755) == -1) {
            perror("mkdir");
            exit(EXIT_FAILURE);
        }
    }
}

void load_env_vars(char ***env_vars, int *count) {
    static char env_file[MAX_PATH];
    snprintf(env_file, sizeof(env_file), "%s/.env", REPO);
    
    FILE *fp = fopen(env_file, "r");
    if (!fp) return;
    
    char line[MAX_LINE];
    while (fgets(line, sizeof(line), fp)) {
        char *key = strtok(line, "=");
        if (!key) continue;
        
        char *value = strtok(NULL, "\n");
        if (!value) continue;
        
        // Remove quotes if present
        if (value[0] == '"' && value[strlen(value) - 1] == '"') {
            value[strlen(value) - 1] = '\0';
            value++;
        }
        
        *env_vars = realloc(*env_vars, (*count + 2) * sizeof(char *));
        (*env_vars)[*count] = malloc(strlen(key) + strlen(value) + 2);
        sprintf((*env_vars)[*count], "%s=%s", key, value);
        (*count)++;
        (*env_vars)[*count] = NULL;
    }
    
    fclose(fp);
}

void free_env_vars(char **env_vars, int count) {
    for (int i = 0; i < count; i++) {
        free(env_vars[i]);
    }
    free(env_vars);
}

char* get_env_value(char **env_vars, int count, const char *key) {
    if (!key[0]) return NULL;
    
    for (int i = 0; i < count; i++) {
        if (strncmp(env_vars[i], key, strlen(key)) == 0 && 
            env_vars[i][strlen(key)] == '=') {
            return strchr(env_vars[i], '=') + 1;
        }
    }
    return NULL;
}

void run_chrome_with_args(int argc, char **argv) {
    char *chrome_path = find_chrome();
    if (!chrome_path) {
        error_exit("Chrome not found");
    }
    
    // Build argument list
    char **args = malloc(sizeof(char *) * (argc + 50));
    int arg_count = 0;
    
    args[arg_count++] = chrome_path;
    args[arg_count++] = "--no-sandbox";
    args[arg_count++] = "--autoplay-policy=no-user-gesture-required";
    args[arg_count++] = "--disable-blink-features=AutomationControlled";
    
    // Add proxy arguments if needed
    char *socks = get_flag_value(argc, argv, "--socks", NULL);
    char proxy_arg[256];
    if (socks[0]) {
        snprintf(proxy_arg, sizeof(proxy_arg), "--proxy-server=socks5://%s", socks);
        args[arg_count++] = strdup(proxy_arg);
    } else {
        char *proxy_env = getenv("HTTPS_PROXY");
        if (!proxy_env) proxy_env = getenv("https_proxy");
        if (proxy_env) {
            snprintf(proxy_arg, sizeof(proxy_arg), "--proxy-server=%s", proxy_env);
            args[arg_count++] = strdup(proxy_arg);
        }
    }
    
    // Add SSL version max if proxy is used
    if (socks[0] || getenv("HTTPS_PROXY") || getenv("https_proxy")) {
        args[arg_count++] = "--ssl-version-max=tls1.2";
    }
    
    // Add user data directory
    char user_data_dir[MAX_PATH + 32];
    snprintf(user_data_dir, sizeof(user_data_dir), "--user-data-dir=%s", PROFILE);
    args[arg_count++] = strdup(user_data_dir);
    
    // Add other arguments
    for (int i = 0; i < argc; i++) {
        args[arg_count++] = argv[i];
    }
    
    args[arg_count] = NULL;
    
    // Execute Chrome
    execvp(chrome_path, args);
    perror("execvp");
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
    REPO = get_repo_path();
    PROFILE = get_profile_dir();
    
    create_profile_dir();
    
    if (argc < 2) {
        printf("Commands: open <URL> | shot <URL> | login <URL> | state\n");
        return 0;
    }
    
    char *cmd = argv[1];
    
    if (strcmp(cmd, "state") == 0) {
        printf("Profile: %s\n", PROFILE);
        printf("Cookies are stored persistently in the profile directory.\n");
        return 0;
    }
    
    if (strcmp(cmd, "open") == 0 || strcmp(cmd, "shot") == 0 || strcmp(cmd, "login") == 0) {
        if (argc < 3) {
            fprintf(stderr, "URL missing\n");
            return 1;
        }
        
        // For these commands, we would normally use Playwright or similar
        // Since we're in C without such libraries, we'll launch Chrome directly
        // with appropriate flags and let it handle persistence
        
        pid_t pid = fork();
        if (pid == 0) {
            // Child process - execute Chrome
            run_chrome_with_args(argc - 2, argv + 2);
        } else if (pid > 0) {
            // Parent process - wait for Chrome to start
            int status;
            waitpid(pid, &status, 0);
            
            if (WIFEXITED(status)) {
                printf("Chrome exited with status %d\n", WEXITSTATUS(status));
            } else {
                printf("Chrome terminated abnormally\n");
            }
        } else {
            perror("fork");
            return 1;
        }
        
        return 0;
    }
    
    printf("Commands: open <URL> | shot <URL> | login <URL> | state\n");
    return 0;
}
