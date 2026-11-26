#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "00d5e24ef9750329569fda294305b76da1277dd586dece5bd4a014edd0d3c179", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "javascript"}
// extract-tiktok-streamlink.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const { spawnSync, execSync } = require('child_process');
const os = require('os');

// Bounded fallback used by the enhanced extractor. Output is normalized again
// by tiktok-get-stream.js; standalone success must remain URL-only unless
// --json is requested. Exit 75 means preflight overload.

function emitJson(success, method, username, url, quality, author, title, error, timestamp, status) {
    const payload = {
        ...(success !== undefined && success !== null && success !== "" && { success: typeof success === 'string' ? success.toLowerCase() === 'true' : success }),
        ...(method !== undefined && method !== null && method !== "" && { method }),
        ...(username !== undefined && username !== null && username !== "" && { username }),
        ...(url !== undefined && url !== null && url !== "" && { url }),
        ...(quality !== undefined && quality !== null && quality !== "" && { quality }),
        ...(author !== undefined && author !== null && author !== "" && { author }),
        ...(title !== undefined && title !== null && title !== "" && { title }),
        ...(error !== undefined && error !== null && error !== "" && { error }),
        ...(timestamp !== undefined && timestamp !== null && timestamp !== "" && { timestamp }),
        ...(status !== undefined && status !== null && status !== "" && { status })
    };
    console.error(JSON.stringify(payload));
}

function exit(code) {
    process.exit(code);
}

function main() {
    const args = process.argv.slice(2);
    let USERNAME = (args[0] || '').replace(/^@/, '');
    const QUALITY = args[1] || 'best';
    const JSON_FLAG = args[2] || '';
    const TIMESTAMP = new Date().toISOString().replace(/\.\d+Z$/, 'Z');

    if (!/^[A-Za-z0-9._]{1,24}$/.test(USERNAME)) {
        console.error("Invalid TikTok username");
        exit(64);
        return;
    }

    const validQualities = ['best', 'worst', 'original', '1080p60', '720p60', '720p', '540p', '360p', 'auto'];
    if (!validQualities.includes(QUALITY)) {
        console.error("Invalid stream quality");
        exit(64);
        return;
    }

    // Check system load
    try {
        const cpus = os.cpus().length || 1;
        const loadAvg = os.loadavg()[0];
        const LOAD_PER_CPU = loadAvg / cpus;
        const MAX_LOAD = parseFloat(process.env.TIKTOK_MAX_LOAD_PER_CPU || '1.5');
        
        if (LOAD_PER_CPU > MAX_LOAD) {
            emitJson(false, "streamlink", USERNAME, "", QUALITY, "", "", "host overloaded", TIMESTAMP, "overloaded");
            exit(75);
            return;
        }
    } catch (err) {
        // If we can't determine load, continue anyway
    }

    // Check if streamlink exists
    try {
        execSync('streamlink --version', { stdio: 'ignore' });
    } catch (err) {
        emitJson(false, "streamlink", USERNAME, "", QUALITY, "", "", "streamlink not installed", TIMESTAMP, "dependency_missing");
        exit(2);
        return;
    }

    const LIVE_URL = `https://www.tiktok.com/@${USERNAME}/live`;
    let SELECTOR = QUALITY;

    switch (QUALITY) {
        case 'original':
            SELECTOR = "origin,uhd_60,hd_60,hd,sd,ld,best,worst";
            break;
        case 'auto':
            SELECTOR = "best,origin,uhd_60,hd_60,hd,sd,ld,worst";
            break;
        case '1080p60':
            SELECTOR = "uhd_60,hd_60,hd,sd,ld,worst";
            break;
        case '720p60':
            SELECTOR = "hd_60,hd,sd,ld,worst";
            break;
        case '720p':
            SELECTOR = "hd,sd,ld,worst";
            break;
        case '540p':
            SELECTOR = "sd,ld,worst";
            break;
        case '360p':
            SELECTOR = "ld,worst";
            break;
    }

    // Try with --json first
    let result = spawnSync('streamlink', ['--json', LIVE_URL, SELECTOR], { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    let EXIT_CODE = result.status;
    let OUTPUT = result.stdout.trim();

    if (EXIT_CODE !== 0 || !OUTPUT) {
        // Fallback to --stream-url
        result = spawnSync('streamlink', ['--stream-url', LIVE_URL, SELECTOR], { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
        const URL = result.stdout.trim();
        
        if (result.status !== 0 || !URL) {
            emitJson(false, "streamlink", USERNAME, "", QUALITY, "", "", "streamlink failed or no stream found", TIMESTAMP, "offline");
            exit(1);
            return;
        }
        
        if (JSON_FLAG === "--json") {
            emitJson(true, "streamlink", USERNAME, URL, QUALITY, "", "", "", TIMESTAMP, "live");
        } else {
            console.log(URL);
        }
        exit(0);
        return;
    }

    // Parse JSON output
    try {
        const data = JSON.parse(OUTPUT);
        let url = data.url || "";
        const streams = data.streams || {};
        
        if (!url && typeof streams === 'object') {
            const keys = ["best", "worst", ...Object.keys(streams)];
            for (const key of keys) {
                const value = streams[key];
                if (typeof value === 'object' && value && value.url) {
                    url = value.url;
                    break;
                }
            }
        }
        
        const metadata = data.metadata || {};
        const AUTHOR = metadata.author || "";
        const TITLE = metadata.title || "";
        
        if (!url) {
            emitJson(false, "streamlink", USERNAME, "", QUALITY, AUTHOR, TITLE, "could not extract stream URL", TIMESTAMP, "offline");
            exit(1);
            return;
        }
        
        if (JSON_FLAG === "--json") {
            emitJson(true, "streamlink", USERNAME, url, QUALITY, AUTHOR, TITLE, "", TIMESTAMP, "live");
        } else {
            console.log(url);
        }
    } catch (parseError) {
        emitJson(false, "streamlink", USERNAME, "", QUALITY, "", "", "invalid streamlink JSON", TIMESTAMP, "technical_error");
        exit(2);
        return;
    }
}

main();
