#!/usr/bin/env node
// websearch-research.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/websearch-research.sh
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

// Web Search Script: Deep Research für Incidents
// Verwendung: node websearch-research.js "Beschreibung des Problems"

const fs = require('fs');
const https = require('https');
const process = require('process');

const QUERY = process.argv[2];
const OUTPUT_DIR = process.argv[3] || './research';

if (!QUERY) {
  console.log('Verwendung: node websearch-research.js "Problem Beschreibung" [OUTPUT_DIR]');
  process.exit(1);
}

// Hilfsfunktion für HTTP-Anfragen
function httpRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', chunk => responseData += chunk);
      res.on('end', () => resolve(JSON.parse(responseData)));
    });
    req.on('error', err => reject(err));
    if (data) {
      req.write(data);
    }
    req.end();
  });
}

// Aktuelles Datum im Format YYYYMMDD_HHMMSS
function getTimestamp() {
  const now = new Date();
  const pad = (num) => String(num).padStart(2, '0');
  return `${now.getFullYear()}${pad(now.getMonth()+1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

// Hauptfunktion
async function main() {
  const timestamp = getTimestamp();
  const outputFile = `${OUTPUT_DIR}/incident_${timestamp}.md`;

  // Verzeichnis erstellen
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  // Header schreiben
  let content = `# Incident Research\n`;
  content += `Datum: ${new Date().toString()}\n`;
  content += `Query: ${QUERY}\n\n`;

  // 1. EXA für schnelle Recherche
  content += `## 1. Schnelle Recherche (EXA)\n`;
  
  const exaOptions = {
    hostname: 'openrouter.ai',
    path: '/api/v1/chat/completions',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json'
    }
  };

  const exaData = JSON.stringify({
    model: "openai/gpt-5.6-terra",
    messages: [{ role: "user", content: QUERY }],
    plugins: [{ id: "web", engine: "exa", max_results: 5 }]
  });

  try {
    const exaResponse = await httpRequest(exaOptions, exaData);
    content += (exaResponse.choices && exaResponse.choices[0] && exaResponse.choices[0].message && exaResponse.choices[0].message.content) || "Keine Ergebnisse";
  } catch (err) {
    content += "Fehler bei der Anfrage";
  }

  content += "\n\n---\n";

  // 2. Verifizierte Quellen (Perplexity)
  content += `## 2. Verifizierte Fakten (Perplexity)\n`;

  const perplexityOptions = {
    hostname: 'openrouter.ai',
    path: '/api/v1/chat/completions',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json'
    }
  };

  const perplexityData = JSON.stringify({
    model: "perplexity/sonar:online",
    messages: [{ role: "user", content: `${QUERY} troubleshooting` }]
  });

  try {
    const perplexityResponse = await httpRequest(perplexityOptions, perplexityData);
    content += (perplexityResponse.choices && perplexityResponse.choices[0] && perplexityResponse.choices[0].message && perplexityResponse.choices[0].message.content) || "Keine Ergebnisse";
  } catch (err) {
    content += "Fehler bei der Anfrage";
  }

  // In Datei schreiben
  fs.writeFileSync(outputFile, content);
  console.log(`Gespeichert in: ${outputFile}`);
}

main();
