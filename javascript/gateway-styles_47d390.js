#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "52269e664538fd0aa64223790d7fa0cfa4577a893cd1fc85ddc0dc81bf9dc03c", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "javascript"}
// gateway-styles.css — portiert nach javascript
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// Funktion zum Erstellen eines CSS-Kommentars
function createComment(text) {
  return `/* ${text} */`;
}

// Funktion zum Erstellen einer CSS-Regel
function createRule(selector, declarations) {
  const decls = Object.entries(declarations)
    .map(([prop, value]) => `  ${prop}: ${value};`)
    .join('\n');
  return `${selector} {\n${decls}\n}`;
}

// Funktion zum Erstellen einer CSS-Variable-Deklaration
function createVarDeclaration(vars) {
  const varDecls = Object.entries(vars)
    .map(([name, value]) => `  ${name}: ${value};`)
    .join('\n');
  return `:root {\n${varDecls}\n}`;
}

// Erstellen des Stylesheets
function createStylesheet() {
  const parts = [];
  
  // Kommentar
  parts.push(createComment('OpenClaw Gateway Dashboard'));
  parts.push('');
  
  // Globale Reset-Regel
  parts.push(createRule('*, *::before, *::after', {
    'box-sizing': 'border-box',
    'margin': '0',
    'padding': '0'
  }));
  parts.push('');
  
  // Root-Variablen
  parts.push(createVarDeclaration({
    '--bg': '#0d1117',
    '--surface': '#161b22',
    '--border': '#30363d',
    '--text': '#e6edf3',
    '--muted': '#8b949e',
    '--green': '#3fb950',
    '--yellow': '#d29922',
    '--red': '#f85149',
    '--accent': '#58a6ff'
  }));
  parts.push('');
  
  // Body-Regel
  parts.push(createRule('body', {
    'background': 'var(--bg)',
    'color': 'var(--text)',
    'font-family': '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'min-height': '100vh'
  }));
  parts.push('');
  
  // Header-Regeln
  parts.push(createRule('header', {
    'display': 'flex',
    'align-items': 'center',
    'gap': '1rem',
    'padding': '1.25rem 2rem',
    'border-bottom': '1px solid var(--border)',
    'background': 'var(--surface)'
  }));
  parts.push('');
  
  parts.push(createRule('header h1', {
    'font-size': '1.25rem',
    'color': 'var(--accent)'
  }));
  parts.push('');
  
  // Badge-Regeln
  parts.push(createRule('.badge', {
    'padding': '.25rem .75rem',
    'border-radius': '999px',
    'font-size': '.75rem',
    'font-weight': '600',
    'background': 'var(--border)',
    'color': 'var(--muted)'
  }));
  parts.push('');
  
  parts.push(createRule('.badge.ok', {
    'background': '#1a3a2a',
    'color': 'var(--green)'
  }));
  parts.push('');
  
  parts.push(createRule('.badge.warn', {
    'background': '#3a2e0a',
    'color': 'var(--yellow)'
  }));
  parts.push('');
  
  parts.push(createRule('.badge.error', {
    'background': '#3a1010',
    'color': 'var(--red)'
  }));
  parts.push('');
  
  // Main-Regel
  parts.push(createRule('main', {
    'padding': '2rem',
    'max-width': '960px',
    'margin': '0 auto'
  }));
  parts.push('');
  
  // Grid-Regel
  parts.push(createRule('.grid', {
    'display': 'grid',
    'grid-template-columns': 'repeat(auto-fit, minmax(260px, 1fr))',
    'gap': '1rem',
    'margin-bottom': '2rem'
  }));
  parts.push('');
  
  // Card-Regeln
  parts.push(createRule('.card', {
    'background': 'var(--surface)',
    'border': '1px solid var(--border)',
    'border-radius': '8px',
    'padding': '1.25rem',
    'position': 'relative'
  }));
  parts.push('');
  
  parts.push(createRule('.card h2', {
    'font-size': '1rem',
    'margin-bottom': '.25rem'
  }));
  parts.push('');
  
  parts.push(createRule('.card .endpoint', {
    'font-size': '.8rem',
    'color': 'var(--muted)'
  }));
  parts.push('');
  
  // Status-Dot-Regeln
  parts.push(createRule('.status-dot', {
    'position': 'absolute',
    'top': '1.25rem',
    'right': '1.25rem',
    'width': '10px',
    'height': '10px',
    'border-radius': '50%',
    'background': 'var(--border)'
  }));
  parts.push('');
  
  parts.push(createRule('.status-dot.green', {
    'background': 'var(--green)',
    'box-shadow': '0 0 6px var(--green)'
  }));
  parts.push('');
  
  parts.push(createRule('.status-dot.red', {
    'background': 'var(--red)',
    'box-shadow': '0 0 6px var(--red)'
  }));
  parts.push('');
  
  // Metrics-Regeln
  parts.push(createRule('.metrics h2', {
    'font-size': '1rem',
    'margin-bottom': '1rem'
  }));
  parts.push('');
  
  // Table-Regeln
  parts.push(createRule('table', {
    'width': '100%',
    'border-collapse': 'collapse',
    'font-size': '.875rem'
  }));
  parts.push('');
  
  parts.push(createRule('th, td', {
    'padding': '.625rem 1rem',
    'text-align': 'left',
    'border-bottom': '1px solid var(--border)'
  }));
  parts.push('');
  
  parts.push(createRule('th', {
    'color': 'var(--muted)',
    'font-weight': '500'
  }));
  parts.push('');
  
  parts.push(createRule('tr:last-child td', {
    'border-bottom': 'none'
  }));
  
  return parts.join('\n');
}

// Hauptfunktion
function main() {
  const args = process.argv.slice(2);
  
  if (args.length !== 1) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }
  
  const outputPath = path.resolve(args[0]);
  const stylesheet = createStylesheet();
  
  fs.writeFileSync(outputPath, stylesheet);
  console.log(`Stylesheet wurde erfolgreich erstellt: ${outputPath}`);
}

main();
