// abstraction-provenance: {"artifact_sha256": "f9950188b84b8c822b2d00e8d05e02b61946f8e5743d51bad762289df4bced14", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "java"}
// frame.sh — portiert nach java
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class Frame {
    
    private static void usage() {
        System.err.println("Usage:");
        System.err.println("  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg");
        System.err.println();
        System.err.println("Examples:");
        System.err.println("  frame.sh video.mp4 --out /tmp/frame.jpg");
        System.err.println("  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg");
        System.err.println("  frame.sh video.mp4 --index 0 --out /tmp/frame0.png");
        System.exit(2);
    }
    
    public static void main(String[] args) {
        if (args.length == 0 || args[0].equals("-h") || args[0].equals("--help")) {
            usage();
        }
        
        String in = args[0];
        String time = "";
        String index = "";
        String out = "";
        
        int i = 1;
        while (i < args.length) {
            switch (args[i]) {
                case "--time":
                    if (i + 1 >= args.length) {
                        System.err.println("Missing value for --time");
                        usage();
                    }
                    time = args[i + 1];
                    i += 2;
                    break;
                case "--index":
                    if (i + 1 >= args.length) {
                        System.err.println("Missing value for --index");
                        usage();
                    }
                    index = args[i + 1];
                    i += 2;
                    break;
                case "--out":
                    if (i + 1 >= args.length) {
                        System.err.println("Missing value for --out");
                        usage();
                    }
                    out = args[i + 1];
                    i += 2;
                    break;
                default:
                    System.err.println("Unknown arg: " + args[i]);
                    usage();
                    break;
            }
        }
        
        File inFile = new File(in);
        if (!inFile.exists()) {
            System.err.println("File not found: " + in);
            System.exit(1);
        }
        
        if (out.isEmpty()) {
            System.err.println("Missing --out");
            usage();
        }
        
        // Create output directory
        try {
            Files.createDirectories(Paths.get(out).getParent());
        } catch (IOException e) {
            System.err.println("Failed to create output directory: " + e.getMessage());
            System.exit(1);
        }
        
        try {
            ProcessBuilder processBuilder;
            if (!index.isEmpty()) {
                processBuilder = new ProcessBuilder(
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", in,
                    "-vf", "select=eq(n\\," + index + ")",
                    "-vframes", "1",
                    out
                );
            } else if (!time.isEmpty()) {
                processBuilder = new ProcessBuilder(
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-ss", time,
                    "-i", in,
                    "-frames:v", "1",
                    out
                );
            } else {
                processBuilder = new ProcessBuilder(
                    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-i", in,
                    "-vf", "select=eq(n\\,0)",
                    "-vframes", "1",
                    out
                );
            }
            
            Process process = processBuilder.start();
            int exitCode = process.waitFor();
            
            if (exitCode != 0) {
                // Read error output
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
                String line;
                while ((line = reader.readLine()) != null) {
                    System.err.println(line);
                }
                System.exit(exitCode);
            }
            
            System.out.println(out);
            
        } catch (IOException | InterruptedException e) {
            System.err.println("Error executing ffmpeg: " + e.getMessage());
            System.exit(1);
        }
    }
}
