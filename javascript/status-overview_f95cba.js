#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "356e255cec9410270a9ab4e9c76910441e71bfdf3f97c8df134c378b74562244", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "javascript"}
// status-overview.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Funktion zur Erstellung der CSS-Struktur
function createCSSRules() {
  const rules = [];
  
  // Universelle Regel
  rules.push({
    selector: '*',
    declarations: {
      'box-sizing': 'border-box'
    }
  });
  
  // HTML und Body Regeln
  rules.push({
    selector: 'html,body',
    declarations: {
      'margin': '0',
      'min-height': '100%',
      'background': '#101015',
      'color': '#fff',
      'font': '14px system-ui,sans-serif'
    }
  });
  
  // Body spezifische Regel
  rules.push({
    selector: 'body',
    declarations: {
      'display': 'flex',
      'flex-direction': 'column',
      'height': '100vh'
    }
  });
  
  // Header Regel
  rules.push({
    selector: 'header',
    declarations: {
      'display': 'flex',
      'gap': '1em',
      'align-items': 'baseline',
      'padding': '0 12px'
    }
  });
  
  // H1 Regel
  rules.push({
    selector: 'h1',
    declarations: {
      'font-size': '17px',
      'margin': '8px 0'
    }
  });
  
  // Header P Regel
  rules.push({
    selector: 'header p',
    declarations: {
      'font-size': '12px',
      'color': '#bbb',
      'margin': '0'
    }
  });
  
  // Main Regel
  rules.push({
    selector: 'main',
    declarations: {
      'flex': '1',
      'min-height': '0',
      'display': 'grid',
      'grid-template-columns': 'repeat(3,minmax(0,1fr))',
      'grid-template-rows': 'repeat(3,minmax(0,1fr))',
      'gap': '4px',
      'padding': '0'
    }
  });
  
  // Tile Container Regel
  rules.push({
    selector: '.tile',
    declarations: {
      'min-width': '0',
      'min-height': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'background': '#202026',
      'border': '1px solid #393940'
    }
  });
  
  // Tile H2 Regel
  rules.push({
    selector: '.tile h2',
    declarations: {
      'font-size': '13px',
      'margin': '3px 8px'
    }
  });
  
  // Tile Video Regel
  rules.push({
    selector: '.tile video',
    declarations: {
      'min-height': '0',
      'width': '100%',
      'flex': '1',
      'object-fit': 'contain',
      'background': '#000'
    }
  });
  
  // Tile P Regel
  rules.push({
    selector: '.tile p',
    declarations: {
      'font-size': '11px',
      'margin': '3px 8px',
      'color': '#ddd'
    }
  });
  
  // Grid2 Klassenregeln
  rules.push({
    selector: 'main.grid2',
    declarations: {
      'grid-template-columns': 'repeat(2,minmax(0,1fr))',
      'grid-template-rows': 'repeat(2,minmax(0,1fr))'
    }
  });
  
  // Hidden Tile Regel
  rules.push({
    selector: '.tile[hidden]',
    declarations: {
      'display': 'none'
    }
  });
  
  return rules;
}

// Funktion zur Formatierung der CSS-Regeln
function formatCSS(rules) {
  return rules.map(rule => {
    const declarationString = Object.entries(rule.declarations)
      .map(([property, value]) => `  ${property}:${value}`)
      .join(';');
    
    return `${rule.selector}{${declarationString}}`;
  }).join('');
}

// Hauptfunktion
function generateCSS(outputPath) {
  const rules = createCSSRules();
  const cssContent = formatCSS(rules);
  
  if (outputPath) {
    writeFileSync(outputPath, cssContent, 'utf8');
    console.log(`CSS file generated: ${outputPath}`);
  } else {
    console.log(cssContent);
  }
}

// Parameterverarbeitung
const outputPath = process.argv[2];
generateCSS(outputPath);
