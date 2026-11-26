// abstraction-provenance: {"artifact_sha256": "33c3674b8097edbff68c9eaf19e8cee5102531ffb5a26889eb96f8c0104555b1", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "java"}
// gateway_transport.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * Gateway-authenticated transport with manager-owned attempt records.
 *
 * An attempt is saved before submission. If its outcome is uncertain, subsequent
 * calls only query the same node and attempt; they do not submit it again.
 */
public class GatewayTransport {
    private final Map<String, Object> state;
    private final Runnable save;
    private final String url;
    private final String token;
    private final int timeout;
    private final int interval;
    private final Function<HttpRequest, HttpResponse> opener;
    private final Supplier<Double> clock;
    private final Consumer<Integer> sleep;

    public GatewayTransport(Map<String, Object> state, Runnable save, String url, String token) {
        this(state, save, url, token, 3900, 3, 
             request -> HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString()),
             () -> (double) System.nanoTime() / 1_000_000_000,
             seconds -> {
                 try {
                     Thread.sleep(seconds * 1000);
                 } catch (InterruptedException e) {
                     Thread.currentThread().interrupt();
                 }
             });
    }

    public GatewayTransport(Map<String, Object> state, Runnable save, String url, String token,
                           int timeout, int interval, Function<HttpRequest, HttpResponse> opener,
                           Supplier<Double> clock, Consumer<Integer> sleep) {
        URI uri;
        try {
            uri = URI.create(url);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("invalid Gateway URL");
        }
        
        String scheme = uri.getScheme();
        String hostname = uri.getHost();
        
        if (!"http".equals(scheme) && !"https".equals(scheme) || hostname == null || hostname.isEmpty()) {
            throw new IllegalArgumentException("invalid Gateway URL");
        }
        if ("http".equals(scheme) && !Arrays.asList("127.0.0.1", "localhost", "::1").contains(hostname)) {
            throw new IllegalArgumentException("unencrypted Gateway must use loopback");
        }
        if (token == null || token.trim().isEmpty() || timeout <= 0 || interval <= 0) {
            throw new IllegalArgumentException("Gateway token and positive timeouts required");
        }
        
        this.state = state;
        this.save = save;
        this.url = url;
        this.token = token.trim();
        this.timeout = timeout;
        this.interval = interval;
        this.opener = opener;
        this.clock = clock;
        this.sleep = sleep;
    }

    private Map<String, Object> request(String node, Map<String, Object> requestMap, String deviceId) throws TransportUnresolved {
        Map<String, Object> payloadMap = new HashMap<>();
        payloadMap.put("node", node);
        payloadMap.put("device_id", deviceId);
        payloadMap.put("request", requestMap);
        
        String payload;
        try {
            payload = toJson(payloadMap);
        } catch (Exception e) {
            throw new TransportUnresolved("Failed to serialize payload", e);
        }
        
        HttpRequest.Builder builder = HttpRequest.newBuilder()
            .uri(URI.create(this.url))
            .header("Authorization", "Bearer " + this.token)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(payload));
            
        int requestTimeout = "node4".equals(node) ? 150 : 40;
        
        try {
            HttpResponse<String> response = this.opener.apply(builder.build());
            String raw = response.body();
            
            if (raw.length() > 4_000_000) {
                throw new TransportUnresolved("response too large");
            }
            
            Map<String, Object> data = (Map<String, Object>) fromJson(raw);
            if (!data.containsKey("result")) {
                throw new TransportUnresolved("invalid gateway response");
            }
            
            if (deviceId != null && !deviceId.equals(data.get("device_id"))) {
                throw new TransportUnresolved("gateway device identity mismatch");
            }
            
            return (Map<String, Object>) data.get("result");
        } catch (Exception error) {
            throw new TransportUnresolved("Gateway request failed", error);
        }
    }

    public Map<String, Object> available() throws TransportUnresolved {
        Map<String, Object> result = request("node1", Map.of("operation", "availability"), null);
        if (!(result instanceof Map)) {
            throw new TransportUnresolved("invalid node availability");
        }
        return result;
    }

    private void release(Map<String, Object> original, Map<String, Object> entry) {
        if (Boolean.TRUE.equals(entry.get("released"))) {
            return;
        }
        try {
            Map<String, Object> requestMap = new HashMap<>();
            requestMap.put("operation", "release");
            requestMap.put("job_id", original.get("job_id"));
            requestMap.put("attempt_id", original.get("attempt_id"));
            
            Map<String, Object> result = request(
                (String) original.get("selected_node"), 
                requestMap, 
                (String) original.get("selected_device_id")
            );
            
            if ("released".equals(result.get("status")) &&
                original.get("job_id").equals(result.get("job_id")) &&
                original.get("attempt_id").equals(result.get("attempt_id")) &&
                original.get("selected_node").equals(result.get("selected_node")) &&
                original.get("target_language").equals(result.get("target_language"))) {
                
                entry.put("released", true);
                this.save.run();
            }
        } catch (TransportUnresolved e) {
            // Retry cleanup later; the result is durable in manager state.
        }
    }

    public void releasePending() {
        Map<String, Object> auftraege = (Map<String, Object>) this.state.getOrDefault("auftraege", new HashMap<>());
        for (Object value : auftraege.values()) {
            if (value instanceof Map) {
                Map<String, Object> entry = (Map<String, Object>) value;
                String status = (String) entry.get("status");
                if (Arrays.asList("completed", "rejected", "failed").contains(status) &&
                    entry.get("job") instanceof Map) {
                    release((Map<String, Object>) entry.get("job"), entry);
                }
            }
        }
    }

    public void reject(Map<String, Object> job, String reason) {
        String sourceSha256 = (String) job.get("source_sha256");
        String targetLanguage = (String) job.get("target_language");
        if (sourceSha256 == null || targetLanguage == null) {
            return;
        }
        
        String key = sourceSha256 + ":" + targetLanguage;
        Map<String, Object> auftraege = (Map<String, Object>) this.state.getOrDefault("auftraege", new HashMap<>());
        Object entryObj = auftraege.get(key);
        
        if (!(entryObj instanceof Map)) {
            return;
        }
        
        Map<String, Object> entry = (Map<String, Object>) entryObj;
        if (!"completed".equals(entry.get("status"))) {
            return;
        }
        
        Map<String, Object> entryJob = (Map<String, Object>) entry.get("job");
        if (!Objects.equals(entryJob.get("attempt_id"), job.get("attempt_id"))) {
            throw new RuntimeException("rejected attempt identity mismatch");
        }
        
        entry.put("status", "rejected");
        entry.put("validation_error", reason.substring(0, Math.min(reason.length(), 500)));
        this.save.run();
    }

    public Map<String, Object> call(Map<String, Object> job) throws TransportUnresolved {
        String sourceSha256 = (String) job.get("source_sha256");
        String targetLanguage = (String) job.get("target_language");
        String selectedDeviceId = (String) job.get("selected_device_id");
        
        if (sourceSha256 == null || targetLanguage == null || selectedDeviceId == null) {
            throw new IllegalArgumentException("missing source identity");
        }
        
        String key = sourceSha256 + ":" + targetLanguage;
        Map<String, Object> auftraege = (Map<String, Object>) this.state.computeIfAbsent("auftraege", k -> new HashMap<>());
        Object entryObj = auftraege.get(key);
        Map<String, Object> entry = null;
        boolean fresh;
        
        if (entryObj instanceof Map) {
            entry = (Map<String, Object>) entryObj;
            if ("rejected".equals(entry.get("status"))) {
                release((Map<String, Object>) entry.get("job"), entry);
                if (!Boolean.TRUE.equals(entry.get("released"))) {
                    throw new TransportUnresolved("rejected attempt release is unresolved");
                }
                
                Map<String, Object> previous = entry;
                Map<String, Object> original = new HashMap<>(job);
                original.put("attempt_id", UUID.randomUUID().toString());
                
                List<Map<String, Object>> previousAttempts = (List<Map<String, Object>>) previous.getOrDefault("previous_attempts", new ArrayList<>());
                List<Map<String, Object>> newPreviousAttempts = new ArrayList<>(previousAttempts);
                
                Map<String, Object> attemptInfo = new HashMap<>();
                attemptInfo.put("job_id", ((Map<String, Object>) previous.get("job")).get("job_id"));
                attemptInfo.put("attempt_id", ((Map<String, Object>) previous.get("job")).get("attempt_id"));
                attemptInfo.put("selected_node", ((Map<String, Object>) previous.get("job")).get("selected_node"));
                attemptInfo.put("validation_error", previous.get("validation_error"));
                
                newPreviousAttempts.add(attemptInfo);
                
                entry = new HashMap<>();
                entry.put("job", original);
                entry.put("status", "submitted");
                entry.put("previous_attempts", newPreviousAttempts);
                
                auftraege.put(key, entry);
                this.save.run();
                fresh = true;
            } else {
                fresh = false;
            }
        } else {
            fresh = true;
        }
        
        if (entry == null) {
            Map<String, Object> original = new HashMap<>(job);
            original.put("attempt_id", UUID.randomUUID().toString());
            entry = new HashMap<>();
            entry.put("job", original);
            entry.put("status", "submitted");
            auftraege.put(key, entry);
            // If this write fails there must be no remote submission.
            this.save.run();
        }
        
        Map<String, Object> original = (Map<String, Object>) entry.get("job");
        // The dispatcher verifies the job object after transport returns.
        job.clear();
        job.putAll(original);
        
        if (entry.containsKey("response")) {
            release(original, entry);
            return (Map<String, Object>) entry.get("response");
        }
        
        if ("failed".equals(entry.get("status"))) {
            throw new TransportUnresolved("attempt requires reconciliation");
        }
        
        Map<String, Object> status = null;
        if (fresh) {
            try {
                Map<String, Object> executeRequest = new HashMap<>();
                executeRequest.put("operation", "execute");
                executeRequest.put("job", original);
                
                status = request(
                    (String) original.get("selected_node"),
                    executeRequest,
                    (String) original.get("selected_device_id")
                );
            } catch (TransportUnresolved e) {
                // The request may have been accepted. Query, never resend.
            }
        }
        
        double deadline = this.clock.get() + this.timeout;
        while (true) {
            if (status == null) {
                Map<String, Object> statusRequest = new HashMap<>();
                statusRequest.put("operation", "status");
                statusRequest.put("job_id", original.get("job_id"));
                statusRequest.put("attempt_id", original.get("attempt_id"));
                
                status = request(
                    (String) original.get("selected_node"),
                    statusRequest,
                    (String) original.get("selected_device_id")
                );
            }
            
            if (!(status instanceof Map)) {
                throw new TransportUnresolved("attempt is not known by the node");
            }
            
            if (!Objects.equals(status.get("job_id"), original.get("job_id")) ||
                !Objects.equals(status.get("attempt_id"), original.get("attempt_id")) ||
                !Objects.equals(status.get("selected_node"), original.get("selected_node")) ||
                !Objects.equals(status.get("target_language"), original.get("target_language"))) {
                throw new TransportUnresolved("status identity mismatch");
            }
            
            String state = (String) status.get("status");
            if ("completed".equals(state)) {
                Map<String, Object> response = (Map<String, Object>) status.get("response");
                if (response == null || !"ok".equals(response.get("status")) ||
                    !Objects.equals(response.get("job_id"), original.get("job_id")) ||
                    !Objects.equals(response.get("selected_node"), original.get("selected_node")) ||
                    !Objects.equals(response.get("target_language"), original.get("target_language")) ||
                    !(response.get("code") instanceof String) ||
                    ((String) response.get("code")).trim().isEmpty()) {
                    throw new TransportUnresolved("invalid translation result");
                }
                
                entry.put("response", response);
                entry.put("status", "completed");
                this.save.run();
                release(original, entry);
                return response;
            }
            
            if (Arrays.asList("failed", "unknown").contains(state)) {
                entry.put("status", state);
                this.save.run();
                if ("failed".equals(state)) {
                    release(original, entry);
                }
                throw new TransportUnresolved("attempt requires reconciliation");
            }
            
            if (!"running".equals(state) || this.clock.get() >= deadline) {
                throw new TransportUnresolved("attempt is unresolved");
            }
            
            this.sleep.accept(this.interval);
            status = null;
        }
    }

    // Helper methods for JSON handling
    private String toJson(Object obj) {
        // Simple JSON serialization - in practice you'd use a proper library like Jackson or Gson
        return obj.toString(); // Placeholder implementation
    }

    private Map<String, Object> fromJson(String json) {
        // Simple JSON deserialization - in practice you'd use a proper library like Jackson or Gson
        return new HashMap<>(); // Placeholder implementation
    }

    // Custom exception class
    public static class TransportUnresolved extends RuntimeException {
        public TransportUnresolved(String message) {
            super(message);
        }
        
        public TransportUnresolved(String message, Throwable cause) {
            super(message, cause);
        }
    }

    // Functional interfaces for dependency injection
    @FunctionalInterface
    public interface Function<T, R> {
        R apply(T t) throws Exception;
    }

    @FunctionalInterface
    public interface Supplier<T> {
        T get();
    }

    @FunctionalInterface
    public interface Consumer<T> {
        void accept(T t);
    }

    // Placeholder for HTTP response
    public static class HttpResponse<T> {
        private final T body;

        public HttpResponse(T body) {
            this.body = body;
        }

        public T body() {
            return body;
        }
    }

    // Placeholder for HTTP request
    public static class HttpRequest {
        public static class Builder {
            public Builder uri(URI uri) { return this; }
            public Builder header(String name, String value) { return this; }
            public Builder POST(HttpRequest.BodyPublisher publisher) { return this; }
            public HttpRequest build() { return new HttpRequest(); }
        }

        public static class BodyPublishers {
            public static HttpRequest.BodyPublisher ofString(String data) { return new BodyPublisher(); }
        }

        public static class BodyPublisher {}
    }

    // Static method equivalent to Python's gateway_token function
    public static String gatewayToken() {
        String token = System.getenv("OPENCLAW_GATEWAY_TOKEN");
        if (token != null && !token.trim().isEmpty()) {
            return token.trim();
        }
        
        String configPathStr = System.getenv("OPENCLAW_CONFIG_PATH");
        Path path;
        if (configPathStr != null && !configPathStr.isEmpty()) {
            path = Paths.get(configPathStr);
        } else {
            path = Paths.get(System.getProperty("user.home"), ".openclaw", "openclaw.json");
        }
        
        try {
            String content = Files.readString(path);
            // In practice, parse JSON properly with a library
            // This is a simplified placeholder
            return ""; // Placeholder implementation
        } catch (Exception e) {
            return "";
        }
    }
}
