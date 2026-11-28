#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "012efa1bbef6ce283ce5a9ce65990e2e2591656fa139a87ab1925b4d4d9942a2", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "javascript"}
// periodensystem.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');

function generateCSS() {
  const styles = {
    '*': {
      'box-sizing': 'border-box',
      'margin': '0',
      'padding': '0'
    },
    ':root': {
      '--bg': '#fafaf7',
      '--surface': '#ffffff',
      '--border': 'rgba(0,0,0,0.12)',
      '--text': '#1a1a1a',
      '--text-muted': '#666'
    },
    '@media (prefers-color-scheme: dark)': {
      ':root': {
        '--bg': '#1a1a1a',
        '--surface': '#242424',
        '--border': 'rgba(255,255,255,0.15)',
        '--text': '#f0f0f0',
        '--text-muted': '#aaa'
      }
    },
    'body': {
      'font-family': "-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif",
      'background': 'var(--bg)',
      'color': 'var(--text)',
      'padding': '24px',
      'max-width': '1100px',
      'margin': '0 auto',
      'line-height': '1.5'
    },
    'h1': {
      'font-size': '22px',
      'font-weight': '500',
      'margin-bottom': '4px'
    },
    '.subtitle': {
      'color': 'var(--text-muted)',
      'font-size': '14px',
      'margin-bottom': '20px'
    },
    '.detail': {
      'background': 'var(--surface)',
      'border': '1px solid var(--border)',
      'border-radius': '12px',
      'padding': '16px 20px',
      'min-height': '110px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '20px',
      'margin-bottom': '16px'
    },
    '.detail-empty': {
      'color': 'var(--text-muted)',
      'font-size': '14px',
      'text-align': 'center',
      'width': '100%'
    },
    '.symbol-box': {
      'font-size': '40px',
      'font-weight': '500',
      'line-height': '1',
      'width': '80px',
      'height': '80px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border-radius': '8px',
      'flex-shrink': '0'
    },
    '.info-name': {
      'font-size': '20px',
      'font-weight': '500',
      'margin-bottom': '8px'
    },
    '.info-meta': {
      'font-size': '13px',
      'color': 'var(--text-muted)',
      'display': 'grid',
      'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      'gap': '4px 24px'
    },
    '.info-meta b': {
      'font-weight': '500',
      'color': 'var(--text)',
      'margin-left': '6px'
    },
    '.grid': {
      'display': 'grid',
      'grid-template-columns': 'repeat(18, minmax(0, 1fr))',
      'gap': '3px'
    },
    '.fgrid': {
      'margin-top': '8px'
    },
    '.cell': {
      'aspect-ratio': '1',
      'border-radius': '4px',
      'padding': '3px',
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'cursor': 'pointer',
      'font-family': 'inherit',
      'line-height': '1',
      'transition': 'transform 0.12s ease',
      'border': '0',
      'position': 'relative',
      'overflow': 'hidden'
    },
    '.cell:hover': {
      'transform': 'scale(1.18)',
      'z-index': '5',
      'box-shadow': '0 2px 8px rgba(0,0,0,0.15)'
    },
    '.cell:focus-visible': {
      'outline': '2px solid var(--text)',
      'outline-offset': '1px'
    },
    '.cell.active': {
      'outline': '2px solid var(--text)',
      'outline-offset': '1px',
      'z-index': '4'
    },
    '.cell .num': {
      'font-size': '9px',
      'opacity': '0.75',
      'align-self': 'flex-start',
      'line-height': '1',
      'padding-left': '2px'
    },
    '.cell .sym': {
      'font-size': '14px',
      'font-weight': '500',
      'margin-top': '2px'
    },
    '.cell-marker': {
      'cursor': 'default',
      'font-size': '9px',
      'font-weight': '500',
      'border': '1px dashed currentColor',
      'background': 'transparent !important'
    },
    '.cell-marker:hover': {
      'transform': 'none',
      'box-shadow': 'none'
    },
    '.cat-am': {
      'background': '#FCEBEB',
      'color': '#501313'
    },
    '.cat-em': {
      'background': '#FAEEDA',
      'color': '#412402'
    },
    '.cat-tm': {
      'background': '#E6F1FB',
      'color': '#042C53'
    },
    '.cat-ptm': {
      'background': '#F1EFE8',
      'color': '#2C2C2A'
    },
    '.cat-hm': {
      'background': '#E1F5EE',
      'color': '#04342C'
    },
    '.cat-nm': {
      'background': '#EAF3DE',
      'color': '#173404'
    },
    '.cat-h': {
      'background': '#EEEDFE',
      'color': '#26215C'
    },
    '.cat-eg': {
      'background': '#FBEAF0',
      'color': '#4B1528'
    },
    '.cat-la': {
      'background': '#FAECE7',
      'color': '#4A1B0C'
    },
    '.cat-ac': {
      'background': '#F5C4B3',
      'color': '#4A1B0C'
    },
    '@media (prefers-color-scheme: dark) .cat-am': {
      'background': '#791F1F',
      'color': '#F7C1C1'
    },
    '@media (prefers-color-scheme: dark) .cat-em': {
      'background': '#633806',
      'color': '#FAC775'
    },
    '@media (prefers-color-scheme: dark) .cat-tm': {
      'background': '#0C447C',
      'color': '#B5D4F4'
    },
    '@media (prefers-color-scheme: dark) .cat-ptm': {
      'background': '#444441',
      'color': '#D3D1C7'
    },
    '@media (prefers-color-scheme: dark) .cat-hm': {
      'background': '#085041',
      'color': '#9FE1CB'
    },
    '@media (prefers-color-scheme: dark) .cat-nm': {
      'background': '#27500A',
      'color': '#C0DD97'
    },
    '@media (prefers-color-scheme: dark) .cat-h': {
      'background': '#3C3489',
      'color': '#CECBF6'
    },
    '@media (prefers-color-scheme: dark) .cat-eg': {
      'background': '#72243E',
      'color': '#F4C0D1'
    },
    '@media (prefers-color-scheme: dark) .cat-la': {
      'background': '#712B13',
      'color': '#F5C4B3'
    },
    '@media (prefers-color-scheme: dark) .cat-ac': {
      'background': '#993C1D',
      'color': '#F5C4B3'
    },
    '.legend': {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fit, minmax(160px, 1fr))',
      'gap': '8px 16px',
      'margin-top': '24px',
      'font-size': '12px',
      'color': 'var(--text-muted)'
    },
    '.legend-item': {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px'
    },
    '.legend-swatch': {
      'width': '14px',
      'height': '14px',
      'border-radius': '3px',
      'flex-shrink': '0'
    }
  };

  let cssContent = `/* abstraction-provenance: {"artifact_sha256": "57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "css"} */\n`;
  cssContent += `/* periodensystem.html — portiert nach css */\n`;
  cssContent += `/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n`;
  cssContent += `/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n`;

  for (const [selector, rules] of Object.entries(styles)) {
    if (selector.startsWith('@media')) {
      cssContent += `${selector} {\n`;
      for (const [subSelector, subRules] of Object.entries(rules)) {
        cssContent += `  ${subSelector} { `;
        cssContent += Object.entries(subRules).map(([prop, value]) => `${prop}: ${value}`).join('; ');
        cssContent += ' }\n';
      }
      cssContent += '}\n\n';
    } else {
      cssContent += `${selector} { `;
      cssContent += Object.entries(rules).map(([prop, value]) => `${prop}: ${value}`).join('; ');
      cssContent += ' }\n';
    }
  }

  return cssContent;
}

function main() {
  const args = process.argv.slice(2);
  if (args.length !== 1) {
    console.error('Verwendung: node periodensystem.js <ausgabedatei>');
    process.exit(1);
  }

  const outputFile = args[0];
  const cssContent = generateCSS();
  
  try {
    fs.writeFileSync(outputFile, cssContent, 'utf8');
    console.log(`CSS erfolgreich geschrieben nach: ${outputFile}`);
  } catch (error) {
    console.error('Fehler beim Schreiben der Datei:', error.message);
    process.exit(1);
  }
}

main();
