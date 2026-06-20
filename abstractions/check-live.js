'use strict';

/**
 * @fileoverview check-live.js — TikTok Live-Status-Prüfer.
 *
 * Prüft ob ein TikTok-Benutzer aktuell live streamt und gibt den Status
 * strukturiert zurück. Beinhaltet Rate-Limiting, Retry-Logik und
 * vollständige Fehlerbehandlung.
 *
 * Sicherheitsmaßnahmen:
 *   - Benutzernamen-Validierung verhindert Injection in URLs
 *   - HTTPS-only Requests (kein HTTP-Fallback)
 *   - Timeout verhindert hängende Requests
 *   - Keine sensiblen Daten in Logs
 *
 * @module check-live
 * @version 1.0.0
 * @license Internal Use Only
 *
 * @example
 * // Programmatisch
 * const { checkTikTokLiveStatus } = require('./check-live');
 * const status = await checkTikTokLiveStatus('username123');
 * console.log(status.isLive); // true / false
 *
 * // CLI
 * node check-live.js --username someuser --interval 60
 */

const https   = require('https');
const { URL } = require('url');

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

/** @typedef {Object} LiveCheckConfig
 * @property {number} requestTimeoutMs - HTTP-Timeout in ms (Standard: 10000).
 * @property {number} maxRetryAttempts - Maximale Retry-Versuche (Standard: 3).
 * @property {number} retryDelayMs - Verzögerung zwischen Retries in ms (Standard: 2000).
 * @property {string} userAgent - User-Agent-Header für HTTP-Requests.
 */

/** @type {LiveCheckConfig} */
const DEFAULT_CONFIG = {
    requestTimeoutMs: 10_000,
    maxRetryAttempts: 3,
    retryDelayMs: 2_000,
    userAgent: 'Mozilla/5.0 (compatible; OpenClaw-LiveChecker/1.0)',
};

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

const useJson = (process.env.ABSTRACTIONS_JSON_LOGGING ?? '1') === '1';

/**
 * @param {'DEBUG'|'INFO'|'WARN'|'ERROR'} level
 * @param {string} message
 * @param {Object} [extra]
 */
function log(level, message, extra = {}) {
    const entry = {
        timestamp: new Date().toISOString(),
        level,
        logger: 'check-live',
        message,
        ...extra,
    };
    const line = useJson ? JSON.stringify(entry) : `${entry.timestamp} | ${level} | ${message}`;
    (level === 'ERROR' ? process.stderr : process.stdout).write(line + '\n');
}

// ---------------------------------------------------------------------------
// Typen
// ---------------------------------------------------------------------------

/**
 * @typedef {Object} LiveStatus
 * @property {string}  username   - TikTok-Benutzername.
 * @property {boolean} isLive     - True wenn Benutzer live ist.
 * @property {string}  checkedAt  - ISO-Timestamp der Prüfung.
 * @property {number}  [viewerCount] - Anzahl Zuschauer (wenn verfügbar).
 * @property {string}  [streamTitle] - Stream-Titel (wenn verfügbar).
 * @property {string}  [error]    - Fehlermeldung wenn isLive nicht bestimmt werden konnte.
 */

// ---------------------------------------------------------------------------
// Validierung
// ---------------------------------------------------------------------------

/**
 * Validiert einen TikTok-Benutzernamen.
 *
 * TikTok erlaubt: Buchstaben, Ziffern, Unterstriche, Punkte.
 * Länge: 2–24 Zeichen. Das @-Präfix ist optional und wird entfernt.
 *
 * @param {string} rawUsername - Roher Benutzername (mit oder ohne @).
 * @returns {string} Validierter Benutzername ohne @.
 * @throws {TypeError} Wenn `rawUsername` kein String ist.
 * @throws {RangeError} Wenn der Benutzername ungültige Zeichen oder
 *   falsche Länge hat.
 *
 * @example
 * validateTikTokUsername('@alice_123')  // → 'alice_123'
 * validateTikTokUsername('alice_123')   // → 'alice_123'
 */
function validateTikTokUsername(rawUsername) {
    if (typeof rawUsername !== 'string') {
        throw new TypeError(`Benutzername muss ein String sein, war: ${typeof rawUsername}`);
    }

    const normalized = rawUsername.trim().replace(/^@/, '');

    if (!/^[a-zA-Z0-9_.]{2,24}$/.test(normalized)) {
        throw new RangeError(
            `Ungültiger TikTok-Benutzername: '${normalized}'. ` +
            'Erlaubt: Buchstaben, Ziffern, _ und . (2–24 Zeichen).'
        );
    }

    return normalized;
}

// ---------------------------------------------------------------------------
// HTTP-Hilfsfunktionen
// ---------------------------------------------------------------------------

