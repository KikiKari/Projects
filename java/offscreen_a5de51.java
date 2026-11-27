// abstraction-provenance: {"artifact_sha256": "202c4258a8a41200a15a0e894f3c62ebeda6388a622fbadbff8f7c1a2c9d2224", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "java"}
// offscreen.html — portiert nach java
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;

public class OffscreenGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java OffscreenGenerator <dateiname>");
            System.exit(1);
        }
        
        String dateiname = args[0];
        
        try {
            generateOffscreenHtml(dateiname);
            System.out.println("HTML-Datei erfolgreich erstellt: " + dateiname);
        } catch (IOException e) {
            System.err.println("Fehler beim Erstellen der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
    
    /**
     * Erzeugt das offscreen.html Dokument und schreibt es in eine Datei
     * @param dateiname Der Name der Ausgabedatei
     * @throws IOException wenn beim Schreiben der Datei ein Fehler auftritt
     */
    public static void generateOffscreenHtml(String dateiname) throws IOException {
        try (FileWriter writer = new FileWriter(dateiname)) {
            // DOCTYPE wird bei FileWriter nicht direkt unterstützt, 
            // aber wir fügen ihn als erste Zeile hinzu
            writer.write("<!DOCTYPE html>\n");
            writer.write("<html lang=\"de\">\n");
            writer.write("<head>\n");
            writer.write("  <meta charset=\"utf-8\">\n");
            writer.write("  <title>TikTok LIVE Companion Sprachausgabe</title>\n");
            writer.write("</head>\n");
            writer.write("<body>\n");
            writer.write("  <script src=\"offscreen.js\"></script>\n");
            writer.write("</body>\n");
            writer.write("</html>\n");
        }
    }
}
