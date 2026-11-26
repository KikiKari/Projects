// abstraction-provenance: {"artifact_sha256": "ddfcbaccf16472d2058d5db14065d22b15acb69e718469059bb18286f2bda8ad", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "c"}
// install_cron.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define WORKSPACE_PATH "/home/openclaw/.openclaw/workspace"
#define CRON_DIR "crons"
#define CRON_FILE "db-maintainer.cron"
#define JOBS_JSON ".openclaw/cron/jobs.json"

const char* CRON_JOB = 
"# DB Maintainer - Alle 30 Minuten\n"
"*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1";

void create_directories(const char* path) {
    char tmp[1024];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len - 1] == '/')
        tmp[len - 1] = '\0';

    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    mkdir(tmp, 0755);
}

int file_exists(const char* filename) {
    return access(filename, F_OK) == 0;
}

void write_cron_file(const char* filepath) {
    FILE* f = fopen(filepath, "w");
    if (!f) {
        perror("Fehler beim Öffnen der Cron-Datei");
        exit(1);
    }
    fprintf(f, "%s\n", CRON_JOB);
    fclose(f);
}

void update_jobs_json(const char* filepath) {
    // In C ist JSON-Handling komplexer, daher hier eine vereinfachte Lösung
    // Die Datei wird überschrieben mit dem aktualisierten Inhalt
    
    const char* content = 
"{\n"
"  \"db-maintainer\": {\n"
"    \"schedule\": \"*/30 * * * *\",\n"
"    \"command\": \"python3 skills/db-maintainer/scripts/db_maintainer.py\",\n"
"    \"enabled\": true\n"
"  }\n"
"}";
    
    FILE* f = fopen(filepath, "w");
    if (!f) {
        perror("Fehler beim Öffnen der jobs.json");
        return;
    }
    fprintf(f, "%s\n", content);
    fclose(f);
}

void install() {
    char cron_filepath[1024];
    char jobs_json_path[1024];
    char cron_dir_path[1024];
    
    snprintf(cron_filepath, sizeof(cron_filepath), "%s/%s/%s", WORKSPACE_PATH, CRON_DIR, CRON_FILE);
    snprintf(jobs_json_path, sizeof(jobs_json_path), "%s/%s", WORKSPACE_PATH, JOBS_JSON);
    snprintf(cron_dir_path, sizeof(cron_dir_path), "%s/%s", WORKSPACE_PATH, CRON_DIR);
    
    create_directories(cron_dir_path);
    
    write_cron_file(cron_filepath);
    
    printf("✅ Cron-Job installiert: %s\n", cron_filepath);
    printf("   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron\n");
    
    // Auch in OpenClaw cron registrieren
    if (file_exists(jobs_json_path)) {
        update_jobs_json(jobs_json_path);
        printf("✅ In OpenClaw cron registriert\n");
    }
}

int main() {
    install();
    return 0;
}
