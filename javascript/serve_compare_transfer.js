#!/usr/bin/env node
// serve_compare_transfer.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/serve_compare_transfer.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const http = require('http');

const COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare";
const TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer";
const HOST_IP = "152.53.145.65";
const PORT = 80;
const SELF_PATH = __filename;

// Funktion zum rekursiven Auflisten von Dateien
function getFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = entries
    .filter(file => file.isFile() && path.join(dir, file.name) !== SELF_PATH)
    .map(file => path.join(dir, file.name));
  
  return files.sort();
}

const files = getFiles(COMPARE_DIR);

if (files.length === 0) {
  console.log(`Keine Dateien in ${COMPARE_DIR} gefunden.`);
  process.exit(1);
}

console.log();
console.log(`Bereitgestellte Dateien aus ${COMPARE_DIR}:`);
files.forEach(src => {
  console.log(`- ${path.basename(src)}`);
});

console.log();
console.log(`Copy/Paste auf anderem Gateway (Download nach ${TRANSFER_DIR}):`);
files.forEach(src => {
  const file = path.basename(src);
  console.log(`curl -fL --retry 3 --connect-timeout 10 -o ${TRANSFER_DIR}/${file} http://${HOST_IP}:${PORT}/${file}`);
});

console.log();
console.log(`Server auf Port ${PORT} aktiv. Beenden mit STRG+C.`);
console.log();

// HTTP-Server erstellen
const server = http.createServer((req, res) => {
  // Sicherstellen, dass der Pfad innerhalb von COMPARE_DIR bleibt
  const requestedPath = path.join(COMPARE_DIR, path.normalize(req.url));
  
  // Überprüfen, ob die angeforderte Datei im Vergleichsverzeichnis liegt
  if (!requestedPath.startsWith(COMPARE_DIR)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Forbidden');
    return;
  }

  // Prüfen, ob die Datei existiert
  fs.access(requestedPath, fs.constants.F_OK, (err) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('File not found');
      return;
    }

    // Datei senden
    const stream = fs.createReadStream(requestedPath);
    res.writeHead(200);
    stream.pipe(res);
    
    stream.on('error', () => {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
    });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server läuft auf Port ${PORT}`);
});
