// abstraction-provenance: {"artifact_sha256": "727bd1974efe75ad88c655ccb41adb6c46e882584fd593af70844c1c752859f2", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "cpp"}
// node-monitor.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    // Schreibe den CSS-Inhalt
    file << "/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */\n";
    file << "/* node-monitor.html — portiert nach css */\n";
    file << "/* Quelle: html, OpenClaw@main:examples/node-monitor.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  --bg: #0d1117;\n";
    file << "  --surface: #161b22;\n";
    file << "  --border: #30363d;\n";
    file << "  --text: #e6edf3;\n";
    file << "  --green: #3fb950;\n";
    file << "  --red: #f85149;\n";
    file << "  --accent: #58a6ff;\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "  margin: 0;\n";
    file << "  padding: 0;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "  font-family: -apple-system, sans-serif;\n";
    file << "  padding: 1.5rem;\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  color: var(--accent);\n";
    file << "  margin-bottom: 1rem;\n";
    file << "  font-size: 1.2rem;\n";
    file << "}\n\n";

    file << "canvas {\n";
    file << "  display: block;\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 8px;\n";
    file << "  background: var(--surface);\n";
    file << "}\n\n";

    file << "#log {\n";
    file << "  margin-top: 1rem;\n";
    file << "  height: 140px;\n";
    file << "  overflow-y: auto;\n";
    file << "  background: var(--surface);\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 8px;\n";
    file << "  padding: .75rem;\n";
    file << "  font-size: .78rem;\n";
    file << "  font-family: monospace;\n";
    file << "  color: #8b949e;\n";
    file << "}\n\n";

    file << "#log .err {\n";
    file << "  color: var(--red);\n";
    file << "}\n\n";

    file << "#log .ok {\n";
    file << "  color: var(--green);\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }

    writeCSS(argv[1]);
    return 0;
}
