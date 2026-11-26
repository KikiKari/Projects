// abstraction-provenance: {"artifact_sha256": "2f04d352ab7ab4d544167fead065ba7482a344cdb7305b1a753716bb5bd511fc", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "java"}
// node_health.py — portiert nach java
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
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
    private static final Path WORKSPACE = Paths.get(System.getProperty("user.home"), ".openclaw", "workspace");
    private static final Path HEALTH_DB = WORKSPACE.resolve("db/health.db");
    private static final Path LOG_FILE = WORKSPACE.resolve("logs/node-health.log");
    
    // Node-Definitionen
    private static final Map<String, Map<String, Object>> NODES = new HashMap<>();
    
    static {
        Map<String, Object> node1 = new HashMap<>();
        node1.put("name", "Node 1");
        node1.put("host", "localhost");
        node1.put("user", "openclaw");
        node1.put("critical", true);
        NODES.put("node1", node1);
        
        Map<String, Object> node2 = new HashMap<>();
        node2.put("name", "Node 2");
        node2.put("host", "10.10.0.2");
        node2.put("user", "root");
        node2.put("ssh_key", "~/.ssh/id_rsa");
        node2.put("ssh_opts", "-o ConnectTimeout=10 -o BatchMode=yes");
        NODES.put("node2", node2);
        
        Map<String, Object> node3 = new HashMap<>();
        node3.put("name", "Node 3");
        node3.put("host", "localhost");
        node3.put("user", "root");
        node3.put("port", 18794);
        node3.put("ssh_opts", "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes");
        node3.put("disk_warning", 85);
        NODES.put("node3", node3);
        
        Map<String, Object> node5 = new HashMap<>();
        node5.put("name", "Redmi");
        node5.put("host", "192.168.1.x");
        node5.put("user", "openclaw");
        node5.put("optional", true);
        NODES.put("node5", node5);
    }
    
    public static void log(String message, String level) {
        /** Logging */
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
        /** Prüft Erreichbarkeit (Timeout seconds) */
        try {
            Process process = new ProcessBuilder("ping", "-c", "1", "-W", String.valueOf(timeout), host).start();
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    @SuppressWarnings("unchecked")
    public static boolean checkSsh(Map<String, Object> nodeConfig) {
        /** Prüft SSH-Verbindung */
        String host = (String) nodeConfig.get("host");
        String user = (String) nodeConfig.getOrDefault("user", "root");
        String sshOpts = (String) nodeConfig.getOrDefault("ssh_opts", "");
        Integer port = (Integer) nodeConfig.get("port");
        
        List<String> cmd = new ArrayList<>();
        cmd.add("ssh");
        
        if (!sshOpts.isEmpty()) {
            cmd.addAll(Arrays.asList(sshOpts.split("\\s+")));
        }
        
        if (port != null) {
            cmd.addAll(Arrays.asList("-p", String.valueOf(port)));
        }
        
        cmd.addAll(Arrays.asList("-o", "ConnectTimeout=10", "-o", "BatchMode=yes",
                                 user + "@" + host, "echo", "\"OK\""));
        
        try {
            Process process = new ProcessBuilder(cmd).start();
            int exitCode = process.waitFor();
            String output = new String(process.getInputStream().readAllBytes());
            return exitCode == 0 && output.contains("OK");
        } catch (Exception e) {
            return false;
        }
    }
    
    @SuppressWarnings("unchecked")
    public static Map<String, Object> getNodeMetrics(Map<String, Object> nodeConfig) {
        /** Holt Metriken via SSH */
        String host = (String) nodeConfig.get("host");
        String user = (String) nodeConfig.getOrDefault("user", "root");
        
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("timestamp", LocalDateTime.now().toString());
        metrics.put("available", false);
        metrics.put("cpu", null);
        metrics.put("ram", null);
        metrics.put("disk", null);
        metrics.put("load", null);
        
        // SSH-Command für alle Metriken
        String cmd = String.format(
            "ssh -o ConnectTimeout=10 %s@%s ' " +
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
            "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\"\\\\,\\\")\"\n" +
            "\n" +
            "# Gateway Status\n" +
            "if command -v openclaw >/dev/null 2>&1; then\n" +
            "    systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"\n" +
            "fi\n" +
            "'",
            user, host
        );
        
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"/bin/sh", "-c", cmd});
            if (process.waitFor(15, TimeUnit.SECONDS)) {
                int exitCode = process.exitValue();
                String output = new String(process.getInputStream().readAllBytes());
                
                if (exitCode == 0) {
                    metrics.put("available", true);
                    
                    for (String line : output.trim().split("\n")) {
                        if (line.contains(":")) {
                            String[] parts = line.split(":", 2);
                            String key = parts[0];
                            String value = parts[1];
                            
                            switch (key) {
                                case "CPU":
                                    metrics.put("cpu", Double.parseDouble(value));
                                    break;
                                case "RAM":
                                    metrics.put("ram", Double.parseDouble(value));
                                    break;
                                case "DISK":
                                    metrics.put("disk", Integer.parseInt(value));
                                    break;
                                case "LOAD":
                                    metrics.put("load", Double.parseDouble(value));
                                    break;
                                case "GATEWAY":
                                    metrics.put("gateway_status", value);
                                    break;
                            }
                        }
                    }
                }
            } else {
                process.destroyForcibly();
                log(String.format("SSH timeout for %s", nodeConfig.get("name")), "WARN");
            }
        } catch (Exception e) {
            log(String.format("Error checking %s: %s", nodeConfig.get("name"), e.getMessage()), "ERROR");
        }
        
        return metrics;
    }
    
    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> checkAlerts(String nodeId, Map<String, Object> nodeConfig, Map<String, Object> metrics) {
        /** Prüft Schwellwerte und generiert Alerts */
        List<Map<String, Object>> alerts = new ArrayList<>();
        
        // Verfügbarkeit
        Boolean available = (Boolean) metrics.get("available");
        if (available != null && !available) {
            Boolean optional = (Boolean) nodeConfig.getOrDefault("optional", false);
            if (!optional) {
                Map<String, Object> alert = new HashMap<>();
                alert.put("level", "CRITICAL");
                alert.put("message", String.format("Node %s nicht erreichbar!", nodeConfig.get("name")));
                alerts.add(alert);
            }
        } else if (available != null && available) {
            // CPU
            Double cpu = (Double) metrics.get("cpu");
            if (cpu != null && cpu > 90) {
                Map<String, Object> alert = new HashMap<>();
                alert.put("level", "WARNING");
                alert.put("message", String.format("Node %s: CPU bei %.1f%%", nodeConfig.get("name"), cpu));
                alerts.add(alert);
            }
            
            // RAM
            Double ram = (Double) metrics.get("ram");
            if (ram != null && ram > 90) {
                Map<String, Object> alert = new HashMap<>();
                alert.put("level", "WARNING");
                alert.put("message", String.format("Node %s: RAM bei %.1f%%", nodeConfig.get("name"), ram));
                alerts.add(alert);
            }
            
            // Disk
            Integer diskWarning = (Integer) nodeConfig.getOrDefault("disk_warning", 85);
            Integer disk = (Integer) metrics.get("disk");
            if (disk != null && disk > diskWarning) {
                String level = disk > 95 ? "CRITICAL" : "WARNING";
                Map<String, Object> alert = new HashMap<>();
                alert.put("level", level);
                alert.put("message", String.format("Node %s: Disk bei %d%%", nodeConfig.get("name"), disk));
                alerts.add(alert);
            }
            
            // Gateway
            Boolean critical = (Boolean) nodeConfig.getOrDefault("critical", false);
            String gatewayStatus = (String) metrics.get("gateway_status");
            if (critical && "inactive".equals(gatewayStatus)) {
                Map<String, Object> alert = new HashMap<>();
                alert.put("level", "CRITICAL");
                alert.put("message", String.format("Node %s: OpenClaw Gateway nicht aktiv!", nodeConfig.get("name")));
                alerts.add(alert);
            }
        }
        
        return alerts;
    }
    
    public static void sendAlert(Map<String, Object> alert) {
        /** Sendet Alert via channel-status-agent */
        try {
            String scriptPath = WORKSPACE.resolve("skills/channel-status-agent/scripts/channel_status.py").toString();
            String messageType = (String) alert.get("level");
            String message = messageType + ": " + (String) alert.get("message");
            
            Process process = new ProcessBuilder("python3", scriptPath, "--type", "alert", "--message", message).start();
            process.waitFor();
            log("Alert sent: " + (String) alert.get("message"));
        } catch (Exception e) {
            log("Failed to send alert: " + e.getMessage(), "ERROR");
        }
    }
    
    @SuppressWarnings("unchecked")
    public static void main(String[] args) {
        /** Hauptfunktion */
        // Simple argument parsing
        String nodeArg = "all";
        String checkArg = "all";
        boolean sendAlerts = false;
        
        for (int i = 0; i < args.length; i++) {
            if ("--node".equals(args[i]) && i + 1 < args.length) {
                nodeArg = args[++i];
            } else if ("--check".equals(args[i]) && i + 1 < args.length) {
                checkArg = args[++i];
            } else if ("--alert".equals(args[i])) {
                sendAlerts = true;
            }
        }
        
        // Nodes bestimmen
        Set<Map.Entry<String, Map<String, Object>>> nodesToCheck;
        if ("all".equals(nodeArg)) {
            nodesToCheck = NODES.entrySet();
        } else {
            if (NODES.containsKey(nodeArg)) {
                nodesToCheck = new HashSet<>();
                nodesToCheck.add(new AbstractMap.SimpleEntry<>(nodeArg, NODES.get(nodeArg)));
            } else {
                log("Unknown node: " + nodeArg, "ERROR");
                System.exit(1);
                return;
            }
        }
        
        // Health-Checks durchführen
        List<Map<String, Object>> allAlerts = new ArrayList<>();
        
        for (Map.Entry<String, Map<String, Object>> entry : nodesToCheck) {
            String nodeId = entry.getKey();
            Map<String, Object> nodeConfig = entry.getValue();
            String nodeName = (String) nodeConfig.get("name");
            
            log(String.format("Checking %s (%s)", nodeName, nodeId));
            
            // Ping
            if ("ping".equals(checkArg) || "all".equals(checkArg)) {
                String host = (String) nodeConfig.get("host");
                if (!"localhost".equals(host)) {
                    boolean pingOk = checkPing(host, 10);
                    log("  Ping: " + (pingOk ? "OK" : "FAILED"));
                }
            }
            
            // SSH
            if ("ssh".equals(checkArg) || "all".equals(checkArg)) {
                boolean sshOk = checkSsh(nodeConfig);
                log("  SSH: " + (sshOk ? "OK" : "FAILED"));
            }
            
            // Metriken
            if ("metrics".equals(checkArg) || "all".equals(checkArg)) {
                Map<String, Object> metrics = getNodeMetrics(nodeConfig);
                Boolean available = (Boolean) metrics.get("available");
                
                if (available != null && available) {
                    Double cpu = (Double) metrics.get("cpu");
                    Double ram = (Double) metrics.get("ram");
                    Integer disk = (Integer) metrics.get("disk");
                    Double load = (Double) metrics.get("load");
                    
                    log("  CPU: " + (cpu != null ? String.format("%.1f%%", cpu) : "N/A"));
                    log("  RAM: " + (ram != null ? String.format("%.1f%%", ram) : "N/A"));
                    log("  Disk: " + (disk != null ? disk + "%" : "N/A"));
                    log("  Load: " + (load != null ? load.toString() : "N/A"));
                } else {
                    log("  Metrics: UNAVAILABLE");
                }
                
                // Alerts prüfen
                List<Map<String, Object>> alerts = checkAlerts(nodeId, nodeConfig, metrics);
                allAlerts.addAll(alerts);
            }
        }
        
        // Alerts senden
        if (sendAlerts && !allAlerts.isEmpty()) {
            log(String.format("\nSending %d alerts...", allAlerts.size()));
            for (Map<String, Object> alert : allAlerts) {
                sendAlert(alert);
            }
        } else if (!allAlerts.isEmpty()) {
            log(String.format("\n%d alerts found (use --alert to send)", allAlerts.size()));
        } else {
            log("\nAll nodes healthy!");
        }
    }
}
