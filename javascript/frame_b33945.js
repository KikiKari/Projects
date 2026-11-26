#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "9fb0bd64606103ad19e31c5f8197fcedec5ad616c88f93c7418fe68807a6b016", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "javascript"}
// frame.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0 || args[0] === '-h' || args[0] === '--help') {
    usage();
  }

  const input = args[0];
  args.shift();

  let time = '';
  let index = '';
  let out = '';

  while (args.length > 0) {
    const arg = args[0];
    switch (arg) {
      case '--time':
        if (args.length < 2) {
          console.error('Missing value for --time');
          usage();
        }
        time = args[1];
        args.splice(0, 2);
        break;
      case '--index':
        if (args.length < 2) {
          console.error('Missing value for --index');
          usage();
        }
        index = args[1];
        args.splice(0, 2);
        break;
      case '--out':
        if (args.length < 2) {
          console.error('Missing value for --out');
          usage();
        }
        out = args[1];
        args.splice(0, 2);
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

  if (!out) {
    console.error('Missing --out');
    usage();
  }

  // Create output directory
  const outDir = path.dirname(out);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  let result;
  if (index !== '') {
    result = spawnSync('ffmpeg', [
      '-hide_banner',
      '-loglevel', 'error',
      '-y',
      '-i', input,
      '-vf', `select=eq(n\\,${index})`,
      '-vframes', '1',
      out
    ], { stdio: 'inherit' });
  } else if (time !== '') {
    result = spawnSync('ffmpeg', [
      '-hide_banner',
      '-loglevel', 'error',
      '-y',
      '-ss', time,
      '-i', input,
      '-frames:v', '1',
      out
    ], { stdio: 'inherit' });
  } else {
    result = spawnSync('ffmpeg', [
      '-hide_banner',
      '-loglevel', 'error',
      '-y',
      '-i', input,
      '-vf', 'select=eq(n\\,0)',
      '-vframes', '1',
      out
    ], { stdio: 'inherit' });
  }

  if (result.error) {
    console.error(`Error executing ffmpeg: ${result.error.message}`);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status);
  }

  console.log(out);
}

main();
