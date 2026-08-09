#!/usr/bin/env node
// gateway-styles.css — portiert nach javascript
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// CSS content structure
const cssStructure = {
  // Universal selector
  '*': {
    'box-sizing': 'border-box',
    'margin': '0',
    'padding': '0'
  },
  
  '*::before': {
    'box-sizing': 'border-box',
    'margin': '0',
    'padding': '0'
  },
  
  '*::after': {
    'box-sizing': 'border-box',
    'margin': '0',
    'padding': '0'
  },
  
  // Root variables
  ':root': {
    '--bg': '#0d1117',
    '--surface': '#161b22',
    '--border': '#30363d',
    '--text': '#e6edf3',
    '--muted': '#8b949e',
    '--green': '#3fb950',
    '--yellow': '#d29922',
    '--red': '#f85149',
    '--accent': '#58a6ff'
  },
  
  // Body styles
  'body': {
    'background': 'var(--bg)',
    'color': 'var(--text)',
    'font-family': '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'min-height': '100vh'
  },
  
  // Header styles
  'header': {
    'display': 'flex',
    'align-items': 'center',
    'gap': '1rem',
    'padding': '1.25rem 2rem',
    'border-bottom': '1px solid var(--border)',
    'background': 'var(--surface)'
  },
  
  'header h1': {
    'font-size': '1.25rem',
    'color': 'var(--accent)'
  },
  
  // Badge styles
  '.badge': {
    'padding': '.25rem .75rem',
    'border-radius': '999px',
    'font-size': '.75rem',
    'font-weight': '600',
    'background': 'var(--border)',
    'color': 'var(--muted)'
  },
  
  '.badge.ok': {
    'background': '#1a3a2a',
    'color': 'var(--green)'
  },
  
  '.badge.warn': {
    'background': '#3a2e0a',
    'color': 'var(--yellow)'
  },
  
  '.badge.error': {
    'background': '#3a1010',
    'color': 'var(--red)'
  },
  
  // Main styles
  'main': {
    'padding': '2rem',
    'max-width': '960px',
    'margin': '0 auto'
  },
  
  // Grid styles
  '.grid': {
    'display': 'grid',
    'grid-template-columns': 'repeat(auto-fit, minmax(260px, 1fr))',
    'gap': '1rem',
    'margin-bottom': '2rem'
  },
  
  // Card styles
  '.card': {
    'background': 'var(--surface)',
    'border': '1px solid var(--border)',
    'border-radius': '8px',
    'padding': '1.25rem',
    'position': 'relative'
  },
  
  '.card h2': {
    'font-size': '1rem',
    'margin-bottom': '.25rem'
  },
  
  '.card .endpoint': {
    'font-size': '.8rem',
    'color': 'var(--muted)'
  },
  
  // Status dot styles
  '.status-dot': {
    'position': 'absolute',
    'top': '1.25rem',
    'right': '1.25rem',
    'width': '10px',
    'height': '10px',
    'border-radius': '50%',
    'background': 'var(--border)'
  },
  
  '.status-dot.green': {
    'background': 'var(--green)',
    'box-shadow': '0 0 6px var(--green)'
  },
  
  '.status-dot.red': {
    'background': 'var(--red)',
    'box-shadow': '0 0 6px var(--red)'
  },
  
  // Metrics styles
  '.metrics h2': {
    'font-size': '1rem',
    'margin-bottom': '1rem'
  },
  
  // Table styles
  'table': {
    'width': '100%',
    'border-collapse': 'collapse',
    'font-size': '.875rem'
  },
  
  'th': {
    'padding': '.625rem 1rem',
    'text-align': 'left',
    'border-bottom': '1px solid var(--border)',
    'color': 'var(--muted)',
    'font-weight': '500'
  },
  
  'td': {
    'padding': '.625rem 1rem',
    'text-align': 'left',
    'border-bottom': '1px solid var(--border)'
  },
  
  'tr:last-child td': {
    'border-bottom': 'none'
  }
};

// Function to convert object to CSS string
function objectToCSS(obj) {
  let css = '';
  
  for (const [selector, properties] of Object.entries(obj)) {
    css += `${selector} {\n`;
    
    for (const [property, value] of Object.entries(properties)) {
      css += `  ${property}: ${value};\n`;
    }
    
    css += '}\n\n';
  }
  
  return css;
}

// Add comments
function addComments(css) {
  return `/* OpenClaw Gateway Dashboard */

${css}`.trim();
}

// Generate the complete CSS
let cssOutput = objectToCSS(cssStructure);
cssOutput = addComments(cssOutput);

// Handle file output
const outputFile = process.argv[2];

if (outputFile) {
  fs.writeFileSync(outputFile, cssOutput, 'utf8');
} else {
  console.log(cssOutput);
}
