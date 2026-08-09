#!/usr/bin/env node
// extract-tiktok-yt-dlp.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { spawnSync } from 'child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const USERNAME = process.argv[2]?.replace(/^@/, '') || '';
const FORMAT = process.argv[3] || 'best';
const JSON_FLAG = process.argv[4] || '';
const TIMESTAMP = new Date().toISOString().replace(/\.\d+Z$/, 'Z');

const TMP_DIR = mkdtempSync(join(tmpdir(), 'tiktok-yt-dlp-'));
process.on('exit', () => {
  rmSync(TMP_DIR, { recursive: true, force: true });
});

function emitJson(success, method, username, url, format, error, timestamp, status) {
  const payload = {
    ...(success !== undefined && success !== '' && { success: String(success).toLowerCase() === 'true' }),
    ...(method !== undefined && method !== '' && { method }),
    ...(username !== undefined && username !== '' && { username }),
    ...(url !== undefined && url !== '' && { url }),
    ...(format !== undefined && format !== '' && { format }),
    ...(error !== undefined && error !== '' && { error }),
    ...(timestamp !== undefined && timestamp !== '' && { timestamp }),
    ...(status !== undefined && status !== '' && { status })
  };
  console.error(JSON.stringify(payload, null, 0));
}

if (!USERNAME.match(/^[A-Za-z0-9._]{1,24}$/)) {
  console.error('Invalid TikTok username');
  process.exit(64);
}

const validFormats = [
  'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
  'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
  'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
  'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
  'hls-sd/hls-ld/flv-sd/flv-ld',
  'hls-ld/flv-ld',
  'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld'
];

if (!validFormats.includes(FORMAT)) {
  console.error('Invalid yt-dlp format');
  process.exit(64);
}

const loadPerCpu = parseFloat(spawnSync('python3', ['-c', 'import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))']).stdout.toString().trim());
const maxLoad = parseFloat(process.env.TIKTOK_MAX_LOAD_PER_CPU || '1.5');

if (loadPerCpu > maxLoad) {
  emitJson(false, 'yt-dlp', USERNAME, '', FORMAT, 'host overloaded', TIMESTAMP, 'overloaded');
  process.exit(75);
}

if (!spawnSync('command', ['-v', 'yt-dlp']).status === 0) {
  emitJson(false, 'yt-dlp', USERNAME, '', FORMAT, 'yt-dlp not installed', TIMESTAMP, 'dependency_missing');
  process.exit(2);
}

const LIVE_URL = `https://www.tiktok.com/@${USERNAME}/live`;
const stdoutFile = join(TMP_DIR, 'stdout.json');
const stderrFile = join(TMP_DIR, 'stderr.log');

const ytDlpResult = spawnSync('yt-dlp', [
  '--no-warnings',
  '--dump-single-json',
  '--skip-download',
  '--format', FORMAT,
  LIVE_URL
], {
  stdio: ['ignore', 'pipe', 'pipe']
});

writeFileSync(stdoutFile, ytDlpResult.stdout);
writeFileSync(stderrFile, ytDlpResult.stderr);

const EXIT_CODE = ytDlpResult.status;

if (EXIT_CODE !== 0) {
  const stderrContent = readFileSync(stderrFile, 'utf8');
  let STATUS, CODE;
  
  if (/not currently live|No live cdn found|not available|private video/i.test(stderrContent)) {
    STATUS = 'offline';
    CODE = 1;
  } else {
    STATUS = 'technical_error';
    CODE = 2;
  }
  
  emitJson(false, 'yt-dlp', USERNAME, '', FORMAT, stderrContent.substring(0, 1000), TIMESTAMP, STATUS);
  process.exit(CODE);
}

const jsonData = JSON.parse(readFileSync(stdoutFile, 'utf8'));
let URL = '';

if (typeof jsonData.url === 'string') {
  URL = jsonData.url;
} else {
  const formats = jsonData.formats || [];
  for (const item of formats) {
    if (typeof item === 'object' && typeof item.url === 'string') {
      const value = item.url;
      const low = value.toLowerCase();
      if (value.startsWith('https://') && (low.includes('.m3u8') || low.includes('.flv')) && !low.includes('only_audio=1')) {
        URL = value;
        break;
      }
    }
  }
}

if (!URL) {
  emitJson(false, 'yt-dlp', USERNAME, '', FORMAT, 'could not extract HTTPS video URL', TIMESTAMP, 'offline');
  process.exit(1);
}

if (JSON_FLAG === '--json') {
  emitJson(true, 'yt-dlp', USERNAME, URL, FORMAT, '', TIMESTAMP, 'live');
} else {
  console.log(URL);
}
