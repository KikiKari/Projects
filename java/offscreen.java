// abstraction-provenance: {"artifact_sha256": "40936f08be52c8619f671ed04008c2591bd646510a81fed4e9f03d3bcbc96326", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "java"}
// offscreen.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;

public class OffscreenGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java OffscreenGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            generateOffscreenHtml(outputFile);
            System.out.println("HTML file generated successfully: " + Paths.get(outputFile).toAbsolutePath());
        } catch (IOException e) {
            System.err.println("Error generating HTML file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    /**
     * Erzeugt die HTML-Struktur fuer das Offscreen-Dokument
     */
    private static void generateOffscreenHtml(String outputPath) throws IOException {
        try (FileWriter writer = new FileWriter(outputPath)) {
            // DOCTYPE declaration
            writer.write("<!doctype html>\n");
            
            // HTML root element with language attribute
            writer.write("<html lang=\"de\">\n");
            
            // Head section
            writer.write("<head>\n");
            writer.write("  <meta charset=\"utf-8\">\n");
            writer.write("  <title>TikTok LIVE Companion Sprachausgabe</title>\n");
            writer.write("</head>\n");
            
            // Body section
            writer.write("<body>\n");
            writer.write("  <script src=\"offscreen.js\"></script>\n");
            writer.write("</body>\n");
            
            // Close HTML tag
            writer.write("</html>\n");
        }
    }
}
