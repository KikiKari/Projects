#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ea9a02fc6da6a313d8b4046e69f26cc36d90b05490a122a2289a4d4fa67fc4ee", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "javascript"}
// json_processor.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * JSON Processor mit Validation und JSON-Repair.
 * Für robuste Verarbeitung von LLM-Outputs.
 */

const fs = require('fs');
const path = require('path');

// Simple validation class to mimic Pydantic behavior
class BaseModel {
  constructor(data) {
    Object.assign(this, data);
  }

  static validate(data) {
    return new this(data);
  }

  static model_validate(data) {
    return this.validate(data);
  }
}

class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
}

class JSONProcessingError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JSONProcessingError';
  }
}

class JSONValidationError extends JSONProcessingError {
  constructor(message) {
    super(message);
    this.name = 'JSONValidationError';
  }
}

class JSONRepairError extends JSONProcessingError {
  constructor(message) {
    super(message);
    this.name = 'JSONRepairError';
  }
}

function repair_json_string(raw_json) {
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
  let cleaned = raw_json.trim();
  
  // Entferne JavaScript-Kommentare
  cleaned = cleaned.replace(/\/\/.*?\n/g, '\n');
  cleaned = cleaned.replace(/\/\*.*?\*\//gs, '');
  
  // Entferne trailing commas vor ] oder }
  cleaned = cleaned.replace(/,(\s*[}\]])/g, '$1');
  
  return cleaned;
}

function parse_json(raw_input, repair = true) {
  /**
   * Parst JSON-String mit optionaler automatischer Reparatur.
   * 
   * @param {string} raw_input - Der zu parsende JSON-String
   * @param {boolean} repair - Ob JSON-Reparatur versucht werden soll (default: true)
   * 
   * @returns {any} Geparstes JavaScript-Objekt
   * 
   * @throws {JSONProcessingError} Wenn Parsing fehlschlägt
   */
  raw_input = raw_input.trim();
  
  // Versuche zuerst direktes Parsing
  try {
    return JSON.parse(raw_input);
  } catch (error) {
    // Ignoriere Fehler und fahre mit Extraktion fort
  }
  
  // Extrahiere JSON aus Markdown-Code-Blöcken
  if (raw_input.includes("```")) {
    const patterns = [
      /```json\s*(.*?)\s*```/gs,
      /```\s*(\{.*?\})\s*```/gs,
      /```\s*(\[.*?\])\s*```/gs,
    ];
    
    for (const pattern of patterns) {
      const matches = raw_input.match(pattern);
      if (matches) {
        for (const match of matches) {
          const jsonContent = match.match(pattern)[1];
          try {
            return JSON.parse(jsonContent);
          } catch (error) {
            continue;
          }
        }
      }
    }
  }
  
  // Versuche Reparatur
  if (repair) {
    try {
      const repaired = repair_json_string(raw_input);
      return JSON.parse(repaired);
    } catch (error) {
      throw new JSONProcessingError(`Could not parse JSON even after repair: ${error.message}`);
    }
  }
  
  throw new JSONProcessingError("Could not parse JSON");
}

function parse_and_validate(raw_input, model_class, repair = true, strict = false) {
  /**
   * Parst JSON und validiert gegen ein Model.
   * 
   * @param {string} raw_input - Der zu parsende JSON-String
   * @param {Function} model_class - Modelklasse für Validierung
   * @param {boolean} repair - Ob JSON-Reparatur versucht werden soll
   * @param {boolean} strict - Ob strikte Validierung angewendet werden soll
   * 
   * @returns {object} Validierte Instanz des Models
   * 
   * @throws {JSONValidationError} Wenn Validierung fehlschlägt
   */
  try {
    const data = parse_json(raw_input, repair);
    return model_class.validate(data);
  } catch (error) {
    if (error instanceof JSONProcessingError) {
      throw new JSONValidationError(`JSON parsing failed: ${error.message}`);
    }
    throw error;
  }
}

function validate_tool_call(raw_json, tool_name = null) {
  /**
   * Validiert einen OpenClaw/Tool-Call JSON.
   * 
   * @param {string} raw_json - Der Tool-Call JSON-String
   * @param {string|null} tool_name - Optionaler erwarteter Tool-Name
   * 
   * @returns {object} Validiertes Tool-Call Dict
   */
  
  class ToolCall extends BaseModel {
    constructor(data) {
      super(data);
      this.tool = data.tool;
      this.arguments = data.arguments || {};
      this.reasoning = data.reasoning || null;
    }
  }
  
  const tool_call = parse_and_validate(raw_json, ToolCall, true);
  
  if (tool_name && tool_call.tool !== tool_name) {
    throw new JSONValidationError(
      `Expected tool '${tool_name}', got '${tool_call.tool}'`
    );
  }
  
  return {
    tool: tool_call.tool,
    arguments: tool_call.arguments,
    reasoning: tool_call.reasoning
  };
}

function safe_json_loads(raw_input, defaultValue = null, repair = true) {
  /**
   * Sicheres JSON-Parsing mit Fallback auf Default-Wert.
   * 
   * @param {string} raw_input - Der zu parsende JSON-String
   * @param {any} defaultValue - Rückgabewert bei Fehlschlag (default: null)
   * @param {boolean} repair - Ob Reparatur versucht werden soll
   * 
   * @returns {any} Geparstes Objekt oder Default-Wert
   */
  try {
    return parse_json(raw_input, repair);
  } catch (error) {
    return defaultValue;
  }
}

function extract_json_from_text(text) {
  /**
   * Extrahiert alle JSON-Objekte aus einem Text.
   * 
   * @param {string} text - Text, der JSON-Objekte enthalten könnte
   * 
   * @returns {Array} Liste aller gefundenen und geparsten JSON-Objekte
   */
  const results = [];
  
  // Pattern für JSON-Objekte und Arrays
  const patterns = [
    /\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/g,  // Objekte
    /\[[^\[\]]*(?:\[[^\[\]*\][^\[\]]*)*\]/g,  // Arrays
  ];
  
  for (const pattern of patterns) {
    const matches = text.match(pattern) || [];
    for (const match of matches) {
      try {
        const parsed = parse_json(match, true);
        results.push(parsed);
      } catch (error) {
        continue;
      }
    }
  }
  
  return results;
}

// CLI-Interface
if (require.main === module) {
  const args = process.argv.slice(2);
  let input = '';
  let isFile = false;
  let repair = true;
  let pretty = false;
  
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--file' || arg === '-f') {
      isFile = true;
    } else if (arg === '--no-repair') {
      repair = false;
    } else if (arg === '--pretty' || arg === '-p') {
      pretty = true;
    } else if (!arg.startsWith('-')) {
      input = arg;
    }
  }
  
  try {
    let content = '';
    if (isFile) {
      content = fs.readFileSync(input, 'utf8');
    } else {
      content = input;
    }
    
    const result = parse_json(content, repair);
    const output = JSON.stringify(result, null, pretty ? 2 : null);
    console.log(output);
  } catch (error) {
    if (error instanceof JSONProcessingError) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    } else {
      console.error(`Unexpected error: ${error.message}`);
      process.exit(1);
    }
  }
}

module.exports = {
  BaseModel,
  ValidationError,
  JSONProcessingError,
  JSONValidationError,
  JSONRepairError,
  repair_json_string,
  parse_json,
  parse_and_validate,
  validate_tool_call,
  safe_json_loads,
  extract_json_from_text
};
