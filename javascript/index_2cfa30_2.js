#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "227d883f2edfdd074dec1d9f4871b2181eafb92b4ac281790cb7d42634a05a34", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Funktion zum Erstellen des HTML-Dokuments
function createHTMLDocument() {
  // Erstelle das HTML-Dokument
  const docType = '<!doctype html>';
  
  // HTML-Element mit Attributen
  const html = {
    tag: 'html',
    attributes: { lang: 'de' },
    children: []
  };
  
  // Head-Bereich
  const head = {
    tag: 'head',
    children: [
      { tag: 'meta', attributes: { charset: 'UTF-8' } },
      { tag: 'meta', 
        attributes: { 
          name: 'viewport', 
          content: 'width=device-width, initial-scale=1.0' 
        } 
      },
      { tag: 'meta',
        attributes: {
          name: 'description',
          content: 'Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
        }
      },
      { tag: 'meta',
        attributes: {
          name: 'theme-color',
          content: '#ffffff'
        }
      },
      { tag: 'link',
        attributes: {
          rel: 'icon',
          type: 'image/png',
          href: '/branding/staenderglobus-ios.png'
        }
      },
      { tag: 'link',
        attributes: {
          rel: 'apple-touch-icon',
          href: '/branding/staenderglobus-ios.png'
        }
      },
      { tag: 'title',
        children: ['TikTok LIVE Companion – Dokumentation']
      }
    ]
  };
  
  // Body-Bereich
  const body = {
    tag: 'body',
    children: [
      { tag: 'div', attributes: { id: 'root' } },
      { tag: 'script',
        attributes: {
          type: 'module',
          src: '/src/main.tsx'
        }
      }
    ]
  };
  
  // Füge Head und Body zum HTML hinzu
  html.children.push(head, body);
  
  // Render-Funktion für HTML-Elemente
  function renderElement(element) {
    if (typeof element === 'string') {
      return element;
    }
    
    const tag = element.tag;
    const attributes = element.attributes || {};
    const children = element.children || [];
    
    // Attribute als String zusammenbauen
    const attrString = Object.entries(attributes)
      .map(([key, value]) => `${key}="${value}"`)
      .join(' ');
    
    // Kinder rendern
    const childrenString = children.map(renderElement).join('');
    
    // Element zusammenbauen
    if (attrString) {
      return `<${tag} ${attrString}>${childrenString}</${tag}>`;
    } else {
      return `<${tag}>${childrenString}</${tag}>`;
    }
  }
  
  // Gesamtes Dokument rendern
  const htmlString = renderElement(html);
  
  return docType + htmlString;
}

// Hauptfunktion
function main() {
  // Prüfe Kommandozeilenargumente
  const args = process.argv.slice(2);
  
  if (args.length !== 1) {
    console.error('Verwendung: node script.js <ausgabedatei>');
    process.exit(1);
  }
  
  const outputFile = args[0];
  
  try {
    // Erstelle das HTML-Dokument
    const htmlContent = createHTMLDocument();
    
    // Schreibe in Datei
    writeFileSync(outputFile, htmlContent, 'utf8');
    
    console.log(`HTML-Dokument erfolgreich erstellt: ${outputFile}`);
  } catch (error) {
    console.error('Fehler beim Erstellen des HTML-Dokuments:', error.message);
    process.exit(1);
  }
}

// Skript ausführen
main();
