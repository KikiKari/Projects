// abstraction-provenance: {"artifact_sha256": "a4481d408f2cecdf96567b5f0bb592527bac359663da4e5474891c200643e119", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "java"}
// git_source_inventory.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.Pattern;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class GitSourceInventory {

    public static class Manager {
        public Path QUELLEN_DIR;
        public Map<String, String> QUELLSPRACHEN;
        public List<String> AUSSCHLUSS;
        public String GITHUB_BENUTZER;
        public int MAX_BYTES;

        public ProcessResult _git(String... args) throws IOException, InterruptedException {
            return _git(null, args);
        }

        public ProcessResult _git(Path verzeichnis, String... args) throws IOException, InterruptedException {
            List<String> command = new ArrayList<>();
            command.add("git");
            Collections.addAll(command, args);

            ProcessBuilder pb = new ProcessBuilder(command);
            if (verzeichnis != null) {
                pb.directory(verzeichnis.toFile());
            }
            Process process = pb.start();
            ByteArrayOutputStream stdout = new ByteArrayOutputStream();
            ByteArrayOutputStream stderr = new ByteArrayOutputStream();

            ExecutorService executor = Executors.newFixedThreadPool(2);
            executor.submit(() -> copyStream(process.getInputStream(), stdout));
            executor.submit(() -> copyStream(process.getErrorStream(), stderr));
            executor.shutdown();
            process.waitFor();

            return new ProcessResult(process.exitValue(), stdout.toByteArray(), stderr.toByteArray());
        }

        private void copyStream(InputStream input, OutputStream output) {
            try {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = input.read(buffer)) != -1) {
                    output.write(buffer, 0, bytesRead);
                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        public boolean enthaelt_zugangsdaten(byte[] data) {
            String content = new String(data);
            return content.contains("password") || content.contains("secret") || content.contains("key");
        }

        public String _prioritaet(String path, String language) {
            if (language != null && (language.equals("java") || language.equals("python"))) {
                return "high";
            } else if (language != null && (language.equals("js") || language.equals("html"))) {
                return "medium";
            } else {
                return "low";
            }
        }

        public static class ProcessResult {
            public final int returncode;
            public final byte[] stdout;
            public final byte[] stderr;

            public ProcessResult(int returncode, byte[] stdout, byte[] stderr) {
                this.returncode = returncode;
                this.stdout = stdout;
                this.stderr = stderr;
            }
        }
    }

    public static class Source {
        public String repo;
        public Object branches; // Can be "alle" or List<String>

        public Source(String repo, Object branches) {
            this.repo = repo;
            this.branches = branches;
        }
    }

    public static void writePrivate(String path, byte[] data) throws IOException {
        Path filePath = Paths.get(path);
        Files.createDirectories(filePath.getParent());
        Set<PosixFilePermission> perms = PosixFilePermissions.fromString("rw-------");
        Files.write(filePath, data, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
        Files.setPosixFilePermissions(filePath, perms);
    }

    public static Map<String, Object> snapshot(Manager manager, String runId, int runAttempt, String workflowSha) 
            throws IOException, InterruptedException, ExecutionException {
        
        ExecutorService executor = Executors.newFixedThreadPool(3);
        try {
            List<Callable<Map.Entry<String, Map<String, Object>>>> tasks = new ArrayList<>();
            
            for (Object src : manager.QUELLEN) {
                Source source = (Source) src;
                tasks.add(() -> repositoryIndex(manager, source));
            }
            
            Map<String, Map<String, Object>> repositories = new HashMap<>();
            for (Future<Map.Entry<String, Map<String, Object>>> future : executor.invokeAll(tasks)) {
                Map.Entry<String, Map<String, Object>> result = future.get();
                repositories.put(result.getKey(), result.getValue());
            }
            
            Map<String, Object> result = new HashMap<>();
            result.put("version", 1);
            result.put("run_id", runId);
            result.put("run_attempt", runAttempt);
            result.put("workflow_sha", workflowSha);
            result.put("repositories", repositories);
            return result;
        } finally {
            executor.shutdown();
        }
    }

    private static Map.Entry<String, Map<String, Object>> repositoryIndex(Manager manager, Source source) 
            throws IOException, InterruptedException {
        String name = source.repo;
        Path mirror = manager.QUELLEN_DIR.resolve(name + ".git");

        List<String> refsLines = Arrays.asList(new String(manager._git(mirror, "for-each-ref", 
                "--format=%(refname:strip=2)%00%(objectname)", "refs/heads").stdout).split("\n"));
        
        List<Map.Entry<String, String>> selected = new ArrayList<>();
        for (String line : refsLines) {
            if (!line.isEmpty()) {
                String[] parts = line.split("\0", 2);
                String branch = parts[0];
                String commit = parts[1];
                if ("alle".equals(source.branches) || 
                    (source.branches instanceof List && ((List<?>) source.branches).contains(branch))) {
                    selected.add(new AbstractMap.SimpleEntry<>(branch, commit));
                }
            }
        }

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            List<Callable<Map.Entry<String, Map<String, Object>>>> tasks = new ArrayList<>();
            for (Map.Entry<String, String> item : selected) {
                tasks.add(() -> branchIndex(manager, mirror, item));
            }

            Map<String, Map<String, Object>> branches = new HashMap<>();
            for (Future<Map.Entry<String, Map<String, Object>>> future : executor.invokeAll(tasks)) {
                Map.Entry<String, Map<String, Object>> result = future.get();
                branches.put(result.getKey(), result.getValue());
            }

            if (branches.isEmpty() || 
                (!"alle".equals(source.branches) && !new HashSet<>(branches.keySet()).equals(new HashSet<>((List<String>) source.branches)))) {
                throw new IllegalArgumentException("incomplete source branches");
            }

            return new AbstractMap.SimpleEntry<>(name, branches);
        } finally {
            executor.shutdown();
        }
    }

    private static Map.Entry<String, Map<String, Object>> branchIndex(Manager manager, Path mirror, Map.Entry<String, String> item) 
            throws IOException, InterruptedException {
        String branch = item.getKey();
        String commit = item.getValue();

        String lsTreeOutput = new String(manager._git(mirror, "ls-tree", "-r", "-z", "--full-tree", commit).stdout);
        String[] entries = lsTreeOutput.split("\0");
        
        List<String> paths = new ArrayList<>();
        for (String entry : entries) {
            if (!entry.isEmpty()) {
                String[] parts = entry.split("\t", 2);
                String meta = parts[0];
                String path = parts[1];
                String[] metaParts = meta.split(" ");
                if (metaParts.length >= 2 && "blob".equals(metaParts[1])) {
                    String suffix = getFileExtension(path).toLowerCase();
                    if (manager.QUELLSPRACHEN.containsKey(suffix)) {
                        paths.add(path.replace("\\\\", "/"));
                    }
                }
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("commit", commit);
        result.put("paths", paths);
        return new AbstractMap.SimpleEntry<>(branch, result);
    }

    private static String getFileExtension(String fileName) {
        int lastDotIndex = fileName.lastIndexOf('.');
        return (lastDotIndex == -1) ? "" : fileName.substring(lastDotIndex);
    }

    public static Map<String, Object> prepareGitSources(
            Manager manager, String directory, Map<String, Object> state, String priority, 
            int count, String runId, int runAttempt, String workflowSha) 
            throws IOException, InterruptedException, ExecutionException, NoSuchAlgorithmException {
        
        manager.QUELLEN_DIR.toFile().mkdirs();

        ExecutorService executor = Executors.newFixedThreadPool(3);
        try {
            List<Callable<Void>> updateTasks = new ArrayList<>();
            for (Object src : manager.QUELLEN) {
                Source source = (Source) src;
                updateTasks.add(() -> {
                    update(manager, source);
                    return null;
                });
            }
            for (Future<Void> future : executor.invokeAll(updateTasks)) {
                future.get();
            }
        } finally {
            executor.shutdown();
        }

        Map<String, Object> index = snapshot(manager, runId, runAttempt, workflowSha);
        List<Map<String, Object>> sources = new ArrayList<>();

        @SuppressWarnings("unchecked")
        Map<String, Map<String, Object>> repos = (Map<String, Map<String, Object>>) index.get("repositories");
        
        List<Object[]> branches = new ArrayList<>();
        for (Map.Entry<String, Map<String, Object>> repoEntry : repos.entrySet()) {
            String repo = repoEntry.getKey();
            Map<String, Object> details = repoEntry.getValue();
            for (Map.Entry<String, Object> branchEntry : details.entrySet()) {
                String branch = branchEntry.getKey();
                @SuppressWarnings("unchecked")
                Map<String, Object> data = (Map<String, Object>) branchEntry.getValue();
                String commit = (String) data.get("commit");
                branches.add(new Object[]{repo, branch, commit});
            }
        }

        ExecutorService listExecutor = Executors.newFixedThreadPool(6);
        try {
            List<Callable<List<Map<String, Object>>>> listTasks = new ArrayList<>();
            for (Object[] branchData : branches) {
                listTasks.add(() -> listBranch(manager, branchData));
            }
            
            for (Future<List<Map<String, Object>>> future : listExecutor.invokeAll(listTasks)) {
                sources.addAll(future.get());
            }
        } finally {
            listExecutor.shutdown();
        }

        Map<String, Map<String, Object>> grouped = new HashMap<>();
        for (Map<String, Object> source : sources) {
            String oid = (String) source.get("oid");
            String repo = (String) source.get("repo");
            String branch = (String) source.get("branch");
            String commit = (String) source.get("commit");
            String path = (String) source.get("path");
            String language = (String) source.get("language");
            
            String origin = repo + "@" + branch + ":" + path;
            Map<String, Object> item = grouped.get(oid);
            if (item == null) {
                item = new HashMap<>();
                item.put("blob", oid);
                item.put("repo", repo);
                item.put("commit", commit);
                item.put("path", path);
                item.put("sprache", language);
                item.put("herkunft", new ArrayList<String>());
                item.put("prioritaet", manager._prioritaet(path, language));
                grouped.put(oid, item);
            }
            @SuppressWarnings("unchecked")
            List<String> herkunft = (List<String>) item.get("herkunft");
            herkunft.add(origin);
        }

        List<Map<String, Object>> candidates = new ArrayList<>();
        for (Map<String, Object> item : grouped.values()) {
            if ("alle".equals(priority) || priority.equals(item.get("prioritaet"))) {
                candidates.add(item);
            }
        }

        candidates.sort((a, b) -> {
            Map<String, Integer> rank = new HashMap<>();
            rank.put("high", 0);
            rank.put("medium", 1);
            rank.put("low", 2);
            
            int priorityRankA = rank.get(a.get("prioritaet"));
            int priorityRankB = rank.get(b.get("prioritaet"));
            
            if (priorityRankA != priorityRankB) {
                return Integer.compare(priorityRankA, priorityRankB);
            }
            
            String nameA = new File((String) a.get("path")).getName();
            String nameB = new File((String) b.get("path")).getName();
            return nameA.compareTo(nameB);
        });

        @SuppressWarnings("unchecked")
        Map<String, Object> auswahlBlobCursor = (Map<String, Object>) 
            ((Map<String, Object>) state.getOrDefault("auswahl_blob_cursor", new HashMap<>())).getOrDefault(priority, new HashMap<>());
        
        String cursor = (String) auswahlBlobCursor.get("cursor");
        if (cursor != null && !cursor.isEmpty()) {
            int pos = -1;
            for (int i = 0; i < candidates.size(); i++) {
                if (cursor.equals(candidates.get(i).get("blob"))) {
                    pos = i;
                    break;
                }
            }
            if (pos != -1) {
                List<Map<String, Object>> temp = new ArrayList<>(candidates);
                candidates = new ArrayList<>();
                candidates.addAll(temp.subList(pos + 1, temp.size()));
                candidates.addAll(temp.subList(0, pos + 1));
            }
        }

        List<Map<String, Object>> selected = candidates.subList(0, Math.min(candidates.size(), count));

        Map<String, List<Map<String, Object>>> byRepo = new HashMap<>();
        for (Map<String, Object> item : selected) {
            String repo = (String) item.get("repo");
            byRepo.computeIfAbsent(repo, k -> new ArrayList<>()).add(item);
        }

        Map<String, byte[]> loaded = new HashMap<>();
        ExecutorService readExecutor = Executors.newFixedThreadPool(3);
        try {
            List<Callable<Map.Entry<String, byte[]>>> readTasks = new ArrayList<>();
            for (Map.Entry<String, List<Map<String, Object>>> entry : byRepo.entrySet()) {
                readTasks.add(() -> readBlobs(manager, entry.getKey(), entry.getValue()));
            }
            
            for (Future<Map.Entry<String, byte[]>> future : readExecutor.invokeAll(readTasks)) {
                Map.Entry<String, byte[]> result = future.get();
                if (result != null) {
                    loaded.put(result.getKey(), result.getValue());
                }
            }
        } finally {
            readExecutor.shutdown();
        }

        Path sourceDir = Paths.get(directory, "sources");
        sourceDir.toFile().mkdirs();
        Set<PosixFilePermission> dirPerms = PosixFilePermissions.fromString("rwx------");
        Files.setPosixFilePermissions(sourceDir, dirPerms);

        List<Map<String, Object>> inventory = new ArrayList<>();
        String lastBlob = null;
        for (Map<String, Object> item : selected) {
            String blob = (String) item.get("blob");
            byte[] raw = loaded.get(blob);
            if (raw != null && raw.length > 0 && !manager.enthaelt_zugangsdaten(raw)) {
                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                String hexDigest = bytesToHex(digest.digest(raw));
                
                Path target = sourceDir.resolve(hexDigest);
                if (!Files.exists(target)) {
                    writePrivate(target.toString(), raw);
                }
                
                String path = (String) item.get("path");
                String language = (String) item.get("sprache");
                String prio = (String) item.get("prioritaet");
                @SuppressWarnings("unchecked")
                List<String> herkunft = (List<String>) item.get("herkunft");
                
                Map<String, Object> invItem = new HashMap<>();
                invItem.put("hash", hexDigest.substring(0, 16));
                invItem.put("name", new File(path).getName());
                invItem.put("stamm", new File(path).getName().replaceFirst("[.][^.]+$", ""));
                invItem.put("sprache", language);
                invItem.put("bytes", raw.length);
                invItem.put("pfad", target.toString());
                invItem.put("herkunft", herkunft);
                invItem.put("prioritaet", prio);
                invItem.put("css_only", false);
                invItem.put("source_blob", blob);
                invItem.put("source_repo", item.get("repo"));
                invItem.put("source_commit", item.get("commit"));
                invItem.put("source_path", path);
                invItem.put("source_sha256", hexDigest);
                
                inventory.add(invItem);
                lastBlob = blob;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("index", index);
        result.put("inventory", inventory);
        result.put("lastBlob", lastBlob);
        return result;
    }

    private static void update(Manager manager, Source source) throws IOException, InterruptedException {
        String repo = source.repo;
        Path mirror = manager.QUELLEN_DIR.resolve(repo + ".git");
        ProcessResult result;
        
        if (Files.exists(mirror)) {
            result = manager._git(mirror, "remote", "update", "--prune");
        } else {
            String url = "https://github.com/" + manager.GITHUB_BENUTZER + "/" + repo + ".git";
            result = manager._git("clone", "--mirror", "--filter=blob:none", url, mirror.toString());
        }
        
        if (result.returncode != 0) {
            throw new RuntimeException(repo + ": Quellspiegel nicht verfuegbar");
        }
    }

    private static List<Map<String, Object>> listBranch(Manager manager, Object[] branchData) 
            throws IOException, InterruptedException {
        String repo = (String) branchData[0];
        String branch = (String) branchData[1];
        String commit = (String) branchData[2];
        
        Path mirror = manager.QUELLEN_DIR.resolve(repo + ".git");
        String lsTreeOutput = new String(manager._git(mirror, "ls-tree", "-r", "-z", "--full-tree", commit).stdout);
        String[] entries = lsTreeOutput.split("\0");
        
        List<Map<String, Object>> records = new ArrayList<>();
        for (String item : entries) {
            if (item.isEmpty()) continue;
            
            String[] parts = item.split("\t", 2);
            String metadata = parts[0];
            String rawPath = parts[1];
            
            String[] metaParts = metadata.split(" ", 3);
            if (metaParts.length != 3) continue;
            
            String mode = metaParts[0];
            String kind = metaParts[1];
            String oid = metaParts[2];
            
            if (!"blob".equals(kind) || (!"100644".equals(mode) && !"100755".equals(mode))) {
                continue;
            }
            
            String path = rawPath.replace("\\\\", "/");
            String extension = getFileExtension(path).toLowerCase();
            String language = manager.QUELLSPRACHEN.get(extension);
            
            boolean excluded = false;
            for (String pattern : manager.AUSSCHLUSS) {
                if (("/" + path).contains(pattern)) {
                    excluded = true;
                    break;
                }
            }
            
            if (language == null || excluded) {
                continue;
            }
            
            if (!oid.matches("[0-9a-f]{40}")) {
                throw new IllegalArgumentException("invalid Git blob identity");
            }
            
            Map<String, Object> record = new HashMap<>();
            record.put("repo", repo);
            record.put("branch", branch);
            record.put("commit", commit);
            record.put("path", path);
            record.put("language", language);
            record.put("oid", oid);
            records.add(record);
        }
        
        return records;
    }

    private static Map.Entry<String, byte[]> readBlobs(Manager manager, String repo, List<Map<String, Object>> items) 
            throws IOException, InterruptedException {
        Path mirror = manager.QUELLEN_DIR.resolve(repo + ".git");
        
        StringBuilder requested = new StringBuilder();
        for (Map<String, Object> item : items) {
            requested.append(item.get("blob")).append("\n");
        }
        
        String batchCheckOutput = new String(manager._git(mirror, "cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", 
                requested.toString()).stdout);
        String[] checks = batchCheckOutput.split("\n");
        
        if (checks.length != items.size()) {
            throw new IllegalArgumentException("incomplete Git blob metadata");
        }
        
        List<Map<String, Object>> eligible = new ArrayList<>();
        for (int i = 0; i < items.size(); i++) {
            Map<String, Object> item = items.get(i);
            String[] fields = checks[i].split(" ");
            if (fields.length != 3 || !fields[0].equals(item.get("blob")) || !"blob".equals(fields[1])) {
                throw new IllegalArgumentException("invalid Git blob metadata");
            }
            int size = Integer.parseInt(fields[2]);
            if (size <= manager.MAX_BYTES) {
                Map<String, Object> eligibleItem = new HashMap<>(item);
                eligibleItem.put("size", size);
                eligible.add(eligibleItem);
            }
        }
        
        if (eligible.isEmpty()) {
            return null;
        }
        
        StringBuilder wanted = new StringBuilder();
        for (Map<String, Object> item : eligible) {
            wanted.append(item.get("blob")).append("\n");
        }
        
        byte[] batchOutput = manager._git(mirror, "cat-file", "--batch", wanted.toString()).stdout;
        ByteArrayInputStream input = new ByteArrayInputStream(batchOutput);
        BufferedReader reader = new BufferedReader(new InputStreamReader(input));
        
        Map<String, byte[]> result = new HashMap<>();
        for (Map<String, Object> item : eligible) {
            String line = reader.readLine();
            if (line == null) {
                throw new IllegalArgumentException("invalid Git blob response");
            }
            
            String[] header = line.trim().split(" ");
            if (header.length != 3 || !header[0].equals(item.get("blob")) || !"blob".equals(header[1])) {
                throw new IllegalArgumentException("invalid Git blob response");
            }
            
            int expectedSize = Integer.parseInt(header[2]);
            int actualSize = (Integer) item.get("size");
            if (expectedSize != actualSize) {
                throw new IllegalArgumentException("invalid Git blob response");
            }
            
            byte[] raw = new byte[actualSize];
            int bytesRead = input.read(raw);
            if (bytesRead != actualSize || input.read() != '\n') {
                throw new IllegalArgumentException("incomplete Git blob response");
            }
            
            result.put((String) item.get("blob"), raw);
        }
        
        return new AbstractMap.SimpleEntry<>(repo, batchOutput);
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
