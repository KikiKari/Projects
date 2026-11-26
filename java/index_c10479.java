// abstraction-provenance: {"artifact_sha256": "bbb06435e51de03c974cfde0433c2779db295c89297b35a4b3e8abc0c839612d", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;

public class IndexGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IndexGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            // Write doctype
            writer.write("<!DOCTYPE html>\n");
            
            // Start html tag with language attribute
            writer.write("<html lang=\"de\">\n");
            
            // Head section
            writer.write("  <head>\n");
            writer.write("    <meta charset=\"UTF-8\" />\n");
            writer.write("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n");
            writer.write("    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n");
            writer.write("    <meta name=\"theme-color\" content=\"#ffffff\" />\n");
            writer.write("    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n");
            writer.write("    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n");
            writer.write("    <title>TikTok LIVE Companion – Dokumentation</title>\n");
            writer.write("  </head>\n");
            
            // Body section
            writer.write("  <body>\n");
            writer.write("    <div id=\"root\"></div>\n");
            writer.write("    <script type=\"module\" src=\"/src/main.tsx\"></script>\n");
            writer.write("  </body>\n");
            
            // Close html tag
            writer.write("</html>\n");
            
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }
}
