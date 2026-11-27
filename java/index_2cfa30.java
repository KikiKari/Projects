// abstraction-provenance: {"artifact_sha256": "67b763595ba2b80d06eeff77c274fa1baaf6ef261663f1eacc5ae557d1e3ea9f", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;

public class IndexGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java IndexGenerator <ausgabedatei>");
            System.exit(1);
        }
        
        String dateiname = args[0];
        
        try (FileWriter writer = new FileWriter(dateiname)) {
            // DOCTYPE und HTML-Start
            writer.write("<!DOCTYPE html>\n");
            writer.write("<html lang=\"de\">\n");
            
            // HEAD-Bereich
            writer.write("  <head>\n");
            writer.write("    <meta charset=\"UTF-8\" />\n");
            writer.write("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n");
            writer.write("    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n");
            writer.write("    <meta name=\"theme-color\" content=\"#ffffff\" />\n");
            writer.write("    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n");
            writer.write("    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n");
            writer.write("    <title>TikTok LIVE Companion – Dokumentation</title>\n");
            writer.write("  </head>\n");
            
            // BODY-Bereich
            writer.write("  <body>\n");
            writer.write("    <div id=\"root\"></div>\n");
            writer.write("    <script type=\"module\" src=\"/src/main.tsx\"></script>\n");
            writer.write("  </body>\n");
            
            // HTML-Ende
            writer.write("</html>\n");
            
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
