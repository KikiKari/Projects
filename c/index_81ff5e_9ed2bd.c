// abstraction-provenance: {"artifact_sha256": "ad6339a1ec1ad48179aab468438081c4990a2090a1d1fcadb7c7165dfd240a01", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "c"}
// index_81ff5e.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9\", \"source_sha256\": \"81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, ":root {\n");
    fprintf(file, "  color-scheme: light;\n");
    fprintf(file, "  --ink: #1b1c1f;\n");
    fprintf(file, "  --muted: #6c6e75;\n");
    fprintf(file, "  --faint: #9a9ca3;\n");
    fprintf(file, "  --card: #fff;\n");
    fprintf(file, "  --line: #e9eaee;\n");
    fprintf(file, "  --accent: #5b5bd6;\n");
    fprintf(file, "  --accent2: #7c5cff;\n");
    fprintf(file, "  --ok: #22a06b;\n");
    fprintf(file, "  --err: #e0533d;\n");
    fprintf(file, "  --radius: 16px;\n");
    fprintf(file, "  --shadow: 0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "  min-height: 100vh;\n");
    fprintf(file, "  background: radial-gradient(1100px 560px at 100%% -10%%, #e8ecff 0%%, rgba(232, 236, 255, 0) 55%%),\n");
    fprintf(file, "    linear-gradient(180deg, #eef1f6, #f7f7f8 42%%);\n");
    fprintf(file, "  background-attachment: fixed;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".wrap {\n");
    fprintf(file, "  max-width: 820px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "  padding: 24px 18px 70px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".brand {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 12px;\n");
    fprintf(file, "  margin-bottom: 4px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".mark {\n");
    fprintf(file, "  width: 32px;\n");
    fprintf(file, "  height: 32px;\n");
    fprintf(file, "  border-radius: 9px;\n");
    fprintf(file, "  background: linear-gradient(135deg, var(--accent), var(--accent2));\n");
    fprintf(file, "  box-shadow: 0 4px 12px rgba(91, 91, 214, 0.35);\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  flex: 0 0 auto;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".mark:after {\n");
    fprintf(file, "  content: \"\";\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  inset: 8px;\n");
    fprintf(file, "  border-radius: 4px;\n");
    fprintf(file, "  border: 2px solid rgba(255, 255, 255, 0.92);\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h1 {\n");
    fprintf(file, "  font-size: 21px;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-weight: 700;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".sub {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  margin: 2px 0 16px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card {\n");
    fprintf(file, "  background: var(--card);\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: var(--radius);\n");
    fprintf(file, "  box-shadow: var(--shadow);\n");
    fprintf(file, "  padding: 16px;\n");
    fprintf(file, "  margin-bottom: 14px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card h2 {\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  margin: 0 0 10px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "label.lab {\n");
    fprintf(file, "  display: block;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin: 8px 0 3px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "input,\n");
    fprintf(file, "textarea {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  padding: 8px 10px;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 9px;\n");
    fprintf(file, "  font-family: ui-monospace, Menlo, Consolas, monospace;\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "textarea {\n");
    fprintf(file, "  min-height: 90px;\n");
    fprintf(file, "  white-space: pre;\n");
    fprintf(file, "  overflow: auto;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".row {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn {\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "  padding: 8px 14px;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  box-shadow: var(--shadow);\n");
    fprintf(file, "  transition: transform 0.1s;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn:hover {\n");
    fprintf(file, "  transform: translateY(-1px);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn.primary {\n");
    fprintf(file, "  background: linear-gradient(135deg, var(--accent), var(--accent2));\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "  border-color: transparent;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".btn.sm {\n");
    fprintf(file, "  padding: 5px 9px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".msg {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  margin-left: 6px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".msg.ok {\n");
    fprintf(file, "  color: var(--ok);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".msg.err {\n");
    fprintf(file, "  color: var(--err);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".prov {\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 12px;\n");
    fprintf(file, "  padding: 10px 12px;\n");
    fprintf(file, "  margin-bottom: 10px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".prov h3 {\n");
    fprintf(file, "  margin: 0 0 6px;\n");
    fprintf(file, "  font-size: 13.5px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".kv {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: 180px 1fr auto;\n");
    fprintf(file, "  gap: 6px;\n");
    fprintf(file, "  margin: 4px 0;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".kv input {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  padding: 5px 7px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".kv .k {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".muted {\n");
    fprintf(file, "  color: var(--faint);\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".hide {\n");
    fprintf(file, "  display: none;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".foot {\n");
    fprintf(file, "  color: var(--faint);\n");
    fprintf(file, "  font-size: 11.5px;\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "  margin-top: 18px;\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "a {\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
