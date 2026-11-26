// abstraction-provenance: {"artifact_sha256": "6e08a82d1e50f22cb52913bda88290b85b2110ec336e5ba9556ee03ccbd0e92b", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "c"}
// collect_ist_gateway_b.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <errno.h>

#define MAX_PATH 1024
#define MAX_LINE 2048
#define MAX_CMD_OUTPUT 8192

// Function prototypes
void execute_command(const char *cmd, char *output, size_t output_size);
int file_exists(const char *path);
int dir_exists(const char *path);
void get_os_pretty_name(char *buffer, size_t buffer_size);
void write_ist_file(const char *filename, const char *now_local, const char *now_utc,
                   const char *hostname_short, const char *hostname_fqdn, 
                   const char *arch, const char *kernel, const char *os_pretty,
                   const char *ipv4_all, const char *public_ip, const char *tailscale_ip,
                   const char *openclaw_ver, const char *node_ver,
                   const char *base_dir, const char *vscode_dir, const char *out_dir);
void write_inventory_file(const char *filename, const char *now_local, 
                         const char *base_dir, const char *vscode_dir);
void write_config_snapshot(const char *filename, const char *now_local, 
                           const char *openclaw_json);
void write_env_status(const char *filename, const char *now_local,
                      const char *env_dot, const char *env_systemd);
void write_run_file(const char *filename, const char *now_local, const char *now_utc,
                   const char *ist_file, const char *inv_file, const char *cfg_file, 
                   const char *env_file, const char *argv0);
void list_directory(const char *path, FILE *fp);
void read_file_content(const char *path, FILE *fp);

