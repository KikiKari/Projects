// abstraction-provenance: {"artifact_sha256": "c79c81f51bb5e2d9d6ae2a5f64d841c4492b52b984001f24f02c590d330d0fac", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "java"}
// node_health.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Node Health Monitor - Multi-Node Gesundheitsüberwachung
 */
public class NodeHealthMonitor {
    
    // Konfiguration
    private static final Path WORKSPACE = Paths.get("/home/openclaw/.openclaw/workspace");
    private static final Path HEALTH_DB = WORKSPACE.resolve("db/health.db");
    private static final Path LOG_FILE = WORKSPACE.resolve("logs/node-health.log");
    
    // Node-Definitionen
    private static final Map<String, NodeConfig> NODES = new HashMap<>();
    
    static {
        NODES.put("node1", new NodeConfig("Gateway", "localhost", "openclaw", true, false, null, 85));
        NODES.put("node2", new NodeConfig("Worker", "100.92.155.34", "root", false, false, "~/.ssh/id_rsa", 85));
        NODES.put("node3", new NodeConfig("Relay", "185.242.xxx.xxx", "root", false, false, null, 85));
        NODES.put("node5", new NodeConfig("Redmi", "192.168.1.x", "openclaw", false, true, null, 85));
    }
    
    private static class NodeConfig {
        String name;
        String host;
        String user;
        boolean critical;
        boolean optional;
        String sshKey;
        Integer diskWarning;
        
        NodeConfig(String name, String host, String user, boolean critical, boolean optional, String sshKey, Integer diskWarning) {
            this.name = name;
            this.host = host;
            this.user = user;
            this.critical = critical;
            this.optional = optional;
            this.sshKey = sshKey;
            this.diskWarning = diskWarning;
        }
    }
    
    private static class Metrics {
        String timestamp;
        boolean available;
        Double cpu;
        Double ram;
        Integer disk;
        Double load;
        String gatewayStatus;
        
        Metrics() {
            this.timestamp = LocalDateTime.now().toString();
            this.available = false;
        }
    }
    
    private static class Alert {
        String level;
        String message;
        
        Alert(String level, String message) {
            this.level = level;
            this.message = message;
        }
    }
    
    public static void log(String message, String level) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String entry = String.format("[%s] [%s] %s", timestamp, level, message);
        System.out.println(entry);
        
        try {
            Files.createDirectories(LOG_FILE.getParent());
            Files.write(LOG_FILE, (entry + "\n").getBytes(), StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            System.err.println("Failed to write log: " + e.getMessage());
        }
    }
    
