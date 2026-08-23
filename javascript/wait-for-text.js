#!/usr/bin/env node
// wait-for-text.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/wait-for-text.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/wait-for-text.sh
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const { spawn, execSync } = require('child_process');

const usage = () => {
  console.error(`Usage: wait-for-text.js -t target -p pattern [options]

Poll a tmux pane for text and exit when found.

Options:
  -t, --target    tmux target (session:window.pane), required
  -p, --pattern   regex pattern to look for, required
  -F, --fixed     treat pattern as a fixed string (grep -F)
  -T, --timeout   seconds to wait (integer, default: 15)
  -i, --interval  poll interval in seconds (default: 0.5)
  -l, --lines     number of history lines to inspect (integer, default: 1000)
  -h, --help      show this help`);
};

let target = "";
let pattern = "";
let grepFlag = "-E";
let timeout = 15;
let interval = 0.5;
let lines = 1000;

const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '-t':
    case '--target':
      target = args[++i] || "";
      break;
    case '-p':
    case '--pattern':
      pattern = args[++i] || "";
      break;
    case '-F':
    case '--fixed':
      grepFlag = "-F";
      break;
    case '-T':
    case '--timeout':
      timeout = parseInt(args[++i]) || timeout;
      break;
    case '-i':
    case '--interval':
      interval = parseFloat(args[++i]) || interval;
      break;
    case '-l':
    case '--lines':
      lines = parseInt(args[++i]) || lines;
      break;
    case '-h':
    case '--help':
      usage();
      process.exit(0);
    default:
      console.error(`Unknown option: ${args[i]}`);
      usage();
      process.exit(1);
  }
}

if (!target || !pattern) {
  console.error("target and pattern are required");
  usage();
  process.exit(1);
}

if (!Number.isInteger(timeout)) {
  console.error("timeout must be an integer number of seconds");
  process.exit(1);
}

if (!Number.isInteger(lines)) {
  console.error("lines must be an integer");
  process.exit(1);
}

// Check if tmux exists
try {
  execSync('which tmux', { stdio: 'ignore' });
} catch (error) {
  console.error("tmux not found in PATH");
  process.exit(1);
}

const startTime = Math.floor(Date.now() / 1000);
const deadline = startTime + timeout;

const sleep = (seconds) => {
  return new Promise(resolve => setTimeout(resolve, seconds * 1000));
};

const runGrep = (text, pattern, flags) => {
  return new Promise((resolve) => {
    const grep = spawn('grep', [flags, '--', pattern]);
    let found = false;

    grep.stdout.on('data', () => {
      found = true;
    });

    grep.on('close', () => {
      resolve(found);
    });

    grep.stdin.write(text);
    grep.stdin.end();
  });
};

const main = async () => {
  while (true) {
    let paneText = "";
    try {
      paneText = execSync(`tmux capture-pane -p -J -t "${target}" -S "-${lines}"`, {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'ignore']
      });
    } catch (error) {
      // Ignore tmux errors, treat as empty output
      paneText = "";
    }

    const found = await runGrep(paneText, pattern, grepFlag);
    
    if (found) {
      process.exit(0);
    }

    const now = Math.floor(Date.now() / 1000);
    if (now >= deadline) {
      console.error(`Timed out after ${timeout}s waiting for pattern: ${pattern}`);
      console.error(`Last ${lines} lines from ${target}:`);
      console.error(paneText);
      process.exit(1);
    }

    await sleep(interval);
  }
};

main();
