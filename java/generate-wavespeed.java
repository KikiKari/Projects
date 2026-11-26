// abstraction-provenance: {"artifact_sha256": "966aa3f9c9cc66aad18d176e4a72e534085ed6c3f81a350bae7413dc77dbd788", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "java"}
// generate-wavespeed.mjs — portiert nach java
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.*;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.core.type.TypeReference;

public class GenerateWavespeed {
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final String API_KEY = System.getenv("WAVESPEED_API_KEY");
    
    public static void main(String[] args) throws Exception {
        if (API_KEY == null || API_KEY.isEmpty()) {
            throw new RuntimeException("WAVESPEED_API_KEY fehlt.");
        }
        
        Path currentDir = Paths.get("").toAbsolutePath();
        Path projectRoot = currentDir.getParent().getParent();
        Path mediaProductionDir = projectRoot.resolve("media-production");
        Path rawDir = mediaProductionDir.resolve("raw");
        Path publicDir = projectRoot.resolve("public").resolve("media");
        Path jobsFile = mediaProductionDir.resolve("wavespeed-jobs.json");
        Path resultsFile = mediaProductionDir.resolve("wavespeed-results.json");
        
        Files.createDirectories(rawDir);
        Files.createDirectories(publicDir);
        
        List<Map<String, Object>> jobs = objectMapper.readValue(jobsFile.toFile(), new TypeReference<List<Map<String, Object>>>(){});
        List<Map<String, Object>> log = new ArrayList<>();
        
        if (Files.exists(resultsFile)) {
            try {
                log = objectMapper.readValue(resultsFile.toFile(), new TypeReference<List<Map<String, Object>>>(){});
            } catch (Exception e) {
                log = new ArrayList<>();
            }
        }
        
        for (Map<String, Object> job : jobs) {
            String jobId = (String) job.get("id");
            String outputName = (String) job.get("output");
            Path rawPath = rawDir.resolve(jobId + ".png");
            Path targetPath = publicDir.resolve(outputName + ".png");
            
            boolean alreadyGenerated = Files.exists(rawPath);
            if (alreadyGenerated) {
                boolean foundInLog = false;
                for (Map<String, Object> entry : log) {
                    if (entry.get("id").equals(jobId)) {
                        foundInLog = true;
                        break;
                    }
                }
                
                if (!foundInLog) {
                    Map<String, Object> logEntry = new HashMap<>();
                    logEntry.put("id", jobId);
                    logEntry.put("requestId", "completed-before-resume");
                    logEntry.put("model", "google/nano-banana-2/edit");
                    logEntry.put("resolution", "4k");
                    logEntry.put("plannedCostUsd", 0.14);
                    logEntry.put("output", targetPath.getFileName().toString());
                    log.add(logEntry);
                    writeResults(resultsFile, log);
                }
                System.out.println("Übersprungen: " + jobId + " ist bereits vorhanden.");
                continue;
            }
            
            List<String> images = new ArrayList<>();
            List<String> jobImages = (List<String>) job.get("images");
            for (String image : jobImages) {
                if (image.startsWith("http:") || image.startsWith("https:") || image.startsWith("data:")) {
                    images.add(image);
                } else {
                    Path imagePath = projectRoot.resolve("..").resolve(image).normalize();
                    byte[] bytes = Files.readAllBytes(imagePath);
                    String base64 = Base64.getEncoder().encodeToString(bytes);
                    images.add("data:image/png;base64," + base64);
                }
            }
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("prompt", job.get("prompt"));
            requestBody.put("images", images);
            requestBody.put("aspect_ratio", job.get("aspectRatio"));
            requestBody.put("resolution", "4k");
            requestBody.put("output_format", "png");
            requestBody.put("enable_web_search", false);
            requestBody.put("enable_image_search", false);
            requestBody.put("enable_sync_mode", false);
            requestBody.put("enable_base64_output", false);
            
            String jsonBody = objectMapper.writeValueAsString(requestBody);
            
            URL url = new URL("https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Authorization", "Bearer " + API_KEY);
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setDoOutput(true);
            
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = jsonBody.getBytes("utf-8");
                os.write(input, 0, input.length);
            }
            
            int responseCode = connection.getResponseCode();
            if (responseCode != 200) {
                String errorResponse = readResponse(connection.getErrorStream());
                throw new RuntimeException("WaveSpeed submit fehlgeschlagen: " + responseCode + " " + errorResponse);
            }
            
            String responseJson = readResponse(connection.getInputStream());
            Map<String, Object> submitted = objectMapper.readValue(responseJson, new TypeReference<Map<String, Object>>(){});
            Map<String, Object> data = (Map<String, Object>) submitted.get("data");
            String requestId = data != null ? (String) data.get("id") : (String) submitted.get("id");
            
            Map<String, Object> result = null;
            for (int attempt = 0; attempt < 90; attempt++) {
                Thread.sleep(4000);
                
                URL pollUrl = new URL("https://api.wavespeed.ai/api/v3/predictions/" + requestId + "/result");
                HttpURLConnection pollConnection = (HttpURLConnection) pollUrl.openConnection();
                pollConnection.setRequestProperty("Authorization", "Bearer " + API_KEY);
                
                String pollResponse = readResponse(pollConnection.getInputStream());
                result = objectMapper.readValue(pollResponse, new TypeReference<Map<String, Object>>(){});
                
                Map<String, Object> resultData = (Map<String, Object>) result.get("data");
                if (resultData != null && "completed".equals(resultData.get("status"))) {
                    break;
                }
                
                if (resultData != null && "failed".equals(resultData.get("status"))) {
                    throw new RuntimeException("WaveSpeed job fehlgeschlagen: " + jobId);
                }
            }
            
            Map<String, Object> resultData = (Map<String, Object>) result.get("data");
            List<String> outputs = (List<String>) resultData.get("outputs");
            String imageUrl = outputs.get(0);
            
            URL imageURL = new URL(imageUrl);
            InputStream in = imageURL.openStream();
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] dataBuffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = in.read(dataBuffer, 0, dataBuffer.length)) != -1) {
                buffer.write(dataBuffer, 0, bytesRead);
            }
            byte[] imageBytes = buffer.toByteArray();
            
            Files.write(rawPath, imageBytes);
            Files.write(targetPath, imageBytes);
            
            Map<String, Object> logEntry = new HashMap<>();
            logEntry.put("id", jobId);
            logEntry.put("requestId", requestId);
            logEntry.put("model", "google/nano-banana-2/edit");
            logEntry.put("resolution", "4k");
            logEntry.put("plannedCostUsd", 0.14);
            logEntry.put("output", targetPath.getFileName().toString());
            log.add(logEntry);
            
            writeResults(resultsFile, log);
            System.out.println("Abgeschlossen: " + jobId);
        }
        
        writeResults(resultsFile, log);
        double totalCost = log.size() * 0.14;
        System.out.println("WaveSpeed abgeschlossen: " + log.size() + " Assets, geplante Basiskosten $" + String.format("%.2f", totalCost) + ".");
    }
    
    private static String readResponse(InputStream inputStream) throws IOException {
        if (inputStream == null) return "";
        StringBuilder response = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
        }
        return response.toString();
    }
    
    private static void writeResults(Path file, List<Map<String, Object>> data) throws IOException {
        String json = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(data);
        Files.write(file, json.getBytes("utf-8"));
    }
}
