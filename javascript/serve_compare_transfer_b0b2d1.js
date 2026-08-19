#!/usr/bin/env node
// serve_compare_transfer.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/serve_compare_transfer.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const http = require('http');

const COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare";
const TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer";
const HOST_IP = "89.58.15.220";
const PORT = "80";
const SELF_PATH = __filename;

// Funktion zum rekursiven Lesen von Dateien (ähnlich find)
function readFilesSync(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  
  list.forEach(file => {
    file = path.resolve(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      // Überspringe Unterverzeichnisse
    } else {
      if (file !== SELF_PATH) {
        results.push(file);
      }
    }
  });
  
  return results.sort();
}

const files = readFilesSync(COMPARE_DIR);

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
  const filePath = path.join(COMPARE_DIR, req.url === '/' ? 'index.html' : req.url);
  
  fs.access(filePath, fs.constants.F_OK, (err) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('File not found');
      return;
    }
    
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      res.writeHead(403, { 'Content-Type': 'text/plain' });
      res.end('Directory access forbidden');
      return;
    }
    
    res.writeHead(200, {
      'Content-Type': 'application/octet-stream',
      'Content-Length': stat.size
    });
    
    const readStream = fs.createReadStream(filePath);
    readStream.pipe(res);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server läuft auf http://0.0.0.0:${PORT}`);
});
