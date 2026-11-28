// abstraction-provenance: {"artifact_sha256": "ff3a0740a3da9204e1efe8f37ef7daea70b418a7e34f3adba525e13c2403c8d2", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "java"}
// kontaktbogen.css — portiert nach java
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class KontaktbogenCSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java KontaktbogenCSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        generateCSS(outputFile);
    }

    private static void generateCSS(String outputFile) {
        StringBuilder css = new StringBuilder();
        
        // Add comments
        css.append("/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */\n");
        css.append("/* kontaktbogen.html — portiert nach css */\n");
        css.append("/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n");
        css.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
        
        // Root variables
        css.append(":root {\n");
        css.append("  --bg: #FAF8F4;\n");
        css.append("  --ink: #1B1A17;\n");
        css.append("  --muted: #6E6A61;\n");
        css.append("  --line: #E5E1D8;\n");
        css.append("  --accent: #A8542F;\n");
        css.append("  --accent-2: #2E7D7B;\n");
        css.append("  --surface: #fff;\n");
        css.append("}\n\n");
        
        // Universal selector
        css.append("* {\n");
        css.append("  box-sizing: border-box;\n");
        css.append("}\n\n");
        
        // Body styles
        css.append("body {\n");
        css.append("  margin: 0;\n");
        css.append("  font-family: 'Hanken Grotesk', system-ui, sans-serif;\n");
        css.append("  background: var(--bg);\n");
        css.append("  color: var(--ink);\n");
        css.append("  line-height: 1.5;\n");
        css.append("}\n\n");
        
        // Header styles
        css.append("header {\n");
        css.append("  padding: 2.5rem 2rem 1rem;\n");
        css.append("  border-bottom: 1px solid var(--line);\n");
        css.append("  background: var(--surface);\n");
        css.append("  position: sticky;\n");
        css.append("  top: 0;\n");
        css.append("  z-index: 10;\n");
        css.append("}\n\n");
        
        css.append("header h1 {\n");
        css.append("  margin: 0 0 .5rem;\n");
        css.append("  font-family: 'Newsreader', Georgia, serif;\n");
        css.append("  font-weight: 400;\n");
        css.append("  font-size: 2.25rem;\n");
        css.append("}\n\n");
        
        css.append("header p {\n");
        css.append("  margin: .25rem 0;\n");
        css.append("  color: var(--muted);\n");
        css.append("  max-width: 80ch;\n");
        css.append("}\n\n");
        
        // Legend styles
        css.append(".legend {\n");
        css.append("  display: flex;\n");
        css.append("  gap: 1rem;\n");
        css.append("  flex-wrap: wrap;\n");
        css.append("  margin-top: .75rem;\n");
        css.append("  font-size: .8125rem;\n");
        css.append("}\n\n");
        
        // Pill styles
        css.append(".pill {\n");
        css.append("  padding: .15rem .6rem;\n");
        css.append("  border-radius: 999px;\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  background: #fff;\n");
        css.append("}\n\n");
        
        css.append(".pill.pflicht {\n");
        css.append("  border-color: var(--accent);\n");
        css.append("  color: var(--accent);\n");
        css.append("  font-weight: 600;\n");
        css.append("}\n\n");
        
        css.append(".pill.auswahl {\n");
        css.append("  border-color: var(--accent-2);\n");
        css.append("  color: var(--accent-2);\n");
        css.append("  font-weight: 600;\n");
        css.append("}\n\n");
        
        // Main styles
        css.append("main {\n");
        css.append("  padding: 2rem;\n");
        css.append("  max-width: 1400px;\n");
        css.append("  margin: 0 auto;\n");
        css.append("}\n\n");
        
        // Section styles
        css.append("section {\n");
        css.append("  margin: 2.5rem 0;\n");
        css.append("}\n\n");
        
        css.append("section h2 {\n");
        css.append("  font-family: 'Newsreader', serif;\n");
        css.append("  font-weight: 400;\n");
        css.append("  font-size: 1.5rem;\n");
        css.append("  margin: 0 0 .25rem;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: .75rem;\n");
        css.append("}\n\n");
        
        css.append("section .sub {\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-size: .875rem;\n");
        css.append("  margin: 0 0 1.25rem;\n");
        css.append("}\n\n");
        
        // Grid styles
        css.append(".grid {\n");
        css.append("  display: grid;\n");
        css.append("  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));\n");
        css.append("  gap: 1rem;\n");
        css.append("}\n\n");
        
        // Card styles
        css.append(".card {\n");
        css.append("  background: var(--surface);\n");
        css.append("  border: 1px solid var(--line);\n");
        css.append("  border-radius: 10px;\n");
        css.append("  overflow: hidden;\n");
        css.append("  display: flex;\n");
        css.append("  flex-direction: column;\n");
        css.append("}\n\n");
        
        css.append(".card .imgwrap {\n");
        css.append("  aspect-ratio: 1;\n");
        css.append("  background: #f1eee7;\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  justify-content: center;\n");
        css.append("  overflow: hidden;\n");
        css.append("}\n\n");
        
        css.append(".card img {\n");
        css.append("  width: 100%;\n");
        css.append("  height: 100%;\n");
        css.append("  object-fit: contain;\n");
        css.append("  background: #fff;\n");
        css.append("}\n\n");
        
        css.append(".card .meta {\n");
        css.append("  padding: .6rem .75rem .75rem;\n");
        css.append("  font-size: .78125rem;\n");
        css.append("}\n\n");
        
        css.append(".card .name {\n");
        css.append("  font-family: 'JetBrains Mono', monospace;\n");
        css.append("  font-size: .6875rem;\n");
        css.append("  color: var(--muted);\n");
        css.append("  word-break: break-all;\n");
        css.append("  line-height: 1.3;\n");
        css.append("  margin-bottom: .35rem;\n");
        css.append("}\n\n");
        
        css.append(".card .dims {\n");
        css.append("  color: var(--muted);\n");
        css.append("  font-size: .6875rem;\n");
        css.append("  margin-bottom: .35rem;\n");
        css.append("}\n\n");
        
        css.append(".card .prompt {\n");
        css.append("  color: var(--ink);\n");
        css.append("  font-size: .75rem;\n");
        css.append("  line-height: 1.35;\n");
        css.append("  font-style: italic;\n");
        css.append("  border-top: 1px solid var(--line);\n");
        css.append("  padding-top: .4rem;\n");
        css.append("  margin-top: .35rem;\n");
        css.append("  max-height: 5.5em;\n");
        css.append("  overflow: hidden;\n");
        css.append("}\n\n");
        
        // Tag styles
        css.append(".tag {\n");
        css.append("  display: inline-block;\n");
        css.append("  padding: .1rem .45rem;\n");
        css.append("  border-radius: 999px;\n");
        css.append("  font-size: .6875rem;\n");
        css.append("  background: #F1EEE7;\n");
        css.append("  color: var(--muted);\n");
        css.append("  margin-right: .25rem;\n");
        css.append("}\n\n");
        
        css.append(".tag.p {\n");
        css.append("  background: #F1E5DD;\n");
        css.append("  color: var(--accent);\n");
        css.append("}\n\n");
        
        css.append(".tag.a {\n");
        css.append("  background: #DEEDEC;\n");
        css.append("  color: var(--accent-2);\n");
        css.append("}\n");
        
        // Write to file
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(css.toString());
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
}
