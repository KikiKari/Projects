// abstraction-provenance: {"artifact_sha256": "0d61b758a0b857565601d188994ee8c581168bb80f1d252903abb0d1882515f1", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "java"}
// json_schema_validator.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.networknt.schema.*;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
 * Erweitert Pydantic mit externen Schema-Dateien.
 */
public class JsonSchemaValidator {
    
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final boolean HAS_JSON_SCHEMA = true;
    
    /**
     * Raised when JSON Schema validation fails.
     */
    public static class SchemaValidationError extends Exception {
        public SchemaValidationError(String message) {
            super(message);
        }
        
        public SchemaValidationError(String message, Throwable cause) {
            super(message, cause);
        }
    }
    
    /**
     * Lädt ein JSON Schema aus verschiedenen Quellen.
     *
     * @param schemaSource Pfad zur Schema-Datei oder Schema-Dict oder JSON String
     * @return Schema als Dictionary
     */
    public static JsonNode loadSchema(Object schemaSource) throws SchemaValidationError {
        if (schemaSource instanceof JsonNode) {
            return (JsonNode) schemaSource;
        }
        
        if (schemaSource instanceof String) {
            String schemaStr = (String) schemaSource;
            Path schemaPath = Paths.get(schemaStr);
            
            if (Files.exists(schemaPath)) {
                try {
                    String content = Files.readString(schemaPath);
                    return objectMapper.readTree(content);
                } catch (IOException e) {
                    throw new SchemaValidationError("Invalid JSON in schema file: " + e.getMessage(), e);
                }
            }
            
            // Versuche als JSON String zu parsen
            try {
                return objectMapper.readTree(schemaStr);
            } catch (IOException e) {
                throw new SchemaValidationError("Schema not found or invalid: " + schemaStr);
            }
        }
        
        throw new SchemaValidationError("Unsupported schema source type");
    }
    
