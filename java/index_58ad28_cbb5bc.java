// abstraction-provenance: {"artifact_sha256": "b1ce20416d9e093d6371405610c0fb8830763dd252d021c991ebe0db37d89d86", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "java"}
// index_58ad28.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class CSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie den Dateipfad als Parameter an.");
            System.exit(1);
        }

        String filePath = args[0];
        try {
            generateCSS(filePath);
            System.out.println("CSS erfolgreich in " + filePath + " geschrieben.");
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der CSS-Datei: " + e.getMessage());
        }
    }

    private static void generateCSS(String filePath) throws IOException {
        StringBuilder css = new StringBuilder();

        // Root Variablen für Light Mode
        css.append(":root {\n");
        css.append("  --bg: #ffffff;\n");
        css.append("  --soft: #f6f7f9;\n");
        css.append("  --line: #e3e6ea;\n");
        css.append("  --text: #16191d;\n");
        css.append("  --muted: #5f6773;\n");
        css.append("  --tg: #2481cc;\n");
        css.append("  --tg-soft: #e8f2fb;\n");
        css.append("  --tt: #fe2c55;\n");
        css.append("  --ok: #15803d;\n");
        css.append("  --ok-soft: #e7f6ec;\n");
        css.append("  --warn: #b45309;\n");
        css.append("  --warn-soft: #fdf3e3;\n");
        css.append("  color-scheme: light;\n");
        css.append("}\n\n");

        // Dark Mode Media Query
        css.append("@media (prefers-color-scheme: dark) {\n");
        css.append("  :root {\n");
        css.append("    --bg: #0f1115;\n");
        css.append("    --soft: #171a21;\n");
        css.append("    --line: #262b36;\n");
        css.append("    --text: #f2f4f8;\n");
        css.append("    --muted: #9aa3b2;\n");
        css.append("    --tg-soft: #132a3d;\n");
        css.append("    --ok-soft: #12261a;\n");
        css.append("    --warn-soft: #2c2110;\n");
        css.append("    color-scheme: dark;\n");
        css.append("  }\n");
        css.append("}\n\n");

        // Globale Styles
        css.append("* {\n");
        css.append("  box-sizing: border-box;\n");
        css.append("}\n\n");

        css.append("body {\n");
        css.append("  margin: 0;\n");
        css.append("  background: var(--bg);\n");
        css.append("  color: var(--text);\n");
        css.append("  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n");
        css.append("}\n\n");

        css.append(".wrap {\n");
        css.append("  max-width: 820px;\n");
        css.append("  margin: 0 auto;\n");
        css.append("  padding: 0 20px 72px;\n");
        css.append("}\n\n");

        css.append("header {\n");
        css.append("  padding: 64px 0 40px;\n");
        css.append("  border-bottom: 1px solid var(--line);\n");
        css.append("  margin-bottom: 8px;\n");
        css.append("}\n\n");

        css.append("h1 {\n");
        css.append("  font-size: 34px;\n");
        css.append("  line-height: 1.2;\n");
        css.append("  margin: 0 0 12px;\n");
        css.append("  letter-spacing: -0.02em;\n");
        css.append("}\n\n");

        css.append(".lede {\n");
        css.append("  font-size: 18px;\n");
        css.append("  color: var(--muted);\n");
        css.append("  margin: 0 0 22px;\n");
        css.append("  max-width: 60ch;\n");
        css.append("}\n\n");

        css.append("h2 {\n");
        css.append("  font-size: 13px;\n");
        css.append("  margin: 44px 0 14px;\n");
        css.append("  text-transform: uppercase;\n");
        css.append("  letter-spacing: 0.06em;\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-weight: 650;\n");
        css.append("}\n\n");

        css.append("h3 {\n");
        css.append("  font-size: 17px;\n");
        css.append("  margin: 26px 0 6px;\n");
        css.append("}\n\n");

        css.append("p {\n");
        css.append("  margin: 0 0 14px;\n");
        css.append("  max-width: 68ch;\n");
        css.append("}\n\n");

        css.append(".badges {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 7px;\n");
        css.append("  flex-wrap: wrap;\n");
        css.append("  margin-bottom: 22px;\n");
        css.append("}\n\n");

        css.append(".badge {\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 650;\n");
        css.append("  padding: 4px 11px;\n");
        css.append("  border-radius: 99px;\n");
        css.append("  background: var(--soft);\n");
        css.append("  color: var(--muted);\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("}\n\n");

        css.append(".badge.on {\n");
        css.append("  background: var(--ok-soft);\n");
        css.append("  color: var(--ok);\n");
        css.append("  border-color: transparent;\n");
        css.append("}\n\n");

        css.append(".cta {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 10px;\n");
        css.append("  flex-wrap: wrap;\n");
        css.append("}\n\n");

        css.append(".btn {\n");
        css.append("  display: inline-block;\n");
        css.append("  font-weight: 650;\n");
        css.append("  font-size: 15px;\n");
        css.append("  padding: 11px 20px;\n");
        css.append("  border-radius: 9px;\n");
        css.append("  text-decoration: none;\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  background: var(--bg);\n");
        css.append("  color: var(--text);\n");
        css.append("}\n\n");

        css.append(".btn.primary {\n");
        css.append("  background: var(--tg);\n");
        css.append("  border-color: var(--tg);\n");
        css.append("  color: #fff;\n");
        css.append("}\n\n");

        css.append(".btn:hover {\n");
        css.append("  border-color: var(--tg);\n");
        css.append("}\n\n");

        css.append(".grid {\n");
        css.append("  display: grid;\n");
        css.append("  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));\n");
        css.append("  gap: 14px;\n");
        css.append("}\n\n");

        css.append(".card {\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 12px;\n");
        css.append("  padding: 16px 18px;\n");
        css.append("  background: var(--bg);\n");
        css.append("}\n\n");

        css.append(".card h3 {\n");
        css.append("  margin-top: 0;\n");
        css.append("  font-size: 15.5px;\n");
        css.append("}\n\n");

        css.append(".card p {\n");
        css.append("  font-size: 14px;\n");
        css.append("  color: var(--muted);\n");
        css.append("  margin: 0;\n");
        css.append("}\n\n");

        css.append("ol.steps {\n");
        css.append("  list-style: none;\n");
        css.append("  counter-reset: s;\n");
        css.append("  padding: 0;\n");
        css.append("  margin: 0;\n");
        css.append("}\n\n");

        css.append("ol.steps li {\n");
        css.append("  counter-increment: s;\n");
        css.append("  position: relative;\n");
        css.append("  padding: 0 0 20px 40px;\n");
        css.append("  border-left: 2px solid var(--line);\n");
        css.append("  margin-left: 11px;\n");
        css.append("}\n\n");

        css.append("ol.steps li:last-child {\n");
        css.append("  border-left-color: transparent;\n");
        css.append("  padding-bottom: 0;\n");
        css.append("}\n\n");

        css.append("ol.steps li::before {\n");
        css.append("  content: counter(s);\n");
        css.append("  position: absolute;\n");
        css.append("  left: -13px;\n");
        css.append("  top: 0;\n");
        css.append("  width: 24px;\n");
        css.append("  height: 24px;\n");
        css.append("  border-radius: 50%;\n");
        css.append("  background: var(--tg);\n");
        css.append("  color: #fff;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 700;\n");
        css.append("}\n\n");

        css.append("ol.steps b {\n");
        css.append("  display: block;\n");
        css.append("  margin-bottom: 3px;\n");
        css.append("}\n\n");

        css.append("ol.steps p {\n");
        css.append("  font-size: 14.5px;\n");
        css.append("  color: var(--muted);\n");
        css.append("  margin: 0 0 8px;\n");
        css.append("}\n\n");

        css.append("code {\n");
        css.append("  background: var(--soft);\n");
        css.append("  padding: 2px 7px;\n");
        css.append("  border-radius: 5px;\n");
        css.append("  font-size: 13.5px;\n");
        css.append("  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n");
        css.append("  word-break: break-word;\n");
        css.append("}\n\n");

        css.append("pre {\n");
        css.append("  background: var(--soft);\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 10px;\n");
        css.append("  padding: 13px 15px;\n");
        css.append("  overflow-x: auto;\n");
        css.append("  margin: 0 0 14px;\n");
        css.append("}\n\n");

        css.append("pre code {\n");
        css.append("  background: none;\n");
        css.append("  padding: 0;\n");
        css.append("  font-size: 13.5px;\n");
        css.append("  line-height: 1.7;\n");
        css.append("}\n\n");

        css.append("table {\n");
        css.append("  width: 100%;\n");
        css.append("  border-collapse: collapse;\n");
        css.append("  font-size: 14.5px;\n");
        css.append("  margin: 0 0 16px;\n");
        css.append("}\n\n");

        css.append("th,\n");
        css.append("td {\n");
        css.append("  text-align: left;\n");
        css.append("  padding: 9px 11px;\n");
        css.append("  border-bottom: 1px solid var(--line);\n");
        css.append("  vertical-align: top;\n");
        css.append("}\n\n");

        css.append("th {\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-size: 12px;\n");
        css.append("  text-transform: uppercase;\n");
        css.append("  letter-spacing: 0.04em;\n");
        css.append("  font-weight: 650;\n");
        css.append("}\n\n");

        css.append(".note {\n");
        css.append("  border-left: 3px solid var(--warn);\n");
        css.append("  background: var(--warn-soft);\n");
        css.append("  border-radius: 0 9px 9px 0;\n");
        css.append("  padding: 13px 16px;\n");
        css.append("  margin: 0 0 16px;\n");
        css.append("  font-size: 14.5px;\n");
        css.append("}\n\n");

        css.append(".note b {\n");
        css.append("  display: block;\n");
        css.append("  margin-bottom: 3px;\n");
        css.append("}\n\n");

        css.append("a {\n");
        css.append("  color: var(--tg);\n");
        css.append("}\n\n");

        css.append("footer {\n");
        css.append("  margin-top: 52px;\n");
        css.append("  padding-top: 22px;\n");
        css.append("  border-top: 1px solid var(--line);\n");
        css.append("  font-size: 13.5px;\n");
        css.append("  color: var(--muted);\n");
        css.append("}\n");

        // Schreibe CSS in Datei
        Files.write(Paths.get(filePath), css.toString().getBytes());
    }
}
