// abstraction-provenance: {"artifact_sha256": "6567d3a5861e84b8b2fcbce265e9434d40b44ec5684ef26c4896156899d9974d", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "java"}
// periodensystem.css — portiert nach java
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;

public class PeriodensystemCSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java PeriodensystemCSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        try {
            generateCSS(outputFile);
            System.out.println("CSS file generated successfully: " + Paths.get(outputFile).toAbsolutePath());
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateCSS(String outputFile) throws IOException {
        try (FileWriter writer = new FileWriter(outputFile)) {
            // Write header comments
            writer.write("/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */\n");
            writer.write("/* periodensystem.html — portiert nach css */\n");
            writer.write("/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n");
            writer.write("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

            // Universal selector
            writer.write("* { box-sizing: border-box; margin: 0; padding: 0; }\n");
            
            // Root variables
            writer.write(":root {\n");
            writer.write("  --bg: #fafaf7;\n");
            writer.write("  --surface: #ffffff;\n");
            writer.write("  --border: rgba(0,0,0,0.12);\n");
            writer.write("  --text: #1a1a1a;\n");
            writer.write("  --text-muted: #666;\n");
            writer.write("}\n\n");
            
            // Dark mode media query
            writer.write("@media (prefers-color-scheme: dark) {\n");
            writer.write("  :root {\n");
            writer.write("    --bg: #1a1a1a;\n");
            writer.write("    --surface: #242424;\n");
            writer.write("    --border: rgba(255,255,255,0.15);\n");
            writer.write("    --text: #f0f0f0;\n");
            writer.write("    --text-muted: #aaa;\n");
            writer.write("  }\n");
            writer.write("}\n\n");
            
            // Body styles
            writer.write("body {\n");
            writer.write("  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;\n");
            writer.write("  background: var(--bg);\n");
            writer.write("  color: var(--text);\n");
            writer.write("  padding: 24px;\n");
            writer.write("  max-width: 1100px;\n");
            writer.write("  margin: 0 auto;\n");
            writer.write("  line-height: 1.5;\n");
            writer.write("}\n\n");
            
            // Heading styles
            writer.write("h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }\n");
            writer.write(".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }\n\n");
            
            // Detail section
            writer.write(".detail {\n");
            writer.write("  background: var(--surface);\n");
            writer.write("  border: 1px solid var(--border);\n");
            writer.write("  border-radius: 12px;\n");
            writer.write("  padding: 16px 20px;\n");
            writer.write("  min-height: 110px;\n");
            writer.write("  display: flex;\n");
            writer.write("  align-items: center;\n");
            writer.write("  gap: 20px;\n");
            writer.write("  margin-bottom: 16px;\n");
            writer.write("}\n\n");
            
            writer.write(".detail-empty {\n");
            writer.write("  color: var(--text-muted);\n");
            writer.write("  font-size: 14px;\n");
            writer.write("  text-align: center;\n");
            writer.write("  width: 100%;\n");
            writer.write("}\n\n");
            
            // Symbol box
            writer.write(".symbol-box {\n");
            writer.write("  font-size: 40px;\n");
            writer.write("  font-weight: 500;\n");
            writer.write("  line-height: 1;\n");
            writer.write("  width: 80px;\n");
            writer.write("  height: 80px;\n");
            writer.write("  display: flex;\n");
            writer.write("  align-items: center;\n");
            writer.write("  justify-content: center;\n");
            writer.write("  border-radius: 8px;\n");
            writer.write("  flex-shrink: 0;\n");
            writer.write("}\n\n");
            
            // Info styles
            writer.write(".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }\n");
            writer.write(".info-meta {\n");
            writer.write("  font-size: 13px;\n");
            writer.write("  color: var(--text-muted);\n");
            writer.write("  display: grid;\n");
            writer.write("  grid-template-columns: repeat(2, minmax(0, 1fr));\n");
            writer.write("  gap: 4px 24px;\n");
            writer.write("}\n");
            writer.write(".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }\n\n");
            
            // Grid styles
            writer.write(".grid {\n");
            writer.write("  display: grid;\n");
            writer.write("  grid-template-columns: repeat(18, minmax(0, 1fr));\n");
            writer.write("  gap: 3px;\n");
            writer.write("}\n");
            writer.write(".fgrid { margin-top: 8px; }\n\n");
            
            // Cell styles
            writer.write(".cell {\n");
            writer.write("  aspect-ratio: 1;\n");
            writer.write("  border-radius: 4px;\n");
            writer.write("  padding: 3px;\n");
            writer.write("  display: flex;\n");
            writer.write("  flex-direction: column;\n");
            writer.write("  align-items: center;\n");
            writer.write("  justify-content: center;\n");
            writer.write("  cursor: pointer;\n");
            writer.write("  font-family: inherit;\n");
            writer.write("  line-height: 1;\n");
            writer.write("  transition: transform 0.12s ease;\n");
            writer.write("  border: 0;\n");
            writer.write("  position: relative;\n");
            writer.write("  overflow: hidden;\n");
            writer.write("}\n\n");
            
            writer.write(".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }\n");
            writer.write(".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }\n");
            writer.write(".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }\n");
            writer.write(".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }\n");
            writer.write(".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }\n\n");
            
            // Marker cell
            writer.write(".cell-marker {\n");
            writer.write("  cursor: default;\n");
            writer.write("  font-size: 9px;\n");
            writer.write("  font-weight: 500;\n");
            writer.write("  border: 1px dashed currentColor;\n");
            writer.write("  background: transparent !important;\n");
            writer.write("}\n");
            writer.write(".cell-marker:hover { transform: none; box-shadow: none; }\n\n");
            
            // Category colors - Light mode
            writer.write(".cat-am { background: #FCEBEB; color: #501313; }\n");
            writer.write(".cat-em { background: #FAEEDA; color: #412402; }\n");
            writer.write(".cat-tm { background: #E6F1FB; color: #042C53; }\n");
            writer.write(".cat-ptm { background: #F1EFE8; color: #2C2C2A; }\n");
            writer.write(".cat-hm { background: #E1F5EE; color: #04342C; }\n");
            writer.write(".cat-nm { background: #EAF3DE; color: #173404; }\n");
            writer.write(".cat-h { background: #EEEDFE; color: #26215C; }\n");
            writer.write(".cat-eg { background: #FBEAF0; color: #4B1528; }\n");
            writer.write(".cat-la { background: #FAECE7; color: #4A1B0C; }\n");
            writer.write(".cat-ac { background: #F5C4B3; color: #4A1B0C; }\n\n");
            
            // Category colors - Dark mode
            writer.write("@media (prefers-color-scheme: dark) {\n");
            writer.write("  .cat-am { background: #791F1F; color: #F7C1C1; }\n");
            writer.write("  .cat-em { background: #633806; color: #FAC775; }\n");
            writer.write("  .cat-tm { background: #0C447C; color: #B5D4F4; }\n");
            writer.write("  .cat-ptm { background: #444441; color: #D3D1C7; }\n");
            writer.write("  .cat-hm { background: #085041; color: #9FE1CB; }\n");
            writer.write("  .cat-nm { background: #27500A; color: #C0DD97; }\n");
            writer.write("  .cat-h { background: #3C3489; color: #CECBF6; }\n");
            writer.write("  .cat-eg { background: #72243E; color: #F4C0D1; }\n");
            writer.write("  .cat-la { background: #712B13; color: #F5C4B3; }\n");
            writer.write("  .cat-ac { background: #993C1D; color: #F5C4B3; }\n");
            writer.write("}\n\n");
            
            // Legend styles
            writer.write(".legend {\n");
            writer.write("  display: grid;\n");
            writer.write("  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));\n");
            writer.write("  gap: 8px 16px;\n");
            writer.write("  margin-top: 24px;\n");
            writer.write("  font-size: 12px;\n");
            writer.write("  color: var(--text-muted);\n");
            writer.write("}\n\n");
            
            writer.write(".legend-item { display: flex; align-items: center; gap: 8px; }\n");
            writer.write(".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }\n");
        }
    }
}
