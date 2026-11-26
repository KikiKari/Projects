// abstraction-provenance: {"artifact_sha256": "d667792b20552f16d69e63a9d65a93467871072ac28ff0ac473fe68855db9d63", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "java"}
// dispatch_job.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Function;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */
public class DispatchJob {

    // Node-Konfiguration
    private static final Map<String, Map<String, Object>> NODES = new HashMap<>();
    private static final Map<String, Set<String>> NODE_NAMES = new HashMap<>();

    static {
        Map<String, Object> node1 = new HashMap<>();
        node1.put("always_available", true);
        node1.put("capacity", "medium");
        node1.put("priority", 3);
        node1.put("description", "Gateway");
        NODES.put("node1", node1);

        Map<String, Object> node2 = new HashMap<>();
        node2.put("always_available", false);
        node2.put("capacity", "high");
        node2.put("priority", 1);
        node2.put("description", "ARM Server");
        NODES.put("node2", node2);

        Map<String, Object> node3 = new HashMap<>();
        node3.put("always_available", false);
        node3.put("capacity", "medium");
        node3.put("priority", 4);
        node3.put("description", "AMD Server");
        NODES.put("node3", node3);

        Map<String, Object> node4 = new HashMap<>();
        node4.put("always_available", false);
        node4.put("capacity", "low");
        node4.put("priority", 5);
        node4.put("device", "Redmi Note 11S");
        NODES.put("node4", node4);

        Map<String, Object> node5 = new HashMap<>();
        node5.put("always_available", false);
        node5.put("capacity", "high");
        node5.put("priority", 2);
        node5.put("device", "Lenovo");
        NODES.put("node5", node5);

        Map<String, Object> node6 = new HashMap<>();
        node6.put("always_available", false);
        node6.put("device", "Lenovo (Docker)");
        NODES.put("node6", node6);

        Set<String> node2Names = new HashSet<>(Arrays.asList(
            "openclaw-node2", "arm64-node", "v2202604104722449961", 
            "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"
        ));
        NODE_NAMES.put("node2", node2Names);

        Set<String> node3Names = new HashSet<>(Arrays.asList(
            "openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"
        ));
        NODE_NAMES.put("node3", node3Names);

        Set<String> node4Names = new HashSet<>(Arrays.asList(
            "openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"
        ));
        NODE_NAMES.put("node4", node4Names);

        Set<String> node5Names = new HashSet<>(Arrays.asList(
            "openclaw-node5", "windows node (lenovo-7)"
        ));
        NODE_NAMES.put("node5", node5Names);

        Set<String> node6Names = new HashSet<>(Arrays.asList(
            "openclaw-node6"
        ));
        NODE_NAMES.put("node6", node6Names);
    }

    private static int _job_weight_bytes(Path scriptPath, int targetLangsCount) throws IOException {
        /** Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen. */
        return (int) Files.size(scriptPath) * targetLangsCount;
    }

