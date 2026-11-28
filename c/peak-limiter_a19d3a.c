// abstraction-provenance: {"artifact_sha256": "7a303775e89bb9c42533149deb49953ee7aa8a20fabef44368aa74f5aa5eaa62", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "c"}
// peak-limiter.css — portiert nach c
// Quelle: css, Projects@abstractions:css/peak-limiter.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_content(FILE *file) {
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d\", \"source_sha256\": \"162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* peak-limiter.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */\n");
    fprintf(file, "/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */\n");
    fprintf(file, "/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */\n");
    fprintf(file, "/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
    
    fprintf(file, "body {\n");
    fprintf(file, "  font: 16px system-ui;\n");
    fprintf(file, "  max-width: 1000px;\n");
    fprintf(file, "  margin: 40px auto;\n");
    fprintf(file, "  padding: 20px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "pre {\n");
    fprintf(file, "  white-space: pre-wrap;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button {\n");
    fprintf(file, "  padding: 12px;\n");
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }
    
    FILE *output_file = fopen(argv[1], "w");
    if (output_file == NULL) {
        perror("Fehler beim Öffnen der Datei");
        return 1;
    }
    
    write_css_content(output_file);
    
    if (fclose(output_file) != 0) {
        perror("Fehler beim Schließen der Datei");
        return 1;
    }
    
    return 0;
}
