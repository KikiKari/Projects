// abstraction-provenance: {"artifact_sha256": "3d883ddd56b5428bb9a5e43d82acb9ecb08090ee72466ebb1064a7038c84901b", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "cpp"}
// status-overview.css — portiert nach cpp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void generateCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    // Schreiben des CSS-Inhalts
    file << "*{box-sizing:border-box}\n";
    file << "html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}\n";
    file << "body{display:flex;flex-direction:column;height:100vh}\n";
    file << "header{display:flex;gap:1em;align-items:baseline;padding:0 12px}\n";
    file << "h1{font-size:17px;margin:8px 0}\n";
    file << "header p{font-size:12px;color:#bbb;margin:0}\n";
    file << "main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}\n";
    file << ".tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}\n";
    file << ".tile h2{font-size:13px;margin:3px 8px}\n";
    file << ".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}\n";
    file << ".tile p{font-size:11px;margin:3px 8px;color:#ddd}\n";
    file << "\n";
    file << "main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}\n";
    file << ".tile[hidden]{display:none}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }

    generateCSS(argv[1]);
    return 0;
}
