#!/usr/bin/env node
// json_batch_processor.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
 */

const fs = require('fs');
const path = require('path');
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');

// Simple JSON repair function (basic implementation)
function repairJson(jsonString) {
  // Entferne führende/trailing whitespace
  jsonString = jsonString.trim();
  
  // Ersetze einfache Anführungszeichen durch doppelte (wenn nicht escaped)
  jsonString = jsonString.replace(/'/g, '"');
  
  // Entferne trailing Kommas
  jsonString = jsonString.replace(/,\s*([\]}])/g, '$1');
  
  return jsonString;
}

// Parse JSON with optional repair
function parseJson(content, repair = true) {
  try {
    return JSON.parse(content);
  } catch (e) {
    if (repair) {
      try {
        const repaired = repairJson(content);
        return JSON.parse(repaired);
      } catch (repairError) {
        throw new Error(`JSON parse error: ${e.message}`);
      }
    } else {
      throw new Error(`JSON parse error: ${e.message}`);
    }
  }
}

// BatchResult Klasse
class BatchResult {
  constructor(index, source, success, data = null, error = null) {
    this.index = index;
    this.source = source;
    this.success = success;
    this.data = data;
    this.error = error;
  }

  toDict() {
    return {
      index: this.index,
      source: this.source,
      success: this.success,
      data: this.data,
      error: this.error
    };
  }
}

// Liest JSON-Lines (NDJSON) Datei Zeile für Zeile
function* readJsonl(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  for (let lineNum = 0; lineNum < lines.length; lineNum++) {
    const line = lines[lineNum].trim();
    if (!line) continue;
    
    try {
      yield JSON.parse(line);
    } catch (e) {
      yield new BatchResult(
        lineNum + 1,
        `${filePath}:${lineNum + 1}`,
        false,
        null,
        `JSON decode error: ${e.message}`
      );
    }
  }
}

// Verarbeitet eine Liste von Inputs parallel
async function processBatch(inputs, processor, maxWorkers = 4) {
  const results = [];
  const workers = [];
  const workerPromises = [];
  
  // Node.js unterstützt keine echte Thread-Pools wie Python,
  // daher simulieren wir parallele Verarbeitung mit Promises
  const promises = inputs.map((inp, idx) => 
    Promise.resolve().then(() => processor(inp, idx))
  );
  
  // Warte auf alle Promises
  for (const promise of promises) {
    try {
      const result = await promise;
      results.push(result);
    } catch (e) {
      // Im Fehlerfall müssten wir den Index kennen, was hier schwierig ist
      results.push(new BatchResult(
        results.length,
        'unknown',
        false,
        null,
        `Unexpected error: ${e.message}`
      ));
    }
  }
  
  // Sortiere nach Index
  results.sort((a, b) => a.index - b.index);
  return results;
}

// Verarbeitet mehrere JSON-Dateien im Batch
async function processFileBatch(filePaths, repair = true, validateModel = null, maxWorkers = 4) {
  const processor = async (filePath, idx) => {
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      
      // In JS gibt es kein Pydantic, daher überspringen wir die Validierung
      const data = parseJson(content, repair);
      
      return new BatchResult(
        idx,
        filePath,
        true,
        data
      );
    } catch (e) {
      return new BatchResult(
        idx,
        filePath,
        false,
        null,
        e.message
      );
    }
  };
  
  return await processBatch(filePaths, processor, maxWorkers);
}

// Verarbeitet eine JSON-Lines Datei
function processJsonlFile(filePath, repair = true, validateModel = null) {
  const results = [];
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  for (let lineNum = 0; lineNum < lines.length; lineNum++) {
    const line = lines[lineNum].trim();
    if (!line) continue;
    
    try {
      // In JS gibt es kein Pydantic, daher überspringen wir die Validierung
      const data = parseJson(line, repair);
      
      results.push(new BatchResult(
        lineNum + 1,
        `${filePath}:${lineNum + 1}`,
        true,
        data
      ));
    } catch (e) {
      results.push(new BatchResult(
        lineNum + 1,
        `${filePath}:${lineNum + 1}`,
        false,
        null,
        e.message
      ));
    }
  }
  
  return results;
}

// Schreibt BatchResult-Liste als JSON-Lines
function writeJsonl(results, outputPath, onlySuccessful = true) {
  const fd = fs.openSync(outputPath, 'w');
  
  for (const result of results) {
    if (onlySuccessful && !result.success) continue;
    const jsonLine = JSON.stringify(result.toDict());
    fs.writeSync(fd, jsonLine + '\n');
  }
  
  fs.closeSync(fd);
}

// Hauptfunktion
async function main() {
  const args = process.argv.slice(2);
  const options = {
    inputs: [],
    jsonl: false,
    repair: true,
    workers: 4,
    output: null,
    summary: false
  };
  
  // Einfacher Argument Parser
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (arg === '--jsonl' || arg === '-l') {
      options.jsonl = true;
    } else if (arg === '--repair' || arg === '-r') {
      options.repair = true;
    } else if (arg === '--workers' || arg === '-w') {
      options.workers = parseInt(args[++i]);
    } else if (arg === '--output' || arg === '-o') {
      options.output = args[++i];
    } else if (arg === '--summary' || arg === '-s') {
      options.summary = true;
    } else if (!arg.startsWith('-')) {
      options.inputs.push(arg);
    }
  }
  
  if (options.inputs.length === 0) {
    console.error('ERROR: No input files provided');
    process.exit(1);
  }
  
  let allResults = [];
  
  if (options.jsonl) {
    // JSON-Lines Modus
    for (const inputPath of options.inputs) {
      const results = processJsonlFile(inputPath, options.repair);
      allResults = allResults.concat(results);
    }
  } else {
    // Standard JSON Batch
    allResults = await processFileBatch(
      options.inputs,
      options.repair,
      null,
      options.workers
    );
  }
  
  // Ausgabe
  const successful = allResults.filter(r => r.success).length;
  const failed = allResults.length - successful;
  
  if (options.summary) {
    console.log(`Processed: ${allResults.length}`);
    console.log(`Successful: ${successful}`);
    console.log(`Failed: ${failed}`);
  } else {
    for (const result of allResults) {
      if (result.success) {
        console.log(JSON.stringify(result.data));
      } else {
        console.error(`ERROR [${result.source}]: ${result.error}`);
      }
    }
  }
  
  // Optional: JSONL Output
  if (options.output) {
    writeJsonl(allResults, options.output, false);
    console.error(`\nResults written to: ${options.output}`);
  }
  
  // Exit code
  process.exit(failed === 0 ? 0 : 1);
}

if (require.main === module) {
  main().catch(e => {
    console.error(e);
    process.exit(1);
  });
}

module.exports = {
  BatchResult,
  readJsonl,
  processBatch,
  processFileBatch,
  processJsonlFile,
  writeJsonl,
  parseJson
};
