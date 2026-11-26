// abstraction-provenance: {"artifact_sha256": "be50db4fe076c15de55ecf285255222606c8848ab759510c3b31b86a3c6889e1", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "c"}
// collect_ist_gateway_a.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <dirent.h>
#include <libgen.h>

#define MAX_PATH 1024
#define MAX_BUFFER 4096

void mkdir_p(const char *dir) {
    char tmp[MAX_PATH];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", dir);
    len = strlen(tmp);
    if (tmp[len - 1] == '/')
        tmp[len - 1] = '\0';
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            mkdir(tmp, S_IRWXU);
            *p = '/';
        }
    }
    mkdir(tmp, S_IRWXU);
}

char* get_home_dir() {
    char* home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "HOME environment variable not set\n");
        exit(1);
    }
    return home;
}

void execute_command(const char* cmd, char* output, size_t output_size) {
    FILE* fp = popen(cmd, "r");
    if (fp == NULL) {
        strcpy(output, "");
        return;
    }
    
    char buffer[1024];
    output[0] = '\0';
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        strncat(output, buffer, output_size - strlen(output) - 1);
    }
    
    // Remove trailing newline if present
    size_t len = strlen(output);
    if (len > 0 && output[len-1] == '\n') {
        output[len-1] = '\0';
    }
    
    pclose(fp);
}

int file_exists(const char* path) {
    struct stat buffer;
    return (stat(path, &buffer) == 0);
}

int directory_exists(const char* path) {
    struct stat info;
    return (stat(path, &info) == 0 && S_ISDIR(info.st_mode));
}

void list_directory(const char* path, FILE* out_file) {
    DIR* dir = opendir(path);
    if (dir == NULL) {
        fprintf(out_file, "(nicht vorhanden)\n");
        return;
    }
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            fprintf(out_file, "%s\n", entry->d_name);
        }
    }
    
    closedir(dir);
}

void list_directory_detailed(const char* path, FILE* out_file) {
    DIR* dir = opendir(path);
    if (dir == NULL) {
        fprintf(out_file, "(nicht vorhanden)\n");
        return;
    }
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            char full_path[MAX_PATH];
            snprintf(full_path, sizeof(full_path), "%s/%s", path, entry->d_name);
            
            struct stat info;
            if (stat(full_path, &info) == 0) {
                fprintf(out_file, "%s%s%s %ld\n", 
                    S_ISDIR(info.st_mode) ? "d" : "-",
                    entry->d_name,
                    S_ISDIR(info.st_mode) ? "/" : "",
                    info.st_size);
            }
        }
    }
    
    closedir(dir);
}

void read_file_content(const char* path, FILE* out_file) {
    FILE* file = fopen(path, "r");
    if (file == NULL) {
        fprintf(out_file, "# %s fehlt\n", basename((char*)path));
        return;
    }
    
    char line[MAX_BUFFER];
    while (fgets(line, sizeof(line), file)) {
        fprintf(out_file, "%s", line);
    }
    
    fclose(file);
}

