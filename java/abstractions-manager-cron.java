// abstraction-provenance: {"artifact_sha256": "cacbc273bc2130b8b2ff6150406cdd70db5609b5e2e8bdc1a9f4f54e17b5fd6c", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "java"}
// abstractions-manager-cron.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

public class AbstractionsManagerCron {
    public static void main(String[] args) {
        // Set the PATH environment variable
        System.setProperty("PATH", "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin");

        // Load environment variables from .env file
        Map<String, String> env = new HashMap<>(System.getenv());
        try (BufferedReader reader = new BufferedReader(new FileReader("/home/openclaw/.openclaw/.env"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("#") && line.contains("=")) {
                    String[] parts = line.split("=", 2);
                    env.put(parts[0].trim(), parts[1].trim());
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }

        // Check for required environment variable
        if (!env.containsKey("OPENROUTER_API_KEY")) {
            System.err.println("OPENROUTER_API_KEY fehlt");
            System.exit(1);
        }

        // Set GITHUB_TOKEN environment variable
        String githubToken = env.getOrDefault("GITHUB_TOKEN", env.getOrDefault("GH_TOKEN", env.getOrDefault("GH_ACCESS_TOKEN", "")));
        env.put("GITHUB_TOKEN", githubToken);

        // Try to acquire a lock and execute the Python script
        File lockFile = new File("/home/openclaw/.openclaw/locks/abstractions-manager.lock");
        if (lockFile.exists() && lockFile.isFile()) {
            System.err.println("Lock file exists, exiting.");
            System.exit(1);
        } else {
            try {
                Files.createFile(lockFile.toPath());
                ProcessBuilder processBuilder = new ProcessBuilder(
                        "/usr/bin/python3",
                        "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py"
                );
                processBuilder.environment().putAll(env);
                processBuilder.inheritIO();
                Process process = processBuilder.start();
                int exitCode = process.waitFor();
                System.exit(exitCode);
            } catch (IOException | InterruptedException e) {
                e.printStackTrace();
                System.exit(1);
            } finally {
                lockFile.delete();
            }
        }
    }
}
