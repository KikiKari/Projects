#!/usr/bin/env node
// globals.css — portiert nach javascript
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function generateCSS() {
  const cssParts = [];
  
  // Add import
  cssParts.push('@import "tailwindcss";');
  cssParts.push('');
  
  // Add :root variables
  cssParts.push(':root {');
  const rootVars = {
    '--bg': '#faf8f4',
    '--surface': '#ffffff',
    '--surface-2': '#f1eee7',
    '--ink': '#1b1a17',
    '--ink-2': '#3c3a34',
    '--muted': '#6e6a61',
    '--line': '#e5e1d8',
    '--line-strong': '#d4cfc3',
    '--accent': '#a8542f',
    '--accent-press': '#8e4526',
    '--accent-tint': '#f1e5dd',
    '--on-accent': '#ffffff',
    '--accent-2': '#2e7d7b',
    '--accent-2-press': '#225e5b',
    '--accent-3': '#c77d2e',
    '--footer-bg': '#191815',
    '--footer-fg': '#efeae0',
    '--footer-muted': '#9a958a',
    '--success': '#2e7d5b',
    '--danger': '#9e3f32',
    '--font-display': '"Iowan Old Style", "Palatino Linotype", Georgia, "Times New Roman", serif',
    '--font-sans': '"Segoe UI", Inter, system-ui, -apple-system, sans-serif',
    '--font-mono': '"Cascadia Code", "SFMono-Regular", Consolas, ui-monospace, monospace',
    '--space-1': '0.25rem',
    '--space-2': '0.5rem',
    '--space-3': '0.75rem',
    '--space-4': '1rem',
    '--space-5': '1.25rem',
    '--space-6': '1.5rem',
    '--space-8': '2rem',
    '--space-10': '2.5rem',
    '--space-12': '3rem',
    '--space-16': '4rem',
    '--space-20': '5rem',
    '--space-24': '6rem',
    '--space-30': '7.5rem',
    '--radius-sm': '0.375rem',
    '--radius-md': '0.625rem',
    '--radius-lg': '1.125rem',
    '--radius-pill': '999px',
    '--shadow-sm': '0 1px 2px rgb(27 26 23 / 6%)',
    '--shadow-md': '0 10px 30px -16px rgb(27 26 23 / 22%)',
    '--shadow-lg': '0 34px 70px -34px rgb(27 26 23 / 32%)',
    '--container': '75rem',
    '--motion-fast': '180ms',
    '--motion-base': '350ms',
    '--motion-slow': '800ms',
    '--ease-out': 'cubic-bezier(0.22, 0.61, 0.36, 1)'
  };
  
  Object.entries(rootVars).forEach(([key, value]) => {
    cssParts.push(`  ${key}: ${value};`);
  });
  cssParts.push('}');
  cssParts.push('');
  
  // Add @theme inline
  cssParts.push('@theme inline {');
  const themeVars = {
    '--color-bg': 'var(--bg)',
    '--color-surface': 'var(--surface)',
    '--color-surface-2': 'var(--surface-2)',
    '--color-ink': 'var(--ink)',
    '--color-ink-2': 'var(--ink-2)',
    '--color-muted': 'var(--muted)',
    '--color-line': 'var(--line)',
    '--color-line-strong': 'var(--line-strong)',
    '--color-accent': 'var(--accent)',
    '--color-accent-2': 'var(--accent-2)',
    '--color-accent-3': 'var(--accent-3)',
    '--font-display': 'var(--font-display)',
    '--font-sans': 'var(--font-sans)',
    '--font-mono': 'var(--font-mono)'
  };
  
  Object.entries(themeVars).forEach(([key, value]) => {
    cssParts.push(`  ${key}: ${value};`);
  });
  cssParts.push('}');
  cssParts.push('');
  
  // Add base styles
  cssParts.push('* { box-sizing: border-box; }');
  cssParts.push('html { scroll-behavior: smooth; }');
  cssParts.push('body {');
  cssParts.push('  margin: 0;');
  cssParts.push('  background: var(--bg);');
  cssParts.push('  color: var(--ink);');
  cssParts.push('  font-family: var(--font-sans);');
  cssParts.push('  line-height: 1.5;');
  cssParts.push('  -webkit-font-smoothing: antialiased;');
  cssParts.push('}');
  cssParts.push('a { color: inherit; }');
  cssParts.push('button, input, textarea { font: inherit; }');
  cssParts.push('::selection { background: var(--accent-tint); color: var(--ink); }');
  cssParts.push('');
  
  // Add utility classes
  cssParts.push('.display {');
  cssParts.push('  font-family: var(--font-display);');
  cssParts.push('  font-weight: 400;');
  cssParts.push('  letter-spacing: -0.022em;');
  cssParts.push('}');
  cssParts.push('.eyebrow {');
  cssParts.push('  font-family: var(--font-mono);');
  cssParts.push('  font-size: 0.75rem;');
  cssParts.push('  letter-spacing: 0.16em;');
  cssParts.push('  text-transform: uppercase;');
  cssParts.push('}');
  cssParts.push('.focus-ring:focus-visible {');
  cssParts.push('  outline: 2px solid var(--accent);');
  cssParts.push('  outline-offset: 4px;');
  cssParts.push('}');
  cssParts.push('.content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }');
  cssParts.push('');
  
  // Add media query
  cssParts.push('@media (prefers-reduced-motion: reduce) {');
  cssParts.push('  html { scroll-behavior: auto; }');
  cssParts.push('  *, *::before, *::after {');
  cssParts.push('    animation-duration: 0.01ms !important;');
  cssParts.push('    animation-iteration-count: 1 !important;');
  cssParts.push('    scroll-behavior: auto !important;');
  cssParts.push('    transition-duration: 0.01ms !important;');
  cssParts.push('  }');
  cssParts.push('}');
  cssParts.push('');
  
  // Add header hiding styles
  cssParts.push('/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */');
  cssParts.push('body[data-hero-immersive="true"] > header,');
  cssParts.push('body[data-hero-immersive="true"] header[data-site-header] {');
  cssParts.push('  opacity: 0;');
  cssParts.push('  pointer-events: none;');
  cssParts.push('  transition: opacity 0.4s ease-out;');
  cssParts.push('}');
  cssParts.push('');
  
  // Add keyframes
  cssParts.push('/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */');
  cssParts.push('@keyframes dropfall {');
  cssParts.push('  0% {');
  cssParts.push('    transform: translateY(0);');
  cssParts.push('    opacity: 0;');
  cssParts.push('  }');
  cssParts.push('  10% {');
  cssParts.push('    opacity: 0.9;');
  cssParts.push('  }');
  cssParts.push('  90% {');
  cssParts.push('    opacity: 0.7;');
  cssParts.push('  }');
  cssParts.push('  100% {');
  cssParts.push('    transform: translateY(110vh);');
  cssParts.push('    opacity: 0;');
  cssParts.push('  }');
  cssParts.push('}');
  
  return cssParts.join('\n');
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Bitte geben Sie einen Dateinamen an.');
    process.exit(1);
  }
  
  const outputPath = args[0];
  const cssContent = generateCSS();
  
  try {
    fs.writeFileSync(outputPath, cssContent);
    console.log(`CSS erfolgreich in ${outputPath} geschrieben.`);
  } catch (error) {
    console.error(`Fehler beim Schreiben der Datei: ${error.message}`);
    process.exit(1);
  }
}

main();
