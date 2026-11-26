// abstraction-provenance: {"artifact_sha256": "90bb6fc8c590375656dd1f456a1a10219118d21360c8753df3c7081cfe6178a6", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "java"}
// find-sessions.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class FindSessions {

    private static String socketName = "";
    private static String socketPath = "";
    private static String query = "";
    private static boolean scanAll = false;
    private static String socketDir = System.getenv("CLAWDBOT_TMUX_SOCKET_DIR");
    
    public static void main(String[] args) {
        if (socketDir == null) {
            String tmpDir = System.getenv("TMPDIR");
            if (tmpDir == null) {
                tmpDir = "/tmp";
            }
            socketDir = tmpDir + "/clawdbot-tmux-sockets";
        }

        parseArguments(args);

        if (scanAll && (!socketName.isEmpty() || !socketPath.isEmpty())) {
            System.err.println("Cannot combine --all with -L or -S");
            System.exit(1);
        }

        if (!socketName.isEmpty() && !socketPath.isEmpty()) {
            System.err.println("Use either -L or -S, not both");
            System.exit(1);
        }

        if (!isCommandAvailable("tmux")) {
            System.err.println("tmux not found in PATH");
            System.exit(1);
        }

        int exitCode = 0;
        if (scanAll) {
            exitCode = handleScanAll();
        } else {
            exitCode = handleSingleSocket();
        }
        
        System.exit(exitCode);
    }

    private static void usage() {
        System.out.print(
            "Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]\n\n" +
            "List tmux sessions on a socket (default tmux socket if none provided).\n\n" +
            "Options:\n" +
            "  -L, --socket       tmux socket name (passed to tmux -L)\n" +
            "  -S, --socket-path  tmux socket path (passed to tmux -S)\n" +
            "  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR\n" +
            "  -q, --query        case-insensitive substring to filter session names\n" +
            "  -h, --help         show this help\n"
        );
    }

    private static void parseArguments(String[] args) {
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-L":
                case "--socket":
                    if (i + 1 < args.length) {
                        socketName = args[++i];
                    }
                    break;
                case "-S":
                case "--socket-path":
                    if (i + 1 < args.length) {
                        socketPath = args[++i];
                    }
                    break;
                case "-A":
                case "--all":
                    scanAll = true;
                    break;
                case "-q":
                case "--query":
                    if (i + 1 < args.length) {
                        query = args[++i];
                    }
                    break;
                case "-h":
                case "--help":
                    usage();
                    System.exit(0);
                    break;
                default:
                    System.err.println("Unknown option: " + args[i]);
                    usage();
                    System.exit(1);
            }
        }
    }

    private static boolean isCommandAvailable(String command) {
        try {
            Process process = new ProcessBuilder("which", command).start();
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static int listSessions(String label, List<String> tmuxCmd) {
        List<String> command = new ArrayList<>(tmuxCmd);
        command.add("list-sessions");
        command.add("-F");
        command.add("#{session_name}\t#{session_attached}\t#{session_created_string}");

        try {
            Process process = new ProcessBuilder(command).start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            StringBuilder output = new StringBuilder();
            String line;
            
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
            
            int exitCode = process.waitFor();
            String sessions = output.toString().trim();
            
            if (exitCode != 0) {
                System.err.println("No tmux server found on " + label);
                return 1;
            }

            if (!query.isEmpty()) {
                sessions = filterSessions(sessions, query);
            }

            if (sessions.isEmpty()) {
                System.out.println("No sessions found on " + label);
                return 0;
            }

            System.out.println("Sessions on " + label + ":");
            String[] sessionLines = sessions.split("\n");
            for (String sessionLine : sessionLines) {
                if (!sessionLine.trim().isEmpty()) {
                    String[] parts = sessionLine.split("\t");
                    if (parts.length >= 3) {
                        String name = parts[0];
                        String attached = parts[1];
                        String created = parts[2];
                        String attachedLabel = "1".equals(attached) ? "attached" : "detached";
                        System.out.printf("  - %s (%s, started %s)%n", name, attachedLabel, created);
                    }
                }
            }
            return 0;
        } catch (Exception e) {
            System.err.println("Error listing sessions on " + label);
            return 1;
        }
    }

    private static String filterSessions(String sessions, String query) {
        StringBuilder result = new StringBuilder();
        String[] lines = sessions.split("\n");
        for (String line : lines) {
            if (line.toLowerCase().contains(query.toLowerCase())) {
                result.append(line).append("\n");
            }
        }
        return result.toString().trim();
    }

    private static int handleScanAll() {
        File dir = new File(socketDir);
        if (!dir.exists() || !dir.isDirectory()) {
            System.err.println("Socket directory not found: " + socketDir);
            return 1;
        }

        File[] sockets = dir.listFiles();
        if (sockets == null || sockets.length == 0) {
            System.err.println("No sockets found under " + socketDir);
            return 1;
        }

        int exitCode = 0;
        for (File sock : sockets) {
            if (sock.exists() && sock.isFile()) {
                List<String> cmd = new ArrayList<>();
                cmd.add("tmux");
                cmd.add("-S");
                cmd.add(sock.getAbsolutePath());
                int result = listSessions("socket path '" + sock.getAbsolutePath() + "'", cmd);
                if (result != 0) {
                    exitCode = result;
                }
            }
        }
        return exitCode;
    }

    private static int handleSingleSocket() {
        List<String> tmuxCmd = new ArrayList<>();
        tmuxCmd.add("tmux");
        String socketLabel = "default socket";

        if (!socketName.isEmpty()) {
            tmuxCmd.add("-L");
            tmuxCmd.add(socketName);
            socketLabel = "socket name '" + socketName + "'";
        } else if (!socketPath.isEmpty()) {
            tmuxCmd.add("-S");
            tmuxCmd.add(socketPath);
            socketLabel = "socket path '" + socketPath + "'";
        }

        return listSessions(socketLabel, tmuxCmd);
    }
}
