#!/usr/bin/env node
// json_schema_validator.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
 * Erweitert Pydantic mit externen Schema-Dateien.
 */

const fs = require('fs');
const path = require('path');

// Dynamically import modules that might not be available
let HAS_JSONSCHEMA = false;
let validateFunction = null;
let JSONSchemaValidationError = null;

let HAS_AJV = false;
let Ajv = null;
let ajvInstance = null;

// Try to load jsonschema
try {
  const jsonschema = require('jsonschema');
  validateFunction = jsonschema.validate;
  JSONSchemaValidationError = jsonschema.ValidationError;
  HAS_JSONSCHEMA = true;
} catch (e) {
  // jsonschema not available
}

// Try to load ajv as fallback
try {
  Ajv = require('ajv');
  const addFormats = require('ajv-formats');
  ajvInstance = new Ajv({allErrors: true});
  addFormats(ajvInstance);
  HAS_AJV = true;
} catch (e) {
  // ajv not available
}

// Custom error classes
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

class JSONProcessingError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JSONProcessingError';
  }
}

/**
 * Parst JSON mit optionaler Reparatur.
 * 
 * @param {string} raw_input - JSON-String
 * @param {boolean} repair - Ob Reparatur versucht werden soll
 * @returns {any} Geparste Daten
 */
function parse_json(raw_input, repair = true) {
  try {
    return JSON.parse(raw_input);
  } catch (e) {
    if (repair) {
      // Versuche einfache Reparaturen
      let repaired = raw_input.trim();
      
      // Entferne trailing commas
      repaired = repaired.replace(/,\s*([\]}])/g, '$1');
      
      // Ersetze single quotes mit double quotes (nur bei keys und strings)
      // Dies ist eine vereinfachte Reparatur - in der Praxis komplexer
      try {
        return JSON.parse(repaired);
      } catch (e2) {
        throw new JSONProcessingError(`Invalid JSON: ${e.message}`);
      }
    } else {
      throw new JSONProcessingError(`Invalid JSON: ${e.message}`);
    }
  }
}

/**
 * Lädt ein JSON Schema aus verschiedenen Quellen.
 * 
 * @param {string|Object} schema_source - Pfad zur Schema-Datei oder Schema-Dict oder JSON String
 * @returns {Object} Schema als Dictionary
 */
function load_schema(schema_source) {
  /**
   * Lädt ein JSON Schema aus verschiedenen Quellen.
   * 
   * Args:
   *     schema_source: Pfad zur Schema-Datei oder Schema-Dict oder JSON String
   * 
   * Returns:
   *     Schema als Dictionary
   */
  if (typeof schema_source === 'object' && schema_source !== null) {
    return schema_source;
  }

  // Prüfe ob es ein Pfad ist
  if (typeof schema_source === 'string') {
    try {
      if (fs.existsSync(schema_source)) {
        const content = fs.readFileSync(schema_source, 'utf8');
        return JSON.parse(content);
      }
    } catch (e) {
      if (e instanceof Error && e.name === 'SyntaxError') {
        throw new SchemaValidationError(`Invalid JSON in schema file: ${e.message}`);
      }
      // Falls Datei nicht existiert, weiter mit JSON parsen
    }

    // Versuche als JSON String zu parsen
    try {
      return JSON.parse(schema_source);
    } catch (e) {
      throw new SchemaValidationError(`Schema not found or invalid: ${schema_source}`);
    }
  }

  throw new SchemaValidationError(`Schema not found or invalid: ${schema_source}`);
}

/**
 * Validiert Daten gegen ein JSON Schema.
 * 
 * @param {any} data - Zu validierende Daten
 * @param {string|Object} schema - JSON Schema (Pfad, String oder Dict)
 * @param {string} draft - JSON Schema Draft Version ("auto", "draft7", "2020-12")
 * @returns {boolean} True wenn valid
 */
function validate_with_jsonschema(data, schema, draft = "auto") {
  /**
   * Validiert Daten gegen ein JSON Schema.
   * 
   * Args:
   *     data: Zu validierende Daten
   *     schema: JSON Schema (Pfad, String oder Dict)
   *     draft: JSON Schema Draft Version ("auto", "draft7", "2020-12")
   * 
   * Returns:
   *     True wenn valid
   * 
   * Raises:
   *     SchemaValidationError: Wenn Validierung fehlschlägt
   */
  if (!HAS_JSONSCHEMA && !HAS_AJV) {
    throw new SchemaValidationError("Neither jsonschema nor ajv installed. Run: npm install jsonschema or npm install ajv ajv-formats");
  }

  const schema_dict = load_schema(schema);

  try {
    if (HAS_JSONSCHEMA) {
      const result = validateFunction(data, schema_dict);
      if (!result.valid) {
        const error = result.errors[0];
        const path = error.path || [];
        throw new SchemaValidationError(`Schema validation failed: ${error.message} at ${JSON.stringify(path)}`);
      }
      return true;
    } else if (HAS_AJV) {
      const validate = ajvInstance.compile(schema_dict);
      const valid = validate(data);
      if (!valid) {
        const error = validate.errors[0];
        const path = error.instancePath ? error.instancePath.split('/').filter(p => p) : [];
        throw new SchemaValidationError(`Schema validation failed: ${error.message} at ${JSON.stringify(path)}`);
      }
      return true;
    }
  } catch (e) {
    if (e instanceof SchemaValidationError) {
      throw e;
    }
    throw new SchemaValidationError(`Schema validation error: ${e.message}`);
  }
}

