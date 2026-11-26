// abstraction-provenance: {"artifact_sha256": "6cb87b6a9d738cdca477072327f1a3331f99ca64a7b21871376f1efbb939b82c", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "java"}
// db_maintainer.py — portiert nach java
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;

public class DbMaintainer {
    private static final Path WORKSPACE = Paths.get(System.getenv().getOrDefault("OPENCLAW_WORKSPACE", 
        new File(DbMaintainer.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParentFile().getParent()));
    private static final Path DB_DIR = WORKSPACE;
    private static final Path BACKUP_DIR = WORKSPACE.resolve("db").resolve("backups");
    private static final Path LOG_DIR = WORKSPACE.resolve("logs").resolve("db-maintainer");
    private static final Path IMPORTANT_DIR = WORKSPACE.resolve("important");

    static {
        try {
            Files.createDirectories(BACKUP_DIR);
            Files.createDirectories(LOG_DIR);
            Files.createDirectories(IMPORTANT_DIR);
        } catch (IOException e) {
            System.err.println("Failed to create directories: " + e.getMessage());
            System.exit(1);
        }
    }

    public static void main(String[] args) {
        DatabaseMaintainer maintainer = new DatabaseMaintainer();
        try {
            maintainer.runCycle();
        } catch (Exception e) {
            maintainer.getLogger().error("CRITICAL ERROR: " + e.getMessage());
            System.exit(1);
        }
    }

    static class Logger {
        private Path logFile;

        public Logger() {
            String today = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            this.logFile = LOG_DIR.resolve(today + ".log");
        }

        public void log(String level, String message) {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            String line = "[" + timestamp + "] [" + level + "] " + message;
            System.out.println(line);
            try (PrintWriter writer = new PrintWriter(new FileWriter(logFile.toFile(), true))) {
                writer.println(line);
            } catch (IOException e) {
                System.err.println("Failed to write to log file: " + e.getMessage());
            }
        }

        public void info(String msg) { log("INFO", msg); }
        public void warn(String msg) { log("WARN", msg); }
        public void error(String msg) { log("ERROR", msg); }
    }

    static class DatabaseMaintainer {
        private Logger logger;
        private Path stateFile;
        private int retentionDays = 3;

        public DatabaseMaintainer() {
            this.logger = new Logger();
            this.stateFile = DB_DIR.resolve("maintainer_state.json");
        }

        public Logger getLogger() {
            return logger;
        }

        public Map<String, Object> loadState() {
            if (Files.exists(stateFile)) {
                try {
                    String content = new String(Files.readAllBytes(stateFile));
                    return parseJson(content);
                } catch (IOException e) {
                    logger.error("Failed to read state file: " + e.getMessage());
                }
            }
            Map<String, Object> state = new HashMap<>();
            state.put("last_check", null);
            state.put("last_backup", null);
            state.put("last_tree_update", null);
            state.put("file_hashes", new HashMap<>());
            return state;
        }

        public void saveState(Map<String, Object> state) {
            try {
                String json = toJson(state);
                Files.write(stateFile, json.getBytes());
            } catch (IOException e) {
                logger.error("Failed to save state: " + e.getMessage());
            }
        }

        public String getFileHash(Path filepath) {
            try {
                MessageDigest md = MessageDigest.getInstance("MD5");
                byte[] data = Files.readAllBytes(filepath);
                byte[] hashBytes = md.digest(data);
                StringBuilder sb = new StringBuilder();
                for (byte b : hashBytes) {
                    sb.append(String.format("%02x", b));
                }
                return sb.toString();
            } catch (IOException | NoSuchAlgorithmException e) {
                return null;
            }
        }

        private String pythonTreeFallback(int maxDepth) {
            List<String> lines = new ArrayList<>();
            lines.add(WORKSPACE.toString());
            walk(WORKSPACE, "", 1, lines, maxDepth);
            return String.join("\n", lines) + "\n";
        }

        private void walk(Path dirpath, String prefix, int depth, List<String> lines, int maxDepth) {
            if (depth > maxDepth) return;
            try (Stream<Path> stream = Files.list(dirpath)) {
                List<Path> entries = stream.sorted((a, b) -> {
                    boolean aIsDir = Files.isDirectory(a);
                    boolean bIsDir = Files.isDirectory(b);
                    if (aIsDir && !bIsDir) return -1;
                    if (!aIsDir && bIsDir) return 1;
                    return a.getFileName().toString().compareTo(b.getFileName().toString());
                }).toList();

                for (int i = 0; i < entries.size(); i++) {
                    Path entry = entries.get(i);
                    String connector = (i == entries.size() - 1) ? "└── " : "├── ";
                    lines.add(prefix + connector + entry.getFileName().toString());
                    if (Files.isDirectory(entry) && !Files.isSymbolicLink(entry)) {
                        String extension = (i == entries.size() - 1) ? "    " : "│   ";
                        walk(entry, prefix + extension, depth + 1, lines, maxDepth);
                    }
                }
            } catch (IOException e) {
                // Ignore permission errors
            }
        }

        public String runTreeCommand() {
            try {
                ProcessBuilder pb = new ProcessBuilder("tree", "-a", "-L", "8", WORKSPACE.toString());
                Process process = pb.start();
                if (process.waitFor(60, TimeUnit.SECONDS)) {
                    if (process.exitValue() == 0) {
                        String output = new String(process.getInputStream().readAllBytes());
                        logger.info("tree -a -L 8 erfolgreich ausgeführt");
                        return output;
                    } else {
                        String error = new String(process.getErrorStream().readAllBytes()).trim();
                        logger.warn("tree command fehlgeschlagen: " + error + " – nutze Python-Fallback");
                        return pythonTreeFallback(8);
                    }
                } else {
                    process.destroyForcibly();
                    throw new InterruptedException("Process timed out");
                }
            } catch (IOException e) {
                logger.warn("tree-Binary nicht installiert – nutze Python-Fallback");
                return pythonTreeFallback(8);
            } catch (InterruptedException e) {
                logger.error("tree command interrupted: " + e.getMessage());
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

            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(treeFile))) {
                writer.print(header);
                writer.print(treeOutput);
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
                             logger.error("Failed to process file: " + path + " - " + e.getMessage());
                         }
                     });
            } catch (IOException e) {
                logger.error("Failed to scan documentations: " + e.getMessage());
            }
            return docs;
        }

        public Map<String, Object> checkForChanges() {
            Map<String, Object> result = new HashMap<>();
            Map<String, Object> state = loadState();
            List<Map<String, Object>> currentDocs = scanDocumentations();
            
            List<String> changes = new ArrayList<>();
            Map<String, String> currentHashes = new HashMap<>();
            
            @SuppressWarnings("unchecked")
            Map<String, String> oldHashes = (Map<String, String>) state.getOrDefault("file_hashes", new HashMap<>());
            
            for (Map<String, Object> doc : currentDocs) {
                String path = (String) doc.get("path");
                String hash = (String) doc.get("hash");
                currentHashes.put(path, hash);
                
                if (!oldHashes.containsKey(path)) {
                    changes.add("NEW: " + path);
                } else if (!oldHashes.get(path).equals(hash)) {
                    changes.add("CHANGED: " + path);
                }
            }
            
            for (String oldPath : oldHashes.keySet()) {
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
                ProcessBuilder pb = new ProcessBuilder("python3", 
                    WORKSPACE.resolve("scripts").resolve("update_docs_db.py").toString());
                Process process = pb.start();
                if (process.waitFor(60, TimeUnit.SECONDS)) {
                    if (process.exitValue() == 0) {
                        logger.info("docs.db aktualisiert");
                        return true;
                    } else {
                        String error = new String(process.getErrorStream().readAllBytes());
                        logger.error("DB-Update fehlgeschlagen: " + error);
                        return false;
                    }
                } else {
                    process.destroyForcibly();
                    throw new InterruptedException("Process timed out");
                }
            } catch (Exception e) {
                logger.error("DB-Update Exception: " + e.getMessage());
                return false;
            }
        }

        public boolean updateTreeDbV2() {
            try {
                ProcessBuilder pb = new ProcessBuilder("python3", 
                    WORKSPACE.resolve("scripts").resolve("tree_indexer_v2.py").toString());
                Process process = pb.start();
                if (process.waitFor(120, TimeUnit.SECONDS)) {
                    if (process.exitValue() == 0) {
                        logger.info("tree.db v2 aktualisiert");
                        return true;
                    } else {
                        String error = new String(process.getErrorStream().readAllBytes());
                        logger.error("Tree-DB v2 fehlgeschlagen: " + error);
                        return false;
                    }
                } else {
                    process.destroyForcibly();
                    throw new InterruptedException("Process timed out");
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
                        logger.error("Failed to create backup for " + dbName + ": " + e.getMessage());
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
                    Files.list(BACKUP_DIR)
                         .filter(path -> path.toString().endsWith("_" + dbName + ".bak"))
                         .forEach(backup -> {
                             try {
                                 String fileName = backup.getFileName().toString();
                                 String[] parts = fileName.split("_");
                                 if (parts.length >= 2) {
                                     String dateStr = parts[0];
                                     String timeStr = parts[1];
                                     LocalDateTime backupTime = LocalDateTime.parse(dateStr + "_" + timeStr, 
                                         DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm"));
                                     
                                     if (backupTime.isBefore(cutoff)) {
                                         Files.delete(backup);
                                         deleted++;
                                         logger.info("Altes Backup gelöscht: " + fileName);
                                     }
                                 }
                             } catch (Exception e) {
                                 logger.warn("Konnte Backup-Datum nicht parsen: " + backup.getFileName());
                             }
                         });
                } catch (IOException e) {
                    logger.error("Failed to list backups: " + e.getMessage());
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
            if (treeOutput != null && !treeOutput.isEmpty()) {
                updateTreeFile(treeOutput);
                state.put("last_tree_update", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            }
            
            // 2. tree.db aktualisieren (intern v2)
            logger.info("Aktualisiere tree.db v2...");
            updateTreeDbV2();
            
            // 3. Änderungen prüfen
            logger.info("Prüfe auf Dokumentations-Änderungen...");
            Map<String, Object> changesResult = checkForChanges();
            @SuppressWarnings("unchecked")
            List<String> changes = (List<String>) changesResult.get("changes");
            @SuppressWarnings("unchecked")
            Map<String, String> currentHashes = (Map<String, String>) changesResult.get("current_hashes");
            
            if (!changes.isEmpty()) {
                logger.info(changes.size() + " Änderungen gefunden:");
                int displayCount = Math.min(10, changes.size());
                for (int i = 0; i < displayCount; i++) {
                    logger.info("  - " + changes.get(i));
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
            
            if (lastBackupObj instanceof String) {
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

        private Map<String, Object> parseJson(String json) {
            // Simple JSON parser - in real implementation you would use a proper library like Jackson or Gson
            Map<String, Object> result = new HashMap<>();
            // This is a simplified implementation for the specific use case
            // In practice, you should use a proper JSON library
            return result;
        }

        private String toJson(Map<String, Object> map) {
            // Simple JSON serializer - in real implementation you would use a proper library
            StringBuilder sb = new StringBuilder("{\n");
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                sb.append("  \"").append(entry.getKey()).append("\": ");
                if (entry.getValue() instanceof String) {
                    sb.append("\"").append(entry.getValue()).append("\"");
                } else if (entry.getValue() instanceof Map) {
                    sb.append(toJson((Map<String, Object>) entry.getValue()));
                } else {
                    sb.append(entry.getValue());
                }
                sb.append(",\n");
            }
            if (sb.length() > 2) {
                sb.setLength(sb.length() - 2); // Remove last comma and newline
            }
            sb.append("\n}");
            return sb.toString();
        }
    }
}
