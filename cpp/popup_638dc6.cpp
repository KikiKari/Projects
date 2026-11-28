// abstraction-provenance: {"artifact_sha256": "7225dadd8004a36c985a84f8868c19ef605104a8c962c27e61701da70bd57a8e", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "cpp"}
// popup.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/popup.css
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

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9\", \"source_sha256\": \"460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94\", \"target_language\": \"css\"} */\n";
    file << "/* popup.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  --bg: #0f1115;\n";
    file << "  --card: #171a21;\n";
    file << "  --line: #262b36;\n";
    file << "  --text: #f2f4f8;\n";
    file << "  --muted: #9aa3b2;\n";
    file << "  --accent: #fe2c55;\n";
    file << "  --ok: #22c55e;\n";
    file << "  color-scheme: dark;\n";
    file << "}\n\n";

    file << "@media (prefers-color-scheme: light) {\n";
    file << "  :root {\n";
    file << "    --bg: #fff;\n";
    file << "    --card: #f6f7f9;\n";
    file << "    --line: #e3e6ea;\n";
    file << "    --text: #16191d;\n";
    file << "    --muted: #6b7280;\n";
    file << "  }\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  width: 420px;\n";
    file << "  max-height: 600px;\n";
    file << "  overflow: auto;\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "  font: 14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n";
    file << "}\n\n";

    file << ".wrap {\n";
    file << "  padding: 12px;\n";
    file << "}\n\n";

    file << "header {\n";
    file << "  display: flex;\n";
    file << "  gap: 8px;\n";
    file << "  align-items: center;\n";
    file << "  margin-bottom: 10px;\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  font-size: 14px;\n";
    file << "  margin: 0;\n";
    file << "  font-weight: 650;\n";
    file << "  flex: 1;\n";
    file << "}\n\n";

    file << ".badge {\n";
    file << "  font-size: 11px;\n";
    file << "  font-weight: 700;\n";
    file << "  padding: 3px 9px;\n";
    file << "  border-radius: 99px;\n";
    file << "  background: #2a2f3a;\n";
    file << "  color: var(--muted);\n";
    file << "  display: inline-flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 5px;\n";
    file << "}\n\n";

    file << ".badge.live {\n";
    file << "  background: var(--accent);\n";
    file << "  color: #fff;\n";
    file << "}\n\n";

    file << ".badge .dot {\n";
    file << "  width: 6px;\n";
    file << "  height: 6px;\n";
    file << "  border-radius: 50%;\n";
    file << "  background: currentColor;\n";
    file << "}\n\n";

    file << ".badge.live .dot {\n";
    file << "  animation: pulse 1.6s infinite;\n";
    file << "}\n\n";

    file << "@keyframes pulse {\n";
    file << "  0%, 100% {\n";
    file << "    opacity: 1;\n";
    file << "  }\n";
    file << "  50% {\n";
    file << "    opacity: .25;\n";
    file << "  }\n";
    file << "}\n\n";

    file << ".row {\n";
    file << "  display: flex;\n";
    file << "  gap: 6px;\n";
    file << "  flex-wrap: wrap;\n";
    file << "  align-items: center;\n";
    file << "  margin-bottom: 8px;\n";
    file << "}\n\n";

    file << "input, select, button {\n";
    file << "  font: inherit;\n";
    file << "  border-radius: 7px;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  background: var(--card);\n";
    file << "  color: var(--text);\n";
    file << "  padding: 6px 9px;\n";
    file << "}\n\n";

    file << "button {\n";
    file << "  cursor: pointer;\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << "button.primary {\n";
    file << "  background: var(--accent);\n";
    file << "  border-color: var(--accent);\n";
    file << "  color: #fff;\n";
    file << "}\n\n";

    file << ".player {\n";
    file << "  position: relative;\n";
    file << "  width: 100%;\n";
    file << "  aspect-ratio: 9/16;\n";
    file << "  max-height: 360px;\n";
    file << "  background: #000;\n";
    file << "  border-radius: 10px;\n";
    file << "  overflow: hidden;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  margin: 8px 0;\n";
    file << "}\n\n";

    file << ".player iframe {\n";
    file << "  position: absolute;\n";
    file << "  inset: 0;\n";
    file << "  width: 100%;\n";
    file << "  height: 100%;\n";
    file << "  border: 0;\n";
    file << "}\n\n";

    file << ".placeholder {\n";
    file << "  position: absolute;\n";
    file << "  inset: 0;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  gap: 6px;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  color: var(--muted);\n";
    file << "  text-align: center;\n";
    file << "  padding: 16px;\n";
    file << "  font-size: 13px;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  background: var(--card);\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 10px;\n";
    file << "  padding: 10px 12px;\n";
    file << "  margin-bottom: 8px;\n";
    file << "}\n\n";

    file << "h2 {\n";
    file << "  font-size: 11px;\n";
    file << "  text-transform: uppercase;\n";
    file << "  letter-spacing: .05em;\n";
    file << "  color: var(--muted);\n";
    file << "  margin: 0 0 6px;\n";
    file << "  font-weight: 650;\n";
    file << "}\n\n";

    file << ".meta {\n";
    file << "  color: var(--muted);\n";
    file << "  font-size: 12.5px;\n";
    file << "}\n\n";

    file << ".strong {\n";
    file << "  color: var(--text);\n";
    file << "  font-weight: 600;\n";
    file << "}\n\n";

    file << ".stream {\n";
    file << "  display: flex;\n";
    file << "  gap: 8px;\n";
    file << "  padding: 5px 0;\n";
    file << "  border-bottom: 1px solid var(--line);\n";
    file << "  font-size: 12.5px;\n";
    file << "}\n\n";

    file << ".stream:last-child {\n";
    file << "  border-bottom: 0;\n";
    file << "}\n\n";

    file << ".stream .when {\n";
    file << "  color: var(--muted);\n";
    file << "  white-space: nowrap;\n";
    file << "  font-variant-numeric: tabular-nums;\n";
    file << "}\n\n";

    file << ".stream .t {\n";
    file << "  flex: 1;\n";
    file << "  min-width: 0;\n";
    file << "  overflow: hidden;\n";
    file << "  text-overflow: ellipsis;\n";
    file << "  white-space: nowrap;\n";
    file << "}\n\n";

    file << ".stream.now {\n";
    file << "  color: var(--accent);\n";
    file << "  font-weight: 650;\n";
    file << "}\n\n";

    file << ".err {\n";
    file << "  background: #3a1d22;\n";
    file << "  border: 1px solid #5c2a33;\n";
    file << "  color: #ffb4c0;\n";
    file << "  padding: 8px 10px;\n";
    file << "  border-radius: 8px;\n";
    file << "  font-size: 12.5px;\n";
    file << "  margin-bottom: 8px;\n";
    file << "}\n\n";

    file << "@media (prefers-color-scheme: light) {\n";
    file << "  .err {\n";
    file << "    background: #fdeceb;\n";
    file << "    border-color: #f5c6c2;\n";
    file << "    color: #b91c1c;\n";
    file << "  }\n";
    file << "}\n\n";

    file << ".note {\n";
    file << "  font-size: 11.5px;\n";
    file << "  color: var(--muted);\n";
    file << "  line-height: 1.4;\n";
    file << "  margin-top: 8px;\n";
    file << "}\n\n";

    file << "a {\n";
    file << "  color: var(--accent);\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <Ausgabedatei>" << std::endl;
        return 1;
    }

    writeCSS(argv[1]);
    return 0;
}
