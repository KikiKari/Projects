// abstraction-provenance: {"artifact_sha256": "04835e013d6f5fed821524b4401ff63f09ef960296ec31f63f37e077ae2a74b8", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "java"}
// github_publisher.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

public class GithubPublisher {
    private static final Set<String> LANGUAGES = new HashSet<>(Arrays.asList(
        "perl5", "powershell", "perl6", "tcl", "javascript", "ruby", "python", 
        "lua", "shell", "go", "java", "c", "cpp", "php", "fsharp", "css"
    ));

    /**
     * Reconcile a remote snapshot into the checkout without changing its Git history.
     */
    public static class SyncResult {
        public final String revision;
        public final Map<String, Integer> counts;

        public SyncResult(String revision, Map<String, Integer> counts) {
            this.revision = revision;
            this.counts = counts;
        }
    }

    public static SyncResult synchronizeCheckout(Path root, String remote, String branch) 
            throws IOException, InterruptedException {
        root = root.toAbsolutePath().normalize();
        if (!Files.exists(root) || !Files.isDirectory(root)) {
            throw new IOException("Root directory does not exist or is not a directory");
        }

        Path tmpDir = Files.createTempDirectory("abstractions-snapshot-");
        try {
            Path snapshot = tmpDir.resolve("repo");
            
            ProcessBuilder cloneProcess = new ProcessBuilder(
                "git", "clone", "--quiet", "--depth=1", "--single-branch",
                "--branch", branch, "--", remote, snapshot.toString()
            );
            Process process = cloneProcess.start();
            boolean finished = process.waitFor(300, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new IOException("Git clone timed out");
            }
            if (process.exitValue() != 0) {
                throw new IOException("Git clone failed with exit code " + process.exitValue());
            }

            ProcessBuilder revParseProcess = new ProcessBuilder(
                "git", "-C", snapshot.toString(), "rev-parse", "HEAD"
            );
            Process revParseProc = revParseProcess.start();
            String revision;
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(revParseProc.getInputStream()))) {
                revision = reader.readLine().trim();
            }
            revParseProc.waitFor(30, TimeUnit.SECONDS);

            Map<String, Integer> counts = new HashMap<>();
            for (String language : new TreeSet<>(LANGUAGES)) {
                Path source = snapshot.resolve(language);
                Path target = root.resolve(language);
                
                if (Files.isSymbolicLink(source) || Files.isSymbolicLink(target)) {
                    throw new IOException("language directory is a symlink");
                }
                
                Files.createDirectories(target);
                
                Set<String> known = new HashSet<>();
                if (Files.exists(target)) {
                    try (DirectoryStream<Path> stream = Files.newDirectoryStream(target)) {
                        for (Path p : stream) {
                            if (Files.isRegularFile(p) && !Files.isSymbolicLink(p)) {
                                known.add(sha256Hash(p));
                            }
                        }
                    }
                }
                
                List<Path> files = new ArrayList<>();
                if (Files.exists(source) && Files.isDirectory(source)) {
                    try (DirectoryStream<Path> stream = Files.newDirectoryStream(source)) {
                        for (Path p : stream) {
                            if (Files.isSymbolicLink(p) || !Files.isRegularFile(p)) {
                                throw new IOException("invalid remote abstraction");
                            }
                            files.add(p);
                        }
                    }
                }
                
                Collections.sort(files);
                counts.put(language, files.size());
                
                for (Path item : files) {
                    byte[] data = Files.readAllBytes(item);
                    String digest = sha256Hash(data);
                    if (known.contains(digest)) {
                        continue;
                    }
                    
                    Path destination = target.resolve(item.getFileName().toString());
                    if (Files.exists(destination) || Files.isSymbolicLink(destination)) {
                        String stem = item.getFileName().toString();
                        int dotIndex = stem.lastIndexOf('.');
                        String name = dotIndex > 0 ? stem.substring(0, dotIndex) : stem;
                        String suffix = dotIndex > 0 ? stem.substring(dotIndex) : "";
                        destination = target.resolve(name + "__pool_" + digest + suffix);
                    }
                    
                    try {
                        Files.write(destination, data, StandardOpenOption.CREATE_NEW);
                    } catch (FileAlreadyExistsException e) {
                        if (Files.isSymbolicLink(destination) || 
                            !Files.isRegularFile(destination) || 
                            !Arrays.equals(Files.readAllBytes(destination), data)) {
                            throw new IOException("local abstraction conflict");
                        }
                    }
                    known.add(digest);
                }
            }
            
