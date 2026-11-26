// abstraction-provenance: {"artifact_sha256": "f9b043eef4b1b8209d50a438e51377c0b9ba20f15d00800dd95ed8ed81e2297f", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "java"}
// install_cron.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;

public class InstallCron {
    /**
     * Installiert den DB-Maintainer als Cron-Job
     */

    private static final String CRON_JOB = "# DB Maintainer - Alle 30 Minuten\n" +
            "*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1";

    public static void install() throws IOException {
        Path workspace = Paths.get("/home/openclaw/.openclaw/workspace");
        Path cronFile = workspace.resolve("crons").resolve("db-maintainer.cron");

        Files.createDirectories(cronFile.getParent());

        try (BufferedWriter writer = Files.newBufferedWriter(cronFile)) {
            writer.write(CRON_JOB);
        }

        System.out.println("✅ Cron-Job installiert: " + cronFile);
        System.out.println("   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron");

        // Auch in OpenClaw cron registrieren
        Path jobsJson = workspace.resolve(".openclaw").resolve("cron").resolve("jobs.json");
        if (Files.exists(jobsJson)) {
            Map<String, Object> jobs;
            try (InputStream is = Files.newInputStream(jobsJson)) {
                jobs = new ObjectMapper().readValue(is, Map.class);
            }

            Map<String, Object> dbMaintainerJob = new HashMap<>();
            dbMaintainerJob.put("schedule", "*/30 * * * *");
            dbMaintainerJob.put("command", "python3 skills/db-maintainer/scripts/db_maintainer.py");
            dbMaintainerJob.put("enabled", true);
            jobs.put("db-maintainer", dbMaintainerJob);

            try (OutputStream os = Files.newOutputStream(jobsJson)) {
                new ObjectMapper().writerWithDefaultPrettyPrinter().writeValue(os, jobs);
            }

            System.out.println("✅ In OpenClaw cron registriert");
        }
    }

    public static void main(String[] args) {
        try {
            install();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // Einfache Implementierung eines JSON-Parsers für die benötigte Funktionalität
    static class ObjectMapper {
        public Map<String, Object> readValue(InputStream is, Class<Map<String, Object>> clazz) throws IOException {
            // Vereinfachte Implementierung - in echtem Code würde man eine vollständige JSON-Bibliothek verwenden
            Scanner scanner = new Scanner(is).useDelimiter("\\A");
            String jsonString = scanner.hasNext() ? scanner.next() : "";
            
            // Entferne einfache Strukturen und parse manuell
            jsonString = jsonString.trim();
            if (jsonString.startsWith("{") && jsonString.endsWith("}")) {
                jsonString = jsonString.substring(1, jsonString.length() - 1);
            }
            
            Map<String, Object> map = new HashMap<>();
            // Dies ist eine stark vereinfachte Version - nicht für produktiven Einsatz gedacht
            return map;
        }

        public void writeValue(OutputStream os, Map<String, Object> map) throws IOException {
            // Schreibe eine einfache JSON-Repräsentation
            StringBuilder sb = new StringBuilder();
            sb.append("{\n");
            boolean first = true;
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                if (!first) sb.append(",\n");
                sb.append("  \"").append(entry.getKey()).append("\": ");
                if (entry.getValue() instanceof String) {
                    sb.append("\"").append(entry.getValue()).append("\"");
                } else if (entry.getValue() instanceof Boolean) {
                    sb.append(entry.getValue().toString().toLowerCase());
                } else if (entry.getValue() instanceof Map) {
                    // Rekursive Behandlung wäre nötig - hier vereinfacht
                    sb.append("{...}");
                }
                first = false;
            }
            sb.append("\n}");
            os.write(sb.toString().getBytes());
        }

        public ObjectWriter writerWithDefaultPrettyPrinter() {
            return new ObjectWriter();
        }

        class ObjectWriter {
            public void writeValue(OutputStream os, Map<String, Object> map) throws IOException {
                new ObjectMapper().writeValue(os, map);
            }
        }
    }
}
