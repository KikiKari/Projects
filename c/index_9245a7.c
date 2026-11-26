// abstraction-provenance: {"artifact_sha256": "8a8805125b5c63d300f57b915607aa194f97e613e17f991ba6b60f2bbe9c9461", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "<meta charset=\"utf-8\">\n");
    fprintf(file, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">\n");
    fprintf(file, "<title>Weiterleitung zur 3D-Ansicht</title>\n");
    fprintf(file, "<link rel=\"canonical\" href=\"3d.html\">\n");
    fprintf(file, "<script>location.replace('3d.html');</script>\n");
    fprintf(file, "</head>\n");
}

void write_html_body(FILE *file) {
    fprintf(file, "<body>\n");
    fprintf(file, "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>\n");
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

int main(int argc, char *argv[]) {
    FILE *output_file;
    
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <ausgabedatei>\n", argv[0]);
        return 1;
    }
    
    output_file = fopen(argv[1], "w");
    if (output_file == NULL) {
        perror("Fehler beim Öffnen der Datei");
        return 1;
    }
    
    write_html_header(output_file);
    write_html_body(output_file);
    
    fclose(output_file);
    return 0;
}
