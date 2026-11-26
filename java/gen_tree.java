// abstraction-provenance: {"artifact_sha256": "d9744486c8974dcf1cb55393e70f5b80db2cce7a3259209b6029fbb51e922ab8", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "java"}
// gen_tree.py — portiert nach java
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class GenTree {
    private static final String ROOT = "/workspace";
    private static final String OUT = "/workspace/important/openclaw-tree.txt";
    private static final int MAX_DEPTH = 6;

    public static void main(String[] args) {
        List<String> body = collect(ROOT, "", 1);
        String header = 
            "# OpenClaw Workspace Tree\n" +
            "# Generiert: " + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) + "\n" +
            "# Befehl: tree -a -L 6 " + ROOT + " (emuliert via gen_tree.java)\n" +
            "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
        String content = header + ".\n" + String.join("\n", body) + "\n";

        try {
            Files.write(Paths.get(OUT), content.getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }

        System.out.println("written " + OUT + ": " + (body.size() + 1) + " lines, " + content.length() + " bytes");
    }

    private static List<String> collect(String path, String prefix, int depth) {
        List<String> lines = new ArrayList<>();
        File dir = new File(path);
        
        if (!dir.exists() || !dir.isDirectory()) {
            return lines;
        }
        
        File[] entriesArray = dir.listFiles();
        if (entriesArray == null) {
            return lines;
        }
        
        Arrays.sort(entriesArray, (a, b) -> a.getName().compareTo(b.getName()));
        List<File> entries = Arrays.asList(entriesArray);
        int total = entries.size();
        
        for (int i = 0; i < total; i++) {
            File entry = entries.get(i);
            boolean isLast = (i == total - 1);
            String connector = isLast ? "└── " : "├── ";
            lines.add(prefix + connector + entry.getName());
            
            if (depth < MAX_DEPTH && entry.isDirectory() && !Files.isSymbolicLink(entry.toPath())) {
                String nextPrefix = prefix + (isLast ? "    " : "│   ");
                lines.addAll(collect(entry.getAbsolutePath(), nextPrefix, depth + 1));
            }
        }
        
        return lines;
    }
}
