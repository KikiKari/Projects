#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "50277942acb669cc73878f2f86cb738aeb8d7222404163074a84fe8427ce8cc4", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "javascript"}
// extract-tiktok-yt-dlp.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { spawn } from 'child_process';
import { createRequire } from 'module';
import { tmpdir } from 'os';
import { join } from 'path';
import { promises as fs } from 'fs';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Bounded fallback used by the enhanced extractor. Temporary files are cleaned
// on every exit and output is normalized again by tiktok-get-stream.js.
// Standalone overload exits 75 before yt-dlp starts.

if (process.argv.length < 3) {
  console.error('Usage: node extract-tiktok-yt-dlp.js <username> [format] [--json]');
  process.exit(64);
}

const USERNAME = process.argv[2].startsWith('@') ? process.argv[2].substring(1) : process.argv[2];
const FORMAT = process.argv[3] || 'best';
const JSON_FLAG = process.argv[4] || '';
const TIMESTAMP = new Date().toISOString().replace(/\.\d+Z$/, 'Z');

let TMP_DIR;
let CLEANUP_REGISTERED = false;

async function cleanup() {
  if (TMP_DIR && CLEANUP_REGISTERED) {
    try {
      await fs.rm(TMP_DIR, { recursive: true });
    } catch (e) {
      // ignore
    }
  }
}

function registerCleanup(dir) {
  TMP_DIR = dir;
  CLEANUP_REGISTERED = true;
  process.on('exit', cleanup);
  process.on('SIGINT', () => { cleanup(); process.exit(1); });
  process.on('SIGTERM', () => { cleanup(); process.exit(1); });
}

function emitJson(success, method, username, url, format, error, timestamp, status) {
  const payload = {};
  if (success !== undefined && success !== "") payload.success = success === "true" || success === true;
  if (method !== undefined && method !== "") payload.method = method;
  if (username !== undefined && username !== "") payload.username = username;
  if (url !== undefined && url !== "") payload.url = url;
  if (format !== undefined && format !== "") payload.format = format;
  if (error !== undefined && error !== "") payload.error = error;
  if (timestamp !== undefined && timestamp !== "") payload.timestamp = timestamp;
  if (status !== undefined && status !== "") payload.status = status;
  
  return JSON.stringify(payload);
}

function isValidUsername(username) {
  return /^[A-Za-z0-9._]{1,24}$/.test(username);
}

function isValidFormat(format) {
  const validFormats = [
    'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
    'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
    'hls-sd/hls-ld/flv-sd/flv-ld',
    'hls-ld/flv-ld',
    'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld'
  ];
  return validFormats.includes(format);
}

function getLoadAvgPerCpu() {
  const loadAvg = process.loadavg()[0];
  const cpuCount = require('os').cpus().length;
  return loadAvg / Math.max(1, cpuCount);
}

function runPython(code, args = []) {
  return new Promise((resolve, reject) => {
    const py = spawn('python3', ['-c', code, ...args]);
    let stdout = '';
    let stderr = '';
    
    py.stdout.on('data', data => stdout += data.toString());
    py.stderr.on('data', data => stderr += data.toString());
    
    py.on('close', code => {
      if (code === 0) {
        resolve(stdout.trim());
      } else {
        reject(new Error(stderr || 'Python script failed'));
      }
    });
  });
}

async function checkDependencies() {
  try {
    await fs.access('/usr/bin/yt-dlp');
    return true;
  } catch {
    try {
      await fs.access('/usr/local/bin/yt-dlp');
      return true;
    } catch {
      return false;
    }
  }
}

async function runYtdlp(url, format, outputFile, errorFile) {
  return new Promise((resolve) => {
    const ytdlp = spawn('yt-dlp', [
      '--no-warnings',
      '--dump-single-json',
      '--skip-download',
      '--format', format,
      url
    ]);
    
    const stdoutFile = fs.open(outputFile, 'w');
    const stderrFile = fs.open(errorFile, 'w');
    
    Promise.all([stdoutFile, stderrFile]).then(([stdoutFd, stderrFd]) => {
      ytdlp.stdout.pipe(fs.createWriteStream('', { fd: stdoutFd }));
      ytdlp.stderr.pipe(fs.createWriteStream('', { fd: stderrFd }));
      
      ytdlp.on('close', (code) => {
        stdoutFd.close();
        stderrFd.close();
        resolve(code);
      });
    });
  });
}

