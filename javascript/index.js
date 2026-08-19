#!/usr/bin/env node
// index.css — portiert nach javascript
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// CSS-Inhalt als strukturiertes Objekt
const cssRules = {
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

// Funktion zum Konvertieren des Regelobjekts in CSS-Text
function generateCSSText(rules) {
  let cssText = '';
  
  for (const [selector, properties] of Object.entries(rules)) {
    cssText += `${selector} {\n`;
    
    for (const [property, value] of Object.entries(properties)) {
      cssText += `  ${property}: ${value};\n`;
    }
    
    cssText += '}\n\n';
  }
  
  return cssText.trim();
}

// Hauptfunktion
function main() {
  // Prüfe Kommandozeilenargumente
  if (process.argv.length < 3) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }

  const outputFile = process.argv[2];
  const cssContent = generateCSSText(cssRules);
  
  try {
    fs.writeFileSync(outputFile, cssContent);
    console.log(`CSS erfolgreich geschrieben in: ${outputFile}`);
  } catch (error) {
    console.error('Fehler beim Schreiben der Datei:', error.message);
    process.exit(1);
  }
}

main();
