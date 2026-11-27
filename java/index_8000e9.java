// abstraction-provenance: {"artifact_sha256": "40d6d5ab5e2ca853d3300bac34415c2778edaeaeb6def44eecefd791d2147e26", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;

public class HtmlGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie den Dateinamen als Parameter an.");
            System.exit(1);
        }
        
        String filename = args[0];
        generateHtml(filename);
    }

    private static void generateHtml(String filename) {
        try (FileWriter writer = new FileWriter(filename)) {
            writer.write("<!DOCTYPE html>\n");
            writer.write("<html lang=\"de\">\n");
            writer.write("<head>\n");
            writer.write("<meta charset=\"UTF-8\">\n");
            writer.write("<title>Hover-Preview Varianten · Vergleich</title>\n");
            writer.write("<style>\n");
            writer.write("  :root {\n");
            writer.write("    --bg: #FAF8F4;\n");
            writer.write("    --ink: #1B1A17;\n");
            writer.write("    --accent: #A8542F;\n");
            writer.write("    --accent-2: #2E7D7B;\n");
            writer.write("    --font-display: 'Newsreader', Georgia, serif;\n");
            writer.write("    --font-body: 'Hanken Grotesk', -apple-system, sans-serif;\n");
            writer.write("    --font-mono: 'JetBrains Mono', monospace;\n");
            writer.write("  }\n");
            writer.write("  * { box-sizing: border-box; margin: 0; padding: 0; }\n");
            writer.write("  body {\n");
            writer.write("    font-family: var(--font-body);\n");
            writer.write("    background: var(--bg);\n");
            writer.write("    color: var(--ink);\n");
            writer.write("    padding: 32px 16px 80px;\n");
            writer.write("  }\n");
            writer.write("  h1 {\n");
            writer.write("    font-family: var(--font-display);\n");
            writer.write("    font-weight: 500;\n");
            writer.write("    font-size: 28px;\n");
            writer.write("    max-width: 1400px;\n");
            writer.write("    margin: 0 auto 12px;\n");
            writer.write("  }\n");
            writer.write("  .intro {\n");
            writer.write("    max-width: 1400px;\n");
            writer.write("    margin: 0 auto 32px;\n");
            writer.write("    color: #666;\n");
            writer.write("    font-size: 14px;\n");
            writer.write("    line-height: 1.5;\n");
            writer.write("  }\n");
            writer.write("  .grid {\n");
            writer.write("    display: grid;\n");
            writer.write("    gap: 32px;\n");
            writer.write("    max-width: 1400px;\n");
            writer.write("    margin: 0 auto;\n");
            writer.write("  }\n");
            writer.write("  .variant {\n");
            writer.write("    background: #000;\n");
            writer.write("    border-radius: 16px;\n");
            writer.write("    overflow: hidden;\n");
            writer.write("    box-shadow: 0 12px 40px rgba(0,0,0,0.15);\n");
            writer.write("  }\n");
            writer.write("  .variant-header {\n");
            writer.write("    background: #fff;\n");
            writer.write("    padding: 16px 24px;\n");
            writer.write("    display: flex;\n");
            writer.write("    align-items: center;\n");
            writer.write("    justify-content: space-between;\n");
            writer.write("    gap: 16px;\n");
            writer.write("    border-bottom: 1px solid #eee;\n");
            writer.write("  }\n");
            writer.write("  .variant-label {\n");
            writer.write("    font-family: var(--font-mono);\n");
            writer.write("    font-size: 11px;\n");
            writer.write("    letter-spacing: 0.2em;\n");
            writer.write("    text-transform: uppercase;\n");
            writer.write("    color: var(--accent);\n");
            writer.write("    font-weight: 600;\n");
            writer.write("  }\n");
            writer.write("  .variant-title {\n");
            writer.write("    font-family: var(--font-display);\n");
            writer.write("    font-size: 20px;\n");
            writer.write("    font-weight: 500;\n");
            writer.write("  }\n");
            writer.write("  .variant-desc {\n");
            writer.write("    font-size: 13px;\n");
            writer.write("    color: #666;\n");
            writer.write("    flex: 1;\n");
            writer.write("    text-align: right;\n");
            writer.write("  }\n");
            writer.write("  .scene {\n");
            writer.write("    position: relative;\n");
            writer.write("    aspect-ratio: 16 / 9;\n");
            writer.write("    background: url('bg.png') center/cover no-repeat;\n");
            writer.write("    overflow: hidden;\n");
            writer.write("  }\n");
            writer.write("  .orb {\n");
            writer.write("    position: absolute;\n");
            writer.write("    width: 12%;\n");
            writer.write("    aspect-ratio: 1;\n");
            writer.write("    left: 42%;\n");
            writer.write("    top: 55%;\n");
            writer.write("    transform: translate(-50%, -50%);\n");
            writer.write("    cursor: pointer;\n");
            writer.write("  }\n");
            writer.write("  .orb img { width: 100%; height: 100%; object-fit: contain; }\n\n");
            
            writer.write("  /* Variante 1: Karte daneben */\n");
            writer.write("  .card-preview {\n");
            writer.write("    position: absolute;\n");
            writer.write("    left: 55%;\n");
            writer.write("    top: 45%;\n");
            writer.write("    background: rgba(255,255,255,0.98);\n");
            writer.write("    padding: 16px 20px;\n");
            writer.write("    border-radius: 12px;\n");
            writer.write("    box-shadow: 0 8px 24px rgba(0,0,0,0.25);\n");
            writer.write("    width: 240px;\n");
            writer.write("    animation: slideIn 0.3s ease-out;\n");
            writer.write("  }\n");
            writer.write("  .card-preview .badge {\n");
            writer.write("    display: inline-block;\n");
            writer.write("    background: var(--accent-2);\n");
            writer.write("    color: white;\n");
            writer.write("    font-family: var(--font-mono);\n");
            writer.write("    font-size: 9px;\n");
            writer.write("    letter-spacing: 0.15em;\n");
            writer.write("    text-transform: uppercase;\n");
            writer.write("    padding: 3px 8px;\n");
            writer.write("    border-radius: 3px;\n");
            writer.write("    margin-bottom: 8px;\n");
            writer.write("  }\n");
            writer.write("  .card-preview h3 {\n");
            writer.write("    font-family: var(--font-display);\n");
            writer.write("    font-size: 18px;\n");
            writer.write("    font-weight: 500;\n");
            writer.write("    margin-bottom: 6px;\n");
            writer.write("    color: var(--ink);\n");
            writer.write("  }\n");
            writer.write("  .card-preview p {\n");
            writer.write("    font-size: 12px;\n");
            writer.write("    color: #555;\n");
            writer.write("    line-height: 1.4;\n");
            writer.write("  }\n");
            writer.write("  @keyframes slideIn {\n");
            writer.write("    from { opacity: 0; transform: translateX(-8px); }\n");
            writer.write("    to { opacity: 1; transform: translateX(0); }\n");
            writer.write("  }\n\n");
            
            writer.write("  /* Variante 2: Minimaler Tooltip */\n");
            writer.write("  .tooltip {\n");
            writer.write("    position: absolute;\n");
            writer.write("    left: 42%;\n");
            writer.write("    top: 46%;\n");
            writer.write("    transform: translate(-50%, -100%);\n");
            writer.write("    color: white;\n");
            writer.write("    text-shadow: 0 2px 12px rgba(0,0,0,0.8);\n");
            writer.write("    font-family: var(--font-display);\n");
            writer.write("    font-size: 20px;\n");
            writer.write("    font-weight: 500;\n");
            writer.write("    white-space: nowrap;\n");
            writer.write("    animation: fadeUp 0.3s ease-out;\n");
            writer.write("  }\n");
            writer.write("  @keyframes fadeUp {\n");
            writer.write("    from { opacity: 0; transform: translate(-50%, -80%); }\n");
            writer.write("    to { opacity: 1; transform: translate(-50%, -100%); }\n");
            writer.write("  }\n\n");
            
            writer.write("  /* Variante 3: Vollflächiges Overlay */\n");
            writer.write("  .full-overlay {\n");
            writer.write("    position: absolute;\n");
            writer.write("    inset: 0;\n");
            writer.write("    background: rgba(0,0,0,0.5);\n");
            writer.write("    backdrop-filter: blur(6px);\n");
            writer.write("    display: flex;\n");
            writer.write("    align-items: center;\n");
            writer.write("    justify-content: center;\n");
            writer.write("    animation: fadeIn 0.35s ease-out;\n");
            writer.write("  }\n");
            writer.write("  .full-overlay .panel {\n");
            writer.write("    background: rgba(255,255,255,0.98);\n");
            writer.write("    padding: 32px 40px;\n");
            writer.write("    border-radius: 20px;\n");
            writer.write("    max-width: 420px;\n");
            writer.write("    box-shadow: 0 20px 60px rgba(0,0,0,0.4);\n");
            writer.write("    text-align: center;\n");
            writer.write("  }\n");
            writer.write("  .full-overlay .badge {\n");
            writer.write("    display: inline-block;\n");
            writer.write("    background: var(--accent);\n");
            writer.write("    color: white;\n");
            writer.write("    font-family: var(--font-mono);\n");
            writer.write("    font-size: 10px;\n");
            writer.write("    letter-spacing: 0.2em;\n");
            writer.write("    text-transform: uppercase;\n");
            writer.write("    padding: 4px 10px;\n");
            writer.write("    border-radius: 4px;\n");
            writer.write("    margin-bottom: 14px;\n");
            writer.write("  }\n");
            writer.write("  .full-overlay h3 {\n");
            writer.write("    font-family: var(--font-display);\n");
            writer.write("    font-size: 28px;\n");
            writer.write("    font-weight: 500;\n");
            writer.write("    margin-bottom: 10px;\n");
            writer.write("    color: var(--ink);\n");
            writer.write("  }\n");
            writer.write("  .full-overlay p {\n");
            writer.write("    font-size: 14px;\n");
            writer.write("    color: #555;\n");
            writer.write("    line-height: 1.5;\n");
            writer.write("    margin-bottom: 20px;\n");
            writer.write("  }\n");
            writer.write("  .full-overlay .preview-img {\n");
            writer.write("    width: 100%;\n");
            writer.write("    aspect-ratio: 16/10;\n");
            writer.write("    background: linear-gradient(135deg, #A8542F, #2E7D7B);\n");
            writer.write("    border-radius: 8px;\n");
            writer.write("    margin-bottom: 16px;\n");
            writer.write("    display: flex;\n");
            writer.write("    align-items: center;\n");
            writer.write("    justify-content: center;\n");
            writer.write("    color: white;\n");
            writer.write("    font-family: var(--font-mono);\n");
            writer.write("    font-size: 11px;\n");
            writer.write("    letter-spacing: 0.15em;\n");
            writer.write("    opacity: 0.9;\n");
            writer.write("  }\n");
            writer.write("  @keyframes fadeIn {\n");
            writer.write("    from { opacity: 0; }\n");
            writer.write("    to { opacity: 1; }\n");
            writer.write("  }\n\n");
            
            writer.write("  .instruction {\n");
            writer.write("    text-align: center;\n");
            writer.write("    color: #999;\n");
            writer.write("    font-size: 12px;\n");
            writer.write("    margin-top: 16px;\n");
            writer.write("    font-family: var(--font-mono);\n");
            writer.write("    letter-spacing: 0.15em;\n");
            writer.write("    text-transform: uppercase;\n");
            writer.write("  }\n\n");
            
            writer.write("  @media (max-width: 900px) {\n");
            writer.write("    .card-preview { width: 180px; padding: 12px 14px; }\n");
            writer.write("    .card-preview h3 { font-size: 15px; }\n");
            writer.write("    .card-preview p { font-size: 11px; }\n");
            writer.write("    .tooltip { font-size: 15px; }\n");
            writer.write("    .full-overlay .panel { padding: 20px 24px; max-width: 300px; }\n");
            writer.write("    .full-overlay h3 { font-size: 20px; }\n");
            writer.write("  }\n");
            writer.write("</style>\n");
            writer.write("<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n");
            writer.write("<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n");
            writer.write("<link href=\"https://fonts.googleapis.com/css2?family=Newsreader:wght@400;500&family=Hanken+Grotesk:wght@400;500&family=JetBrains+Mono:wght@400;500&display=swap\" rel=\"stylesheet\">\n");
            writer.write("</head>\n");
            writer.write("<body>\n\n");
            
            writer.write("<h1>Hover-Preview · drei Varianten im Vergleich</h1>\n");
            writer.write("<p class=\"intro\">Gleiche Szene, gleiche Kugel-Position (Beispiel: Projekt-Kugel \"Weather-Check\").<br>Alle drei Varianten zeigen den Zustand <em>bei Maushover</em>. Welche soll ins Projekt?</p>\n\n");
            
            writer.write("<div class=\"grid\">\n\n");
            
            // Variante 1
            writer.write("  <!-- Variante 1 -->\n");
            writer.write("  <div class=\"variant\">\n");
            writer.write("    <div class=\"variant-header\">\n");
            writer.write("      <div>\n");
            writer.write("        <div class=\"variant-label\">Variante 1</div>\n");
            writer.write("        <div class=\"variant-title\">Karte daneben</div>\n");
            writer.write("      </div>\n");
            writer.write("      <div class=\"variant-desc\">Kompakte Card rechts der Kugel · Titel + Badge + kurze Beschreibung aus content.ts · dezent, nicht störend</div>\n");
            writer.write("    </div>\n");
            writer.write("    <div class=\"scene\">\n");
            writer.write("      <div class=\"orb\"><img src=\"orb-01-teal.png\" alt=\"\"></div>\n");
            writer.write("      <div class=\"card-preview\">\n");
            writer.write("        <span class=\"badge\">GitHub · Public</span>\n");
            writer.write("        <h3>Weather-Check</h3>\n");
            writer.write("        <p>Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.</p>\n");
            writer.write("      </div>\n");
            writer.write("    </div>\n");
            writer.write("  </div>\n\n");
            
            // Variante 2
            writer.write("  <!-- Variante 2 -->\n");
            writer.write("  <div class=\"variant\">\n");
            writer.write("    <div class=\"variant-header\">\n");
            writer.write("      <div>\n");
            writer.write("        <div class=\"variant-label\">Variante 2</div>\n");
            writer.write("        <div class=\"variant-title\">Minimaler Tooltip</div>\n");
            writer.write("      </div>\n");
            writer.write("      <div class=\"variant-desc\">Nur der Titel schwebt über der Kugel · maximal reduziert · schnell erfassbar · lässt die Bildwirkung ungestört</div>\n");
            writer.write("    </div>\n");
            writer.write("    <div class=\"scene\">\n");
            writer.write("      <div class=\"orb\"><img src=\"orb-01-teal.png\" alt=\"\"></div>\n");
            writer.write("      <div class=\"tooltip\">Weather-Check</div>\n");
            writer.write("    </div>\n");
            writer.write("  </div>\n\n");
            
            // Variante 3
            writer.write("  <!-- Variante 3 -->\n");
            writer.write("  <div class=\"variant\">\n");
            writer.write("    <div class=\"variant-header\">\n");
            writer.write("      <div>\n");
            writer.write("        <div class=\"variant-label\">Variante 3</div>\n");
            writer.write("        <div class=\"variant-title\">Vollflächiges Overlay</div>\n");
            writer.write("      </div>\n");
            writer.write("      <div class=\"variant-desc\">Zentrales Modal mit Preview-Bild + Titel + Beschreibung · prominent · lädt zum Klicken ein · verdeckt aber Szene</div>\n");
            writer.write("    </div>\n");
            writer.write("    <div class=\"scene\">\n");
            writer.write("      <div class=\"orb\"><img src=\"orb-01-teal.png\" alt=\"\"></div>\n");
            writer.write("      <div class=\"full-overlay\">\n");
            writer.write("        <div class=\"panel\">\n");
            writer.write("          <div class=\"preview-img\">PROJEKT-PREVIEW</div>\n");
            writer.write("          <span class=\"badge\">GitHub · Public</span>\n");
            writer.write("          <h3>Weather-Check</h3>\n");
            writer.write("          <p>Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.</p>\n");
            writer.write("        </div>\n");
            writer.write("      </div>\n");
            writer.write("    </div>\n");
            writer.write("  </div>\n\n");
            
            writer.write("</div>\n\n");
            
            writer.write("<p class=\"instruction\">Sag mir welche Variante — dann baue ich sie ins Frontend ein.</p>\n\n");
            
            writer.write("</body>\n");
            writer.write("</html>\n");
            
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