/**
 * Parst, repariert und validiert JSON gegen Schema.
 * 
 * @param {string} raw_input - JSON-String
 * @param {string|Object} schema - JSON Schema
 * @param {boolean} repair - Ob Reparatur versucht werden soll
 * @returns {any} Validierte Daten
 */
function validate_and_convert(raw_input, schema, repair = true) {
  /**
   * Parst, repariert und validiert JSON gegen Schema.
   * 
   * Args:
   *     raw_input: JSON-String
   *     schema: JSON Schema
   *     repair: Ob Reparatur versucht werden soll
   * 
   * Returns:
   *     Validierte Daten
   */
  const data = parse_json(raw_input, repair);
  validate_with_jsonschema(data, schema);
  return data;
}

/**
 * Hilfsklasse zum Erstellen von JSON Schemas.
 */
class SchemaBuilder {
  /** Hilfsklasse zum Erstellen von JSON Schemas. */

  /**
   * Erstellt ein Object-Schema.
   * @param {Object} properties - Eigenschaften
   * @param {string[]} required - Erforderliche Felder
   * @returns {Object} Schema
   */
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

  /**
   * Erstellt ein String-Schema.
   * @param {string[]} enum_values - Enum-Werte
   * @param {string} pattern - Regex-Pattern
   * @param {number} min_length - Minimale Länge
   * @returns {Object} Schema
   */
  static string(enum_values = null, pattern = null, min_length = null) {
    /** Erstellt ein String-Schema. */
    const schema = {type: "string"};
    if (enum_values) {
      schema.enum = enum_values;
    }
    if (pattern) {
      schema.pattern = pattern;
    }
    if (min_length !== null) {
      schema.minLength = min_length;
    }
    return schema;
  }

  /**
   * Erstellt ein Integer-Schema.
   * @param {number} minimum - Minimalwert
   * @param {number} maximum - Maximalwert
   * @returns {Object} Schema
   */
  static integer(minimum = null, maximum = null) {
    /** Erstellt ein Integer-Schema. */
    const schema = {type: "integer"};
    if (minimum !== null) {
      schema.minimum = minimum;
    }
    if (maximum !== null) {
      schema.maximum = maximum;
    }
    return schema;
  }

  /**
   * Erstellt ein Array-Schema.
   * @param {Object} items - Item-Schema
   * @param {number} min_items - Minimale Anzahl Items
   * @returns {Object} Schema
   */
  static array(items, min_items = null) {
    /** Erstellt ein Array-Schema. */
    const schema = {type: "array", items: items};
    if (min_items !== null) {
      schema.minItems = min_items;
    }
    return schema;
  }
}

// Command line interface
async function main() {
  const { Command } = require('commander');
  const program = new Command();

  program
    .description('JSON Schema Validator')
    .argument('<input>', 'JSON file or string')
    .option('-s, --schema <schema>', 'Schema file')
    .option('-f, --file', 'Input is file')
    .option('-r, --repair', 'Attempt to repair JSON', true)
    .action((input, options) => {
      // Lade Input (Auto-detect file vs string)
      let raw_input;
      if (options.file || (fs.existsSync(input) && fs.statSync(input).isFile())) {
        raw_input = fs.readFileSync(input, 'utf8');
      } else {
        raw_input = input;
      }

      try {
        const result = validate_and_convert(raw_input, options.schema, options.repair);
        console.log(JSON.stringify(result, null, 2));
        console.error("\n✓ Validation passed");
      } catch (e) {
        if (e instanceof JSONProcessingError || e instanceof SchemaValidationError) {
          console.error(`✗ Validation failed: ${e.message}`);
          process.exit(1);
        } else {
          console.error(`✗ Unexpected error: ${e.message}`);
          process.exit(1);
        }
      }
    });

  await program.parseAsync(process.argv);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  SchemaValidationError,
  load_schema,
  validate_with_jsonschema,
  validate_and_convert,
  SchemaBuilder,
  parse_json,
  JSONProcessingError,
  JSONValidationError
};
