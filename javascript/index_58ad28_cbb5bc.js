#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "34a22e3d7feb0cc72da6592ddc4bd5b400999bcdbb4410e3b3a725ffb9c98c06", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "javascript"}
// index_58ad28.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Funktion zur Erstellung eines CSS-Regelobjekts
function createRule(selector, declarations) {
  return { selector, declarations };
}

// Funktion zur Erstellung einer Media-Query-Regel
function createMediaQuery(condition, rules) {
  return { condition, rules };
}

// Funktion zur Erstellung eines Kommentars
function createComment(text) {
  return { type: 'comment', text };
}

// Erstellen der CSS-Struktur
const cssStructure = [
  createComment('abstraction-provenance: {"artifact_sha256": "537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "css"}'),
  createComment('index.html — portiert nach css'),
  createComment('Quelle: html, Projects@Telegram-Monitor:public/index.html'),
  createComment('Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py'),

  // Root-Variablen
  createRule(':root', {
    '--bg': '#ffffff',
    '--soft': '#f6f7f9',
    '--line': '#e3e6ea',
    '--text': '#16191d',
    '--muted': '#5f6773',
    '--tg': '#2481cc',
    '--tg-soft': '#e8f2fb',
    '--tt': '#fe2c55',
    '--ok': '#15803d',
    '--ok-soft': '#e7f6ec',
    '--warn': '#b45309',
    '--warn-soft': '#fdf3e3',
    'color-scheme': 'light'
  }),

  // Dark Mode Media Query
  createMediaQuery('(prefers-color-scheme: dark)', [
    createRule(':root', {
      '--bg': '#0f1115',
      '--soft': '#171a21',
      '--line': '#262b36',
      '--text': '#f2f4f8',
      '--muted': '#9aa3b2',
      '--tg-soft': '#132a3d',
      '--ok-soft': '#12261a',
      '--warn-soft': '#2c2110',
      'color-scheme': 'dark'
    })
  ]),

  // Globale Styles
  createRule('*', {
    'box-sizing': 'border-box'
  }),

  createRule('body', {
    'margin': '0',
    'background': 'var(--bg)',
    'color': 'var(--text)',
    'font': '16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
  }),

  createRule('.wrap', {
    'max-width': '820px',
    'margin': '0 auto',
    'padding': '0 20px 72px'
  }),

  createRule('header', {
    'padding': '64px 0 40px',
    'border-bottom': '1px solid var(--line)',
    'margin-bottom': '8px'
  }),

  createRule('h1', {
    'font-size': '34px',
    'line-height': '1.2',
    'margin': '0 0 12px',
    'letter-spacing': '-0.02em'
  }),

  createRule('.lede', {
    'font-size': '18px',
    'color': 'var(--muted)',
    'margin': '0 0 22px',
    'max-width': '60ch'
  }),

  createRule('h2', {
    'font-size': '13px',
    'margin': '44px 0 14px',
    'text-transform': 'uppercase',
    'letter-spacing': '0.06em',
    'color': 'var(--muted)',
    'font-weight': '650'
  }),

  createRule('h3', {
    'font-size': '17px',
    'margin': '26px 0 6px'
  }),

  createRule('p', {
    'margin': '0 0 14px',
    'max-width': '68ch'
  }),

  createRule('.badges', {
    'display': 'flex',
    'gap': '7px',
    'flex-wrap': 'wrap',
    'margin-bottom': '22px'
  }),

  createRule('.badge', {
    'font-size': '12px',
    'font-weight': '650',
    'padding': '4px 11px',
    'border-radius': '99px',
    'background': 'var(--soft)',
    'color': 'var(--muted)',
    'border': '1px solid var(--line)'
  }),

  createRule('.badge.on', {
    'background': 'var(--ok-soft)',
    'color': 'var(--ok)',
    'border-color': 'transparent'
  }),

  createRule('.cta', {
    'display': 'flex',
    'gap': '10px',
    'flex-wrap': 'wrap'
  }),

  createRule('.btn', {
    'display': 'inline-block',
    'font-weight': '650',
    'font-size': '15px',
    'padding': '11px 20px',
    'border-radius': '9px',
    'text-decoration': 'none',
    'border': '1px solid var(--line)',
    'background': 'var(--bg)',
    'color': 'var(--text)'
  }),

  createRule('.btn.primary', {
    'background': 'var(--tg)',
    'border-color': 'var(--tg)',
    'color': '#fff'
  }),

  createRule('.btn:hover', {
    'border-color': 'var(--tg)'
  }),

  createRule('.grid', {
    'display': 'grid',
    'grid-template-columns': 'repeat(auto-fit, minmax(230px, 1fr))',
    'gap': '14px'
  }),

  createRule('.card', {
    'border': '1px solid var(--line)',
    'border-radius': '12px',
    'padding': '16px 18px',
    'background': 'var(--bg)'
  }),

  createRule('.card h3', {
    'margin-top': '0',
    'font-size': '15.5px'
  }),

  createRule('.card p', {
    'font-size': '14px',
    'color': 'var(--muted)',
    'margin': '0'
  }),

  createRule('ol.steps', {
    'list-style': 'none',
    'counter-reset': 's',
    'padding': '0',
    'margin': '0'
  }),

  createRule('ol.steps li', {
    'counter-increment': 's',
    'position': 'relative',
    'padding': '0 0 20px 40px',
    'border-left': '2px solid var(--line)',
    'margin-left': '11px'
  }),

  createRule('ol.steps li:last-child', {
    'border-left-color': 'transparent',
    'padding-bottom': '0'
  }),

  createRule('ol.steps li::before', {
    'content': 'counter(s)',
    'position': 'absolute',
    'left': '-13px',
    'top': '0',
    'width': '24px',
    'height': '24px',
    'border-radius': '50%',
    'background': 'var(--tg)',
    'color': '#fff',
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'font-size': '12px',
    'font-weight': '700'
  }),

  createRule('ol.steps b', {
    'display': 'block',
    'margin-bottom': '3px'
  }),

  createRule('ol.steps p', {
    'font-size': '14.5px',
    'color': 'var(--muted)',
    'margin': '0 0 8px'
  }),

  createRule('code', {
    'background': 'var(--soft)',
    'padding': '2px 7px',
    'border-radius': '5px',
    'font-size': '13.5px',
    'font-family': 'ui-monospace, SFMono-Regular, Menlo, monospace',
    'word-break': 'break-word'
  }),

  createRule('pre', {
    'background': 'var(--soft)',
    'border': '1px solid var(--line)',
    'border-radius': '10px',
    'padding': '13px 15px',
    'overflow-x': 'auto',
    'margin': '0 0 14px'
  }),

  createRule('pre code', {
    'background': 'none',
    'padding': '0',
    'font-size': '13.5px',
    'line-height': '1.7'
  }),

  createRule('table', {
    'width': '100%',
    'border-collapse': 'collapse',
    'font-size': '14.5px',
    'margin': '0 0 16px'
  }),

  createRule('th, td', {
    'text-align': 'left',
    'padding': '9px 11px',
    'border-bottom': '1px solid var(--line)',
    'vertical-align': 'top'
  }),

  createRule('th', {
    'color': 'var(--muted)',
    'font-size': '12px',
    'text-transform': 'uppercase',
    'letter-spacing': '0.04em',
    'font-weight': '650'
  }),

  createRule('.note', {
    'border-left': '3px solid var(--warn)',
    'background': 'var(--warn-soft)',
    'border-radius': '0 9px 9px 0',
    'padding': '13px 16px',
    'margin': '0 0 16px',
    'font-size': '14.5px'
  }),

  createRule('.note b', {
    'display': 'block',
    'margin-bottom': '3px'
  }),

  createRule('a', {
    'color': 'var(--tg)'
  }),

  createRule('footer', {
    'margin-top': '52px',
    'padding-top': '22px',
    'border-top': '1px solid var(--line)',
    'font-size': '13.5px',
    'color': 'var(--muted)'
  })
];

