// abstraction-provenance: {"artifact_sha256": "62c5bf7768fd9f937a8c70a625759ee3a1088e0b03e977c9713de17ed3e9df73", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "java"}
// collect_ist_gateway_b.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class CollectIstGatewayB {
    private static final String BASE_DIR = System.getProperty("user.home") + "/.openclaw";
    private static final String OUT_DIR = BASE_DIR + "/workspace/vscode";
    
    private final String NOW_UTC;
    private final String NOW_LOCAL;
    private final String TS;
    
    private final String IST_FILE;
    private final String INV_FILE;
    private final String CFG_FILE;
    private final String ENV_FILE;
    private final String RUN_FILE;
    
    private final String OPENCLAW_JSON;
    private final String ENV_DOT;
    private final String ENV_SYSTEMD;
    private final String VSCODE_DIR;
    
    private String HOSTNAME_FQDN;
    private String HOSTNAME_SHORT;
    private String ARCH;
    private String KERNEL;
    private String OS_PRETTY;
    private String IPV4_ALL;
    private String PUBLIC_IP;
    private String TAILSCALE_IP;
    private String OPENCLAW_VER;
    private String NODE_VER;

    public CollectIstGatewayB() {
        ZonedDateTime nowUtc = ZonedDateTime.now(ZoneOffset.UTC);
        ZonedDateTime nowLocal = ZonedDateTime.now();
        
        NOW_UTC = nowUtc.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        NOW_LOCAL = nowLocal.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z"));
        TS = nowLocal.format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
        
        IST_FILE = OUT_DIR + "/IST-ZUSTAND_GATEWAY-B_NODE7.md";
        INV_FILE = OUT_DIR + "/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md";
        CFG_FILE = OUT_DIR + "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md";
        ENV_FILE = OUT_DIR + "/ENV-STATUS_GATEWAY-B_NODE7.md";
        RUN_FILE = OUT_DIR + "/RUN-" + TS + ".md";
        
        OPENCLAW_JSON = BASE_DIR + "/openclaw.json";
        ENV_DOT = BASE_DIR + "/.env";
        ENV_SYSTEMD = BASE_DIR + "/gateway.systemd.env";
        VSCODE_DIR = BASE_DIR + "/.vscode";
        
        gatherSystemInfo();
    }

    private void gatherSystemInfo() {
        try {
            HOSTNAME_FQDN = executeCommand("hostname -f");
            if (HOSTNAME_FQDN.isEmpty()) {
                HOSTNAME_FQDN = executeCommand("hostname");
            }
        } catch (Exception e) {
            HOSTNAME_FQDN = executeCommand("hostname");
        }
        
        try {
            HOSTNAME_SHORT = executeCommand("hostname");
        } catch (Exception e) {
            HOSTNAME_SHORT = "unknown";
        }
        
        try {
            ARCH = executeCommand("uname -m");
        } catch (Exception e) {
            ARCH = "unknown";
        }
        
        try {
            KERNEL = executeCommand("uname -r");
        } catch (Exception e) {
            KERNEL = "unknown";
        }
        
        try {
            OS_PRETTY = getOsPrettyName();
        } catch (Exception e) {
            OS_PRETTY = "unknown";
        }
        
        try {
            IPV4_ALL = executeCommand("hostname -I").trim();
        } catch (Exception e) {
            IPV4_ALL = "";
        }
        
        try {
            PUBLIC_IP = executeCommand("curl -4 -s --max-time 4 ifconfig.me");
        } catch (Exception e) {
            PUBLIC_IP = "";
        }
        
        try {
            TAILSCALE_IP = executeCommand("tailscale ip -4").split("\\n")[0];
        } catch (Exception e) {
            TAILSCALE_IP = "";
        }
        
        try {
            OPENCLAW_VER = executeCommand("openclaw --version");
        } catch (Exception e) {
            OPENCLAW_VER = "";
        }
        
        try {
            NODE_VER = executeCommand("node -v");
        } catch (Exception e) {
            NODE_VER = "";
        }
        
        if (PUBLIC_IP.isEmpty()) {
            PUBLIC_IP = "(nicht ermittelt)";
        }
        if (TAILSCALE_IP.isEmpty()) {
            TAILSCALE_IP = "(nicht ermittelt)";
        }
        if (OPENCLAW_VER.isEmpty()) {
            OPENCLAW_VER = "(nicht ermittelt)";
        }
        if (NODE_VER.isEmpty()) {
            NODE_VER = "(nicht ermittelt)";
        }
    }

    private String getOsPrettyName() throws IOException {
        List<String> lines = Files.readAllLines(Paths.get("/etc/os-release"));
        for (String line : lines) {
            if (line.startsWith("PRETTY_NAME=")) {
                return line.substring(13).replace("\"", "");
            }
        }
        return "";
    }

    private String executeCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"/bin/sh", "-c", command});
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            StringBuilder output = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
            process.destroy();
            return output.toString().trim();
        } catch (Exception e) {
            return "";
        }
    }

    private void createDirectories() throws IOException {
        Files.createDirectories(Paths.get(OUT_DIR));
    }

    private void writeIstFile() throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(IST_FILE))) {
            writer.println("# IST-Zustand: Gateway B / Node 7");
            writer.println();
            writer.println("Stand (lokal): " + NOW_LOCAL + "  ");
            writer.println("Stand (UTC): " + NOW_UTC);
            writer.println();
            writer.println("## 1) Identität & System");
            writer.println();
            writer.println("- Gateway: **B**");
            writer.println("- Node: **7**");
            writer.println("- Hostname (short): `" + HOSTNAME_SHORT + "`");
            writer.println("- Hostname (FQDN): `" + HOSTNAME_FQDN + "`");
            writer.println("- Architektur: `" + ARCH + "`");
            writer.println("- Kernel: `" + KERNEL + "`");
            writer.println("- OS: `" + OS_PRETTY + "`");
            writer.println("- IPv4 (lokal): `" + IPV4_ALL + "`");
            writer.println("- Public IPv4: `" + PUBLIC_IP + "`");
            writer.println("- Tailscale IPv4: `" + TAILSCALE_IP + "`");
            writer.println("- OpenClaw Version: `" + OPENCLAW_VER + "`");
            writer.println("- Node.js Version: `" + NODE_VER + "`");
            writer.println();
            writer.println("## 2) Arbeitsverzeichnisse");
            writer.println();
            writer.println("- Basis: `" + BASE_DIR + "`");
            writer.println("- Funktionell VSCode: `" + VSCODE_DIR + "`");
            writer.println("- Workspace Doku: `" + OUT_DIR + "`");
            writer.println();
            writer.println("## 3) Kernartefakte (Existenz)");
            writer.println();
            writer.println("- `" + OPENCLAW_JSON + "`: " + (Files.exists(Paths.get(OPENCLAW_JSON)) ? "vorhanden" : "fehlt"));
            writer.println("- `" + ENV_DOT + "`: " + (Files.exists(Paths.get(ENV_DOT)) ? "vorhanden" : "fehlt"));
            writer.println("- `" + ENV_SYSTEMD + "`: " + (Files.exists(Paths.get(ENV_SYSTEMD)) ? "vorhanden" : "fehlt"));
            writer.println("- `" + BASE_DIR + "/plugins/installs.json`: " + 
                          (Files.exists(Paths.get(BASE_DIR, "plugins/installs.json")) ? "vorhanden" : "fehlt"));
            writer.println("- `" + BASE_DIR + "/plugin-skills`: " + 
                          (Files.exists(Paths.get(BASE_DIR, "plugin-skills")) ? "vorhanden" : "fehlt"));
            writer.println();
            writer.println("## 4) Hinweis");
            writer.println();
            writer.println("Diese Datei wird bei jedem Lauf neu geschrieben.");
            writer.println("Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.");
        }
    }

    private void writeInvFile() throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(INV_FILE))) {
            writer.println("# Artefakt-Inventar: Gateway B / Node 7");
            writer.println();
            writer.println("Stand: " + NOW_LOCAL);
            writer.println();
            writer.println("## Top-Level in ~/.openclaw");
            writer.println();
            writer.println("```text");
            
            try {
                File baseDir = new File(BASE_DIR);
                if (baseDir.exists() && baseDir.isDirectory()) {
                    File[] files = baseDir.listFiles();
                    if (files != null) {
                        Arrays.sort(files);
                        for (File file : files) {
                            writer.println(file.getName());
                        }
                    }
                }
            } catch (Exception e) {
                // Ignore
            }
            
            writer.println("```");
            writer.println();
            writer.println("## ~/.openclaw/.vscode");
            writer.println();
            writer.println("```text");
            
            try {
                File vscodeDir = new File(VSCODE_DIR);
                if (vscodeDir.exists() && vscodeDir.isDirectory()) {
                    File[] files = vscodeDir.listFiles();
                    if (files != null) {
                        Arrays.sort(files, (f1, f2) -> {
                            if (f1.isDirectory() && !f2.isDirectory()) return -1;
                            if (!f1.isDirectory() && f2.isDirectory()) return 1;
                            return f1.getName().compareTo(f2.getName());
                        });
                        
                        for (File file : files) {
                            String perms = file.canRead() ? "r" : "-";
                            perms += file.canWrite() ? "w" : "-";
                            perms += file.canExecute() ? "x" : "-";
                            long size = file.length();
                            String type = file.isDirectory() ? "d" : "f";
                            writer.println(perms + " " + size + " " + type + " " + file.getName());
                        }
                    }
                } else {
                    writer.println("(nicht vorhanden)");
                }
            } catch (Exception e) {
                writer.println("(nicht vorhanden)");
            }
            
            writer.println("```");
            writer.println();
            writer.println("## plugin-skills/");
            writer.println();
            writer.println("```text");
            
            try {
                File skillsDir = new File(BASE_DIR, "plugin-skills");
                if (skillsDir.exists() && skillsDir.isDirectory()) {
                    File[] files = skillsDir.listFiles();
                    if (files != null) {
                        Arrays.sort(files);
                        for (File file : files) {
                            writer.println(file.getName());
                        }
                    }
                } else {
                    writer.println("(nicht vorhanden)");
                }
            } catch (Exception e) {
                writer.println("(nicht vorhanden)");
            }
            
            writer.println("```");
            writer.println();
            writer.println("## openclaw.json Backups");
            writer.println();
            writer.println("```text");
            
            try {
                File baseDir = new File(BASE_DIR);
                File[] backupFiles = baseDir.listFiles((dir, name) -> name.startsWith("openclaw.json.bak"));
                if (backupFiles != null && backupFiles.length > 0) {
                    Arrays.sort(backupFiles);
                    for (File file : backupFiles) {
                        writer.println(file.getName());
                    }
                } else {
                    writer.println("(keine gefunden)");
                }
            } catch (Exception e) {
                writer.println("(keine gefunden)");
            }
            
            writer.println("```");
        }
    }

    private void writeCfgFile() throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(CFG_FILE))) {
            writer.println("# OpenClaw Config Snapshot: Gateway B / Node 7");
            writer.println();
            writer.println("Stand: " + NOW_LOCAL);
            writer.println();
            writer.println("## Schlüsselpositionen (grep)");
            writer.println();
            writer.println("```text");
            
            try {
                if (Files.exists(Paths.get(OPENCLAW_JSON))) {
                    Process process = Runtime.getRuntime().exec(
                        new String[]{"grep", "-nE", 
                            "\"gateway\"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"", 
                            OPENCLAW_JSON});
                    BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                    String line;
                    while ((line = reader.readLine()) != null) {
                        writer.println(line);
                    }
                    process.destroy();
                } else {
                    writer.println("openclaw.json fehlt");
                }
            } catch (Exception e) {
                writer.println("openclaw.json fehlt");
            }
            
            writer.println("```");
            writer.println();
            writer.println("## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)");
            writer.println();
            writer.println("```json");
            
            try {
                if (Files.exists(Paths.get(OPENCLAW_JSON))) {
                    List<String> lines = Files.readAllLines(Paths.get(OPENCLAW_JSON));
                    int start = Math.min(579, lines.size() - 1);
                    int end = Math.min(779, lines.size() - 1);
                    
                    for (int i = start; i <= end && i < lines.size(); i++) {
                        writer.println(lines.get(i));
                    }
                } else {
                    writer.println("{ \"error\": \"openclaw.json fehlt\" }");
                }
            } catch (Exception e) {
                writer.println("{ \"error\": \"openclaw.json fehlt\" }");
            }
            
            writer.println("```");
        }
    }

    private void writeEnvFile() throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(ENV_FILE))) {
            writer.println("# ENV-Status: Gateway B / Node 7");
            writer.println();
            writer.println("Stand: " + NOW_LOCAL);
            writer.println();
            writer.println("## Dateien");
            writer.println();
            writer.println("```text");
            
            try {
                File envDot = new File(ENV_DOT);
                File envSystemd = new File(ENV_SYSTEMD);
                
                if (envDot.exists()) {
                    String perms = envDot.canRead() ? "r" : "-";
                    perms += envDot.canWrite() ? "w" : "-";
                    perms += envDot.canExecute() ? "x" : "-";
                    long size = envDot.length();
                    writer.println(perms + " " + size + " f " + envDot.getName());
                }
                
                if (envSystemd.exists()) {
                    String perms = envSystemd.canRead() ? "r" : "-";
                    perms += envSystemd.canWrite() ? "w" : "-";
                    perms += envSystemd.canExecute() ? "x" : "-";
                    long size = envSystemd.length();
                    writer.println(perms + " " + size + " f " + envSystemd.getName());
                }
            } catch (Exception e) {
                // Ignore
            }
            
            writer.println("```");
            writer.println();
            writer.println("## .env (vollständig, ungefiltert)");
            writer.println();
            writer.println("```dotenv");
            
            try {
                if (Files.exists(Paths.get(ENV_DOT))) {
                    List<String> lines = Files.readAllLines(Paths.get(ENV_DOT));
                    for (String line : lines) {
                        writer.println(line);
                    }
                } else {
                    writer.println("# .env fehlt");
                }
            } catch (Exception e) {
                writer.println("# .env fehlt");
            }
            
            writer.println("```");
            writer.println();
            writer.println("## gateway.systemd.env (vollständig, ungefiltert)");
            writer.println();
            writer.println("```dotenv");
            
            try {
                if (Files.exists(Paths.get(ENV_SYSTEMD))) {
                    List<String> lines = Files.readAllLines(Paths.get(ENV_SYSTEMD));
                    for (String line : lines) {
                        writer.println(line);
                    }
                } else {
                    writer.println("# gateway.systemd.env fehlt");
                }
            } catch (Exception e) {
                writer.println("# gateway.systemd.env fehlt");
            }
            
            writer.println("```");
        }
    }

    private void writeRunFile() throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(RUN_FILE))) {
            writer.println("# Laufprotokoll Gateway B / Node 7");
            writer.println();
            writer.println("- Zeit (lokal): " + NOW_LOCAL);
            writer.println("- Zeit (UTC): " + NOW_UTC);
            writer.println("- Script: " + new File("").getAbsolutePath() + "/CollectIstGatewayB.java");
            writer.println();
            writer.println("## Erzeugte Dateien");
            writer.println();
            writer.println("- " + new File(IST_FILE).getName());
            writer.println("- " + new File(INV_FILE).getName());
            writer.println("- " + new File(CFG_FILE).getName());
            writer.println("- " + new File(ENV_FILE).getName());
        }
    }

    private void printSummary() {
        System.out.println("OK: IST-Zustand erfasst.");
        System.out.println("Ausgabeordner: " + OUT_DIR);
        System.out.println("Dateien:");
        
        try {
            File outDir = new File(OUT_DIR);
            if (outDir.exists() && outDir.isDirectory()) {
                File[] files = outDir.listFiles();
                if (files != null) {
                    Arrays.sort(files);
                    for (File file : files) {
                        System.out.println("- " + file.getName());
                    }
                }
            }
        } catch (Exception e) {
            // Ignore
        }
    }

    public void run() throws IOException {
        createDirectories();
        writeIstFile();
        writeInvFile();
        writeCfgFile();
        writeEnvFile();
        writeRunFile();
        printSummary();
    }

    public static void main(String[] args) {
        try {
            new CollectIstGatewayB().run();
        } catch (Exception e) {
            System.err.println("Fehler: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
