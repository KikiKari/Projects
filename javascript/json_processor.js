#!/usr/bin/env node
// json_processor.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * JSON Processor mit Validierung und JSON-Repair.
 * Für robuste Verarbeitung von LLM-Outputs.
 */

const fs = require('fs');
const path = require('path');

// Prüfe ob zod installiert ist
let zod;
try {
  zod = require('zod');
} catch (e) {
  console.error("Error: zod not installed. Run: npm install zod");
  process.exit(1);
}

// Prüfe ob jsonrepair installiert ist
let jsonrepair;
let HAS_JSON_REPAIR = false;
try {
  jsonrepair = require('jsonrepair');
  HAS_JSON_REPAIR = true;
} catch (e) {
  console.warn("Warning: jsonrepair not installed. Run: npm install jsonrepair");
}

class JSONProcessingError extends Error {
  /** Base exception for JSON processing errors. */
  constructor(message) {
    super(message);
    this.name = 'JSONProcessingError';
  }
}

class JSONValidationError extends JSONProcessingError {
  /** Raised when JSON validation fails. */
  constructor(message) {
    super(message);
    this.name = 'JSONValidationError';
  }
}

class JSONRepairError extends JSONProcessingError {
  /** Raised when JSON repair fails. */
  constructor(message) {
    super(message);
    this.name = 'JSONRepairError';
  }
}

/**
 * Repariert häufige JSON-Fehler aus LLM-Outputs.
 * 
 * Behebt:
 * - Trailing commas
 * - Einzelne statt doppelte Quotes
 * - JavaScript-Style Kommentare
 * - Unescaped Zeilenumbrüche in Strings
 */
function repairJsonString(rawJson) {
  if (HAS_JSON_REPAIR) {
    try {
      const repaired = jsonrepair.repairJson(rawJson);
      return repaired;
    } catch (e) {
      throw new JSONRepairError(`JSON repair failed: ${e.message}`);
    }
  } else {
    // Fallback: Manuelle Reparaturen
    let cleaned = rawJson.trim();
    
    // Entferne JavaScript-Kommentare
    cleaned = cleaned.replace(/\/\/.*?\n/g, '\n');
    cleaned = cleaned.replace(/\/\*.*?\*\//gs, '');
    
    // Entferne trailing commas vor ] oder }
    cleaned = cleaned.replace(/,(\s*[}\]])/g, '$1');
    
    return cleaned;
  }
}

/**
 * Parst JSON-String mit optionaler automatischer Reparatur.
 * 
 * @param {string} rawInput - Der zu parsende JSON-String
 * @param {boolean} repair - Ob JSON-Reparatur versucht werden soll (default: true)
 * @returns {any} Geparstes JavaScript-Objekt
 * @throws {JSONProcessingError} Wenn Parsing fehlschlägt
 */
function parseJson(rawInput, repair = true) {
  rawInput = rawInput.trim();
  
  // Versuche zuerst direktes Parsing
  try {
    return JSON.parse(rawInput);
  } catch (e) {
    // Weiter im Code behandeln
  }
  
  // Extrahiere JSON aus Markdown-Code-Blöcken
  if (rawInput.includes("```")) {
    // Suche nach JSON in ```json ... ``` oder ``` ... ```
    const patterns = [
      /```json\s*(.*?)\s*```/gs,
      /```\s*(\{.*?\})\s*```/gs,
      /```\s*(\[.*?\])\s*```/gs,
    ];
    
    for (const pattern of patterns) {
      const matches = rawInput.matchAll(pattern);
      for (const match of matches) {
        try {
          return JSON.parse(match[1]);
        } catch (e) {
          continue;
        }
      }
    }
  }
  
  // Versuche Reparatur
  if (repair) {
    try {
      const repaired = repairJsonString(rawInput);
      return JSON.parse(repaired);
    } catch (e) {
      if (e instanceof JSONRepairError || e instanceof SyntaxError) {
        throw new JSONProcessingError(`Could not parse JSON even after repair: ${e.message}`);
      }
      throw e;
    }
  }
  
  throw new JSONProcessingError("Could not parse JSON");
}

/**
 * Parst JSON und validiert gegen ein Zod-Schema.
 * 
 * @param {string} rawInput - Der zu parsende JSON-String
 * @param {zod.ZodSchema} schema - Zod-Schema für Validierung
 * @param {boolean} repair - Ob JSON-Reparatur versucht werden soll
 * @returns {any} Validierte Daten
 * @throws {JSONValidationError} Wenn Validierung fehlschlägt
 */
