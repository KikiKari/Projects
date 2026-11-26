// abstraction-provenance: {"artifact_sha256": "2062a6f0c6d267bc71a16b705e1494ece139b108fbe0a03ebfbdf6ccee2c0168", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "java"}
// db_maintainer.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Database Maintainer Sub-Agent
 * Automated database maintenance with 30min checks, hourly backups (3 days retention),
 * band tree command execution for important/openclaw-tree.txt
 */
public class DbMaintainer {
    private static final Path WORKSPACE = Paths.get("/home/openclaw/.openclaw/workspace");
    private static final Path DB_DIR = WORKSPACE.resolve("db");
    private static final Path BACKUP_DIR = DB_DIR.resolve("backups");
    private static final Path LOG_DIR = WORKSPACE.resolve("logs").resolve("db-maintainer");
    private static final Path IMPORTANT_DIR = WORKSPACE.resolve("important");

    static {
        try {
            Files.createDirectories(BACKUP_DIR);
            Files.createDirectories(LOG_DIR);
        } catch (IOException e) {
            System.err.println("Failed to create directories: " + e.getMessage());
            System.exit(1);
        }
    }

    public static class Logger {
        private Path logFile;

        public Logger() {
            String today = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            this.logFile = LOG_DIR.resolve(today + ".log");
        }

        public void log(String level, String message) {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            String line = "[" + timestamp + "] [" + level + "] " + message;
            System.out.println(line);
            try (BufferedWriter writer = Files.newBufferedWriter(logFile, StandardOpenOption.CREATE, StandardOpenOption.APPEND)) {
                writer.write(line);
                writer.newLine();
            } catch (IOException e) {
                System.err.println("Failed to write to log file: " + e.getMessage());
            }
        }

        public void info(String msg) { log("INFO", msg); }
        public void warn(String msg) { log("WARN", msg); }
        public void error(String msg) { log("ERROR", msg); }
    }

    public static class DatabaseMaintainer {
        private Logger logger;
        private Path stateFile;
        private int retentionDays = 3; // 3 Tage Backup-Aufbewahrung

        public DatabaseMaintainer() {
            this.logger = new Logger();
            this.stateFile = DB_DIR.resolve("maintainer_state.json");
        }

        public Map<String, Object> loadState() {
            if (Files.exists(stateFile)) {
                try {
                    String content = new String(Files.readAllBytes(stateFile));
                    @SuppressWarnings("unchecked")
                    Map<String, Object> state = (Map<String, Object>) new com.google.gson.Gson().fromJson(content, Map.class);
                    return state != null ? state : getDefaultState();
                } catch (Exception e) {
                    logger.warn("Failed to load state: " + e.getMessage());
                }
            }
            return getDefaultState();
        }

        private Map<String, Object> getDefaultState() {
            Map<String, Object> state = new HashMap<>();
            state.put("last_check", null);
            state.put("last_backup", null);
            state.put("last_tree_update", null);
            state.put("file_hashes", new HashMap<>());
            return state;
        }

