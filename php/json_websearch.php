<?php
// abstraction-provenance: {"artifact_sha256": "2bb8d0bdb78027d94ea523d2f1d46566cea73532adfa1d1efdc6adc09cc66f7e", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "php"}
// json_websearch.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * JSON Utils + WebSearch integration.
 * Fetch API schemas from web, validate real API responses, batch-validate endpoints.
 */

// Autoload classes (assuming PSR-4 or similar setup)
spl_autoload_register(function ($class) {
    $prefix = 'JsonUtils\\';
    $base_dir = __DIR__ . '/../../json-utils/scripts/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

class WebSearchResult {
    public $query;
    public $json_data;
    public $validation_errors;
    public $schema_matched;
    public $source_url;

    public function __construct($query, $json_data, $validation_errors, $schema_matched, $source_url) {
        $this->query = $query;
        $this->json_data = $json_data;
        $this->validation_errors = $validation_errors;
        $this->schema_matched = $schema_matched;
        $this->source_url = $source_url;
    }
}

class WebSearchJSON {
    /**
     * Combine WebSearch with JSON validation.
     *
     * Use cases:
     * 1. Search for API documentation, extract schema
     * 2. Validate real API responses against schemas
     * 3. Batch-validate multiple API endpoints
     * 4. Auto-repair common API response errors
     */
    
    private $use_repair;
    private $json_available;

    public function __construct($use_repair = true) {
        $this->use_repair = $use_repair;
        $this->json_available = class_exists('JsonUtils\JsonProcessor');
        if (!$this->json_available) {
            echo "Warning: json-utils not found. Some features disabled.\n";
        }
    }

    /**
     * Search web for JSON data, validate against schema.
     *
     * This is a placeholder - in real usage, this would:
     * 1. Call WebSearch to find API docs
     * 2. Extract JSON examples/schemas from results
     * 3. Parse and validate with json-utils
     */
    public function search_and_validate($query, $schema = null, $schema_path = null) {
        // Simulate web search result (would be actual search in production)
        $mock_response = [
            "api" => explode(" ", $query)[0] ?? "unknown",
            "version" => "1.0",
            "endpoints" => [
                ["path" => "/items", "method" => "GET"],
                ["path" => "/items", "method" => "POST"]
            ]
        ];

        // Validate with json-utils if available
        $validation_errors = [];
        $schema_matched = false;

        if ($this->json_available && ($schema || $schema_path)) {
            try {
                if ($schema_path) {
                    \JsonUtils\SchemaValidator::validateWithJsonSchema($mock_response, $schema_path);
                }
                $schema_matched = true;
            } catch (Exception $e) {
                $validation_errors[] = $e->getMessage();
            }
        }

        return new WebSearchResult(
            $query,
            $mock_response,
            $validation_errors,
            $schema_matched,
            "https://api.github.com/search?q=" . urlencode($query)
        );
    }

    /**
     * Validate an API response with auto-repair.
     *
     * Uses json-utils for robust parsing.
     */
    public function validate_api_response($response_data, $endpoint, $expected_schema = null) {
        if (!$this->json_available) {
            return json_decode($response_data, true);
        }

        // Use json-utils parser with auto-repair
        $result = \JsonUtils\JsonProcessor::parseJson($response_data, ['repair' => $this->use_repair]);

        if ($expected_schema) {
            try {
                \JsonUtils\JsonProcessor::parseAndValidate(json_encode($result), $expected_schema);
            } catch (Exception $e) {
                echo "Schema validation failed for {$endpoint}: " . $e->getMessage() . "\n";
            }
        }

        return $result;
    }

    /**
     * Batch-validate multiple API endpoint responses.
     */
    public function batch_validate_endpoints($endpoints, $responses, $schema_path = null) {
        $results = [];
        foreach (array_combine($endpoints, $responses) as $endpoint => $response) {
            try {
                $json_data = $this->validate_api_response($response, $endpoint);
                $results[] = new WebSearchResult(
                    $endpoint,
                    $json_data,
                    [],
                    true,
                    $endpoint
                );
            } catch (Exception $e) {
                $results[] = new WebSearchResult(
                    $endpoint,
                    [],
                    [$e->getMessage()],
                    false,
                    $endpoint
                );
            }
        }
        return $results;
    }

    /**
     * Generate JSON Schema from sample API response.
     */
    public function generate_api_schema($sample_response, $endpoint) {
        if (!$this->json_available) {
            return [];
        }

        $data = \JsonUtils\JsonProcessor::parseJson($sample_response);

        // Basic schema generation
        $infer_schema = function ($obj, $path = "root") use (&$infer_schema) {
            if (is_array($obj) && array_keys($obj) !== range(0, count($obj) - 1)) {
                // Associative array - treat as object
                $properties = [];
                foreach ($obj as $k => $v) {
                    $properties[$k] = $infer_schema($v, "{$path}.{$k}");
                }
                return [
                    "type" => "object",
                    "properties" => $properties
                ];
            } elseif (is_array($obj)) {
                // Indexed array - treat as array
                if (!empty($obj)) {
                    return [
                        "type" => "array",
                        "items" => $infer_schema($obj[0], "{$path}[]")
                    ];
                } else {
                    return [
                        "type" => "array",
                        "items" => ["type" => "null"]
                    ];
                }
            } elseif (is_string($obj)) {
                return ["type" => "string"];
            } elseif (is_int($obj)) {
                return ["type" => "integer"];
            } elseif (is_float($obj)) {
                return ["type" => "number"];
            } elseif (is_bool($obj)) {
                return ["type" => "boolean"];
            } else {
                return ["type" => "null"];
            }
        };

        $schema = [
            '$schema' => "http://json-schema.org/draft-07/schema#",
            'title' => "{$endpoint} Response Schema"
        ];

        // Merge inferred schema properties into base schema
        $inferred = $infer_schema($data);
        foreach ($inferred as $key => $value) {
            $schema[$key] = $value;
        }

        return $schema;
    }
}

function main() {
    global $argv;
    
    $args = [
        '--search' => null,
        '--validate-file' => null,
        '--schema' => null,
        '--generate-schema' => null,
        '--endpoint' => null
    ];
    
    // Simple argument parser
    for ($i = 1; $i < count($argv); $i++) {
        if (array_key_exists($argv[$i], $args) && isset($argv[$i+1])) {
            $args[$argv[$i]] = $argv[$i+1];
            $i++; // Skip next arg
        }
    }
    
    $ws = new WebSearchJSON();
    
    if ($args['--search']) {
        $result = $ws->search_and_validate($args['--search'], null, $args['--schema']);
        echo "Query: {$result->query}\n";
        echo "Data: " . json_encode($result->json_data, JSON_PRETTY_PRINT) . "\n";
        echo "Schema matched: " . ($result->schema_matched ? 'true' : 'false') . "\n";
        if (!empty($result->validation_errors)) {
            echo "Errors: " . implode(", ", $result->validation_errors) . "\n";
        }
    } elseif ($args['--generate-schema'] && $args['--endpoint']) {
        $sample = file_get_contents($args['--generate-schema']);
        $schema = $ws->generate_api_schema($sample, $args['--endpoint']);
        echo json_encode($schema, JSON_PRETTY_PRINT) . "\n";
    }
}

if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    main();
}
?>
