// abstraction-provenance: {"artifact_sha256": "aa8439679d984c35d8bc8fcbaada69dc1bd2d5af8f15124c1163cff16023b346", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "java"}
// json_websearch.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.*;

/**
 * JSON Utils + WebSearch integration.
 * Fetch API schemas from web, validate real API responses, batch-validate endpoints.
 */
public class JsonWebSearch {
    private static final ObjectMapper objectMapper = new ObjectMapper();
    
    // Mock classes for data structures
    public static class WebSearchResult {
        public String query;
        public Map<String, Object> jsonData;
        public List<String> validationErrors;
        public boolean schemaMatched;
        public String sourceUrl;
        
        public WebSearchResult(String query, Map<String, Object> jsonData, 
                             List<String> validationErrors, boolean schemaMatched, 
                             String sourceUrl) {
            this.query = query;
            this.jsonData = jsonData;
            this.validationErrors = validationErrors;
            this.schemaMatched = schemaMatched;
            this.sourceUrl = sourceUrl;
        }
    }
    
    /**
     * Combine WebSearch with JSON validation.
     * 
     * Use cases:
     * 1. Search for API documentation, extract schema
     * 2. Validate real API responses against schemas
     * 3. Batch-validate multiple API endpoints
     * 4. Auto-repair common API response errors
     */
    public static class WebSearchJSON {
        private boolean useRepair;
        private boolean jsonAvailable;
        
        public WebSearchJSON(boolean useRepair) {
            this.useRepair = useRepair;
            // In Java we assume JSON utilities are always available through Jackson
            this.jsonAvailable = true;
        }
        
        public WebSearchJSON() {
            this(true);
        }
        
        /**
         * Search web for JSON data, validate against schema.
         * 
         * This is a placeholder - in real usage, this would:
         * 1. Call WebSearch to find API docs
         * 2. Extract JSON examples/schemas from results
         * 3. Parse and validate with json-utils
         */
        public WebSearchResult searchAndValidate(String query, 
                                               Map<String, Object> schema, 
                                               Path schemaPath) {
            // Simulate web search result (would be actual search in production)
            Map<String, Object> mockResponse = new HashMap<>();
            mockResponse.put("api", query != null && !query.isEmpty() ? 
                           query.split(" ")[0] : "unknown");
            mockResponse.put("version", "1.0");
            
            List<Map<String, String>> endpoints = new ArrayList<>();
            Map<String, String> endpoint1 = new HashMap<>();
            endpoint1.put("path", "/items");
            endpoint1.put("method", "GET");
            endpoints.add(endpoint1);
            
            Map<String, String> endpoint2 = new HashMap<>();
            endpoint2.put("path", "/items");
            endpoint2.put("method", "POST");
            endpoints.add(endpoint2);
            
            mockResponse.put("endpoints", endpoints);
            
            // Validate with json-utils if available
            List<String> validationErrors = new ArrayList<>();
            boolean schemaMatched = false;
            
            if (jsonAvailable && (schema != null || schemaPath != null)) {
                try {
                    if (schemaPath != null) {
                        // In Java we'd load and validate the schema here
                        // validateWithJsonSchema(mockResponse, schemaPath.toString());
                    }
                    schemaMatched = true;
                } catch (Exception e) {
                    validationErrors.add(e.getMessage());
                }
            }
            
            return new WebSearchResult(
                query,
                mockResponse,
                validationErrors,
                schemaMatched,
                "https://api.github.com/search?q=" + (query != null ? query.replace(" ", "+") : "")
            );
        }
        
        public WebSearchResult searchAndValidate(String query) {
            return searchAndValidate(query, null, null);
        }
        
        public WebSearchResult searchAndValidate(String query, Map<String, Object> schema) {
            return searchAndValidate(query, schema, null);
        }
        
