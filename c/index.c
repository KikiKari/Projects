// abstraction-provenance: {"artifact_sha256": "e6b9766cd90b71aa6cf9a92579db4c62feca1cfcc730885ba9d205f9e6007d35", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "c"}
// index.css — portiert nach c
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_content(FILE *file) {
    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',\n");
    fprintf(file, "    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',\n");
    fprintf(file, "    sans-serif;\n");
    fprintf(file, "  -webkit-font-smoothing: antialiased;\n");
    fprintf(file, "  -moz-osx-font-smoothing: grayscale;\n");
    fprintf(file, "}\n\n");
    fprintf(file, "code {\n");
    fprintf(file, "  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',\n");
    fprintf(file, "    monospace;\n");
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE *output_file = fopen(argv[1], "w");
    if (output_file == NULL) {
        fprintf(stderr, "Error: Could not open file '%s' for writing\n", argv[1]);
        return 1;
    }

    write_css_content(output_file);

    fclose(output_file);
    return 0;
}
