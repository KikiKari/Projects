// abstraction-provenance: {"artifact_sha256": "ff96f79b5faf1f7f2a68622ec7b19c53b8e9e708118db216a014c641ce7912bc", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "java"}
// node-monitor.css — portiert nach java
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.util.Map;

public class NodeMonitorCSS {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie einen Dateinamen als Parameter an.");
            System.exit(1);
        }
        
        String dateiname = args[0];
        erzeugeCSS(dateiname);
    }

    private static void erzeugeCSS(String dateiname) {
        try (FileWriter writer = new FileWriter(dateiname)) {
            // Kommentare
            writer.write("/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */\n");
            writer.write("/* node-monitor.html — portiert nach css */\n");
            writer.write("/* Quelle: html, OpenClaw@main:examples/node-monitor.html */\n");
            writer.write("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

            // Root-Variablen
            writer.write(":root {\n");
            Map<String, String> farben = Map.of(
                "--bg", "#0d1117",
                "--surface", "#161b22",
                "--border", "#30363d",
                "--text", "#e6edf3",
                "--green", "#3fb950",
                "--red", "#f85149",
                "--accent", "#58a6ff"
            );
            
            for (Map.Entry<String, String> eintrag : farben.entrySet()) {
                writer.write("  " + eintrag.getKey() + ": " + eintrag.getValue() + ";\n");
            }
            writer.write("}\n\n");

            // Globale Styles
            writer.write("* {\n");
            writer.write("  box-sizing: border-box;\n");
            writer.write("  margin: 0;\n");
            writer.write("  padding: 0;\n");
            writer.write("}\n\n");

            // Body-Style
            writer.write("body {\n");
            writer.write("  background: var(--bg);\n");
            writer.write("  color: var(--text);\n");
            writer.write("  font-family: -apple-system, sans-serif;\n");
            writer.write("  padding: 1.5rem;\n");
            writer.write("}\n\n");

            // H1-Style
            writer.write("h1 {\n");
            writer.write("  color: var(--accent);\n");
            writer.write("  margin-bottom: 1rem;\n");
            writer.write("  font-size: 1.2rem;\n");
            writer.write("}\n\n");

            // Canvas-Style
            writer.write("canvas {\n");
            writer.write("  display: block;\n");
            writer.write("  border: 1px solid var(--border);\n");
            writer.write("  border-radius: 8px;\n");
            writer.write("  background: var(--surface);\n");
            writer.write("}\n\n");

            // Log-Container
            writer.write("#log {\n");
            writer.write("  margin-top: 1rem;\n");
            writer.write("  height: 140px;\n");
            writer.write("  overflow-y: auto;\n");
            writer.write("  background: var(--surface);\n");
            writer.write("  border: 1px solid var(--border);\n");
            writer.write("  border-radius: 8px;\n");
            writer.write("  padding: .75rem;\n");
            writer.write("  font-size: .78rem;\n");
            writer.write("  font-family: monospace;\n");
            writer.write("  color: #8b949e;\n");
            writer.write("}\n\n");

            // Log Fehlermeldung
            writer.write("#log .err {\n");
            writer.write("  color: var(--red);\n");
            writer.write("}\n\n");

            // Log Erfolgsmeldung
            writer.write("#log .ok {\n");
            writer.write("  color: var(--green);\n");
            writer.write("}\n");
            
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der CSS-Datei: " + e.getMessage());
            System.exit(1);
        }
    }
}