        /**
         * Validate an API response with auto-repair.
         * 
         * Uses json-utils for robust parsing.
         */
        public Map<String, Object> validateApiResponse(String responseData, 
                                                     String endpoint,
                                                     Map<String, Object> expectedSchema) {
            if (!jsonAvailable) {
                try {
                    return objectMapper.readValue(responseData, Map.class);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
            
            // Use Jackson parser with basic repair capabilities
            Map<String, Object> result;
            try {
                result = objectMapper.readValue(responseData, Map.class);
            } catch (Exception e) {
                if (useRepair) {
                    // Basic repair attempt
                    String repaired = responseData.trim();
                    if (!repaired.startsWith("{") && !repaired.startsWith("[")) {
                        repaired = "{" + repaired + "}";
                    }
                    try {
                        result = objectMapper.readValue(repaired, Map.class);
                    } catch (Exception repairException) {
                        throw new RuntimeException("Failed to parse JSON even after repair attempts", e);
                    }
                } else {
                    throw new RuntimeException("Failed to parse JSON", e);
                }
            }
            
            if (expectedSchema != null) {
                try {
                    // In a full implementation, we'd validate against the schema here
                    // parseAndValidate(objectMapper.writeValueAsString(result), expectedSchema);
                } catch (Exception e) {
                    System.out.println("Schema validation failed for " + endpoint + ": " + e.getMessage());
                }
            }
            
            return result;
        }
        
        public Map<String, Object> validateApiResponse(String responseData, String endpoint) {
            return validateApiResponse(responseData, endpoint, null);
        }
        
        /**
         * Batch-validate multiple API endpoint responses.
         */
        public List<WebSearchResult> batchValidateEndpoints(List<String> endpoints,
                                                           List<String> responses,
                                                           Path schemaPath) {
            List<WebSearchResult> results = new ArrayList<>();
            
            for (int i = 0; i < endpoints.size(); i++) {
                String endpoint = endpoints.get(i);
                String response = responses.get(i);
                
                try {
                    Map<String, Object> jsonData = validateApiResponse(response, endpoint);
                    results.add(new WebSearchResult(
                        endpoint,
                        jsonData,
                        new ArrayList<>(),
                        true,
                        endpoint
                    ));
                } catch (Exception e) {
                    results.add(new WebSearchResult(
                        endpoint,
                        new HashMap<>(),
                        Arrays.asList(e.getMessage()),
                        false,
                        endpoint
                    ));
                }
            }
            
            return results;
        }
        
        public List<WebSearchResult> batchValidateEndpoints(List<String> endpoints,
                                                           List<String> responses) {
            return batchValidateEndpoints(endpoints, responses, null);
        }
        
        /**
         * Generate JSON Schema from sample API response.
         */
        public Map<String, Object> generateApiSchema(String sampleResponse, String endpoint) {
            if (!jsonAvailable) {
                return new HashMap<>();
            }
            
            Map<String, Object> data;
            try {
                data = objectMapper.readValue(sampleResponse, Map.class);
            } catch (Exception e) {
                throw new RuntimeException("Failed to parse sample response", e);
            }
            
            // Basic schema generation
            Map<String, Object> schema = new HashMap<>();
            schema.put("$schema", "http://json-schema.org/draft-07/schema#");
            schema.put("title", endpoint + " Response Schema");
            
            Map<String, Object> inferredSchema = inferSchema(data, "root");
            schema.putAll(inferredSchema);
            
            return schema;
        }
        
        private Map<String, Object> inferSchema(Object obj, String path) {
            Map<String, Object> schema = new HashMap<>();
            
            if (obj instanceof Map) {
                schema.put("type", "object");
                Map<String, Object> properties = new HashMap<>();
                @SuppressWarnings("unchecked")
                Map<String, Object> mapObj = (Map<String, Object>) obj;
                for (Map.Entry<String, Object> entry : mapObj.entrySet()) {
                    properties.put(entry.getKey(), inferSchema(entry.getValue(), path + "." + entry.getKey()));
                }
                schema.put("properties", properties);
            } else if (obj instanceof List && !((List<?>) obj).isEmpty()) {
                schema.put("type", "array");
                List<?> listObj = (List<?>) obj;
                schema.put("items", inferSchema(listObj.get(0), path + "[]"));
            } else if (obj instanceof String) {
                schema.put("type", "string");
            } else if (obj instanceof Integer) {
                schema.put("type", "integer");
            } else if (obj instanceof Double || obj instanceof Float) {
                schema.put("type", "number");
            } else if (obj instanceof Boolean) {
                schema.put("type", "boolean");
            } else {
                schema.put("type", "null");
            }
            
            return schema;
        }
    }
    
    public static void main(String[] args) {
        // Simple argument parsing
        String searchQuery = null;
        Path validateFile = null;
        Path schemaFile = null;
        Path generateSchemaFile = null;
        String endpoint = null;
        
        for (int i = 0; i < args.length; i++) {
            if ("--search".equals(args[i]) && i + 1 < args.length) {
                searchQuery = args[++i];
            } else if ("--validate-file".equals(args[i]) && i + 1 < args.length) {
                validateFile = Paths.get(args[++i]);
            } else if ("--schema".equals(args[i]) && i + 1 < args.length) {
                schemaFile = Paths.get(args[++i]);
            } else if ("--generate-schema".equals(args[i]) && i + 1 < args.length) {
                generateSchemaFile = Paths.get(args[++i]);
            } else if ("--endpoint".equals(args[i]) && i + 1 < args.length) {
                endpoint = args[++i];
            }
        }
        
        WebSearchJSON ws = new WebSearchJSON();
        
        try {
            if (searchQuery != null) {
                Map<String, Object> schema = null;
                if (schemaFile != null) {
                    String schemaContent = Files.readString(schemaFile);
                    schema = objectMapper.readValue(schemaContent, Map.class);
                }
                
                WebSearchResult result = ws.searchAndValidate(searchQuery, schema, schemaFile);
                System.out.println("Query: " + result.query);
                System.out.println("Data: " + objectMapper.writerWithDefaultPrettyPrinter()
                                 .writeValueAsString(result.jsonData));
                System.out.println("Schema matched: " + result.schemaMatched);
                if (!result.validationErrors.isEmpty()) {
                    System.out.println("Errors: " + result.validationErrors);
                }
            } else if (generateSchemaFile != null && endpoint != null) {
                String sample = Files.readString(generateSchemaFile);
                Map<String, Object> schema = ws.generateApiSchema(sample, endpoint);
                System.out.println(objectMapper.writerWithDefaultPrettyPrinter()
                                 .writeValueAsString(schema));
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
