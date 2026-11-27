#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "eafa4e0f266af7233d2e44a7c5c6a9f58bdb58625a6a33e795f8aa0183cb4bfe", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createHTMLDocument() {
  const docType = '<!DOCTYPE html>';
  
  // Create root element
  const html = {
    tag: 'html',
    attrs: { lang: 'de' },
    children: []
  };
  
  // Build head section
  const head = {
    tag: 'head',
    children: [
      { tag: 'meta', attrs: { charset: 'UTF-8' } },
      { tag: 'title', children: ['Hover-Preview Varianten · Vergleich'] },
      { 
        tag: 'style',
        children: [`
  :root {
    --bg: #FAF8F4;
    --ink: #1B1A17;
    --accent: #A8542F;
    --accent-2: #2E7D7B;
    --font-display: 'Newsreader', Georgia, serif;
    --font-body: 'Hanken Grotesk', -apple-system, sans-serif;
    --font-mono: 'JetBrains Mono', monospace;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: var(--font-body);
    background: var(--bg);
    color: var(--ink);
    padding: 32px 16px 80px;
  }
  h1 {
    font-family: var(--font-display);
    font-weight: 500;
    font-size: 28px;
    max-width: 1400px;
    margin: 0 auto 12px;
  }
  .intro {
    max-width: 1400px;
    margin: 0 auto 32px;
    color: #666;
    font-size: 14px;
    line-height: 1.5;
  }
  .grid {
    display: grid;
    gap: 32px;
    max-width: 1400px;
    margin: 0 auto;
  }
  .variant {
    background: #000;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 12px 40px rgba(0,0,0,0.15);
  }
  .variant-header {
    background: #fff;
    padding: 16px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    border-bottom: 1px solid #eee;
  }
  .variant-label {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    color: var(--accent);
    font-weight: 600;
  }
  .variant-title {
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 500;
  }
  .variant-desc {
    font-size: 13px;
    color: #666;
    flex: 1;
    text-align: right;
  }
  .scene {
    position: relative;
    aspect-ratio: 16 / 9;
    background: url('bg.png') center/cover no-repeat;
    overflow: hidden;
  }
  .orb {
    position: absolute;
    width: 12%;
    aspect-ratio: 1;
    left: 42%;
    top: 55%;
    transform: translate(-50%, -50%);
    cursor: pointer;
  }
  .orb img { width: 100%; height: 100%; object-fit: contain; }

  /* Variante 1: Karte daneben */
  .card-preview {
    position: absolute;
    left: 55%;
    top: 45%;
    background: rgba(255,255,255,0.98);
    padding: 16px 20px;
    border-radius: 12px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.25);
    width: 240px;
    animation: slideIn 0.3s ease-out;
  }
  .card-preview .badge {
    display: inline-block;
    background: var(--accent-2);
    color: white;
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 3px 8px;
    border-radius: 3px;
    margin-bottom: 8px;
  }
  .card-preview h3 {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 500;
    margin-bottom: 6px;
    color: var(--ink);
  }
  .card-preview p {
    font-size: 12px;
    color: #555;
    line-height: 1.4;
  }
  @keyframes slideIn {
    from { opacity: 0; transform: translateX(-8px); }
    to { opacity: 1; transform: translateX(0); }
  }

  /* Variante 2: Minimaler Tooltip */
  .tooltip {
    position: absolute;
    left: 42%;
    top: 46%;
    transform: translate(-50%, -100%);
    color: white;
    text-shadow: 0 2px 12px rgba(0,0,0,0.8);
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 500;
    white-space: nowrap;
    animation: fadeUp 0.3s ease-out;
  }
  @keyframes fadeUp {
    from { opacity: 0; transform: translate(-50%, -80%); }
    to { opacity: 1; transform: translate(-50%, -100%); }
  }

  /* Variante 3: Vollflächiges Overlay */
  .full-overlay {
    position: absolute;
    inset: 0;
    background: rgba(0,0,0,0.5);
    backdrop-filter: blur(6px);
    display: flex;
    align-items: center;
    justify-content: center;
    animation: fadeIn 0.35s ease-out;
  }
  .full-overlay .panel {
    background: rgba(255,255,255,0.98);
    padding: 32px 40px;
    border-radius: 20px;
    max-width: 420px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.4);
    text-align: center;
  }
  .full-overlay .badge {
    display: inline-block;
    background: var(--accent);
    color: white;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    padding: 4px 10px;
    border-radius: 4px;
    margin-bottom: 14px;
  }
  .full-overlay h3 {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 500;
    margin-bottom: 10px;
    color: var(--ink);
  }
  .full-overlay p {
    font-size: 14px;
    color: #555;
    line-height: 1.5;
    margin-bottom: 20px;
  }
  .full-overlay .preview-img {
    width: 100%;
    aspect-ratio: 16/10;
    background: linear-gradient(135deg, #A8542F, #2E7D7B);
    border-radius: 8px;
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.15em;
    opacity: 0.9;
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  .instruction {
    text-align: center;
    color: #999;
    font-size: 12px;
    margin-top: 16px;
    font-family: var(--font-mono);
    letter-spacing: 0.15em;
    text-transform: uppercase;
  }

  @media (max-width: 900px) {
    .card-preview { width: 180px; padding: 12px 14px; }
    .card-preview h3 { font-size: 15px; }
    .card-preview p { font-size: 11px; }
    .tooltip { font-size: 15px; }
    .full-overlay .panel { padding: 20px 24px; max-width: 300px; }
    .full-overlay h3 { font-size: 20px; }
  }
`]
      },
      { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.googleapis.com' } },
      { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' } },
      { 
        tag: 'link',
        attrs: {
          href: 'https://fonts.googleapis.com/css2?family=Newsreader:wght@400;500&family=Hanken+Grotesk:wght@400;500&family=JetBrains+Mono:wght@400;500&display=swap',
          rel: 'stylesheet'
        }
      }
    ]
  };
  
  // Build body section
  const body = {
    tag: 'body',
    children: [
      { tag: 'h1', children: ['Hover-Preview · drei Varianten im Vergleich'] },
      {
        tag: 'p',
        attrs: { class: 'intro' },
        children: [
          'Gleiche Szene, gleiche Kugel-Position (Beispiel: Projekt-Kugel "Weather-Check").',
          { tag: 'br' },
          'Alle drei Varianten zeigen den Zustand ',
          { tag: 'em', children: ['bei Maushover'] },
          '. Welche soll ins Projekt?'
        ]
      },
      {
        tag: 'div',
        attrs: { class: 'grid' },
        children: [
          // Variante 1
          {
            tag: 'div',
            attrs: { class: 'variant' },
            children: [
              {
                tag: 'div',
                attrs: { class: 'variant-header' },
                children: [
                  {
                    tag: 'div',
                    children: [
                      {
                        tag: 'div',
                        attrs: { class: 'variant-label' },
                        children: ['Variante 1']
                      },
                      {
                        tag: 'div',
                        attrs: { class: 'variant-title' },
                        children: ['Karte daneben']
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'variant-desc' },
                    children: ['Kompakte Card rechts der Kugel · Titel + Badge + kurze Beschreibung aus content.ts · dezent, nicht störend']
                  }
                ]
              },
              {
                tag: 'div',
                attrs: { class: 'scene' },
                children: [
                  {
                    tag: 'div',
                    attrs: { class: 'orb' },
                    children: [
                      {
                        tag: 'img',
                        attrs: { src: 'orb-01-teal.png', alt: '' }
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'card-preview' },
                    children: [
                      {
                        tag: 'span',
                        attrs: { class: 'badge' },
                        children: ['GitHub · Public']
                      },
                      {
                        tag: 'h3',
                        children: ['Weather-Check']
                      },
                      {
                        tag: 'p',
                        children: ['Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.']
                      }
                    ]
                  }
                ]
              }
            ]
          },
          // Variante 2
          {
            tag: 'div',
            attrs: { class: 'variant' },
            children: [
              {
                tag: 'div',
                attrs: { class: 'variant-header' },
                children: [
                  {
                    tag: 'div',
                    children: [
                      {
                        tag: 'div',
                        attrs: { class: 'variant-label' },
                        children: ['Variante 2']
                      },
                      {
                        tag: 'div',
                        attrs: { class: 'variant-title' },
                        children: ['Minimaler Tooltip']
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'variant-desc' },
                    children: ['Nur der Titel schwebt über der Kugel · maximal reduziert · schnell erfassbar · lässt die Bildwirkung ungestört']
                  }
                ]
              },
              {
                tag: 'div',
                attrs: { class: 'scene' },
                children: [
                  {
                    tag: 'div',
                    attrs: { class: 'orb' },
                    children: [
                      {
                        tag: 'img',
                        attrs: { src: 'orb-01-teal.png', alt: '' }
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'tooltip' },
                    children: ['Weather-Check']
                  }
                ]
              }
            ]
          },
          // Variante 3
          {
            tag: 'div',
            attrs: { class: 'variant' },
            children: [
              {
                tag: 'div',
                attrs: { class: 'variant-header' },
                children: [
                  {
                    tag: 'div',
                    children: [
                      {
                        tag: 'div',
                        attrs: { class: 'variant-label' },
                        children: ['Variante 3']
                      },
                      {
                        tag: 'div',
                        attrs: { class: 'variant-title' },
                        children: ['Vollflächiges Overlay']
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'variant-desc' },
                    children: ['Zentrales Modal mit Preview-Bild + Titel + Beschreibung · prominent · lädt zum Klicken ein · verdeckt aber Szene']
                  }
                ]
              },
              {
                tag: 'div',
                attrs: { class: 'scene' },
                children: [
                  {
                    tag: 'div',
                    attrs: { class: 'orb' },
                    children: [
                      {
                        tag: 'img',
                        attrs: { src: 'orb-01-teal.png', alt: '' }
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'full-overlay' },
                    children: [
                      {
                        tag: 'div',
                        attrs: { class: 'panel' },
                        children: [
                          {
                            tag: 'div',
                            attrs: { class: 'preview-img' },
                            children: ['PROJEKT-PREVIEW']
                          },
                          {
                            tag: 'span',
                            attrs: { class: 'badge' },
                            children: ['GitHub · Public']
                          },
                          {
                            tag: 'h3',
                            children: ['Weather-Check']
                          },
                          {
                            tag: 'p',
                            children: ['Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen.']
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        tag: 'p',
        attrs: { class: 'instruction' },
        children: ['Sag mir welche Variante — dann baue ich sie ins Frontend ein.']
      }
    ]
  };
  
  html.children.push(head, body);
  
  return { docType, html };
}

function renderElement(element) {
  if (typeof element === 'string') {
    return element.replace(/&/g, '&amp;')
                 .replace(/</g, '&lt;')
                 .replace(/>/g, '&gt;')
                 .replace(/"/g, '&quot;')
                 .replace(/'/g, '&#039;');
  }
  
  if (element === null || element === undefined) return '';
  
  if (!element.tag) {
    throw new Error('Element must have a tag property');
  }
  
  let html = `<${element.tag}`;
  
  if (element.attrs) {
    for (const [key, value] of Object.entries(element.attrs)) {
      html += ` ${key}="${String(value).replace(/"/g, '&quot;')}"`;
    }
  }
  
  if (element.children === undefined || element.children === null) {
    html += '>';
  } else if (Array.isArray(element.children) && element.children.length === 0) {
    html += '>';
  } else {
    html += '>';
    
    if (Array.isArray(element.children)) {
      for (const child of element.children) {
        html += renderElement(child);
      }
    } else {
      html += renderElement(element.children);
    }
    
    html += `</${element.tag}>`;
  }
  
  return html;
}

function generateHTML() {
  const { docType, html } = createHTMLDocument();
  return docType + '\n' + renderElement(html);
}

// Main execution
if (process.argv.length < 3) {
  console.error('Usage: node script.js <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];
const htmlContent = generateHTML();

try {
  writeFileSync(outputFile, htmlContent, 'utf8');
  console.log(`HTML file generated successfully: ${outputFile}`);
} catch (error) {
  console.error('Error writing file:', error.message);
  process.exit(1);
}
