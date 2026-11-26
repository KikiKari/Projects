#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "d77d877d523f3b4a2cd557ab78c9448e88febd5fe8151cc5a34ee224689ee021", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "javascript"}
// json_websearch.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * JSON Utils + WebSearch integration.
 * Fetch API schemas from web, validate real API responses, batch-validate endpoints.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Add json-utils to path
const jsonUtilsPath = path.join(__dirname, '..', '..', '..', 'json-utils', 'scripts');

let JSON_UTILS_AVAILABLE = false;
let parseJson, parseAndValidate, validateWithJsonschema;

try {
    // Dynamically import json-utils functions
    const jsonProcessor = await import(path.join(jsonUtilsPath, 'json_processor.js'));
    const jsonSchemaValidator = await import(path.join(jsonUtilsPath, 'json_schema_validator.js'));
    
    parseJson = jsonProcessor.parseJson;
    parseAndValidate = jsonProcessor.parseAndValidate;
    validateWithJsonschema = jsonSchemaValidator.validateWithJsonschema;
    
    JSON_UTILS_AVAILABLE = true;
} catch (error) {
    console.warn("Warning: json-utils not found. Some features disabled.");
}

class WebSearchResult {
    constructor(query, json_data, validation_errors, schema_matched, source_url) {
        this.query = query;
        this.json_data = json_data;
        this.validation_errors = validation_errors;
        this.schema_matched = schema_matched;
        this.source_url = source_url;
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
    
    constructor(use_repair = true) {
        this.use_repair = use_repair;
        this.json_available = JSON_UTILS_AVAILABLE;
    }
    
    /**
     * Search web for JSON data, validate against schema.
     * 
     * This is a placeholder - in real usage, this would:
     * 1. Call WebSearch to find API docs
     * 2. Extract JSON examples/schemas from results
     * 3. Parse and validate with json-utils
     */
    search_and_validate(query, schema = null, schema_path = null) {
        // Simulate web search result (would be actual search in production)
        const mockResponse = {
            api: query ? query.split(' ')[0] : "unknown",
            version: "1.0",
            endpoints: [
                { path: "/items", method: "GET" },
                { path: "/items", method: "POST" }
            ]
        };
        
        // Validate with json-utils if available
        let validationErrors = [];
        let schemaMatched = false;
        
        if (this.json_available && (schema || schema_path)) {
            try {
                if (schema_path) {
                    validateWithJsonschema(mockResponse, schema_path);
                }
                schemaMatched = true;
            } catch (e) {
                validationErrors.push(e.toString());
            }
        }
        
        return new WebSearchResult(
            query,
            mockResponse,
            validationErrors,
            schemaMatched,
            `https://api.github.com/search?q=${encodeURIComponent(query)}`
        );
    }
    
    /**
     * Validate an API response with auto-repair.
     * 
     * Uses json-utils for robust parsing.
     */
    validate_api_response(response_data, endpoint, expected_schema = null) {
        if (!this.json_available) {
            return JSON.parse(response_data);
        }
        
        // Use json-utils parser with auto-repair
        let result = parseJson(response_data, this.use_repair);
        
        if (expected_schema) {
            try {
                parseAndValidate(JSON.stringify(result), expected_schema);
            } catch (e) {
                console.log(`Schema validation failed for ${endpoint}: ${e}`);
            }
        }
        
        return result;
    }
    
    /**
     * Batch-validate multiple API endpoint responses.
     */
    batch_validate_endpoints(endpoints, responses, schema_path = null) {
        let results = [];
        for (let i = 0; i < endpoints.length; i++) {
            const endpoint = endpoints[i];
            const response = responses[i];
            
            try {
                let jsonData = this.validate_api_response(response, endpoint);
                results.push(new WebSearchResult(
                    endpoint,
                    jsonData,
                    [],
                    true,
                    endpoint
                ));
            } catch (e) {
                results.push(new WebSearchResult(
                    endpoint,
                    {},
                    [e.toString()],
                    false,
                    endpoint
                ));
            }
        }
        return results;
    }
    
    /**
     * Generate JSON Schema from sample API response.
     */
    generate_api_schema(sample_response, endpoint) {
        if (!this.json_available) {
            return {};
        }
        
        let data = parseJson(sample_response);
        
        // Basic schema generation
        function inferSchema(obj, path = "root") {
            if (typeof obj === 'object' && obj !== null && !Array.isArray(obj)) {
                return {
                    type: "object",
                    properties: Object.fromEntries(
                        Object.entries(obj).map(([k, v]) => [
                            k, 
                            inferSchema(v, `${path}.${k}`)
                        ])
                    )
                };
            } else if (Array.isArray(obj) && obj.length > 0) {
                return {
                    type: "array",
                    items: inferSchema(obj[0], `${path}[]`)
                };
            } else if (typeof obj === 'string') {
                return { type: "string" };
            } else if (Number.isInteger(obj)) {
                return { type: "integer" };
            } else if (typeof obj === 'number') {
                return { type: "number" };
            } else if (typeof obj === 'boolean') {
                return { type: "boolean" };
            } else {
                return { type: "null" };
            }
        }
        
        const schema = {
            $schema: "http://json-schema.org/draft-07/schema#",
            title: `${endpoint} Response Schema`,
            ...inferSchema(data)
        };
        
        return schema;
    }
}

function main() {
    // Simple argument parsing
    const args = {};
    for (let i = 2; i < process.argv.length; i++) {
        const arg = process.argv[i];
        if (arg.startsWith('--')) {
            const key = arg.slice(2);
            if (i + 1 < process.argv.length && !process.argv[i + 1].startsWith('--')) {
                args[key] = process.argv[++i];
            } else {
                args[key] = true;
            }
        }
    }
    
    const ws = new WebSearchJSON();
    
    if (args.search) {
        const result = ws.search_and_validate(args.search, null, args.schema || null);
        console.log(`Query: ${result.query}`);
        console.log(`Data: ${JSON.stringify(result.json_data, null, 2)}`);
        console.log(`Schema matched: ${result.schema_matched}`);
        if (result.validation_errors.length > 0) {
            console.log(`Errors: ${result.validation_errors}`);
        }
    } else if (args['generate-schema'] && args.endpoint) {
        const sample = fs.readFileSync(args['generate-schema'], 'utf8');
        const schema = ws.generate_api_schema(sample, args.endpoint);
        console.log(JSON.stringify(schema, null, 2));
    }
}

if (import.meta.url === `file://${process.argv[1]}`) {
    main();
}

export { WebSearchJSON, WebSearchResult };
