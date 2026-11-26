// abstraction-provenance: {"artifact_sha256": "96174db057d66994f910028b2eaaa3c0aa66939761875d2c9907736f18bc4ce0", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "java"}
// check_nodes.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.*;

/**
 * Node-Status Checker - Prüft Verfügbarkeit aller Nodes
 */
public class CheckNodes {

    // Node-Konfiguration (sollte aus config file geladen werden)
    private static final Map<String, NodeConfig> NODES = new LinkedHashMap<>();

    static {
        NODES.put("node1", new NodeConfig(true, "medium", 2, null, "Gateway-Master"));
        NODES.put("node2", new NodeConfig(true, "medium", 3, null, "Stable Worker"));
        NODES.put("node3", new NodeConfig(false, "medium", 4, null, "Bald verfügbar (nach Reorganisation)"));
        NODES.put("node5", new NodeConfig(false, "low", 5, "Redmi Note 11S", "Mobile (bei Internet verfügbar)"));
        NODES.put("node7", new NodeConfig(true, "high", 1, null, "Docker Hauptarbeitspferd (bald verfügbar)"));
    }

    public static void main(String[] args) {
        String format = "table";
        String saveFile = null;

        // Simple argument parsing
        for (int i = 0; i < args.length; i++) {
            if (("-f".equals(args[i]) || "--format".equals(args[i])) && i + 1 < args.length) {
                format = args[++i];
            } else if (("-s".equals(args[i]) || "--save".equals(args[i])) && i + 1 < args.length) {
                saveFile = args[++i];
            }
        }

        System.out.println("🔍 Prüfe Node-Status...");

        List<NodeStatus> nodesStatus = new ArrayList<>();
        for (String nodeId : new TreeSet<>(NODES.keySet())) {
            System.out.print("  → " + nodeId + "... ");
            NodeStatus status = checkNodeStatus(nodeId);
            nodesStatus.add(status);
            System.out.println(status.isOnline() ? "✓" : "✗");
        }

        // Ausgabe
        if ("table".equals(format)) {
            printTable(nodesStatus);
        } else {
            printJson(nodesStatus);
        }

        // Speichern
        if (saveFile != null) {
            saveToFile(nodesStatus, saveFile);
            System.out.println("\n💾 Gespeichert: " + saveFile);
        }

        // Zusammenfassung
        long onlineCount = nodesStatus.stream().filter(NodeStatus::isOnline).count();
        System.out.println("\n📊 Zusammenfassung: " + onlineCount + "/" + nodesStatus.size() + " Nodes online");
    }

    private static NodeStatus checkNodeStatus(String nodeId) {
        try {
            ProcessBuilder pb = new ProcessBuilder("openclaw", "nodes", "status", nodeId);
            Process process = pb.start();

            // Set timeout
            ExecutorService executor = Executors.newSingleThreadExecutor();
            Future<ProcessResult> future = executor.submit(() -> {
                int exitCode = process.waitFor();
                String stdout = readStream(process.getInputStream());
                return new ProcessResult(exitCode, stdout);
            });

            ProcessResult result = future.get(5, TimeUnit.SECONDS);

            boolean isOnline = result.exitCode == 0 && 
                (result.output.toLowerCase().contains("online") || 
                 result.output.toLowerCase().contains("active"));

            String response = result.output.isEmpty() ? "No response" : 
                             result.output.substring(0, Math.min(100, result.output.length()));

            return new NodeStatus(nodeId, isOnline, NODES.get(nodeId).alwaysAvailable, response);

        } catch (TimeoutException e) {
            return new NodeStatus(nodeId, false, NODES.get(nodeId).alwaysAvailable, "Timeout");
        } catch (Exception e) {
            return new NodeStatus(nodeId, false, NODES.get(nodeId).alwaysAvailable, "Error: " + e.getMessage());
        }
    }

