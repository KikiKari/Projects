#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "7d7c06a5e54451b0a9bdc737684676dd07706de76843874957eb1182e8b34e54", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "javascript"}
// abstractions-manager.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

const { spawn } = require('child_process');
const path = require('path');

// Pfad zum Ziel-Skript
const scriptPath = path.join('/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh');

// Übergabe aller Kommandozeilenargumente (außer dem ersten, das ist der Node-Befehl)
const args = process.argv.slice(2);

// Starte das externe Skript und leite stdin, stdout und stderr durch
const child = spawn(scriptPath, args, { stdio: 'inherit' });

// Beende den Node-Prozess mit demselben Exit-Code wie das aufgerufene Skript
child.on('close', (code) => {
  process.exit(code);
});
