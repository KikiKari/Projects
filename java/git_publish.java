// abstraction-provenance: {"artifact_sha256": "b4f3489fe08b05be38ca7cf56a11a1c0ac6f0d2adb5bb99a50b9fb28cd4be669", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "java"}
// git_publish.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Git Publish Agent - Automatisierte Skill-Veröffentlichung
 */
public class GitPublishAgent {
    
    private static final Path SKILLS_DIR = Paths.get(System.getProperty("user.home"), ".openclaw", "workspace", "skills");
    
    /**
     * Commit skill changes.
     */
    public static boolean gitCommit(Path skillPath, String message) {
        try {
            if (message == null || message.isEmpty()) {
                String timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                message = "[skill] Auto-update " + skillPath.getFileName().toString() + " - " + timestamp;
            }
            
            // git add
            ProcessBuilder addProcess = new ProcessBuilder("git", "add", skillPath.toString());
            addProcess.directory(SKILLS_DIR.getParent().toFile());
            Process addResult = addProcess.start();
            addResult.waitFor();
            
            // git commit
            ProcessBuilder commitProcess = new ProcessBuilder("git", "commit", "-m", message);
            commitProcess.directory(SKILLS_DIR.getParent().toFile());
            Process commitResult = commitProcess.start();
            commitResult.waitFor();
            
            return commitResult.exitValue() == 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Publish to ClawHub.
     */
    public static class ClawHubResult {
        public boolean success;
        public String output;
        
        public ClawHubResult(boolean success, String output) {
            this.success = success;
            this.output = output;
        }
    }
    
    public static ClawHubResult clawhubPublish(String skillName) {
        try {
            Path skillPath = SKILLS_DIR.resolve(skillName);
            ProcessBuilder process = new ProcessBuilder(
                "clawhub", "publish", skillPath.toString(),
                "--slug", skillName,
                "--version", "1.0.0"
            );
            Process result = process.start();
            result.waitFor();
            
            String output = readProcessOutput(result);
            return new ClawHubResult(result.exitValue() == 0, output);
        } catch (Exception e) {
            return new ClawHubResult(false, e.getMessage());
        }
    }
    
    /**
     * Publish all changed skills with rate limiting.
     */
    public static void batchPublish() {
        try {
            // Check git status
            ProcessBuilder process = new ProcessBuilder("git", "status", "--short", SKILLS_DIR.toString());
            Process result = process.start();
            result.waitFor();
            
            List<String> changed = new ArrayList<>();
            String output = readProcessOutput(result);
            
            for (String line : output.split("\n")) {
                line = line.trim();
                if (!line.isEmpty() && line.contains("skills/")) {
                    String[] parts = line.split("skills/");
                    if (parts.length > 1) {
                        String skill = parts[1].split("/")[0];
                        if (!changed.contains(skill)) {
                            changed.add(skill);
                        }
                    }
                }
            }
            
            System.out.println("Changed skills: " + changed);
            
            // Publish with delay
            int count = Math.min(changed.size(), 5); // Max 5 per batch
            for (int i = 0; i < count; i++) {
                String skill = changed.get(i);
                if (i > 0) {
                    System.out.println("Waiting 15min for rate limit...");
                    // In real: Thread.sleep(900000);
                }
                
                System.out.println("Publishing " + skill + "...");
                boolean commitOk = gitCommit(SKILLS_DIR.resolve(skill), null);
                if (commitOk) {
                    ClawHubResult pubResult = clawhubPublish(skill);
                    System.out.println("  " + (pubResult.success ? "✓" : "✗") + " " + pubResult.output);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private static String readProcessOutput(Process process) throws IOException {
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }
        return output.toString();
    }
    
    public static void main(String[] args) {
        // Simple argument parsing
        String skill = null;
        boolean publishAll = false;
        boolean noPublish = false;
        String message = null;
        
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--skill":
                    if (i + 1 < args.length) {
                        skill = args[++i];
                    }
                    break;
                case "--all":
                    publishAll = true;
                    break;
                case "--no-publish":
                    noPublish = true;
                    break;
                case "--message":
                    if (i + 1 < args.length) {
                        message = args[++i];
                    }
                    break;
            }
        }
        
        if (skill != null) {
            Path skillPath = SKILLS_DIR.resolve(skill);
            if (noPublish) {
                gitCommit(skillPath, message);
            } else {
                gitCommit(skillPath, message);
                clawhubPublish(skill);
            }
        } else if (publishAll) {
            batchPublish();
        } else {
            System.out.println("Use --skill <name> or --all");
        }
    }
}
