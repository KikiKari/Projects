// abstraction-provenance: {"artifact_sha256": "7eecddb09a43e024c70f8fc5c4ca14ef9305a40fbf1a484f7778ab1dba8cdf81", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "c"}
// index_57e3e2.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_content(FILE *file) {
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
    
    fprintf(file, ":root {\n");
    fprintf(file, "  color-scheme: light;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n");
    fprintf(file, "  background: #f7f7f5;\n");
    fprintf(file, "  color: #1d1c1a;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".wrap {\n");
    fprintf(file, "  max-width: 880px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "  padding: 20px 16px 60px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "h1 {\n");
    fprintf(file, "  font-size: 22px;\n");
    fprintf(file, "  margin: 0 0 2px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".sub {\n");
    fprintf(file, "  color: #6b6a66;\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  margin-bottom: 16px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".bar {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 10px;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  margin-bottom: 16px;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button {\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  padding: 7px 13px;\n");
    fprintf(file, "  border: 1px solid #d9d8d3;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button:hover {\n");
    fprintf(file, "  background: #f2f1ec;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button.primary {\n");
    fprintf(file, "  background: #1d1c1a;\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "  border-color: #1d1c1a;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".note {\n");
    fprintf(file, "  background: #fffdf4;\n");
    fprintf(file, "  border: 1px solid #f0e9c8;\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  padding: 12px 14px;\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  color: #4a4734;\n");
    fprintf(file, "  margin-bottom: 16px;\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".section {\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "  border: 1px solid #e8e7e3;\n");
    fprintf(file, "  border-radius: 12px;\n");
    fprintf(file, "  margin-bottom: 14px;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".section > h2 {\n");
    fprintf(file, "  font-size: 15px;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  padding: 13px 16px;\n");
    fprintf(file, "  border-bottom: 1px solid #efeee9;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 9px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".section > h2 .badge {\n");
    fprintf(file, "  margin-left: auto;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  background: #efeee9;\n");
    fprintf(file, "  color: #5a5852;\n");
    fprintf(file, "  padding: 2px 9px;\n");
    fprintf(file, "  border-radius: 20px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".body {\n");
    fprintf(file, "  padding: 8px 16px 14px;\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".muted {\n");
    fprintf(file, "  color: #8a8884;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".err {\n");
    fprintf(file, "  color: #c0392b;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".kv {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  justify-content: space-between;\n");
    fprintf(file, "  padding: 4px 0;\n");
    fprintf(file, "  border-bottom: 1px solid #f4f3ee;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".kv:last-child {\n");
    fprintf(file, "  border: none;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".kv .k {\n");
    fprintf(file, "  color: #6b6a66;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".kv .v {\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "a {\n");
    fprintf(file, "  color: #2b5cc4;\n");
    fprintf(file, "  text-decoration: none;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "a:hover {\n");
    fprintf(file, "  text-decoration: underline;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "/* settings modal */\n");
    fprintf(file, ".modal {\n");
    fprintf(file, "  position: fixed;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  background: rgba(0, 0, 0, .35);\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "  align-items: flex-start;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  padding: 40px 16px;\n");
    fprintf(file, "  overflow: auto;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".modal.open {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card {\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "  border-radius: 14px;\n");
    fprintf(file, "  max-width: 560px;\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  padding: 20px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card h3 {\n");
    fprintf(file, "  margin: 0 0 4px;\n");
    fprintf(file, "  font-size: 17px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card p.hint {\n");
    fprintf(file, "  margin: 0 0 16px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  color: #8a8884;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".field {\n");
    fprintf(file, "  margin-bottom: 12px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".field label {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  color: #5a5852;\n");
    fprintf(file, "  margin-bottom: 3px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".field input {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  padding: 7px 9px;\n");
    fprintf(file, "  border: 1px solid #d9d8d3;\n");
    fprintf(file, "  border-radius: 7px;\n");
    fprintf(file, "  font-family: ui-monospace, Menlo, monospace;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".field .desc {\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  color: #a8a6a1;\n");
    fprintf(file, "  margin-top: 2px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".actions {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 10px;\n");
    fprintf(file, "  justify-content: flex-end;\n");
    fprintf(file, "  margin-top: 8px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".warn {\n");
    fprintf(file, "  background: #fdf3f3;\n");
    fprintf(file, "  border: 1px solid #f3d9d9;\n");
    fprintf(file, "  color: #9a3b3b;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  padding: 10px 12px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  margin-bottom: 14px;\n");
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }
    
    FILE *output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Error opening file");
        return 1;
    }
    
    write_css_content(output_file);
    
    fclose(output_file);
    return 0;
}
