#!/usr/bin/env node
// validate_tool_output.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/validate_tool_output.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/validate_tool_output.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/**
 * Validiert Tool-Outputs gegen ein Pydantic-Schema.
 * Für OpenClaw Tool-Call-Validierung.
 */

const fs = require('fs');
const path = require('path');
const process = require('process');

// Zod als Ersatz für Pydantic
const { z } = require('zod');

class JSONValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JSONValidationError';
  }
}

function parseAndValidate(jsonInput, schema, options = {}) {
  const { repair = true, strict = false } = options;
  
  let jsonData;
  try {
    jsonData = typeof jsonInput === 'string' ? JSON.parse(jsonInput) : jsonInput;
  } catch (error) {
    throw new JSONValidationError(`Invalid JSON: ${error.message}`);
  }
  
  try {
    const result = schema.parse(jsonData);
    return result;
  } catch (error) {
    if (repair && error instanceof z.ZodError) {
      // Versuche Reparatur durch partielle Validierung
      try {
        const partialResult = {};
        for (const key in jsonData) {
          try {
            if (schema.shape[key]) {
              partialResult[key] = schema.shape[key].parse(jsonData[key]);
            } else if (!strict) {
              partialResult[key] = jsonData[key];
            }
          } catch (fieldError) {
            if (!strict) {
              partialResult[key] = jsonData[key];
            }
          }
        }
        return partialResult;
      } catch (partialError) {
        throw new JSONValidationError(`Validation failed: ${error.message}`);
      }
    }
    throw new JSONValidationError(`Validation failed: ${error.message}`);
  }
}

function createDynamicModel(schema) {
  /** Erstellt ein dynamisches Zod-Modell aus einem JSON-Schema. */
  const fields = {};
  
  const properties = schema.properties || {};
  const requiredFields = new Set(schema.required || []);
  
  for (const [fieldName, fieldInfo] of Object.entries(properties)) {
    let fieldSchema;
    
    const jsonType = fieldInfo.type || 'string';
    switch (jsonType) {
      case 'integer':
        fieldSchema = z.number().int();
        break;
      case 'number':
        fieldSchema = z.number();
        break;
      case 'boolean':
        fieldSchema = z.boolean();
        break;
      case 'array':
        fieldSchema = z.array(z.any());
        break;
      case 'object':
        fieldSchema = z.record(z.any());
        break;
      case 'string':
      default:
        fieldSchema = z.string();
    }
    
    // Beschreibung hinzufügen, falls vorhanden
    if (fieldInfo.description) {
      fieldSchema = fieldSchema.describe(fieldInfo.description);
    }
    
    // Default-Wert setzen
    if (fieldInfo.default !== undefined) {
      fieldSchema = fieldSchema.default(fieldInfo.default);
    }
    
    // Feld optional machen, wenn nicht required
    if (!requiredFields.has(fieldName)) {
      fieldSchema = fieldSchema.optional();
      if (fieldInfo.default === undefined) {
        fieldSchema = fieldSchema.nullable();
      }
    }
    
    fields[fieldName] = fieldSchema;
  }
  
  return z.object(fields);
}

function main() {
  const args = parseArguments();
  
  // Lade Schema
  let schema;
  try {
    const schemaContent = fs.readFileSync(args.schema, 'utf8');
    schema = JSON.parse(schemaContent);
  } catch (error) {
    console.error(`Error loading schema: ${error.message}`);
    process.exit(1);
  }
  
  // Lade Input
  let rawInput;
  try {
    if (args.file) {
      rawInput = fs.readFileSync(args.json_input, 'utf8');
    } else {
      rawInput = args.json_input;
    }
  } catch (error) {
    console.error(`Error loading input: ${error.message}`);
    process.exit(1);
  }
  
  // Erstelle dynamisches Modell und validiere
  try {
    const modelSchema = createDynamicModel(schema);
    const result = parseAndValidate(rawInput, modelSchema, { 
      repair: args.repair, 
      strict: args.strict 
    });
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    if (error instanceof JSONValidationError) {
      console.error(`Validation error: ${error.message}`);
    } else {
      console.error(`Unexpected error: ${error.message}`);
    }
    process.exit(1);
  }
}

function parseArguments() {
  const argv = process.argv.slice(2);
  const args = {
    json_input: null,
    schema: null,
    file: false,
    repair: true,
    strict: false
  };
  
  const positionalArgs = [];
  
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    
    if (arg === '--schema' || arg === '-s') {
      args.schema = argv[++i];
    } else if (arg === '--file' || arg === '-f') {
      args.file = true;
    } else if (arg === '--repair' || arg === '-r') {
      args.repair = true;
    } else if (arg === '--no-repair') {
      args.repair = false;
    } else if (arg === '--strict') {
      args.strict = true;
    } else if (!arg.startsWith('-')) {
      positionalArgs.push(arg);
    }
  }
  
  if (positionalArgs.length > 0) {
    args.json_input = positionalArgs[0];
  }
  
  if (!args.json_input) {
    console.error('Error: json_input argument is required');
    process.exit(1);
  }
  
  if (!args.schema) {
    console.error('Error: --schema/-s option is required');
    process.exit(1);
  }
  
  return args;
}

if (require.main === module) {
  main();
}

module.exports = {
  createDynamicModel,
  parseAndValidate,
  JSONValidationError
};
