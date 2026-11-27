// abstraction-provenance: {"artifact_sha256": "9deeb26f7d043f86d48f32a76f103f2c537e446f63c9eb9452c889b4dbfc7919", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "java"}
// status-overview.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class StatusOverviewGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java StatusOverviewGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            generateStatusOverview(outputFile);
            System.out.println("Status overview generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error generating status overview: " + e.getMessage());
            System.exit(1);
        }
    }
    
    public static void generateStatusOverview(String outputFile) throws IOException {
        try (FileWriter writer = new FileWriter(outputFile, StandardCharsets.UTF_8)) {
            // Write DOCTYPE
            writer.write("<!DOCTYPE html>\n");
            
            // Write html start tag with lang attribute
            writer.write("<html lang=\"de\">");
            
            // Write head section
            writer.write("<head>");
            writer.write("<meta charset=\"utf-8\">");
            writer.write("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
            writer.write("<title>STATUS-Overview</title>");
            writer.write("<link rel=\"stylesheet\" href=\"status-overview.css\">");
            writer.write("</head>");
            
            // Write body section
            writer.write("<body>");
            writer.write("<main id=\"grid\" aria-label=\"LIVE-Übersicht\"></main>");
            writer.write("<script src=\"vendor-mpegts.js\"></script>");
            writer.write("<script src=\"status-overview-player.js\"></script>");
            writer.write("</body>");
            
            // Close html tag
            writer.write("</html>");
        }
    }
}
