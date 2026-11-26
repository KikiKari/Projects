// abstraction-provenance: {"artifact_sha256": "71d614b1842cb3c2707fd7bdfa1590de71c501a97239587598ec5e717f87cca3", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "c"}
// ops-hub-heartbeat.js — portiert nach c
// Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
// auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <locale.h>
#include <langinfo.h>
#include <unistd.h>

#define STATUS_FILE_PATH "../docs/ops-hub/status.md"
#define BUFFER_SIZE 4096

void updateHeartbeat() {
    FILE *file;
    char *content = NULL;
    long file_size;
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    char *updated_content = NULL;
    size_t updated_size = 0;
    
    // Lese die gesamte Datei
    file = fopen(STATUS_FILE_PATH, "r");
    if (file == NULL) {
        fprintf(stderr, "❌ Konnte status.md nicht lesen: %s\n", strerror(errno));
        return;
    }
    
    // Bestimme die Dateigröße
    fseek(file, 0, SEEK_END);
    file_size = ftell(file);
    rewind(file);
    
    // Allokiere Speicher für den Inhalt
    content = malloc(file_size + 1);
    if (content == NULL) {
        fprintf(stderr, "❌ Speicher konnte nicht allokiert werden\n");
        fclose(file);
        return;
    }
    
    // Lese den gesamten Inhalt
    fread(content, 1, file_size, file);
    content[file_size] = '\0';
    fclose(file);
    
    // Setze das deutsche Locale für die Zeitformatierung
    setlocale(LC_TIME, "de_DE.UTF-8");
    
    // Hole die aktuelle Zeit
    time_t now_time;
    struct tm *time_info;
    char time_str[100];
    
    time(&now_time);
    time_info = localtime(&now_time);
    strftime(time_str, sizeof(time_str), "%d.%m.%Y, %H:%M:%S", time_info);
    
    // Ersetze die Zeile mit "Letzter Heartbeat:"
    updated_content = malloc(BUFFER_SIZE);
    if (updated_content == NULL) {
        fprintf(stderr, "❌ Speicher konnte nicht allokiert werden\n");
        free(content);
        return;
    }
    
    // Suche nach der Zeile mit "Letzter Heartbeat:" und ersetze sie
    char *line_start = content;
    char *line_end;
    int found = 0;
    
    while (line_start < content + file_size) {
        line_end = strchr(line_start, '\n');
        if (line_end == NULL) {
            line_end = content + file_size;
        }
        
        // Prüfe ob die Zeile "Letzter Heartbeat:" enthält
        if (strncmp(line_start, "Letzter Heartbeat:", 18) == 0) {
            // Füge die neue Zeile hinzu
            char new_line[BUFFER_SIZE];
            snprintf(new_line, sizeof(new_line), "Letzter Heartbeat: %s", time_str);
            
            // Prüfe ob genug Platz vorhanden ist
            if (updated_size + strlen(new_line) + 1 > BUFFER_SIZE) {
                updated_content = realloc(updated_content, updated_size + strlen(new_line) + 1);
                if (updated_content == NULL) {
                    fprintf(stderr, "❌ Speicher konnte nicht reallokiert werden\n");
                    free(content);
                    return;
                }
            }
            
            strcat(updated_content, new_line);
            updated_size += strlen(new_line);
            found = 1;
        } else {
            // Kopiere die originale Zeile
            size_t line_len = line_end - line_start;
            char *temp_line = strndup(line_start, line_len);
            
            // Prüfe ob genug Platz vorhanden ist
            if (updated_size + line_len + 2 > BUFFER_SIZE) {
                updated_content = realloc(updated_content, updated_size + line_len + 2);
                if (updated_content == NULL) {
                    fprintf(stderr, "❌ Speicher konnte nicht reallokiert werden\n");
                    free(temp_line);
                    free(content);
                    return;
                }
            }
            
            strcat(updated_content, temp_line);
            updated_size += line_len;
            free(temp_line);
        }
        
        // Füge Zeilenumbruch hinzu wenn nicht am Ende
        if (line_end < content + file_size) {
            if (updated_size + 2 > BUFFER_SIZE) {
                updated_content = realloc(updated_content, updated_size + 2);
                if (updated_content == NULL) {
                    fprintf(stderr, "❌ Speicher konnte nicht reallokiert werden\n");
                    free(content);
                    return;
                }
            }
            strcat(updated_content, "\n");
            updated_size += 1;
        }
        
        line_start = line_end + 1;
        if (line_start >= content + file_size) break;
    }
    
    // Schreibe die aktualisierten Inhalte zurück in die Datei
    file = fopen(STATUS_FILE_PATH, "w");
    if (file == NULL) {
        fprintf(stderr, "❌ Konnte status.md nicht schreiben: %s\n", strerror(errno));
        free(content);
        free(updated_content);
        return;
    }
    
    fputs(updated_content, file);
    fclose(file);
    
    printf("✅ Heartbeat aktualisiert: %s\n", time_str);
    
    free(content);
    free(updated_content);
}

int main() {
    updateHeartbeat();
    return 0;
}
