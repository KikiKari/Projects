// abstraction-provenance: {"artifact_sha256": "f9d0480a5039addb876dc6508b560efdbb88e9a1f8dd315f170792403ae95a8c", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "cpp"}
// App.css — portiert nach cpp
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void generateCSS(const std::string& filename) {
    std::ofstream file(filename);
    
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << ":root {\n";
    file << "  color-scheme: dark;\n";
    file << "  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n";
    file << "  background: #0b1020;\n";
    file << "  color: #eef2ff;\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  min-width: 320px;\n";
    file << "  min-height: 100vh;\n";
    file << "  background:\n";
    file << "    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),\n";
    file << "    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),\n";
    file << "    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);\n";
    file << "}\n\n";

    file << ".page-shell {\n";
    file << "  min-height: 100vh;\n";
    file << "  display: grid;\n";
    file << "  place-items: center;\n";
    file << "  padding: 2rem;\n";
    file << "}\n\n";

    file << ".hero-card {\n";
    file << "  width: min(100%, 56rem);\n";
    file << "  padding: clamp(2rem, 6vw, 4.5rem);\n";
    file << "  border: 1px solid rgba(148, 163, 184, 0.28);\n";
    file << "  border-radius: 2rem;\n";
    file << "  background: rgba(15, 23, 42, 0.72);\n";
    file << "  box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35);\n";
    file << "  backdrop-filter: blur(18px);\n";
    file << "}\n\n";

    file << ".eyebrow {\n";
    file << "  margin: 0 0 1rem;\n";
    file << "  color: #67e8f9;\n";
    file << "  font-size: 0.8rem;\n";
    file << "  font-weight: 700;\n";
    file << "  letter-spacing: 0.18em;\n";
    file << "  text-transform: uppercase;\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  margin: 0;\n";
    file << "  max-width: 12ch;\n";
    file << "  font-size: clamp(2.75rem, 8vw, 6rem);\n";
    file << "  line-height: 0.95;\n";
    file << "  letter-spacing: -0.06em;\n";
    file << "}\n\n";

    file << ".lead {\n";
    file << "  margin: 1.5rem 0 0;\n";
    file << "  max-width: 42rem;\n";
    file << "  color: #cbd5e1;\n";
    file << "  font-size: clamp(1.05rem, 2vw, 1.35rem);\n";
    file << "  line-height: 1.65;\n";
    file << "}\n\n";

    file << ".link-grid {\n";
    file << "  display: grid;\n";
    file << "  gap: 0.85rem;\n";
    file << "  margin-top: 2rem;\n";
    file << "}\n\n";

    file << ".link-grid a {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: space-between;\n";
    file << "  gap: 1rem;\n";
    file << "  padding: 1rem 1.15rem;\n";
    file << "  border: 1px solid rgba(148, 163, 184, 0.25);\n";
    file << "  border-radius: 1rem;\n";
    file << "  color: #f8fafc;\n";
    file << "  text-decoration: none;\n";
    file << "  background: rgba(255, 255, 255, 0.06);\n";
    file << "}\n\n";

    file << ".link-grid a:hover,\n";
    file << ".link-grid a:focus-visible {\n";
    file << "  border-color: rgba(103, 232, 249, 0.75);\n";
    file << "  outline: none;\n";
    file << "  background: rgba(103, 232, 249, 0.12);\n";
    file << "}\n";

    file.close();
    
    std::cout << "CSS-Datei erfolgreich erstellt: " << filename << std::endl;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }
    
    generateCSS(argv[1]);
    
    return 0;
}
