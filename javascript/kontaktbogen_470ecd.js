#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "dabdc06d5dc719e9d7b09ddad5f6fbfefb30f0304104ce27e890a00cd9e75dbf", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "javascript"}
// kontaktbogen.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const styles = {
    root: {
      '--bg': '#FAF8F4',
      '--ink': '#1B1A17',
      '--muted': '#6E6A61',
      '--line': '#E5E1D8',
      '--accent': '#A8542F',
      '--accent-2': '#2E7D7B',
      '--surface': '#fff'
    },
    
    universal: {
      'box-sizing': 'border-box'
    },
    
    body: {
      margin: '0',
      'font-family': "'Hanken Grotesk', system-ui, sans-serif",
      background: 'var(--bg)',
      color: 'var(--ink)',
      'line-height': '1.5'
    },
    
    header: {
      padding: '2.5rem 2rem 1rem',
      'border-bottom': '1px solid var(--line)',
      background: 'var(--surface)',
      position: 'sticky',
      top: '0',
      'z-index': '10'
    },
    
    'header h1': {
      margin: '0 0 .5rem',
      'font-family': "'Newsreader', Georgia, serif",
      'font-weight': '400',
      'font-size': '2.25rem'
    },
    
    'header p': {
      margin: '.25rem 0',
      color: 'var(--muted)',
      'max-width': '80ch'
    },
    
    '.legend': {
      display: 'flex',
      gap: '1rem',
      'flex-wrap': 'wrap',
      'margin-top': '.75rem',
      'font-size': '.8125rem'
    },
    
    '.pill': {
      padding: '.15rem .6rem',
      'border-radius': '999px',
      border: '1px solid var(--line)',
      background: '#fff'
    },
    
    '.pill.pflicht': {
      'border-color': 'var(--accent)',
      color: 'var(--accent)',
      'font-weight': '600'
    },
    
    '.pill.auswahl': {
      'border-color': 'var(--accent-2)',
      color: 'var(--accent-2)',
      'font-weight': '600'
    },
    
    main: {
      padding: '2rem',
      'max-width': '1400px',
      margin: '0 auto'
    },
    
    section: {
      margin: '2.5rem 0'
    },
    
    'section h2': {
      'font-family': "'Newsreader', serif",
      'font-weight': '400',
      'font-size': '1.5rem',
      margin: '0 0 .25rem',
      display: 'flex',
      'align-items': 'center',
      gap: '.75rem'
    },
    
    'section .sub': {
      color: 'var(--muted)',
      'font-size': '.875rem',
      margin: '0 0 1.25rem'
    },
    
    '.grid': {
      display: 'grid',
      'grid-template-columns': 'repeat(auto-fill, minmax(240px, 1fr))',
      gap: '1rem'
    },
    
    '.card': {
      background: 'var(--surface)',
      border: '1px solid var(--line)',
      'border-radius': '10px',
      overflow: 'hidden',
      display: 'flex',
      'flex-direction': 'column'
    },
    
    '.card .imgwrap': {
      'aspect-ratio': '1',
      background: '#f1eee7',
      display: 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      overflow: 'hidden'
    },
    
    '.card img': {
      width: '100%',
      height: '100%',
      'object-fit': 'contain',
      background: '#fff'
    },
    
    '.card .meta': {
      padding: '.6rem .75rem .75rem',
      'font-size': '.78125rem'
    },
    
    '.card .name': {
      'font-family': "'JetBrains Mono', monospace",
      'font-size': '.6875rem',
      color: 'var(--muted)',
      'word-break': 'break-all',
      'line-height': '1.3',
      'margin-bottom': '.35rem'
    },
    
    '.card .dims': {
      color: 'var(--muted)',
      'font-size': '.6875rem',
      'margin-bottom': '.35rem'
    },
    
    '.card .prompt': {
      color: 'var(--ink)',
      'font-size': '.75rem',
      'line-height': '1.35',
      'font-style': 'italic',
      'border-top': '1px solid var(--line)',
      'padding-top': '.4rem',
      'margin-top': '.35rem',
      'max-height': '5.5em',
      overflow: 'hidden'
    },
    
    '.tag': {
      display: 'inline-block',
      padding: '.1rem .45rem',
      'border-radius': '999px',
      'font-size': '.6875rem',
      background: '#F1EEE7',
      color: 'var(--muted)',
      'margin-right': '.25rem'
    },
    
    '.tag.p': {
      background: '#F1E5DD',
      color: 'var(--accent)'
    },
    
    '.tag.a': {
      background: '#DEEDEC',
      color: 'var(--accent-2)'
    }
  };

  let cssContent = '';
  
  // Add comments
  cssContent += `/* abstraction-provenance: {"artifact_sha256": "450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "css"} */\n`;
  cssContent += `/* kontaktbogen.html — portiert nach css */\n`;
  cssContent += `/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n`;
  cssContent += `/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n`;
  
  // Add root variables
  cssContent += ':root {\n';
  for (const [key, value] of Object.entries(styles.root)) {
    cssContent += `  ${key}: ${value};\n`;
  }
  cssContent += '}\n\n';
  
  // Add universal selector
  cssContent += '* {\n';
  for (const [key, value] of Object.entries(styles.universal)) {
    cssContent += `  ${key}: ${value};\n`;
  }
  cssContent += '}\n\n';
  
  // Add all other selectors
  const sortedSelectors = Object.keys(styles).filter(sel => sel !== 'root' && sel !== 'universal').sort();
  sortedSelectors.unshift('universal'); // Move universal to the beginning after root
  
  for (const selector of sortedSelectors) {
    if (selector === 'universal') continue; // Already handled
    
    const rules = styles[selector];
    cssContent += `${selector} {\n`;
    for (const [property, value] of Object.entries(rules)) {
      cssContent += `  ${property}: ${value};\n`;
    }
    cssContent += '}\n\n';
  }
  
  return cssContent.trim() + '\n';
}

function writeFile(content, filename) {
  const dir = path.dirname(filename);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(filename, content, 'utf8');
}

// Main execution
if (require.main === module) {
  const outputFile = process.argv[2] || 'kontaktbogen.css';
  const cssContent = generateCSS();
  writeFile(cssContent, outputFile);
  console.log(`CSS file written to ${outputFile}`);
}

module.exports = { generateCSS, writeFile };
