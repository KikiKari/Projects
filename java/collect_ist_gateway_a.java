// abstraction-provenance: {"artifact_sha256": "de78e5c45769c3a547f4dfae6919a6975abe02e213a6e1dcdd4886385cbf6c8d", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "java"}
// collect_ist_gateway_a.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

public class CollectIstGatewayA {
    private static final String BASE_DIR = System.getProperty("user.home") + "/.openclaw";
    private static final String OUT_DIR = BASE_DIR + "/workspace/vscode";
    
    private final LocalDateTime nowUtc = LocalDateTime.now(ZoneOffset.UTC);
    private final LocalDateTime nowLocal = LocalDateTime.now();
    private final String ts = nowLocal.format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
    
    private final String istFile = OUT_DIR + "/IST-ZUSTAND_GATEWAY-A_NODE1.md";
    private final String invFile = OUT_DIR + "/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md";
    private final String cfgFile = OUT_DIR + "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md";
    private final String envFile = OUT_DIR + "/ENV-STATUS_GATEWAY-A_NODE1.md";
    private final String runFile = OUT_DIR + "/RUN-" + ts + ".md";
    
    private final String openclawJson = BASE_DIR + "/openclaw.json";
    private final String envDot = BASE_DIR + "/.env";
    private final String envSystemd = BASE_DIR + "/gateway.systemd.env";
    private final String vscodeDir = BASE_DIR + "/.vscode";
    
    private String hostnameFqdn;
    private String hostnameShort;
    private String arch;
    private String kernel;
    private String osPretty;
    private String ipv4All;
    private String publicIp;
    private String tailscaleIp;
    private String openclawVer;
    private String nodeVer;
    
    public static void main(String[] args) throws IOException, InterruptedException {
        new CollectIstGatewayA().run();
    }
    
    public void run() throws IOException, InterruptedException {
        createOutputDirectory();
        gatherSystemInfo();
        writeIstFile();
        writeInvFile();
        writeCfgFile();
        writeEnvFile();
        writeRunFile();
        printSummary();
    }
    
    private void createOutputDirectory() throws IOException {
        Files.createDirectories(Paths.get(OUT_DIR));
    }
    
    private void gatherSystemInfo() throws IOException, InterruptedException {
        hostnameFqdn = executeCommand("hostname -f");
        if (hostnameFqdn.isEmpty()) hostnameFqdn = executeCommand("hostname");
        hostnameShort = executeCommand("hostname");
        arch = executeCommand("uname -m");
        kernel = executeCommand("uname -r");
        osPretty = getOsPrettyName();
        ipv4All = executeCommand("hostname -I").trim();
        publicIp = executeCommandWithTimeout("curl -4 -s --max-time 4 ifconfig.me", 5000);
        tailscaleIp = executeCommand("tailscale ip -4").split("\\r?\\n")[0];
        openclawVer = executeCommand("openclaw --version");
        nodeVer = executeCommand("node -v");
        
        // Handle empty values
        if (publicIp.isEmpty()) publicIp = "(nicht ermittelt)";
        if (tailscaleIp.isEmpty()) tailscaleIp = "(nicht ermittelt)";
        if (openclawVer.isEmpty()) openclawVer = "(nicht ermittelt)";
        if (nodeVer.isEmpty()) nodeVer = "(nicht ermittelt)";
    }
    
    private String getOsPrettyName() {
        try {
            List<String> lines = Files.readAllLines(Paths.get("/etc/os-release"));
            for (String line : lines) {
                if (line.startsWith("PRETTY_NAME=")) {
                    return line.substring(13).replace("\"", "");
                }
            }
        } catch (IOException e) {
            // ignore
        }
        return "";
    }
    
