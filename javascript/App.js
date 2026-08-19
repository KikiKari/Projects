#!/usr/bin/env node
// App.css — portiert nach javascript
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const styles = {
    ':root': {
      'color-scheme': 'dark',
      'font-family': 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      'background': '#0b1020',
      'color': '#eef2ff'
    },
    
    '*': {
      'box-sizing': 'border-box'
    },
    
    'body': {
      'margin': '0',
      'min-width': '320px',
      'min-height': '100vh',
      'background': [
        'radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem)',
        'radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem)',
        'linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)'
      ].join(',\n    ')
    },
    
    '.page-shell': {
      'min-height': '100vh',
      'display': 'grid',
      'place-items': 'center',
      'padding': '2rem'
    },
    
    '.hero-card': {
      'width': 'min(100%, 56rem)',
      'padding': 'clamp(2rem, 6vw, 4.5rem)',
      'border': '1px solid rgba(148, 163, 184, 0.28)',
      'border-radius': '2rem',
      'background': 'rgba(15, 23, 42, 0.72)',
      'box-shadow': '0 2rem 6rem rgba(0, 0, 0, 0.35)',
      'backdrop-filter': 'blur(18px)'
    },
    
    '.eyebrow': {
      'margin': '0 0 1rem',
      'color': '#67e8f9',
      'font-size': '0.8rem',
      'font-weight': '700',
      'letter-spacing': '0.18em',
      'text-transform': 'uppercase'
    },
    
    'h1': {
      'margin': '0',
      'max-width': '12ch',
      'font-size': 'clamp(2.75rem, 8vw, 6rem)',
      'line-height': '0.95',
      'letter-spacing': '-0.06em'
    },
    
    '.lead': {
      'margin': '1.5rem 0 0',
      'max-width': '42rem',
      'color': '#cbd5e1',
      'font-size': 'clamp(1.05rem, 2vw, 1.35rem)',
      'line-height': '1.65'
    },
    
    '.link-grid': {
      'display': 'grid',
      'gap': '0.85rem',
      'margin-top': '2rem'
    },
    
    '.link-grid a': {
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
    },
    
    '.link-grid a:hover': {
      'border-color': 'rgba(103, 232, 249, 0.75)',
      'outline': 'none',
      'background': 'rgba(103, 232, 249, 0.12)'
    },
    
    '.link-grid a:focus-visible': {
      'border-color': 'rgba(103, 232, 249, 0.75)',
      'outline': 'none',
      'background': 'rgba(103, 232, 249, 0.12)'
    }
  };

  function formatValue(value) {
    if (Array.isArray(value)) {
      return value.join(',\n    ');
    }
    return value;
  }

  function buildRule(selector, properties) {
    const propStrings = Object.entries(properties).map(([prop, value]) => 
      `  ${prop}: ${formatValue(value)};`
    );
    
    return `${selector} {\n${propStrings.join('\n')}\n}`;
  }

  const cssSections = Object.entries(styles).map(([selector, properties]) => 
    buildRule(selector, properties)
  );

  return cssSections.join('\n\n');
}

function writeCSSFile(filename) {
  const cssContent = generateCSS();
  fs.writeFileSync(path.resolve(filename), cssContent, 'utf8');
}

if (require.main === module) {
  const filename = process.argv[2] || 'App.css';
  writeCSSFile(filename);
  console.log(`CSS file generated: ${filename}`);
}

module.exports = { generateCSS, writeCSSFile };
