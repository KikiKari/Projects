// abstraction-provenance: {"artifact_sha256": "ec40ac2509334a5e4d65c1106cedeb6d5dfa813308f3d9573c2ad1cd61c2aed3", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "java"}
// openclaw-node-autostart-termux.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class OpenClawNodeAutostart {

    private static final String SESSION = "openclaw-node";
    private static final String LOGFILE = System.getProperty("user.home") + "/.openclaw/node.log";
    private static final String GATEWAY = "10.10.0.1";
    private static final String PORT = "18789";

    public static void main(String[] args) {
        try {
            // Log-Verzeichnis erstellen
            Path logDir = Paths.get(System.getProperty("user.home"), ".openclaw");
            Files.createDirectories(logDir);

            // Prüfen ob tmux Session bereits läuft (Simulation)
            if (isTmuxSessionRunning(SESSION)) {
                logMessage("OpenClaw Node läuft bereits in tmux Session '" + SESSION + "'");
                return;
            }

            // Neue tmux Session erstellen und OpenClaw starten (Simulation)
            startOpenClawNode();

            logMessage("OpenClaw Node Autostart aktiviert (tmux Session: " + SESSION + ")");

            // Optional: Hinweis falls interaktiv gestartet
            if (System.console() != null) {
                System.out.println("OpenClaw Node Mode gestartet in tmux Session '" + SESSION + "'");
                System.out.println("Zum Anschauen: tmux attach -t " + SESSION);
                System.out.println("Log-Datei: " + LOGFILE);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static boolean isTmuxSessionRunning(String sessionName) {
        try {
            Process process = new ProcessBuilder("tmux", "has-session", "-t", sessionName)
                    .redirectError(new File("/dev/null"))
                    .start();
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static void startOpenClawNode() {
        Thread thread = new Thread(() -> {
            try {
                while (true) {
                    logMessage("Starting OpenClaw Node Mode...");

                    // Prüfe WireGuard Verbindung
                    if (!isGatewayReachable(GATEWAY)) {
                        logMessage("FEHLER: WireGuard Gateway " + GATEWAY + " nicht erreichbar!");
                        logMessage("Warte 10 Sekunden...");
                        Thread.sleep(10000);
                        continue;
                    }

                    // OpenClaw Node Mode starten
                    Process process = new ProcessBuilder("openclaw", "node", "run", "--host", GATEWAY, "--port", PORT)
                            .inheritIO()
                            .start();
                    process.waitFor();

                    // Wenn der Prozess endet, warte und neustarten
                    logMessage("OpenClaw beendet. Neustart in 5 Sekunden...");
                    Thread.sleep(5000);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
        thread.setDaemon(true);
        thread.start();
    }

    private static boolean isGatewayReachable(String gateway) {
        try {
            Process process = new ProcessBuilder("ping", "-c", "1", "-W", "3", gateway)
                    .redirectOutput(new File("/dev/null"))
                    .redirectError(new File("/dev/null"))
                    .start();
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static void logMessage(String message) {
        try {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            String logEntry = "[" + timestamp + "] " + message + "\n";
            
            Files.write(
                Paths.get(LOGFILE), 
                logEntry.getBytes(), 
                StandardOpenOption.CREATE, 
                StandardOpenOption.APPEND
            );
            
            // Auch auf Konsole ausgeben wenn interaktiv
            if (System.console() != null) {
                System.out.print(logEntry);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
