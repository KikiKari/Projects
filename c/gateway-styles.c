// abstraction-provenance: {"artifact_sha256": "141362192ec704d837db12acc4a8b9a384fdb568b4e62c979c34282deb2e9763", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "c"}
// gateway-styles.css — portiert nach c
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    // Write CSS content
    fprintf(file, "/* OpenClaw Gateway Dashboard */\n\n");
    
    fprintf(file, "*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n\n");
    
    fprintf(file, ":root {\n");
    fprintf(file, "  --bg:       #0d1117;\n");
    fprintf(file, "  --surface:  #161b22;\n");
    fprintf(file, "  --border:   #30363d;\n");
    fprintf(file, "  --text:     #e6edf3;\n");
    fprintf(file, "  --muted:    #8b949e;\n");
    fprintf(file, "  --green:    #3fb950;\n");
    fprintf(file, "  --yellow:   #d29922;\n");
    fprintf(file, "  --red:      #f85149;\n");
    fprintf(file, "  --accent:   #58a6ff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "body {\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n");
    fprintf(file, "  min-height: 100vh;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 1rem;\n");
    fprintf(file, "  padding: 1.25rem 2rem;\n");
    fprintf(file, "  border-bottom: 1px solid var(--border);\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header h1 { font-size: 1.25rem; color: var(--accent); }\n\n");
    
    fprintf(file, ".badge {\n");
    fprintf(file, "  padding: .25rem .75rem;\n");
    fprintf(file, "  border-radius: 999px;\n");
    fprintf(file, "  font-size: .75rem;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  background: var(--border);\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "}\n");
    fprintf(file, ".badge.ok    { background: #1a3a2a; color: var(--green); }\n");
    fprintf(file, ".badge.warn  { background: #3a2e0a; color: var(--yellow); }\n");
    fprintf(file, ".badge.error { background: #3a1010; color: var(--red); }\n\n");
    
    fprintf(file, "main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n\n");
    
    fprintf(file, ".grid {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));\n");
    fprintf(file, "  gap: 1rem;\n");
    fprintf(file, "  margin-bottom: 2rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card {\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  padding: 1.25rem;\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card h2   { font-size: 1rem; margin-bottom: .25rem; }\n");
    fprintf(file, ".card .endpoint { font-size: .8rem; color: var(--muted); }\n\n");
    
    fprintf(file, ".status-dot {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  top: 1.25rem;\n");
    fprintf(file, "  right: 1.25rem;\n");
    fprintf(file, "  width: 10px;\n");
    fprintf(file, "  height: 10px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  background: var(--border);\n");
    fprintf(file, "}\n");
    fprintf(file, ".status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }\n");
    fprintf(file, ".status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }\n\n");
    
    fprintf(file, ".metrics h2 { font-size: 1rem; margin-bottom: 1rem; }\n\n");
    
    fprintf(file, "table {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  border-collapse: collapse;\n");
    fprintf(file, "  font-size: .875rem;\n");
    fprintf(file, "}\n");
    fprintf(file, "th, td {\n");
    fprintf(file, "  padding: .625rem 1rem;\n");
    fprintf(file, "  text-align: left;\n");
    fprintf(file, "  border-bottom: 1px solid var(--border);\n");
    fprintf(file, "}\n");
    fprintf(file, "th { color: var(--muted); font-weight: 500; }\n");
    fprintf(file, "tr:last-child td { border-bottom: none; }\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output-file>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
