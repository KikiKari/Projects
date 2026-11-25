// abstraction-provenance: {"artifact_sha256": "5e3b7af2e128de1e48d78256a7ec50d8b76b96788fe8265fafa712fc8ad55b7a", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "c"}
// check_conflicts.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <time.h>
#include <openssl/sha.h>

#define CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
#define GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"
#define MAX_PATH 1024

// Function prototypes
void check_conflicts();
char* get_file_hash(const char* filepath);
int is_directory(const char* path);
int compare_strings(const void* a, const void* b);
void get_files_recursive(const char* base_path, const char* dir_path, char*** files, int* count);
char* get_relative_path(const char* base_path, const char* full_path);

/*
Check Conflicts - Erkennt Sync-Konflikte
*/

typedef struct {
    char file[MAX_PATH];
    char clawhub_modified[20];
    char git_modified[20];
    char newer[10];
} FileConflict;

typedef struct {
    char skill[MAX_PATH];
    FileConflict* conflicts;
    int conflict_count;
} Conflict;

/**
 * Prüft auf Konflikte zwischen ClawHub und Git
 */
void check_conflicts() {
    Conflict conflicts[1000];
    int total_conflicts = 0;
    
    // Liste aller Skills in beiden Verzeichnissen
    DIR *clawhub_dir = opendir(CLAWHUB_DIR);
    DIR *git_dir = opendir(GIT_DIR);
    
    if (!clawhub_dir || !git_dir) {
        printf("Fehler beim Öffnen der Verzeichnisse\n");
        return;
    }
    
    // Hole alle Skills aus ClawHub
    char clawhub_skills[1000][MAX_PATH];
    int clawhub_count = 0;
    struct dirent *entry;
    while ((entry = readdir(clawhub_dir)) != NULL) {
        if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            strcpy(clawhub_skills[clawhub_count], entry->d_name);
            clawhub_count++;
        }
    }
    closedir(clawhub_dir);
    
    // Hole alle Skills aus Git
    char git_skills[1000][MAX_PATH];
    int git_count = 0;
    while ((entry = readdir(git_dir)) != NULL) {
        if (entry->d_type == DT_DIR && strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            strcpy(git_skills[git_count], entry->d_name);
            git_count++;
        }
    }
    closedir(git_dir);
    
    // Finde gemeinsame Skills
    char common_skills[1000][MAX_PATH];
    int common_count = 0;
    
    for (int i = 0; i < clawhub_count; i++) {
        for (int j = 0; j < git_count; j++) {
            if (strcmp(clawhub_skills[i], git_skills[j]) == 0) {
                strcpy(common_skills[common_count], clawhub_skills[i]);
                common_count++;
                break;
            }
        }
    }
    
    printf("Prüfe %d Skills auf Konflikte...\n\n", common_count);
    
    // Sortiere Skills alphabetisch
    qsort(common_skills, common_count, sizeof(common_skills[0]), compare_strings);
    
    for (int s = 0; s < common_count; s++) {
        char* skill = common_skills[s];
        char clawhub_path[MAX_PATH];
        char git_path[MAX_PATH];
        
        snprintf(clawhub_path, sizeof(clawhub_path), "%s/%s", CLAWHUB_DIR, skill);
        snprintf(git_path, sizeof(git_path), "%s/%s", GIT_DIR, skill);
        
        // Hole alle Dateien
        char** clawhub_files = NULL;
        int clawhub_file_count = 0;
        get_files_recursive(clawhub_path, clawhub_path, &clawhub_files, &clawhub_file_count);
        
        char** git_files = NULL;
        int git_file_count = 0;
        get_files_recursive(git_path, git_path, &git_files, &git_file_count);
        
        // Vergleiche Dateien
        FileConflict skill_conflicts[1000];
        int skill_conflict_count = 0;
        
        for (int i = 0; i < clawhub_file_count; i++) {
            char* clawhub_rel_path = get_relative_path(clawhub_path, clawhub_files[i]);
            
            for (int j = 0; j < git_file_count; j++) {
                char* git_rel_path = get_relative_path(git_path, git_files[j]);
                
                if (strcmp(clawhub_rel_path, git_rel_path) == 0) {
                    char* clawhub_hash = get_file_hash(clawhub_files[i]);
                    char* git_hash = get_file_hash(git_files[j]);
                    
                    if (strcmp(clawhub_hash, git_hash) != 0) {
                        struct stat clawhub_stat, git_stat;
                        stat(clawhub_files[i], &clawhub_stat);
                        stat(git_files[j], &git_stat);
                        
                        time_t clawhub_mtime = clawhub_stat.st_mtime;
                        time_t git_mtime = git_stat.st_mtime;
                        
                        struct tm* clawhub_tm = localtime(&clawhub_mtime);
                        struct tm* git_tm = localtime(&git_mtime);
                        
                        strftime(skill_conflicts[skill_conflict_count].clawhub_modified, 
                                sizeof(skill_conflicts[skill_conflict_count].clawhub_modified),
                                "%Y-%m-%d %H:%M:%S", clawhub_tm);
                                
                        strftime(skill_conflicts[skill_conflict_count].git_modified,
                                sizeof(skill_conflicts[skill_conflict_count].git_modified),
                                "%Y-%m-%d %H:%M:%S", git_tm);
                                
                        strcpy(skill_conflicts[skill_conflict_count].file, clawhub_rel_path);
                        strcpy(skill_conflicts[skill_conflict_count].newer, 
                               clawhub_mtime > git_mtime ? "clawhub" : "git");
                               
                        skill_conflict_count++;
                    }
                    
                    free(git_rel_path);
                    break;
                }
                
                free(git_rel_path);
            }
            
            free(clawhub_rel_path);
        }
        
        // Speichere Konflikte für diesen Skill
        if (skill_conflict_count > 0) {
            strcpy(conflicts[total_conflicts].skill, skill);
            conflicts[total_conflicts].conflicts = malloc(sizeof(FileConflict) * skill_conflict_count);
            memcpy(conflicts[total_conflicts].conflicts, skill_conflicts, sizeof(FileConflict) * skill_conflict_count);
            conflicts[total_conflicts].conflict_count = skill_conflict_count;
            total_conflicts++;
        }
        
        // Freigabe des Speichers
        for (int i = 0; i < clawhub_file_count; i++) {
            free(clawhub_files[i]);
        }
        free(clawhub_files);
        
        for (int i = 0; i < git_file_count; i++) {
            free(git_files[i]);
        }
        free(git_files);
    }
    
    // Ausgabe
    if (total_conflicts > 0) {
        printf("⚠️  KONFLIKTE GEFUNDEN:\n");
        printf("================================================================================\n");
        
        for (int i = 0; i < total_conflicts; i++) {
            printf("\n📦 Skill: %s\n", conflicts[i].skill);
            printf("----------------------------------------\n");
            
            for (int j = 0; j < conflicts[i].conflict_count; j++) {
                FileConflict* fc = &conflicts[i].conflicts[j];
                printf("  📄 %s\n", fc->file);
                printf("     ClawHub: %s\n", fc->clawhub_modified);
                printf("     Git:     %s\n", fc->git_modified);
                printf("     Neuer:   %s\n", fc->newer);
                printf("\n");
            }
            
            free(conflicts[i].conflicts);
        }
        
        printf("================================================================================\n");
        printf("Gesamt: %d Skills mit Konflikten\n", total_conflicts);
        printf("\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.\n");
    } else {
        printf("✅ Keine Konflikte gefunden!\n");
        printf("Alle gemeinsamen Skills sind synchron.\n");
    }
}

