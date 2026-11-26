<?php
// abstraction-provenance: {"artifact_sha256": "b8c17e9e373a81b66279d1f3f6c07cdba163e0e8ce9151550e0af77928461173", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "php"}
// json_processor.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * JSON Processor mit Validierung und JSON-Reparatur.
 * Für robuste Verarbeitung von LLM-Outputs.
 */

class JSONProcessingError extends Exception {
    /** Base exception for JSON processing errors. */
}

class JSONValidationError extends JSONProcessingError {
    /** Raised when JSON validation fails. */
}

class JSONRepairError extends JSONProcessingError {
    /** Raised when JSON repair fails. */
}

function repair_json_string($raw_json) {
    /**
     * Repariert häufige JSON-Fehler aus LLM-Outputs.
     *
     * Behebt:
     * - Trailing commas
     * - Einzelne statt doppelte Quotes
     * - JavaScript-Style Kommentare
     * - Unescaped Zeilenumbrüche in Strings
     */

    // Fallback: Manuelle Reparaturen
    $cleaned = trim($raw_json);

    // Entferne JavaScript-Kommentare
    $cleaned = preg_replace('/\/\/.*?\n/', "\n", $cleaned);
    $cleaned = preg_replace('/\/\*.*?\*\//s', '', $cleaned);

    // Entferne trailing commas vor ] oder }
    $cleaned = preg_replace('/,(\\s*[}\\]])/', '$1', $cleaned);

    return $cleaned;
}

function parse_json($raw_input, $repair = true) {
    /**
     * Parst JSON-String mit optionaler automatischer Reparatur.
     *
     * @param string $raw_input Der zu parsende JSON-String
     * @param bool $repair Ob JSON-Reparatur versucht werden soll (default: True)
     *
     * @return mixed Geparstes PHP-Objekt
     *
     * @throws JSONProcessingError Wenn Parsing fehlschlägt
     */

    $raw_input = trim($raw_input);

    // Versuche zuerst direktes Parsing
    $data = json_decode($raw_input, true);
    if ($data !== null || json_last_error() === JSON_ERROR_NONE) {
        return $data;
    }

    // Extrahiere JSON aus Markdown-Code-Blöcken
    if (strpos($raw_input, "```") !== false) {
        // Suche nach JSON in ```json ... ``` oder ``` ... ```
        $patterns = [
            '/```json\\s*(.*?)\\s*```/s',
            '/```\\s*(\\{.*?\\})\\s*```/s',
            '/```\\s*(\\[.*?\\])\\s*```/s',
        ];
        foreach ($patterns as $pattern) {
            if (preg_match_all($pattern, $raw_input, $matches)) {
                foreach ($matches[1] as $match) {
                    $data = json_decode($match, true);
                    if ($data !== null || json_last_error() === JSON_ERROR_NONE) {
                        return $data;
                    }
                }
            }
        }
    }

    // Versuche Reparatur
    if ($repair) {
        try {
            $repaired = repair_json_string($raw_input);
            $data = json_decode($repaired, true);
            if ($data !== null || json_last_error() === JSON_ERROR_NONE) {
                return $data;
            } else {
                throw new JSONProcessingError("Could not parse JSON even after repair: " . json_last_error_msg());
            }
        } catch (Exception $e) {
            throw new JSONProcessingError("Could not parse JSON even after repair: " . $e->getMessage());
        }
    }

    throw new JSONProcessingError("Could not parse JSON");
}

function parse_and_validate($raw_input, $model_class, $repair = true, $strict = false) {
    /**
     * Parst JSON und validiert gegen ein Modell.
     *
     * @param string $raw_input Der zu parsende JSON-String
     * @param string $model_class Modellklasse für Validierung
     * @param bool $repair Ob JSON-Reparatur versucht werden soll
     * @param bool $strict Ob strikte Validierung angewendet werden soll
     *
     * @return object Validierte Instanz des Modells
     *
     * @throws JSONValidationError Wenn Validierung fehlschlägt
     */

    try {
        $data = parse_json($raw_input, $repair);
    } catch (JSONProcessingError $e) {
        throw new JSONValidationError("JSON parsing failed: " . $e->getMessage());
    }

    try {
        if ($strict) {
            return $model_class::model_validate($data, true);
        } else {
            return $model_class::model_validate($data);
        }
    } catch (Exception $e) {
        throw new JSONValidationError("Validation failed: " . $e->getMessage());
    }
}

