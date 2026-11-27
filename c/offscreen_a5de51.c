// abstraction-provenance: {"artifact_sha256": "b03741ee3571b022326bb2679e2a2d3452b49738549e6e82f0935741da6de54c", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "c"}
// offscreen.html — portiert nach c
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_document(FILE* file) {
    // Write DOCTYPE
    fprintf(file, "<!doctype html>\n");
    
    // Write html tag with lang attribute
    fprintf(file, "<html lang=\"de\">\n");
    
    // Write head section
    fprintf(file, "<head>\n");
    fprintf(file, "  <meta charset=\"utf-8\">\n");
    fprintf(file, "  <title>TikTok LIVE Companion Sprachausgabe</title>\n");
    fprintf(file, "</head>\n");
    
    // Write body section
    fprintf(file, "<body>\n");
    fprintf(file, "  <script src=\"offscreen.js\"></script>\n");
    fprintf(file, "</body>\n");
    
    // Close html tag
    fprintf(file, "</html>\n");
}

int main(int argc, char* argv[]) {
    FILE* output_file;
    
    // Check if filename argument is provided
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }
    
    // Open file for writing
    output_file = fopen(argv[1], "w");
    if (output_file == NULL) {
        fprintf(stderr, "Error: Could not open file '%s' for writing\n", argv[1]);
        return 1;
    }
    
    // Write the HTML document
    write_html_document(output_file);
    
    // Close file
    fclose(output_file);
    
    return 0;
}
