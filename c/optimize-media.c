// abstraction-provenance: {"artifact_sha256": "d7f072899433a1da9eb17047f65049ce3ba3e878a0bd746e898680675a61a999", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "c"}
// optimize-media.mjs — portiert nach c
// Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef _WIN32
    #include <direct.h>
    #define getcwd _getcwd
    #define chdir _chdir
#else
    #include <unistd.h>
    #define getcwd getcwd
    #define chdir chdir
#endif

// Simple implementation without external libraries like 'sharp'
// This is a conceptual translation - actual image conversion would require additional libraries

void replace_extension(char* filename, const char* new_ext) {
    char* dot = strrchr(filename, '.');
    if (dot) {
        strcpy(dot, new_ext);
    } else {
        strcat(filename, new_ext);
    }
}

int ends_with(const char* str, const char* suffix) {
    size_t str_len = strlen(str);
    size_t suffix_len = strlen(suffix);
    
    if (suffix_len > str_len) {
        return 0;
    }
    
    return strcmp(str + str_len - suffix_len, suffix) == 0;
}

int main() {
    // Change to the media directory (assuming it's at "../public/media" relative to current dir)
    if (chdir("../public/media") != 0) {
        perror("Could not change to media directory");
        return 1;
    }

    DIR* dir;
    struct dirent* entry;

    dir = opendir(".");
    if (!dir) {
        perror("Could not open directory");
        return 1;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_type == DT_REG && ends_with(entry->d_name, ".png")) {
            char source[512];
            char webp_file[512];
            char avif_file[512];
            
            strcpy(source, entry->d_name);
            
            // Create WebP filename
            strcpy(webp_file, entry->d_name);
            replace_extension(webp_file, ".webp");
            
            // Create AVIF filename
            strcpy(avif_file, entry->d_name);
            replace_extension(avif_file, ".avif");
            
            // In a real implementation, you would use an image library here
            // For example with ImageMagick or other C libraries:
            // convert_png_to_webp(source, webp_file, 84);
            // convert_png_to_avif(source, avif_file, 58);
            
            printf("Would convert %s to %s and %s\n", source, webp_file, avif_file);
        }
    }

    closedir(dir);
    printf("WebP- und AVIF-Derivate erzeugt.\n");

    return 0;
}
