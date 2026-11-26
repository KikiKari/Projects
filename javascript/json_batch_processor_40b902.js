#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "f736ac9fb06923c8ceb948d8f87cb942f9ef0522c4330fc173f8911c9217846b", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "javascript"}
// json_batch_processor.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
 */

const fs = require('fs');
const path = require('path');
const { program } = require('commander');

// Globale Variablen für Pydantic-ähnliche Validierung
let HAS_PYDANTIC = false;

// Versuche, ein Validierungsmodell zu laden (ähnlich Pydantic)
function loadValidationModel() {
    // In JS/Node gibt es kein direktes Äquivalent zu Pydantic
    // Dies wäre eine Stelle für zukünftige Integration
    return null;
}

// Fehlerklasse für JSON-Verarbeitungsfehler
class JSONProcessingError extends Error {
    constructor(message) {
        super(message);
        this.name = 'JSONProcessingError';
    }
}

// Ergebnisklasse für Batch-Verarbeitung
class BatchResult {
    /**
     * Ergebnis einer Batch-Verarbeitung.
     */
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

/**
 * Liest JSON-Lines (NDJSON) Datei Zeile für Zeile.
 * 
 * @param {string} filePath - Pfad zur .jsonl oder .ndjson Datei
 * @yields {object} Geparste JSON-Objekte
 */
function* readJsonl(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        
        try {
            yield JSON.parse(line);
        } catch (e) {
            yield new BatchResult(
                i + 1,
                `${filePath}:${i + 1}`,
                false,
                null,
                `JSON decode error: ${e.message}`
            );
        }
    }
}

/**
 * Verarbeitet eine Liste von Inputs parallel.
 * 
 * @param {Array} inputs - Liste der zu verarbeitenden Eingaben (Strings oder Pfade)
 * @param {Function} processor - Funktion, die (input, index) => BatchResult zurückgibt
 * @param {number} maxWorkers - Anzahl paralleler Worker
 * @returns {Promise<Array>} Liste der BatchResult-Objekte
 */
