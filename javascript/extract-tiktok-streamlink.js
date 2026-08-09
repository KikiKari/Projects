#!/usr/bin/env node
// extract-tiktok-streamlink.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { spawnSync, execSync } from 'child_process';
import os from 'os';

const emitJson = (success, method, username, url, quality, author, title, error, timestamp, status) => {
    const payload = {
        success: typeof success === 'string' ? success.toLowerCase() === 'true' : success,
        method,
        username,
        url: url || undefined,
        quality,
        author: author || undefined,
        title: title || undefined,
        error: error || undefined,
        timestamp,
        status: status || undefined
    };
    
    // Remove undefined values
    Object.keys(payload).forEach(key => {
        if (payload[key] === undefined) {
            delete payload[key];
        }
    });
    
    console.error(JSON.stringify(payload));
};

const args = process.argv.slice(2);
const USERNAME = args[0] ? args[0].replace(/^@/, '') : '';
const QUALITY = args[1] || 'best';
const JSON_FLAG = args[2] || '';
const TIMESTAMP = new Date().toISOString().replace(/\.\d+Z$/, 'Z');

if (!USERNAME.match(/^[A-Za-z0-9._]{1,24}$/)) {
    console.error('Invalid TikTok username');
    process.exit(64);
}

if (!QUALITY.match(/^(best|worst|original|1080p60|720p60|720p|540p|360p|auto)$/)) {
    console.error('Invalid stream quality');
    process.exit(64);
}

const getLoadPerCpu = () => {
    const cpus = os.cpus().length || 1;
    const load = os.loadavg()[0];
    return load / cpus;
};

const LOAD_PER_CPU = getLoadPerCpu();
const MAX_LOAD = process.env.TIKTOK_MAX_LOAD_PER_CPU ? parseFloat(process.env.TIKTOK_MAX_LOAD_PER_CPU) : 1.5;

if (LOAD_PER_CPU > MAX_LOAD) {
    emitJson(false, 'streamlink', USERNAME, '', QUALITY, '', '', 'host overloaded', TIMESTAMP, 'overloaded');
    process.exit(75);
}

const streamlinkExists = () => {
    try {
        execSync('which streamlink', { stdio: 'ignore' });
        return true;
    } catch {
        return false;
    }
};

if (!streamlinkExists()) {
    emitJson(false, 'streamlink', USERNAME, '', QUALITY, '', '', 'streamlink not installed', TIMESTAMP, 'dependency_missing');
    process.exit(2);
}

const LIVE_URL = `https://www.tiktok.com/@${USERNAME}/live`;

const QUALITY_SELECTOR = {
    original: 'origin,uhd_60,hd_60,hd,sd,ld,best,worst',
    auto: 'best,origin,uhd_60,hd_60,hd,sd,ld,worst',
    '1080p60': 'uhd_60,hd_60,hd,sd,ld,worst',
    '720p60': 'hd_60,hd,sd,ld,worst',
    '720p': 'hd,sd,ld,worst',
    '540p': 'sd,ld,worst',
    '360p': 'ld,worst'
};

const SELECTOR = QUALITY_SELECTOR[QUALITY] || QUALITY;

const runStreamlink = (args) => {
    const result = spawnSync('streamlink', args, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
    return {
        stdout: result.stdout.trim(),
        stderr: result.stderr.trim(),
        status: result.status
    };
};

const jsonResult = runStreamlink(['--json', LIVE_URL, SELECTOR]);
let EXIT_CODE = jsonResult.status;
let OUTPUT = jsonResult.stdout;

if (EXIT_CODE !== 0 || !OUTPUT) {
    const urlResult = runStreamlink(['--stream-url', LIVE_URL, SELECTOR]);
    const URL = urlResult.stdout;
    
    if (urlResult.status !== 0 || !URL) {
        emitJson(false, 'streamlink', USERNAME, '', QUALITY, '', '', 'streamlink failed or no stream found', TIMESTAMP, 'offline');
        process.exit(1);
    }
    
    if (JSON_FLAG === '--json') {
        emitJson(true, 'streamlink', USERNAME, URL, QUALITY, '', '', '', TIMESTAMP, 'live');
    } else {
        console.log(URL);
    }
    process.exit(0);
}

let PARSED;
try {
    const data = JSON.parse(OUTPUT);
    let url = data.url || '';
    const streams = data.streams || {};
    
    if (!url && typeof streams === 'object') {
        const keys = ['best', 'worst', ...Object.keys(streams)];
        for (const key of keys) {
            const value = streams[key];
            if (typeof value === 'object' && value.url) {
                url = value.url;
                break;
            }
        }
    }
    
    const metadata = data.metadata || {};
    PARSED = {
        url: url,
        author: metadata.author || '',
        title: metadata.title || ''
    };
} catch (e) {
    emitJson(false, 'streamlink', USERNAME, '', QUALITY, '', '', 'invalid streamlink JSON', TIMESTAMP, 'technical_error');
    process.exit(2);
}

const { url: URL, author: AUTHOR, title: TITLE } = PARSED;

if (!URL) {
    emitJson(false, 'streamlink', USERNAME, '', QUALITY, AUTHOR, TITLE, 'could not extract stream URL', TIMESTAMP, 'offline');
    process.exit(1);
}

if (JSON_FLAG === '--json') {
    emitJson(true, 'streamlink', USERNAME, URL, QUALITY, AUTHOR, TITLE, '', TIMESTAMP, 'live');
} else {
    console.log(URL);
}
