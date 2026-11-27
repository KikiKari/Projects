// abstraction-provenance: {"artifact_sha256": "ae3ff618d514c0df5ae3730757d6e390c9c99da556412ebcf98b8a9a9d75d73e", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "java"}
// status-overview.css — portiert nach java
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class StatusOverviewCSS {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java StatusOverviewCSS <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            generateCSS(outputFile);
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static void generateCSS(String outputFile) throws IOException {
        StringBuilder css = new StringBuilder();
        
        // Global styles
        css.append("*{box-sizing:border-box}")
           .append("html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}")
           .append("body{display:flex;flex-direction:column;height:100vh}")
           
           // Header styles
           .append("header{display:flex;gap:1em;align-items:baseline;padding:0 12px}")
           .append("h1{font-size:17px;margin:8px 0}")
           .append("header p{font-size:12px;color:#bbb;margin:0}")
           
           // Main grid layout
           .append("main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));")
           .append("grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}")
           
           // Tile styles
           .append(".tile{min-width:0;min-height:0;display:flex;flex-direction:column;")
           .append("background:#202026;border:1px solid #393940}")
           .append(".tile h2{font-size:13px;margin:3px 8px}")
           .append(".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}")
           .append(".tile p{font-size:11px;margin:3px 8px;color:#ddd}")
           
           // Alternative grid layout
           .append("main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));")
           .append("grid-template-rows:repeat(2,minmax(0,1fr))}")
           
           // Hidden elements
           .append(".tile[hidden]{display:none}");
        
        Files.write(Paths.get(outputFile), css.toString().getBytes());
    }
}
