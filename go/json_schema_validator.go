// abstraction-provenance: {"artifact_sha256": "eae72d28ea10dd9297b1f9b49dea2afdcb68ab5925833093ab92555952477843", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "go"}
// json_schema_validator.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
Erweitert Pydantic mit externen Schema-Dateien.
*/

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// JSONValidationError represents a generic JSON validation error
type JSONValidationError struct {
	Message string
}

func (e *JSONValidationError) Error() string {
	return e.Message
}

// SchemaValidationError represents a schema validation error
type SchemaValidationError struct {
	Message string
}

func (e *SchemaValidationError) Error() string {
	return e.Message
}

// JSONProcessingError represents an error during JSON processing
type JSONProcessingError struct {
	Message string
}

func (e *JSONProcessingError) Error() string {
	return e.Message
}

// Schema represents a JSON schema structure
type Schema map[string]interface{}

// parseJSON parses and optionally repairs JSON
func parseJSON(rawInput string, repair bool) (interface{}, error) {
	var data interface{}
	err := json.Unmarshal([]byte(rawInput), &data)
	if err != nil && repair {
		// Simple repair attempts
		repaired := strings.ReplaceAll(rawInput, "'", "\"")
		repaired = regexp.MustCompile(`(\w+):`).ReplaceAllString(repaired, "\"$1\":")
		err = json.Unmarshal([]byte(repaired), &data)
		if err != nil {
			return nil, &JSONProcessingError{Message: fmt.Sprintf("Failed to parse JSON: %v", err)}
		}
		return data, nil
	} else if err != nil {
		return nil, &JSONProcessingError{Message: fmt.Sprintf("Failed to parse JSON: %v", err)}
	}
	return data, nil
}

// loadSchema loads a JSON schema from various sources
func loadSchema(schemaSource interface{}) (Schema, error) {
	switch src := schemaSource.(type) {
	case Schema:
		return src, nil
	case map[string]interface{}:
		return Schema(src), nil
	case string:
		// Check if it's a file path
		if _, err := os.Stat(src); err == nil {
			content, err := ioutil.ReadFile(src)
			if err != nil {
				return nil, &SchemaValidationError{Message: fmt.Sprintf("Failed to read schema file: %v", err)}
			}
			
			var schema Schema
			err = json.Unmarshal(content, &schema)
			if err != nil {
				return nil, &SchemaValidationError{Message: fmt.Sprintf("Invalid JSON in schema file: %v", err)}
			}
			return schema, nil
		}
		
		// Try parsing as JSON string
		var schema Schema
		err := json.Unmarshal([]byte(src), &schema)
		if err != nil {
			return nil, &SchemaValidationError{Message: fmt.Sprintf("Schema not found or invalid: %s", src)}
		}
		return schema, nil
	default:
		return nil, &SchemaValidationError{Message: "Unsupported schema source type"}
	}
}

// validateWithJSONSchema validates data against a JSON schema
func validateWithJSONSchema(data interface{}, schema interface{}) error {
	schemaDict, err := loadSchema(schema)
	if err != nil {
		return &SchemaValidationError{Message: fmt.Sprintf("Failed to load schema: %v", err)}
	}
	
	// Basic validation implementation
	// Note: This is a simplified version - a full implementation would require
	// a complete JSON Schema validator library
	if !validateData(data, schemaDict) {
		return &SchemaValidationError{Message: "Schema validation failed"}
	}
	
	return nil
}

// validateData performs basic JSON schema validation
func validateData(data interface{}, schema Schema) bool {
	if schemaType, ok := schema["type"]; ok {
		switch schemaType {
		case "object":
			if objData, ok := data.(map[string]interface{}); ok {
				return validateObject(objData, schema)
			}
			return false
		case "string":
			_, ok := data.(string)
			return ok
		case "integer":
			_, ok := data.(float64) // JSON numbers are float64
			return ok
		case "array":
			_, ok := data.([]interface{})
			return ok
		}
	}
	return true
}

