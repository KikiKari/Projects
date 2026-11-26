// abstraction-provenance: {"artifact_sha256": "bef31d0e5475345e28f1004ae64329b970dee83a653de78a7288be75c8750b71", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "java"}
// dispatch_job.py — portiert nach java
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */
public class DispatchJob {

    // Node-Konfiguration
    private static final Map<String, Map<String, Object>> NODES = new HashMap<>();

    static {
        Map<String, Object> node1 = new HashMap<>();
        node1.put("always_available", true);
        node1.put("capacity", "medium");
        node1.put("priority", 2);
        NODES.put("node1", node1);

        Map<String, Object> node2 = new HashMap<>();
        node2.put("always_available", true);
        node2.put("capacity", "medium");
        node2.put("priority", 3);
        NODES.put("node2", node2);

        Map<String, Object> node3 = new HashMap<>();
        node3.put("always_available", false);
        node3.put("capacity", "medium");
        node3.put("priority", 4);
        NODES.put("node3", node3);

        Map<String, Object> node5 = new HashMap<>();
        node5.put("always_available", false);
        node5.put("capacity", "low");
        node5.put("priority", 5);
        node5.put("device", "Redmi Note 11S");
        NODES.put("node5", node5);

        Map<String, Object> node7 = new HashMap<>();
        node7.put("always_available", true);
        node7.put("capacity", "high");
        node7.put("priority", 1);
        NODES.put("node7", node7);
    }

    public static class JobDispatcher {
        /** Bewertet Job-Gewicht */
        public String getJobWeight(Path scriptPath, int targetLangsCount) {
            if (!Files.exists(scriptPath)) {
                return "medium";
            }

            try {
                long scriptSize = Files.size(scriptPath);
                long totalWork = scriptSize * targetLangsCount;

                if (totalWork > 50000) {  // > 50KB
                    return "heavy";
                } else if (totalWork > 10000) {  // > 10KB
                    return "medium";
                } else {
                    return "light";
                }
            } catch (IOException e) {
                return "medium";
            }
        }

        /** Wählt besten Node basierend auf Job-Gewicht */
        public String selectNode(String jobWeight) {
            List<String> preferred;

            if ("heavy".equals(jobWeight)) {
                // Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
                preferred = Arrays.asList("node7", "node2", "node1");
            } else if ("medium".equals(jobWeight)) {
                // Mittlere Jobs → Stable Nodes
                preferred = Arrays.asList("node2", "node1", "node7");
            } else {  // light
                // Leichte Jobs → Mobile/verfügbare Nodes
                preferred = Arrays.asList("node5", "node1", "node2");
            }

            // Prüfe Verfügbarkeit
            for (String nodeId : preferred) {
                if (checkNodeAvailable(nodeId)) {
                    return nodeId;
                }
            }

            // Fallback
            return "node1";
        }

        /** Prüft ob Node erreichbar ist */
        public boolean checkNodeAvailable(String nodeId) {
            if (!NODES.containsKey(nodeId)) {
                return false;
            }

            Map<String, Object> node = NODES.get(nodeId);
            Boolean alwaysAvailable = (Boolean) node.getOrDefault("always_available", false);

            // Nicht immer-verfügbare Nodes nur wenn explizit requested
            if (!alwaysAvailable) {
                // Für light-jobs prüfen wir ob online
                if ("node5".equals(nodeId)) {  // Redmi
                    return checkMobileOnline();
                }
                return false;
            }

            // Für immer-verfügbare Nodes: prüfe ob wirklich online
            try {
                Process process = new ProcessBuilder("openclaw", "nodes", "status", nodeId).start();
                process.waitFor();
                return process.exitValue() == 0;
            } catch (Exception e) {
                return alwaysAvailable;
            }
        }

        /** Prüft ob Redmi (Node 5) Internet hat */
        private boolean checkMobileOnline() {
            try {
                Process process = new ProcessBuilder("openclaw", "nodes", "status", "node5").start();
                process.waitFor();
                
                if (process.exitValue() == 0) {
                    BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                    StringBuilder output = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        output.append(line.toLowerCase());
                    }
                    return output.toString().contains("online");
                }
                return false;
            } catch (Exception e) {
                return false;
            }
        }

        /** Dispatched Job und gibt Info zurück */
        public Map<String, Object> dispatch(Path jobScript, List<String> targetLangs) {
            if (targetLangs == null) {
                targetLangs = Arrays.asList("perl5");
            }

            String weight = getJobWeight(jobScript, targetLangs.size());
            String selectedNode = selectNode(weight);

            Map<String, Object> result = new HashMap<>();
            result.put("job", jobScript.toString());
            result.put("weight", weight);
            result.put("selected_node", selectedNode);
            result.put("target_langs", targetLangs);
            result.put("status", "dispatched");

            return result;
        }
    }

    public static void main(String[] args) {
        String jobPathStr = null;
        String langsStr = "perl5";
        String weight = null;
        boolean execute = false;

        // Simple argument parsing
        for (int i = 0; i < args.length; i++) {
            if (("--job".equals(args[i]) || "-j".equals(args[i])) && i + 1 < args.length) {
                jobPathStr = args[++i];
            } else if (("--langs".equals(args[i]) || "-l".equals(args[i])) && i + 1 < args.length) {
                langsStr = args[++i];
            } else if (("--weight".equals(args[i]) || "-w".equals(args[i])) && i + 1 < args.length) {
                weight = args[++i];
            } else if ("--execute".equals(args[i]) || "-x".equals(args[i])) {
                execute = true;
            }
        }

        if (jobPathStr == null) {
            System.err.println("❌ Job path is required");
            System.exit(1);
            return;
        }

        Path jobPath = Paths.get(jobPathStr);
        if (!Files.exists(jobPath)) {
            System.err.println("❌ Job not found: " + jobPath);
            System.exit(1);
            return;
        }

        JobDispatcher dispatcher = new JobDispatcher();
        List<String> targetLangs = Arrays.asList(langsStr.split(","));

        // Determine weight
        if (weight == null) {
            weight = dispatcher.getJobWeight(jobPath, targetLangs.size());
        }

        // Select node
        String selectedNode = dispatcher.selectNode(weight);

        // Output
        System.out.println("📦 Job Dispatch Information");
        System.out.println("==================================================");
        try {
            System.out.println("Job: " + jobPath);
            System.out.println("Size: " + Files.size(jobPath) + " bytes");
        } catch (IOException e) {
            System.out.println("Job: " + jobPath);
            System.out.println("Size: unknown bytes");
        }
        System.out.println("Target langs: " + String.join(", ", targetLangs));
        System.out.println("Job weight: " + weight);
        System.out.println("Selected node: " + selectedNode);
        System.out.println("==================================================");

        if (execute) {
            System.out.println("\n🚀 Executing on " + selectedNode + "...");
            // TODO: Implement remote execution
            System.out.println("(Remote execution not yet implemented)");
        } else {
            System.out.println("\n💡 To execute: java DispatchJob --job " + jobPathStr + " --execute");
        }
    }
}
