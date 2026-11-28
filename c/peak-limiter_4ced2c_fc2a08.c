// abstraction-provenance: {"artifact_sha256": "ffcad06a45cdea05c97659e2122bd21d4d2025d2620b0145c3a8314b18b91b6a", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "c"}
// peak-limiter_4ced2c.css — portiert nach c
// Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_content(FILE *file) {
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800\", \"source_sha256\": \"4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* peak-limiter.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */\n");
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
    
    fclose(output_file);
    return 0;
}
