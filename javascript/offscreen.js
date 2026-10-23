#!/usr/bin/env node
// offscreen.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateOffscreenHTML() {
  // Create the document structure
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

// Get output file path from command line argument
const outputFile = process.argv[2];

if (!outputFile) {
  console.error('Bitte geben Sie eine Ausgabedatei als Parameter an.');
  process.exit(1);
}

try {
  // Generate the HTML content
  const htmlContent = generateOffscreenHTML();
  
  // Write to file
  fs.writeFileSync(outputFile, htmlContent, 'utf8');
  
  console.log(`HTML file successfully written to ${outputFile}`);
} catch (error) {
  console.error('Error writing file:', error.message);
  process.exit(1);
}