    private static String readStream(InputStream stream) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream))) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
        }
        return sb.toString().trim();
    }

    private static void printTable(List<NodeStatus> nodesStatus) {
        System.out.println("\n" + "=".repeat(90));
        System.out.printf("%-8s %-12s %-12s %-10s %-10s %s%n", 
                         "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung");
        System.out.println("=".repeat(90));

        for (NodeStatus status : nodesStatus) {
            NodeConfig config = NODES.get(status.getId());

            String statusIcon = status.isOnline() ? "🟢 Online" : "🔴 Offline";
            String availIcon = status.isAvailable() ? "✅ Immer" : "📱 Bedingt";
            String capacity = config.capacity != null ? config.capacity : "unknown";
            String priority = String.valueOf(config.priority);
            String device = config.device != null ? config.device : 
                           (config.description != null ? config.description : "");

            System.out.printf("%-8s %-12s %-12s %-10s %-10s %s%n",
                             status.getId(), statusIcon, availIcon, capacity, priority, device);
        }

        System.out.println("=".repeat(90));
        System.out.println("\nGeprüft am: " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
    }

    private static void printJson(List<NodeStatus> nodesStatus) {
        Map<String, Object> output = new HashMap<>();
        output.put("timestamp", LocalDateTime.now().toString());

        Map<String, Map<String, Object>> nodesMap = new HashMap<>();
        for (NodeStatus status : nodesStatus) {
            Map<String, Object> nodeInfo = new HashMap<>();
            nodeInfo.put("status", Map.of(
                "id", status.getId(),
                "online", status.isOnline(),
                "available", status.isAvailable(),
                "response", status.getResponse()
            ));
            nodeInfo.put("config", NODES.get(status.getId()));
            nodesMap.put(status.getId(), nodeInfo);
        }
        output.put("nodes", nodesMap);

        try {
            System.out.println(toJson(output));
        } catch (Exception e) {
            System.err.println("JSON serialization error: " + e.getMessage());
        }
    }

    private static void saveToFile(List<NodeStatus> nodesStatus, String filename) {
        Map<String, Object> output = new HashMap<>();
        output.put("timestamp", LocalDateTime.now().toString());

        Map<String, NodeStatus> statusMap = new HashMap<>();
        for (NodeStatus status : nodesStatus) {
            statusMap.put(status.getId(), status);
        }
        output.put("nodes", statusMap);

        try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(Paths.get(filename)))) {
            writer.println(toJson(output));
        } catch (IOException e) {
            System.err.println("Error saving file: " + e.getMessage());
        }
    }

    // Simple JSON conversion (for basic use case)
    private static String toJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            if (!first) sb.append(",");
            sb.append("\"").append(entry.getKey()).append("\":");
            sb.append(valueToJson(entry.getValue()));
            first = false;
        }
        sb.append("}");
        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    private static String valueToJson(Object value) {
        if (value instanceof String) {
            return "\"" + ((String) value).replace("\"", "\\\"") + "\"";
        } else if (value instanceof Number || value instanceof Boolean) {
            return value.toString();
        } else if (value instanceof Map) {
            return toJson((Map<String, Object>) value);
        } else if (value == null) {
            return "null";
        } else {
            return "\"" + value.toString() + "\"";
        }
    }

    // Data classes
    private static class NodeConfig {
        final boolean alwaysAvailable;
        final String capacity;
        final int priority;
        final String device;
        final String description;

        NodeConfig(boolean alwaysAvailable, String capacity, int priority, String device, String description) {
            this.alwaysAvailable = alwaysAvailable;
            this.capacity = capacity;
            this.priority = priority;
            this.device = device;
            this.description = description;
        }
    }

    private static class NodeStatus {
        private final String id;
        private final boolean online;
        private final boolean available;
        private final String response;

        NodeStatus(String id, boolean online, boolean available, String response) {
            this.id = id;
            this.online = online;
            this.available = available;
            this.response = response;
        }

        public String getId() { return id; }
        public boolean isOnline() { return online; }
        public boolean isAvailable() { return available; }
        public String getResponse() { return response; }
    }

    private static class ProcessResult {
        final int exitCode;
        final String output;

        ProcessResult(int exitCode, String output) {
            this.exitCode = exitCode;
            this.output = output;
        }
    }
}
