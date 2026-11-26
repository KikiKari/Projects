// abstraction-provenance: {"artifact_sha256": "35e9a38fbe1d30bad213a90e64bced2a6ce3a673cb19154d7c00704c4fd32681", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class IndexHtmlGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java IndexHtmlGenerator <ausgabedatei>");
            System.exit(1);
        }
        
        String dateiname = args[0];
        
        try {
            generiereIndexHtml(dateiname);
            System.out.println("Datei " + dateiname + " erfolgreich erstellt.");
        } catch (IOException e) {
            System.err.println("Fehler beim Erstellen der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
    
    /**
     * Erzeugt eine HTML-Datei mit Weiterleitung zur 3D-Ansicht
     * @param dateiname Pfad zur Ausgabedatei
     * @throws IOException wenn die Datei nicht geschrieben werden kann
     */
    public static void generiereIndexHtml(String dateiname) throws IOException {
        try (FileWriter writer = new FileWriter(dateiname, StandardCharsets.UTF_8)) {
            // DOCTYPE
            writer.write("<!DOCTYPE html>\n");
            
            // HTML-Element mit Sprachattribut
            writer.write("<html lang=\"de\">\n");
            
            // Kopfbereich
            writer.write("<head>\n");
            writer.write("<meta charset=\"utf-8\">\n");
            writer.write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
            writer.write("<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">\n");
            writer.write("<title>Weiterleitung zur 3D-Ansicht</title>\n");
            writer.write("<link rel=\"canonical\" href=\"3d.html\">\n");
            writer.write("<script>location.replace('3d.html');</script>\n");
            writer.write("</head>\n");
            
            // Body-Bereich
            writer.write("<body>\n");
            writer.write("<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>\n");
            writer.write("</body>\n");
            
            // Abschluss
            writer.write("</html>\n");
        }
    }
}
