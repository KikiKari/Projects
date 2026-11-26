// abstraction-provenance: {"artifact_sha256": "94777e2b647fba1b37a2fa4e6702af82d2687bb5f3c1d4ee3171fefbc9f8bc00", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "c"}
// collect_compare_bundle.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <dirent.h>
#include <libgen.h>
#include <errno.h>

#define ROOT "/home/openclaw/.openclaw"
#define OUT_DIR ROOT "/workspace/vscode/compare"
#define TRANSFER_DIR OUT_DIR "/transfer"
#define MD_FILE OUT_DIR "/local-gateway-config.md"
#define TREE_FILE OUT_DIR "/tree.txt"
#define BACKUP_FILE "/home/openclaw/openclaw-backup.tar.gz"

void mkdir_p(const char *path) {
    char *_path = strdup(path);
    char *p = _path;
    while (*p) {
        if (*p == '/') {
            *p = '\0';
            if (strlen(_path) > 0) {
                mkdir(_path, 0755);
            }
            *p = '/';
        }
        p++;
    }
    mkdir(_path, 0755);
    free(_path);
}

int file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

void append_file_verbatim(FILE *md_fp, const char *label, const char *path, const char *lang) {
    fprintf(md_fp, "\n## %s\n\nPfad: `%s`\n\n```%s\n", label, path, lang ? lang : "text");
    FILE *fp = fopen(path, "r");
    if (fp) {
        int ch;
        while ((ch = fgetc(fp)) != EOF) {
            fputc(ch, md_fp);
        }
        fclose(fp);
    } else {
        fprintf(md_fp, "[FEHLT] %s", path);
    }
    fprintf(md_fp, "\n```\n");
}

void append_env_verbatim(FILE *md_fp) {
    fprintf(md_fp, "\n## Umgebungsvariablen (env)\n\n```text\n");
    extern char **environ;
    for (char **env = environ; *env; ++env) {
        fprintf(md_fp, "%s\n", *env);
    }
    fprintf(md_fp, "```\n");
}

void append_dir_files_verbatim(FILE *md_fp, const char *section, const char *dir) {
    fprintf(md_fp, "\n## %s\n\n", section);
    if (!file_exists(dir)) {
        fprintf(md_fp, "[FEHLT] %s\n", dir);
        return;
    }
    fprintf(md_fp, "Basisverzeichnis: `%s`\n", dir);

    char find_cmd[1024];
    snprintf(find_cmd, sizeof(find_cmd), "find '%s' -type f | sort", dir);

    FILE *find_fp = popen(find_cmd, "r");
    if (!find_fp) {
        perror("popen failed");
        return;
    }

    char path[1024];
    while (fgets(path, sizeof(path), find_fp)) {
        size_t len = strlen(path);
        if (len > 0 && path[len - 1] == '\n') {
            path[len - 1] = '\0';
        }

        fprintf(md_fp, "\n### Datei: `%s`\n\n```text\n", path);
        FILE *file_fp = fopen(path, "r");
        if (file_fp) {
            int ch;
            while ((ch = fgetc(file_fp)) != EOF) {
                fputc(ch, md_fp);
            }
            fclose(file_fp);
        }
        fprintf(md_fp, "\n```\n");
    }
    pclose(find_fp);
}

int main() {
    setenv("LANG", "C", 1); // Ensure consistent date formatting

    mkdir_p(OUT_DIR);
    mkdir_p(TRANSFER_DIR);

    if (system("which tree > /dev/null 2>&1") != 0) {
        printf("Fehler: 'tree' ist nicht installiert.\n");
        return 1;
    }

    FILE *md_fp = fopen(MD_FILE, "w");
    if (!md_fp) {
        perror("Failed to open MD_FILE");
        return 1;
    }

    time_t rawtime;
    struct tm *timeinfo;

    time(&rawtime);
    timeinfo = localtime(&rawtime);
    char NOW_LOCAL[64];
    strftime(NOW_LOCAL, sizeof(NOW_LOCAL), "%Y-%m-%d %H:%M:%S %Z", timeinfo);

    timeinfo = gmtime(&rawtime);
    char NOW_UTC[64];
    strftime(NOW_UTC, sizeof(NOW_UTC), "%Y-%m-%dT%H:%M:%SZ", timeinfo);

    char HOST[256];
    if (gethostname(HOST, sizeof(HOST)) != 0) {
        strcpy(HOST, "unknown");
    }

    fprintf(md_fp, "# Lokaler Gateway-Konfigurationsstand\n\nGeneriert: %s\nUTC: %s\nHost: %s\n\nDiese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n", NOW_LOCAL, NOW_UTC, HOST);

    append_file_verbatim(md_fp, "openclaw.json", ROOT "/openclaw.json", "json");
    append_file_verbatim(md_fp, "exec-approvals.json", ROOT "/exec-approvals.json", "json");
    append_file_verbatim(md_fp, "gateway.systemd.env", ROOT "/gateway.systemd.env", "dotenv");
    append_file_verbatim(md_fp, ".env", ROOT "/.env", "dotenv");
    append_env_verbatim(md_fp);
    append_dir_files_verbatim(md_fp, ".config (alle Dateien rekursiv)", ROOT "/.config");
    append_dir_files_verbatim(md_fp, "agents (alle Dateien rekursiv)", ROOT "/agents");

    fclose(md_fp);

    char tree_cmd[1024];
    snprintf(tree_cmd, sizeof(tree_cmd), "tree -a -L 6 '%s' > '%s'", ROOT, TREE_FILE);
    if (system(tree_cmd) != 0) {
        printf("Warning: Failed to run tree command\n");
    }

    char backup_cmd[1024];
    snprintf(backup_cmd, sizeof(backup_cmd), "openclaw backup create --output '%s' --verify", BACKUP_FILE);
    if (system(backup_cmd) != 0) {
        printf("Error: Failed to create backup\n");
        return 1;
    }

    char copy_cmd[1024];
    snprintf(copy_cmd, sizeof(copy_cmd), "cp '%s' '%s'", BACKUP_FILE, OUT_DIR);
    if (system(copy_cmd) != 0) {
        printf("Error: Failed to copy backup file\n");
        return 1;
    }

    printf("OK\nErzeugt:\n- %s\n- %s\n- %s\n- %s (leer)\n", MD_FILE, TREE_FILE, BACKUP_FILE, TRANSFER_DIR);

    return 0;
}
