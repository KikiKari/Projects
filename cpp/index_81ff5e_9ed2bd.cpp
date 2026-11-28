// abstraction-provenance: {"artifact_sha256": "670a7015380e9e727d278d185ad227e8d4bff71eb3d454a82968ccdaa21845dc", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "cpp"}
// index_81ff5e.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
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

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9\", \"source_sha256\": \"81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  color-scheme: light;\n";
    file << "  --ink: #1b1c1f;\n";
    file << "  --muted: #6c6e75;\n";
    file << "  --faint: #9a9ca3;\n";
    file << "  --card: #fff;\n";
    file << "  --line: #e9eaee;\n";
    file << "  --accent: #5b5bd6;\n";
    file << "  --accent2: #7c5cff;\n";
    file << "  --ok: #22a06b;\n";
    file << "  --err: #e0533d;\n";
    file << "  --radius: 16px;\n";
    file << "  --shadow: 0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06);\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n";
    file << "  color: var(--ink);\n";
    file << "  min-height: 100vh;\n";
    file << "  background: radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%),\n";
    file << "    linear-gradient(180deg, #eef1f6, #f7f7f8 42%);\n";
    file << "  background-attachment: fixed;\n";
    file << "}\n\n";

    file << ".wrap {\n";
    file << "  max-width: 820px;\n";
    file << "  margin: 0 auto;\n";
    file << "  padding: 24px 18px 70px;\n";
    file << "}\n\n";

    file << ".brand {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 12px;\n";
    file << "  margin-bottom: 4px;\n";
    file << "}\n\n";

    file << ".mark {\n";
    file << "  width: 32px;\n";
    file << "  height: 32px;\n";
    file << "  border-radius: 9px;\n";
    file << "  background: linear-gradient(135deg, var(--accent), var(--accent2));\n";
    file << "  box-shadow: 0 4px 12px rgba(91, 91, 214, 0.35);\n";
    file << "  position: relative;\n";
    file << "  flex: 0 0 auto;\n";
    file << "}\n\n";

    file << ".mark:after {\n";
    file << "  content: \"\";\n";
    file << "  position: absolute;\n";
    file << "  inset: 8px;\n";
    file << "  border-radius: 4px;\n";
    file << "  border: 2px solid rgba(255, 255, 255, 0.92);\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  font-size: 21px;\n";
    file << "  margin: 0;\n";
    file << "  font-weight: 700;\n";
    file << "}\n\n";

    file << ".sub {\n";
    file << "  color: var(--muted);\n";
    file << "  font-size: 13px;\n";
    file << "  margin: 2px 0 16px;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  background: var(--card);\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: var(--radius);\n";
    file << "  box-shadow: var(--shadow);\n";
    file << "  padding: 16px;\n";
    file << "  margin-bottom: 14px;\n";
    file << "}\n\n";

    file << ".card h2 {\n";
    file << "  font-size: 14px;\n";
    file << "  margin: 0 0 10px;\n";
    file << "}\n\n";

    file << "label.lab {\n";
    file << "  display: block;\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 600;\n";
    file << "  color: var(--muted);\n";
    file << "  margin: 8px 0 3px;\n";
    file << "}\n\n";

    file << "input,\n";
    file << "textarea {\n";
    file << "  width: 100%;\n";
    file << "  font-size: 13px;\n";
    file << "  padding: 8px 10px;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 9px;\n";
    file << "  font-family: ui-monospace, Menlo, Consolas, monospace;\n";
    file << "  background: #fff;\n";
    file << "}\n\n";

    file << "textarea {\n";
    file << "  min-height: 90px;\n";
    file << "  white-space: pre;\n";
    file << "  overflow: auto;\n";
    file << "}\n\n";

    file << ".row {\n";
    file << "  display: flex;\n";
    file << "  gap: 8px;\n";
    file << "  flex-wrap: wrap;\n";
    file << "  align-items: center;\n";
    file << "}\n\n";

    file << ".btn {\n";
    file << "  font-size: 13px;\n";
    file << "  font-weight: 600;\n";
    file << "  padding: 8px 14px;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 10px;\n";
    file << "  background: #fff;\n";
    file << "  cursor: pointer;\n";
    file << "  box-shadow: var(--shadow);\n";
    file << "  transition: transform 0.1s;\n";
    file << "}\n\n";

    file << ".btn:hover {\n";
    file << "  transform: translateY(-1px);\n";
    file << "}\n\n";

    file << ".btn.primary {\n";
    file << "  background: linear-gradient(135deg, var(--accent), var(--accent2));\n";
    file << "  color: #fff;\n";
    file << "  border-color: transparent;\n";
    file << "}\n\n";

    file << ".btn.sm {\n";
    file << "  padding: 5px 9px;\n";
    file << "  font-size: 12px;\n";
    file << "}\n\n";

    file << ".msg {\n";
    file << "  font-size: 12px;\n";
    file << "  margin-left: 6px;\n";
    file << "}\n\n";

    file << ".msg.ok {\n";
    file << "  color: var(--ok);\n";
    file << "}\n\n";

    file << ".msg.err {\n";
    file << "  color: var(--err);\n";
    file << "}\n\n";

    file << ".prov {\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 12px;\n";
    file << "  padding: 10px 12px;\n";
    file << "  margin-bottom: 10px;\n";
    file << "}\n\n";

    file << ".prov h3 {\n";
    file << "  margin: 0 0 6px;\n";
    file << "  font-size: 13.5px;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 8px;\n";
    file << "}\n\n";

    file << ".kv {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: 180px 1fr auto;\n";
    file << "  gap: 6px;\n";
    file << "  margin: 4px 0;\n";
    file << "  align-items: center;\n";
    file << "}\n\n";

    file << ".kv input {\n";
    file << "  font-size: 12px;\n";
    file << "  padding: 5px 7px;\n";
    file << "}\n\n";

    file << ".kv .k {\n";
    file << "  color: var(--muted);\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << ".muted {\n";
    file << "  color: var(--faint);\n";
    file << "  font-size: 13px;\n";
    file << "}\n\n";

    file << ".hide {\n";
    file << "  display: none;\n";
    file << "}\n\n";

    file << ".foot {\n";
    file << "  color: var(--faint);\n";
    file << "  font-size: 11.5px;\n";
    file << "  text-align: center;\n";
    file << "  margin-top: 18px;\n";
    file << "  line-height: 1.5;\n";
    file << "}\n\n";

    file << "a {\n";
    file << "  color: var(--accent);\n";
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
