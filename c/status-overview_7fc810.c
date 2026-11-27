// abstraction-provenance: {"artifact_sha256": "adc7c1bef39429ac8e71f49cba265ef4486cbc6e8450c36ce240ebdc8e593ba1", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "c"}
// status-overview.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_document(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return;
    }

    // Schreibe DOCTYPE
    fprintf(file, "<!doctype html>\n");
    
    // HTML-Struktur
    fprintf(file, "<html lang=\"de\">");
    fprintf(file, "<head>");
    fprintf(file, "<meta charset=\"utf-8\">");
    fprintf(file, "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
    fprintf(file, "<title>STATUS-Overview</title>");
    fprintf(file, "<link rel=\"stylesheet\" href=\"status-overview.css\">");
    fprintf(file, "</head>");
    fprintf(file, "<body>");
    fprintf(file, "<main id=\"grid\" aria-label=\"LIVE-Übersicht\"></main>");
    fprintf(file, "<script src=\"vendor-mpegts.js\"></script>");
    fprintf(file, "<script src=\"status-overview-player.js\"></script>");
    fprintf(file, "</body>");
    fprintf(file, "</html>");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }

    write_html_document(argv[1]);
    return 0;
}
