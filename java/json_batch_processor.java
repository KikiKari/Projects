// abstraction-provenance: {"artifact_sha256": "925ceca1b4b506d32eca162038bf3ee5fc7e37b401c97941e5a4a1f964cf41a1", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "java"}
// json_batch_processor.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.*;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.core.JsonProcessingException;

/**
 * Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
 */
public class JsonBatchProcessor {
    
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static boolean HAS_JACKSON = true;
    
    /**
     * Ergebnis einer Batch-Verarbeitung.
     */
    public static class BatchResult {
        public int index;
        public String source;
        public boolean success;
        public Object data;
        public String error;
        
        public BatchResult(int index, String source, boolean success, Object data, String error) {
            this.index = index;
            this.source = source;
            this.success = success;
            this.data = data;
            this.error = error;
        }
        
        public Map<String, Object> toMap() {
            Map<String, Object> map = new HashMap<>();
            map.put("index", index);
            map.put("source", source);
            map.put("success", success);
            map.put("data", data);
            map.put("error", error);
            return map;
        }
    }
    
    /**
     * Liest JSON-Lines (NDJSON) Datei Zeile für Zeile.
     *
     * @param filePath Pfad zur .jsonl oder .ndjson Datei
     * @return Geparste JSON-Objekte
     */
    public static List<Object> readJsonl(Path filePath) throws IOException {
        List<Object> results = new ArrayList<>();
        try (BufferedReader reader = Files.newBufferedReader(filePath)) {
            String line;
            int lineNum = 1;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (!line.isEmpty()) {
                    try {
                        Object parsed = objectMapper.readValue(line, Object.class);
                        results.add(parsed);
                    } catch (JsonProcessingException e) {
                        BatchResult errorResult = new BatchResult(
                            lineNum,
                            filePath.toString() + ":" + lineNum,
                            false,
                            null,
                            "JSON decode error: " + e.getMessage()
                        );
                        results.add(errorResult);
                    }
                }
                lineNum++;
            }
        }
        return results;
    }
    
    /**
     * Verarbeitet eine Liste von Inputs parallel.
     *
     * @param inputs Liste der zu verarbeitenden Eingaben (Strings oder Pfade)
     * @param processor Funktion, die (input, index) -> BatchResult zurückgibt
     * @param maxWorkers Anzahl paralleler Worker
     * @return Liste der BatchResult-Objekte
     */
    public static List<BatchResult> processBatch(
        List<?> inputs,
        BatchProcessor processor,
        int maxWorkers
    ) {
        List<BatchResult> results = new ArrayList<>();
        ExecutorService executor = Executors.newFixedThreadPool(maxWorkers);
        List<Future<BatchResult>> futures = new ArrayList<>();
        
        for (int i = 0; i < inputs.size(); i++) {
            final int idx = i;
            final Object inp = inputs.get(i);
            Future<BatchResult> future = executor.submit(() -> processor.process(inp, idx));
            futures.add(future);
        }
        
        for (Future<BatchResult> future : futures) {
            try {
                BatchResult result = future.get();
                results.add(result);
            } catch (InterruptedException | ExecutionException e) {
                // Find the corresponding index
                int idx = futures.indexOf(future);
                results.add(new BatchResult(
                    idx,
                    inputs.get(idx).toString(),
                    false,
                    null,
                    "Unexpected error: " + e.getMessage()
                ));
            }
        }
        
        executor.shutdown();
        
        // Sortiere nach Index
        results.sort(Comparator.comparingInt(r -> r.index));
        return results;
    }
    
    @FunctionalInterface
    public interface BatchProcessor {
        BatchResult process(Object input, int index) throws Exception;
    }
    
    /**
     * Verarbeitet mehrere JSON-Dateien im Batch.
     *
     * @param filePaths Liste der Datei-Pfade
     * @param repair Ob JSON-Reparatur angewendet werden soll
     * @param maxWorkers Parallele Worker
     * @return Liste der BatchResult-Objekte
     */
    public static List<BatchResult> processFileBatch(
        List<Path> filePaths,
        boolean repair,
        int maxWorkers
    ) {
        BatchProcessor processor = (input, idx) -> {
            Path path = (Path) input;
            try {
                String content = Files.readString(path);
                Object data = parseJson(content, repair);
                
                return new BatchResult(
                    idx,
                    path.toString(),
                    true,
                    data,
                    null
                );
            } catch (JsonProcessingError e) {
                return new BatchResult(
                    idx,
                    path.toString(),
                    false,
                    null,
                    e.getMessage()
                );
            } catch (Exception e) {
                return new BatchResult(
                    idx,
                    path.toString(),
                    false,
                    null,
                    e.getClass().getSimpleName() + ": " + e.getMessage()
                );
            }
        };
        
        return processBatch(new ArrayList<>(filePaths), processor, maxWorkers);
    }
    
    /**
     * Verarbeitet eine JSON-Lines Datei.
     *
     * @param filePath Pfad zur .jsonl Datei
     * @param repair Ob Reparatur angewendet werden soll
     * @return Liste der BatchResult-Objekte
     */
    public static List<BatchResult> processJsonlFile(
        Path filePath,
        boolean repair
    ) throws IOException {
        List<BatchResult> results = new ArrayList<>();
        
        try (BufferedReader reader = Files.newBufferedReader(filePath)) {
            String line;
            int lineNum = 1;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (!line.isEmpty()) {
                    try {
                        Object data = parseJson(line, repair);
                        
                        results.add(new BatchResult(
                            lineNum,
                            filePath.toString() + ":" + lineNum,
                            true,
                            data,
                            null
                        ));
                    } catch (JsonProcessingError e) {
                        results.add(new BatchResult(
                            lineNum,
                            filePath.toString() + ":" + lineNum,
                            false,
                            null,
                            e.getMessage()
                        ));
                    }
                }
                lineNum++;
            }
        }
        
        return results;
    }
    
    /**
     * Schreibt BatchResult-Liste als JSON-Lines.
     *
     * @param results Liste der Ergebnisse
     * @param outputPath Ausgabedatei
     * @param onlySuccessful Nur erfolgreiche Ergebnisse schreiben
     */
    public static void writeJsonl(List<BatchResult> results, Path outputPath, boolean onlySuccessful) throws IOException {
        try (BufferedWriter writer = Files.newBufferedWriter(outputPath)) {
            for (BatchResult result : results) {
                if (onlySuccessful && !result.success) {
                    continue;
                }
                writer.write(objectMapper.writeValueAsString(result.toMap()));
                writer.newLine();
            }
        }
    }
    
    public static Object parseJson(String content, boolean repair) throws JsonProcessingError {
        try {
            return objectMapper.readValue(content, Object.class);
        } catch (JsonProcessingException e) {
            if (repair) {
                // Versuche einfache Reparaturen
                String repaired = content.replace("'", "\"");
                try {
                    return objectMapper.readValue(repaired, Object.class);
                } catch (JsonProcessingException e2) {
                    throw new JsonProcessingError("Failed to parse JSON even after repair attempts: " + e2.getMessage());
                }
            } else {
                throw new JsonProcessingError("Failed to parse JSON: " + e.getMessage());
            }
        }
    }
    
    public static class JsonProcessingError extends Exception {
        public JsonProcessingError(String message) {
            super(message);
        }
    }
    
    public static void main(String[] args) {
        // Simple argument parsing
        List<String> inputs = new ArrayList<>();
        boolean jsonlMode = false;
        boolean repair = true;
        int workers = 4;
        String output = null;
        boolean summary = false;
        
        for (int i = 0; i < args.length; i++) {
            String arg = args[i];
            if (arg.equals("--jsonl") || arg.equals("-l")) {
                jsonlMode = true;
            } else if (arg.equals("--repair") || arg.equals("-r")) {
                repair = true;
            } else if (arg.equals("--workers") || arg.equals("-w")) {
                workers = Integer.parseInt(args[++i]);
            } else if (arg.equals("--output") || arg.equals("-o")) {
                output = args[++i];
            } else if (arg.equals("--summary") || arg.equals("-s")) {
                summary = true;
            } else if (!arg.startsWith("-")) {
                inputs.add(arg);
            }
        }
        
        if (inputs.isEmpty()) {
            System.err.println("No input files provided");
            System.exit(1);
            return;
        }
        
        List<BatchResult> allResults = new ArrayList<>();
        
        try {
            if (jsonlMode) {
                // JSON-Lines Modus
                for (String inputPath : inputs) {
                    List<BatchResult> results = processJsonlFile(Paths.get(inputPath), repair);
                    allResults.addAll(results);
                }
            } else {
                // Standard JSON Batch
                List<Path> filePaths = inputs.stream().map(Paths::get).collect(Collectors.toList());
                allResults = processFileBatch(filePaths, repair, workers);
            }
            
            // Ausgabe
            int successful = (int) allResults.stream().filter(r -> r.success).count();
            int failed = allResults.size() - successful;
            
            if (summary) {
                System.out.println("Processed: " + allResults.size());
                System.out.println("Successful: " + successful);
                System.out.println("Failed: " + failed);
            } else {
                for (BatchResult result : allResults) {
                    if (result.success) {
                        System.out.println(objectMapper.writeValueAsString(result.data));
                    } else {
                        System.err.println("ERROR [" + result.source + "]: " + result.error);
                    }
                }
            }
            
            // Optional: JSONL Output
            if (output != null) {
                writeJsonl(allResults, Paths.get(output), false);
                System.err.println("\nResults written to: " + output);
            }
            
            // Exit code
            System.exit(failed == 0 ? 0 : 1);
            
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            System.exit(1);
        }
    }
}
