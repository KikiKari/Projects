// abstraction-provenance: {"artifact_sha256": "4b56d566f6d8e3e074df696ba31ea8ecf861a0fb969cb22b17b179d19a940a0d", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "c"}
// offscreen.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_document(FILE* file) {
    // Write DOCTYPE
    fprintf(file, "<!doctype html>\n");
    
    // Write HTML opening tag with language attribute
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
    
    // Close HTML tag
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
        perror("Error opening file");
        return 1;
    }
    
    // Write the HTML document structure
    write_html_document(output_file);
    
    // Close file
    fclose(output_file);
    
    return 0;
}
