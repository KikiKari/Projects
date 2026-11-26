// abstraction-provenance: {"artifact_sha256": "1d531e8493a451faef4d7894a19f028a73c9e1f161715da7117175d56fb953f3", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "java"}
// fix_gateway_node_path.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class FixGatewayNodePath {

    public static void main(String[] args) {
        try {
            // Backup der originalen Service-Datei
            backupServiceFile();

            // Korrektur des Node.js Pfads in der Service-Datei
            fixNodePath();

            // Service neu laden und neu starten
            reloadAndRestartService();

            // Status prüfen
            checkServiceStatus();

        } catch (Exception e) {
            System.err.println("Fehler beim Ausführen des Skripts: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void backupServiceFile() throws IOException {
        String serviceFilePath = "/etc/systemd/system/openclaw-gateway.service";
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
        String backupFileName = "openclaw-gateway.service.backup-" + now.format(formatter);
        String backupFilePath = "/etc/systemd/system/" + backupFileName;

        Path source = Paths.get(serviceFilePath);
        Path target = Paths.get(backupFilePath);

        Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
        System.out.println("Backup erstellt: " + backupFilePath);
    }

    private static void fixNodePath() throws IOException {
        String serviceFilePath = "/etc/systemd/system/openclaw-gateway.service";
        String oldNodePath = "/home/openclaw/.nvm/versions/node/v22.22.2/bin/node";
        String newNodePath = "/usr/bin/node";

        // Datei einlesen
        Path path = Paths.get(serviceFilePath);
        String content = new String(Files.readAllBytes(path));

        // Pfad ersetzen
        String updatedContent = content.replace(oldNodePath, newNodePath);

        // Aktualisierten Inhalt zurückschreiben
        Files.write(path, updatedContent.getBytes());
        System.out.println("Node.js Pfad korrigiert in: " + newNodePath);
    }

    private static void reloadAndRestartService() throws Exception {
        // systemctl daemon-reload
        ProcessBuilder pb1 = new ProcessBuilder("systemctl", "daemon-reload");
        Process process1 = pb1.start();
        int exitCode1 = process1.waitFor();
        if (exitCode1 != 0) {
            throw new RuntimeException("systemctl daemon-reload fehlgeschlagen mit Exit-Code: " + exitCode1);
        }

        // systemctl restart openclaw-gateway
        ProcessBuilder pb2 = new ProcessBuilder("systemctl", "restart", "openclaw-gateway");
        Process process2 = pb2.start();
        int exitCode2 = process2.waitFor();
        if (exitCode2 != 0) {
            throw new RuntimeException("systemctl restart openclaw-gateway fehlgeschlagen mit Exit-Code: " + exitCode2);
        }

        System.out.println("Service neu geladen und neu gestartet");
    }

    private static void checkServiceStatus() throws Exception {
        ProcessBuilder pb = new ProcessBuilder("systemctl", "status", "openclaw-gateway", "--no-pager");
        Process process = pb.start();

        // Ausgabe des Status auf Konsole weiterleiten
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
            System.out.println(line);
        }

        int exitCode = process.waitFor();
        if (exitCode != 0) {
            System.err.println("Warnung: systemctl status gab Exit-Code " + exitCode + " zurück");
        }
    }
}
