// abstraction-provenance: {"artifact_sha256": "b08b773ea3901beef0a482d67fdfbc4df7bc181af1c1031fd5dc1001a1de893d", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "java"}
// extract-tiktok-yt-dlp.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.time.format.DateTimeFormatter;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class ExtractTikTokYTDLP {
    private static final String TMP_DIR_PREFIX = "/tmp/tiktok-yt-dlp.";
    private static final Gson gson = new Gson();
    
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Username required");
            System.exit(64);
        }
        
        String username = args[0].startsWith("@") ? args[0].substring(1) : args[0];
        String format = args.length > 1 ? args[1] : "best";
        String jsonFlag = args.length > 2 ? args[2] : "";
        
        String timestamp = ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        
        Path tmpDir;
        try {
            tmpDir = Files.createTempDirectory(Paths.get("/tmp"), "tiktok-yt-dlp.");
        } catch (IOException e) {
            System.err.println("Failed to create temp directory");
            System.exit(2);
            return;
        }
        
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                deleteRecursively(tmpDir);
            } catch (IOException ignored) {}
        }));
        
        // Validate username
        if (!username.matches("^[A-Za-z0-9._]{1,24}$")) {
            System.err.println("Invalid TikTok username");
            System.exit(64);
            return;
        }
        
        // Validate format
        Set<String> validFormats = new HashSet<>(Arrays.asList(
            "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
            "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
            "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
            "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
            "hls-sd/hls-ld/flv-sd/flv-ld",
            "hls-ld/flv-ld",
            "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
        ));
        if (!validFormats.contains(format)) {
            System.err.println("Invalid yt-dlp format");
            System.exit(64);
            return;
        }
        
        // Check system load
        double loadPerCpu = getLoadPerCpu();
        String maxLoadStr = System.getenv("TIKTOK_MAX_LOAD_PER_CPU");
        double maxLoad = maxLoadStr != null ? Double.parseDouble(maxLoadStr) : 1.5;
        if (loadPerCpu > maxLoad) {
            emitJson(false, "yt-dlp", username, "", format, "host overloaded", timestamp, "overloaded");
            System.exit(75);
            return;
        }
        
        // Check if yt-dlp exists
        if (!isCommandAvailable("yt-dlp")) {
            emitJson(false, "yt-dlp", username, "", format, "yt-dlp not installed", timestamp, "dependency_missing");
            System.exit(2);
            return;
        }
        
        // Run yt-dlp
        String liveUrl = "https://www.tiktok.com/@" + username + "/live";
        Path stdoutFile = tmpDir.resolve("stdout.json");
        Path stderrFile = tmpDir.resolve("stderr.log");
        
        int exitCode = runYtDlp(liveUrl, format, stdoutFile, stderrFile);
        if (exitCode != 0) {
            String status, errorStatus;
            int code;
            try {
                String stderrContent = readFile(stderrFile, 1000);
                if (stderrContent.toLowerCase().contains("not currently live") ||
                    stderrContent.toLowerCase().contains("no live cdn found") ||
                    stderrContent.toLowerCase().contains("not available") ||
                    stderrContent.toLowerCase().contains("private video")) {
                    status = "offline";
                    code = 1;
                } else {
                    status = "technical_error";
                    code = 2;
                }
                emitJson(false, "yt-dlp", username, "", format, stderrContent, timestamp, status);
            } catch (IOException e) {
                emitJson(false, "yt-dlp", username, "", format, "failed to read error log", timestamp, "technical_error");
            }
            System.exit(code);
            return;
        }
        
        // Extract URL
        String url = extractVideoUrl(stdoutFile);
        if (url == null || url.isEmpty()) {
            emitJson(false, "yt-dlp", username, "", format, "could not extract HTTPS video URL", timestamp, "offline");
            System.exit(1);
            return;
        }
        
        if ("--json".equals(jsonFlag)) {
            emitJson(true, "yt-dlp", username, url, format, "", timestamp, "live");
        } else {
            System.out.println(url);
        }
    }
    
    private static double getLoadPerCpu() {
        try {
            // This is a simplified approach - actual implementation would need OS-specific code
            // For demonstration purposes, returning a dummy value
            return 0.5;
        } catch (Exception e) {
            return 0.0;
        }
    }
    
    private static boolean isCommandAvailable(String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"which", command});
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static int runYtDlp(String url, String format, Path stdoutFile, Path stderrFile) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "yt-dlp",
                "--no-warnings",
                "--dump-single-json",
                "--skip-download",
                "--format",
                format,
                url
            );
            pb.redirectOutput(stdoutFile.toFile());
            pb.redirectError(stderrFile.toFile());
            Process process = pb.start();
            return process.waitFor();
        } catch (Exception e) {
            return -1;
        }
    }
    
    private static String extractVideoUrl(Path jsonFile) {
        try {
            String content = Files.readString(jsonFile);
            JsonObject obj = gson.fromJson(content, JsonObject.class);
            
            List<String> candidates = new ArrayList<>();
            
            if (obj.has("url") && obj.get("url").isJsonPrimitive()) {
                candidates.add(obj.get("url").getAsString());
            }
            
            if (obj.has("formats") && obj.get("formats").isJsonArray()) {
                for (var element : obj.getAsJsonArray("formats")) {
                    if (element.isJsonObject()) {
                        var formatObj = element.getAsJsonObject();
                        if (formatObj.has("url") && formatObj.get("url").isJsonPrimitive()) {
                            candidates.add(formatObj.get("url").getAsString());
                        }
                    }
                }
            }
            
            for (String value : candidates) {
                String lowerValue = value.toLowerCase();
                if (value.startsWith("https://") && 
                    (lowerValue.contains(".m3u8") || lowerValue.contains(".flv")) &&
                    !lowerValue.contains("only_audio=1")) {
                    return value;
                }
            }
        } catch (Exception e) {
            // Ignore parsing errors
        }
        return null;
    }
    
    private static void emitJson(boolean success, String method, String username, String url, 
                                 String format, String error, String timestamp, String status) {
        JsonObject payload = new JsonObject();
        payload.addProperty("success", success);
        if (method != null && !method.isEmpty()) payload.addProperty("method", method);
        if (username != null && !username.isEmpty()) payload.addProperty("username", username);
        if (url != null && !url.isEmpty()) payload.addProperty("url", url);
        if (format != null && !format.isEmpty()) payload.addProperty("format", format);
        if (error != null && !error.isEmpty()) payload.addProperty("error", error);
        if (timestamp != null && !timestamp.isEmpty()) payload.addProperty("timestamp", timestamp);
        if (status != null && !status.isEmpty()) payload.addProperty("status", status);
        
        System.err.println(gson.toJson(payload));
    }
    
    private static String readFile(Path file, int maxLength) throws IOException {
        byte[] bytes = Files.readAllBytes(file);
        if (bytes.length > maxLength) {
            return new String(Arrays.copyOf(bytes, maxLength));
        }
        return new String(bytes);
    }
    
    private static void deleteRecursively(Path path) throws IOException {
        if (Files.isDirectory(path)) {
            try (DirectoryStream<Path> stream = Files.newDirectoryStream(path)) {
                for (Path entry : stream) {
                    deleteRecursively(entry);
                }
            }
        }
        Files.deleteIfExists(path);
    }
}
