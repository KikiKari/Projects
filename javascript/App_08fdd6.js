#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "4a7a9a316656aca9aa147401ffe36372ec16be04e31e17b9408ae7b69fbc4dca", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "javascript"}
// App.css — portiert nach javascript
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// Funktion zum Erstellen eines CSS-Regelobjekts
function createRule(selector, properties) {
  return { selector, properties };
}

// Funktion zum Konvertieren eines Regelobjekts in CSS-Text
function ruleToCSS(rule) {
  const propString = Object.entries(rule.properties)
    .map(([key, value]) => `  ${key}: ${value};`)
    .join('\n');
  return `${rule.selector} {\n${propString}\n}`;
}

// Haupt-CSS-Struktur
const cssRules = [
  // :root Regel
  createRule(':root', {
    'color-scheme': 'dark',
    'font-family': 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'background': '#0b1020',
    'color': '#eef2ff'
  }),

  // Universal-Selektor
  createRule('*', {
    'box-sizing': 'border-box'
  }),

  // Body-Regel
  createRule('body', {
    'margin': '0',
    'min-width': '320px',
    'min-height': '100vh',
    'background': 
      'radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),\n' +
      'radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),\n' +
      'linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)'
  }),

  // Page-shell
  createRule('.page-shell', {
    'min-height': '100vh',
    'display': 'grid',
    'place-items': 'center',
    'padding': '2rem'
  }),

  // Hero card
  createRule('.hero-card', {
    'width': 'min(100%, 56rem)',
    'padding': 'clamp(2rem, 6vw, 4.5rem)',
    'border': '1px solid rgba(148, 163, 184, 0.28)',
    'border-radius': '2rem',
    'background': 'rgba(15, 23, 42, 0.72)',
    'box-shadow': '0 2rem 6rem rgba(0, 0, 0, 0.35)',
    'backdrop-filter': 'blur(18px)'
  }),

  // Eyebrow
  createRule('.eyebrow', {
    'margin': '0 0 1rem',
    'color': '#67e8f9',
    'font-size': '0.8rem',
    'font-weight': '700',
    'letter-spacing': '0.18em',
    'text-transform': 'uppercase'
  }),

  // h1
  createRule('h1', {
    'margin': '0',
    'max-width': '12ch',
    'font-size': 'clamp(2.75rem, 8vw, 6rem)',
    'line-height': '0.95',
    'letter-spacing': '-0.06em'
  }),

  // Lead
  createRule('.lead', {
    'margin': '1.5rem 0 0',
    'max-width': '42rem',
    'color': '#cbd5e1',
    'font-size': 'clamp(1.05rem, 2vw, 1.35rem)',
    'line-height': '1.65'
  }),

  // Link grid container
  createRule('.link-grid', {
    'display': 'grid',
    'gap': '0.85rem',
    'margin-top': '2rem'
  }),

  // Link grid anchor
  createRule('.link-grid a', {
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'space-between',
    'gap': '1rem',
    'padding': '1rem 1.15rem',
    'border': '1px solid rgba(148, 163, 184, 0.25)',
    'border-radius': '1rem',
    'color': '#f8fafc',
    'text-decoration': 'none',
    'background': 'rgba(255, 255, 255, 0.06)'
  }),

  // Link grid hover/focus
  createRule('.link-grid a:hover,\n.link-grid a:focus-visible', {
    'border-color': 'rgba(103, 232, 249, 0.75)',
    'outline': 'none',
    'background': 'rgba(103, 232, 249, 0.12)'
  })
];

// Generiere den vollständigen CSS-Code
function generateCSS() {
  return cssRules.map(ruleToCSS).join('\n\n');
}

// Hauptfunktion
function main() {
  // Prüfe Kommandozeilenargumente
  if (process.argv.length < 3) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }

  const outputFile = process.argv[2];
  const cssContent = generateCSS();
  
  // Schreibe die CSS-Datei
  fs.writeFileSync(outputFile, cssContent, 'utf8');
  console.log(`CSS erfolgreich generiert und gespeichert unter: ${outputFile}`);
}

main();
