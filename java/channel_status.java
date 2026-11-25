// abstraction-provenance: {"artifact_sha256": "d6a39d871a04b46c42dc8b01550d4e588e129db9f72c4138cfecdcd433ab55fe", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "java"}
// channel_status.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Channel Status Agent - Automatische Status-Updates
 */
public class ChannelStatusAgent {
    
    // Konfiguration
    private static final Path WORKSPACE = Paths.get(System.getProperty("user.home"), ".openclaw", "workspace");
    private static final Path LOGS_DB = WORKSPACE.resolve("db/logs.db");
    private static final Path CONFIG_FILE = WORKSPACE.resolve("config/channel-status.json");
    private static final Path LOG_FILE = WORKSPACE.resolve("logs/channel-status.log");
    
    public static void main(String[] args) {
        try {
            // Ensure log directory exists
            Files.createDirectories(LOG_FILE.getParent());
            
            String type = null;
            String message = null;
            String channel = "-1002381931352";
            boolean dryRun = false;
            
            // Simple argument parsing
            for (int i = 0; i < args.length; i++) {
                switch (args[i]) {
                    case "--type":
                        if (i + 1 < args.length) type = args[++i];
                        break;
                    case "--message":
                        if (i + 1 < args.length) message = args[++i];
                        break;
                    case "--channel":
                        if (i + 1 < args.length) channel = args[++i];
                        break;
                    case "--dry-run":
                        dryRun = true;
                        break;
                }
            }
            
            if (type == null) {
                System.err.println("Error: --type is required");
                System.exit(1);
                return;
            }
            
            log("Starting " + type + " status update");
            
            // Status sammeln
            Map<String, Object> status = getSystemStatus();
            
            // Message formatieren
            String formattedMessage;
            switch (type) {
                case "daily":
                    formattedMessage = formatDailyStatus(status);
                    break;
                case "weekly":
                    formattedMessage = formatWeeklyStatus(status);
                    break;
                case "alert":
                    formattedMessage = "🚨 **ALERT**\n" + (message != null ? message : "Manual alert");
                    break;
                default:
                    log("Unknown type: " + type, "ERROR");
                    return;
            }
            
            // Senden oder Dry-Run
            if (dryRun) {
                System.out.println("\n--- DRY RUN ---");
                System.out.println(formattedMessage);
                System.out.println("--- END ---");
            } else {
                sendToChannel(formattedMessage, "telegram", channel);
            }
            
            log("Status update completed");
            
        } catch (Exception e) {
            log("Fatal error: " + e.getMessage(), "ERROR");
            e.printStackTrace();
        }
    }
    
    private static void log(String message) {
        log(message, "INFO");
    }
    
