// abstraction-provenance: {"artifact_sha256": "0f270afbdb6bcee456497d54456d9f74b2e7daa9a584539d385c237f65b3d237", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "java"}
// index_8000e9.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_8000e9.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class CSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie einen Dateinamen als Parameter an.");
            System.exit(1);
        }

        String filename = args[0];
        StringBuilder cssContent = new StringBuilder();

        // Root-Variablen
        cssContent.append(":root {\n");
        cssContent.append("  --bg: #FAF8F4;\n");
        cssContent.append("  --ink: #1B1A17;\n");
        cssContent.append("  --accent: #A8542F;\n");
        cssContent.append("  --accent-2: #2E7D7B;\n");
        cssContent.append("  --font-display: 'Newsreader', Georgia, serif;\n");
        cssContent.append("  --font-body: 'Hanken Grotesk', -apple-system, sans-serif;\n");
        cssContent.append("  --font-mono: 'JetBrains Mono', monospace;\n");
        cssContent.append("}\n\n");

        // Globale Styles
        cssContent.append("* {\n");
        cssContent.append("  box-sizing: border-box;\n");
        cssContent.append("  margin: 0;\n");
        cssContent.append("  padding: 0;\n");
        cssContent.append("}\n\n");

        cssContent.append("body {\n");
        cssContent.append("  font-family: var(--font-body);\n");
        cssContent.append("  background: var(--bg);\n");
        cssContent.append("  color: var(--ink);\n");
        cssContent.append("  padding: 32px 16px 80px;\n");
        cssContent.append("}\n\n");

        cssContent.append("h1 {\n");
        cssContent.append("  font-family: var(--font-display);\n");
        cssContent.append("  font-weight: 500;\n");
        cssContent.append("  font-size: 28px;\n");
        cssContent.append("  max-width: 1400px;\n");
        cssContent.append("  margin: 0 auto 12px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".intro {\n");
        cssContent.append("  max-width: 1400px;\n");
        cssContent.append("  margin: 0 auto 32px;\n");
        cssContent.append("  color: #666;\n");
        cssContent.append("  font-size: 14px;\n");
        cssContent.append("  line-height: 1.5;\n");
        cssContent.append("}\n\n");

        cssContent.append(".grid {\n");
        cssContent.append("  display: grid;\n");
        cssContent.append("  gap: 32px;\n");
        cssContent.append("  max-width: 1400px;\n");
        cssContent.append("  margin: 0 auto;\n");
        cssContent.append("}\n\n");

        // Variant-Klasse
        cssContent.append(".variant {\n");
        cssContent.append("  background: #000;\n");
        cssContent.append("  border-radius: 16px;\n");
        cssContent.append("  overflow: hidden;\n");
        cssContent.append("  box-shadow: 0 12px 40px rgba(0,0,0,0.15);\n");
        cssContent.append("}\n\n");

        cssContent.append(".variant-header {\n");
        cssContent.append("  background: #fff;\n");
        cssContent.append("  padding: 16px 24px;\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  align-items: center;\n");
        cssContent.append("  justify-content: space-between;\n");
        cssContent.append("  gap: 16px;\n");
        cssContent.append("  border-bottom: 1px solid #eee;\n");
        cssContent.append("}\n\n");

        cssContent.append(".variant-label {\n");
        cssContent.append("  font-family: var(--font-mono);\n");
        cssContent.append("  font-size: 11px;\n");
        cssContent.append("  letter-spacing: 0.2em;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  color: var(--accent);\n");
        cssContent.append("  font-weight: 600;\n");
        cssContent.append("}\n\n");

        cssContent.append(".variant-title {\n");
        cssContent.append("  font-family: var(--font-display);\n");
        cssContent.append("  font-size: 20px;\n");
        cssContent.append("  font-weight: 500;\n");
        cssContent.append("}\n\n");

        cssContent.append(".variant-desc {\n");
        cssContent.append("  font-size: 13px;\n");
        cssContent.append("  color: #666;\n");
        cssContent.append("  flex: 1;\n");
        cssContent.append("  text-align: right;\n");
        cssContent.append("}\n\n");

        // Scene-Klasse
        cssContent.append(".scene {\n");
        cssContent.append("  position: relative;\n");
        cssContent.append("  aspect-ratio: 16 / 9;\n");
        cssContent.append("  background: url('bg.png') center/cover no-repeat;\n");
        cssContent.append("  overflow: hidden;\n");
        cssContent.append("}\n\n");

        cssContent.append(".orb {\n");
        cssContent.append("  position: absolute;\n");
        cssContent.append("  width: 12%;\n");
        cssContent.append("  aspect-ratio: 1;\n");
        cssContent.append("  left: 42%;\n");
        cssContent.append("  top: 55%;\n");
        cssContent.append("  transform: translate(-50%, -50%);\n");
        cssContent.append("  cursor: pointer;\n");
        cssContent.append("}\n\n");

        cssContent.append(".orb img {\n");
        cssContent.append("  width: 100%;\n");
        cssContent.append("  height: 100%;\n");
        cssContent.append("  object-fit: contain;\n");
        cssContent.append("}\n\n");

        // Card Preview
        cssContent.append(".card-preview {\n");
        cssContent.append("  position: absolute;\n");
        cssContent.append("  left: 55%;\n");
        cssContent.append("  top: 45%;\n");
        cssContent.append("  background: rgba(255,255,255,0.98);\n");
        cssContent.append("  padding: 16px 20px;\n");
        cssContent.append("  border-radius: 12px;\n");
        cssContent.append("  box-shadow: 0 8px 24px rgba(0,0,0,0.25);\n");
        cssContent.append("  width: 240px;\n");
        cssContent.append("  animation: slideIn 0.3s ease-out;\n");
        cssContent.append("}\n\n");

        cssContent.append(".card-preview .badge {\n");
        cssContent.append("  display: inline-block;\n");
        cssContent.append("  background: var(--accent-2);\n");
        cssContent.append("  color: white;\n");
        cssContent.append("  font-family: var(--font-mono);\n");
        cssContent.append("  font-size: 9px;\n");
        cssContent.append("  letter-spacing: 0.15em;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  padding: 3px 8px;\n");
        cssContent.append("  border-radius: 3px;\n");
        cssContent.append("  margin-bottom: 8px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".card-preview h3 {\n");
        cssContent.append("  font-family: var(--font-display);\n");
        cssContent.append("  font-size: 18px;\n");
        cssContent.append("  font-weight: 500;\n");
        cssContent.append("  margin-bottom: 6px;\n");
        cssContent.append("  color: var(--ink);\n");
        cssContent.append("}\n\n");

        cssContent.append(".card-preview p {\n");
        cssContent.append("  font-size: 12px;\n");
        cssContent.append("  color: #555;\n");
        cssContent.append("  line-height: 1.4;\n");
        cssContent.append("}\n\n");

        // SlideIn Animation
        cssContent.append("@keyframes slideIn {\n");
        cssContent.append("  from {\n");
        cssContent.append("    opacity: 0;\n");
        cssContent.append("    transform: translateX(-8px);\n");
        cssContent.append("  }\n");
        cssContent.append("  to {\n");
        cssContent.append("    opacity: 1;\n");
        cssContent.append("    transform: translateX(0);\n");
        cssContent.append("  }\n");
        cssContent.append("}\n\n");

        // Tooltip
        cssContent.append(".tooltip {\n");
        cssContent.append("  position: absolute;\n");
        cssContent.append("  left: 42%;\n");
        cssContent.append("  top: 46%;\n");
        cssContent.append("  transform: translate(-50%, -100%);\n");
        cssContent.append("  color: white;\n");
        cssContent.append("  text-shadow: 0 2px 12px rgba(0,0,0,0.8);\n");
        cssContent.append("  font-family: var(--font-display);\n");
        cssContent.append("  font-size: 20px;\n");
        cssContent.append("  font-weight: 500;\n");
        cssContent.append("  white-space: nowrap;\n");
        cssContent.append("  animation: fadeUp 0.3s ease-out;\n");
        cssContent.append("}\n\n");

        // FadeUp Animation
        cssContent.append("@keyframes fadeUp {\n");
        cssContent.append("  from {\n");
        cssContent.append("    opacity: 0;\n");
        cssContent.append("    transform: translate(-50%, -80%);\n");
        cssContent.append("  }\n");
        cssContent.append("  to {\n");
        cssContent.append("    opacity: 1;\n");
        cssContent.append("    transform: translate(-50%, -100%);\n");
        cssContent.append("  }\n");
        cssContent.append("}\n\n");

        // Full Overlay
        cssContent.append(".full-overlay {\n");
        cssContent.append("  position: absolute;\n");
        cssContent.append("  inset: 0;\n");
        cssContent.append("  background: rgba(0,0,0,0.5);\n");
        cssContent.append("  backdrop-filter: blur(6px);\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  align-items: center;\n");
        cssContent.append("  justify-content: center;\n");
        cssContent.append("  animation: fadeIn 0.35s ease-out;\n");
        cssContent.append("}\n\n");

        cssContent.append(".full-overlay .panel {\n");
        cssContent.append("  background: rgba(255,255,255,0.98);\n");
        cssContent.append("  padding: 32px 40px;\n");
        cssContent.append("  border-radius: 20px;\n");
        cssContent.append("  max-width: 420px;\n");
        cssContent.append("  box-shadow: 0 20px 60px rgba(0,0,0,0.4);\n");
        cssContent.append("  text-align: center;\n");
        cssContent.append("}\n\n");

        cssContent.append(".full-overlay .badge {\n");
        cssContent.append("  display: inline-block;\n");
        cssContent.append("  background: var(--accent);\n");
        cssContent.append("  color: white;\n");
        cssContent.append("  font-family: var(--font-mono);\n");
        cssContent.append("  font-size: 10px;\n");
        cssContent.append("  letter-spacing: 0.2em;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("  padding: 4px 10px;\n");
        cssContent.append("  border-radius: 4px;\n");
        cssContent.append("  margin-bottom: 14px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".full-overlay h3 {\n");
        cssContent.append("  font-family: var(--font-display);\n");
        cssContent.append("  font-size: 28px;\n");
        cssContent.append("  font-weight: 500;\n");
        cssContent.append("  margin-bottom: 10px;\n");
        cssContent.append("  color: var(--ink);\n");
        cssContent.append("}\n\n");

        cssContent.append(".full-overlay p {\n");
        cssContent.append("  font-size: 14px;\n");
        cssContent.append("  color: #555;\n");
        cssContent.append("  line-height: 1.5;\n");
        cssContent.append("  margin-bottom: 20px;\n");
        cssContent.append("}\n\n");

        cssContent.append(".full-overlay .preview-img {\n");
        cssContent.append("  width: 100%;\n");
        cssContent.append("  aspect-ratio: 16/10;\n");
        cssContent.append("  background: linear-gradient(135deg, #A8542F, #2E7D7B);\n");
        cssContent.append("  border-radius: 8px;\n");
        cssContent.append("  margin-bottom: 16px;\n");
        cssContent.append("  display: flex;\n");
        cssContent.append("  align-items: center;\n");
        cssContent.append("  justify-content: center;\n");
        cssContent.append("  color: white;\n");
        cssContent.append("  font-family: var(--font-mono);\n");
        cssContent.append("  font-size: 11px;\n");
        cssContent.append("  letter-spacing: 0.15em;\n");
        cssContent.append("  opacity: 0.9;\n");
        cssContent.append("}\n\n");

        // FadeIn Animation
        cssContent.append("@keyframes fadeIn {\n");
        cssContent.append("  from {\n");
        cssContent.append("    opacity: 0;\n");
        cssContent.append("  }\n");
        cssContent.append("  to {\n");
        cssContent.append("    opacity: 1;\n");
        cssContent.append("  }\n");
        cssContent.append("}\n\n");

        // Instruction
        cssContent.append(".instruction {\n");
        cssContent.append("  text-align: center;\n");
        cssContent.append("  color: #999;\n");
        cssContent.append("  font-size: 12px;\n");
        cssContent.append("  margin-top: 16px;\n");
        cssContent.append("  font-family: var(--font-mono);\n");
        cssContent.append("  letter-spacing: 0.15em;\n");
        cssContent.append("  text-transform: uppercase;\n");
        cssContent.append("}\n\n");

        // Media Query
        cssContent.append("@media (max-width: 900px) {\n");
        cssContent.append("  .card-preview {\n");
        cssContent.append("    width: 180px;\n");
        cssContent.append("    padding: 12px 14px;\n");
        cssContent.append("  }\n\n");
        
        cssContent.append("  .card-preview h3 {\n");
        cssContent.append("    font-size: 15px;\n");
        cssContent.append("  }\n\n");
        
        cssContent.append("  .card-preview p {\n");
        cssContent.append("    font-size: 11px;\n");
        cssContent.append("  }\n\n");
        
        cssContent.append("  .tooltip {\n");
        cssContent.append("    font-size: 15px;\n");
        cssContent.append("  }\n\n");
        
        cssContent.append("  .full-overlay .panel {\n");
        cssContent.append("    padding: 20px 24px;\n");
        cssContent.append("    max-width: 300px;\n");
        cssContent.append("  }\n\n");
        
        cssContent.append("  .full-overlay h3 {\n");
        cssContent.append("    font-size: 20px;\n");
        cssContent.append("  }\n");
        cssContent.append("}\n");

        // Schreiben in Datei
        try (FileWriter writer = new FileWriter(filename)) {
            writer.write(cssContent.toString());
            System.out.println("CSS-Datei erfolgreich erstellt: " + filename);
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der CSS-Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
