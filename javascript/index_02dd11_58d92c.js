#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "49cc1f2bc5105fac50b7a1b3a600cf28fe5334862815f9fb1fe678257c430565", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "javascript"}
// index_02dd11.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/index_02dd11.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';

class CSSBuilder {
  constructor() {
    this.rules = [];
    this.variables = new Map();
  }

  addVariable(name, value) {
    this.variables.set(name, value);
    return this;
  }

  addRule(selector, properties) {
    this.rules.push({ selector, properties });
    return this;
  }

  addMediaQuery(query, rules) {
    this.rules.push({ media: query, rules });
    return this;
  }

  build() {
    let output = '/* abstraction-provenance: {"artifact_sha256": "8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402", "source_sha256": "02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb", "target_language": "css"} */\n';
    output += '/* index.html — portiert nach css */\n';
    output += '/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */\n';
    output += '/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n';

    if (this.variables.size > 0) {
      output += ':root {\n';
      for (const [name, value] of this.variables) {
        output += `  ${name}: ${value};\n`;
      }
      output += '}\n\n';
    }

    for (const rule of this.rules) {
      if (rule.media) {
        output += `@media ${rule.media} {\n`;
        for (const subRule of rule.rules) {
          output += `${subRule.selector} {\n`;
          for (const [prop, value] of Object.entries(subRule.properties)) {
            output += `  ${prop.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value};\n`;
          }
          output += '}\n\n';
        }
        output += '}\n\n';
      } else {
        output += `${rule.selector} {\n`;
        for (const [prop, value] of Object.entries(rule.properties)) {
          output += `  ${prop.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value};\n`;
        }
        output += '}\n\n';
      }
    }

    return output;
  }
}

