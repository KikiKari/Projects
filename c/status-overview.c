// abstraction-provenance: {"artifact_sha256": "54132716ada82bc221e1212924bd5a74c6d379a1c1cb85fdb3f1528d27d30002", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "c"}
// status-overview.css — portiert nach c
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_content(FILE *file) {
    fprintf(file, "*{box-sizing:border-box}html,body{margin:0;min-height:100%%;background:#101015;color:#fff;font:14px system-ui,sans-serif}body{display:flex;flex-direction:column;height:100vh}header{display:flex;gap:1em;align-items:baseline;padding:0 12px}h1{font-size:17px;margin:8px 0}header p{font-size:12px;color:#bbb;margin:0}main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}.tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}.tile h2{font-size:13px;margin:3px 8px}.tile video{min-height:0;width:100%%;flex:1;object-fit:contain;background:#000}.tile p{font-size:11px;margin:3px 8px;color:#ddd}\n\nmain.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}.tile[hidden]{display:none}\n");
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
