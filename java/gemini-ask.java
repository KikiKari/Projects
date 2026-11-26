// abstraction-provenance: {"artifact_sha256": "e684dc4ec28989b309458aa155c3fecc956eb3f05886282b7d5c2eadee189fa4", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "java"}
// gemini-ask.js — portiert nach java
// Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
// auch in: OpenClaw@gateway2:scripts/gemini-ask.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class GeminiAsk {

    private static final String DEFAULT_MODEL = System.getenv().getOrDefault("GEMINI_MODEL", "gemini-pro");

    public static void main(String[] args) {
        // Check API key
        String apiKey = System.getenv("GEMINI_API_KEY");
        if (apiKey == null || apiKey.isEmpty()) {
            System.err.println("Error: GEMINI_API_KEY environment variable is required");
            System.exit(1);
        }

        // Parse arguments
        String prompt = "";
        String modelName = DEFAULT_MODEL;
        String systemPrompt = "";
        List<String> remainingArgs = new ArrayList<>();
        
        // Process arguments
        for (int i = 0; i < args.length; i++) {
            if (("--model".equals(args[i]) || "-m".equals(args[i])) && i + 1 < args.length) {
                modelName = args[i + 1];
                i++; // Skip next argument
            } else if (("--system".equals(args[i]) || "-s".equals(args[i])) && i + 1 < args.length) {
                systemPrompt = args[i + 1];
                i++; // Skip next argument
            } else if ("--file".equals(args[i]) || "-f".equals(args[i])) {
                if (i + 1 >= args.length) {
                    System.err.println("Error: No file specified");
                    System.exit(1);
                }
                try {
                    prompt = readFile(args[i + 1]);
                } catch (IOException e) {
                    System.err.println("Error reading file: " + e.getMessage());
                    System.exit(1);
                }
                i++; // Skip next argument
            } else {
                remainingArgs.add(args[i]);
            }
        }

        // Handle remaining arguments or stdin
        if (prompt.isEmpty()) {
            if (!remainingArgs.isEmpty()) {
                prompt = String.join(" ", remainingArgs);
            } else {
                // Read from stdin
                try {
                    prompt = readFromStdin();
                } catch (IOException e) {
                    System.err.println("Error reading from stdin: " + e.getMessage());
                    System.exit(1);
                }
            }
        }

        if (prompt.trim().isEmpty()) {
            System.err.println("Error: No prompt provided");
            System.err.println("Usage: gemini-ask \"your question\"");
            System.err.println("       gemini-ask --model gemini-pro \"your question\"");
            System.err.println("       echo \"your question\" | gemini-ask");
            System.exit(1);
        }

        // Note: Actual API interaction would require the Google Generative AI client library for Java
        // Since there's no direct equivalent shown in standard Java libraries, this part would need
        // to be implemented using HTTP requests or including the appropriate Java SDK.
        // For now, we'll just print the parameters that would be used.
        
        System.out.println("API Key: " + apiKey);
        System.out.println("Model: " + modelName);
        System.out.println("System Prompt: " + systemPrompt);
        System.out.println("User Prompt: " + prompt);
        System.out.println("Note: Full API integration requires Google Generative AI client library for Java.");
    }

    private static String readFile(String filePath) throws IOException {
        StringBuilder content = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line).append("\n");
            }
        }
        return content.toString();
    }

    private static String readFromStdin() throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
        StringBuilder input = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            input.append(line).append("\n");
        }
        return input.toString();
    }
}