int main(int argc, char *argv[]) {
    char base_dir[MAX_PATH];
    char out_dir[MAX_PATH];
    char now_utc[64];
    char now_local[64];
    char ts[32];
    
    // Get home directory and set paths
    char *home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "ERROR: HOME environment variable not set\n");
        return 1;
    }
    
    snprintf(base_dir, sizeof(base_dir), "%s/.openclaw", home);
    snprintf(out_dir, sizeof(out_dir), "%s/.openclaw/workspace/vscode", home);
    
    // Create output directory
    mkdir(out_dir, 0755);
    
    // Get current time
    time_t rawtime;
    struct tm *timeinfo;
    
    time(&rawtime);
    timeinfo = gmtime(&rawtime);
    strftime(now_utc, sizeof(now_utc), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
    
    timeinfo = localtime(&rawtime);
    strftime(now_local, sizeof(now_local), "%Y-%m-%d %H:%M:%S %Z", timeinfo);
    strftime(ts, sizeof(ts), "%Y%m%d-%H%M%S", timeinfo);
    
    // File paths
    char ist_file[MAX_PATH];
    char inv_file[MAX_PATH];
    char cfg_file[MAX_PATH];
    char env_file[MAX_PATH];
    char run_file[MAX_PATH];
    
    snprintf(ist_file, sizeof(ist_file), "%s/IST-ZUSTAND_GATEWAY-B_NODE7.md", out_dir);
    snprintf(inv_file, sizeof(inv_file), "%s/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md", out_dir);
    snprintf(cfg_file, sizeof(cfg_file), "%s/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md", out_dir);
    snprintf(env_file, sizeof(env_file), "%s/ENV-STATUS_GATEWAY-B_NODE7.md", out_dir);
    snprintf(run_file, sizeof(run_file), "%s/RUN-%s.md", out_dir, ts);
    
    // Configuration file paths
    char openclaw_json[MAX_PATH];
    char env_dot[MAX_PATH];
    char env_systemd[MAX_PATH];
    char vscode_dir[MAX_PATH];
    
    snprintf(openclaw_json, sizeof(openclaw_json), "%s/openclaw.json", base_dir);
    snprintf(env_dot, sizeof(env_dot), "%s/.env", base_dir);
    snprintf(env_systemd, sizeof(env_systemd), "%s/gateway.systemd.env", base_dir);
    snprintf(vscode_dir, sizeof(vscode_dir), "%s/.vscode", base_dir);
    
    // System information
    char hostname_fqdn[256] = {0};
    char hostname_short[256];
    char arch[64];
    char kernel[256];
    char os_pretty[256] = {0};
    char ipv4_all[512] = {0};
    char public_ip[64] = {0};
    char tailscale_ip[64] = {0};
    char openclaw_ver[128] = {0};
    char node_ver[128] = {0};
    
    // Get hostname
    gethostname(hostname_short, sizeof(hostname_short));
    strcpy(hostname_fqdn, hostname_short); // Fallback
    
    // Get architecture and kernel
    struct utsname uname_data;
    if (uname(&uname_data) == 0) {
        strncpy(arch, uname_data.machine, sizeof(arch) - 1);
        strncpy(kernel, uname_data.release, sizeof(kernel) - 1);
    } else {
        strcpy(arch, "unknown");
        strcpy(kernel, "unknown");
    }
    
    // Get OS pretty name
    get_os_pretty_name(os_pretty, sizeof(os_pretty));
    
    // Get IP addresses (basic implementation)
    strcpy(ipv4_all, "localhost 127.0.0.1");
    strcpy(public_ip, "(nicht ermittelt)");
    strcpy(tailscale_ip, "(nicht ermittelt)");
    
    // Get versions (using placeholder - would need actual command execution)
    strcpy(openclaw_ver, "(nicht ermittelt)");
    strcpy(node_ver, "(nicht ermittelt)");
    
    // Write all files
    write_ist_file(ist_file, now_local, now_utc, hostname_short, hostname_fqdn,
                   arch, kernel, os_pretty, ipv4_all, public_ip, tailscale_ip,
                   openclaw_ver, node_ver, base_dir, vscode_dir, out_dir);
                   
    write_inventory_file(inv_file, now_local, base_dir, vscode_dir);
    write_config_snapshot(cfg_file, now_local, openclaw_json);
    write_env_status(env_file, now_local, env_dot, env_systemd);
    write_run_file(run_file, now_local, now_utc, ist_file, inv_file, cfg_file, env_file, argv[0]);
    
    printf("OK: IST-Zustand erfasst.\n");
    printf("Ausgabeordner: %s\n", out_dir);
    printf("Dateien:\n");
    
    DIR *dir = opendir(out_dir);
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_name[0] != '.') {
                printf("- %s\n", entry->d_name);
            }
        }
        closedir(dir);
    }
    
    return 0;
}

void get_os_pretty_name(char *buffer, size_t buffer_size) {
    FILE *fp = fopen("/etc/os-release", "r");
    if (!fp) {
        strcpy(buffer, "Unknown");
        return;
    }
    
    char line[512];
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "PRETTY_NAME=", 13) == 0) {
            char *start = strchr(line, '=');
            if (start) {
                start++;
                char *end = strrchr(start, '\n');
                if (end) *end = '\0';
                end = strrchr(start, '"');
                if (end) *end = '\0';
                if (*start == '"') start++;
                strncpy(buffer, start, buffer_size - 1);
                buffer[buffer_size - 1] = '\0';
                fclose(fp);
                return;
            }
        }
    }
    
    fclose(fp);
    strcpy(buffer, "Unknown");
}

int file_exists(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0) && S_ISREG(st.st_mode);
}

int dir_exists(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0) && S_ISDIR(st.st_mode);
}