/**
 * Berechnet den SHA256 Hash einer Datei
 */
char* get_file_hash(const char* filepath) {
    static char hash_string[65];
    FILE* file = fopen(filepath, "rb");
    
    if (!file) {
        return "";
    }
    
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    
    unsigned char buffer[8192];
    size_t bytes_read;
    
    while ((bytes_read = fread(buffer, 1, sizeof(buffer), file))) {
        SHA256_Update(&sha256, buffer, bytes_read);
    }
    
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_Final(hash, &sha256);
    
    fclose(file);
    
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(&hash_string[i * 2], "%02x", hash[i]);
    }
    
    return hash_string;
}

/**
 * Prüft ob ein Pfad ein Verzeichnis ist
 */
int is_directory(const char* path) {
    struct stat statbuf;
    if (stat(path, &statbuf) != 0)
        return 0;
    return S_ISDIR(statbuf.st_mode);
}

/**
 * Vergleichsfunktion für qsort
 */
int compare_strings(const void* a, const void* b) {
    return strcmp(*(const char**)a, *(const char**)b);
}

/**
 * Rekursives Sammeln aller Dateien in einem Verzeichnis
 */
void get_files_recursive(const char* base_path, const char* dir_path, char*** files, int* count) {
    DIR* dir = opendir(dir_path);
    if (!dir) return;
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;
        if (strstr(entry->d_name, ".git") != NULL) continue;
        
        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", dir_path, entry->d_name);
        
        if (entry->d_type == DT_DIR) {
            get_files_recursive(base_path, full_path, files, count);
        } else {
            *files = realloc(*files, (*count + 1) * sizeof(char*));
            (*files)[*count] = malloc(strlen(full_path) + 1);
            strcpy((*files)[*count], full_path);
            (*count)++;
        }
    }
    
    closedir(dir);
}

/**
 * Ermittelt den relativen Pfad
 */
char* get_relative_path(const char* base_path, const char* full_path) {
    char* rel_path = malloc(strlen(full_path) + 1);
    if (strlen(full_path) > strlen(base_path) && strncmp(full_path, base_path, strlen(base_path)) == 0) {
        strcpy(rel_path, full_path + strlen(base_path) + 1);
    } else {
        strcpy(rel_path, full_path);
    }
    return rel_path;
}

/**
 * Hauptfunktion
 */
int main() {
    check_conflicts();
    return 0;
}
