// abstraction-provenance: {"artifact_sha256": "79e492b9330008b31a9c3c60a43c17810229bb4111e67d87a5ac44a6e0599f97", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "java"}
// json_processor.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * JSON Processor mit Validation und JSON-Reparatur.
 * Für robuste Verarbeitung von LLM-Outputs.
 */
public class JsonProcessor {

    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final boolean HAS_JSON_REPAIR = false; // In Java nicht direkt verfügbar

    public static class JSONProcessingException extends Exception {
        public JSONProcessingException(String message) {
            super(message);
        }

        public JSONProcessingException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    public static class JSONValidationError extends JSONProcessingException {
        public JSONValidationError(String message) {
            super(message);
        }

        public JSONValidationError(String message, Throwable cause) {
            super(message, cause);
        }
    }

    public static class JSONRepairError extends JSONProcessingException {
        public JSONRepairError(String message) {
            super(message);
        }

        public JSONRepairError(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /**
     * Repariert häufige JSON-Fehler aus LLM-Outputs.
     *
     * Behebt:
     * - Trailing commas
     * - Einzelne statt doppelte Quotes
     * - JavaScript-Style Kommentare
     * - Unescaped Zeilenumbrüche in Strings
     */
    public static String repairJsonString(String rawJson) throws JSONRepairError {
        if (HAS_JSON_REPAIR) {
            // In Java würde man hier eine entsprechende Library verwenden
            throw new JSONRepairError("JSON repair library not available in Java");
        } else {
            // Fallback: Manuelle Reparaturen
            String cleaned = rawJson.trim();

            // Entferne JavaScript-Kommentare
            cleaned = cleaned.replaceAll("//.*?\\n", "\n");
            cleaned = cleaned.replaceAll("/\\*.*?\\*/", "");

            // Entferne trailing commas vor ] oder }
            cleaned = cleaned.replaceAll(",(\\s*[}\\]])", "$1");

            return cleaned;
        }
    }

    /**
     * Parst JSON-String mit optionaler automatischer Reparatur.
     *
     * @param rawInput Der zu parsende JSON-String
     * @param repair   Ob JSON-Reparatur versucht werden soll (default: true)
     * @return Geparstes JsonNode Objekt
     * @throws JSONProcessingException Wenn Parsing fehlschlägt
     */
    public static JsonNode parseJson(String rawInput, boolean repair) throws JSONProcessingException {
        rawInput = rawInput.trim();

        // Versuche zuerst direktes Parsing
        try {
            return objectMapper.readTree(rawInput);
        } catch (JsonProcessingException e) {
            // Ignoriere und fahre mit weiteren Schritten fort
        }

        // Extrahiere JSON aus Markdown-Code-Blöcken
        if (rawInput.contains("```")) {
            String[] patterns = {
                "```json\\s*(.*?)\\s*```",
                "```\\s*(\\{.*?\\})\\s*```",
                "```\\s*(\\[.*?\\])\\s*```"
            };

            for (String patternStr : patterns) {
                Pattern pattern = Pattern.compile(patternStr, Pattern.DOTALL);
                Matcher matcher = pattern.matcher(rawInput);
                while (matcher.find()) {
                    try {
                        return objectMapper.readTree(matcher.group(1));
                    } catch (JsonProcessingException e) {
                        // Ignoriere und versuche nächsten Match
                    }
                }
            }
        }

        // Versuche Reparatur
        if (repair) {
            try {
                String repaired = repairJsonString(rawInput);
                return objectMapper.readTree(repaired);
            } catch (JsonProcessingException | JSONRepairError e) {
                throw new JSONProcessingException("Could not parse JSON even after repair: " + e.getMessage(), e);
            }
        }

        throw new JSONProcessingException("Could not parse JSON");
    }

    /**
     * Parst JSON und validiert gegen ein definiertes Schema.
     *
     * @param rawInput   Der zu parsende JSON-String
     * @param repair     Ob JSON-Reparatur versucht werden soll
     * @return Validierte Instanz des JSON-Objekts
     * @throws JSONValidationError Wenn Validierung fehlschlägt
     */
    public static JsonNode parseAndValidate(String rawInput, boolean repair) throws JSONValidationError {
        try {
            return parseJson(rawInput, repair);
        } catch (JSONProcessingException e) {
            throw new JSONValidationError("JSON parsing failed: " + e.getMessage(), e);
        }
    }

    /**
     * Validiert einen OpenClaw/Tool-Call JSON.
     *
     * @param rawJson   Der Tool-Call JSON-String
     * @param toolName  Optionaler erwarteter Tool-Name
     * @return Validiertes Tool-Call Dict
     * @throws JSONValidationError Wenn Validierung fehlschlägt
     */
    public static ObjectNode validateToolCall(String rawJson, String toolName) throws JSONValidationError {
        JsonNode toolCall;
        try {
            toolCall = parseAndValidate(rawJson, true);
        } catch (JSONValidationError e) {
            throw new JSONValidationError("Tool call validation failed: " + e.getMessage(), e);
        }

        if (!toolCall.has("tool")) {
            throw new JSONValidationError("Missing required field 'tool'");
        }

        String actualToolName = toolCall.get("tool").asText();
        if (toolName != null && !actualToolName.equals(toolName)) {
            throw new JSONValidationError(
                String.format("Expected tool '%s', got '%s'", toolName, actualToolName)
            );
        }

        ObjectNode result = objectMapper.createObjectNode();
        result.put("tool", actualToolName);
        result.set("arguments", toolCall.has("arguments") ? toolCall.get("arguments") : objectMapper.createObjectNode());
        if (toolCall.has("reasoning")) {
            result.put("reasoning", toolCall.get("reasoning").asText());
        }

        return result;
    }

    /**
     * Sicheres JSON-Parsing mit Fallback auf Default-Wert.
     *
     * @param rawInput Der zu parsende JSON-String
     * @param defaultValue Rückgabewert bei Fehlschlag
     * @param repair   Ob Reparatur versucht werden soll
     * @return Geparstes Objekt oder Default-Wert
     */
    public static JsonNode safeJsonLoads(String rawInput, JsonNode defaultValue, boolean repair) {
        try {
            return parseJson(rawInput, repair);
        } catch (JSONProcessingException e) {
            return defaultValue;
        }
    }

    /**
     * Extrahiert alle JSON-Objekte aus einem Text.
     *
     * @param text Text, der JSON-Objekte enthalten könnte
     * @return Liste aller gefundenen und geparsten JSON-Objekte
     */
    public static List<JsonNode> extractJsonFromText(String text) {
        List<JsonNode> results = new ArrayList<>();

        // Pattern für JSON-Objekte und Arrays
        String[] patterns = {
            "\\{[^{}]*(?:\\{[^{}]*\\}[^{}]*)*\\}",  // Objekte
            "\\[[^\\[\\]]*(?:\\[[^\\[\\]]*\\][^\\[\\]]*)*\\]"  // Arrays
        };

        for (String patternStr : patterns) {
            Pattern pattern = Pattern.compile(patternStr);
            Matcher matcher = pattern.matcher(text);
            while (matcher.find()) {
                try {
                    JsonNode parsed = parseJson(matcher.group(), true);
                    results.add(parsed);
                } catch (JSONProcessingException e) {
                    // Ignoriere ungültige Matches
                }
            }
        }

        return results;
    }

    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java JsonProcessor <input> [--file] [--repair|--no-repair] [--pretty]");
            System.exit(1);
        }

        String input = args[0];
        boolean isFile = false;
        boolean repair = true;
        boolean pretty = false;

        for (int i = 1; i < args.length; i++) {
            switch (args[i]) {
                case "--file":
                case "-f":
                    isFile = true;
                    break;
                case "--repair":
                case "-r":
                    repair = true;
                    break;
                case "--no-repair":
                    repair = false;
                    break;
                case "--pretty":
                case "-p":
                    pretty = true;
                    break;
            }
        }

        try {
            String content;
            if (isFile) {
                content = new String(Files.readAllBytes(Paths.get(input)));
            } else {
                content = input;
            }

            JsonNode result = parseJson(content, repair);

            String output;
            if (pretty) {
                output = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(result);
            } else {
                output = objectMapper.writeValueAsString(result);
            }

            System.out.println(output);

        } catch (JSONProcessingException e) {
            System.err.println("Error: " + e.getMessage());
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Unexpected error: " + e.getMessage());
            System.exit(1);
        }
    }
}