    private void writeIstFile() throws IOException {
        StringBuilder content = new StringBuilder();
        content.append("# IST-Zustand: Gateway A / Node 1\n\n");
        content.append("Stand (lokal): ").append(formatDateTime(nowLocal)).append("  \n");
        content.append("Stand (UTC): ").append(formatDateTime(nowUtc)).append("\n\n");
        content.append("## 1) Identitaet & System\n\n");
        content.append("- Gateway: **A**\n");
        content.append("- Node: **1**\n");
        content.append("- Hostname (short): `").append(hostnameShort).append("`\n");
        content.append("- Hostname (FQDN): `").append(hostnameFqdn).append("`\n");
        content.append("- Architektur: `").append(arch).append("`\n");
        content.append("- Kernel: `").append(kernel).append("`\n");
        content.append("- OS: `").append(osPretty).append("`\n");
        content.append("- IPv4 (lokal): `").append(ipv4All).append("`\n");
        content.append("- Public IPv4: `").append(publicIp).append("`\n");
        content.append("- Tailscale IPv4: `").append(tailscaleIp).append("`\n");
        content.append("- OpenClaw Version: `").append(openclawVer).append("`\n");
        content.append("- Node.js Version: `").append(nodeVer).append("`\n\n");
        content.append("## 2) Arbeitsverzeichnisse\n\n");
        content.append("- Basis: `").append(BASE_DIR).append("`\n");
        content.append("- Funktionell VSCode: `").append(vscodeDir).append("`\n");
        content.append("- Workspace Doku: `").append(OUT_DIR).append("`\n\n");
        content.append("## 3) Kernartefakte (Existenz)\n\n");
        content.append("- `").append(openclawJson).append("`:");
        content.append(Files.exists(Paths.get(openclawJson)) ? " vorhanden\n" : " fehlt\n");
        content.append("- `").append(envDot).append("`:");
        content.append(Files.exists(Paths.get(envDot)) ? " vorhanden\n" : " fehlt\n");
        content.append("- `").append(envSystemd).append("`:");
        content.append(Files.exists(Paths.get(envSystemd)) ? " vorhanden\n" : " fehlt\n");
        content.append("- `").append(BASE_DIR).append("/plugins/installs.json`:");
        content.append(Files.exists(Paths.get(BASE_DIR, "plugins/installs.json")) ? " vorhanden\n" : " fehlt\n");
        content.append("- `").append(BASE_DIR).append("/plugin-skills`:");
        content.append(Files.exists(Paths.get(BASE_DIR, "plugin-skills")) ? " vorhanden\n" : " fehlt\n");
        
        Files.write(Paths.get(istFile), content.toString().getBytes());
    }
    
    private void writeInvFile() throws IOException {
        StringBuilder content = new StringBuilder();
        content.append("# Artefakt-Inventar: Gateway A / Node 1\n\n");
        content.append("Stand: ").append(formatDateTime(nowLocal)).append("\n\n");
        content.append("## Top-Level in ~/.openclaw\n\n");
        content.append("```\n");
        try {
            Files.list(Paths.get(BASE_DIR))
                 .map(path -> path.getFileName().toString())
                 .sorted()
                 .forEach(name -> content.append(name).append("\n"));
        } catch (IOException e) {
            // ignore
        }
        content.append("```\n\n");
        content.append("## ~/.openclaw/.vscode\n\n");
        content.append("```\n");
        if (Files.exists(Paths.get(vscodeDir))) {
            try {
                Files.list(Paths.get(vscodeDir))
                     .sorted()
                     .forEach(path -> {
                         try {
                             content.append(Files.getLastModifiedTime(path))
                                    .append(" ")
                                    .append(Files.size(path))
                                    .append(" ")
                                    .append(path.getFileName())
                                    .append("\n");
                         } catch (IOException e) {
                             // ignore
                         }
                     });
            } catch (IOException e) {
                // ignore
            }
        } else {
            content.append("(nicht vorhanden)\n");
        }
        content.append("```\n\n");
        content.append("## plugin-skills/\n\n");
        content.append("```\n");
        Path skillsPath = Paths.get(BASE_DIR, "plugin-skills");
        if (Files.exists(skillsPath)) {
            try {
                Files.list(skillsPath)
                     .map(path -> path.getFileName().toString())
                     .sorted()
                     .forEach(name -> content.append(name).append("\n"));
            } catch (IOException e) {
                // ignore
            }
        } else {
            content.append("(nicht vorhanden)\n");
        }
        content.append("```\n\n");
        content.append("## openclaw.json Backups\n\n");
        content.append("```\n");
        try {
            Files.list(Paths.get(BASE_DIR))
                 .filter(path -> path.getFileName().toString().startsWith("openclaw.json.bak"))
                 .map(path -> path.getFileName().toString())
                 .sorted()
                 .forEach(name -> content.append(name).append("\n"));
        } catch (IOException e) {
            content.append("(keine gefunden)\n");
        }
        content.append("```\n");
        
        Files.write(Paths.get(invFile), content.toString().getBytes());
    }
    
