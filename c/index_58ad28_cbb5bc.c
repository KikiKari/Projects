// abstraction-provenance: {"artifact_sha256": "dab013c0e193de3f9d9e6f9cc07aab57bd498c600ac160787ed40e29661d3f06", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "c"}
// index_58ad28.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Error opening file");
        return;
    }

    // Write the CSS content
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f\", \"source_sha256\": \"58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@Telegram-Monitor:public/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #ffffff;\n");
    fprintf(file, "  --soft: #f6f7f9;\n");
    fprintf(file, "  --line: #e3e6ea;\n");
    fprintf(file, "  --text: #16191d;\n");
    fprintf(file, "  --muted: #5f6773;\n");
    fprintf(file, "  --tg: #2481cc;\n");
    fprintf(file, "  --tg-soft: #e8f2fb;\n");
    fprintf(file, "  --tt: #fe2c55;\n");
    fprintf(file, "  --ok: #15803d;\n");
    fprintf(file, "  --ok-soft: #e7f6ec;\n");
    fprintf(file, "  --warn: #b45309;\n");
    fprintf(file, "  --warn-soft: #fdf3e3;\n");
    fprintf(file, "  color-scheme: light;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@media (prefers-color-scheme: dark) {\n");
    fprintf(file, "  :root {\n");
    fprintf(file, "    --bg: #0f1115;\n");
    fprintf(file, "    --soft: #171a21;\n");
    fprintf(file, "    --line: #262b36;\n");
    fprintf(file, "    --text: #f2f4f8;\n");
    fprintf(file, "    --muted: #9aa3b2;\n");
    fprintf(file, "    --tg-soft: #132a3d;\n");
    fprintf(file, "    --ok-soft: #12261a;\n");
    fprintf(file, "    --warn-soft: #2c2110;\n");
    fprintf(file, "    color-scheme: dark;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");

    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".wrap {\n");
    fprintf(file, "  max-width: 820px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "  padding: 0 20px 72px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "header {\n");
    fprintf(file, "  padding: 64px 0 40px;\n");
    fprintf(file, "  border-bottom: 1px solid var(--line);\n");
    fprintf(file, "  margin-bottom: 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h1 {\n");
    fprintf(file, "  font-size: 34px;\n");
    fprintf(file, "  line-height: 1.2;\n");
    fprintf(file, "  margin: 0 0 12px;\n");
    fprintf(file, "  letter-spacing: -0.02em;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".lede {\n");
    fprintf(file, "  font-size: 18px;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin: 0 0 22px;\n");
    fprintf(file, "  max-width: 60ch;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h2 {\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  margin: 44px 0 14px;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  letter-spacing: 0.06em;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h3 {\n");
    fprintf(file, "  font-size: 17px;\n");
    fprintf(file, "  margin: 26px 0 6px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "p {\n");
    fprintf(file, "  margin: 0 0 14px;\n");
    fprintf(file, "  max-width: 68ch;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".badges {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 7px;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "  margin-bottom: 22px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".badge {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "  padding: 4px 11px;\n");
    fprintf(file, "  border-radius: 99px;\n");
    fprintf(file, "  background: var(--soft);\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".badge.on {\n");
    fprintf(file, "  background: var(--ok-soft);\n");
    fprintf(file, "  color: var(--ok);\n");
    fprintf(file, "  border-color: transparent;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".cta {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 10px;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn {\n");
    fprintf(file, "  display: inline-block;\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "  font-size: 15px;\n");
    fprintf(file, "  padding: 11px 20px;\n");
    fprintf(file, "  border-radius: 9px;\n");
    fprintf(file, "  text-decoration: none;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn.primary {\n");
    fprintf(file, "  background: var(--tg);\n");
    fprintf(file, "  border-color: var(--tg);\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn:hover {\n");
    fprintf(file, "  border-color: var(--tg);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".grid {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));\n");
    fprintf(file, "  gap: 14px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card {\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 12px;\n");
    fprintf(file, "  padding: 16px 18px;\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card h3 {\n");
    fprintf(file, "  margin-top: 0;\n");
    fprintf(file, "  font-size: 15.5px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card p {\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps {\n");
    fprintf(file, "  list-style: none;\n");
    fprintf(file, "  counter-reset: s;\n");
    fprintf(file, "  padding: 0;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps li {\n");
    fprintf(file, "  counter-increment: s;\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  padding: 0 0 20px 40px;\n");
    fprintf(file, "  border-left: 2px solid var(--line);\n");
    fprintf(file, "  margin-left: 11px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps li:last-child {\n");
    fprintf(file, "  border-left-color: transparent;\n");
    fprintf(file, "  padding-bottom: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps li::before {\n");
    fprintf(file, "  content: counter(s);\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  left: -13px;\n");
    fprintf(file, "  top: 0;\n");
    fprintf(file, "  width: 24px;\n");
    fprintf(file, "  height: 24px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  background: var(--tg);\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 700;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps b {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  margin-bottom: 3px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "ol.steps p {\n");
    fprintf(file, "  font-size: 14.5px;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin: 0 0 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "code {\n");
    fprintf(file, "  background: var(--soft);\n");
    fprintf(file, "  padding: 2px 7px;\n");
    fprintf(file, "  border-radius: 5px;\n");
    fprintf(file, "  font-size: 13.5px;\n");
    fprintf(file, "  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n");
    fprintf(file, "  word-break: break-word;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "pre {\n");
    fprintf(file, "  background: var(--soft);\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  padding: 13px 15px;\n");
    fprintf(file, "  overflow-x: auto;\n");
    fprintf(file, "  margin: 0 0 14px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "pre code {\n");
    fprintf(file, "  background: none;\n");
    fprintf(file, "  padding: 0;\n");
    fprintf(file, "  font-size: 13.5px;\n");
    fprintf(file, "  line-height: 1.7;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "table {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  border-collapse: collapse;\n");
    fprintf(file, "  font-size: 14.5px;\n");
    fprintf(file, "  margin: 0 0 16px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "th,\n");
    fprintf(file, "td {\n");
    fprintf(file, "  text-align: left;\n");
    fprintf(file, "  padding: 9px 11px;\n");
    fprintf(file, "  border-bottom: 1px solid var(--line);\n");
    fprintf(file, "  vertical-align: top;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "th {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  letter-spacing: 0.04em;\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".note {\n");
    fprintf(file, "  border-left: 3px solid var(--warn);\n");
    fprintf(file, "  background: var(--warn-soft);\n");
    fprintf(file, "  border-radius: 0 9px 9px 0;\n");
    fprintf(file, "  padding: 13px 16px;\n");
    fprintf(file, "  margin: 0 0 16px;\n");
    fprintf(file, "  font-size: 14.5px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".note b {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  margin-bottom: 3px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "a {\n");
    fprintf(file, "  color: var(--tg);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "footer {\n");
    fprintf(file, "  margin-top: 52px;\n");
    fprintf(file, "  padding-top: 22px;\n");
    fprintf(file, "  border-top: 1px solid var(--line);\n");
    fprintf(file, "  font-size: 13.5px;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
