// abstraction-provenance: {"artifact_sha256": "6b067e600e13eb95597d69dc23998905002160ba573fbb61f5a160de7368baba", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "java"}
// index_6925e5.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_6925e5.css
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
        StringBuilder cssContent = new StringBuilder();

        // Root styles
        cssContent.append(":root {\n");
        cssContent.append("  --bg: #fff;\n");
        cssContent.append("  --soft: #f6f7f9;\n");
        cssContent.append("  --line: #e3e6ea;\n");
        cssContent.append("  --text: #16191d;\n");
        cssContent.append("  --muted: #5f6773;\n");
        cssContent.append("  --ac: #6d5bd0;\n");
        cssContent.append("  --ac-soft: #efecfb;\n");
        cssContent.append("  --ok: #15803d;\n");
        cssContent.append("  --ok-soft: #e7f6ec;\n");
        cssContent.append("  --warn: #b45309;\n");
        cssContent.append("  --warn-soft: #fdf3e3;\n");
        cssContent.append("  color-scheme: light;\n");
        cssContent.append("}\n\n");

        // Dark mode media query
        cssContent.append("@media (prefers-color-scheme: dark) {\n");
        cssContent.append("  :root {\n");
        cssContent.append("    --bg: #0f1115;\n");
        cssContent.append("    --soft: #171a21;\n");
        cssContent.append("    --line: #262b36;\n");
        cssContent.append("    --text: #f2f4f8;\n");
        cssContent.append("    --muted: #9aa3b2;\n");
        cssContent.append("    --ac-soft: #1e1a33;\n");
        cssContent.append("    --ok-soft: #12261a;\n");
        cssContent.append("    --warn-soft: #2c2110;\n");
        cssContent.append("    color-scheme: dark;\n");
        cssContent.append("  }\n");
        cssContent.append("}\n\n");

        // Universal selector
        cssContent.append("* {\n");
        cssContent.append("  box-sizing: border-box;\n");
        cssContent.append("}\n\n");

        // Body styles
        cssContent.append("body {\n");
        cssContent.append("  margin: 0;\n");
        cssContent.append("  background: var(--bg);\n");
        cssContent.append("  color: var(--text);\n");
        cssContent.append("  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n");
        cssContent.append("}\n\n");

        // Wrap styles
        cssContent.append(".wrap {\n");
        cssContent.append("  max-width: 840px;\n");
        cssContent.append("  margin: 0 auto;\n");
        cssContent.append("  padding: 0 20px 72px;\n");
        cssContent.append("}\n\n");

        // Header styles
        cssContent.append("header {\n");
        cssContent.append("  padding: 64px 0 36px;\n");
        cssContent.append("  border-bottom: 1px solid var(--line);\n");
        cssContent.append("}\n\n");

        // H1 styles
        cssContent.append("h1 {\n");
        cssContent.append("  font-size: 34px;\n");
        cssContent.append("  line-height: 1.2;\n");
        cssContent.append("  margin: 0 0 12px;\n");
        cssContent.append("  letter-spacing: -0.02em;\n");
        cssContent.append("}\n\n");

        // Lede styles
        cssContent.append(".lede {\n");
        cssContent.append("  font-size: 18px;\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  margin: 0 0 20px;\n");
        cssContent.append("  max-width: 62ch;\n");
        cssContent.append("}\n\n");

        // H2 styles
        cssContent.append("h2 {\n");
        cssContent.append("  font-size: 13px;\n");
        cssContent.append("  margin: 48px 0 14px;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  letter-spacing: 0.06em;\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  font-weight: 650;\n");
        cssContent.append("}\n\n");

        // H3 styles
        cssContent.append("h3 {\n");
        cssContent.append("  font-size: 17px;\n");
        cssContent.append("  margin: 24px 0 6px;\n");
        cssContent.append("}\n\n");

        // P styles
        cssContent.append("p {\n");
        cssContent.append("  margin: 0 0 14px;\n");
        cssContent.append("  max-width: 70ch;\n");
        cssContent.append("}\n\n");

        // Badges container
        cssContent.append(".badges {\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  gap: 7px;\n");
        cssContent.append("  flex-wrap: wrap;\n");
        cssContent.append("  margin-bottom: 20px;\n");
        cssContent.append("}\n\n");

        // Badge styles
        cssContent.append(".badge {\n");
        cssContent.append("  font-size: 12px;\n");
        cssContent.append("  font-weight: 650;\n");
        cssContent.append("  padding: 4px 11px;\n");
        cssContent.append("  border-radius: 99px;\n");
        cssContent.append("  background: var(--soft);\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("}\n\n");

        cssContent.append(".badge.on {\n");
        cssContent.append("  background: var(--ok-soft);\n");
        cssContent.append("  color: var(--ok);\n");
        cssContent.append("  border-color: transparent;\n");
        cssContent.append("}\n\n");

        // Table styles
        cssContent.append("table {\n");
        cssContent.append("  border-collapse: collapse;\n");
        cssContent.append("  width: 100%;\n");
        cssContent.append("  font-size: 14.5px;\n");
        cssContent.append("  margin: 0 0 14px;\n");
        cssContent.append("}\n\n");

        cssContent.append("th, td {\n");
        cssContent.append("  text-align: left;\n");
        cssContent.append("  padding: 9px 10px;\n");
        cssContent.append("  border-bottom: 1px solid var(--line);\n");
        cssContent.append("  vertical-align: top;\n");
        cssContent.append("}\n\n");

        cssContent.append("th {\n");
        cssContent.append("  font-size: 12px;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  letter-spacing: 0.04em;\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("}\n\n");

        // Code styles
        cssContent.append("code {\n");
        cssContent.append("  background: var(--soft);\n");
        cssContent.append("  padding: 2px 7px;\n");
        cssContent.append("  border-radius: 5px;\n");
        cssContent.append("  font-size: 13.5px;\n");
        cssContent.append("  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n");
        cssContent.append("  word-break: break-word;\n");
        cssContent.append("}\n\n");

        cssContent.append("pre {\n");
        cssContent.append("  background: var(--soft);\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("  border-radius: 10px;\n");
        cssContent.append("  padding: 13px 15px;\n");
        cssContent.append("  overflow-x: auto;\n");
        cssContent.append("  margin: 0 0 14px;\n");
        cssContent.append("}\n\n");

        cssContent.append("pre code {\n");
        cssContent.append("  background: none;\n");
        cssContent.append("  padding: 0;\n");
        cssContent.append("}\n\n");

        // Card styles
        cssContent.append(".card {\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("  border-radius: 12px;\n");
        cssContent.append("  padding: 18px 20px;\n");
        cssContent.append("  background: var(--bg);\n");
        cssContent.append("}\n\n");

        // Note styles
        cssContent.append(".note {\n");
        cssContent.append("  background: var(--warn-soft);\n");
        cssContent.append("  border: 1px solid transparent;\n");
        cssContent.append("  border-radius: 10px;\n");
        cssContent.append("  padding: 14px 16px;\n");
        cssContent.append("  margin: 0 0 16px;\n");
        cssContent.append("  font-size: 14.5px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".note b {\n");
        cssContent.append("  color: var(--warn);\n");
        cssContent.append("}\n\n");

        // Fieldset styles
        cssContent.append("fieldset {\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("  border-radius: 10px;\n");
        cssContent.append("  padding: 14px 16px;\n");
        cssContent.append("  margin: 0 0 14px;\n");
        cssContent.append("}\n\n");

        cssContent.append("legend {\n");
        cssContent.append("  font-size: 12px;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  letter-spacing: 0.05em;\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  padding: 0 6px;\n");
        cssContent.append("}\n\n");

        // Label styles
        cssContent.append("label.q {\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  gap: 10px;\n");
        cssContent.append("  align-items: flex-start;\n");
        cssContent.append("  padding: 7px 0;\n");
        cssContent.append("  font-size: 15px;\n");
        cssContent.append("  cursor: pointer;\n");
        cssContent.append("}\n\n");

        cssContent.append("label.q input {\n");
        cssContent.append("  margin-top: 4px;\n");
        cssContent.append("  flex: none;\n");
        cssContent.append("}\n\n");

        cssContent.append("label.q span small {\n");
        cssContent.append("  display: block;\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  font-size: 13px;\n");
        cssContent.append("}\n\n");

        // Ergebnis styles
        cssContent.append("#ergebnis {\n");
        cssContent.append("  margin-top: 6px;\n");
        cssContent.append("}\n\n");

        // Verdict styles
        cssContent.append(".verdict {\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("  border-left: 4px solid var(--ac);\n");
        cssContent.append("  border-radius: 10px;\n");
        cssContent.append("  padding: 16px 18px;\n");
        cssContent.append("  background: var(--soft);\n");
        cssContent.append("}\n\n");

        cssContent.append(".verdict h3 {\n");
        cssContent.append("  margin: 0 0 6px;\n");
        cssContent.append("  font-size: 18px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".verdict .step {\n");
        cssContent.append("  font-weight: 650;\n");
        cssContent.append("  margin: 10px 0 0;\n");
        cssContent.append("}\n\n");

        cssContent.append(".verdict .w {\n");
        cssContent.append("  margin-top: 12px;\n");
        cssContent.append("  padding: 11px 13px;\n");
        cssContent.append("  background: var(--warn-soft);\n");
        cssContent.append("  border-radius: 8px;\n");
        cssContent.append("  font-size: 14px;\n");
        cssContent.append("}\n\n");

        // Probe styles
        cssContent.append(".probe {\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  gap: 8px;\n");
        cssContent.append("  flex-wrap: wrap;\n");
        cssContent.append("  margin-bottom: 12px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".probe input {\n");
        cssContent.append("  flex: 1 1 240px;\n");
        cssContent.append("  padding: 10px 12px;\n");
        cssContent.append("  border: 1px solid var(--line);\n");
        cssContent.append("  border-radius: 9px;\n");
        cssContent.append("  background: var(--bg);\n");
        cssContent.append("  color: var(--text);\n");
        cssContent.append("  font-size: 15px;\n");
        cssContent.append("}\n\n");

        // Button styles
        cssContent.append(".btn {\n");
        cssContent.append("  font-weight: 650;\n");
        cssContent.append("  font-size: 15px;\n");
        cssContent.append("  padding: 10px 18px;\n");
        cssContent.append("  border-radius: 9px;\n");
        cssContent.append("  border: 1px solid var(--ac);\n");
        cssContent.append("  background: var(--ac);\n");
        cssContent.append("  color: #fff;\n");
        cssContent.append("  cursor: pointer;\n");
        cssContent.append("}\n\n");

        cssContent.append(".btn.ghost {\n");
        cssContent.append("  background: var(--bg);\n");
        cssContent.append("  color: var(--text);\n");
        cssContent.append("  border-color: var(--line);\n");
        cssContent.append("}\n\n");

        // Footer styles
        cssContent.append("footer {\n");
        cssContent.append("  margin-top: 56px;\n");
        cssContent.append("  padding-top: 22px;\n");
        cssContent.append("  border-top: 1px solid var(--line);\n");
        cssContent.append("  color: var(--muted);\n");
        cssContent.append("  font-size: 14px;\n");
        cssContent.append("}\n\n");

        // Anchor styles
        cssContent.append("a {\n");
        cssContent.append("  color: var(--ac);\n");
        cssContent.append("}\n");

        try {
            Files.write(Paths.get(filePath), cssContent.toString().getBytes());
            System.out.println("CSS file successfully written to: " + filePath);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
}