function validate_tool_call($raw_json, $tool_name = null) {
    /**
     * Validiert einen OpenClaw/Tool-Call JSON.
     *
     * @param string $raw_json Der Tool-Call JSON-String
     * @param string|null $tool_name Optionaler erwarteter Tool-Name
     *
     * @return array Validiertes Tool-Call Array
     */

    // In PHP simulieren wir das Pydantic-Modell durch eine eigene Klasse
    class ToolCall {
        public $tool;
        public $arguments = [];
        public $reasoning = null;

        public function __construct($data) {
            $this->tool = $data['tool'] ?? null;
            $this->arguments = $data['arguments'] ?? [];
            $this->reasoning = $data['reasoning'] ?? null;
        }

        public static function model_validate($data, $strict = false) {
            $instance = new self($data);
            if (!isset($instance->tool)) {
                throw new Exception("Field 'tool' is required");
            }
            if (!is_array($instance->arguments)) {
                if ($strict) {
                    throw new Exception("Field 'arguments' must be an array");
                }
                $instance->arguments = [];
            }
            return $instance;
        }
    }

    $tool_call = parse_and_validate($raw_json, 'ToolCall', true);

    if ($tool_name && $tool_call->tool !== $tool_name) {
        throw new JSONValidationError(
            "Expected tool '{$tool_name}', got '{$tool_call->tool}'"
        );
    }

    return [
        "tool" => $tool_call->tool,
        "arguments" => $tool_call->arguments,
        "reasoning" => $tool_call->reasoning
    ];
}

function safe_json_loads($raw_input, $default = null, $repair = true) {
    /**
     * Sicheres JSON-Parsing mit Fallback auf Default-Wert.
     *
     * @param string $raw_input Der zu parsende JSON-String
     * @param mixed $default Rückgabewert bei Fehlschlag (default: null)
     * @param bool $repair Ob Reparatur versucht werden soll
     *
     * @return mixed Geparstes Objekt oder Default-Wert
     */

    try {
        return parse_json($raw_input, $repair);
    } catch (JSONProcessingError $e) {
        return $default;
    }
}

function extract_json_from_text($text) {
    /**
     * Extrahiert alle JSON-Objekte aus einem Text.
     *
     * @param string $text Text, der JSON-Objekte enthalten könnte
     *
     * @return array Liste aller gefundenen und geparsten JSON-Objekte
     */

    $results = [];

    // Pattern für JSON-Objekte und Arrays
    $patterns = [
        '/\\{[^{}]*(?:\\{[^{}]*\\}[^{}]*)*\\}/',  // Objekte
        '/\\[[^\\[\\]]*(?:\\[[^\\[\\]]*\\][^\\[\\]]*)*\\]/',  // Arrays
    ];

    foreach ($patterns as $pattern) {
        if (preg_match_all($pattern, $text, $matches)) {
            foreach ($matches[0] as $match) {
                try {
                    $parsed = parse_json($match, true);
                    $results[] = $parsed;
                } catch (JSONProcessingError $e) {
                    continue;
                }
            }
        }
    }

    return $results;
}

// CLI-Interface
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    $options = getopt("f::r::p::", ["file::", "repair::", "no-repair::", "pretty::"]);
    $args = $argv;

    if (count($args) < 2) {
        echo "Usage: php json_processor.php [options] <input>\n";
        exit(1);
    }

    $input_arg = $args[count($args) - 1];
    $is_file = isset($options['f']) || isset($options['file']);
    $repair = !(isset($options['no-repair']));
    $pretty = isset($options['p']) || isset($options['pretty']);

    try {
        if ($is_file) {
            $content = file_get_contents($input_arg);
            if ($content === false) {
                throw new Exception("Could not read file: {$input_arg}");
            }
        } else {
            $content = $input_arg;
        }

        $result = parse_json($content, $repair);

        $output = json_encode($result, $pretty ? JSON_PRETTY_PRINT : 0);
        echo $output . "\n";

    } catch (JSONProcessingError $e) {
        fwrite(STDERR, "Error: " . $e->getMessage() . "\n");
        exit(1);
    } catch (Exception $e) {
        fwrite(STDERR, "Unexpected error: " . $e->getMessage() . "\n");
        exit(1);
    }
}
?>