    private static Map<String, Boolean> fetch_node_status() {
        /** Return mapped OpenClaw connection states; null indicates lookup failure. */
        try {
            ProcessBuilder pb = new ProcessBuilder("openclaw", "nodes", "status", "--json");
            Process process = pb.start();
            
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }
            
            if (process.waitFor(10, TimeUnit.SECONDS)) {
                process.destroyForcibly();
                return null;
            }
            
            ObjectMapper mapper = new ObjectMapper();
            JsonNode payload = mapper.readTree(output.toString());
            
            if (!payload.isObject() || !payload.has("nodes") || !payload.get("nodes").isArray()) {
                return null;
            }
            
            Map<String, Boolean> states = new HashMap<>();
            for (String node : NODE_NAMES.keySet()) {
                states.put(node, false);
            }
            
            for (JsonNode item : payload.get("nodes")) {
                if (!item.isObject()) {
                    continue;
                }
                
                Set<String> names = new HashSet<>();
                if (item.has("displayName")) names.add(item.get("displayName").asText().toLowerCase());
                if (item.has("nodeId")) names.add(item.get("nodeId").asText().toLowerCase());
                if (item.has("remoteIp")) names.add(item.get("remoteIp").asText().toLowerCase());
                
                for (Map.Entry<String, Set<String>> entry : NODE_NAMES.entrySet()) {
                    String node = entry.getKey();
                    Set<String> aliases = entry.getValue();
                    
                    Set<String> intersection = new HashSet<>(names);
                    intersection.retainAll(aliases);
                    
                    if (!intersection.isEmpty() && item.has("connected") && item.get("connected").asBoolean()) {
                        states.put(node, true);
                    }
                }
            }
            
            states.put("node1", true); // successful Gateway status request
            return states;
            
        } catch (Exception e) {
            return null;
        }
    }

    public static class JobDispatcher {
        /** Dispatches jobs to appropriate nodes based on weight */

        public String getJobWeight(Path scriptPath, int targetLangsCount) throws IOException {
            /** Bewertet Job-Gewicht */
            if (!Files.exists(scriptPath)) {
                return "medium";
            }

            int totalWork = _job_weight_bytes(scriptPath, targetLangsCount);

            if (totalWork > 50000) {  // > 50KB
                return "heavy";
            } else if (totalWork > 10000) {  // > 10KB
                return "medium";
            } else {
                return "light";
            }
        }

        public String selectNode(String jobWeight) {
            /** Wählt besten Node basierend auf Job-Gewicht */
            List<String> preferred;
            
            switch (jobWeight) {
                case "heavy":
                    preferred = Arrays.asList("node1", "node2", "node5", "node6");
                    break;
                case "medium":
                    preferred = Arrays.asList("node1", "node2", "node3", "node6");
                    break;
                case "light":
                    preferred = Arrays.asList("node2", "node1", "node3", "node4");
                    break;
                default:
                    throw new IllegalArgumentException("Unknown job weight: " + jobWeight);
            }

            Map<String, Boolean> states = fetch_node_status();
            for (String nodeId : preferred) {
                if (states != null && states.getOrDefault(nodeId, false)) {
                    return nodeId;
                }
            }
            return null; // no verified reachable node
        }

        public boolean checkNodeAvailable(String nodeId) {
            /** Use the live connection state rather than static availability. */
            Map<String, Boolean> states = fetch_node_status();
            return states != null && states.getOrDefault(nodeId, false);
        }

        public String executeTranslation(Map<String, Object> job, Function<Map<String, Object>, Map<String, Object>> transport) {
            return execute_translation(job, transport);
        }

        private boolean _check_mobile_online() {
            /** Check Node4 (Redmi). */
            return checkNodeAvailable("node4");
        }

        public Map<String, Object> dispatch(Path jobScript, List<String> targetLangs,
                                           String sourceText, String sourceLanguage) throws IOException {
            /** Dispatched Job und gibt Info zurück */
            if (targetLangs == null) {
                targetLangs = Arrays.asList("perl5");
            }

            String weight = getJobWeight(jobScript, targetLangs.size());
            String selectedNode = selectNode(weight);
            
            List<Map<String, Object>> translationJobs = new ArrayList<>();
            for (String language : targetLangs) {
                Map<String, Object> job = new HashMap<>();
                job.put("job_id", UUID.randomUUID().toString());
                job.put("source", jobScript.toString());
                job.put("target_language", language);
                job.put("selected_node", selectedNode);
                
                if (sourceText != null) {
                    job.put("source_text", sourceText);
                }
                if (sourceLanguage != null) {
                    job.put("source_language", sourceLanguage);
                }
                translationJobs.add(job);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("job", jobScript.toString());
            result.put("weight", weight);
            result.put("selected_node", selectedNode);
            result.put("target_langs", targetLangs);
            result.put("translation_jobs", translationJobs);
            result.put("status", selectedNode != null ? "selected" : "unavailable");
            
            return result;
        }
    }

    public static String execute_translation(Map<String, Object> job, Function<Map<String, Object>, Map<String, Object>> transport) {
        /** Execute via a supplied transport and verify its result belongs to the job. */
        if (job.get("selected_node") == null || transport == null) {
            throw new RuntimeException("no verified node or authorized translation transport");
        }
        
        Map<String, Object> response = transport.apply(job);
        
        if (response == null) {
            throw new IllegalArgumentException("invalid transport response");
        }
        
        for (String key : Arrays.asList("job_id", "selected_node", "target_language")) {
            if (!Objects.equals(response.get(key), job.get(key))) {
                throw new IllegalArgumentException("transport response does not match job");
            }
        }
        
        String code = (String) response.get("code");
        String status = (String) response.get("status");
        
        if (!"ok".equals(status) || code == null || code.trim().isEmpty()) {
            throw new IllegalArgumentException("translation did not complete with code");
        }
        
        return code;
    }

    public static Map<String, Object> dispatch_abstraction_job(Path jobScript, List<String> targetLangs) throws IOException {
        /** Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag. */
        JobDispatcher dispatcher = new JobDispatcher();
        return dispatcher.dispatch(jobScript, targetLangs, null, null);
    }

    public static void main(String[] args) {
        // Simple argument parsing
        String jobPath = null;
        String langs = "perl5";
        String weight = null;
        boolean execute = false;
        
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--job":
                case "-j":
                    if (i + 1 < args.length) {
                        jobPath = args[++i];
                    }
                    break;
                case "--langs":
                case "-l":
                    if (i + 1 < args.length) {
                        langs = args[++i];
                    }
                    break;
                case "--weight":
                case "-w":
                    if (i + 1 < args.length) {
                        weight = args[++i];
                    }
                    break;
                case "--execute":
                case "-x":
                    execute = true;
                    break;
            }
        }
        
        if (jobPath == null) {
            System.err.println("❌ Job path is required");
            System.exit(1);
            return;
        }
        
        Path jobFile = Paths.get(jobPath);
        if (!Files.exists(jobFile)) {
            System.err.println("❌ Job not found: " + jobFile);
            System.exit(1);
            return;
        }
        
        JobDispatcher dispatcher = new JobDispatcher();
        List<String> targetLangs = Arrays.asList(langs.split(","));
        
        // Determine weight
        String jobWeight;
        try {
            if (weight != null) {
                jobWeight = weight;
            } else {
                jobWeight = dispatcher.getJobWeight(jobFile, targetLangs.size());
            }
        } catch (IOException e) {
            System.err.println("❌ Error determining job weight: " + e.getMessage());
            System.exit(1);
            return;
        }
        
        // Select node
        String selectedNode = dispatcher.selectNode(jobWeight);
        
        // Output
        System.out.println("📦 Job Dispatch Information");
        System.out.println("==================================================");
        System.out.println("Job: " + jobFile);
        try {
            System.out.println("Size: " + Files.size(jobFile) + " bytes");
        } catch (IOException e) {
            System.out.println("Size: unknown");
        }
        System.out.println("Target langs: " + String.join(", ", targetLangs));
        System.out.println("Job weight: " + jobWeight);
        System.out.println("Selected node: " + selectedNode);
        System.out.println("==================================================");
        
        if (execute) {
            System.err.println("\nTranslation dispatch on " + selectedNode + " is not implemented.");
            System.exit(1);
        } else {
            System.out.println("\n💡 To execute: java DispatchJob --job " + jobPath + " --execute");
        }
    }
}
