#!/usr/bin/env node
// websearch-crawl.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/websearch-crawl.sh
// auch in: OpenClaw@gateway2:scripts/websearch-crawl.sh
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import https from 'https';
import { spawn } from 'child_process';

// Web Search Script: Website Crawling mit Firecrawl
// Verwendung: node websearch-crawl.js <URL> [OUTPUT_DIR]

const args = process.argv.slice(2);
const WEBSITE_URL = args[0];
const OUTPUT_DIR = args[1] || './crawled';

// API-Key aus Umgebungsvariable oder aus Datei lesen
let FIRECRAWL_API_KEY = process.env.FIRECRAWL_API_KEY;
if (!FIRECRAWL_API_KEY) {
  try {
    const openclawEnvPath = path.join(process.env.HOME, '.openclaw', 'openclaw.env');
    const envContent = fs.readFileSync(openclawEnvPath, 'utf-8');
    const match = envContent.match(/OPENROUTER\s*=\s*"([^"]+)"/);
    if (match) {
      FIRECRAWL_API_KEY = match[1];
    }
  } catch (err) {
    // Datei nicht gefunden oder anderer Fehler - API_KEY bleibt undefined
  }
}

if (!WEBSITE_URL) {
  console.log('Verwendung: node websearch-crawl.js <URL> [OUTPUT_DIR]');
  process.exit(1);
}

// OUTPUT_DIR erstellen
fs.mkdirSync(OUTPUT_DIR, { recursive: true });
console.log(`Crawling ${WEBSITE_URL}...`);

// Hilfsfunktion für HTTP-Anfragen
function httpRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    if (postData) {
      req.write(postData);
    }

    req.end();
  });
}

// Crawl starten
async function startCrawl() {
  const options = {
    hostname: 'api.firecrawl.dev',
    port: 443,
    path: '/v1/crawl',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${FIRECRAWL_API_KEY}`,
      'Content-Type': 'application/json'
    }
  };

  const postData = JSON.stringify({
    url: WEBSITE_URL,
    limit: 100,
    scrapeOptions: { formats: ['markdown'] }
  });

  try {
    const response = await httpRequest(options, postData);
    const crawlId = response.id;

    if (!crawlId) {
      console.error('Fehler: Crawl konnte nicht gestartet werden');
      console.error(JSON.stringify(response, null, 2));
      process.exit(1);
    }

    console.log(`Crawl ID: ${crawlId}`);
    return crawlId;
  } catch (err) {
    console.error('Fehler beim Starten des Crawls:', err.message);
    process.exit(1);
  }
}

// Status prüfen
async function checkStatus(crawlId) {
  const options = {
    hostname: 'api.firecrawl.dev',
    port: 443,
    path: `/v1/crawl/${crawlId}`,
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${FIRECRAWL_API_KEY}`
    }
  };

  while (true) {
    try {
      const response = await httpRequest(options);
      const status = response.status || 'unknown';
      console.log(`Status: ${status}`);

      if (status === 'completed') {
        const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const outputFile = path.join(OUTPUT_DIR, `${dateStr}_crawl.json`);
        fs.writeFileSync(outputFile, JSON.stringify(response, null, 2));
        console.log(`Gespeichert in ${OUTPUT_DIR}`);
        break;
      } else if (status === 'failed') {
        console.error('Crawl fehlgeschlagen');
        process.exit(1);
      }

      // 5 Sekunden warten
      await new Promise(resolve => setTimeout(resolve, 5000));
    } catch (err) {
      console.error('Fehler beim Prüfen des Status:', err.message);
      process.exit(1);
    }
  }
}

// Hauptfunktion
(async () => {
  try {
    const crawlId = await startCrawl();
    await checkStatus(crawlId);
  } catch (err) {
    console.error('Unerwarteter Fehler:', err.message);
    process.exit(1);
  }
})();