    /**
     * Validiert Daten gegen ein JSON Schema.
     *
     * @param data Zu validierende Daten
     * @param schema JSON Schema (Pfad, String oder Dict)
     * @param draft JSON Schema Draft Version ("auto", "draft7", "2020-12")
     * @return True wenn valid
     * @throws SchemaValidationError Wenn Validierung fehlschlägt
     */
    public static boolean validateWithJsonSchema(
            Object data,
            Object schema,
            String draft) throws SchemaValidationError {
        
        if (!HAS_JSON_SCHEMA) {
            throw new SchemaValidationError("jsonschema not installed. Add dependency to your project");
        }
        
        try {
            JsonNode schemaNode = loadSchema(schema);
            JsonNode dataNode;
            
            if (data instanceof String) {
                dataNode = objectMapper.readTree((String) data);
            } else if (data instanceof JsonNode) {
                dataNode = (JsonNode) data;
            } else {
                dataNode = objectMapper.valueToTree(data);
            }
            
            JsonSchemaFactory factory = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V202012);
            JsonSchema jsonSchema = factory.getSchema(schemaNode);
            
            Set<ValidationMessage> errors = jsonSchema.validate(dataNode);
            if (!errors.isEmpty()) {
                StringBuilder errorMsg = new StringBuilder("Schema validation failed: ");
                for (ValidationMessage error : errors) {
                    errorMsg.append(error.getMessage()).append(" at ").append(error.getPath());
                }
                throw new SchemaValidationError(errorMsg.toString());
            }
            
            return true;
        } catch (Exception e) {
            if (e instanceof SchemaValidationError) {
                throw (SchemaValidationError) e;
            }
            throw new SchemaValidationError("Schema validation error: " + e.getMessage(), e);
        }
    }
    
    /**
     * Validiert Daten gegen ein JSON Schema.
     *
     * @param data Zu validierende Daten
     * @param schema JSON Schema (Pfad, String oder Dict)
     * @return True wenn valid
     * @throws SchemaValidationError Wenn Validierung fehlschlägt
     */
    public static boolean validateWithJsonSchema(Object data, Object schema) throws SchemaValidationError {
        return validateWithJsonSchema(data, schema, "auto");
    }
    
    /**
     * Parst, repariert und validiert JSON gegen Schema.
     *
     * @param rawInput JSON-String
     * @param schema JSON Schema
     * @param repair Ob Reparatur versucht werden soll
     * @return Validierte Daten
     */
    public static JsonNode validateAndConvert(String rawInput, Object schema, boolean repair) throws SchemaValidationError {
        try {
            // Simulating parse_json with repair functionality
            JsonNode data = objectMapper.readTree(rawInput);
            validateWithJsonSchema(data, schema);
            return data;
        } catch (Exception e) {
            throw new SchemaValidationError("Validation failed: " + e.getMessage(), e);
        }
    }
    
    public static JsonNode validateAndConvert(String rawInput, Object schema) throws SchemaValidationError {
        return validateAndConvert(rawInput, schema, true);
    }
    
    /**
     * Hilfsklasse zum Erstellen von JSON Schemas.
     */
    public static class SchemaBuilder {
        
        /**
         * Erstellt ein Object-Schema.
         */
        public static ObjectNode object(Map<String, Object> properties, List<String> required) {
            ObjectNode schema = objectMapper.createObjectNode();
            schema.put("type", "object");
            
            ObjectNode propsNode = objectMapper.createObjectNode();
            for (Map.Entry<String, Object> entry : properties.entrySet()) {
                if (entry.getValue() instanceof JsonNode) {
                    propsNode.set(entry.getKey(), (JsonNode) entry.getValue());
                } else {
                    propsNode.set(entry.getKey(), objectMapper.valueToTree(entry.getValue()));
                }
            }
            schema.set("properties", propsNode);
            
            if (required != null && !required.isEmpty()) {
                schema.set("required", objectMapper.valueToTree(required));
            }
            
            return schema;
        }
        
        public static ObjectNode object(Map<String, Object> properties) {
            return object(properties, null);
        }
        
        /**
         * Erstellt ein String-Schema.
         */
        public static ObjectNode string(List<String> enumValues, String pattern, Integer minLength) {
            ObjectNode schema = objectMapper.createObjectNode();
            schema.put("type", "string");
            
            if (enumValues != null && !enumValues.isEmpty()) {
                schema.set("enum", objectMapper.valueToTree(enumValues));
            }
            if (pattern != null) {
                schema.put("pattern", pattern);
            }
            if (minLength != null) {
                schema.put("minLength", minLength);
            }
            
            return schema;
        }
        
        public static ObjectNode string() {
            return string(null, null, null);
        }
        
        public static ObjectNode string(List<String> enumValues) {
            return string(enumValues, null, null);
        }
        
        public static ObjectNode string(List<String> enumValues, String pattern) {
            return string(enumValues, pattern, null);
        }
        
        /**
         * Erstellt ein Integer-Schema.
         */
        public static ObjectNode integer(Integer minimum, Integer maximum) {
            ObjectNode schema = objectMapper.createObjectNode();
            schema.put("type", "integer");
            
            if (minimum != null) {
                schema.put("minimum", minimum);
            }
            if (maximum != null) {
                schema.put("maximum", maximum);
            }
            
            return schema;
        }
        
        public static ObjectNode integer() {
            return integer(null, null);
        }
        
        public static ObjectNode integer(Integer minimum) {
            return integer(minimum, null);
        }
        
        /**
         * Erstellt ein Array-Schema.
         */
        public static ObjectNode array(JsonNode items, Integer minItems) {
            ObjectNode schema = objectMapper.createObjectNode();
            schema.put("type", "array");
            schema.set("items", items);
            
            if (minItems != null) {
                schema.put("minItems", minItems);
            }
            
            return schema;
        }
        
        public static ObjectNode array(JsonNode items) {
            return array(items, null);
        }
    }
    
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: java JsonSchemaValidator <input> --schema <schema>");
            System.exit(1);
        }
        
        String input = args[0];
        String schemaPath = null;
        boolean isFile = false;
        boolean repair = true;
        
        // Simple argument parsing
        for (int i = 1; i < args.length; i++) {
            if ("--schema".equals(args[i]) || "-s".equals(args[i])) {
                if (i + 1 < args.length) {
                    schemaPath = args[i + 1];
                    i++;
                }
            } else if ("--file".equals(args[i]) || "-f".equals(args[i])) {
                isFile = true;
            } else if ("--repair".equals(args[i]) || "-r".equals(args[i])) {
                repair = true;
            }
        }
        
        if (schemaPath == null) {
            System.err.println("Schema argument is required");
            System.exit(1);
        }
        
        try {
            String rawInput;
            if (isFile || Files.exists(Paths.get(input))) {
                rawInput = Files.readString(Paths.get(input));
            } else {
                rawInput = input;
            }
            
            JsonNode result = validateAndConvert(rawInput, schemaPath, repair);
            System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(result));
            System.err.println("\n✓ Validation passed");
        } catch (Exception e) {
            System.err.println("✗ Validation failed: " + e.getMessage());
            System.exit(1);
        }
    }
}