async function extractUrlFromJson(file) {
  try {
    const content = await fs.readFile(file, 'utf8');
    const data = JSON.parse(content);
    const candidates = [];
    
    if (typeof data.url === 'string') {
      candidates.push(data.url);
    }
    
    if (Array.isArray(data.formats)) {
      for (const item of data.formats) {
        if (item && typeof item.url === 'string') {
          candidates.push(item.url);
        }
      }
    }
    
    for (const value of candidates) {
      const low = value.toLowerCase();
      if (value.startsWith('https://') && 
          (low.includes('.m3u8') || low.includes('.flv')) && 
          !low.includes('only_audio=1')) {
        return value;
      }
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

async function main() {
  if (!isValidUsername(USERNAME)) {
    console.error('Invalid TikTok username');
    process.exit(64);
  }
  
  if (!isValidFormat(FORMAT)) {
    console.error('Invalid yt-dlp format');
    process.exit(64);
  }
  
  const loadPerCpu = getLoadAvgPerCpu();
  const maxLoad = process.env.TIKTOK_MAX_LOAD_PER_CPU || '1.5';
  
  if (loadPerCpu > parseFloat(maxLoad)) {
    const jsonOutput = emitJson(
      'false', 'yt-dlp', USERNAME, '', FORMAT, 
      'host overloaded', TIMESTAMP, 'overloaded'
    );
    console.error(jsonOutput);
    process.exit(75);
  }
  
  if (!(await checkDependencies())) {
    const jsonOutput = emitJson(
      'false', 'yt-dlp', USERNAME, '', FORMAT, 
      'yt-dlp not installed', TIMESTAMP, 'dependency_missing'
    );
    console.error(jsonOutput);
    process.exit(2);
  }
  
  const tmpDir = await fs.mkdtemp(join(tmpdir(), 'tiktok-yt-dlp-'));
  registerCleanup(tmpDir);
  
  const stdoutFile = join(tmpDir, 'stdout.json');
  const stderrFile = join(tmpDir, 'stderr.log');
  const liveUrl = `https://www.tiktok.com/@${USERNAME}/live`;
  
  const exitCode = await runYtdlp(liveUrl, FORMAT, stdoutFile, stderrFile);
  
  if (exitCode !== 0) {
    let status, code;
    try {
      const stderrContent = await fs.readFile(stderrFile, 'utf8');
      if (/not currently live|No live cdn found|not available|private video/i.test(stderrContent)) {
        status = 'offline';
        code = 1;
      } else {
        status = 'technical_error';
        code = 2;
      }
      
      const jsonOutput = emitJson(
        'false', 'yt-dlp', USERNAME, '', FORMAT,
        stderrContent.substring(0, 1000), TIMESTAMP, status
      );
      console.error(jsonOutput);
      process.exit(code);
    } catch (e) {
      const jsonOutput = emitJson(
        'false', 'yt-dlp', USERNAME, '', FORMAT,
        'failed to read error log', TIMESTAMP, 'technical_error'
      );
      console.error(jsonOutput);
      process.exit(2);
    }
  }
  
  const url = await extractUrlFromJson(stdoutFile);
  
  if (!url) {
    const jsonOutput = emitJson(
      'false', 'yt-dlp', USERNAME, '', FORMAT,
      'could not extract HTTPS video URL', TIMESTAMP, 'offline'
    );
    console.error(jsonOutput);
    process.exit(1);
  }
  
  if (JSON_FLAG === '--json') {
    const jsonOutput = emitJson(
      'true', 'yt-dlp', USERNAME, url, FORMAT, 
      '', TIMESTAMP, 'live'
    );
    console.log(jsonOutput);
  } else {
    console.log(url);
  }
}

main().catch(e => {
  console.error('Unexpected error:', e.message);
  process.exit(2);
});