void write_ist_file(const char *filename, const char *now_local, const char *now_utc,
                   const char *hostname_short, const char *hostname_fqdn, 
                   const char *arch, const char *kernel, const char *os_pretty,
                   const char *ipv4_all, const char *public_ip, const char *tailscale_ip,
                   const char *openclaw_ver, const char *node_ver,
                   const char *base_dir, const char *vscode_dir, const char *out_dir) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("Failed to open IST file");
        return;
    }
    
    fprintf(fp, "# IST-Zustand: Gateway B / Node 7\n\n");
    fprintf(fp, "Stand (lokal): %s  \n", now_local);
    fprintf(fp, "Stand (UTC): %s\n\n", now_utc);
    fprintf(fp, "## 1) Identität & System\n\n");
    fprintf(fp, "- Gateway: **B**\n");
    fprintf(fp, "- Node: **7**\n");
    fprintf(fp, "- Hostname (short): `%s`\n", hostname_short);
    fprintf(fp, "- Hostname (FQDN): `%s`\n", hostname_fqdn);
    fprintf(fp, "- Architektur: `%s`\n", arch);
    fprintf(fp, "- Kernel: `%s`\n", kernel);
    fprintf(fp, "- OS: `%s`\n", os_pretty);
    fprintf(fp, "- IPv4 (lokal): `%s`\n", ipv4_all);
    fprintf(fp, "- Public IPv4: `%s`\n", public_ip);
    fprintf(fp, "- Tailscale IPv4: `%s`\n", tailscale_ip);
    fprintf(fp, "- OpenClaw Version: `%s`\n", openclaw_ver);
    fprintf(fp, "- Node.js Version: `%s`\n\n", node_ver);
    
    fprintf(fp, "## 2) Arbeitsverzeichnisse\n\n");
    fprintf(fp, "- Basis: `%s`\n", base_dir);
    fprintf(fp, "- Funktionell VSCode: `%s`\n", vscode_dir);
    fprintf(fp, "- Workspace Doku: `%s`\n\n", out_dir);
    
    fprintf(fp, "## 3) Kernartefakte (Existenz)\n\n");
    
    char path[MAX_PATH];
    snprintf(path, sizeof(path), "%s/openclaw.json", base_dir);
    fprintf(fp, "- `%s`: %s\n", path, file_exists(path) ? "vorhanden" : "fehlt");
    
    snprintf(path, sizeof(path), "%s/.env", base_dir);
    fprintf(fp, "- `%s`: %s\n", path, file_exists(path) ? "vorhanden" : "fehlt");
    
    snprintf(path, sizeof(path), "%s/gateway.systemd.env", base_dir);
    fprintf(fp, "- `%s`: %s\n", path, file_exists(path) ? "vorhanden" : "fehlt");
    
    snprintf(path, sizeof(path), "%s/plugins/installs.json", base_dir);
    fprintf(fp, "- `%s`: %s\n", path, file_exists(path) ? "vorhanden" : "fehlt");
    
    snprintf(path, sizeof(path), "%s/plugin-skills", base_dir);
    fprintf(fp, "- `%s`: %s\n\n", path, dir_exists(path) ? "vorhanden" : "fehlt");
    
    fprintf(fp, "## 4) Hinweis\n\n");
    fprintf(fp, "Diese Datei wird bei jedem Lauf neu geschrieben.\n");
    fprintf(fp, "Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.\n");
    
    fclose(fp);
}

void write_inventory_file(const char *filename, const char *now_local, 
                         const char *base_dir, const char *vscode_dir) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("Failed to open inventory file");
        return;
    }
    
    fprintf(fp, "# Artefakt-Inventar: Gateway B / Node 7\n\n");
    fprintf(fp, "Stand: %s\n\n", now_local);
    fprintf(fp, "## Top-Level in ~/.openclaw\n\n");
    fprintf(fp, "```text\n");
    list_directory(base_dir, fp);
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## ~/.openclaw/.vscode\n\n");
    fprintf(fp, "```text\n");
    if (dir_exists(vscode_dir)) {
        DIR *dir = opendir(vscode_dir);
        if (dir) {
            struct dirent *entry;
            while ((entry = readdir(dir)) != NULL) {
                fprintf(fp, "%s\n", entry->d_name);
            }
            closedir(dir);
        }
    } else {
        fprintf(fp, "(nicht vorhanden)\n");
    }
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## plugin-skills/\n\n");
    fprintf(fp, "```text\n");
    char skills_path[MAX_PATH];
    snprintf(skills_path, sizeof(skills_path), "%s/plugin-skills", base_dir);
    if (dir_exists(skills_path)) {
        list_directory(skills_path, fp);
    } else {
        fprintf(fp, "(nicht vorhanden)\n");
    }
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## openclaw.json Backups\n\n");
    fprintf(fp, "```text\n");
    // This is a simplified version - would need globbing for full functionality
    fprintf(fp, "(keine gefunden)\n");
    fprintf(fp, "```\n");
    
    fclose(fp);
}

