'use strict';

/**
 * @fileoverview json_processor.js — JSON-Verarbeitungs-Utilities.
 *
 * Stellt robuste Funktionen für JSON-Serialisierung, -Deserialisierung
 * und -Transformation bereit. Alle Funktionen beinhalten vollständige
 * Fehlerbehandlung und strukturiertes Logging.
 *
 * @module json_processor
 * @version 1.0.0
 * @license Internal Use Only
 *
 * @example
 * const { serializeToFormattedJson, parseJsonSafely } = require('./json_processor');
 *
 * const json = serializeToFormattedJson({ name: 'Alice', age: 30 });
 * const data = parseJsonSafely('{"key": "value"}');
 */

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Minimales strukturiertes Logging (ohne externe Dependencies)
// ---------------------------------------------------------------------------

/**
 * Erstellt einen einfachen strukturierten Logger.
 *
 * @param {string} moduleName - Name des Moduls für den Logger-Context.
 * @returns {{ debug: Function, info: Function, warn: Function, error: Function }}
 */
function createLogger(moduleName) {
    const logLevel = (process.env.ABSTRACTIONS_LOG_LEVEL || 'INFO').toUpperCase();
    const levels   = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3 };
    const threshold = levels[logLevel] ?? levels.INFO;
    const useJson   = (process.env.ABSTRACTIONS_JSON_LOGGING ?? '1') === '1';

    /**
     * @param {string} level
     * @param {string} message
     * @param {Object} [extra]
     */
    function log(level, message, extra = {}) {
        if (levels[level] < threshold) return;

        const entry = {
            timestamp: new Date().toISOString(),
            level,
            logger: moduleName,
            message,
            ...extra,
        };

        const output = useJson
            ? JSON.stringify(entry)
            : `${entry.timestamp} | ${level.padEnd(5)} | ${moduleName} | ${message}`;

        if (level === 'ERROR') {
            process.stderr.write(output + '\n');
        } else {
            process.stdout.write(output + '\n');
        }
    }

    return {
        debug: (msg, extra) => log('DEBUG', msg, extra),
        info:  (msg, extra) => log('INFO',  msg, extra),
        warn:  (msg, extra) => log('WARN',  msg, extra),
        error: (msg, extra) => log('ERROR', msg, extra),
    };
}

const logger = createLogger('json_processor');

// ---------------------------------------------------------------------------
// Serialisierung
// ---------------------------------------------------------------------------

/**
 * Serialisiert ein JavaScript-Objekt in einen formatierten JSON-String.
 *
 * @param {*} dataToSerialize - Das zu serialisierende Objekt.
 *   Muss JSON-kompatibel sein (keine zirkulären Referenzen).
 * @param {number} [indentationSpaces=2] - Einrückungstiefe (0–8 Leerzeichen).
 * @param {boolean} [sortKeysAlphabetically=false] - Keys alphabetisch sortieren.
 * @returns {string} Formatierter JSON-String.
 * @throws {RangeError} Wenn `indentationSpaces` außerhalb von 0–8 liegt.
 * @throws {TypeError} Wenn `dataToSerialize` zirkuläre Referenzen enthält
 *   oder anderweitig nicht serialisierbar ist.
 *
 * @example
 * const json = serializeToFormattedJson({ name: 'Alice', age: 30 });
 * // '{\n  "name": "Alice",\n  "age": 30\n}'
 */
function serializeToFormattedJson(
    dataToSerialize,
    indentationSpaces = 2,
    sortKeysAlphabetically = false,
) {
    if (!Number.isInteger(indentationSpaces) || indentationSpaces < 0 || indentationSpaces > 8) {
        throw new RangeError(
            `Ungültige Einrückung: ${indentationSpaces}. Erlaubt: 0–8.`
        );
    }

    try {
        const replacer = sortKeysAlphabetically
            ? (_, value) => (value && typeof value === 'object' && !Array.isArray(value)
                ? Object.fromEntries(Object.entries(value).sort())
                : value)
            : null;

        const serialized = JSON.stringify(dataToSerialize, replacer, indentationSpaces);

        logger.debug('JSON-Serialisierung erfolgreich', {
            resultLength: serialized.length,
            inputType: typeof dataToSerialize,
        });

        return serialized;

    } catch (serializationError) {
        logger.error('JSON-Serialisierung fehlgeschlagen', {
            inputType: typeof dataToSerialize,
            error: serializationError.message,
        });
        throw new TypeError(
            `Objekt nicht serialisierbar: ${serializationError.message}`
        );
    }
}

// ---------------------------------------------------------------------------
// Deserialisierung
// ---------------------------------------------------------------------------

/**
 * Parst einen JSON-String sicher und gibt bei Fehler `null` oder einen
 * Fallback-Wert zurück (wirft keine Exception).
 *
 * @template T
 * @param {string} jsonString - Der zu parsende JSON-String.
 * @param {T} [fallbackValue=null] - Rückgabewert bei Parse-Fehler.
 * @returns {T | null} Geparster Wert oder `fallbackValue`.
 *
 * @example
 * const data = parseJsonSafely('{"key": 42}', {});
 * // { key: 42 }
 *
 * const failed = parseJsonSafely('invalid json', {});
 * // {}  ← fallbackValue
 */