// validateObject validates an object against schema properties
func validateObject(obj map[string]interface{}, schema Schema) bool {
	if properties, ok := schema["properties"].(map[string]interface{}); ok {
		for key, propSchema := range properties {
			if value, exists := obj[key]; exists {
				propMap, _ := propSchema.(map[string]interface{})
				if !validateData(value, propMap) {
					return false
				}
			}
		}
	}
	
	// Check required fields
	if required, ok := schema["required"].([]interface{}); ok {
		for _, req := range required {
			if reqStr, ok := req.(string); ok {
				if _, exists := obj[reqStr]; !exists {
					return false
				}
			}
		}
	}
	
	return true
}

// validateAndConvert parses, repairs and validates JSON against schema
func validateAndConvert(rawInput string, schema interface{}, repair bool) (interface{}, error) {
	data, err := parseJSON(rawInput, repair)
	if err != nil {
		return nil, err
	}
	
	err = validateWithJSONSchema(data, schema)
	if err != nil {
		return nil, err
	}
	
	return data, nil
}

// SchemaBuilder helper for creating JSON schemas
type SchemaBuilder struct{}

// Object creates an object schema
func (sb *SchemaBuilder) Object(properties map[string]interface{}, required []string) Schema {
	schema := Schema{
		"type":       "object",
		"properties": properties,
	}
	
	if required != nil {
		requiredInterface := make([]interface{}, len(required))
		for i, v := range required {
			requiredInterface[i] = v
		}
		schema["required"] = requiredInterface
	}
	
	return schema
}

// String creates a string schema
func (sb *SchemaBuilder) String(enum []string, pattern string, minLength *int) Schema {
	schema := Schema{"type": "string"}
	
	if enum != nil {
		enumInterface := make([]interface{}, len(enum))
		for i, v := range enum {
			enumInterface[i] = v
		}
		schema["enum"] = enumInterface
	}
	
	if pattern != "" {
		schema["pattern"] = pattern
	}
	
	if minLength != nil {
		schema["minLength"] = *minLength
	}
	
	return schema
}

// Integer creates an integer schema
func (sb *SchemaBuilder) Integer(minimum *int, maximum *int) Schema {
	schema := Schema{"type": "integer"}
	
	if minimum != nil {
		schema["minimum"] = *minimum
	}
	
	if maximum != nil {
		schema["maximum"] = *maximum
	}
	
	return schema
}

// Array creates an array schema
func (sb *SchemaBuilder) Array(items Schema, minItems *int) Schema {
	schema := Schema{
		"type": "array",
		"items": items,
	}
	
	if minItems != nil {
		schema["minItems"] = *minItems
	}
	
	return schema
}

// CLI arguments structure
type args struct {
	input  string
	schema string
	file   bool
	repair bool
}

// parseArgs parses command line arguments
func parseArgs() (*args, error) {
	result := &args{repair: true}
	
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		
		switch arg {
		case "--schema", "-s":
			if i+1 < len(os.Args) {
				result.schema = os.Args[i+1]
				i++
			}
		case "--file", "-f":
			result.file = true
		case "--repair", "-r":
			result.repair = true
		case "--no-repair":
			result.repair = false
		default:
			if !strings.HasPrefix(arg, "-") && result.input == "" {
				result.input = arg
			}
		}
	}
	
	if result.input == "" || result.schema == "" {
		return nil, fmt.Errorf("input and schema are required")
	}
	
	return result, nil
}

func main() {
	args, err := parseArgs()
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ Error parsing arguments: %v\n", err)
		os.Exit(1)
	}
	
	// Load input (auto-detect file vs string)
	var rawInput string
	inputPath := args.input
	
	if args.file || (func() bool {
		_, err := os.Stat(inputPath)
		return err == nil
	}()) {
		content, err := ioutil.ReadFile(inputPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "✗ Failed to read input file: %v\n", err)
			os.Exit(1)
		}
		rawInput = string(content)
	} else {
		rawInput = args.input
	}
	
	// Validate
	result, err := validateAndConvert(rawInput, args.schema, args.repair)
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ Validation failed: %v\n", err)
		os.Exit(1)
	}
	
	// Output result
	output, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ Failed to format output: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println(string(output))
	fmt.Fprintln(os.Stderr, "\n✓ Validation passed")
}
