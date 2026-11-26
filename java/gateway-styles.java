// abstraction-provenance: {"artifact_sha256": "538411c03e193b5dc0c194d1b3f6b2848cfd2fcbdfcde4a463dbd9e189e08cee", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "java"}
// gateway-styles.css — portiert nach java
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class CSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie einen Dateinamen als Parameter an.");
            System.exit(1);
        }
        
        String filename = args[0];
        generateCSS(filename);
    }

    private static void generateCSS(String filename) {
        StringBuilder css = new StringBuilder();
        
        // Kommentar
        css.append("/* OpenClaw Gateway Dashboard */\n\n");
        
        // Globale Reset-Regeln
        css.append("*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n\n");
        
        // Root-Variablen
        css.append(":root {\n");
        css.append("  --bg:       #0d1117;\n");
        css.append("  --surface:  #161b22;\n");
        css.append("  --border:   #30363d;\n");
        css.append("  --text:     #e6edf3;\n");
        css.append("  --muted:    #8b949e;\n");
        css.append("  --green:    #3fb950;\n");
        css.append("  --yellow:   #d29922;\n");
        css.append("  --red:      #f85149;\n");
        css.append("  --accent:   #58a6ff;\n");
        css.append("}\n\n");
        
        // Body-Stil
        css.append("body {\n");
        css.append("  background: var(--bg);\n");
        css.append("  color: var(--text);\n");
        css.append("  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n");
        css.append("  min-height: 100vh;\n");
        css.append("}\n\n");
        
        // Header-Stil
        css.append("header {\n");
        css.append("  display: flex;\n");
        css.append("  align-items: center;\n");
        css.append("  gap: 1rem;\n");
        css.append("  padding: 1.25rem 2rem;\n");
        css.append("  border-bottom: 1px solid var(--border);\n");
        css.append("  background: var(--surface);\n");
        css.append("}\n\n");
        
        css.append("header h1 { font-size: 1.25rem; color: var(--accent); }\n\n");
        
        // Badge-Stile
        css.append(".badge {\n");
        css.append("  padding: .25rem .75rem;\n");
        css.append("  border-radius: 999px;\n");
        css.append("  font-size: .75rem;\n");
        css.append("  font-weight: 600;\n");
        css.append("  background: var(--border);\n");
        css.append("  color: var(--muted);\n");
        css.append("}\n");
        css.append(".badge.ok    { background: #1a3a2a; color: var(--green); }\n");
        css.append(".badge.warn  { background: #3a2e0a; color: var(--yellow); }\n");
        css.append(".badge.error { background: #3a1010; color: var(--red); }\n\n");
        
        // Main-Bereich
        css.append("main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n\n");
        
        // Grid-Layout
        css.append(".grid {\n");
        css.append("  display: grid;\n");
        css.append("  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));\n");
        css.append("  gap: 1rem;\n");
        css.append("  margin-bottom: 2rem;\n");
        css.append("}\n\n");
        
        // Card-Komponente
        css.append(".card {\n");
        css.append("  background: var(--surface);\n");
        css.append("  border: 1px solid var(--border);\n");
        css.append("  border-radius: 8px;\n");
        css.append("  padding: 1.25rem;\n");
        css.append("  position: relative;\n");
        css.append("}\n\n");
        
        css.append(".card h2   { font-size: 1rem; margin-bottom: .25rem; }\n");
        css.append(".card .endpoint { font-size: .8rem; color: var(--muted); }\n\n");
        
        // Status-Dot
        css.append(".status-dot {\n");
        css.append("  position: absolute;\n");
        css.append("  top: 1.25rem;\n");
        css.append("  right: 1.25rem;\n");
        css.append("  width: 10px;\n");
        css.append("  height: 10px;\n");
        css.append("  border-radius: 50%;\n");
        css.append("  background: var(--border);\n");
        css.append("}\n");
        css.append(".status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }\n");
        css.append(".status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }\n\n");
        
        // Metriken
        css.append(".metrics h2 { font-size: 1rem; margin-bottom: 1rem; }\n\n");
        
        // Tabellen-Stil
        css.append("table {\n");
        css.append("  width: 100%;\n");
        css.append("  border-collapse: collapse;\n");
        css.append("  font-size: .875rem;\n");
        css.append("}\n");
        css.append("th, td {\n");
        css.append("  padding: .625rem 1rem;\n");
        css.append("  text-align: left;\n");
        css.append("  border-bottom: 1px solid var(--border);\n");
        css.append("}\n");
        css.append("th { color: var(--muted); font-weight: 500; }\n");
        css.append("tr:last-child td { border-bottom: none; }\n");
        
        // Schreiben in Datei
        try (FileWriter writer = new FileWriter(filename)) {
            writer.write(css.toString());
            System.out.println("CSS erfolgreich in " + filename + " geschrieben.");
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der CSS-Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
