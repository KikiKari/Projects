// abstraction-provenance: {"artifact_sha256": "54d6ef0925418bd409575c0ccbc181eebeb902132aec2af7e5cc3ad55d2ac4a9", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_html_document(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (file == NULL) {
        perror("Fehler beim Öffnen der Datei");
        exit(1);
    }

    // Schreibe das HTML-Dokument
    fprintf(file, "<!doctype html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "  <head>\n");
    fprintf(file, "    <meta charset=\"UTF-8\" />\n");
    fprintf(file, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n");
    fprintf(file, "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n");
    fprintf(file, "    <meta name=\"theme-color\" content=\"#ffffff\" />\n");
    fprintf(file, "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n");
    fprintf(file, "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n");
    fprintf(file, "    <title>TikTok LIVE Companion – Dokumentation</title>\n");
    fprintf(file, "  </head>\n");
    fprintf(file, "  <body>\n");
    fprintf(file, "    <div id=\"root\"></div>\n");
    fprintf(file, "    <script type=\"module\" src=\"/src/main.tsx\"></script>\n");
    fprintf(file, "  </body>\n");
    fprintf(file, "</html>\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }

    write_html_document(argv[1]);
    return 0;
}
