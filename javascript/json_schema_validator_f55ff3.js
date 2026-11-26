#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "741e688d75518b78dc6cfc7f81aa7fe5254a54683e17c8fc743b2e1a4b0049ab", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "javascript"}
// json_schema_validator.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
 * Erweitert Pydantic mit externen Schema-Dateien.
 */

const fs = require('fs');
const path = require('path');
const process = require('process');

// Dynamischer Import für AJV (entspricht jsonschema in Python)
let ajvInstance = null;
let Ajv = null;
let HAS_AJV = false;

try {
  Ajv = require('ajv').default;
  ajvInstance = new Ajv({ allErrors: true });
  HAS_AJV = true;
} catch (e) {
  HAS_AJV = false;
}

// Fehlerklassen
class JSONProcessingError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JSONProcessingError';
  }
}

class JSONValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JSONValidationError';
  }
}

class SchemaValidationError extends JSONValidationError {
  /** Raised when JSON Schema validation fails. */
  constructor(message) {
    super(message);
    this.name = 'SchemaValidationError';
  }
}

// Hilfsfunktionen für JSON-Verarbeitung (ersetzt json_processor)
function parseJson(rawInput, repair = true) {
  /**
   * Parst JSON-String mit optionaler Reparatur.
   * 
   * @param {string} rawInput - JSON-String
   * @param {boolean} repair - Ob Reparatur versucht werden soll
   * @returns {any} Geparste Daten
   */
  try {
    return JSON.parse(rawInput);
  } catch (error) {
    if (repair) {
      // Versuche einfache Reparaturen
      let repaired = rawInput.trim();
      
      // Entferne trailing Kommas
      repaired = repaired.replace(/,\s*([\]}])/g, '$1');
      
      try {
        return JSON.parse(repaired);
      } catch (repairError) {
        throw new JSONProcessingError(`Failed to parse JSON: ${error.message}`);
      }
    } else {
      throw new JSONProcessingError(`Failed to parse JSON: ${error.message}`);
    }
  }
}

function loadSchema(schemaSource) {
  /**
   * Lädt ein JSON Schema aus verschiedenen Quellen.
   * 
   * @param {string|Object} schemaSource - Pfad zur Schema-Datei oder Schema-Dict oder JSON String
   * @returns {Object} Schema als Dictionary
   */
  if (typeof schemaSource === 'object' && schemaSource !== null) {
    return schemaSource;
  }

  try {
    // Prüfe ob es ein Dateipfad ist
    if (fs.existsSync(schemaSource) && fs.statSync(schemaSource).isFile()) {
      const content = fs.readFileSync(schemaSource, 'utf8');
      return JSON.parse(content);
    }
  } catch (fileError) {
    // Ignoriere File-Fehler und versuche als JSON String
  }

  // Versuche als JSON String zu parsen
  try {
    return JSON.parse(schemaSource);
  } catch (jsonError) {
    throw new SchemaValidationError(`Schema not found or invalid: ${schemaSource}`);
  }
}

function validateWithJsonSchema(data, schema, draft = "auto") {
  /**
   * Validiert Daten gegen ein JSON Schema.
   * 
   * @param {any} data - Zu validierende Daten
   * @param {string|Object} schema - JSON Schema (Pfad, String oder Dict)
   * @param {string} draft - JSON Schema Draft Version ("auto", "draft7", "2020-12")
   * @returns {boolean} True wenn valid
   * @throws {SchemaValidationError} Wenn Validierung fehlschlägt
   */
  if (!HAS_AJV) {
    throw new SchemaValidationError("ajv not installed. Run: npm install ajv");
  }

  const schemaDict = loadSchema(schema);
  
  try {
    const validate = ajvInstance.compile(schemaDict);
    const valid = validate(data);
    
    if (!valid) {
      const errors = validate.errors.map(err => `${err.message} at ${err.instancePath || '/'}`).join('; ');
      throw new SchemaValidationError(`Schema validation failed: ${errors}`);
    }
    
    return true;
  } catch (e) {
    if (e instanceof SchemaValidationError) {
      throw e;
    }
    throw new SchemaValidationError(`Schema validation error: ${e.message}`);
  }
}

function validateAndConvert(rawInput, schema, repair = true) {
  /**
   * Parst, repariert und validiert JSON gegen Schema.
   * 
   * @param {string} rawInput - JSON-String
   * @param {string|Object} schema - JSON Schema
   * @param {boolean} repair - Ob Reparatur versucht werden soll
   * @returns {any} Validierte Daten
   */
  const data = parseJson(rawInput, repair);
  validateWithJsonSchema(data, schema);
  return data;
}

class SchemaBuilder {
  /** Hilfsklasse zum Erstellen von JSON Schemas. */

  static object(properties, required = null) {
    /** Erstellt ein Object-Schema. */
    const schema = {
      type: "object",
      properties: properties
    };
    if (required) {
      schema.required = required;
    }
    return schema;
  }

  static string(enumValues = null, pattern = null, minLength = null) {
    /** Erstellt ein String-Schema. */
    const schema = { type: "string" };
    if (enumValues) {
      schema.enum = enumValues;
    }
    if (pattern) {
      schema.pattern = pattern;
    }
    if (minLength !== null) {
      schema.minLength = minLength;
    }
    return schema;
  }

  static integer(minimum = null, maximum = null) {
    /** Erstellt ein Integer-Schema. */
    const schema = { type: "integer" };
    if (minimum !== null) {
      schema.minimum = minimum;
    }
    if (maximum !== null) {
      schema.maximum = maximum;
    }
    return schema;
  }

  static array(items, minItems = null) {
    /** Erstellt ein Array-Schema. */
    const schema = { type: "array", items: items };
    if (minItems !== null) {
      schema.minItems = minItems;
    }
    return schema;
  }
}

function main() {
  const { program } = require('commander');
  
  program
    .description("JSON Schema Validator")
    .argument("<input>", "JSON file or string")
    .option("-s, --schema <schema>", "Schema file", "")
    .option("-f, --file", "Input is file")
    .option("-r, --repair", "Repair JSON", true)
    .action((input, options) => {
      if (!options.schema) {
        console.error("✗ Schema file is required");
        process.exit(1);
      }
      
      // Lade Input (Auto-detect file vs string)
      let rawInput;
      const inputPath = path.resolve(input);
      if (options.file || (fs.existsSync(inputPath) && fs.statSync(inputPath).isFile())) {
        rawInput = fs.readFileSync(inputPath, 'utf8');
      } else {
        rawInput = input;
      }
      
      try {
        const result = validateAndConvert(rawInput, options.schema, options.repair);
        console.log(JSON.stringify(result, null, 2));
        console.error("\n✓ Validation passed");
      } catch (error) {
        if (error instanceof JSONProcessingError || error instanceof SchemaValidationError) {
          console.error(`✗ Validation failed: ${error.message}`);
        } else {
          console.error(`✗ Unexpected error: ${error.message}`);
        }
        process.exit(1);
      }
    });
  
  program.parse();
}

if (require.main === module) {
  main();
}

module.exports = {
  SchemaValidationError,
  loadSchema,
  validateWithJsonSchema,
  validateAndConvert,
  SchemaBuilder,
  parseJson
};
