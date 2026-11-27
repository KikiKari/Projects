// abstraction-provenance: {"artifact_sha256": "b33064687e862feb7d05295b23369dc4252714ca22abb684e41dc8432788ba2e", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_html_document(FILE* file) {
    fprintf(file, "<!doctype html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "  <head>\n");
    fprintf(file, "    <meta charset=\"UTF-8\" />\n");
    fprintf(file, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n");
    fprintf(file, "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n");
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
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE* output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Error opening file");
        return 1;
    }

    write_html_document(output_file);

    fclose(output_file);
    return 0;
}
