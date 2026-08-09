#!/usr/bin/env node
// frame.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function usage() {
  console.error(`Usage:
  frame.js <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.js video.mp4 --out /tmp/frame.jpg
  frame.js video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.js video.mp4 --index 0 --out /tmp/frame0.png`);
  process.exit(2);
}

const args = process.argv.slice(2);

if (args.length === 0 || args[0] === '-h' || args[0] === '--help') {
  usage();
}

const input = args[0];
const restArgs = args.slice(1);

let time = '';
let index = '';
let out = '';

let i = 0;
while (i < restArgs.length) {
  const arg = restArgs[i];
  switch (arg) {
    case '--time':
      time = restArgs[i + 1] || '';
      i += 2;
      break;
    case '--index':
      index = restArgs[i + 1] || '';
      i += 2;
      break;
    case '--out':
      out = restArgs[i + 1] || '';
      i += 2;
      break;
    default:
      console.error(`Unknown arg: ${arg}`);
      usage();
  }
}

if (!fs.existsSync(input)) {
  console.error(`File not found: ${input}`);
  process.exit(1);
}

if (out === '') {
  console.error('Missing --out');
  usage();
}

const outDir = path.dirname(out);
fs.mkdirSync(outDir, { recursive: true });

let ffmpegArgs;
if (index !== '') {
  ffmpegArgs = [
    '-hide_banner',
    '-loglevel', 'error',
    '-y',
    '-i', input,
    '-vf', `select=eq(n\\,${index})`,
    '-vframes', '1',
    out
  ];
} else if (time !== '') {
  ffmpegArgs = [
    '-hide_banner',
    '-loglevel', 'error',
    '-y',
    '-ss', time,
    '-i', input,
    '-frames:v', '1',
    out
  ];
} else {
  ffmpegArgs = [
    '-hide_banner',
    '-loglevel', 'error',
    '-y',
    '-i', input,
    '-vf', 'select=eq(n\\,0)',
    '-vframes', '1',
    out
  ];
}

const result = spawnSync('ffmpeg', ffmpegArgs, { stdio: 'inherit' });

if (result.error) {
  console.error('Failed to execute ffmpeg');
  process.exit(1);
}

if (result.status !== 0) {
  process.exit(result.status);
}

console.log(out);
