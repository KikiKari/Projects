#!/usr/bin/env node
// status-overview.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const styles = {
    '*': {
      'box-sizing': 'border-box'
    },
    'html,body': {
      margin: '0',
      'min-height': '100%',
      background: '#101015',
      color: '#fff',
      font: '14px system-ui,sans-serif'
    },
    'body': {
      display: 'flex',
      'flex-direction': 'column',
      height: '100vh'
    },
    'header': {
      display: 'flex',
      gap: '1em',
      'align-items': 'baseline',
      padding: '0 12px'
    },
    'h1': {
      'font-size': '17px',
      margin: '8px 0'
    },
    'header p': {
      'font-size': '12px',
      color: '#bbb',
      margin: '0'
    },
    'main': {
      flex: '1',
      'min-height': '0',
      display: 'grid',
      'grid-template-columns': 'repeat(3,minmax(0,1fr))',
      'grid-template-rows': 'repeat(3,minmax(0,1fr))',
      gap: '4px',
      padding: '0'
    },
    '.tile': {
      'min-width': '0',
      'min-height': '0',
      display: 'flex',
      'flex-direction': 'column',
      background: '#202026',
      border: '1px solid #393940'
    },
    '.tile h2': {
      'font-size': '13px',
      margin: '3px 8px'
    },
    '.tile video': {
      'min-height': '0',
      width: '100%',
      flex: '1',
      'object-fit': 'contain',
      background: '#000'
    },
    '.tile p': {
      'font-size': '11px',
      margin: '3px 8px',
      color: '#ddd'
    },
    'main.grid2': {
      'grid-template-columns': 'repeat(2,minmax(0,1fr))',
      'grid-template-rows': 'repeat(2,minmax(0,1fr))'
    },
    '.tile[hidden]': {
      display: 'none'
    }
  };

  let cssContent = '';
  
  for (const [selector, rules] of Object.entries(styles)) {
    cssContent += `${selector}{`;
    for (const [property, value] of Object.entries(rules)) {
      cssContent += `${property}:${value};`;
    }
    cssContent += '}';
  }
  
  return cssContent;
}

function writeCSSFile(filename) {
  const cssContent = generateCSS();
  fs.writeFileSync(path.resolve(filename), cssContent);
}

// Wenn das Skript direkt aufgerufen wird
if (require.main === module) {
  const filename = process.argv[2];
  if (!filename) {
    console.error('Bitte geben Sie einen Dateinamen als Parameter an.');
    process.exit(1);
  }
  
  writeCSSFile(filename);
  console.log(`CSS-Datei wurde erfolgreich erstellt: ${filename}`);
}

module.exports = { generateCSS, writeCSSFile };
