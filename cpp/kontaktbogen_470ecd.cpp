// abstraction-provenance: {"artifact_sha256": "8c38e5d45497bb1d4d1dbe06c4928048ecaa05561ef12356f37270e6b5934264", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "cpp"}
// kontaktbogen.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << std::endl;
        return;
    }

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */\n";
    file << "/* kontaktbogen.html — portiert nach css */\n";
    file << "/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  --bg: #FAF8F4;\n";
    file << "  --ink: #1B1A17;\n";
    file << "  --muted: #6E6A61;\n";
    file << "  --line: #E5E1D8;\n";
    file << "  --accent: #A8542F;\n";
    file << "  --accent-2: #2E7D7B;\n";
    file << "  --surface: #fff;\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  font-family: 'Hanken Grotesk', system-ui, sans-serif;\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--ink);\n";
    file << "  line-height: 1.5;\n";
    file << "}\n\n";

    file << "header {\n";
    file << "  padding: 2.5rem 2rem 1rem;\n";
    file << "  border-bottom: 1px solid var(--line);\n";
    file << "  background: var(--surface);\n";
    file << "  position: sticky;\n";
    file << "  top: 0;\n";
    file << "  z-index: 10;\n";
    file << "}\n\n";

    file << "header h1 {\n";
    file << "  margin: 0 0 .5rem;\n";
    file << "  font-family: 'Newsreader', Georgia, serif;\n";
    file << "  font-weight: 400;\n";
    file << "  font-size: 2.25rem;\n";
    file << "}\n\n";

    file << "header p {\n";
    file << "  margin: .25rem 0;\n";
    file << "  color: var(--muted);\n";
    file << "  max-width: 80ch;\n";
    file << "}\n\n";

    file << ".legend {\n";
    file << "  display: flex;\n";
    file << "  gap: 1rem;\n";
    file << "  flex-wrap: wrap;\n";
    file << "  margin-top: .75rem;\n";
    file << "  font-size: .8125rem;\n";
    file << "}\n\n";

    file << ".pill {\n";
    file << "  padding: .15rem .6rem;\n";
    file << "  border-radius: 999px;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  background: #fff;\n";
    file << "}\n\n";

    file << ".pill.pflicht {\n";
    file << "  border-color: var(--accent);\n";
    file << "  color: var(--accent);\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << ".pill.auswahl {\n";
    file << "  border-color: var(--accent-2);\n";
    file << "  color: var(--accent-2);\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << "main {\n";
    file << "  padding: 2rem;\n";
    file << "  max-width: 1400px;\n";
    file << "  margin: 0 auto;\n";
    file << "}\n\n";

    file << "section {\n";
    file << "  margin: 2.5rem 0;\n";
    file << "}\n\n";

    file << "section h2 {\n";
    file << "  font-family: 'Newsreader', serif;\n";
    file << "  font-weight: 400;\n";
    file << "  font-size: 1.5rem;\n";
    file << "  margin: 0 0 .25rem;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: .75rem;\n";
    file << "}\n\n";

    file << "section .sub {\n";
    file << "  color: var(--muted);\n";
    file << "  font-size: .875rem;\n";
    file << "  margin: 0 0 1.25rem;\n";
    file << "}\n\n";

    file << ".grid {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));\n";
    file << "  gap: 1rem;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  background: var(--surface);\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 10px;\n";
    file << "  overflow: hidden;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "}\n\n";

    file << ".card .imgwrap {\n";
    file << "  aspect-ratio: 1;\n";
    file << "  background: #f1eee7;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  overflow: hidden;\n";
    file << "}\n\n";

    file << ".card img {\n";
    file << "  width: 100%;\n";
    file << "  height: 100%;\n";
    file << "  object-fit: contain;\n";
    file << "  background: #fff;\n";
    file << "}\n\n";

    file << ".card .meta {\n";
    file << "  padding: .6rem .75rem .75rem;\n";
    file << "  font-size: .78125rem;\n";
    file << "}\n\n";

    file << ".card .name {\n";
    file << "  font-family: 'JetBrains Mono', monospace;\n";
    file << "  font-size: .6875rem;\n";
    file << "  color: var(--muted);\n";
    file << "  word-break: break-all;\n";
    file << "  line-height: 1.3;\n";
    file << "  margin-bottom: .35rem;\n";
    file << "}\n\n";

    file << ".card .dims {\n";
    file << "  color: var(--muted);\n";
    file << "  font-size: .6875rem;\n";
    file << "  margin-bottom: .35rem;\n";
    file << "}\n\n";

    file << ".card .prompt {\n";
    file << "  color: var(--ink);\n";
    file << "  font-size: .75rem;\n";
    file << "  line-height: 1.35;\n";
    file << "  font-style: italic;\n";
    file << "  border-top: 1px solid var(--line);\n";
    file << "  padding-top: .4rem;\n";
    file << "  margin-top: .35rem;\n";
    file << "  max-height: 5.5em;\n";
    file << "  overflow: hidden;\n";
    file << "}\n\n";

    file << ".tag {\n";
    file << "  display: inline-block;\n";
    file << "  padding: .1rem .45rem;\n";
    file << "  border-radius: 999px;\n";
    file << "  font-size: .6875rem;\n";
    file << "  background: #F1EEE7;\n";
    file << "  color: var(--muted);\n";
    file << "  margin-right: .25rem;\n";
    file << "}\n\n";

    file << ".tag.p {\n";
    file << "  background: #F1E5DD;\n";
    file << "  color: var(--accent);\n";
    file << "}\n\n";

    file << ".tag.a {\n";
    file << "  background: #DEEDEC;\n";
    file << "  color: var(--accent-2);\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>" << std::endl;
        return 1;
    }

    writeCSS(argv[1]);
    return 0;
}
