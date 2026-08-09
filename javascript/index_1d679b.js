#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { createRequire } from 'module';

// Create HTML document structure
const html = `<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>`;

// Get output file path from command line argument
const outputPath = process.argv[2];

if (!outputPath) {
  console.error('Usage: node script.js <output-file>');
  process.exit(1);
}

// Write HTML to file
writeFileSync(outputPath, html, 'utf8');

console.log(`HTML file written to ${outputPath}`);