async function processBatch(inputs, processor, maxWorkers = 4) {
    const results = [];
    const workers = [];
    
    // Erstelle Worker-Promises
    for (let idx = 0; idx < inputs.length; idx++) {
        const inp = inputs[idx];
        const worker = processor(inp, idx);
        workers.push(worker);
    }
    
    // Warte auf alle Worker
    for (const worker of workers) {
        try {
            const result = await worker;
            results.push(result);
        } catch (e) {
            // Hier müsste der Index ermittelt werden - vereinfacht:
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

/**
 * Repariert einfache JSON-Fehler (sehr basic).
 * 
 * @param {string} jsonString - Der zu reparierende JSON-String
 * @returns {string} Reparierte JSON-Zeichenkette
 */
function repairJson(jsonString) {
    // Entferne führende/trailende Whitespace
    let fixed = jsonString.trim();
    
    // Versuche einfache Reparaturen
    try {
        // Prüfe auf fehlende Anführungszeichen bei Keys
        fixed = fixed.replace(/([{,]\s*)([^"\s][^:]*)(\s*:)/g, '$1"$2"$3');
        
        // Prüfe auf einfache anstelle doppelter Anführungszeichen
        fixed = fixed.replace(/(['`])([^'`]*)\1/g, '"$2"');
        
        // Prüfe auf trailing commas
        fixed = fixed.replace(/,\s*([}\]])/g, '$1');
        
        return fixed;
    } catch (e) {
        return jsonString;
    }
}

/**
 * Parst einen JSON-String mit optionaler Reparatur.
 * 
 * @param {string} jsonString - Der zu parsende JSON-String
 * @param {boolean} repair - Ob Reparaturversuch durchgeführt werden soll
 * @returns {object} Das geparste JSON-Objekt
 */
function parseJson(jsonString, repair = true) {
    try {
        return JSON.parse(jsonString);
    } catch (e) {
        if (repair) {
            try {
                const repaired = repairJson(jsonString);
                return JSON.parse(repaired);
            } catch (re) {
                throw new JSONProcessingError(`JSON parsing failed: ${e.message}`);
            }
        } else {
            throw new JSONProcessingError(`JSON parsing failed: ${e.message}`);
        }
    }
}

/**
 * Parst und validiert einen JSON-String (simuliert Pydantic).
 * 
 * @param {string} jsonString - Der zu parsende und validierende JSON-String
 * @param {Function|null} validateModel - Validierungsmodell (nicht implementiert)
 * @param {boolean} repair - Ob Reparaturversuch durchgeführt werden soll
 * @returns {object} Das geparste und validierte JSON-Objekt
 */
function parseAndValidate(jsonString, validateModel = null, repair = true) {
    const data = parseJson(jsonString, repair);
    
    // Wenn ein Validierungsmodell vorhanden wäre, würde hier die Validierung stattfinden
    // Da wir kein echtes Pydantic haben, geben wir einfach die Daten zurück
    
    return data;
}

/**
 * Verarbeitet mehrere JSON-Dateien im Batch.
 * 
 * @param {Array<string>} filePaths - Liste der Datei-Pfade
 * @param {boolean} repair - Ob JSON-Reparatur angewendet werden soll
 * @param {Function|null} validateModel - Optionales Validierungsmodell
 * @param {number} maxWorkers - Parallele Worker
 * @returns {Promise<Array>} Liste der BatchResult-Objekte
 */
async function processFileBatch(filePaths, repair = true, validateModel = null, maxWorkers = 4) {
    async function processor(filePath, idx) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            
            let data;
            if (validateModel && HAS_PYDANTIC) {
                data = parseAndValidate(content, validateModel, repair);
            } else {
                data = parseJson(content, repair);
            }
            
            return new BatchResult(
                idx,
                filePath,
                true,
                data
            );
        } catch (e) {
            if (e instanceof JSONProcessingError) {
                return new BatchResult(
                    idx,
                    filePath,
                    false,
                    null,
                    e.message
                );
            } else {
                return new BatchResult(
                    idx,
                    filePath,
                    false,
                    null,
                    `${e.constructor.name}: ${e.message}`
                );
            }
        }
    }
    
    return await processBatch(filePaths, processor, maxWorkers);
}

/**
 * Verarbeitet eine JSON-Lines Datei.
 * 
 * @param {string} filePath - Pfad zur .jsonl Datei
 * @param {boolean} repair - Ob Reparatur angewendet werden soll
 * @param {Function|null} validateModel - Optionales Validierungsmodell
 * @returns {Array} Liste der BatchResult-Objekte
 */
function processJsonlFile(filePath, repair = true, validateModel = null) {
    const results = [];
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    
    for (let lineNum = 0; lineNum < lines.length; lineNum++) {
        const line = lines[lineNum].trim();
        if (!line) continue;
        
        try {
            let data;
            if (validateModel && HAS_PYDANTIC) {
                data = parseAndValidate(line, validateModel, repair);
            } else {
                data = parseJson(line, repair);
            }
            
            results.push(new BatchResult(
                lineNum + 1,
                `${filePath}:${lineNum + 1}`,
                true,
                data
            ));
        } catch (e) {
            if (e instanceof JSONProcessingError) {
                results.push(new BatchResult(
                    lineNum + 1,
                    `${filePath}:${lineNum + 1}`,
                    false,
                    null,
                    e.message
                ));
            } else {
                results.push(new BatchResult(
                    lineNum + 1,
                    `${filePath}:${lineNum + 1}`,
                    false,
                    null,
                    `${e.constructor.name}: ${e.message}`
                ));
            }
        }
    }
    
    return results;
}

/**
 * Schreibt BatchResult-Liste als JSON-Lines.
 * 
 * @param {Array<BatchResult>} results - Liste der Ergebnisse
 * @param {string} outputPath - Ausgabedatei
 * @param {boolean} onlySuccessful - Nur erfolgreiche Ergebnisse schreiben
 */
function writeJsonl(results, outputPath, onlySuccessful = true) {
    const fd = fs.openSync(outputPath, 'w');
    
    for (const result of results) {
        if (onlySuccessful && !result.success) {
            continue;
        }
        fs.writeSync(fd, JSON.stringify(result.toDict()) + '\n');
    }
    
    fs.closeSync(fd);
}

/**
 * Hauptprogramm
 */
async function main() {
    program
        .description('Batch JSON Processor')
        .argument('<inputs...>', 'JSON files to process')
        .option('--jsonl, -l', 'Treat inputs as JSON-Lines files')
        .option('--repair, -r', 'Enable JSON repair', true)
        .option('--workers, -w <number>', 'Parallel workers', 4)
        .option('--output, -o <file>', 'Output JSON-Lines file')
        .option('--summary, -s', 'Show summary only')
        .parse();
    
    const options = program.opts();
    const inputs = program.args;
    
    let allResults = [];
    
    if (options.jsonl) {
        // JSON-Lines Modus
        for (const inputPath of inputs) {
            const results = processJsonlFile(inputPath, options.repair);
            allResults = allResults.concat(results);
        }
    } else {
        // Standard JSON Batch
        allResults = await processFileBatch(
            inputs,
            options.repair,
            null, // validateModel
            parseInt(options.workers)
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

// Starte das Programm
if (require.main === module) {
    main().catch(console.error);
}

module.exports = {
    BatchResult,
    readJsonl,
    processBatch,
    parseJson,
    parseAndValidate,
    processFileBatch,
    processJsonlFile,
    writeJsonl,
    JSONProcessingError
};