    private void writeCfgFile() throws IOException {
        StringBuilder content = new StringBuilder();
        content.append("# OpenClaw Config Snapshot: Gateway A / Node 1\n\n");
        content.append("Stand: ").append(formatDateTime(nowLocal)).append("\n\n");
        content.append("## Schluesselpositionen (grep)\n\n");
        content.append("```\n");
        if (Files.exists(Paths.get(openclawJson))) {
            try {
                List<String> lines = Files.readAllLines(Paths.get(openclawJson));
                for (int i = 0; i < lines.size(); i++) {
                    String line = lines.get(i);
                    if (line.contains("\"gateway\"") || 
                        line.contains("\"session\"") || 
                        line.contains("\"dmScope\"") || 
                        line.contains("\"auth\"") || 
                        line.contains("\"secrets\"") || 
                        line.contains("\"tools\"") || 
                        line.contains("\"plugins\"") || 
                        line.contains("\"profile\"") || 
                        line.contains("\"alsoAllow\"") || 
                        line.contains("\"denyCommands\"")) {
                        content.append((i + 1)).append(": ").append(line).append("\n");
                    }
                }
            } catch (IOException e) {
                // ignore
            }
        } else {
            content.append("openclaw.json fehlt\n");
        }
        content.append("```\n\n");
        content.append("## Ausschnitt gateway/session/auth\n\n");
        content.append("```json\n");
        if (Files.exists(Paths.get(openclawJson))) {
            try {
                List<String> lines = Files.readAllLines(Paths.get(openclawJson));
                int start = Math.max(0, 580 - 1);
                int end = Math.min(lines.size(), 780);
                for (int i = start; i < end; i++) {
                    content.append(lines.get(i)).append("\n");
                }
            } catch (IOException e) {
                // ignore
            }
        } else {
            content.append("{ \"error\": \"openclaw.json fehlt\" }\n");
        }
        content.append("```\n");
        
        Files.write(Paths.get(cfgFile), content.toString().getBytes());
    }
    
    private void writeEnvFile() throws IOException {
        StringBuilder content = new StringBuilder();
        content.append("# ENV-Status: Gateway A / Node 1\n\n");
        content.append("Stand: ").append(formatDateTime(nowLocal)).append("\n\n");
        content.append("## Dateien\n\n");
        content.append("```\n");
        try {
            if (Files.exists(Paths.get(envDot))) {
                content.append(Files.getLastModifiedTime(Paths.get(envDot)))
                       .append(" ")
                       .append(Files.size(Paths.get(envDot)))
                       .append(" ")
                       .append(".env")
                       .append("\n");
            }
            if (Files.exists(Paths.get(envSystemd))) {
                content.append(Files.getLastModifiedTime(Paths.get(envSystemd)))
                       .append(" ")
                       .append(Files.size(Paths.get(envSystemd)))
                       .append(" ")
                       .append("gateway.systemd.env")
                       .append("\n");
            }
        } catch (IOException e) {
            // ignore
        }
        content.append("```\n\n");
        content.append("## .env (vollstaendig)\n\n");
        content.append("```dotenv\n");
        if (Files.exists(Paths.get(envDot))) {
            content.append(Files.readString(Paths.get(envDot)));
        } else {
            content.append("# .env fehlt\n");
        }
        content.append("```\n\n");
        content.append("## gateway.systemd.env (vollstaendig)\n\n");
        content.append("```dotenv\n");
        if (Files.exists(Paths.get(envSystemd))) {
            content.append(Files.readString(Paths.get(envSystemd)));
        } else {
            content.append("# gateway.systemd.env fehlt\n");
        }
        content.append("```\n");
        
        Files.write(Paths.get(envFile), content.toString().getBytes());
    }
    
    private void writeRunFile() throws IOException {
        StringBuilder content = new StringBuilder();
        content.append("# Laufprotokoll Gateway A / Node 1\n\n");
        content.append("- Zeit (lokal): ").append(formatDateTime(nowLocal)).append("\n");
        content.append("- Zeit (UTC): ").append(formatDateTime(nowUtc)).append("\n");
        content.append("- Script: ").append(new File("").getAbsolutePath()).append("\n\n");
        content.append("## Erzeugte Dateien\n\n");
        content.append("- ").append(Paths.get(istFile).getFileName()).append("\n");
        content.append("- ").append(Paths.get(invFile).getFileName()).append("\n");
        content.append("- ").append(Paths.get(cfgFile).getFileName()).append("\n");
        content.append("- ").append(Paths.get(envFile).getFileName()).append("\n");
        
        Files.write(Paths.get(runFile), content.toString().getBytes());
    }
    
    private void printSummary() throws IOException {
        System.out.println("OK: IST-Zustand erfasst.");
        Files.list(Paths.get(OUT_DIR))
             .map(path -> "- " + path.getFileName().toString())
             .sorted()
             .forEach(System.out::println);
    }
    
    private String formatDateTime(LocalDateTime dateTime) {
        if (dateTime == nowUtc) {
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        } else {
            return dateTime.atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z"));
        }
    }
    
    private String executeCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(command);
            if (process.waitFor() == 0) {
                return new BufferedReader(new InputStreamReader(process.getInputStream()))
                    .lines()
                    .collect(Collectors.joining("\n"));
            }
        } catch (Exception e) {
            // ignore
        }
        return "";
    }
    
    private String executeCommandWithTimeout(String command, int timeoutMs) {
        try {
            Process process = Runtime.getRuntime().exec(command);
            if (process.waitFor(timeoutMs, TimeUnit.MILLISECONDS) && process.exitValue() == 0) {
                return new BufferedReader(new InputStreamReader(process.getInputStream()))
                    .lines()
                    .collect(Collectors.joining("\n"));
            }
        } catch (Exception e) {
            // ignore
        }
        return "";
    }
}
