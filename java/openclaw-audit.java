// abstraction-provenance: {"artifact_sha256": "b59aaae741c7fc1b8e26d9e667a89823c04c5a4d990a19dab79a820c4963227b", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "java"}
// openclaw-audit.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class OpenClawAudit {
    private static final String SCRIPT_NAME = "openclaw-audit";
    
    public static void main(String[] args) {
        try {
            Path scriptDir = Paths.get("").toAbsolutePath();
            String dateStamp = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            Path outFile = scriptDir.resolve(SCRIPT_NAME + "-" + dateStamp + ".log");
            
            List<String> ocCmd = Arrays.asList("openclaw", "--no-color");
            
            // Write header
            try (BufferedWriter writer = Files.newBufferedWriter(outFile, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)) {
                writer.write("================================================================");
                writer.newLine();
                writer.write("OpenClaw audit run");
                writer.newLine();
                writer.write("Started:  " + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                writer.newLine();
                writer.write("Host:     " + getHostName());
                writer.newLine();
                writer.write("User:     " + System.getProperty("user.name"));
                writer.newLine();
                writer.write("Version:  " + getVersion());
                writer.newLine();
                writer.write("Output:   " + outFile.toAbsolutePath());
                writer.newLine();
                writer.write("================================================================");
                writer.newLine();
            }
            
            // Run all commands
            runCmd(outFile, "tasks audit --severity error", concat(ocCmd, Arrays.asList("tasks", "audit", "--severity", "error")));
            runCmd(outFile, "secrets audit", concat(ocCmd, Arrays.asList("secrets", "audit")));
            runCmd(outFile, "security audit", concat(ocCmd, Arrays.asList("security", "audit")));
            runCmd(outFile, "plugins doctor", concat(ocCmd, Arrays.asList("plugins", "doctor")));
            runCmd(outFile, "plugins deps", concat(ocCmd, Arrays.asList("plugins", "deps")));
            runCmd(outFile, "plugins registry", concat(ocCmd, Arrays.asList("plugins", "registry")));
            runCmd(outFile, "skills check", concat(ocCmd, Arrays.asList("skills", "check")));
            runCmd(outFile, "hooks check", concat(ocCmd, Arrays.asList("hooks", "check")));
            runCmd(outFile, "gateway status --deep", concat(ocCmd, Arrays.asList("gateway", "status", "--deep")));
            runCmd(outFile, "channels status --probe", concat(ocCmd, Arrays.asList("channels", "status", "--probe")));
            runCmd(outFile, "memory status --deep", concat(ocCmd, Arrays.asList("memory", "status", "--deep")));
            runCmd(outFile, "sessions --all-agents", concat(ocCmd, Arrays.asList("sessions", "--all-agents")));
            runCmd(outFile, "tasks list", concat(ocCmd, Arrays.asList("tasks", "list")));
            runCmd(outFile, "cron list", concat(ocCmd, Arrays.asList("cron", "list")));
            
            // Write footer
            try (BufferedWriter writer = Files.newBufferedWriter(outFile, StandardOpenOption.APPEND)) {
                writer.newLine();
                writer.write("================================================================");
                writer.newLine();
                writer.write("Audit complete: " + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                writer.newLine();
                writer.write("================================================================");
                writer.newLine();
            }
            
            System.out.println("Audit complete. Output: " + outFile.toAbsolutePath());
            
        } catch (Exception e) {
            System.err.println("Error running audit: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private static void runCmd(Path outFile, String title, List<String> command) {
        try (BufferedWriter writer = Files.newBufferedWriter(outFile, StandardOpenOption.APPEND)) {
            writer.newLine();
            writer.write("----------------------------------------------------------------");
            writer.newLine();
            writer.write("### " + title);
            writer.newLine();
            writer.write("### $ " + String.join(" ", command));
            writer.newLine();
            writer.write("### " + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            writer.newLine();
            writer.write("----------------------------------------------------------------");
            writer.newLine();
            
            ProcessBuilder pb = new ProcessBuilder(command);
            Process process = pb.start();
            
            // Capture both stdout and stderr
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            
            String line;
            while ((line = reader.readLine()) != null) {
                writer.write(line);
                writer.newLine();
            }
            
            while ((line = errorReader.readLine()) != null) {
                writer.write(line);
                writer.newLine();
            }
            
            int exitCode = process.waitFor();
            writer.write("[exit: " + exitCode + "]");
            writer.newLine();
            
        } catch (Exception e) {
            try (BufferedWriter writer = Files.newBufferedWriter(outFile, StandardOpenOption.APPEND)) {
                writer.write("Error executing command: " + e.getMessage());
                writer.newLine();
                writer.write("[exit: 1]");
                writer.newLine();
            } catch (IOException ioException) {
                ioException.printStackTrace();
            }
        }
    }
    
    private static String getHostName() {
        try {
            return java.net.InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "unknown";
        }
    }
    
    private static String getVersion() {
        try {
            Process process = new ProcessBuilder("openclaw", "--version").start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String version = reader.readLine();
            process.waitFor();
            return version != null ? version : "unknown";
        } catch (Exception e) {
            return "unknown";
        }
    }
    
    private static <T> List<T> concat(List<T> list1, List<T> list2) {
        List<T> result = new ArrayList<>(list1);
        result.addAll(list2);
        return result;
    }
}
