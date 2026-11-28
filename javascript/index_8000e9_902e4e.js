#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "909109f33090a8dfd3594f346168c9e7624fcda75605422997e00b10329587c3", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "javascript"}
// index_8000e9.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/index_8000e9.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const variables = {
    '--bg': '#FAF8F4',
    '--ink': '#1B1A17',
    '--accent': '#A8542F',
    '--accent-2': '#2E7D7B',
    '--font-display': "'Newsreader', Georgia, serif",
    '--font-body': "'Hanken Grotesk', -apple-system, sans-serif",
    '--font-mono': "'JetBrains Mono', monospace"
  };

  const rules = [
    {
      selector: ':root',
      declarations: variables
    },
    {
      selector: '*',
      declarations: {
        'box-sizing': 'border-box',
        'margin': '0',
        'padding': '0'
      }
    },
    {
      selector: 'body',
      declarations: {
        'font-family': 'var(--font-body)',
        'background': 'var(--bg)',
        'color': 'var(--ink)',
        'padding': '32px 16px 80px'
      }
    },
    {
      selector: 'h1',
      declarations: {
        'font-family': 'var(--font-display)',
        'font-weight': '500',
        'font-size': '28px',
        'max-width': '1400px',
        'margin': '0 auto 12px'
      }
    },
    {
      selector: '.intro',
      declarations: {
        'max-width': '1400px',
        'margin': '0 auto 32px',
        'color': '#666',
        'font-size': '14px',
        'line-height': '1.5'
      }
    },
    {
      selector: '.grid',
      declarations: {
        'display': 'grid',
        'gap': '32px',
        'max-width': '1400px',
        'margin': '0 auto'
      }
    },
    {
      selector: '.variant',
      declarations: {
        'background': '#000',
        'border-radius': '16px',
        'overflow': 'hidden',
        'box-shadow': '0 12px 40px rgba(0,0,0,0.15)'
      }
    },
    {
      selector: '.variant-header',
      declarations: {
        'background': '#fff',
        'padding': '16px 24px',
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'space-between',
        'gap': '16px',
        'border-bottom': '1px solid #eee'
      }
    },
    {
      selector: '.variant-label',
      declarations: {
        'font-family': 'var(--font-mono)',
        'font-size': '11px',
        'letter-spacing': '0.2em',
        'text-transform': 'uppercase',
        'color': 'var(--accent)',
        'font-weight': '600'
      }
    },
    {
      selector: '.variant-title',
      declarations: {
        'font-family': 'var(--font-display)',
        'font-size': '20px',
        'font-weight': '500'
      }
    },
    {
      selector: '.variant-desc',
      declarations: {
        'font-size': '13px',
        'color': '#666',
        'flex': '1',
        'text-align': 'right'
      }
    },
    {
      selector: '.scene',
      declarations: {
        'position': 'relative',
        'aspect-ratio': '16 / 9',
        'background': "url('bg.png') center/cover no-repeat",
        'overflow': 'hidden'
      }
    },
    {
      selector: '.orb',
      declarations: {
        'position': 'absolute',
        'width': '12%',
        'aspect-ratio': '1',
        'left': '42%',
        'top': '55%',
        'transform': 'translate(-50%, -50%)',
        'cursor': 'pointer'
      }
    },
    {
      selector: '.orb img',
      declarations: {
        'width': '100%',
        'height': '100%',
        'object-fit': 'contain'
      }
    },
    {
      selector: '.card-preview',
      declarations: {
        'position': 'absolute',
        'left': '55%',
        'top': '45%',
        'background': 'rgba(255,255,255,0.98)',
        'padding': '16px 20px',
        'border-radius': '12px',
        'box-shadow': '0 8px 24px rgba(0,0,0,0.25)',
        'width': '240px',
        'animation': 'slideIn 0.3s ease-out'
      }
    },
    {
      selector: '.card-preview .badge',
      declarations: {
        'display': 'inline-block',
        'background': 'var(--accent-2)',
        'color': 'white',
        'font-family': 'var(--font-mono)',
        'font-size': '9px',
        'letter-spacing': '0.15em',
        'text-transform': 'uppercase',
        'padding': '3px 8px',
        'border-radius': '3px',
        'margin-bottom': '8px'
      }
    },
    {
      selector: '.card-preview h3',
      declarations: {
        'font-family': 'var(--font-display)',
        'font-size': '18px',
        'font-weight': '500',
        'margin-bottom': '6px',
        'color': 'var(--ink)'
      }
    },
    {
      selector: '.card-preview p',
      declarations: {
        'font-size': '12px',
        'color': '#555',
        'line-height': '1.4'
      }
    },
    {
      selector: '@keyframes slideIn',
      declarations: {
        'from': {
          'opacity': '0',
          'transform': 'translateX(-8px)'
        },
        'to': {
          'opacity': '1',
          'transform': 'translateX(0)'
        }
      },
      isKeyframes: true
    },
    {
      selector: '.tooltip',
      declarations: {
        'position': 'absolute',
        'left': '42%',
        'top': '46%',
        'transform': 'translate(-50%, -100%)',
        'color': 'white',
        'text-shadow': '0 2px 12px rgba(0,0,0,0.8)',
        'font-family': 'var(--font-display)',
        'font-size': '20px',
        'font-weight': '500',
        'white-space': 'nowrap',
        'animation': 'fadeUp 0.3s ease-out'
      }
    },
    {
      selector: '@keyframes fadeUp',
      declarations: {
        'from': {
          'opacity': '0',
          'transform': 'translate(-50%, -80%)'
        },
        'to': {
          'opacity': '1',
          'transform': 'translate(-50%, -100%)'
        }
      },
      isKeyframes: true
    },
    {
      selector: '.full-overlay',
      declarations: {
        'position': 'absolute',
        'inset': '0',
        'background': 'rgba(0,0,0,0.5)',
        'backdrop-filter': 'blur(6px)',
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'animation': 'fadeIn 0.35s ease-out'
      }
    },
    {
      selector: '.full-overlay .panel',
      declarations: {
        'background': 'rgba(255,255,255,0.98)',
        'padding': '32px 40px',
        'border-radius': '20px',
        'max-width': '420px',
        'box-shadow': '0 20px 60px rgba(0,0,0,0.4)',
        'text-align': 'center'
      }
    },
    {
      selector: '.full-overlay .badge',
      declarations: {
        'display': 'inline-block',
        'background': 'var(--accent)',
        'color': 'white',
        'font-family': 'var(--font-mono)',
        'font-size': '10px',
        'letter-spacing': '0.2em',
        'text-transform': 'uppercase',
        'padding': '4px 10px',
        'border-radius': '4px',
        'margin-bottom': '14px'
      }
    },
    {
      selector: '.full-overlay h3',
      declarations: {
        'font-family': 'var(--font-display)',
        'font-size': '28px',
        'font-weight': '500',
        'margin-bottom': '10px',
        'color': 'var(--ink)'
      }
    },
    {
      selector: '.full-overlay p',
      declarations: {
        'font-size': '14px',
        'color': '#555',
        'line-height': '1.5',
        'margin-bottom': '20px'
      }
    },
    {
      selector: '.full-overlay .preview-img',
      declarations: {
        'width': '100%',
        'aspect-ratio': '16/10',
        'background': 'linear-gradient(135deg, #A8542F, #2E7D7B)',
        'border-radius': '8px',
        'margin-bottom': '16px',
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'color': 'white',
        'font-family': 'var(--font-mono)',
        'font-size': '11px',
        'letter-spacing': '0.15em',
        'opacity': '0.9'
      }
    },
    {
      selector: '@keyframes fadeIn',
      declarations: {
        'from': {
          'opacity': '0'
        },
        'to': {
          'opacity': '1'
        }
      },
      isKeyframes: true
    },
    {
      selector: '.instruction',
      declarations: {
        'text-align': 'center',
        'color': '#999',
        'font-size': '12px',
        'margin-top': '16px',
        'font-family': 'var(--font-mono)',
        'letter-spacing': '0.15em',
        'text-transform': 'uppercase'
      }
    },
    {
      selector: '@media (max-width: 900px)',
      declarations: {
        '.card-preview': {
          'width': '180px',
          'padding': '12px 14px'
        },
        '.card-preview h3': {
          'font-size': '15px'
        },
        '.card-preview p': {
          'font-size': '11px'
        },
        '.tooltip': {
          'font-size': '15px'
        },
        '.full-overlay .panel': {
          'padding': '20px 24px',
          'max-width': '300px'
        },
        '.full-overlay h3': {
          'font-size': '20px'
        }
      },
      isMediaQuery: true
    }
  ];

  let cssContent = `/* abstraction-provenance: {"artifact_sha256": "50aebf2d1d10e4ad074a50e2b0bd451a6c86206ca6d2a94a111305552465c90c", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

`;

  rules.forEach(rule => {
    if (rule.isKeyframes) {
      cssContent += `${rule.selector} {\n`;
      for (const [keyframe, properties] of Object.entries(rule.declarations)) {
        cssContent += `  ${keyframe} {\n`;
        for (const [prop, value] of Object.entries(properties)) {
          cssContent += `    ${prop}: ${value};\n`;
        }
        cssContent += `  }\n`;
      }
      cssContent += `}\n\n`;
    } else if (rule.isMediaQuery) {
      cssContent += `${rule.selector} {\n`;
      for (const [selector, properties] of Object.entries(rule.declarations)) {
        cssContent += `  ${selector} {\n`;
        for (const [prop, value] of Object.entries(properties)) {
          cssContent += `    ${prop}: ${value};\n`;
        }
        cssContent += `  }\n`;
      }
      cssContent += `}\n\n`;
    } else {
      cssContent += `${rule.selector} {\n`;
      for (const [prop, value] of Object.entries(rule.declarations)) {
        cssContent += `  ${prop}: ${value};\n`;
      }
      cssContent += `}\n\n`;
    }
  });

  return cssContent;
}

function writeToFile(filePath) {
  const cssContent = generateCSS();
  fs.writeFileSync(filePath, cssContent, 'utf8');
  console.log(`CSS file written to: ${filePath}`);
}

// Wenn das Skript direkt aufgerufen wird
if (require.main === module) {
  const outputPath = process.argv[2] || 'index_8000e9.css';
  writeToFile(outputPath);
}

module.exports = { generateCSS, writeToFile };