            return new SyncResult(revision, counts);
        } finally {
            deleteRecursively(tmpDir);
        }
    }

    private static void deleteRecursively(Path path) throws IOException {
        if (Files.exists(path)) {
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

    public static void updateStatusCounts(Path path, String revision, Map<String, Integer> counts) 
            throws IOException {
        String text = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
        
        StringBuilder rows = new StringBuilder();
        rows.append("## Bestand\n\n");
        rows.append(String.format("GitHub-Stand: `%s`\n\n", revision));
        rows.append("| Zielsprache | Dateien |\n");
        rows.append("|---|---:|\n");
        
        int total = 0;
        for (String language : new TreeSet<>(LANGUAGES)) {
            int count = counts.getOrDefault(language, 0);
            total += count;
            rows.append(String.format("| %s | %d |\n", language, count));
        }
        rows.append(String.format("| **gesamt** | **%d** |\n\n", total));
        
        String pattern = "(?sm)^## Bestand\\n.*?(?=^## Quellen\\n)";
        text = text.replaceFirst(pattern, rows.toString());
        
        Files.write(path, text.getBytes(StandardCharsets.UTF_8));
    }

    public static void queueArtifact(Map<String, Object> state, Path root, Path path) 
            throws IOException {
        root = root.toAbsolutePath().normalize();
        path = path.toAbsolutePath().normalize();
        
        if (Files.isSymbolicLink(path)) {
            throw new IOException("artifact must not be a symlink");
        }
        
        Path relative = root.relativize(path);
        String relativeStr = relative.toString().replace('\\', '/');
        
        if (!"STATUS.md".equals(relativeStr) && 
            (relative.getNameCount() == 0 || !LANGUAGES.contains(relative.getName(0).toString()))) {
            throw new IOException("artifact is outside a language directory");
        }
        
        @SuppressWarnings("unchecked")
        Map<String, String> pending = (Map<String, String>) 
            state.computeIfAbsent("ausstehende_veroeffentlichungen", k -> new HashMap<>());
        
        pending.put(relativeStr, sha256Hash(path));
    }

    public static boolean publishPending(
            Path root, 
            Map<String, Object> state, 
            Runnable save,
            String token,
            URLOpener opener,
            SyncFunction sync) throws IOException {
        
        @SuppressWarnings("unchecked")
        Map<String, String> pending = (Map<String, String>) 
            state.getOrDefault("ausstehende_veroeffentlichungen", new HashMap<>());
        
        if (!(pending instanceof Map)) {
            throw new IOException("invalid publication queue");
        }
        
        if (pending.isEmpty() && sync == null) {
            return true;
        }
        
        if (token == null || token.trim().isEmpty()) {
            return false;
        }
        
        root = root.toAbsolutePath().normalize();
        String authToken = token.trim();
        
        Map<String, String> headers = new HashMap<>();
        headers.put("Authorization", "Bearer " + authToken);
        headers.put("Accept", "application/vnd.github+json");
        headers.put("X-GitHub-Api-Version", "2022-11-28");
        headers.put("User-Agent", "abstractions-manager");
        
        boolean success = true;
        List<Map.Entry<String, String>> entries = new ArrayList<>(pending.entrySet());
        entries.sort((a, b) -> Boolean.compare("STATUS.md".equals(a.getKey()), "STATUS.md".equals(b.getKey())));
        
        boolean synced = false;
        for (Map.Entry<String, String> entry : entries) {
            String name = entry.getKey();
            String expected = entry.getValue();
            
            try {
                Path path = root.resolve(name);
                if (Files.isSymbolicLink(path) || 
                    !root.relativize(path.toAbsolutePath().normalize()).toString().replace('\\', '/').equals(name)) {
                    throw new IOException("invalid queued path");
                }
                
                byte[] data = Files.readAllBytes(path);
                if (!sha256Hash(data).equals(expected)) {
                    throw new IOException("queued artifact changed");
                }
                
                if ("STATUS.md".equals(name) && sync != null) {
                    if (!success) {
                        throw new IOException("artifact publication incomplete");
                    }
                    
                    SyncResult result = sync.sync(root);
                    synced = true;
                    updateStatusCounts(path, result.revision, result.counts);
                    data = Files.readAllBytes(path);
                    expected = sha256Hash(data);
                    pending.put(name, expected);
                    save.run();
                }
                
                String endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" + 
                    name.replace(" ", "%20");
                
                Map<String, Object> existing = lookup(opener, endpoint + "?ref=gateway1-abstractions", headers);
                
                if ("STATUS.md".equals(name) && existing != null && !same(existing, data)) {
                    String sha = (String) existing.get("sha");
                    if (!(sha instanceof String) || sha.isEmpty()) {
                        throw new IOException("missing remote status version");
                    }
                    
                    Map<String, Object> bodyData = new HashMap<>();
                    bodyData.put("message", "Update abstraction status");
                    bodyData.put("branch", "gateway1-abstractions");
                    bodyData.put("content", Base64.getEncoder().encodeToString(data));
                    bodyData.put("sha", sha);
                    
                    String jsonBody = toJson(bodyData);
                    HttpRequest request = new HttpRequest(endpoint, "PUT", jsonBody.getBytes(StandardCharsets.UTF_8), headers);
                    opener.open(request);
                } else if (existing != null && !same(existing, data)) {
                    Path candidate = Paths.get(name);
                    String alternateName = candidate.getParent() != null ? 
                        candidate.getParent().resolve(
                            candidate.getFileName().toString().substring(0, 
                                candidate.getFileName().toString().lastIndexOf('.')) + 
                            "_" + expected.substring(0, 12) + 
                            candidate.getFileName().toString().substring(
                                candidate.getFileName().toString().lastIndexOf('.'))
                        ).toString().replace('\\', '/') : 
                        candidate.getFileName().toString().substring(0, 
                            candidate.getFileName().toString().lastIndexOf('.')) + 
                        "_" + expected.substring(0, 12) + 
                        candidate.getFileName().toString().substring(
                            candidate.getFileName().toString().lastIndexOf('.'));
                    
                    String alternateEndpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" + 
                        alternateName.replace(" ", "%20");
                    Map<String, Object> alternateExisting = lookup(opener, alternateEndpoint, headers);
                    
                    if (alternateExisting != null && !same(alternateExisting, data)) {
                        throw new IOException("remote artifact conflict");
                    }
                }
                
                if (existing == null) {
                    Map<String, Object> bodyData = new HashMap<>();
                    bodyData.put("message", "Publish script abstraction");
                    bodyData.put("branch", "gateway1-abstractions");
                    bodyData.put("content", Base64.getEncoder().encodeToString(data));
                    
                    String jsonBody = toJson(bodyData);
                    HttpRequest request = new HttpRequest(endpoint, "PUT", jsonBody.getBytes(StandardCharsets.UTF_8), headers);
                    opener.open(request);
                }
                
                pending.remove(name);
                save.run();
            } catch (Exception e) {
                success = false;
            }
        }
        
        if (sync != null && !synced) {
            try {
                sync.sync(root);
            } catch (Exception e) {
                success = false;
            }
        }
        
        return success;
    }

    private static Map<String, Object> lookup(URLOpener opener, String endpoint, Map<String, String> headers) 
            throws IOException {
        try {
            HttpRequest request = new HttpRequest(endpoint, "GET", null, headers);
            HttpResponse response = opener.open(request);
            return fromJson(new String(response.body, StandardCharsets.UTF_8));
        } catch (IOException e) {
            if (e.getMessage().contains("404")) {
                return null;
            }
            throw e;
        }
    }

    private static boolean same(Map<String, Object> existing, byte[] data) {
        if (existing == null || !"base64".equals(existing.get("encoding"))) {
            return false;
        }
        String content = (String) existing.get("content");
        if (content == null) {
            return false;
        }
        try {
            return Arrays.equals(Base64.getDecoder().decode(content), data);
        } catch (Exception e) {
            return false;
        }
    }

    private static String sha256Hash(Path path) throws IOException {
        return sha256Hash(Files.readAllBytes(path));
    }

    private static String sha256Hash(byte[] data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    // Helper classes for HTTP operations
    public interface URLOpener {
        HttpResponse open(HttpRequest request) throws IOException;
    }

    public interface SyncFunction {
        SyncResult sync(Path root) throws IOException, InterruptedException;
    }

    public static class HttpRequest {
        public final String url;
        public final String method;
        public final byte[] data;
        public final Map<String, String> headers;

        public HttpRequest(String url, String method, byte[] data, Map<String, String> headers) {
            this.url = url;
            this.method = method;
            this.data = data;
            this.headers = headers;
        }
    }

    public static class HttpResponse {
        public final byte[] body;

        public HttpResponse(byte[] body) {
            this.body = body;
        }
    }

    // Simple JSON helpers (would need a real JSON library in production)
    private static String toJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            if (!first) sb.append(",");
            sb.append("\"").append(entry.getKey()).append("\":");
            if (entry.getValue() instanceof String) {
                sb.append("\"").append(entry.getValue()).append("\"");
            } else {
                sb.append(entry.getValue().toString());
            }
            first = false;
        }
        sb.append("}");
        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> fromJson(String json) {
        // This is a very simplified JSON parser - use a proper library in production
        Map<String, Object> result = new HashMap<>();
        json = json.trim();
        if (json.startsWith("{") && json.endsWith("}")) {
            json = json.substring(1, json.length() - 1);
            String[] pairs = json.split(",");
            for (String pair : pairs) {
                String[] keyValue = pair.split(":");
                if (keyValue.length == 2) {
                    String key = keyValue[0].trim().replaceAll("^\"|\"$", "");
                    String value = keyValue[1].trim().replaceAll("^\"|\"$", "");
                    result.put(key, value);
                }
            }
        }
        return result;
    }
}
