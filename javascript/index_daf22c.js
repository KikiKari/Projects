#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ef9ae4d229edf1b41cd538e5e31ea7621100dffd404579a0e09942ab417174c8", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "javascript"}
// index.css — portiert nach javascript
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// CSS-Inhalt als JavaScript-Objektstruktur
const cssStyles = {
  body: {
    margin: '0',
    'font-family': [
      '-apple-system',
      'BlinkMacSystemFont',
      "'Segoe UI'",
      "'Roboto'",
      "'Oxygen'",
      "'Ubuntu'",
      "'Cantarell'",
      "'Fira Sans'",
      "'Droid Sans'",
      "'Helvetica Neue'",
      'sans-serif'
    ].join(', '),
    '-webkit-font-smoothing': 'antialiased',
    '-moz-osx-font-smoothing': 'grayscale'
  },
  code: {
    'font-family': [
      'source-code-pro',
      'Menlo',
      'Monaco',
      'Consolas',
      "'Courier New'",
      'monospace'
    ].join(', ')
  }
};

// Funktion zum Konvertieren des JS-Objekts in CSS
function generateCSS(styles) {
  let cssContent = '';
  
  for (const [selector, properties] of Object.entries(styles)) {
    cssContent += `${selector} {\n`;
    
    for (const [property, value] of Object.entries(properties)) {
      cssContent += `  ${property}: ${value};\n`;
    }
    
    cssContent += '}\n\n';
  }
  
  return cssContent.trim();
}

// Hauptprogramm
function main() {
  // Prüfe Kommandozeilenargumente
  if (process.argv.length !== 3) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }

  const outputFile = process.argv[2];
  const cssContent = generateCSS(cssStyles);
  
  // Schreibe in Datei
  fs.writeFileSync(outputFile, cssContent, 'utf8');
  console.log(`CSS-Datei wurde erfolgreich erstellt: ${outputFile}`);
}

main();
