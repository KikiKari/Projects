// abstraction-provenance: {"artifact_sha256": "eaf060e98afeac7197c3fb34856074b13a21f2779230b255a98edfd65e92d1d4", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "java"}
// abstractions-manager.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

public class AbstractionsManager {
    public static void main(String[] args) {
        try {
            // Führe das externe Skript mit denselben Argumenten aus
            ProcessBuilder pb = new ProcessBuilder();
            pb.command("/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh");
            
            // Übergebe alle Argumente an das Skript
            for (String arg : args) {
                pb.command().add(arg);
            }
            
            // Starte den Prozess und warte auf dessen Beendigung
            Process process = pb.start();
            int exitCode = process.waitFor();
            
            // Beende das Java-Programm mit demselben Exit-Code
            System.exit(exitCode);
            
        } catch (Exception e) {
            System.err.println("Fehler beim Ausführen des Skripts: " + e.getMessage());
            System.exit(1);
        }
    }
}
