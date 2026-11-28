// abstraction-provenance: {"artifact_sha256": "4bccf8c54ac93084c395a3a19952abc61858f352a5c3cb2442edd8902e22c52b", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "c"}
// kontaktbogen.css — portiert nach c
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_content(FILE *file) {
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* kontaktbogen.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
    
    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #FAF8F4;\n");
    fprintf(file, "  --ink: #1B1A17;\n");
    fprintf(file, "  --muted: #6E6A61;\n");
    fprintf(file, "  --line: #E5E1D8;\n");
    fprintf(file, "  --accent: #A8542F;\n");
    fprintf(file, "  --accent-2: #2E7D7B;\n");
    fprintf(file, "  --surface: #fff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-family: 'Hanken Grotesk', system-ui, sans-serif;\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header {\n");
    fprintf(file, "  padding: 2.5rem 2rem 1rem;\n");
    fprintf(file, "  border-bottom: 1px solid var(--line);\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "  position: sticky;\n");
    fprintf(file, "  top: 0;\n");
    fprintf(file, "  z-index: 10;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header h1 {\n");
    fprintf(file, "  margin: 0 0 .5rem;\n");
    fprintf(file, "  font-family: 'Newsreader', Georgia, serif;\n");
    fprintf(file, "  font-weight: 400;\n");
    fprintf(file, "  font-size: 2.25rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header p {\n");
    fprintf(file, "  margin: .25rem 0;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  max-width: 80ch;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".legend {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 1rem;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "  margin-top: .75rem;\n");
    fprintf(file, "  font-size: .8125rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".pill {\n");
    fprintf(file, "  padding: .15rem .6rem;\n");
    fprintf(file, "  border-radius: 999px;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".pill.pflicht {\n");
    fprintf(file, "  border-color: var(--accent);\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".pill.auswahl {\n");
    fprintf(file, "  border-color: var(--accent-2);\n");
    fprintf(file, "  color: var(--accent-2);\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "main {\n");
    fprintf(file, "  padding: 2rem;\n");
    fprintf(file, "  max-width: 1400px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "section {\n");
    fprintf(file, "  margin: 2.5rem 0;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "section h2 {\n");
    fprintf(file, "  font-family: 'Newsreader', serif;\n");
    fprintf(file, "  font-weight: 400;\n");
    fprintf(file, "  font-size: 1.5rem;\n");
    fprintf(file, "  margin: 0 0 .25rem;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: .75rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "section .sub {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-size: .875rem;\n");
    fprintf(file, "  margin: 0 0 1.25rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".grid {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));\n");
    fprintf(file, "  gap: 1rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card {\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card .imgwrap {\n");
    fprintf(file, "  aspect-ratio: 1;\n");
    fprintf(file, "  background: #f1eee7;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card img {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  height: 100%%;\n");
    fprintf(file, "  object-fit: contain;\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card .meta {\n");
    fprintf(file, "  padding: .6rem .75rem .75rem;\n");
    fprintf(file, "  font-size: .78125rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card .name {\n");
    fprintf(file, "  font-family: 'JetBrains Mono', monospace;\n");
    fprintf(file, "  font-size: .6875rem;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  word-break: break-all;\n");
    fprintf(file, "  line-height: 1.3;\n");
    fprintf(file, "  margin-bottom: .35rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card .dims {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-size: .6875rem;\n");
    fprintf(file, "  margin-bottom: .35rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card .prompt {\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "  font-size: .75rem;\n");
    fprintf(file, "  line-height: 1.35;\n");
    fprintf(file, "  font-style: italic;\n");
    fprintf(file, "  border-top: 1px solid var(--line);\n");
    fprintf(file, "  padding-top: .4rem;\n");
    fprintf(file, "  margin-top: .35rem;\n");
    fprintf(file, "  max-height: 5.5em;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".tag {\n");
    fprintf(file, "  display: inline-block;\n");
    fprintf(file, "  padding: .1rem .45rem;\n");
    fprintf(file, "  border-radius: 999px;\n");
    fprintf(file, "  font-size: .6875rem;\n");
    fprintf(file, "  background: #F1EEE7;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin-right: .25rem;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".tag.p {\n");
    fprintf(file, "  background: #F1E5DD;\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".tag.a {\n");
    fprintf(file, "  background: #DEEDEC;\n");
    fprintf(file, "  color: var(--accent-2);\n");
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <ausgabedatei>\n", argv[0]);
        return 1;
    }
    
    FILE *output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Fehler beim Öffnen der Ausgabedatei");
        return 1;
    }
    
    write_css_content(output_file);
    
    fclose(output_file);
    return 0;
}