// Funktion zum Konvertieren der Struktur in CSS-Text
function generateCSSText(structure) {
  let css = '';
  
  structure.forEach(item => {
    if (item.type === 'comment') {
      css += `/* ${item.text} */\n`;
    } else if (item.condition) { // Media Query
      css += `\n@media ${item.condition} {\n`;
      item.rules.forEach(rule => {
        css += `  ${rule.selector} {\n`;
        Object.entries(rule.declarations).forEach(([prop, value]) => {
          css += `    ${prop}: ${value};\n`;
        });
        css += `  }\n`;
      });
      css += `}\n`;
    } else { // Normale Regel
      css += `${item.selector} {\n`;
      Object.entries(item.declarations).forEach(([prop, value]) => {
        css += `  ${prop}: ${value};\n`;
      });
      css += `}\n\n`;
    }
  });
  
  return css;
}

// Hauptfunktion
function main() {
  const cssContent = generateCSSText(cssStructure);
  
  // Wenn ein Dateipfad als Argument übergeben wurde, verwenden wir diesen
  // Andernfalls verwenden wir einen Standardpfad
  const outputPath = process.argv[2] || join(__dirname, 'index_58ad28.css');
  
  try {
    writeFileSync(outputPath, cssContent);
    console.log(`CSS-Datei erfolgreich erstellt: ${outputPath}`);
  } catch (error) {
    console.error(`Fehler beim Schreiben der Datei: ${error.message}`);
    process.exit(1);
  }
}

main();
