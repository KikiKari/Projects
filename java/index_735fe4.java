// abstraction-provenance: {"artifact_sha256": "dbc2785aabfc51909974d224d2b56339d7c034990fa96a8c1da5a8d6572f8bd1", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class IndexGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IndexGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        generateIndexHtml(outputFile);
    }
    
    /**
     * Erzeugt die index.html Datei mit der angegebenen Struktur
     * @param outputPath Der Pfad zur Ausgabedatei
     */
    public static void generateIndexHtml(String outputPath) {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE und HTML-Start
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"de\">\n");
        
        // HEAD-Bereich
        html.append("  <head>\n");
        html.append("    <meta charset=\"utf-8\" />\n");
        html.append("    <link rel=\"icon\" href=\"/favicon.ico\" />\n");
        html.append("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n");
        html.append("    <meta name=\"theme-color\" content=\"#0b1020\" />\n");
        html.append("    <meta\n");
        html.append("      name=\"description\"\n");
        html.append("      content=\"OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.\"\n");
        html.append("    />\n");
        html.append("    <link rel=\"apple-touch-icon\" href=\"/logo192.png\" />\n");
        
        // Kommentarblock
        html.append("    <!--\n");
        html.append("      manifest.json provides metadata used when your web app is installed on a\n");
        html.append("      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/\n");
        html.append("    -->\n");
        
        html.append("    <link rel=\"manifest\" href=\"/manifest.json\" />\n");
        html.append("    <title>OpenClaw</title>\n");
        html.append("  </head>\n");
        
        // BODY-Bereich
        html.append("  <body>\n");
        html.append("    <noscript>You need to enable JavaScript to run this app.</noscript>\n");
        html.append("    <div id=\"root\"></div>\n");
        
        // Kommentarblock
        html.append("    <!--\n");
        html.append("      This HTML file is a template.\n");
        html.append("      If you open it directly in the browser, you will see an empty page.\n\n");
        html.append("      You can add webfonts, meta tags, or analytics to this file.\n");
        html.append("      The build step will place the bundled scripts into the <body> tag.\n\n");
        html.append("      To begin the development, run `npm start` or `yarn start`.\n");
        html.append("      To create a production bundle, use `npm run build` or `yarn build`.\n");
        html.append("    -->\n");
        
        html.append("  </body>\n");
        
        // Script-Tag
        html.append("  <script type=\"module\" src=\"/src/index.jsx\"></script>\n");
        html.append("</html>\n");
        
        // Schreiben in Datei
        try {
            Files.createDirectories(Path.of(outputPath).getParent());
            try (FileWriter writer = new FileWriter(outputPath)) {
                writer.write(html.toString());
            }
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
