// abstraction-provenance: {"artifact_sha256": "f5ccbc2ef86805a74adf8f65bef3b79e935463132cae01cfe499c52a2cc29bee", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "java"}
// index_57e3e2.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;

public class CssGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CssGenerator <output-file>");
            System.exit(1);
        }

        String outputFile = args[0];
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(generateCss());
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static String generateCss() {
        StringBuilder css = new StringBuilder();

        // Comments
        css.append("/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */\n");
        css.append("/* index.html — portiert nach css */\n");
        css.append("/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */\n");
        css.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

        // Root
        css.append(":root {\n");
        css.append("  color-scheme: light;\n");
        css.append("}\n\n");

        // Universal selector
        css.append("* {\n");
        css.append("  box-sizing: border-box;\n");
        css.append("}\n\n");

        // Body
        css.append("body {\n");
        css.append("  margin: 0;\n");
        css.append("  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n");
        css.append("  background: #f7f7f5;\n");
        css.append("  color: #1d1c1a;\n");
        css.append("}\n\n");

        // Wrap
        css.append(".wrap {\n");
        css.append("  max-width: 880px;\n");
        css.append("  margin: 0 auto;\n");
        css.append("  padding: 20px 16px 60px;\n");
        css.append("}\n\n");

        // Headings
        css.append("h1 {\n");
        css.append("  font-size: 22px;\n");
        css.append("  margin: 0 0 2px;\n");
        css.append("}\n\n");

        // Sub
        css.append(".sub {\n");
        css.append("  color: #6b6a66;\n");
        css.append("  font-size: 13px;\n");
        css.append("  margin-bottom: 16px;\n");
        css.append("}\n\n");

        // Bar
        css.append(".bar {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 10px;\n");
        css.append("  align-items: center;\n");
        css.append("  margin-bottom: 16px;\n");
        css.append("  flex-wrap: wrap;\n");
        css.append("}\n\n");

        // Button
        css.append("button {\n");
        css.append("  font-size: 13px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  padding: 7px 13px;\n");
        css.append("  border: 1px solid #d9d8d3;\n");
        css.append("  border-radius: 8px;\n");
        css.append("  background: #fff;\n");
        css.append("  cursor: pointer;\n");
        css.append("}\n\n");

        css.append("button:hover {\n");
        css.append("  background: #f2f1ec;\n");
        css.append("}\n\n");

        css.append("button.primary {\n");
        css.append("  background: #1d1c1a;\n");
        css.append("  color: #fff;\n");
        css.append("  border-color: #1d1c1a;\n");
        css.append("}\n\n");

        // Note
        css.append(".note {\n");
        css.append("  background: #fffdf4;\n");
        css.append("  border: 1px solid #f0e9c8;\n");
        css.append("  border-radius: 10px;\n");
        css.append("  padding: 12px 14px;\n");
        css.append("  font-size: 13px;\n");
        css.append("  color: #4a4734;\n");
        css.append("  margin-bottom: 16px;\n");
        css.append("  line-height: 1.5;\n");
        css.append("}\n\n");

        // Section
        css.append(".section {\n");
        css.append("  background: #fff;\n");
        css.append("  border: 1px solid #e8e7e3;\n");
        css.append("  border-radius: 12px;\n");
        css.append("  margin-bottom: 14px;\n");
        css.append("  overflow: hidden;\n");
        css.append("}\n\n");

        css.append(".section > h2 {\n");
        css.append("  font-size: 15px;\n");
        css.append("  margin: 0;\n");
        css.append("  padding: 13px 16px;\n");
        css.append("  border-bottom: 1px solid #efeee9;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 9px;\n");
        css.append("}\n\n");

        css.append(".section > h2 .badge {\n");
        css.append("  margin-left: auto;\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  background: #efeee9;\n");
        css.append("  color: #5a5852;\n");
        css.append("  padding: 2px 9px;\n");
        css.append("  border-radius: 20px;\n");
        css.append("}\n\n");

        // Body
        css.append(".body {\n");
        css.append("  padding: 8px 16px 14px;\n");
        css.append("  font-size: 14px;\n");
        css.append("}\n\n");

        // Muted
        css.append(".muted {\n");
        css.append("  color: #8a8884;\n");
        css.append("}\n\n");

        // Err
        css.append(".err {\n");
        css.append("  color: #c0392b;\n");
        css.append("}\n\n");

        // KV
        css.append(".kv {\n");
        css.append("  display: flex;\n");
        css.append("  justify-content: space-between;\n");
        css.append("  padding: 4px 0;\n");
        css.append("  border-bottom: 1px solid #f4f3ee;\n");
        css.append("}\n\n");

        css.append(".kv:last-child {\n");
        css.append("  border: none;\n");
        css.append("}\n\n");

        css.append(".kv .k {\n");
        css.append("  color: #6b6a66;\n");
        css.append("}\n\n");

        css.append(".kv .v {\n");
        css.append("  font-weight: 600;\n");
        css.append("}\n\n");

        // Links
        css.append("a {\n");
        css.append("  color: #2b5cc4;\n");
        css.append("  text-decoration: none;\n");
        css.append("}\n\n");

        css.append("a:hover {\n");
        css.append("  text-decoration: underline;\n");
        css.append("}\n\n");

        // Modal
        css.append(".modal {\n");
        css.append("  position: fixed;\n");
        css.append("  inset: 0;\n");
        css.append("  background: rgba(0, 0, 0, .35);\n");
        css.append("  display: none;\n");
        css.append("  align-items: flex-start;\n");
        css.append("  justify-content: center;\n");
        css.append("  padding: 40px 16px;\n");
        css.append("  overflow: auto;\n");
        css.append("}\n\n");

        css.append(".modal.open {\n");
        css.append("  display: flex;\n");
        css.append("}\n\n");

        // Card
        css.append(".card {\n");
        css.append("  background: #fff;\n");
        css.append("  border-radius: 14px;\n");
        css.append("  max-width: 560px;\n");
        css.append("  width: 100%;\n");
        css.append("  padding: 20px;\n");
        css.append("}\n\n");

        css.append(".card h3 {\n");
        css.append("  margin: 0 0 4px;\n");
        css.append("  font-size: 17px;\n");
        css.append("}\n\n");

        css.append(".card p.hint {\n");
        css.append("  margin: 0 0 16px;\n");
        css.append("  font-size: 12px;\n");
        css.append("  color: #8a8884;\n");
        css.append("}\n\n");

        // Field
        css.append(".field {\n");
        css.append("  margin-bottom: 12px;\n");
        css.append("}\n\n");

        css.append(".field label {\n");
        css.append("  display: block;\n");
        css.append("  font-size: 12px;\n");
        css.append("  font-weight: 600;\n");
        css.append("  color: #5a5852;\n");
        css.append("  margin-bottom: 3px;\n");
        css.append("}\n\n");

        css.append(".field input {\n");
        css.append("  width: 100%;\n");
        css.append("  font-size: 13px;\n");
        css.append("  padding: 7px 9px;\n");
        css.append("  border: 1px solid #d9d8d3;\n");
        css.append("  border-radius: 7px;\n");
        css.append("  font-family: ui-monospace, Menlo, monospace;\n");
        css.append("}\n\n");

        css.append(".field .desc {\n");
        css.append("  font-size: 11px;\n");
        css.append("  color: #a8a6a1;\n");
        css.append("  margin-top: 2px;\n");
        css.append("}\n\n");

        // Actions
        css.append(".actions {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 10px;\n");
        css.append("  justify-content: flex-end;\n");
        css.append("  margin-top: 8px;\n");
        css.append("}\n\n");

        // Warn
        css.append(".warn {\n");
        css.append("  background: #fdf3f3;\n");
        css.append("  border: 1px solid #f3d9d9;\n");
        css.append("  color: #9a3b3b;\n");
        css.append("  border-radius: 8px;\n");
        css.append("  padding: 10px 12px;\n");
        css.append("  font-size: 12px;\n");
        css.append("  margin-bottom: 14px;\n");
        css.append("}\n");

        return css.toString();
    }
}
