#!/usr/bin/env node
// websearch-research.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/websearch-research.sh
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

// Web Search Script: Deep Research für Incidents
// Verwendung: node websearch-research.js "Beschreibung des Problems"

const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const QUERY = process.argv[2];
const OUTPUT_DIR = process.argv[3] || './research';

if (!QUERY) {
  console.log('Verwendung: node websearch-research.js "Problem Beschreibung" [OUTPUT_DIR]');
  process.exit(1);
}

// Funktion zum sicheren Erstellen von Verzeichnissen
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// Funktion zum Formatieren des Datums
function formatDate() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');
  return `${year}${month}${day}_${hours}${minutes}${seconds}`;
}

// Funktion zum HTTP POST Request
function postRequest(url, headers, postData) {
  return new Promise((resolve, reject) => {
    const options = {
      method: 'POST',
      headers: headers
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve(jsonData);
        } catch (err) {
          resolve(data);
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

// Hauptfunktion
async function main() {
  ensureDir(OUTPUT_DIR);
  const timestamp = formatDate();
  const OUTPUT_FILE = path.join(OUTPUT_DIR, `incident_${timestamp}.md`);

  let content = '# Incident Research\n';
  content += `Datum: ${new Date().toString()}\n`;
  content += `Query: ${QUERY}\n\n`;

  // 1. EXA für schnelle Recherche
  content += '## 1. Schnelle Recherche (EXA)\n';
  
  try {
    const exaData = await postRequest(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      JSON.stringify({
        model: 'openai/gpt-5.4-mini',
        messages: [{ role: 'user', content: QUERY }],
        plugins: [{ id: 'web', engine: 'exa', max_results: 5 }]
      })
    );
    
    const exaResult = exaData.choices && exaData.choices[0] && exaData.choices[0].message 
      ? exaData.choices[0].message.content 
      : 'Keine Ergebnisse';
      
    content += exaResult + '\n\n';
  } catch (err) {
    content += 'Fehler bei der EXA-Recherche\n\n';
  }

  content += '---\n\n';

  // 2. Verifizierte Quellen (Perplexity) falls verfügbar
  content += '## 2. Verifizierte Fakten (Perplexity)\n';
  
  try {
    const perplexityData = await postRequest(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      JSON.stringify({
        model: 'perplexity/sonar:online',
        messages: [{ role: 'user', content: `${QUERY} troubleshooting` }]
      })
    );
    
    const perplexityResult = perplexityData.choices && perplexityData.choices[0] && perplexityData.choices[0].message 
      ? perplexityData.choices[0].message.content 
      : 'Keine Ergebnisse';
      
    content += perplexityResult + '\n\n';
  } catch (err) {
    content += 'Fehler bei der Perplexity-Recherche\n\n';
  }

  fs.writeFileSync(OUTPUT_FILE, content);
  console.log(`Gespeichert in: ${OUTPUT_FILE}`);
}

main().catch(console.error);
