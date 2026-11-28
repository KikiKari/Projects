#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ef2cc2cf8d7dc7f489688077ed2c78bc9ed125975b2ef7f03344b99ffd6f4bfa", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "javascript"}
// index_81ff5e.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
  const cssRules = [];

  // Root variables
  cssRules.push({
    selector: ':root',
    declarations: [
      'color-scheme: light',
      '--ink: #1b1c1f',
      '--muted: #6c6e75',
      '--faint: #9a9ca3',
      '--card: #fff',
      '--line: #e9eaee',
      '--accent: #5b5bd6',
      '--accent2: #7c5cff',
      '--ok: #22a06b',
      '--err: #e0533d',
      '--radius: 16px',
      '--shadow: 0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06)'
    ]
  });

  // Universal selector
  cssRules.push({
    selector: '*',
    declarations: ['box-sizing: border-box']
  });

  // Body styles
  cssRules.push({
    selector: 'body',
    declarations: [
      'margin: 0',
      'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      'color: var(--ink)',
      'min-height: 100vh',
      'background: radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%), linear-gradient(180deg, #eef1f6, #f7f7f8 42%)',
      'background-attachment: fixed'
    ]
  });

  // Wrap class
  cssRules.push({
    selector: '.wrap',
    declarations: [
      'max-width: 820px',
      'margin: 0 auto',
      'padding: 24px 18px 70px'
    ]
  });

  // Brand class
  cssRules.push({
    selector: '.brand',
    declarations: [
      'display: flex',
      'align-items: center',
      'gap: 12px',
      'margin-bottom: 4px'
    ]
  });

  // Mark class
  cssRules.push({
    selector: '.mark',
    declarations: [
      'width: 32px',
      'height: 32px',
      'border-radius: 9px',
      'background: linear-gradient(135deg, var(--accent), var(--accent2))',
      'box-shadow: 0 4px 12px rgba(91, 91, 214, 0.35)',
      'position: relative',
      'flex: 0 0 auto'
    ]
  });

  // Mark pseudo-element
  cssRules.push({
    selector: '.mark:after',
    declarations: [
      'content: ""',
      'position: absolute',
      'inset: 8px',
      'border-radius: 4px',
      'border: 2px solid rgba(255, 255, 255, 0.92)'
    ]
  });

  // H1 styles
  cssRules.push({
    selector: 'h1',
    declarations: [
      'font-size: 21px',
      'margin: 0',
      'font-weight: 700'
    ]
  });

  // Sub class
  cssRules.push({
    selector: '.sub',
    declarations: [
      'color: var(--muted)',
      'font-size: 13px',
      'margin: 2px 0 16px'
    ]
  });

  // Card class
  cssRules.push({
    selector: '.card',
    declarations: [
      'background: var(--card)',
      'border: 1px solid var(--line)',
      'border-radius: var(--radius)',
      'box-shadow: var(--shadow)',
      'padding: 16px',
      'margin-bottom: 14px'
    ]
  });

  // Card h2 styles
  cssRules.push({
    selector: '.card h2',
    declarations: [
      'font-size: 14px',
      'margin: 0 0 10px'
    ]
  });

  // Label.lab styles
  cssRules.push({
    selector: 'label.lab',
    declarations: [
      'display: block',
      'font-size: 12px',
      'font-weight: 600',
      'color: var(--muted)',
      'margin: 8px 0 3px'
    ]
  });

  // Input and textarea styles
  cssRules.push({
    selector: 'input, textarea',
    declarations: [
      'width: 100%',
      'font-size: 13px',
      'padding: 8px 10px',
      'border: 1px solid var(--line)',
      'border-radius: 9px',
      'font-family: ui-monospace, Menlo, Consolas, monospace',
      'background: #fff'
    ]
  });

  // Textarea specific styles
  cssRules.push({
    selector: 'textarea',
    declarations: [
      'min-height: 90px',
      'white-space: pre',
      'overflow: auto'
    ]
  });

  // Row class
  cssRules.push({
    selector: '.row',
    declarations: [
      'display: flex',
      'gap: 8px',
      'flex-wrap: wrap',
      'align-items: center'
    ]
  });

  // Button styles
  cssRules.push({
    selector: '.btn',
    declarations: [
      'font-size: 13px',
      'font-weight: 600',
      'padding: 8px 14px',
      'border: 1px solid var(--line)',
      'border-radius: 10px',
      'background: #fff',
      'cursor: pointer',
      'box-shadow: var(--shadow)',
      'transition: transform 0.1s'
    ]
  });

  // Button hover state
  cssRules.push({
    selector: '.btn:hover',
    declarations: ['transform: translateY(-1px)']
  });

  // Primary button styles
  cssRules.push({
    selector: '.btn.primary',
    declarations: [
      'background: linear-gradient(135deg, var(--accent), var(--accent2))',
      'color: #fff',
      'border-color: transparent'
    ]
  });

  // Small button styles
  cssRules.push({
    selector: '.btn.sm',
    declarations: [
      'padding: 5px 9px',
      'font-size: 12px'
    ]
  });

  // Message styles
  cssRules.push({
    selector: '.msg',
    declarations: [
      'font-size: 12px',
      'margin-left: 6px'
    ]
  });

  // OK message styles
  cssRules.push({
    selector: '.msg.ok',
    declarations: ['color: var(--ok)']
  });

  // Error message styles
  cssRules.push({
    selector: '.msg.err',
    declarations: ['color: var(--err)']
  });

  // Provenance container styles
  cssRules.push({
    selector: '.prov',
    declarations: [
      'border: 1px solid var(--line)',
      'border-radius: 12px',
      'padding: 10px 12px',
      'margin-bottom: 10px'
    ]
  });

  // Provenance heading styles
  cssRules.push({
    selector: '.prov h3',
    declarations: [
      'margin: 0 0 6px',
      'font-size: 13.5px',
      'display: flex',
      'align-items: center',
      'gap: 8px'
    ]
  });

  // Key-value grid styles
  cssRules.push({
    selector: '.kv',
    declarations: [
      'display: grid',
      'grid-template-columns: 180px 1fr auto',
      'gap: 6px',
      'margin: 4px 0',
      'align-items: center'
    ]
  });

  // Key-value input styles
  cssRules.push({
    selector: '.kv input',
    declarations: [
      'font-size: 12px',
      'padding: 5px 7px'
    ]
  });

  // Key class styles
  cssRules.push({
    selector: '.kv .k',
    declarations: [
      'color: var(--muted)',
      'font-weight: 600'
    ]
  });

  // Muted text styles
  cssRules.push({
    selector: '.muted',
    declarations: [
      'color: var(--faint)',
      'font-size: 13px'
    ]
  });

  // Hidden elements
  cssRules.push({
    selector: '.hide',
    declarations: ['display: none']
  });

  // Footer styles
  cssRules.push({
    selector: '.foot',
    declarations: [
      'color: var(--faint)',
      'font-size: 11.5px',
      'text-align: center',
      'margin-top: 18px',
      'line-height: 1.5'
    ]
  });

  // Link styles
  cssRules.push({
    selector: 'a',
    declarations: ['color: var(--accent)']
  });

  return cssRules;
}

function formatCSS(cssRules) {
  let cssContent = `/* abstraction-provenance: {"artifact_sha256": "6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9", "source_sha256": "81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

`;

  cssRules.forEach(rule => {
    cssContent += `${rule.selector} {\n`;
    rule.declarations.forEach(declaration => {
      cssContent += `  ${declaration};\n`;
    });
    cssContent += '}\n\n';
  });

  return cssContent;
}

function main() {
  const outputFile = process.argv[2] || 'index_81ff5e.css';
  const cssRules = generateCSS();
  const cssContent = formatCSS(cssRules);
  
  fs.writeFileSync(outputFile, cssContent);
  console.log(`CSS file generated: ${outputFile}`);
}

main();
