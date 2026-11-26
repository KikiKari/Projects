// abstraction-provenance: {"artifact_sha256": "3b68be952eecf47f118ac290cb083f5131a63e0c96195c34585d7e1a3fa01550", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "java"}
// openclaw-maintenance.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class OpenClawMaintenance {

    private static final String OPENCLAW_BIN = System.getenv().getOrDefault("OPENCLAW_BIN", System.getProperty("user.home") + "/.local/bin/openclaw");

    public static void main(String[] args) {
        try {
            // Prüfe ob die OpenClaw-Binärdatei existiert und ausführbar ist
            Path binPath = Paths.get(OPENCLAW_BIN);
            if (!Files.exists(binPath) || !Files.isExecutable(binPath)) {
                System.err.println("ERROR: OpenClaw binary not found: " + OPENCLAW_BIN);
                System.exit(1);
            }

            // Zeige Version an
            System.out.println("Using OpenClaw: " + executeCommand(OPENCLAW_BIN, "--version"));

            // === 1. Service-/Config-Drift ===
            executeCommand(OPENCLAW_BIN, "doctor");

            // === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
            executeCommand(OPENCLAW_BIN, "plugins", "registry", "--refresh");
            
            String runPluginUpdate = System.getenv().getOrDefault("RUN_PLUGIN_UPDATE", "0");
            if ("1".equals(runPluginUpdate)) {
                executeCommand(OPENCLAW_BIN, "plugins", "update", "--all");
            } else {
                System.out.println("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.");
            }

            // === 3. Tasks ===
            executeCommand(OPENCLAW_BIN, "tasks", "maintenance", "--apply");

            // === 4. Sessions – alle Agents auf einmal ===
            executeCommand(OPENCLAW_BIN, "sessions", "cleanup", "--enforce", "--all-agents");

            // === 5. Memory – status/index decken alle Agents ab ===
            executeCommand(OPENCLAW_BIN, "memory", "status", "--deep", "--fix");
            executeCommand(OPENCLAW_BIN, "memory", "index", "--force");

            // === 6. Memory promote – MUSS pro Agent ===
            String[] agents = {"main", "knecht", "docs", "ops-hub", "cron"};
            for (String agent : agents) {
                executeCommand(OPENCLAW_BIN, "memory", "promote", "--apply", "--agent", agent);
            }

            // === 7. Secrets ===
            executeCommand(OPENCLAW_BIN, "secrets", "reload");

        } catch (Exception e) {
            System.err.println("Fehler bei der Ausführung: " + e.getMessage());
            System.exit(1);
        }
    }

    /**
     * Führt einen Befehl aus und gibt die Ausgabe zurück.
     *
     * @param command Befehl und Argumente
     * @return Ausgabe des Befehls
     * @throws IOException wenn ein Fehler beim Starten des Prozesses auftritt
     * @throws InterruptedException wenn der Thread unterbrochen wird
     */
    private static String executeCommand(String... command) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true); // Kombiniere stdout und stderr
        
        Process process = processBuilder.start();
        
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }
        
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("Befehl schlug fehl mit Exit-Code: " + exitCode + ", Ausgabe: " + output.toString());
        }
        
        String result = output.toString().trim();
        if (!result.isEmpty()) {
            System.out.println(result);
        }
        return result;
    }
}