/**
 * Sendet einen HTTPS-GET-Request und gibt Body + Statuscode zurück.
 *
 * @param {string} requestUrl - Vollständige HTTPS-URL.
 * @param {Object} [headers={}] - Zusätzliche HTTP-Header.
 * @param {number} [timeoutMs=10000] - Request-Timeout in Millisekunden.
 * @returns {Promise<{statusCode: number, body: string}>}
 * @throws {Error} Bei Netzwerkfehlern oder Timeout.
 * @throws {TypeError} Wenn die URL kein HTTPS-URL ist.
 */
function sendHttpsGetRequest(requestUrl, headers = {}, timeoutMs = 10_000) {
    return new Promise((resolve, reject) => {
        let parsedUrl;
        try {
            parsedUrl = new URL(requestUrl);
        } catch {
            reject(new TypeError(`Ungültige URL: ${requestUrl}`));
            return;
        }

        if (parsedUrl.protocol !== 'https:') {
            reject(new TypeError(`Nur HTTPS erlaubt. URL-Protokoll: ${parsedUrl.protocol}`));
            return;
        }

        const requestOptions = {
            hostname: parsedUrl.hostname,
            path:     parsedUrl.pathname + parsedUrl.search,
            method:   'GET',
            headers:  {
                'User-Agent': DEFAULT_CONFIG.userAgent,
                'Accept': 'application/json, text/html',
                ...headers,
            },
            timeout: timeoutMs,
        };

        const request = https.request(requestOptions, (response) => {
            const bodyChunks = [];

            response.on('data', (chunk) => bodyChunks.push(chunk));
            response.on('end', () => {
                resolve({
                    statusCode: response.statusCode,
                    body: Buffer.concat(bodyChunks).toString('utf8'),
                });
            });
        });

        request.on('timeout', () => {
            request.destroy();
            reject(new Error(`Request-Timeout nach ${timeoutMs}ms: ${requestUrl}`));
        });

        request.on('error', (networkError) => {
            reject(new Error(`Netzwerkfehler: ${networkError.message}`));
        });

        request.end();
    });
}

/**
 * Wartet eine definierte Anzahl Millisekunden (async).
 *
 * @param {number} delayMs - Wartezeit in Millisekunden.
 * @returns {Promise<void>}
 */
function sleep(delayMs) {
    return new Promise((resolve) => setTimeout(resolve, delayMs));
}

// ---------------------------------------------------------------------------
// Live-Status-Prüfung
// ---------------------------------------------------------------------------

/**
 * Prüft den TikTok Live-Status eines Benutzers mit Retry-Logik.
 *
 * Sendet einen HTTPS-Request an die TikTok-API und analysiert die
 * Antwort. Bei transienten Fehlern (Netzwerk, Rate-Limit) werden
 * automatisch bis zu `config.maxRetryAttempts` Wiederholungsversuche
 * unternommen.
 *
 * @param {string} rawUsername - TikTok-Benutzername (mit oder ohne @).
 * @param {Partial<LiveCheckConfig>} [config={}] - Optionale Konfiguration.
 * @returns {Promise<LiveStatus>} Live-Status-Objekt.
 *
 * @example
 * const status = await checkTikTokLiveStatus('alice_123');
 * if (status.isLive) {
 *   console.log(`${status.username} ist gerade live! Zuschauer: ${status.viewerCount}`);
 * }
 */
async function checkTikTokLiveStatus(rawUsername, config = {}) {
    const mergedConfig = { ...DEFAULT_CONFIG, ...config };
    const checkedAt = new Date().toISOString();

    let validatedUsername;
    try {
        validatedUsername = validateTikTokUsername(rawUsername);
    } catch (validationError) {
        log('ERROR', 'Ungültiger Benutzername', { error: validationError.message });
        return {
            username: String(rawUsername),
            isLive: false,
            checkedAt,
            error: validationError.message,
        };
    }

    log('INFO', 'Prüfe Live-Status', { username: validatedUsername });

    let lastError = null;

    for (let attempt = 1; attempt <= mergedConfig.maxRetryAttempts; attempt++) {
        try {
            const tiktokApiUrl = `https://www.tiktok.com/api/live/detail/?aid=1988&uniqueId=${encodeURIComponent(validatedUsername)}`;

            const { statusCode, body } = await sendHttpsGetRequest(
                tiktokApiUrl,
                {},
                mergedConfig.requestTimeoutMs,
            );

            if (statusCode === 429) {
                log('WARN', 'Rate-Limit erreicht — warte vor Retry', {
                    attempt,
                    retryDelayMs: mergedConfig.retryDelayMs * attempt,
                });
                await sleep(mergedConfig.retryDelayMs * attempt);
                continue;
            }

            if (statusCode !== 200) {
                throw new Error(`HTTP ${statusCode} von TikTok-API`);
            }

            const responseData = JSON.parse(body);
            const liveRoomInfo = responseData?.LiveRoomInfo;
            const isLive = liveRoomInfo?.status === 2;  // Status 2 = live

            const liveStatus = {
                username: validatedUsername,
                isLive,
                checkedAt,
                ...(isLive && liveRoomInfo?.liveRoomStats && {
                    viewerCount: liveRoomInfo.liveRoomStats.userCount ?? 0,
                    streamTitle: liveRoomInfo.title ?? '',
                }),
            };

            log('INFO', 'Live-Status ermittelt', {
                username: validatedUsername,
                isLive,
                attempt,
            });

            return liveStatus;

        } catch (requestError) {
            lastError = requestError;
            log('WARN', `Versuch ${attempt}/${mergedConfig.maxRetryAttempts} fehlgeschlagen`, {
                username: validatedUsername,
                error: requestError.message,
            });

            if (attempt < mergedConfig.maxRetryAttempts) {
                await sleep(mergedConfig.retryDelayMs * attempt);
            }
        }
    }

    // Alle Versuche fehlgeschlagen
    log('ERROR', 'Live-Status konnte nicht ermittelt werden', {
        username: validatedUsername,
        error: lastError?.message,
        attempts: mergedConfig.maxRetryAttempts,
    });

    return {
        username: validatedUsername,
        isLive: false,
        checkedAt,
        error: `Nach ${mergedConfig.maxRetryAttempts} Versuchen fehlgeschlagen: ${lastError?.message}`,
    };
}