    private static void log(String message, String level) {
        try {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            String entry = String.format("[%s] [%s] %s", timestamp, level, message);
            System.out.println(entry);
            Files.write(LOG_FILE, (entry + "\n").getBytes(), StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            System.err.println("Failed to write to log: " + e.getMessage());
        }
    }
    
    @SuppressWarnings("unchecked")
    private static Map<String, Object> getSystemStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("timestamp", LocalDateTime.now().toString());
        
        // Node-Status (vereinfacht)
        Map<String, Map<String, String>> nodes = new HashMap<>();
        Map<String, String> node1 = new HashMap<>();
        node1.put("name", "Gateway");
        node1.put("status", "online");
        nodes.put("node1", node1);
        
        Map<String, String> node2 = new HashMap<>();
        node2.put("name", "Worker");
        node2.put("status", "online");
        nodes.put("node2", node2);
        
        Map<String, String> node3 = new HashMap<>();
        node3.put("name", "Relay");
        node3.put("status", "offline");
        node3.put("reason", "disk full");
        nodes.put("node3", node3);
        
        Map<String, String> node5 = new HashMap<>();
        node5.put("name", "Redmi");
        node5.put("status", "intermittent");
        nodes.put("node5", node5);
        
        Map<String, String> node7 = new HashMap<>();
        node7.put("name", "Docker");
        node7.put("status", "planned");
        nodes.put("node7", node7);
        
        status.put("nodes", nodes);
        
        Map<String, Object> agents = new HashMap<>();
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"crontab", "-l"});
            process.waitFor(10, TimeUnit.SECONDS);
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            long count = reader.lines().filter(line -> !line.trim().isEmpty() && !line.startsWith("#")).count();
            agents.put("active_crons", count);
        } catch (Exception e) {
            agents.put("active_crons", "unknown");
        }
        status.put("agents", agents);
        
        Map<String, String> system = new HashMap<>();
        try {
            // Disk usage
            Process dfProcess = Runtime.getRuntime().exec(new String[]{"df", "-h", "/"});
            dfProcess.waitFor(10, TimeUnit.SECONDS);
            BufferedReader dfReader = new BufferedReader(new InputStreamReader(dfProcess.getInputStream()));
            String dfLine;
            while ((dfLine = dfReader.readLine()) != null) {
                if (dfLine.contains("/") && dfLine.contains("%")) {
                    String[] parts = dfLine.trim().split("\\s+");
                    if (parts.length >= 5) {
                        system.put("disk_used", parts[4]);
                        break;
                    }
                }
            }
            
            // RAM usage
            Process freeProcess = Runtime.getRuntime().exec(new String[]{"free", "-h"});
            freeProcess.waitFor(10, TimeUnit.SECONDS);
            BufferedReader freeReader = new BufferedReader(new InputStreamReader(freeProcess.getInputStream()));
            String freeLine;
            while ((freeLine = freeReader.readLine()) != null) {
                if (freeLine.contains("Mem:")) {
                    String[] parts = freeLine.trim().split("\\s+");
                    if (parts.length >= 3) {
                        system.put("ram_total", parts[1]);
                        system.put("ram_used", parts[2]);
                        break;
                    }
                }
            }
        } catch (Exception e) {
            // Ignore exceptions
        }
        status.put("system", system);
        
        return status;
    }
    
    @SuppressWarnings("unchecked")
    private static String formatDailyStatus(Map<String, Object> status) {
        Map<String, Map<String, String>> nodes = (Map<String, Map<String, String>>) status.get("nodes");
        long online = nodes.values().stream()
                .map(node -> node.get("status"))
                .filter(s -> "online".equals(s))
                .count();
        
        StringBuilder message = new StringBuilder();
        message.append("📊 **Täglicher Status-Report**\n");
        message.append("🗓️ ").append(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"))).append("\n\n");
        message.append("**🖥️ Nodes (").append(online).append("/5 online):**\n");
        
        for (Map.Entry<String, Map<String, String>> entry : nodes.entrySet()) {
            Map<String, String> info = entry.getValue();
            String statusStr = info.get("status");
            String emoji;
            switch (statusStr) {
                case "online":
                    emoji = "🟢";
                    break;
                case "offline":
                    emoji = "🔴";
                    break;
                default:
                    emoji = "🟡";
                    break;
            }
            message.append(emoji).append(" ").append(info.get("name")).append(": ").append(statusStr);
            if (info.containsKey("reason")) {
                message.append(" (").append(info.get("reason")).append(")");
            }
            message.append("\n");
        }
        
        message.append("\n**🤖 Agents:**\n");
        message.append("Aktive Cron-Jobs: ").append(((Map<String, Object>) status.get("agents")).get("active_crons")).append("\n");
        
        Map<String, String> system = (Map<String, String>) status.get("system");
        if (system.containsKey("disk_used")) {
            message.append("\n**💾 System:**\n");
            message.append("Disk: ").append(system.get("disk_used")).append(" belegt\n");
            message.append("RAM: ").append(system.get("ram_used")).append(" / ").append(system.get("ram_total")).append("\n");
        }
        
        return message.toString();
    }
    
    private static String formatWeeklyStatus(Map<String, Object> status) {
        return "📈 **Wöchentlicher Report**\n" +
               "📅 Woche " + LocalDate.now().format(DateTimeFormatter.ofPattern("ww")) + " - " + Year.now() + "\n\n" +
               "**Zusammenfassung:**\n" +
               "- 5 aktive Sub-Agents\n" +
               "- 11 Skills synchronisiert\n" +
               "- 3 neue Features implementiert\n\n" +
               "**Top-Ereignisse:**\n" +
               "1. ClawHub-Git Sync implementiert ✅\n" +
               "2. Node 3 Disk voll (95%) ⚠️\n" +
               "3. Channel-Status-Agent aktiviert 🆕\n\n" +
               "**Geplante Wartungen:**\n" +
               "- Node 3: Disk-Cleanup erforderlich\n" +
               "- Node 7: Docker-Setup ausstehend\n";
    }
    
    private static boolean sendToChannel(String message, String channelType, String channelId) {
        List<String> cmd;
        if ("telegram".equals(channelType)) {
            cmd = Arrays.asList("openclaw", "message", "send", "--target", channelId, "--message", message);
        } else {
            log("Channel type " + channelType + " not implemented", "WARN");
            return false;
        }
        
        try {
            ProcessBuilder pb = new ProcessBuilder(cmd);
            Process process = pb.start();
            process.waitFor(30, TimeUnit.SECONDS);
            
            if (process.exitValue() == 0) {
                log("Message sent to " + channelType + " " + channelId);
                return true;
            } else {
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
                StringBuilder error = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    error.append(line).append("\n");
                }
                log("Failed to send: " + error.toString(), "ERROR");
                return false;
            }
        } catch (Exception e) {
            log("Send error: " + e.getMessage(), "ERROR");
            return false;
        }
    }
}
