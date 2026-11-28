// abstraction-provenance: {"artifact_sha256": "810048e68ce9b1105bd7bde6ecf0528e2342590c6bf68eb9ccacfe9f3c376b92", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "c"}
// node-monitor.css — portiert nach c
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        exit(EXIT_FAILURE);
    }

    // Schreibe CSS-Inhalt in die Datei
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* node-monitor.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, OpenClaw@main:examples/node-monitor.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #0d1117;\n");
    fprintf(file, "  --surface: #161b22;\n");
    fprintf(file, "  --border: #30363d;\n");
    fprintf(file, "  --text: #e6edf3;\n");
    fprintf(file, "  --green: #3fb950;\n");
    fprintf(file, "  --red: #f85149;\n");
    fprintf(file, "  --accent: #58a6ff;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  padding: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  font-family: -apple-system, sans-serif;\n");
    fprintf(file, "  padding: 1.5rem;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h1 {\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "  margin-bottom: 1rem;\n");
    fprintf(file, "  font-size: 1.2rem;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "canvas {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#log {\n");
    fprintf(file, "  margin-top: 1rem;\n");
    fprintf(file, "  height: 140px;\n");
    fprintf(file, "  overflow-y: auto;\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  padding: .75rem;\n");
    fprintf(file, "  font-size: .78rem;\n");
    fprintf(file, "  font-family: monospace;\n");
    fprintf(file, "  color: #8b949e;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#log .err {\n");
    fprintf(file, "  color: var(--red);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#log .ok {\n");
    fprintf(file, "  color: var(--green);\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <dateiname>\n", argv[0]);
        return EXIT_FAILURE;
    }

    write_css_file(argv[1]);
    return EXIT_SUCCESS;
}