// ---------------------------------------------------------------------------
// Polling-Modus
// ---------------------------------------------------------------------------

/**
 * Startet einen Polling-Loop der den Live-Status periodisch prüft.
 *
 * @param {string} username - TikTok-Benutzername.
 * @param {number} intervalSeconds - Prüfintervall in Sekunden (min. 10).
 * @param {Function} [onStatusChange] - Callback bei Status-Wechsel.
 *   Signatur: ``(newStatus: LiveStatus, previousStatus: LiveStatus) => void``.
 * @returns {Function} Stop-Funktion — Aufruf beendet den Polling-Loop.
 *
 * @example
 * const stop = pollLiveStatus('alice_123', 60, (newStatus) => {
 *   if (newStatus.isLive) console.log('Jetzt live!');
 * });
 * // Nach 5 Minuten stoppen:
 * setTimeout(stop, 5 * 60 * 1000);
 */
function pollLiveStatus(username, intervalSeconds, onStatusChange = null) {
    const safeIntervalSeconds = Math.max(10, intervalSeconds);
    let previousStatus = null;
    let isRunning = true;

    log('INFO', 'Starte Live-Status-Polling', {
        username,
        intervalSeconds: safeIntervalSeconds,
    });

    async function runPollCycle() {
        while (isRunning) {
            const currentStatus = await checkTikTokLiveStatus(username);

            const hasStatusChanged = previousStatus === null ||
                previousStatus.isLive !== currentStatus.isLive;

            if (hasStatusChanged && onStatusChange) {
                try {
                    onStatusChange(currentStatus, previousStatus);
                } catch (callbackError) {
                    log('ERROR', 'Fehler im Status-Change-Callback', {
                        error: callbackError.message,
                    });
                }
            }

            previousStatus = currentStatus;

            if (isRunning) {
                await sleep(safeIntervalSeconds * 1000);
            }
        }
        log('INFO', 'Polling beendet', { username });
    }

    runPollCycle().catch((error) => {
        log('ERROR', 'Polling-Loop fehlgeschlagen', { error: error.message });
    });

    return function stopPolling() {
        isRunning = false;
        log('INFO', 'Polling wird gestoppt', { username });
    };
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

async function runCli() {
    const args = process.argv.slice(2);
    const getArg = (flag) => {
        const index = args.indexOf(flag);
        return index !== -1 ? args[index + 1] : null;
    };

    const username = getArg('--username');
    const intervalRaw = getArg('--interval');

    if (!username) {
        console.error('Fehler: --username erforderlich');
        console.error('Verwendung: node check-live.js --username <name> [--interval <sekunden>]');
        process.exit(1);
    }

    if (intervalRaw) {
        const intervalSeconds = parseInt(intervalRaw, 10);
        if (isNaN(intervalSeconds) || intervalSeconds < 10) {
            console.error('Fehler: --interval muss eine Zahl ≥ 10 sein');
            process.exit(1);
        }

        const stop = pollLiveStatus(username, intervalSeconds, (status) => {
            const marker = status.isLive ? '🔴 LIVE' : '⚫ Offline';
            console.log(`[${status.checkedAt}] ${status.username}: ${marker}`);
            if (status.viewerCount !== undefined) {
                console.log(`  Zuschauer: ${status.viewerCount} | ${status.streamTitle}`);
            }
        });

        process.on('SIGINT', () => {
            stop();
            process.exit(0);
        });

    } else {
        const status = await checkTikTokLiveStatus(username);
        console.log(JSON.stringify(status, null, 2));
        process.exit(status.error ? 1 : 0);
    }
}

// ---------------------------------------------------------------------------
// Exports & Einstiegspunkt
// ---------------------------------------------------------------------------

module.exports = {
    checkTikTokLiveStatus,
    pollLiveStatus,
    validateTikTokUsername,
};

if (require.main === module) {
    runCli().catch((error) => {
        log('ERROR', 'CLI-Fehler', { error: error.message });
        process.exit(1);
    });
}