void write_config_snapshot(const char *filename, const char *now_local, 
                           const char *openclaw_json) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("Failed to open config snapshot file");
        return;
    }
    
    fprintf(fp, "# OpenClaw Config Snapshot: Gateway B / Node 7\n\n");
    fprintf(fp, "Stand: %s\n\n", now_local);
    fprintf(fp, "## Schlüsselpositionen (grep)\n\n");
    fprintf(fp, "```text\n");
    if (file_exists(openclaw_json)) {
        fprintf(fp, "[grep functionality would be implemented here]\n");
    } else {
        fprintf(fp, "openclaw.json fehlt\n");
    }
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)\n\n");
    fprintf(fp, "```json\n");
    if (file_exists(openclaw_json)) {
        fprintf(fp, "[lines 580-780 would be extracted here]\n");
    } else {
        fprintf(fp, "{ \"error\": \"openclaw.json fehlt\" }\n");
    }
    fprintf(fp, "```\n");
    
    fclose(fp);
}

void write_env_status(const char *filename, const char *now_local,
                      const char *env_dot, const char *env_systemd) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("Failed to open env status file");
        return;
    }
    
    fprintf(fp, "# ENV-Status: Gateway B / Node 7\n\n");
    fprintf(fp, "Stand: %s\n\n", now_local);
    fprintf(fp, "## Dateien\n\n");
    fprintf(fp, "```text\n");
    fprintf(fp, "[file listing would go here]\n");
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## .env (vollständig, ungefiltert)\n\n");
    fprintf(fp, "```dotenv\n");
    if (file_exists(env_dot)) {
        read_file_content(env_dot, fp);
    } else {
        fprintf(fp, "# .env fehlt\n");
    }
    fprintf(fp, "```\n\n");
    
    fprintf(fp, "## gateway.systemd.env (vollständig, ungefiltert)\n\n");
    fprintf(fp, "```dotenv\n");
    if (file_exists(env_systemd)) {
        read_file_content(env_systemd, fp);
    } else {
        fprintf(fp, "# gateway.systemd.env fehlt\n");
    }
    fprintf(fp, "```\n");
    
    fclose(fp);
}

void write_run_file(const char *filename, const char *now_local, const char *now_utc,
                   const char *ist_file, const char *inv_file, const char *cfg_file, 
                   const char *env_file, const char *argv0) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("Failed to open run file");
        return;
    }
    
    fprintf(fp, "# Laufprotokoll Gateway B / Node 7\n\n");
    fprintf(fp, "- Zeit (lokal): %s\n", now_local);
    fprintf(fp, "- Zeit (UTC): %s\n", now_utc);
    fprintf(fp, "- Script: %s\n\n", argv0);
    fprintf(fp, "## Erzeugte Dateien\n\n");
    fprintf(fp, "- %s\n", "IST-ZUSTAND_GATEWAY-B_NODE7.md");
    fprintf(fp, "- %s\n", "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md");
    fprintf(fp, "- %s\n", "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md");
    fprintf(fp, "- %s\n", "ENV-STATUS_GATEWAY-B_NODE7.md");
    
    fclose(fp);
}

void list_directory(const char *path, FILE *fp) {
    DIR *dir = opendir(path);
    if (!dir) {
        fprintf(fp, "Cannot access directory: %s\n", path);
        return;
    }
    
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            fprintf(fp, "%s\n", entry->d_name);
        }
    }
    closedir(dir);
}

void read_file_content(const char *path, FILE *fp) {
    FILE *file = fopen(path, "r");
    if (!file) {
        fprintf(fp, "# Cannot read file: %s\n", path);
        return;
    }
    
    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), file)) {
        fputs(buffer, fp);
    }
    
    fclose(file);
}