function parseAndValidate(rawInput, schema, repair = true) {
  let data;
  try {
    data = parseJson(rawInput, repair);
  } catch (e) {
    if (e instanceof JSONProcessingError) {
      throw new JSONValidationError(`JSON parsing failed: ${e.message}`);
    }
    throw e;
  }
  
  try {
    const result = schema.parse(data);
    return result;
  } catch (e) {
    if (e instanceof zod.ZodError) {
      throw new JSONValidationError(`Zod validation failed: ${e.message}`);
    }
    throw e;
  }
}

/**
 * Validiert einen OpenClaw/Tool-Call JSON.
 * 
 * @param {string} rawJson - Der Tool-Call JSON-String
 * @param {string|null} toolName - Optionaler erwarteter Tool-Name
 * @returns {Object} Validiertes Tool-Call Dict
 */
function validateToolCall(rawJson, toolName = null) {
  const { z } = zod;
  
  const ToolCallSchema = z.object({
    tool: z.string().describe("Name of the tool to call"),
    arguments: z.record(z.any()).optional().describe("Tool arguments").default({}),
    reasoning: z.string().optional().describe("Optional reasoning")
  });
  
  const toolCall = parseAndValidate(rawJson, ToolCallSchema, true);
  
  if (toolName && toolCall.tool !== toolName) {
    throw new JSONValidationError(
      `Expected tool '${toolName}', got '${toolCall.tool}'`
    );
  }
  
  return {
    tool: toolCall.tool,
    arguments: toolCall.arguments || {},
    reasoning: toolCall.reasoning
  };
}

/**
 * Sicheres JSON-Parsing mit Fallback auf Default-Wert.
 * 
 * @param {string} rawInput - Der zu parsende JSON-String
 * @param {any} defaultValue - Rückgabewert bei Fehlschlag (default: null)
 * @param {boolean} repair - Ob Reparatur versucht werden soll
 * @returns {any} Geparstes Objekt oder Default-Wert
 */
function safeJsonLoads(rawInput, defaultValue = null, repair = true) {
  try {
    return parseJson(rawInput, repair);
  } catch (e) {
    if (e instanceof JSONProcessingError) {
      return defaultValue;
    }
    throw e;
  }
}

/**
 * Extrahiert alle JSON-Objekte aus einem Text.
 * 
 * @param {string} text - Text, der JSON-Objekte enthalten könnte
 * @returns {Array} Liste aller gefundenen und geparsten JSON-Objekte
 */
function extractJsonFromText(text) {
  const results = [];
  
  // Pattern für JSON-Objekte und Arrays
  const patterns = [
    /\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/g,  // Objekte
    /\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]/g,  // Arrays
  ];
  
  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(text)) !== null) {
      try {
        const parsed = parseJson(match[0], true);
        results.push(parsed);
      } catch (e) {
        if (!(e instanceof JSONProcessingError)) {
          throw e;
        }
        // Ignoriere parsing Fehler und fahre fort
      }
    }
  }
  
  return results;
}

// CLI-Interface
if (require.main === module) {
  const { Command } = require('commander');
  const program = new Command();
  
  program
    .description("JSON Processor with repair")
    .argument("<input>", "JSON string or file path")
    .option('-f, --file', 'Input is a file path')
    .option('-r, --repair', 'Enable JSON repair', true)
    .option('--no-repair', 'Disable JSON repair')
    .option('-p, --pretty', 'Pretty print output')
    .action((input, options) => {
      try {
        let content;
        if (options.file) {
          content = fs.readFileSync(input, 'utf8');
        } else {
          content = input;
        }
        
        const result = parseJson(content, options.repair);
        
        const output = JSON.stringify(result, null, options.pretty ? 2 : undefined);
        console.log(output);
      } catch (e) {
        if (e instanceof JSONProcessingError) {
          console.error(`Error: ${e.message}`);
          process.exit(1);
        } else {
          console.error(`Unexpected error: ${e.message}`);
          process.exit(1);
        }
      }
    });
  
  program.parse();
}

module.exports = {
  JSONProcessingError,
  JSONValidationError,
  JSONRepairError,
  repairJsonString,
  parseJson,
  parseAndValidate,
  validateToolCall,
  safeJsonLoads,
  extractJsonFromText
};
