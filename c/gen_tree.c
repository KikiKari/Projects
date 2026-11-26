// abstraction-provenance: {"artifact_sha256": "da9ed2d1aa372ab6359b8756d59f7ec51958674c8484fcc8f8eb30386c396ac3", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "c"}
// gen_tree.py — portiert nach c
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>

#define ROOT "/workspace"
#define OUT "/workspace/important/openclaw-tree.txt"
#define MAX_DEPTH 6
#define MAX_PATH 4096

// Vergleichsfunktion für qsort
int compare_strings(const void *a, const void *b) {
    return strcmp(*(const char **)a, *(const char **)b);
}

// Frees memory allocated for directory entries
void free_entries(char **entries, int count) {
    for (int i = 0; i < count; i++) {
        free(entries[i]);
    }
    free(entries);
}

// Liest Verzeichniseinträge und gibt sie sortiert zurück
char **listdir_sorted(const char *path, int *count) {
    DIR *dir;
    struct dirent *entry;
    char **entries = NULL;
    int capacity = 16;
    *count = 0;

    dir = opendir(path);
    if (!dir) {
        *count = 0;
        return NULL;
    }

    entries = malloc(capacity * sizeof(char*));
    if (!entries) {
        closedir(dir);
        return NULL;
    }

    while ((entry = readdir(dir)) != NULL) {
        // Überspringe . und ..
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        if (*count >= capacity) {
            capacity *= 2;
            char **temp = realloc(entries, capacity * sizeof(char*));
            if (!temp) {
                free_entries(entries, *count);
                closedir(dir);
                return NULL;
            }
            entries = temp;
        }

        entries[*count] = strdup(entry->d_name);
        if (!entries[*count]) {
            free_entries(entries, *count);
            closedir(dir);
            return NULL;
        }
        (*count)++;
    }

    closedir(dir);

    // Sortiere die Einträge
    if (*count > 0) {
        qsort(entries, *count, sizeof(char*), compare_strings);
    }

    return entries;
}

// Prüft, ob der Pfad ein Verzeichnis ist
int is_directory(const char *path) {
    struct stat statbuf;
    if (stat(path, &statbuf) != 0) {
        return 0;
    }
    return S_ISDIR(statbuf.st_mode);
}

// Prüft, ob der Pfad ein Symlink ist
int is_symlink(const char *path) {
    struct stat statbuf;
    if (lstat(path, &statbuf) != 0) {
        return 0;
    }
    return S_ISLNK(statbuf.st_mode);
}

// Rekursive Funktion zum Sammeln der Verzeichnisstruktur
void collect(const char *path, const char *prefix, int depth, FILE *out_file) {
    int count;
    char **entries = listdir_sorted(path, &count);
    
    if (!entries) {
        return;
    }

    for (int i = 0; i < count; i++) {
        int is_last = (i == count - 1);
        const char *connector = is_last ? "└── " : "├── ";
        
        fprintf(out_file, "%s%s%s\n", prefix, connector, entries[i]);
        
        // Erstelle den vollständigen Pfad
        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", path, entries[i]);
        
        // Wenn es ein Verzeichnis ist und nicht zu tief und kein Symlink
        if (depth < MAX_DEPTH && is_directory(full_path) && !is_symlink(full_path)) {
            char next_prefix[MAX_PATH];
            const char *next_connector = is_last ? "    " : "│   ";
            snprintf(next_prefix, sizeof(next_prefix), "%s%s", prefix, next_connector);
            collect(full_path, next_prefix, depth + 1, out_file);
        }
    }
    
    free_entries(entries, count);
}

int main() {
    time_t now;
    struct tm *local_time;
    char timestamp[64];
    
    time(&now);
    local_time = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%S", local_time);
    
    // Erstelle das Ausgabeverzeichnis falls nötig
    char out_dir[MAX_PATH];
    snprintf(out_dir, sizeof(out_dir), "%s/important", ROOT);
    mkdir(out_dir, 0755);
    
    // Öffne die Ausgabedatei
    FILE *out_file = fopen(OUT, "w");
    if (!out_file) {
        perror("Fehler beim Öffnen der Ausgabedatei");
        return 1;
    }
    
    // Schreibe Header
    fprintf(out_file, 
        "# OpenClaw Workspace Tree\n"
        "# Generiert: %s\n"
        "# Befehl: tree -a -L 6 %s (emuliert via gen_tree.c)\n"
        "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
        ".\n",
        timestamp, ROOT);
    
    // Sammle und schreibe die Verzeichnisstruktur
    collect(ROOT, "", 1, out_file);
    
    fclose(out_file);
    
    // Zähle Zeilen und Bytes in der Ausgabe
    FILE *count_file = fopen(OUT, "r");
    if (count_file) {
        int lines = 0;
        int bytes = 0;
        int c;
        while ((c = fgetc(count_file)) != EOF) {
            bytes++;
            if (c == '\n') {
                lines++;
            }
        }
        fclose(count_file);
        printf("written %s: %d lines, %d bytes\n", OUT, lines, bytes);
    } else {
        printf("written %s\n", OUT);
    }
    
    return 0;
}
