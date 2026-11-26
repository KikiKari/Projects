// abstraction-provenance: {"artifact_sha256": "b70a5e243f0d19a26833480edd6503ff3e7bc423418dde1f6625b136ce84d755", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "java"}
// collect_compare_bundle.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;

public class CollectCompareBundle {

    private static final String ROOT = "/home/openclaw/.openclaw";
    private static final String OUT_DIR = ROOT + "/workspace/vscode/compare";
    private static final String TRANSFER_DIR = OUT_DIR + "/transfer";
    private static final String MD_FILE = OUT_DIR + "/local-gateway-config.md";
    private static final String TREE_FILE = OUT_DIR + "/tree.txt";
    private static final String BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz";

    private static final String OPENCLAW_JSON = ROOT + "/openclaw.json";
    private static final String EXEC_APPROVALS_JSON = ROOT + "/exec-approvals.json";
    private static final String GATEWAY_SYSTEMD_ENV = ROOT + "/gateway.systemd.env";
    private static final String DOT_ENV = ROOT + "/.env";
    private static final String CONFIG_DIR = ROOT + "/.config";
    private static final String AGENTS_DIR = ROOT + "/agents";

    private static final String NOW_LOCAL = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z"));
    private static final String NOW_UTC = LocalDateTime.now(ZoneId.of("UTC")).format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
    private static final String HOST = getHostname();

    public static void main(String[] args) throws IOException, InterruptedException {
        // Erstelle Verzeichnisse
        Files.createDirectories(Paths.get(OUT_DIR));
        Files.createDirectories(Paths.get(TRANSFER_DIR));

        // Prüfe ob 'tree' Kommando existiert
        if (!isCommandAvailable("tree")) {
            System.err.println("Fehler: 'tree' ist nicht installiert.");
            System.exit(1);
        }

        // Schreibe Header in Markdown-Datei
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(MD_FILE))) {
            writer.write("# Lokaler Gateway-Konfigurationsstand\n");
            writer.write("\n");
            writer.write("Generiert: " + NOW_LOCAL + "\n");
            writer.write("UTC: " + NOW_UTC + "\n");
            writer.write("Host: " + HOST + "\n");
            writer.write("\n");
            writer.write("Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n");
        }

        appendFileVerbatim("openclaw.json", OPENCLAW_JSON, "json");
        appendFileVerbatim("exec-approvals.json", EXEC_APPROVALS_JSON, "json");
        appendFileVerbatim("gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv");
        appendFileVerbatim(".env", DOT_ENV, "dotenv");
        appendEnvVerbatim();
        appendDirFilesVerbatim(".config (alle Dateien rekursiv)", CONFIG_DIR);
        appendDirFilesVerbatim("agents (alle Dateien rekursiv)", AGENTS_DIR);

        // Führe 'tree' Befehl aus
        ProcessBuilder treeProcess = new ProcessBuilder("tree", "-a", "-L", "6", ROOT);
        treeProcess.redirectOutput(new File(TREE_FILE));
        treeProcess.start().waitFor();

        // Führe Backup-Befehl aus
        ProcessBuilder backupProcess = new ProcessBuilder("openclaw", "backup", "create", "--output", BACKUP_FILE, "--verify");
        backupProcess.inheritIO();
        int backupExitCode = backupProcess.start().waitFor();
        if (backupExitCode != 0) {
            System.err.println("Backup-Prozess mit Fehler beendet: " + backupExitCode);
            System.exit(backupExitCode);
        }

        // Kopiere Backup-Datei
        Files.copy(Paths.get(BACKUP_FILE), Paths.get(OUT_DIR, "openclaw-backup.tar.gz"), StandardCopyOption.REPLACE_EXISTING);

        System.out.println("OK");
        System.out.println("Erzeugt:");
        System.out.println("- " + MD_FILE);
        System.out.println("- " + TREE_FILE);
        System.out.println("- " + BACKUP_FILE);
        System.out.println("- " + TRANSFER_DIR + " (leer)");
    }

    private static void appendFileVerbatim(String label, String path, String lang) throws IOException {
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(MD_FILE), StandardOpenOption.APPEND)) {
            writer.write("\n## " + label + "\n\n");
            writer.write("Pfad: `" + path + "`\n\n");
            writer.write("```" + lang + "\n");
            if (Files.exists(Paths.get(path))) {
                List<String> lines = Files.readAllLines(Paths.get(path));
                for (String line : lines) {
                    writer.write(line + "\n");
                }
            } else {
                writer.write("[FEHLT] " + path + "\n");
            }
            writer.write("\n```\n");
        }
    }

    private static void appendEnvVerbatim() throws IOException {
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(MD_FILE), StandardOpenOption.APPEND)) {
            writer.write("\n## Umgebungsvariablen (env)\n\n");
            writer.write("```text\n");
            Map<String, String> env = System.getenv();
            for (Map.Entry<String, String> entry : env.entrySet()) {
                writer.write(entry.getKey() + "=" + entry.getValue() + "\n");
            }
            writer.write("```\n");
        }
    }

    private static void appendDirFilesVerbatim(String section, String dir) throws IOException {
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(MD_FILE), StandardOpenOption.APPEND)) {
            writer.write("\n## " + section + "\n\n");
            Path dirPath = Paths.get(dir);
            if (!Files.isDirectory(dirPath)) {
                writer.write("[FEHLT] " + dir + "\n");
                return;
            }
            writer.write("Basisverzeichnis: `" + dir + "`\n");

            Files.walk(dirPath)
                 .filter(Files::isRegularFile)
                 .sorted()
                 .forEach(file -> {
                     try {
                         writer.write("\n### Datei: `" + file.toString() + "`\n\n");
                         writer.write("```text\n");
                         List<String> lines = Files.readAllLines(file);
                         for (String line : lines) {
                             writer.write(line + "\n");
                         }
                         writer.write("\n```\n");
                     } catch (IOException e) {
                         throw new RuntimeException(e);
                     }
                 });
        }
    }

    private static boolean isCommandAvailable(String command) {
        try {
            ProcessBuilder pb = new ProcessBuilder("which", command);
            pb.redirectErrorStream(true);
            Process process = pb.start();
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static String getHostname() {
        try {
            ProcessBuilder pb = new ProcessBuilder("hostname", "-f");
            pb.redirectErrorStream(true);
            Process process = pb.start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line = reader.readLine();
            int exitCode = process.waitFor();
            if (exitCode == 0 && line != null) {
                return line.trim();
            } else {
                pb = new ProcessBuilder("hostname");
                pb.redirectErrorStream(true);
                process = pb.start();
                reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                line = reader.readLine();
                process.waitFor();
                return line != null ? line.trim() : "unknown";
            }
        } catch (Exception e) {
            return "unknown";
        }
    }
}
