#!/usr/bin/env node
// test_node3.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/test_node3.sh
// auch in: OpenClaw@gateway2:scripts/test_node3.sh
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

// Test Node 3 Connection
process.env.OPENCLAW_ALLOW_INSECURE_PRIVATE_WS = '1';
console.log('Starting node connection test...');

const { spawn } = require('child_process');

// Spawn the openclaw process with timeout
const child = spawn('/usr/local/bin/openclaw', ['node', 'run', '--host', '152.53.145.65', '--port', '18789'], {
  stdio: 'inherit',
  env: process.env
});

// Set timeout to 15 seconds
const timeout = setTimeout(() => {
  console.log('Timeout reached, killing process...');
  child.kill('SIGTERM');
}, 15000);

// Handle process exit
child.on('exit', (code) => {
  clearTimeout(timeout);
  console.log(`Exit code: ${code}`);
  process.exitCode = code;
});

// Handle process error (e.g., command not found)
child.on('error', (err) => {
  clearTimeout(timeout);
  console.error(`Failed to start process: ${err.message}`);
  process.exitCode = 1;
});
