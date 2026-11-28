// abstraction-provenance: {"artifact_sha256": "f44df5767990cc8899364ca95cb82093ee4118a4435313ded3bbbc9000317424", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "cpp"}
// index_57e3e2.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
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

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  color-scheme: light;\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n";
    file << "  background: #f7f7f5;\n";
    file << "  color: #1d1c1a;\n";
    file << "}\n\n";

    file << ".wrap {\n";
    file << "  max-width: 880px;\n";
    file << "  margin: 0 auto;\n";
    file << "  padding: 20px 16px 60px;\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  font-size: 22px;\n";
    file << "  margin: 0 0 2px;\n";
    file << "}\n\n";

    file << ".sub {\n";
    file << "  color: #6b6a66;\n";
    file << "  font-size: 13px;\n";
    file << "  margin-bottom: 16px;\n";
    file << "}\n\n";

    file << ".bar {\n";
    file << "  display: flex;\n";
    file << "  gap: 10px;\n";
    file << "  align-items: center;\n";
    file << "  margin-bottom: 16px;\n";
    file << "  flex-wrap: wrap;\n";
    file << "}\n\n";

    file << "button {\n";
    file << "  font-size: 13px;\n";
    file << "  font-weight: 600;\n";
    file << "  padding: 7px 13px;\n";
    file << "  border: 1px solid #d9d8d3;\n";
    file << "  border-radius: 8px;\n";
    file << "  background: #fff;\n";
    file << "  cursor: pointer;\n";
    file << "}\n\n";

    file << "button:hover {\n";
    file << "  background: #f2f1ec;\n";
    file << "}\n\n";

    file << "button.primary {\n";
    file << "  background: #1d1c1a;\n";
    file << "  color: #fff;\n";
    file << "  border-color: #1d1c1a;\n";
    file << "}\n\n";

    file << ".note {\n";
    file << "  background: #fffdf4;\n";
    file << "  border: 1px solid #f0e9c8;\n";
    file << "  border-radius: 10px;\n";
    file << "  padding: 12px 14px;\n";
    file << "  font-size: 13px;\n";
    file << "  color: #4a4734;\n";
    file << "  margin-bottom: 16px;\n";
    file << "  line-height: 1.5;\n";
    file << "}\n\n";

    file << ".section {\n";
    file << "  background: #fff;\n";
    file << "  border: 1px solid #e8e7e3;\n";
    file << "  border-radius: 12px;\n";
    file << "  margin-bottom: 14px;\n";
    file << "  overflow: hidden;\n";
    file << "}\n\n";

    file << ".section > h2 {\n";
    file << "  font-size: 15px;\n";
    file << "  margin: 0;\n";
    file << "  padding: 13px 16px;\n";
    file << "  border-bottom: 1px solid #efeee9;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 9px;\n";
    file << "}\n\n";

    file << ".section > h2 .badge {\n";
    file << "  margin-left: auto;\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 600;\n";
    file << "  background: #efeee9;\n";
    file << "  color: #5a5852;\n";
    file << "  padding: 2px 9px;\n";
    file << "  border-radius: 20px;\n";
    file << "}\n\n";

    file << ".body {\n";
    file << "  padding: 8px 16px 14px;\n";
    file << "  font-size: 14px;\n";
    file << "}\n\n";

    file << ".muted {\n";
    file << "  color: #8a8884;\n";
    file << "}\n\n";

    file << ".err {\n";
    file << "  color: #c0392b;\n";
    file << "}\n\n";

    file << ".kv {\n";
    file << "  display: flex;\n";
    file << "  justify-content: space-between;\n";
    file << "  padding: 4px 0;\n";
    file << "  border-bottom: 1px solid #f4f3ee;\n";
    file << "}\n\n";

    file << ".kv:last-child {\n";
    file << "  border: none;\n";
    file << "}\n\n";

    file << ".kv .k {\n";
    file << "  color: #6b6a66;\n";
    file << "}\n\n";

    file << ".kv .v {\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << "a {\n";
    file << "  color: #2b5cc4;\n";
    file << "  text-decoration: none;\n";
    file << "}\n\n";

    file << "a:hover {\n";
    file << "  text-decoration: underline;\n";
    file << "}\n\n";

    file << "/* settings modal */\n";
    file << ".modal {\n";
    file << "  position: fixed;\n";
    file << "  inset: 0;\n";
    file << "  background: rgba(0, 0, 0, .35);\n";
    file << "  display: none;\n";
    file << "  align-items: flex-start;\n";
    file << "  justify-content: center;\n";
    file << "  padding: 40px 16px;\n";
    file << "  overflow: auto;\n";
    file << "}\n\n";

    file << ".modal.open {\n";
    file << "  display: flex;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  background: #fff;\n";
    file << "  border-radius: 14px;\n";
    file << "  max-width: 560px;\n";
    file << "  width: 100%;\n";
    file << "  padding: 20px;\n";
    file << "}\n\n";

    file << ".card h3 {\n";
    file << "  margin: 0 0 4px;\n";
    file << "  font-size: 17px;\n";
    file << "}\n\n";

    file << ".card p.hint {\n";
    file << "  margin: 0 0 16px;\n";
    file << "  font-size: 12px;\n";
    file << "  color: #8a8884;\n";
    file << "}\n\n";

    file << ".field {\n";
    file << "  margin-bottom: 12px;\n";
    file << "}\n\n";

    file << ".field label {\n";
    file << "  display: block;\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 600;\n";
    file << "  color: #5a5852;\n";
    file << "  margin-bottom: 3px;\n";
    file << "}\n\n";

    file << ".field input {\n";
    file << "  width: 100%;\n";
    file << "  font-size: 13px;\n";
    file << "  padding: 7px 9px;\n";
    file << "  border: 1px solid #d9d8d3;\n";
    file << "  border-radius: 7px;\n";
    file << "  font-family: ui-monospace, Menlo, monospace;\n";
    file << "}\n\n";

    file << ".field .desc {\n";
    file << "  font-size: 11px;\n";
    file << "  color: #a8a6a1;\n";
    file << "  margin-top: 2px;\n";
    file << "}\n\n";

    file << ".actions {\n";
    file << "  display: flex;\n";
    file << "  gap: 10px;\n";
    file << "  justify-content: flex-end;\n";
    file << "  margin-top: 8px;\n";
    file << "}\n\n";

    file << ".warn {\n";
    file << "  background: #fdf3f3;\n";
    file << "  border: 1px solid #f3d9d9;\n";
    file << "  color: #9a3b3b;\n";
    file << "  border-radius: 8px;\n";
    file << "  padding: 10px 12px;\n";
    file << "  font-size: 12px;\n";
    file << "  margin-bottom: 14px;\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>\n";
        return 1;
    }

    writeCSS(argv[1]);
    return 0;
}
