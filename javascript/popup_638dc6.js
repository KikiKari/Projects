#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "5c397cd8780f8ebf211a4bdcad136ee716265e2ce83d1389944615d4e5145b35", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "javascript"}
// popup.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/popup.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const styles = {
    ':root': {
      '--bg': '#0f1115',
      '--card': '#171a21',
      '--line': '#262b36',
      '--text': '#f2f4f8',
      '--muted': '#9aa3b2',
      '--accent': '#fe2c55',
      '--ok': '#22c55e',
      'color-scheme': 'dark'
    },
    '@media (prefers-color-scheme: light)': {
      ':root': {
        '--bg': '#fff',
        '--card': '#f6f7f9',
        '--line': '#e3e6ea',
        '--text': '#16191d',
        '--muted': '#6b7280'
      }
    },
    '*': {
      'box-sizing': 'border-box'
    },
    'body': {
      'margin': '0',
      'width': '420px',
      'max-height': '600px',
      'overflow': 'auto',
      'background': 'var(--bg)',
      'color': 'var(--text)',
      'font': '14px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    },
    '.wrap': {
      'padding': '12px'
    },
    'header': {
      'display': 'flex',
      'gap': '8px',
      'align-items': 'center',
      'margin-bottom': '10px'
    },
    'h1': {
      'font-size': '14px',
      'margin': '0',
      'font-weight': '650',
      'flex': '1'
    },
    '.badge': {
      'font-size': '11px',
      'font-weight': '700',
      'padding': '3px 9px',
      'border-radius': '99px',
      'background': '#2a2f3a',
      'color': 'var(--muted)',
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '5px'
    },
    '.badge.live': {
      'background': 'var(--accent)',
      'color': '#fff'
    },
    '.badge .dot': {
      'width': '6px',
      'height': '6px',
      'border-radius': '50%',
      'background': 'currentColor'
    },
    '.badge.live .dot': {
      'animation': 'pulse 1.6s infinite'
    },
    '@keyframes pulse': {
      '0%, 100%': {
        'opacity': '1'
      },
      '50%': {
        'opacity': '.25'
      }
    },
    '.row': {
      'display': 'flex',
      'gap': '6px',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'margin-bottom': '8px'
    },
    'input, select, button': {
      'font': 'inherit',
      'border-radius': '7px',
      'border': '1px solid var(--line)',
      'background': 'var(--card)',
      'color': 'var(--text)',
      'padding': '6px 9px'
    },
    'button': {
      'cursor': 'pointer',
      'font-weight': '600'
    },
    'button.primary': {
      'background': 'var(--accent)',
      'border-color': 'var(--accent)',
      'color': '#fff'
    },
    '.player': {
      'position': 'relative',
      'width': '100%',
      'aspect-ratio': '9/16',
      'max-height': '360px',
      'background': '#000',
      'border-radius': '10px',
      'overflow': 'hidden',
      'border': '1px solid var(--line)',
      'margin': '8px 0'
    },
    '.player iframe': {
      'position': 'absolute',
      'inset': '0',
      'width': '100%',
      'height': '100%',
      'border': '0'
    },
    '.placeholder': {
      'position': 'absolute',
      'inset': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '6px',
      'align-items': 'center',
      'justify-content': 'center',
      'color': 'var(--muted)',
      'text-align': 'center',
      'padding': '16px',
      'font-size': '13px'
    },
    '.card': {
      'background': 'var(--card)',
      'border': '1px solid var(--line)',
      'border-radius': '10px',
      'padding': '10px 12px',
      'margin-bottom': '8px'
    },
    'h2': {
      'font-size': '11px',
      'text-transform': 'uppercase',
      'letter-spacing': '.05em',
      'color': 'var(--muted)',
      'margin': '0 0 6px',
      'font-weight': '650'
    },
    '.meta': {
      'color': 'var(--muted)',
      'font-size': '12.5px'
    },
    '.strong': {
      'color': 'var(--text)',
      'font-weight': '600'
    },
    '.stream': {
      'display': 'flex',
      'gap': '8px',
      'padding': '5px 0',
      'border-bottom': '1px solid var(--line)',
      'font-size': '12.5px'
    },
    '.stream:last-child': {
      'border-bottom': '0'
    },
    '.stream .when': {
      'color': 'var(--muted)',
      'white-space': 'nowrap',
      'font-variant-numeric': 'tabular-nums'
    },
    '.stream .t': {
      'flex': '1',
      'min-width': '0',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
      'white-space': 'nowrap'
    },
    '.stream.now': {
      'color': 'var(--accent)',
      'font-weight': '650'
    },
    '.err': {
      'background': '#3a1d22',
      'border': '1px solid #5c2a33',
      'color': '#ffb4c0',
      'padding': '8px 10px',
      'border-radius': '8px',
      'font-size': '12.5px',
      'margin-bottom': '8px'
    },
    '@media (prefers-color-scheme: light) .err': {
      'background': '#fdeceb',
      'border-color': '#f5c6c2',
      'color': '#b91c1c'
    },
    '.note': {
      'font-size': '11.5px',
      'color': 'var(--muted)',
      'line-height': '1.4',
      'margin-top': '8px'
    },
    'a': {
      'color': 'var(--accent)'
    }
  };

  function formatRule(selector, properties) {
    const propStrings = Object.entries(properties)
      .map(([prop, value]) => `  ${prop}: ${value};`)
      .join('\n');
    return `${selector} {\n${propStrings}\n}`;
  }

  const cssParts = [];

  // Process regular rules
  for (const [selector, properties] of Object.entries(styles)) {
    if (!selector.startsWith('@')) {
      cssParts.push(formatRule(selector, properties));
    }
  }

  // Process @media rules
  if (styles['@media (prefers-color-scheme: light)']) {
    let mediaContent = '';
    for (const [selector, properties] of Object.entries(styles['@media (prefers-color-scheme: light)'])) {
      mediaContent += formatRule(selector, properties) + '\n';
    }
    cssParts.push(`@media (prefers-color-scheme: light) {\n${mediaContent.trim()}\n}`);
  }

  // Process @keyframes
  if (styles['@keyframes pulse']) {
    let keyframeContent = '';
    for (const [step, properties] of Object.entries(styles['@keyframes pulse'])) {
      const propStrings = Object.entries(properties)
        .map(([prop, value]) => `    ${prop}: ${value};`)
        .join('\n');
      keyframeContent += `  ${step} {\n${propStrings}\n  }\n`;
    }
    cssParts.push(`@keyframes pulse {\n${keyframeContent}}`);
  }

  // Process nested media queries
  if (styles['@media (prefers-color-scheme: light) .err']) {
    cssParts.push(`@media (prefers-color-scheme: light) {\n  ${formatRule('.err', styles['@media (prefers-color-scheme: light) .err'])}\n}`);
  }

  return cssParts.join('\n\n') + '\n';
}

function addComments(cssContent) {
  const comments = [
    '/* abstraction-provenance: {"artifact_sha256": "9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "css"} */',
    '/* popup.html — portiert nach css */',
    '/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */',
    '/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */'
  ];
  
  return comments.join('\n') + '\n' + cssContent;
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length !== 1) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }
  
  const outputFile = args[0];
  let cssContent = generateCSS();
  cssContent = addComments(cssContent);
  
  try {
    fs.writeFileSync(outputFile, cssContent);
    console.log(`CSS erfolgreich generiert und gespeichert in: ${outputFile}`);
  } catch (error) {
    console.error(`Fehler beim Schreiben der Datei: ${error.message}`);
    process.exit(1);
  }
}

main();
