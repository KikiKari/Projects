// abstraction-provenance: {"artifact_sha256": "dc179e26eae8f785b312de1d8f6b1d3831f41ece510305974f6680837ebeb69b", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "java"}
// App.css — portiert nach java
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

public class AppCSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java AppCSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            generateCSS(outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateCSS(String outputFile) throws IOException {
        try (FileWriter writer = new FileWriter(outputFile)) {
            // :root styles
            writer.write(":root {\n");
            writer.write("  color-scheme: dark;\n");
            writer.write("  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n");
            writer.write("  background: #0b1020;\n");
            writer.write("  color: #eef2ff;\n");
            writer.write("}\n\n");

            // Universal selector
            writer.write("* {\n");
            writer.write("  box-sizing: border-box;\n");
            writer.write("}\n\n");

            // Body styles
            writer.write("body {\n");
            writer.write("  margin: 0;\n");
            writer.write("  min-width: 320px;\n");
            writer.write("  min-height: 100vh;\n");
            writer.write("  background:\n");
            writer.write("    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),\n");
            writer.write("    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),\n");
            writer.write("    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);\n");
            writer.write("}\n\n");

            // Page shell
            writer.write(".page-shell {\n");
            writer.write("  min-height: 100vh;\n");
            writer.write("  display: grid;\n");
            writer.write("  place-items: center;\n");
            writer.write("  padding: 2rem;\n");
            writer.write("}\n\n");

            // Hero card
            writer.write(".hero-card {\n");
            writer.write("  width: min(100%, 56rem);\n");
            writer.write("  padding: clamp(2rem, 6vw, 4.5rem);\n");
            writer.write("  border: 1px solid rgba(148, 163, 184, 0.28);\n");
            writer.write("  border-radius: 2rem;\n");
            writer.write("  background: rgba(15, 23, 42, 0.72);\n");
            writer.write("  box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35);\n");
            writer.write("  backdrop-filter: blur(18px);\n");
            writer.write("}\n\n");

            // Eyebrow
            writer.write(".eyebrow {\n");
            writer.write("  margin: 0 0 1rem;\n");
            writer.write("  color: #67e8f9;\n");
            writer.write("  font-size: 0.8rem;\n");
            writer.write("  font-weight: 700;\n");
            writer.write("  letter-spacing: 0.18em;\n");
            writer.write("  text-transform: uppercase;\n");
            writer.write("}\n\n");

            // Heading 1
            writer.write("h1 {\n");
            writer.write("  margin: 0;\n");
            writer.write("  max-width: 12ch;\n");
            writer.write("  font-size: clamp(2.75rem, 8vw, 6rem);\n");
            writer.write("  line-height: 0.95;\n");
            writer.write("  letter-spacing: -0.06em;\n");
            writer.write("}\n\n");

            // Lead paragraph
            writer.write(".lead {\n");
            writer.write("  margin: 1.5rem 0 0;\n");
            writer.write("  max-width: 42rem;\n");
            writer.write("  color: #cbd5e1;\n");
            writer.write("  font-size: clamp(1.05rem, 2vw, 1.35rem);\n");
            writer.write("  line-height: 1.65;\n");
            writer.write("}\n\n");

            // Link grid container
            writer.write(".link-grid {\n");
            writer.write("  display: grid;\n");
            writer.write("  gap: 0.85rem;\n");
            writer.write("  margin-top: 2rem;\n");
            writer.write("}\n\n");

            // Link grid anchor elements
            writer.write(".link-grid a {\n");
            writer.write("  display: flex;\n");
            writer.write("  align-items: center;\n");
            writer.write("  justify-content: space-between;\n");
            writer.write("  gap: 1rem;\n");
            writer.write("  padding: 1rem 1.15rem;\n");
            writer.write("  border: 1px solid rgba(148, 163, 184, 0.25);\n");
            writer.write("  border-radius: 1rem;\n");
            writer.write("  color: #f8fafc;\n");
            writer.write("  text-decoration: none;\n");
            writer.write("  background: rgba(255, 255, 255, 0.06);\n");
            writer.write("}\n\n");

            // Link hover and focus states
            writer.write(".link-grid a:hover,\n");
            writer.write(".link-grid a:focus-visible {\n");
            writer.write("  border-color: rgba(103, 232, 249, 0.75);\n");
            writer.write("  outline: none;\n");
            writer.write("  background: rgba(103, 232, 249, 0.12);\n");
            writer.write("}\n");
        }
    }
}