function generateCSS() {
  const builder = new CSSBuilder();

  // Root variables
  builder
    .addVariable('--bg-dark', '#0a0f1e')
    .addVariable('--bg-card', '#121826')
    .addVariable('--bg-panel', '#1a2236')
    .addVariable('--border', '#25324d')
    .addVariable('--text-main', '#e6ecf5')
    .addVariable('--text-muted', '#a0b0cc')
    .addVariable('--text-dim', '#6c7a96')
    .addVariable('--accent', '#5d8aff')
    .addVariable('--accent-hover', '#7a9fff')
    .addVariable('--accent-warn', '#fbd38d')
    .addVariable('--layer-0', '#ff7eb9')
    .addVariable('--layer-1', '#4fd1c5')
    .addVariable('--layer-2', '#ffd166')
    .addVariable('--layer-3-gpt', '#6a5acd')
    .addVariable('--layer-3-gemini', '#4285f4')
    .addVariable('--layer-3-claude', '#f4a261');

  // Base styles
  builder
    .addRule('*', {
      boxSizing: 'border-box',
      margin: '0',
      padding: '0'
    })
    .addRule('body', {
      fontFamily: "'Inter', sans-serif",
      background: 'var(--bg-dark)',
      color: 'var(--text-main)',
      lineHeight: '1.5',
      overflow: 'hidden',
      height: '100vh',
      display: 'flex',
      flexDirection: 'column'
    });

  // Header
  builder
    .addRule('#app-header', {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '12px 20px',
      background: 'rgba(10, 15, 30, 0.8)',
      backdropFilter: 'blur(10px)',
      border: '1px solid var(--border)',
      position: 'relative',
      zIndex: '10'
    })
    .addRule('.header-brand', {
      display: 'flex',
      alignItems: 'center',
      gap: '10px'
    })
    .addRule('.header-brand h1', {
      fontSize: '18px',
      fontWeight: '600',
      color: 'var(--text-main)'
    })
    .addRule('.layer-indicator', {
      display: 'flex',
      alignItems: 'center',
      gap: '4px'
    })
    .addRule('.layer-dot', {
      width: '8px',
      height: '8px',
      borderRadius: '50%',
      opacity: '0.4'
    })
    .addRule('.layer-dot.active', {
      opacity: '1',
      boxShadow: '0 0 6px currentColor'
    })
    .addRule('.header-controls', {
      display: 'flex',
      gap: '8px'
    });

  // Main area
  builder
    .addRule('#board', {
      display: 'flex',
      flex: '1',
      overflow: 'hidden',
      padding: '16px',
      gap: '16px'
    });

  // Camera panel
  builder
    .addRule('#camera-panel', {
      flex: '1',
      display: 'flex',
      flexDirection: 'column',
      background: 'var(--bg-card)',
      borderRadius: '16px',
      border: '1px solid var(--border)',
      overflow: 'hidden',
      minWidth: '320px'
    })
    .addRule('.panel-header', {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: '12px 16px',
      border: '1px solid var(--border)'
    })
    .addRule('.panel-title', {
      fontSize: '12px',
      fontWeight: '600',
      textTransform: 'uppercase',
      letterSpacing: '0.5px',
      color: 'var(--text-muted)'
    })
    .addRule('.badge', {
      fontSize: '10px',
      padding: '2px 6px',
      borderRadius: '4px',
      background: 'rgba(106, 90, 205, 0.15)',
      color: 'var(--layer-3-gpt)',
      border: '1px solid rgba(106, 90, 205, 0.3)'
    })
    .addRule('.badge-idle', {
      background: 'rgba(106, 205, 172, 0.15)',
      color: '#6acda5',
      border: '1px solid rgba(106, 205, 172, 0.3)'
    })
    .addRule('#camera-viewport', {
      position: 'relative',
      flex: '1',
      background: '#000',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    })
    .addRule('#video, #canvas-overlay, #snap-canvas, #filtered-canvas', {
      position: 'absolute',
      top: '0',
      left: '0',
      width: '100%',
      height: '100%',
      objectFit: 'contain'
    })
    .addRule('#canvas-overlay', {
      pointerEvents: 'none',
      zIndex: '2'
    })
    .addRule('#start-overlay', {
      position: 'absolute',
      inset: '0',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '16px',
      background: 'rgba(10, 15, 30, 0.8)',
      zIndex: '5'
    })
    .addRule('#pixel-loupe', {
      position: 'absolute',
      bottom: '20px',
      right: '20px',
      background: 'rgba(0, 0, 0, 0.7)',
      borderRadius: '8px',
      padding: '8px',
      display: 'none',
      flexDirection: 'column',
      alignItems: 'center',
      gap: '6px',
      zIndex: '3'
    })
    .addRule('#loupe-canvas', {
      width: '80px',
      height: '80px',
      imageRendering: 'pixelated',
      border: '1px solid rgba(255, 255, 255, 0.1)'
    })
    .addRule('#loupe-info', {
      fontSize: '10px',
      color: 'var(--text-dim)'
    })
    .addRule('#camera-controls', {
      display: 'flex',
      alignItems: 'center',
      padding: '12px 16px',
      gap: '12px',
      borderTop: '1px solid var(--border)'
    })
    .addRule('select', {
      background: 'var(--bg-panel)',
      color: 'var(--text-main)',
      border: '1px solid var(--border)',
      borderRadius: '6px',
      padding: '6px 10px',
      fontSize: '12px'
    });

  // Right panel
  builder
    .addRule('#right-panel', {
      width: '320px',
      display: 'flex',
      flexDirection: 'column',
      gap: '16px'
    })
    .addRule('.card', {
      background: 'var(--bg-card)',
      borderRadius: '16px',
      border: '1px solid var(--border)',
      overflow: 'hidden',
      display: 'flex',
      flexDirection: 'column'
    })
    .addRule('.card-body', {
      padding: '16px',
      flex: '1'
    })
    .addRule('.slider-row', {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      marginBottom: '12px'
    })
    .addRule('.slider-label', {
      fontSize: '12px',
      width: '100px',
      color: 'var(--text-muted)'
    })
    .addRule('input[type="range"]', {
      flex: '1',
      height: '4px',
      WebkitAppearance: 'none',
      background: 'var(--bg-panel)',
      borderRadius: '2px',
      outline: 'none'
    })
    .addRule('input[type="range"]::-webkit-slider-thumb', {
      WebkitAppearance: 'none',
      width: '16px',
      height: '16px',
      borderRadius: '50%',
      background: 'var(--accent)',
      cursor: 'pointer'
    })
    .addRule('.slider-value', {
      fontSize: '12px',
      width: '40px',
      textAlign: 'right',
      color: 'var(--text-muted)'
    });

  // Tabs
  builder
    .addRule('.tab-bar', {
      display: 'flex',
      borderBottom: '1px solid var(--border)'
    })
    .addRule('.tab', {
      flex: '1',
      padding: '10px 12px',
      fontSize: '12px',
      background: 'transparent',
      border: 'none',
      color: 'var(--text-dim)',
      cursor: 'pointer',
      textAlign: 'center'
    })
    .addRule('.tab.active', {
      color: 'var(--text-main)',
      borderBottom: '2px solid var(--accent)',
      background: 'rgba(93, 138, 255, 0.05)'
    })
    .addRule('.tab-content', {
      display: 'none'
    })
    .addRule('.tab-content.active', {
      display: 'block'
    });

  // Status bar
  builder
    .addRule('#status-bar', {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      padding: '8px 20px',
      background: 'rgba(10, 15, 30, 0.6)',
      borderTop: '1px solid var(--border)',
      fontSize: '12px',
      color: 'var(--text-dim)'
    })
    .addRule('.status-dot', {
      width: '8px',
      height: '8px',
      borderRadius: '50%',
      background: '#6acda5'
    })
    .addRule('.status-dot.loading', {
      background: '#fbd38d',
      animation: 'pulse 1.5s infinite'
    })
    .addRule('@keyframes pulse', {
      '0%': { opacity: '0.4' },
      '50%': { opacity: '1' },
      '100%': { opacity: '0.4' }
    });

  // Buttons
  builder
    .addRule('.btn', {
      display: 'inline-flex',
      alignItems: 'center',
      gap: '6px',
      padding: '8px 12px',
      borderRadius: '8px',
      border: '1px solid var(--border)',
      background: 'var(--bg-panel)',
      color: 'var(--text-main)',
      fontSize: '12px',
      fontWeight: '500',
      cursor: 'pointer',
      transition: 'all 0.2s ease'
    })
    .addRule('.btn:hover', {
      background: 'rgba(93, 138, 255, 0.1)',
      borderColor: 'var(--accent)'
    })
    .addRule('.btn:disabled', {
      opacity: '0.5',
      cursor: 'not-allowed'
    })
    .addRule('.btn-primary', {
      background: 'var(--accent)',
      borderColor: 'var(--accent)',
      color: 'white'
    })
    .addRule('.btn-primary:hover:not(:disabled)', {
      background: 'var(--accent-hover)',
      borderColor: 'var(--accent-hover)'
    })
    .addRule('.btn-icon', {
      padding: '8px'
    })
    .addRule('.btn-snap', {
      background: 'linear-gradient(135deg, #ff7eb9, #ff758c)',
      border: '1px solid #ff7eb9',
      color: 'white'
    })
    .addRule('.btn-sm', {
      padding: '4px 8px',
      fontSize: '11px'
    });

  // Spinner
  builder
    .addRule('.spinner', {
      width: '16px',
      height: '16px',
      border: '2px solid rgba(255, 255, 255, 0.2)',
      borderLeftColor: 'var(--accent)',
      borderRadius: '50%',
      animation: 'spin 1s linear infinite'
    })
    .addRule('@keyframes spin', {
      to: { transform: 'rotate(360deg)' }
    });

  // Settings modal
  builder
    .addRule('#settings-modal', {
      position: 'fixed',
      inset: '0',
      background: 'rgba(0, 0, 0, 0.7)',
      display: 'none',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: '1000'
    })
    .addRule('.modal-box', {
      background: 'var(--bg-card)',
      borderRadius: '16px',
      border: '1px solid var(--border)',
      padding: '20px',
      maxHeight: '90vh',
      overflowY: 'auto'
    })
    .addRule('.modal-title', {
      fontSize: '18px',
      fontWeight: '600',
      marginBottom: '20px',
      color: 'var(--text-main)'
    })
    .addRule('.settings-section', {
      marginBottom: '24px'
    })
    .addRule('.settings-section-title', {
      fontSize: '14px',
      fontWeight: '600',
      marginBottom: '12px'
    })
    .addRule('.settings-label', {
      display: 'block',
      fontSize: '12px',
      marginBottom: '6px',
      color: 'var(--text-muted)'
    })
    .addRule('.settings-input', {
      width: '100%',
      padding: '10px 12px',
      borderRadius: '8px',
      border: '1px solid var(--border)',
      background: 'var(--bg-panel)',
      color: 'var(--text-main)',
      fontSize: '12px',
      marginBottom: '4px'
    })
    .addRule('.settings-hint', {
      fontSize: '11px',
      color: 'var(--text-dim)',
      marginTop: '4px'
    })
    .addRule('.toggle-switch', {
      position: 'relative',
      display: 'inline-block',
      width: '40px',
      height: '20px'
    })
    .addRule('.toggle-switch input', {
      opacity: '0',
      width: '0',
      height: '0'
    })
    .addRule('.toggle-track', {
      position: 'absolute',
      cursor: 'pointer',
      top: '0',
      left: '0',
      right: '0',
      bottom: '0',
      background: 'var(--bg-panel)',
      border: '1px solid var(--border)',
      borderRadius: '20px',
      transition: '.3s'
    })
    .addRule('.toggle-thumb', {
      position: 'absolute',
      content: '""',
      height: '14px',
      width: '14px',
      left: '3px',
      bottom: '2px',
      background: 'var(--text-dim)',
      borderRadius: '50%',
      transition: '.3s'
    })
    .addRule('input:checked + .toggle-track', {
      background: 'var(--accent)',
      borderColor: 'var(--accent)'
    })
    .addRule('input:checked + .toggle-track .toggle-thumb', {
      background: 'white',
      transform: 'translateX(20px)'
    });

  // Pixel inspector
  builder
    .addRule('.pixel-swatch', {
      width: '24px',
      height: '24px',
      borderRadius: '4px',
      border: '1px solid var(--border)'
    })
    .addRule('.pixel-values', {
      display: 'flex',
      flexDirection: 'column',
      fontSize: '11px',
      color: 'var(--text-dim)',
      gap: '2px'
    });

  // Upload zone
  builder
    .addRule('#upload-zone', {
      position: 'fixed',
      inset: '0',
      background: 'rgba(0, 0, 0, 0.8)',
      display: 'none',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--text-main)',
      fontSize: '16px',
      zIndex: '100'
    });

  // Responsive
  builder.addMediaQuery('(max-width: 768px)', [
    { selector: '#board', properties: { flexDirection: 'column' } },
    { selector: '#right-panel', properties: { width: '100%' } },
    { selector: '#camera-panel', properties: { minWidth: 'unset' } }
  ]);

  return builder.build();
}

// Main execution
if (process.argv.length < 3) {
  console.error('Usage: node script.js <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];
const cssContent = generateCSS();

try {
  fs.writeFileSync(outputFile, cssContent, 'utf8');
  console.log(`CSS file generated successfully: ${outputFile}`);
} catch (error) {
  console.error(`Error writing file: ${error.message}`);
  process.exit(1);
}
