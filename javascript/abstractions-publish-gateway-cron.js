#!/usr/bin/env node
// abstractions-publish-gateway-cron.sh — portiert nach javascript
// Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway-cron.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// Wrapper für Linux-crontab - setzt sauberes Environment
process.env.HOME = '/home/openclaw';
process.env.PATH = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

const fs = require('fs');
const { spawn } = require('child_process');

const LOG_DIR = '/home/openclaw/.openclaw/logs/abstractions-publish-gateway';
const CRON_LOG = `${LOG_DIR}/linux-cron.log`;

// Stelle sicher, dass das Log-Verzeichnis existiert
try {
  fs.mkdirSync(LOG_DIR, { recursive: true });
} catch (err) {
  console.error('Fehler beim Erstellen des Log-Verzeichnisses:', err);
  process.exit(1);
}

// Öffne die Log-Datei im Anhang-Modus
const logStream = fs.createWriteStream(CRON_LOG, { flags: 'a' });

// Schreibe den Start-Eintrag
const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
logStream.write(`\n===== CRON START ${timestamp} =====\n`);

// Führe das Shell-Skript aus
const script = spawn('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh');

// Leite stdout und stderr des Skripts in die Log-Datei
script.stdout.pipe(logStream);
script.stderr.pipe(logStream);

// Behandle das Ende des Skripts
script.on('close', (code) => {
  const endTimestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  logStream.write(`===== CRON END (exit ${code}) =====\n`);
  logStream.end();
});
