<?php
// abstraction-provenance: {"artifact_sha256": "89695df11b05219821a29480ff65ca97aa3a90c6f63000259c1295785ac508c1", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "php"}
// json_schema_validator.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
 * Erweitert Pydantic mit externen Schema-Dateien.
 */

// JSON Schema validation library (opis/json-schema recommended)
// Install via composer require opis/json-schema

require_once 'vendor/autoload.php';

use Opis\JsonSchema\Validator;
use Opis\JsonSchema\Schema;
use Opis\JsonSchema\Exception\SchemaException;
use Opis\JsonSchema\Errors\ErrorFormatter;

class JSONProcessingError extends Exception {}
class JSONValidationError extends Exception {}
class SchemaValidationError extends JSONValidationError {}

/**
 * Parst JSON mit optionaler Reparatur
 */
function parse_json($raw_input, $repair = true) {
    $data = json_decode($raw_input, true);
    if (json_last_error() === JSON_ERROR_NONE) {
        return $data;
    }
    
    if (!$repair) {
        throw new JSONProcessingError("Invalid JSON: " . json_last_error_msg());
    }
    
    // Versuche einfache Reparaturen
    $cleaned = preg_replace('/,\s*([\]}])/m', '$1', $raw_input); // trailing commas
    $data = json_decode($cleaned, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new JSONProcessingError("Invalid JSON even after repair: " . json_last_error_msg());
    }
    
    return $data;
}

/**
 * Lädt ein JSON Schema aus verschiedenen Quellen.
 *
 * @param mixed $schema_source Pfad zur Schema-Datei oder Schema-Array oder JSON String
 * @return array Schema als Array
 */
function load_schema($schema_source) {
    if (is_array($schema_source)) {
        return $schema_source;
    }
    
    $schema_path = $schema_source;
    if (file_exists($schema_path)) {
        $content = file_get_contents($schema_path);
        $schema = json_decode($content, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new SchemaValidationError("Invalid JSON in schema file: " . json_last_error_msg());
        }
        return $schema;
    }
    
    // Versuche als JSON String zu parsen
    $schema = json_decode($schema_source, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new SchemaValidationError("Schema not found or invalid: " . $schema_source);
    }
    return $schema;
}

/**
 * Validiert Daten gegen ein JSON Schema.
 *
 * @param mixed $data Zu validierende Daten
 * @param mixed $schema JSON Schema (Pfad, String oder Array)
 * @param string $draft JSON Schema Draft Version ("auto", "draft7", "2020-12")
 * @return bool True wenn valid
 * @throws SchemaValidationError Wenn Validierung fehlschlägt
 */
function validate_with_jsonschema($data, $schema, $draft = "auto") {
    $schema_array = load_schema($schema);
    
    try {
        $validator = new Validator();
        $schema_obj = Schema::fromJsonString(json_encode($schema_array));
        $result = $validator->schemaValidation($data, $schema_obj);
        
        if ($result->isValid()) {
            return true;
        } else {
            $formatter = new ErrorFormatter();
            $errors = $formatter->format($result->error());
            throw new SchemaValidationError("Schema validation failed: " . json_encode($errors));
        }
    } catch (Exception $e) {
        throw new SchemaValidationError("Schema validation failed: " . $e->getMessage());
    }
}

/**
 * Parst, repariert und validiert JSON gegen Schema.
 *
 * @param string $raw_input JSON-String
 * @param mixed $schema JSON Schema
 * @param bool $repair Ob Reparatur versucht werden soll
 * @return mixed Validierte Daten
 */
function validate_and_convert($raw_input, $schema, $repair = true) {
    $data = parse_json($raw_input, $repair);
    validate_with_jsonschema($data, $schema);
    return $data;
}

/**
 * Hilfsklasse zum Erstellen von JSON Schemas.
 */
class SchemaBuilder {
    /**
     * Erstellt ein Object-Schema.
     */
    public static function object($properties, $required = null) {
        $schema = [
            "type" => "object",
            "properties" => $properties
        ];
        if ($required) {
            $schema["required"] = $required;
        }
        return $schema;
    }
    
    /**
     * Erstellt ein String-Schema.
     */
    public static function string($enum = null, $pattern = null, $min_length = null) {
        $schema = ["type" => "string"];
        if ($enum) {
            $schema["enum"] = $enum;
        }
        if ($pattern) {
            $schema["pattern"] = $pattern;
        }
        if ($min_length !== null) {
            $schema["minLength"] = $min_length;
        }
        return $schema;
    }
    
    /**
     * Erstellt ein Integer-Schema.
     */
    public static function integer($minimum = null, $maximum = null) {
        $schema = ["type" => "integer"];
        if ($minimum !== null) {
            $schema["minimum"] = $minimum;
        }
        if ($maximum !== null) {
            $schema["maximum"] = $maximum;
        }
        return $schema;
    }
    
    /**
     * Erstellt ein Array-Schema.
     */
    public static function array($items, $min_items = null) {
        $schema = ["type" => "array", "items" => $items];
        if ($min_items !== null) {
            $schema["minItems"] = $min_items;
        }
        return $schema;
    }
}

function main() {
    global $argv;
    
    $options = getopt("s:fr", ["schema:", "file", "repair"]);
    $args = array_slice($argv, 1);
    
    $schema = isset($options['s']) ? $options['s'] : (isset($options['schema']) ? $options['schema'] : null);
    $is_file = isset($options['f']) || isset($options['file']);
    $repair = isset($options['r']) || isset($options['repair']) || !isset($options['r']) && !isset($options['repair']); // default true
    
    if (!$schema || count($args) < 1) {
        echo "Usage: php json_schema_validator.php [options] <input>\n";
        echo "Options:\n";
        echo "  --schema, -s <schema>  Schema file\n";
        echo "  --file, -f             Input is file\n";
        echo "  --repair, -r           Repair JSON (default)\n";
        exit(1);
    }
    
    $input_arg = $args[count($args)-1];
    
    // Lade Input (Auto-detect file vs string)
    if ($is_file || (file_exists($input_arg) && is_file($input_arg))) {
        $raw_input = file_get_contents($input_arg);
    } else {
        $raw_input = $input_arg;
    }
    
    try {
        $result = validate_and_convert($raw_input, $schema, $repair);
        echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
        fwrite(STDERR, "\n✓ Validation passed\n");
    } catch (Exception $e) {
        fwrite(STDERR, "✗ Validation failed: " . $e->getMessage() . "\n");
        exit(1);
    }
}

if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    main();
}