function parseJsonSafely(jsonString, fallbackValue = null) {
    if (typeof jsonString !== 'string') {
        logger.warn('parseJsonSafely: Eingabe ist kein String', {
            inputType: typeof jsonString,
        });
        return fallbackValue;
    }

    try {
        const parsed = JSON.parse(jsonString);
        logger.debug('JSON-Parse erfolgreich', { inputLength: jsonString.length });
        return parsed;
    } catch (parseError) {
        logger.warn('JSON-Parse fehlgeschlagen — verwende Fallback', {
            error: parseError.message,
            inputPreview: jsonString.slice(0, 50),
        });
        return fallbackValue;
    }
}

// ---------------------------------------------------------------------------
// Datei-Operationen
// ---------------------------------------------------------------------------

/**
 * Liest eine JSON-Datei und gibt den geparsten Inhalt zurück.
 *
 * @param {string} filePath - Absoluter Pfad zur JSON-Datei.
 * @param {string} [encoding='utf8'] - Datei-Encoding.
 * @returns {*} Geparster JSON-Inhalt.
 * @throws {Error} Wenn die Datei nicht existiert oder nicht lesbar ist.
 * @throws {SyntaxError} Wenn der Dateiinhalt kein gültiges JSON ist.
 *
 * @example
 * const config = readJsonFile('/path/to/config.json');
 */
function readJsonFile(filePath, encoding = 'utf8') {
    const resolvedPath = path.resolve(filePath);

    logger.debug('Lese JSON-Datei', { path: resolvedPath });

    try {
        const rawContent = fs.readFileSync(resolvedPath, { encoding });
        const parsedContent = JSON.parse(rawContent);
        logger.info('JSON-Datei gelesen', {
            path: resolvedPath,
            type: typeof parsedContent,
        });
        return parsedContent;
    } catch (readError) {
        logger.error('JSON-Datei-Lesefehler', {
            path: resolvedPath,
            error: readError.message,
            code: readError.code,
        });
        throw readError;
    }
}

/**
 * Schreibt ein Objekt atomar als formatierte JSON-Datei.
 *
 * Schreibt zunächst in eine temporäre Datei und benennt diese dann um,
 * um inkonsistente Zwischenzustände zu vermeiden.
 *
 * @param {string} filePath - Ziel-Dateipfad.
 * @param {*} data - Zu schreibende Daten.
 * @param {number} [indentationSpaces=2] - JSON-Einrückung.
 * @returns {void}
 * @throws {TypeError} Wenn `data` nicht serialisierbar ist.
 * @throws {Error} Bei Dateisystem-Fehlern.
 *
 * @example
 * writeJsonFileAtomically('/path/to/state.json', { version: 1 });
 */
function writeJsonFileAtomically(filePath, data, indentationSpaces = 2) {
    const resolvedPath = path.resolve(filePath);
    const tempPath     = resolvedPath + '.tmp';

    try {
        const jsonContent = serializeToFormattedJson(data, indentationSpaces);

        fs.writeFileSync(tempPath, jsonContent, { encoding: 'utf8', flag: 'w' });
        fs.renameSync(tempPath, resolvedPath);  // atomar auf POSIX

        logger.info('JSON-Datei atomar geschrieben', {
            path: resolvedPath,
            bytes: jsonContent.length,
        });
    } catch (writeError) {
        // Temp-Datei aufräumen
        try { fs.unlinkSync(tempPath); } catch { /* ignorieren */ }

        logger.error('JSON-Datei-Schreibfehler', {
            path: resolvedPath,
            error: writeError.message,
        });
        throw writeError;
    }
}

// ---------------------------------------------------------------------------
// Transformationen
// ---------------------------------------------------------------------------

/**
 * Extrahiert einen verschachtelten Wert aus einem Objekt via Dot-Notation.
 *
 * @param {Object} sourceObject - Das Quell-Objekt.
 * @param {string} dotNotationPath - Pfad in Dot-Notation (z. B. `"user.address.city"`).
 * @param {*} [defaultValue=undefined] - Rückgabewert wenn Pfad nicht existiert.
 * @returns {*} Wert am angegebenen Pfad oder `defaultValue`.
 *
 * @example
 * const city = getNestedValue({ user: { address: { city: 'Berlin' } } }, 'user.address.city');
 * // 'Berlin'
 *
 * const missing = getNestedValue({}, 'a.b.c', 'N/A');
 * // 'N/A'
 */
function getNestedValue(sourceObject, dotNotationPath, defaultValue = undefined) {
    if (!sourceObject || typeof sourceObject !== 'object') {
        return defaultValue;
    }

    const pathSegments = dotNotationPath.split('.');
    let currentValue = sourceObject;

    for (const segment of pathSegments) {
        if (currentValue === null || currentValue === undefined || !(segment in currentValue)) {
            logger.debug('Pfad nicht gefunden', { path: dotNotationPath, segment });
            return defaultValue;
        }
        currentValue = currentValue[segment];
    }

    return currentValue;
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
    serializeToFormattedJson,
    parseJsonSafely,
    readJsonFile,
    writeJsonFileAtomically,
    getNestedValue,
};
