#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "709461a727aa45b51b09c1f287fa13a015d5c3f31bf764ced85377ef8c83fa75", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "javascript"}
// offscreen.html — portiert nach javascript
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createOffscreenHTML() {
    const html = `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>`;

    return html;
}

function main() {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Bitte geben Sie eine Ausgabedatei als Parameter an.');
        process.exit(1);
    }
    
    const htmlContent = createOffscreenHTML();
    
    try {
        fs.writeFileSync(outputFile, htmlContent, 'utf8');
        console.log(`HTML-Datei wurde erfolgreich erstellt: ${outputFile}`);
    } catch (error) {
        console.error(`Fehler beim Schreiben der Datei: ${error.message}`);
        process.exit(1);
    }
}

main();
