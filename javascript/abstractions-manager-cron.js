#!/usr/bin/env node
// abstractions-manager-cron.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// Set environment variables
process.env.PATH = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin";

// Load environment variables from file
const envFilePath = '/home/openclaw/.openclaw/.env';
if (fs.existsSync(envFilePath)) {
  const envContent = fs.readFileSync(envFilePath, 'utf8');
  const envLines = envContent.split('\n');
  
  envLines.forEach(line => {
    if (line.trim() && !line.startsWith('#')) {
      const [key, value] = line.split('=', 2);
      if (key && value !== undefined) {
        process.env[key.trim()] = value.trim().replace(/^['"]|['"]$/g, '');
      }
    }
  });
}

// Check required environment variable
if (!process.env.OPENROUTER_API_KEY) {
  console.error('OPENROUTER_API_KEY fehlt');
  process.exit(1);
}

// Set GITHUB_TOKEN with fallback logic
process.env.GITHUB_TOKEN = process.env.GITHUB_TOKEN || 
                          process.env.GH_TOKEN || 
                          process.env.GH_ACCESS_TOKEN || '';

// File locking implementation
const lockFilePath = '/home/openclaw/.openclaw/locks/abstractions-manager.lock';
const pythonScriptPath = '/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py';

try {
  // Try to acquire lock
  const lockFd = fs.openSync(lockFilePath, 'w');
  const locked = fs.flockSync ? fs.flockSync(lockFd, 'nb') : false;
  
  if (!locked) {
    console.error('Could not acquire lock');
    process.exit(1);
  }
  
  // Execute Python script
  const pythonResult = spawnSync('python3', [pythonScriptPath, ...process.argv.slice(2)], {
    stdio: 'inherit',
    env: process.env
  });
  
  // Release lock and exit with Python script's exit code
  fs.closeSync(lockFd);
  process.exit(pythonResult.status || 0);
  
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