int main() {
    char base_dir[MAX_PATH];
    char out_dir[MAX_PATH];
    char now_utc[100];
    char now_local[100];
    char timestamp[100];
    
    time_t rawtime;
    struct tm *timeinfo;
    
    time(&rawtime);
    timeinfo = gmtime(&rawtime);
    strftime(now_utc, sizeof(now_utc), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
    
    timeinfo = localtime(&rawtime);
    strftime(now_local, sizeof(now_local), "%Y-%m-%d %H:%M:%S %Z", timeinfo);
    strftime(timestamp, sizeof(timestamp), "%Y%m%d-%H%M%S", timeinfo);
    
    char* home_dir = get_home_dir();
    snprintf(base_dir, sizeof(base_dir), "%s/.openclaw", home_dir);
    snprintf(out_dir, sizeof(out_dir), "%s/workspace/vscode", base_dir);
    
    mkdir_p(out_dir);
    
    char ist_file[MAX_PATH];
    char inv_file[MAX_PATH];
    char cfg_file[MAX_PATH];
    char env_file[MAX_PATH];
    char run_file[MAX_PATH];
    
    snprintf(ist_file, sizeof(ist_file), "%s/IST-ZUSTAND_GATEWAY-A_NODE1.md", out_dir);
    snprintf(inv_file, sizeof(inv_file), "%s/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md", out_dir);
    snprintf(cfg_file, sizeof(cfg_file), "%s/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md", out_dir);
    snprintf(env_file, sizeof(env_file), "%s/ENV-STATUS_GATEWAY-A_NODE1.md", out_dir);
    snprintf(run_file, sizeof(run_file), "%s/RUN-%s.md", out_dir, timestamp);
    
    char openclaw_json[MAX_PATH];
    char env_dot[MAX_PATH];
    char env_systemd[MAX_PATH];
    char vscode_dir[MAX_PATH];
    
    snprintf(openclaw_json, sizeof(openclaw_json), "%s/openclaw.json", base_dir);
    snprintf(env_dot, sizeof(env_dot), "%s/.env", base_dir);
    snprintf(env_systemd, sizeof(env_systemd), "%s/gateway.systemd.env", base_dir);
    snprintf(vscode_dir, sizeof(vscode_dir), "%s/.vscode", base_dir);
    
    // Get system information
    char hostname_fqdn[256] = "";
    char hostname_short[256] = "";
    char arch[256] = "";
    char kernel[256] = "";
    char os_pretty[256] = "";
    char ipv4_all[256] = "";
    char public_ip[256] = "";
    char tailscale_ip[256] = "";
    char openclaw_ver[256] = "";
    char node_ver[256] = "";
    
    gethostname(hostname_short, sizeof(hostname_short));
    strcpy(hostname_fqdn, hostname_short); // Simplified
    
    struct utsname uname_data;
    if (uname(&uname_data) == 0) {
        strcpy(arch, uname_data.machine);
        strcpy(kernel, uname_data.release);
    }
    
    // Get OS info from /etc/os-release
    FILE* os_file = fopen("/etc/os-release", "r");
    if (os_file) {
        char line[256];
        while (fgets(line, sizeof(line), os_file)) {
            if (strncmp(line, "PRETTY_NAME=", 12) == 0) {
                char* start = strchr(line, '=');
                if (start) {
                    start++;
                    if (*start == '"') start++;
                    char* end = strrchr(start, '"');
                    if (end) *end = '\0';
                    strncpy(os_pretty, start, sizeof(os_pretty) - 1);
                    break;
                }
            }
        }
        fclose(os_file);
    }
    
    // Get IP addresses
    execute_command("hostname -I 2>/dev/null", ipv4_all, sizeof(ipv4_all));
    
    // Get public IP
    execute_command("curl -4 -s --max-time 4 ifconfig.me 2>/dev/null", public_ip, sizeof(public_ip));
    if (strlen(public_ip) == 0) {
        strcpy(public_ip, "(nicht ermittelt)");
    }
    
    // Get Tailscale IP
    execute_command("tailscale ip -4 2>/dev/null | head -n1", tailscale_ip, sizeof(tailscale_ip));
    if (strlen(tailscale_ip) == 0) {
        strcpy(tailscale_ip, "(nicht ermittelt)");
    }
    
    // Get versions
    execute_command("openclaw --version 2>/dev/null", openclaw_ver, sizeof(openclaw_ver));
    if (strlen(openclaw_ver) == 0) {
        strcpy(openclaw_ver, "(nicht ermittelt)");
    }
    
    execute_command("node -v 2>/dev/null", node_ver, sizeof(node_ver));
    if (strlen(node_ver) == 0) {
        strcpy(node_ver, "(nicht ermittelt)");
    }
    
    // Create IST file
    FILE* ist_fp = fopen(ist_file, "w");
    if (ist_fp) {
        fprintf(ist_fp, "# IST-Zustand: Gateway A / Node 1\n\n");
        fprintf(ist_fp, "Stand (lokal): %s  \n", now_local);
        fprintf(ist_fp, "Stand (UTC): %s\n\n", now_utc);
        fprintf(ist_fp, "## 1) Identitaet & System\n\n");
        fprintf(ist_fp, "- Gateway: **A**\n");
        fprintf(ist_fp, "- Node: **1**\n");
        fprintf(ist_fp, "- Hostname (short): `%s`\n", hostname_short);
        fprintf(ist_fp, "- Hostname (FQDN): `%s`\n", hostname_fqdn);
        fprintf(ist_fp, "- Architektur: `%s`\n", arch);
        fprintf(ist_fp, "- Kernel: `%s`\n", kernel);
        fprintf(ist_fp, "- OS: `%s`\n", os_pretty);
        fprintf(ist_fp, "- IPv4 (lokal): `%s`\n", ipv4_all);
        fprintf(ist_fp, "- Public IPv4: `%s`\n", public_ip);
        fprintf(ist_fp, "- Tailscale IPv4: `%s`\n", tailscale_ip);
        fprintf(ist_fp, "- OpenClaw Version: `%s`\n", openclaw_ver);
        fprintf(ist_fp, "- Node.js Version: `%s`\n\n", node_ver);
        
        fprintf(ist_fp, "## 2) Arbeitsverzeichnisse\n\n");
        fprintf(ist_fp, "- Basis: `%s`\n", base_dir);
        fprintf(ist_fp, "- Funktionell VSCode: `%s`\n", vscode_dir);
        fprintf(ist_fp, "- Workspace Doku: `%s`\n\n", out_dir);
        
        fprintf(ist_fp, "## 3) Kernartefakte (Existenz)\n\n");
        fprintf(ist_fp, "- `%s`: %s\n", openclaw_json, file_exists(openclaw_json) ? "vorhanden" : "fehlt");
        fprintf(ist_fp, "- `%s`: %s\n", env_dot, file_exists(env_dot) ? "vorhanden" : "fehlt");
        fprintf(ist_fp, "- `%s`: %s\n", env_systemd, file_exists(env_systemd) ? "vorhanden" : "fehlt");
        
        char plugin_installs[MAX_PATH];
        snprintf(plugin_installs, sizeof(plugin_installs), "%s/plugins/installs.json", base_dir);
        fprintf(ist_fp, "- `%s`: %s\n", plugin_installs, file_exists(plugin_installs) ? "vorhanden" : "fehlt");
        
        char plugin_skills[MAX_PATH];
        snprintf(plugin_skills, sizeof(plugin_skills), "%s/plugin-skills", base_dir);
        fprintf(ist_fp, "- `%s`: %s\n", plugin_skills, directory_exists(plugin_skills) ? "vorhanden" : "fehlt");
        
        fclose(ist_fp);
    }
    
    // Create inventory file
    FILE* inv_fp = fopen(inv_file, "w");
    if (inv_fp) {
        fprintf(inv_fp, "# Artefakt-Inventar: Gateway A / Node 1\n\n");
        fprintf(inv_fp, "Stand: %s\n\n", now_local);
        fprintf(inv_fp, "## Top-Level in ~/.openclaw\n\n");
        fprintf(inv_fp, "```text\n");
        list_directory(base_dir, inv_fp);
        fprintf(inv_fp, "```\n\n");
        
        fprintf(inv_fp, "## ~/.openclaw/.vscode\n\n");
        fprintf(inv_fp, "```text\n");
        if (directory_exists(vscode_dir)) {
            list_directory_detailed(vscode_dir, inv_fp);
        } else {
            fprintf(inv_fp, "(nicht vorhanden)\n");
        }
        fprintf(inv_fp, "```\n\n");
        
        fprintf(inv_fp, "## plugin-skills/\n\n");
        fprintf(inv_fp, "```text\n");
        if (directory_exists(plugin_skills)) {
            list_directory(plugin_skills, inv_fp);
        } else {
            fprintf(inv_fp, "(nicht vorhanden)\n");
        }
        fprintf(inv_fp, "```\n\n");
        
        fprintf(inv_fp, "## openclaw.json Backups\n\n");
        fprintf(inv_fp, "```text\n");
        char backup_pattern[MAX_PATH];
        snprintf(backup_pattern, sizeof(backup_pattern), "%s/openclaw.json.bak*", base_dir);
        char backup_list[MAX_BUFFER];
        char find_cmd[MAX_PATH];
        snprintf(find_cmd, sizeof(find_cmd), "ls -1 %s/openclaw.json.bak* 2>/dev/null", base_dir);
        execute_command(find_cmd, backup_list, sizeof(backup_list));
        if (strlen(backup_list) > 0) {
            fprintf(inv_fp, "%s\n", backup_list);
        } else {
            fprintf(inv_fp, "(keine gefunden)\n");
        }
        fprintf(inv_fp, "```\n");
        
        fclose(inv_fp);
    }
    
    // Create config snapshot file
    FILE* cfg_fp = fopen(cfg_file, "w");
    if (cfg_fp) {
        fprintf(cfg_fp, "# OpenClaw Config Snapshot: Gateway A / Node 1\n\n");
        fprintf(cfg_fp, "Stand: %s\n\n", now_local);
        fprintf(cfg_fp, "## Schluesselpositionen (grep)\n\n");
        fprintf(cfg_fp, "```text\n");
        if (file_exists(openclaw_json)) {
            char grep_cmd[MAX_PATH];
            snprintf(grep_cmd, sizeof(grep_cmd), "grep -nE '\"gateway\"|\\\"session\\\"|\\\"dmScope\\\"|\\\"auth\\\"|\\\"secrets\\\"|\\\"tools\\\"|\\\"plugins\\\"|\\\"profile\\\"|\\\"alsoAllow\\\"|\\\"denyCommands\\\"' %s", openclaw_json);
            char grep_result[MAX_BUFFER];
            execute_command(grep_cmd, grep_result, sizeof(grep_result));
            if (strlen(grep_result) > 0) {
                fprintf(cfg_fp, "%s\n", grep_result);
            }
        } else {
            fprintf(cfg_fp, "openclaw.json fehlt\n");
        }
        fprintf(cfg_fp, "```\n\n");
        
        fprintf(cfg_fp, "## Ausschnitt gateway/session/auth\n\n");
        fprintf(cfg_fp, "```json\n");
        if (file_exists(openclaw_json)) {
            char sed_cmd[MAX_PATH];
            snprintf(sed_cmd, sizeof(sed_cmd), "sed -n '580,780p' %s", openclaw_json);
            char sed_result[MAX_BUFFER];
            execute_command(sed_cmd, sed_result, sizeof(sed_result));
            if (strlen(sed_result) > 0) {
                fprintf(cfg_fp, "%s\n", sed_result);
            }
        } else {
            fprintf(cfg_fp, "{ \"error\": \"openclaw.json fehlt\" }\n");
        }
        fprintf(cfg_fp, "```\n");
        
        fclose(cfg_fp);
    }
    
    // Create ENV status file
    FILE* env_fp = fopen(env_file, "w");
    if (env_fp) {
        fprintf(env_fp, "# ENV-Status: Gateway A / Node 1\n\n");
        fprintf(env_fp, "Stand: %s\n\n", now_local);
        fprintf(env_fp, "## Dateien\n\n");
        fprintf(env_fp, "```text\n");
        char ls_cmd[MAX_PATH * 2];
        snprintf(ls_cmd, sizeof(ls_cmd), "ls -la '%s' '%s' 2>/dev/null", env_dot, env_systemd);
        char ls_result[MAX_BUFFER];
        execute_command(ls_cmd, ls_result, sizeof(ls_result));
        if (strlen(ls_result) > 0) {
            fprintf(env_fp, "%s\n", ls_result);
        }
        fprintf(env_fp, "```\n\n");
        
        fprintf(env_fp, "## .env (vollstaendig)\n\n");
        fprintf(env_fp, "```dotenv\n");
        if (file_exists(env_dot)) {
            read_file_content(env_dot, env_fp);
        } else {
            fprintf(env_fp, "# .env fehlt\n");
        }
        fprintf(env_fp, "```\n\n");
        
        fprintf(env_fp, "## gateway.systemd.env (vollstaendig)\n\n");
        fprintf(env_fp, "```dotenv\n");
        if (file_exists(env_systemd)) {
            read_file_content(env_systemd, env_fp);
        } else {
            fprintf(env_fp, "# gateway.systemd.env fehlt\n");
        }
        fprintf(env_fp, "```\n");
        
        fclose(env_fp);
    }
    
    // Create run file
    FILE* run_fp = fopen(run_file, "w");
    if (run_fp) {
        fprintf(run_fp, "# Laufprotokoll Gateway A / Node 1\n\n");
        fprintf(run_fp, "- Zeit (lokal): %s\n", now_local);
        fprintf(run_fp, "- Zeit (UTC): %s\n", now_utc);
        fprintf(run_fp, "- Script: collect_ist_gateway_a\n\n");
        fprintf(run_fp, "## Erzeugte Dateien\n\n");
        fprintf(run_fp, "- %s\n", "IST-ZUSTAND_GATEWAY-A_NODE1.md");
        fprintf(run_fp, "- %s\n", "ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md");
        fprintf(run_fp, "- %s\n", "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md");
        fprintf(run_fp, "- %s\n", "ENV-STATUS_GATEWAY-A_NODE1.md");
        
        fclose(run_fp);
    }
    
    printf("OK: IST-Zustand erfasst.\n");
    
    // List created files
    DIR* dir = opendir(out_dir);
    if (dir) {
        struct dirent* entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
                printf("- %s\n", entry->d_name);
            }
        }
        closedir(dir);
    }
    
    return 0;
}