        public void saveState(Map<String, Object> state) {
            try {
                String json = new com.google.gson.Gson().toJson(state);
                Files.write(stateFile, json.getBytes(), StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            } catch (IOException e) {
                logger.error("Failed to save state: " + e.getMessage());
            }
        }

        public String getFileHash(Path filepath) {
            try {
                MessageDigest md = MessageDigest.getInstance("MD5");
                byte[] data = Files.readAllBytes(filepath);
                byte[] hash = md.digest(data);
                StringBuilder sb = new StringBuilder();
                for (byte b : hash) {
                    sb.append(String.format("%02x", b));
                }
                return sb.toString();
            } catch (Exception e) {
                return null;
            }
        }

        public String runTreeCommand() {
            try {
                ProcessBuilder pb = new ProcessBuilder("tree", "-a", "-L", "8", WORKSPACE.toString());
                Process process = pb.start();
                
                if (!process.waitFor(60, TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                    logger.error("tree command timed out");
                    return null;
                }
                
                if (process.exitValue() == 0) {
                    String output = new String(process.getInputStream().readAllBytes());
                    logger.info("tree -a -L 8 erfolgreich ausgeführt");
                    return output;
                } else {
                    String error = new String(process.getErrorStream().readAllBytes());
                    logger.error("tree command fehlgeschlagen: " + error);
                    return null;
                }
            } catch (Exception e) {
                logger.error("tree command Exception: " + e.getMessage());
                return null;
            }
        }

        public boolean updateTreeFile(String treeOutput) {
            if (treeOutput == null || treeOutput.isEmpty()) {
                return false;
            }

            Path treeFile = IMPORTANT_DIR.resolve("openclaw-tree.txt");
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);

            String header = "# OpenClaw Workspace Tree\n" +
                           "# Generiert: " + timestamp + "\n" +
                           "# Befehl: tree -a -L 8 " + WORKSPACE + "\n" +
                           "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

            try {
                Files.write(treeFile, (header + treeOutput).getBytes(), StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
                logger.info("openclaw-tree.txt aktualisiert: " + treeFile);
                return true;
            } catch (IOException e) {
                logger.error("Fehler beim Schreiben von openclaw-tree.txt: " + e.getMessage());
                return false;
            }
        }

        public List<Map<String, Object>> scanDocumentations() {
            List<Map<String, Object>> docs = new ArrayList<>();
            
            try {
                Files.walk(WORKSPACE)
                     .filter(path -> path.toString().endsWith(".md"))
                     .filter(path -> !path.toString().contains("db/backups"))
                     .filter(path -> !path.toString().contains("node_modules"))
                     .forEach(path -> {
                         try {
                             Map<String, Object> doc = new HashMap<>();
                             doc.put("path", WORKSPACE.relativize(path).toString());
                             doc.put("hash", getFileHash(path));
                             doc.put("mtime", Files.getLastModifiedTime(path).toMillis());
                             docs.add(doc);
                         } catch (IOException e) {
                             logger.warn("Could not process file: " + path);
                         }
                     });
            } catch (IOException e) {
                logger.error("Error scanning documentations: " + e.getMessage());
            }
            
            return docs;
        }

        public Map<String, Object> checkForChanges() {
            Map<String, Object> result = new HashMap<>();
            Map<String, Object> state = loadState();
            @SuppressWarnings("unchecked")
            Map<String, String> fileHashes = (Map<String, String>) state.getOrDefault("file_hashes", new HashMap<>());
            List<Map<String, Object>> currentDocs = scanDocumentations();
            
            List<String> changes = new ArrayList<>();
            Map<String, String> currentHashes = new HashMap<>();
            
            for (Map<String, Object> doc : currentDocs) {
                String path = (String) doc.get("path");
                String hash = (String) doc.get("hash");
                currentHashes.put(path, hash);
                
                if (!fileHashes.containsKey(path)) {
                    changes.add("NEW: " + path);
                } else if (!fileHashes.get(path).equals(hash)) {
                    changes.add("CHANGED: " + path);
                }
            }
            
            // Prüfe auf gelöschte Dateien
            for (String oldPath : fileHashes.keySet()) {
                if (!currentHashes.containsKey(oldPath)) {
                    changes.add("DELETED: " + oldPath);
                }
            }
            
            result.put("changes", changes);
            result.put("current_hashes", currentHashes);
            return result;
        }

        public boolean updateDatabases() {
            try {
                ProcessBuilder pb = new ProcessBuilder("python3", WORKSPACE.resolve("scripts/update_docs_db.py").toString());
                Process process = pb.start();
                
                if (!process.waitFor(60, TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                    logger.error("DB update timed out");
                    return false;
                }
                
                if (process.exitValue() == 0) {
                    logger.info("docs.db aktualisiert");
                    return true;
                } else {
                    String error = new String(process.getErrorStream().readAllBytes());
                    logger.error("DB-Update fehlgeschlagen: " + error);
                    return false;
                }
            } catch (Exception e) {
                logger.error("DB-Update Exception: " + e.getMessage());
                return false;
            }
        }

        public boolean updateTreeDbV2() {
            try {
                ProcessBuilder pb = new ProcessBuilder("python3", WORKSPACE.resolve("scripts/tree_indexer_v2.py").toString());
                Process process = pb.start();
                
                if (!process.waitFor(120, TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                    logger.error("Tree-DB v2 timed out");
                    return false;
                }
                
                if (process.exitValue() == 0) {
                    logger.info("tree.db v2 aktualisiert");
                    return true;
                } else {
                    String error = new String(process.getErrorStream().readAllBytes());
                    logger.error("Tree-DB v2 fehlgeschlagen: " + error);
                    return false;
                }
            } catch (Exception e) {
                logger.error("Tree-DB v2 Exception: " + e.getMessage());
                return false;
            }
        }

        public String createBackup() {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm"));
            
            for (String dbName : Arrays.asList("docs.db", "tree.db")) {
                Path source = DB_DIR.resolve(dbName);
                if (Files.exists(source)) {
                    String backupName = timestamp + "_" + dbName + ".bak";
                    Path backupPath = BACKUP_DIR.resolve(backupName);
                    try {
                        Files.copy(source, backupPath, StandardCopyOption.REPLACE_EXISTING);
                        logger.info("Backup erstellt: " + backupName);
                    } catch (IOException e) {
                        logger.error("Failed to create backup: " + e.getMessage());
                    }
                }
            }
            
            return timestamp;
        }

        public void cleanupOldBackups() {
            LocalDateTime cutoff = LocalDateTime.now().minusDays(retentionDays);
            int deleted = 0;
            
            for (String dbName : Arrays.asList("docs.db", "tree.db")) {
                try {
                    DirectoryStream<Path> stream = Files.newDirectoryStream(BACKUP_DIR, "*" + dbName + ".bak");
                    for (Path backup : stream) {
                        try {
                            String fileName = backup.getFileName().toString();
                            String[] parts = fileName.split("_");
                            String dateStr = parts[0];
                            String timeStr = parts[1];
                            LocalDateTime backupTime = LocalDateTime.parse(dateStr + "_" + timeStr, DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm"));
                            
                            if (backupTime.isBefore(cutoff)) {
                                Files.delete(backup);
                                deleted++;
                                logger.info("Altes Backup gelöscht: " + fileName);
                            }
                        } catch (Exception e) {
                            logger.warn("Konnte Backup-Datum nicht parsen: " + backup.getFileName());
                        }
                    }
                } catch (IOException e) {
                    logger.error("Error cleaning up backups: " + e.getMessage());
                }
            }
            
            if (deleted == 0) {
                logger.info("Keine alten Backups zum Löschen");
            } else {
                logger.info(deleted + " alte Backups gelöscht (< 3 Tage)");
            }
        }

        public void runCycle() {
            logger.info("============================================================");
            logger.info("DB MAINTAINER CYCLE START");
            logger.info("============================================================");
            
            Map<String, Object> state = loadState();
            
            // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
            logger.info("Führe tree -a -L 8 aus...");
            String treeOutput = runTreeCommand();
            if (treeOutput != null) {
                updateTreeFile(treeOutput);
                state.put("last_tree_update", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            }
            
            // 2. tree.db aktualisieren (intern v2)
            logger.info("Aktualisiere tree.db v2...");
            updateTreeDbV2();
            
            // 3. Änderungen prüfen
            logger.info("Prüfe auf Dokumentations-Änderungen...");
            Map<String, Object> checkResult = checkForChanges();
            @SuppressWarnings("unchecked")
            List<String> changes = (List<String>) checkResult.get("changes");
            @SuppressWarnings("unchecked")
            Map<String, String> currentHashes = (Map<String, String>) checkResult.get("current_hashes");
            
            if (!changes.isEmpty()) {
                logger.info(changes.size() + " Änderungen gefunden:");
                int count = 0;
                for (String change : changes) {
                    if (count++ < 10) {
                        logger.info("  - " + change);
                    }
                }
                if (changes.size() > 10) {
                    logger.info("  ... und " + (changes.size() - 10) + " weitere");
                }
                
                // 4. docs.db aktualisieren
                logger.info("Aktualisiere docs.db...");
                if (updateDatabases()) {
                    state.put("last_check", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                    state.put("file_hashes", currentHashes);
                }
            } else {
                logger.info("Keine Dokumentations-Änderungen gefunden");
            }
            
            // 5. Prüfe ob Backup fällig (stündlich)
            Object lastBackupObj = state.get("last_backup");
            boolean doBackup;
            
            if (lastBackupObj != null) {
                LocalDateTime lastBackupTime = LocalDateTime.parse((String) lastBackupObj);
                doBackup = LocalDateTime.now().minusHours(1).isAfter(lastBackupTime);
            } else {
                doBackup = true;
            }
            
            if (doBackup) {
                logger.info("Erstelle stündliches Backup...");
                String timestamp = createBackup();
                state.put("last_backup", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                
                // 6. Alte Backups aufräumen (3 Tage Retention)
                logger.info("Räume alte Backups auf (3 Tage Retention)...");
                cleanupOldBackups();
            } else {
                logger.info("Backup nicht nötig (letztes < 1h)");
            }
            
            saveState(state);
            
            logger.info("============================================================");
            logger.info("DB MAINTAINER CYCLE END");
            logger.info("============================================================");
        }
    }

    public static void main(String[] args) {
        DatabaseMaintainer maintainer = new DatabaseMaintainer();
        
        try {
            maintainer.runCycle();
        } catch (Exception e) {
            maintainer.logger.error("CRITICAL ERROR: " + e.getMessage());
            System.exit(1);
        }
    }
}
