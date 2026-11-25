// abstraction-provenance: {"artifact_sha256": "ae8eaa381c40f27247560f920a27f18da16a116802af2ab9d6e949b011fd49be", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "java"}
// check_conflicts.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Check Conflicts - Erkennt Sync-Konflikte
 */
public class CheckConflicts {
    
    private static final Path CLAWHUB_DIR = Paths.get("/home/openclaw/.openclaw/workspace/skills");
    private static final Path GIT_DIR = Paths.get("/home/openclaw/.openclaw/workspace/git/skills");
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    
    public static void main(String[] args) {
        checkConflicts();
    }
    
    /**
     * Prüft auf Konflikte zwischen ClawHub und Git
     */
    public static void checkConflicts() {
        List<Map<String, Object>> conflicts = new ArrayList<>();
        
        // Alle Skills die in beiden Orten existieren
        Set<String> commonSkills = new HashSet<>();
        if (Files.exists(CLAWHUB_DIR) && Files.exists(GIT_DIR)) {
            try {
                Set<String> clawhubSkills = Files.list(CLAWHUB_DIR)
                    .filter(Files::isDirectory)
                    .map(path -> path.getFileName().toString())
                    .collect(Collectors.toSet());
                
                Set<String> gitSkills = Files.list(GIT_DIR)
                    .filter(Files::isDirectory)
                    .map(path -> path.getFileName().toString())
                    .collect(Collectors.toSet());
                
                commonSkills.addAll(clawhubSkills);
                commonSkills.retainAll(gitSkills);
            } catch (IOException e) {
                System.err.println("Fehler beim Lesen der Verzeichnisse: " + e.getMessage());
                return;
            }
        }
        
        System.out.println("Prüfe " + commonSkills.size() + " Skills auf Konflikte...\n");
        
        for (String skill : new TreeSet<>(commonSkills)) {
            Path clawhubPath = CLAWHUB_DIR.resolve(skill);
            Path gitPath = GIT_DIR.resolve(skill);
            
            // Alle Dateien vergleichen
            List<Map<String, Object>> skillConflicts = new ArrayList<>();
            
            // ClawHub Dateien
            Map<String, Path> clawhubFiles = new HashMap<>();
            try {
                Files.walk(clawhubPath)
                    .filter(Files::isRegularFile)
                    .filter(path -> !path.toString().contains(".git"))
                    .forEach(path -> {
                        String relPath = clawhubPath.relativize(path).toString();
                        clawhubFiles.put(relPath, path);
                    });
            } catch (IOException e) {
                System.err.println("Fehler beim Durchsuchen von ClawHub für Skill " + skill + ": " + e.getMessage());
                continue;
            }
            
            // Git Dateien
            Map<String, Path> gitFiles = new HashMap<>();
            try {
                Files.walk(gitPath)
                    .filter(Files::isRegularFile)
                    .filter(path -> !path.toString().contains(".git"))
                    .forEach(path -> {
                        String relPath = gitPath.relativize(path).toString();
                        gitFiles.put(relPath, path);
                    });
            } catch (IOException e) {
                System.err.println("Fehler beim Durchsuchen von Git für Skill " + skill + ": " + e.getMessage());
                continue;
            }
            
            // Vergleiche gemeinsame Dateien
            Set<String> commonFiles = new HashSet<>(clawhubFiles.keySet());
            commonFiles.retainAll(gitFiles.keySet());
            
            for (String relPath : commonFiles) {
                Path clawhubFile = clawhubFiles.get(relPath);
                Path gitFile = gitFiles.get(relPath);
                
                try {
                    if (!getFileHash(clawhubFile).equals(getFileHash(gitFile))) {
                        long clawhubModified = Files.getLastModifiedTime(clawhubFile).toMillis();
                        long gitModified = Files.getLastModifiedTime(gitFile).toMillis();
                        
                        Map<String, Object> fileConflict = new HashMap<>();
                        fileConflict.put("file", relPath);
                        fileConflict.put("clawhub_modified", DATE_FORMAT.format(new Date(clawhubModified)));
                        fileConflict.put("git_modified", DATE_FORMAT.format(new Date(gitModified)));
                        fileConflict.put("newer", clawhubModified > gitModified ? "clawhub" : "git");
                        
                        skillConflicts.add(fileConflict);
                    }
                } catch (IOException | NoSuchAlgorithmException e) {
                    System.err.println("Fehler beim Vergleichen der Datei " + relPath + ": " + e.getMessage());
                }
            }
            
            if (!skillConflicts.isEmpty()) {
                Map<String, Object> conflict = new HashMap<>();
                conflict.put("skill", skill);
                conflict.put("conflicts", skillConflicts);
                conflicts.add(conflict);
            }
        }
        
        // Ausgabe
        if (!conflicts.isEmpty()) {
            System.out.println("⚠️  KONFLIKTE GEFUNDEN:");
            System.out.println("=".repeat(80));
            
            for (Map<String, Object> conflict : conflicts) {
                System.out.println("\n📦 Skill: " + conflict.get("skill"));
                System.out.println("-".repeat(40));
                
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> fileConflicts = (List<Map<String, Object>>) conflict.get("conflicts");
                for (Map<String, Object> fileConflict : fileConflicts) {
                    System.out.println("  📄 " + fileConflict.get("file"));
                    System.out.println("     ClawHub: " + fileConflict.get("clawhub_modified"));
                    System.out.println("     Git:     " + fileConflict.get("git_modified"));
                    System.out.println("     Neuer:   " + ((String) fileConflict.get("newer")).toUpperCase());
                    System.out.println();
                }
            }
            
            System.out.println("=".repeat(80));
            System.out.println("Gesamt: " + conflicts.size() + " Skills mit Konflikten");
            System.out.println("\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.");
        } else {
            System.out.println("✅ Keine Konflikte gefunden!");
            System.out.println("Alle gemeinsamen Skills sind synchron.");
        }
    }
    
    /**
     * Berechnet den SHA-256 Hash einer Datei
     */
    private static String getFileHash(Path file) throws IOException, NoSuchAlgorithmException {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream fis = Files.newInputStream(file)) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                digest.update(buffer, 0, bytesRead);
            }
        }
        byte[] hashBytes = digest.digest();
        StringBuilder sb = new StringBuilder();
        for (byte b : hashBytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