    public static boolean checkPing(String host, int timeout) {
        try {
            Process process = new ProcessBuilder("ping", "-c", "1", "-W", String.valueOf(timeout), host).start();
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    public static boolean checkSSH(NodeConfig nodeConfig) {
        String host = nodeConfig.host;
        String user = nodeConfig.user != null ? nodeConfig.user : "root";
        
        try {
            Process process = new ProcessBuilder("ssh", "-o", "ConnectTimeout=10", "-o", "BatchMode=yes",
                    user + "@" + host, "echo \"OK\"").start();
            int result = process.waitFor();
            
            if (result == 0) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.contains("OK")) {
                        return true;
                    }
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    public static Metrics getNodeMetrics(NodeConfig nodeConfig) {
        Metrics metrics = new Metrics();
        String host = nodeConfig.host;
        String user = nodeConfig.user != null ? nodeConfig.user : "root";
        
        String cmd = String.format(
            "ssh -o ConnectTimeout=10 %s@%s '" +
            "# CPU\n" +
            "echo \"CPU:$(top -bn1 | grep \\\"Cpu(s)\\\" | awk \\\"{print \\\\\\$2}\\\" | cut -d\\\"%%\\\" -f1)\"\n" +
            "\n" +
            "# RAM\n" +
            "echo \"RAM:$(free | grep Mem | awk \\\"{print (\\\\\$3/\\\\\$2) * 100.0}\\\")\"\n" +
            "\n" +
            "# Disk\n" +
            "echo \"DISK:$(df -h / | tail -1 | awk \\\"{print \\\\\\$5}\\\" | tr -d \\\"%%\\\")\"\n" +
            "\n" +
            "# Load\n" +
            "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\" ,\\\")\"\n" +
            "\n" +
            "# Gateway Status\n" +
            "if command -v openclaw >/dev/null 2>&1; then\n" +
            "    systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"\n" +
            "fi\n" +
            "'",
            user, host
        );
        
        try {
            Process process = new ProcessBuilder("bash", "-c", cmd).start();
            
            if (!process.waitFor(15, TimeUnit.SECONDS)) {
                process.destroyForcibly();
                log(String.format("SSH timeout for %s", nodeConfig.name), "WARN");
                return metrics;
            }
            
            if (process.exitValue() == 0) {
                metrics.available = true;
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                String line;
                
                while ((line = reader.readLine()) != null) {
                    if (line.contains(":")) {
                        String[] parts = line.split(":", 2);
                        String key = parts[0];
                        String value = parts.length > 1 ? parts[1].trim() : "";
                        
                        switch (key) {
                            case "CPU":
                                if (!value.isEmpty()) metrics.cpu = Double.parseDouble(value);
                                break;
                            case "RAM":
                                if (!value.isEmpty()) metrics.ram = Double.parseDouble(value);
                                break;
                            case "DISK":
                                if (!value.isEmpty()) metrics.disk = Integer.parseInt(value);
                                break;
                            case "LOAD":
                                if (!value.isEmpty()) metrics.load = Double.parseDouble(value);
                                break;
                            case "GATEWAY":
                                metrics.gatewayStatus = value;
                                break;
                        }
                    }
                }
            }
        } catch (Exception e) {
            log(String.format("Error checking %s: %s", nodeConfig.name, e.getMessage()), "ERROR");
        }
        
        return metrics;
    }
    
    public static List<Alert> checkAlerts(String nodeId, NodeConfig nodeConfig, Metrics metrics) {
        List<Alert> alerts = new ArrayList<>();
        
        // Verfügbarkeit
        if (!metrics.available) {
            if (!nodeConfig.optional) {
                alerts.add(new Alert("CRITICAL", String.format("Node %s nicht erreichbar!", nodeConfig.name)));
            }
        } else {
            // CPU
            if (metrics.cpu != null && metrics.cpu > 90) {
                alerts.add(new Alert("WARNING", String.format("Node %s: CPU bei %.1f%%", nodeConfig.name, metrics.cpu)));
            }
            
            // RAM
            if (metrics.ram != null && metrics.ram > 90) {
                alerts.add(new Alert("WARNING", String.format("Node %s: RAM bei %.1f%%", nodeConfig.name, metrics.ram)));
            }
            
            // Disk
            int diskThreshold = nodeConfig.diskWarning != null ? nodeConfig.diskWarning : 85;
            if (metrics.disk != null && metrics.disk > diskThreshold) {
                String level = metrics.disk > 95 ? "CRITICAL" : "WARNING";
                alerts.add(new Alert(level, String.format("Node %s: Disk bei %d%%", nodeConfig.name, metrics.disk)));
            }
            
            // Gateway
            if (nodeConfig.critical && "inactive".equals(metrics.gatewayStatus)) {
                alerts.add(new Alert("CRITICAL", String.format("Node %s: OpenClaw Gateway nicht aktiv!", nodeConfig.name)));
            }
        }
        
        return alerts;
    }
    
    public static void sendAlert(Alert alert) {
        try {
            Process process = new ProcessBuilder(
                "python3",
                WORKSPACE.resolve("skills/channel-status-agent/scripts/channel_status.py").toString(),
                "--type", "alert",
                "--message", String.format("%s: %s", alert.level, alert.message)
            ).start();
            
            process.waitFor();
            log(String.format("Alert sent: %s", alert.message));
        } catch (Exception e) {
            log(String.format("Failed to send alert: %s", e.getMessage()), "ERROR");
        }
    }
    
    public static void main(String[] args) {
        String nodeArg = "all";
        String checkArg = "all";
        boolean sendAlerts = false;
        
        // Simple argument parsing
        for (int i = 0; i < args.length; i++) {
            if ("--node".equals(args[i]) && i + 1 < args.length) {
                nodeArg = args[++i];
            } else if ("--check".equals(args[i]) && i + 1 < args.length) {
                checkArg = args[++i];
            } else if ("--alert".equals(args[i])) {
                sendAlerts = true;
            }
        }
        
        Set<Map.Entry<String, NodeConfig>> nodesToCheck;
        
        if ("all".equals(nodeArg)) {
            nodesToCheck = NODES.entrySet();
        } else {
            if (NODES.containsKey(nodeArg)) {
                nodesToCheck = Collections.singletonMap(nodeArg, NODES.get(nodeArg)).entrySet();
            } else {
                log(String.format("Unknown node: %s", nodeArg), "ERROR");
                System.exit(1);
                return;
            }
        }
        
        List<Alert> allAlerts = new ArrayList<>();
        
        for (Map.Entry<String, NodeConfig> entry : nodesToCheck) {
            String nodeId = entry.getKey();
            NodeConfig nodeConfig = entry.getValue();
            
            log(String.format("Checking %s (%s)", nodeConfig.name, nodeId));
            
            // Ping
            if ("ping".equals(checkArg) || "all".equals(checkArg)) {
                if (!"localhost".equals(nodeConfig.host)) {
                    boolean pingOk = checkPing(nodeConfig.host, 5);
                    log(String.format("  Ping: %s", pingOk ? "OK" : "FAILED"));
                }
            }
            
            // SSH
            if ("ssh".equals(checkArg) || "all".equals(checkArg)) {
                boolean sshOk = checkSSH(nodeConfig);
                log(String.format("  SSH: %s", sshOk ? "OK" : "FAILED"));
            }
            
            // Metriken
            if ("metrics".equals(checkArg) || "all".equals(checkArg)) {
                Metrics metrics = getNodeMetrics(nodeConfig);
                
                if (metrics.available) {
                    log(String.format("  CPU: %s", metrics.cpu != null ? String.format("%.1f%%", metrics.cpu) : "N/A"));
                    log(String.format("  RAM: %s", metrics.ram != null ? String.format("%.1f%%", metrics.ram) : "N/A"));
                    log(String.format("  Disk: %s", metrics.disk != null ? String.format("%d%%", metrics.disk) : "N/A"));
                    log(String.format("  Load: %s", metrics.load != null ? String.format("%.2f", metrics.load) : "N/A"));
                } else {
                    log("  Metrics: UNAVAILABLE");
                }
                
                // Alerts prüfen
                List<Alert> alerts = checkAlerts(nodeId, nodeConfig, metrics);
                allAlerts.addAll(alerts);
            }
        }
        
        // Alerts senden
        if (sendAlerts && !allAlerts.isEmpty()) {
            log(String.format("\nSending %d alerts...", allAlerts.size()));
            for (Alert alert : allAlerts) {
                sendAlert(alert);
            }
        } else if (!allAlerts.isEmpty()) {
            log(String.format("\n%d alerts found (use --alert to send)", allAlerts.size()));
        } else {
            log("\nAll nodes healthy!");
        }
    }
}
