// abstraction-provenance: {"artifact_sha256": "925cb58d28ffa54b5f0219a18916e9613ac0e93e2bb9529d06c2cb7618828504", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "cpp"}
// index_58ad28.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeCSSFile(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << " for writing." << std::endl;
        return;
    }

    // Write the CSS content
    file << "/* abstraction-provenance: {\"artifact_sha256\": \"537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f\", \"source_sha256\": \"58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@Telegram-Monitor:public/index.html */\n";
    file << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root {\n";
    file << "  --bg: #ffffff;\n";
    file << "  --soft: #f6f7f9;\n";
    file << "  --line: #e3e6ea;\n";
    file << "  --text: #16191d;\n";
    file << "  --muted: #5f6773;\n";
    file << "  --tg: #2481cc;\n";
    file << "  --tg-soft: #e8f2fb;\n";
    file << "  --tt: #fe2c55;\n";
    file << "  --ok: #15803d;\n";
    file << "  --ok-soft: #e7f6ec;\n";
    file << "  --warn: #b45309;\n";
    file << "  --warn-soft: #fdf3e3;\n";
    file << "  color-scheme: light;\n";
    file << "}\n\n";

    file << "@media (prefers-color-scheme: dark) {\n";
    file << "  :root {\n";
    file << "    --bg: #0f1115;\n";
    file << "    --soft: #171a21;\n";
    file << "    --line: #262b36;\n";
    file << "    --text: #f2f4f8;\n";
    file << "    --muted: #9aa3b2;\n";
    file << "    --tg-soft: #132a3d;\n";
    file << "    --ok-soft: #12261a;\n";
    file << "    --warn-soft: #2c2110;\n";
    file << "    color-scheme: dark;\n";
    file << "  }\n";
    file << "}\n\n";

    file << "* {\n";
    file << "  box-sizing: border-box;\n";
    file << "}\n\n";

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n";
    file << "}\n\n";

    file << ".wrap {\n";
    file << "  max-width: 820px;\n";
    file << "  margin: 0 auto;\n";
    file << "  padding: 0 20px 72px;\n";
    file << "}\n\n";

    file << "header {\n";
    file << "  padding: 64px 0 40px;\n";
    file << "  border-bottom: 1px solid var(--line);\n";
    file << "  margin-bottom: 8px;\n";
    file << "}\n\n";

    file << "h1 {\n";
    file << "  font-size: 34px;\n";
    file << "  line-height: 1.2;\n";
    file << "  margin: 0 0 12px;\n";
    file << "  letter-spacing: -0.02em;\n";
    file << "}\n\n";

    file << ".lede {\n";
    file << "  font-size: 18px;\n";
    file << "  color: var(--muted);\n";
    file << "  margin: 0 0 22px;\n";
    file << "  max-width: 60ch;\n";
    file << "}\n\n";

    file << "h2 {\n";
    file << "  font-size: 13px;\n";
    file << "  margin: 44px 0 14px;\n";
    file << "  text-transform: uppercase;\n";
    file << "  letter-spacing: 0.06em;\n";
    file << "  color: var(--muted);\n";
    file << "  font-weight: 650;\n";
    file << "}\n\n";

    file << "h3 {\n";
    file << "  font-size: 17px;\n";
    file << "  margin: 26px 0 6px;\n";
    file << "}\n\n";

    file << "p {\n";
    file << "  margin: 0 0 14px;\n";
    file << "  max-width: 68ch;\n";
    file << "}\n\n";

    file << ".badges {\n";
    file << "  display: flex;\n";
    file << "  gap: 7px;\n";
    file << "  flex-wrap: wrap;\n";
    file << "  margin-bottom: 22px;\n";
    file << "}\n\n";

    file << ".badge {\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 650;\n";
    file << "  padding: 4px 11px;\n";
    file << "  border-radius: 99px;\n";
    file << "  background: var(--soft);\n";
    file << "  color: var(--muted);\n";
    file << "  border: 1px solid var(--line);\n";
    file << "}\n\n";

    file << ".badge.on {\n";
    file << "  background: var(--ok-soft);\n";
    file << "  color: var(--ok);\n";
    file << "  border-color: transparent;\n";
    file << "}\n\n";

    file << ".cta {\n";
    file << "  display: flex;\n";
    file << "  gap: 10px;\n";
    file << "  flex-wrap: wrap;\n";
    file << "}\n\n";

    file << ".btn {\n";
    file << "  display: inline-block;\n";
    file << "  font-weight: 650;\n";
    file << "  font-size: 15px;\n";
    file << "  padding: 11px 20px;\n";
    file << "  border-radius: 9px;\n";
    file << "  text-decoration: none;\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "}\n\n";

    file << ".btn.primary {\n";
    file << "  background: var(--tg);\n";
    file << "  border-color: var(--tg);\n";
    file << "  color: #fff;\n";
    file << "}\n\n";

    file << ".btn:hover {\n";
    file << "  border-color: var(--tg);\n";
    file << "}\n\n";

    file << ".grid {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));\n";
    file << "  gap: 14px;\n";
    file << "}\n\n";

    file << ".card {\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 12px;\n";
    file << "  padding: 16px 18px;\n";
    file << "  background: var(--bg);\n";
    file << "}\n\n";

    file << ".card h3 {\n";
    file << "  margin-top: 0;\n";
    file << "  font-size: 15.5px;\n";
    file << "}\n\n";

    file << ".card p {\n";
    file << "  font-size: 14px;\n";
    file << "  color: var(--muted);\n";
    file << "  margin: 0;\n";
    file << "}\n\n";

    file << "ol.steps {\n";
    file << "  list-style: none;\n";
    file << "  counter-reset: s;\n";
    file << "  padding: 0;\n";
    file << "  margin: 0;\n";
    file << "}\n\n";

    file << "ol.steps li {\n";
    file << "  counter-increment: s;\n";
    file << "  position: relative;\n";
    file << "  padding: 0 0 20px 40px;\n";
    file << "  border-left: 2px solid var(--line);\n";
    file << "  margin-left: 11px;\n";
    file << "}\n\n";

    file << "ol.steps li:last-child {\n";
    file << "  border-left-color: transparent;\n";
    file << "  padding-bottom: 0;\n";
    file << "}\n\n";

    file << "ol.steps li::before {\n";
    file << "  content: counter(s);\n";
    file << "  position: absolute;\n";
    file << "  left: -13px;\n";
    file << "  top: 0;\n";
    file << "  width: 24px;\n";
    file << "  height: 24px;\n";
    file << "  border-radius: 50%;\n";
    file << "  background: var(--tg);\n";
    file << "  color: #fff;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  font-size: 12px;\n";
    file << "  font-weight: 700;\n";
    file << "}\n\n";

    file << "ol.steps b {\n";
    file << "  display: block;\n";
    file << "  margin-bottom: 3px;\n";
    file << "}\n\n";

    file << "ol.steps p {\n";
    file << "  font-size: 14.5px;\n";
    file << "  color: var(--muted);\n";
    file << "  margin: 0 0 8px;\n";
    file << "}\n\n";

    file << "code {\n";
    file << "  background: var(--soft);\n";
    file << "  padding: 2px 7px;\n";
    file << "  border-radius: 5px;\n";
    file << "  font-size: 13.5px;\n";
    file << "  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n";
    file << "  word-break: break-word;\n";
    file << "}\n\n";

    file << "pre {\n";
    file << "  background: var(--soft);\n";
    file << "  border: 1px solid var(--line);\n";
    file << "  border-radius: 10px;\n";
    file << "  padding: 13px 15px;\n";
    file << "  overflow-x: auto;\n";
    file << "  margin: 0 0 14px;\n";
    file << "}\n\n";

    file << "pre code {\n";
    file << "  background: none;\n";
    file << "  padding: 0;\n";
    file << "  font-size: 13.5px;\n";
    file << "  line-height: 1.7;\n";
    file << "}\n\n";

    file << "table {\n";
    file << "  width: 100%;\n";
    file << "  border-collapse: collapse;\n";
    file << "  font-size: 14.5px;\n";
    file << "  margin: 0 0 16px;\n";
    file << "}\n\n";

    file << "th,\n";
    file << "td {\n";
    file << "  text-align: left;\n";
    file << "  padding: 9px 11px;\n";
    file << "  border-bottom: 1px solid var(--line);\n";
    file << "  vertical-align: top;\n";
    file << "}\n\n";

    file << "th {\n";
    file << "  color: var(--muted);\n";
    file << "  font-size: 12px;\n";
    file << "  text-transform: uppercase;\n";
    file << "  letter-spacing: 0.04em;\n";
    file << "  font-weight: 650;\n";
    file << "}\n\n";

    file << ".note {\n";
    file << "  border-left: 3px solid var(--warn);\n";
    file << "  background: var(--warn-soft);\n";
    file << "  border-radius: 0 9px 9px 0;\n";
    file << "  padding: 13px 16px;\n";
    file << "  margin: 0 0 16px;\n";
    file << "  font-size: 14.5px;\n";
    file << "}\n\n";

    file << ".note b {\n";
    file << "  display: block;\n";
    file << "  margin-bottom: 3px;\n";
    file << "}\n\n";

    file << "a {\n";
    file << "  color: var(--tg);\n";
    file << "}\n\n";

    file << "footer {\n";
    file << "  margin-top: 52px;\n";
    file << "  padding-top: 22px;\n";
    file << "  border-top: 1px solid var(--line);\n";
    file << "  font-size: 13.5px;\n";
    file << "  color: var(--muted);\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>" << std::endl;
        return 1;
    }

    writeCSSFile(argv[1]);
    return 0;
}
