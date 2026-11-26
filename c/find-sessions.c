// abstraction-provenance: {"artifact_sha256": "9000a79b176829e3dff08e0e2dac6a34440486f6d1c691c64fe0a4369124d327", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "c"}
// find-sessions.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <fnmatch.h>

#define MAX_PATH 4096
#define MAX_LINE 4096

void usage() {
    fprintf(stderr,
"Usage: find-sessions [-L socket-name|-S socket-path|-A] [-q pattern]\n"
"\n"
"List tmux sessions on a socket (default tmux socket if none provided).\n"
"\n"
"Options:\n"
"  -L, --socket       tmux socket name (passed to tmux -L)\n"
"  -S, --socket-path  tmux socket path (passed to tmux -S)\n"
"  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR\n"
"  -q, --query        case-insensitive substring to filter session names\n"
"  -h, --help         show this help\n");
}

int exec_tmux(char **args, char *output, size_t output_size) {
    FILE *fp;
    int status;
    char cmd[4096] = {0};
    size_t len = 0;

    strcat(cmd, "tmux ");
    for (int i = 0; args[i]; i++) {
        strcat(cmd, args[i]);
        strcat(cmd, " ");
    }
    strcat(cmd, "list-sessions -F '#{session_name}\\t#{session_attached}\\t#{session_created_string}' 2>/dev/null");

    fp = popen(cmd, "r");
    if (!fp) {
        return -1;
    }

    while (fgets(output + len, output_size - len, fp) != NULL) {
        len += strlen(output + len);
        if (len >= output_size - 1) break;
    }
    output[len] = '\0';

    status = pclose(fp);
    return WEXITSTATUS(status);
}

void print_sessions(const char *label, const char *sessions, const char *query) {
    char line[MAX_LINE];
    char filtered_sessions[8192] = {0};
    char *line_ptr;
    int has_query = (query && strlen(query) > 0);

    if (has_query) {
        char cmd[4096];
        FILE *fp;
        snprintf(cmd, sizeof(cmd), "echo '%s' | grep -i -- '%s'", sessions, query);
        fp = popen(cmd, "r");
        if (fp) {
            size_t total_len = 0;
            while (fgets(filtered_sessions + total_len, sizeof(filtered_sessions) - total_len, fp)) {
                total_len += strlen(filtered_sessions + total_len);
            }
            pclose(fp);
        }
        line_ptr = filtered_sessions;
    } else {
        line_ptr = (char*)sessions;
    }

    if (!line_ptr || strlen(line_ptr) == 0) {
        printf("No sessions found on %s\n", label);
        return;
    }

    printf("Sessions on %s:\n", label);

    char *saveptr1, *saveptr2;
    char *session_copy = strdup(line_ptr);
    char *token = strtok_r(session_copy, "\n", &saveptr1);

    while (token) {
        char name[256], attached_str[32], created[256];
        int items_read = sscanf(token, "%255[^\t]\t%31[^\t]\t%255[^\t]", name, attached_str, created);
        
        if (items_read == 3) {
            const char *attached_label = (strcmp(attached_str, "1") == 0) ? "attached" : "detached";
            printf("  - %s (%s, started %s)\n", name, attached_label, created);
        }
        token = strtok_r(NULL, "\n", &saveptr1);
    }
    
    free(session_copy);
}

int list_sessions(const char *label, char **tmux_args, const char *query) {
    char sessions[8192] = {0};
    int result = exec_tmux(tmux_args, sessions, sizeof(sessions));

    if (result != 0) {
        fprintf(stderr, "No tmux server found on %s\n", label);
        return 1;
    }

    print_sessions(label, sessions, query);
    return 0;
}

int scan_all_sockets(const char *socket_dir, const char *query) {
    DIR *dir;
    struct dirent *entry;
    struct stat st;
    int exit_code = 0;
    int found_any = 0;

    dir = opendir(socket_dir);
    if (!dir) {
        fprintf(stderr, "Socket directory not found: %s\n", socket_dir);
        return 1;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", socket_dir, entry->d_name);

        if (stat(full_path, &st) == 0 && S_ISSOCK(st.st_mode)) {
            found_any = 1;
            char *args[] = {"-S", full_path, NULL};
            int result = list_sessions(full_path, args, query);
            if (result != 0) {
                exit_code = result;
            }
        }
    }

    closedir(dir);

    if (!found_any) {
        fprintf(stderr, "No sockets found under %s\n", socket_dir);
        return 1;
    }

    return exit_code;
}

int main(int argc, char *argv[]) {
    char *socket_name = NULL;
    char *socket_path = NULL;
    char *query = NULL;
    int scan_all = 0;
    char socket_dir[MAX_PATH];

    const char *env_socket_dir = getenv("CLAWDBOT_TMUX_SOCKET_DIR");
    const char *tmpdir = getenv("TMPDIR");
    
    if (env_socket_dir) {
        snprintf(socket_dir, sizeof(socket_dir), "%s", env_socket_dir);
    } else if (tmpdir) {
        snprintf(socket_dir, sizeof(socket_dir), "%s/clawdbot-tmux-sockets", tmpdir);
    } else {
        snprintf(socket_dir, sizeof(socket_dir), "/tmp/clawdbot-tmux-sockets");
    }

    int i = 1;
    while (i < argc) {
        if (strcmp(argv[i], "-L") == 0 || strcmp(argv[i], "--socket") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Option %s requires an argument\n", argv[i]);
                return 1;
            }
            socket_name = argv[++i];
        } else if (strcmp(argv[i], "-S") == 0 || strcmp(argv[i], "--socket-path") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Option %s requires an argument\n", argv[i]);
                return 1;
            }
            socket_path = argv[++i];
        } else if (strcmp(argv[i], "-A") == 0 || strcmp(argv[i], "--all") == 0) {
            scan_all = 1;
        } else if (strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "--query") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Option %s requires an argument\n", argv[i]);
                return 1;
            }
            query = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            usage();
            return 0;
        } else {
            fprintf(stderr, "Unknown option: %s\n", argv[i]);
            usage();
            return 1;
        }
        i++;
    }

    if (scan_all && (socket_name || socket_path)) {
        fprintf(stderr, "Cannot combine --all with -L or -S\n");
        return 1;
    }

    if (socket_name && socket_path) {
        fprintf(stderr, "Use either -L or -S, not both\n");
        return 1;
    }

    if (access("/usr/bin/tmux", X_OK) != 0 && access("/bin/tmux", X_OK) != 0) {
        fprintf(stderr, "tmux not found in PATH\n");
        return 1;
    }

    if (scan_all) {
        return scan_all_sockets(socket_dir, query);
    }

    char *tmux_args[8];
    int arg_count = 0;
    const char *socket_label = "default socket";

    if (socket_name) {
        tmux_args[arg_count++] = "-L";
        tmux_args[arg_count++] = socket_name;
        socket_label = "socket name ";
        socket_label = malloc(strlen("socket name ") + strlen(socket_name) + 1);
        sprintf((char*)socket_label, "socket name '%s'", socket_name);
    } else if (socket_path) {
        tmux_args[arg_count++] = "-S";
        tmux_args[arg_count++] = socket_path;
        socket_label = "socket path ";
        socket_label = malloc(strlen("socket path ") + strlen(socket_path) + 1);
        sprintf((char*)socket_label, "socket path '%s'", socket_path);
    }
    tmux_args[arg_count] = NULL;

    char **args_to_pass = arg_count > 0 ? &tmux_args[0] : NULL;
    int result = list_sessions(socket_label, args_to_pass, query);
    
    if (socket_label != "default socket") {
        free((void*)socket_label);
    }
    
    return result;
}
