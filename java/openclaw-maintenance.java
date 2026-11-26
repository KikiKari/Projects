// abstraction-provenance: {"artifact_sha256": "50206a00f4b938b2ce9124c8ba59a9006d2030287ed475636459bc6955ea165c", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "java"}
// openclaw-maintenance.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.List;

public class OpenClawMaintenance {
    
    public static void main(String[] args) {
        OpenClawMaintenance maintenance = new OpenClawMaintenance();
        
        // === 1. Service-/Config-Drift ===
        maintenance.executeCommand("openclaw", "doctor");
        
        // === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
        maintenance.executeCommand("openclaw", "plugins", "registry", "--refresh");
        maintenance.executeCommand("openclaw", "plugins", "update", "--all");
        
        // === 3. Tasks ===
        maintenance.executeCommand("openclaw", "tasks", "maintenance", "--apply");
        
        // === 4. Sessions – alle Agents auf einmal ===
        maintenance.executeCommand("openclaw", "sessions", "cleanup", "--enforce", "--all-agents");
        
        // === 5. Memory – status/index decken alle Agents ab ===
        maintenance.executeCommand("openclaw", "memory", "status", "--deep", "--fix");
        maintenance.executeCommand("openclaw", "memory", "index", "--force");
        
        // === 6. Memory promote – MUSS pro Agent ===
        List<String> agents = Arrays.asList("main", "knecht", "docs", "ops-hub", "cron");
        for (String agent : agents) {
            maintenance.executeCommand("openclaw", "memory", "promote", "--apply", "--agent", agent);
        }
        
        // === 7. Secrets ===
        maintenance.executeCommand("openclaw", "secrets", "reload");
    }
    
    private void executeCommand(String... command) {
        try {
            ProcessBuilder processBuilder = new ProcessBuilder(command);
            Process process = processBuilder.start();
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
            
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.err.println("Command failed with exit code: " + exitCode);
            }
        } catch (IOException | InterruptedException e) {
            System.err.println("Error executing command: " + String.join(" ", command));
            e.printStackTrace();
        }
    }
}
