// abstraction-provenance: {"artifact_sha256": "2c445a9b074caa607559489115d3d01ead5134fe1cba46fe5dc6965f51e015a7", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "java"}
// extract-tiktok-streamlink.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

public class ExtractTiktokStreamlink {
    private static final ObjectMapper objectMapper = new ObjectMapper();
    
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Username required");
            System.exit(64);
        }
        
        String username = args[0].startsWith("@") ? args[0].substring(1) : args[0];
        String quality = args.length > 1 ? args[1] : "best";
        String jsonFlag = args.length > 2 ? args[2] : "";
        String timestamp = ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT).substring(0, 19) + "Z";
        
        // Validate username
        if (!username.matches("^[A-Za-z0-9._]{1,24}$")) {
            System.err.println("Invalid TikTok username");
            System.exit(64);
        }
        
        // Validate quality
        if (!quality.matches("^(best|worst|original|1080p60|720p60|720p|540p|360p|auto)$")) {
            System.err.println("Invalid stream quality");
            System.exit(64);
        }
        
        try {
            double loadPerCpu = getLoadAverage() / Math.max(1, Runtime.getRuntime().availableProcessors());
            String maxLoadStr = System.getenv("TIKTOK_MAX_LOAD_PER_CPU");
            double maxLoad = maxLoadStr != null ? Double.parseDouble(maxLoadStr) : 1.5;
            
            if (loadPerCpu > maxLoad) {
                emitJson(false, "streamlink", username, "", quality, "", "", 
                        "host overloaded", timestamp, "overloaded");
                System.exit(75);
            }
        } catch (Exception e) {
            emitJson(false, "streamlink", username, "", quality, "", "", 
                    "load check failed", timestamp, "technical_error");
            System.exit(2);
        }
        
        if (!isCommandAvailable("streamlink")) {
            emitJson(false, "streamlink", username, "", quality, "", "", 
                    "streamlink not installed", timestamp, "dependency_missing");
            System.exit(2);
        }
        
        String liveUrl = "https://www.tiktok.com/@" + username + "/live";
        String selector = getQualitySelector(quality);
        
        try {
            ProcessBuilder pb = new ProcessBuilder("streamlink", "--json", liveUrl, selector);
            pb.redirectError(new File("/dev/null"));
            Process process = pb.start();
            
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }
            
            int exitCode = process.waitFor();
            String outputStr = output.toString().trim();
            
            if (exitCode != 0 || outputStr.isEmpty()) {
                pb = new ProcessBuilder("streamlink", "--stream-url", liveUrl, selector);
                pb.redirectError(new File("/dev/null"));
                process = pb.start();
                
                StringBuilder urlOutput = new StringBuilder();
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        urlOutput.append(line).append("\n");
                    }
                }
                
                exitCode = process.waitFor();
                String url = urlOutput.toString().trim();
                
                if (exitCode != 0 || url.isEmpty()) {
                    emitJson(false, "streamlink", username, "", quality, "", "", 
                            "streamlink failed or no stream found", timestamp, "offline");
                    System.exit(1);
                }
                
                if ("--json".equals(jsonFlag)) {
                    emitJson(true, "streamlink", username, url, quality, "", "", "", timestamp, "live");
                } else {
                    System.out.println(url);
                }
                System.exit(0);
            }
            
            JsonNode data = objectMapper.readTree(outputStr);
            String url = data.path("url").asText("");
            
            JsonNode streams = data.path("streams");
            if (url.isEmpty() && streams.isObject()) {
                for (String key : Arrays.asList("best", "worst")) {
                    JsonNode stream = streams.path(key);
                    if (stream.isObject() && stream.has("url")) {
                        url = stream.path("url").asText();
                        break;
                    }
                }
                
                if (url.isEmpty()) {
                    Iterator<Map.Entry<String, JsonNode>> fields = streams.fields();
                    while (fields.hasNext()) {
                        Map.Entry<String, JsonNode> entry = fields.next();
                        JsonNode stream = entry.getValue();
                        if (stream.isObject() && stream.has("url")) {
                            url = stream.path("url").asText();
                            break;
                        }
                    }
                }
            }
            
            JsonNode metadata = data.path("metadata");
            String author = metadata.path("author").asText("");
            String title = metadata.path("title").asText("");
            
            if (url.isEmpty()) {
                emitJson(false, "streamlink", username, "", quality, author, title, 
                        "could not extract stream URL", timestamp, "offline");
                System.exit(1);
            }
            
            if ("--json".equals(jsonFlag)) {
                emitJson(true, "streamlink", username, url, quality, author, title, "", timestamp, "live");
            } else {
                System.out.println(url);
            }
            
        } catch (Exception e) {
            emitJson(false, "streamlink", username, "", quality, "", "", 
                    "streamlink execution failed", timestamp, "technical_error");
            System.exit(2);
        }
    }
    
    private static double getLoadAverage() throws IOException {
        List<String> lines = Files.readAllLines(Paths.get("/proc/loadavg"));
        if (!lines.isEmpty()) {
            String[] parts = lines.get(0).split("\\s+");
            if (parts.length > 0) {
                return Double.parseDouble(parts[0]);
            }
        }
        return 0.0;
    }
    
    private static boolean isCommandAvailable(String command) {
        try {
            ProcessBuilder pb = new ProcessBuilder("which", command);
            pb.redirectError(new File("/dev/null"));
            Process process = pb.start();
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static String getQualitySelector(String quality) {
        switch (quality) {
            case "original": return "origin,uhd_60,hd_60,hd,sd,ld,best,worst";
            case "auto": return "best,origin,uhd_60,hd_60,hd,sd,ld,worst";
            case "1080p60": return "uhd_60,hd_60,hd,sd,ld,worst";
            case "720p60": return "hd_60,hd,sd,ld,worst";
            case "720p": return "hd,sd,ld,worst";
            case "540p": return "sd,ld,worst";
            case "360p": return "ld,worst";
            default: return quality;
        }
    }
    
    private static void emitJson(boolean success, String method, String username, String url, 
                               String quality, String author, String title, String error, 
                               String timestamp, String status) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("success", success);
        payload.put("method", method);
        payload.put("username", username);
        if (url != null && !url.isEmpty()) payload.put("url", url);
        if (quality != null && !quality.isEmpty()) payload.put("quality", quality);
        if (author != null && !author.isEmpty()) payload.put("author", author);
        if (title != null && !title.isEmpty()) payload.put("title", title);
        if (error != null && !error.isEmpty()) payload.put("error", error);
        if (timestamp != null && !timestamp.isEmpty()) payload.put("timestamp", timestamp);
        if (status != null && !status.isEmpty()) payload.put("status", status);
        
        try {
            System.err.println(objectMapper.writeValueAsString(payload));
        } catch (Exception e) {
            System.err.println("{\"error\":\"JSON serialization failed\"}");
        }
    }
}
