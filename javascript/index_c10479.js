#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "26b7d948888c258a3c3057bb41c82f06a0de1151e29faa2fa13312d80eface5d", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Funktion zum Erstellen des HTML-Dokuments
function createHTMLDocument() {
  // Erstelle das grundlegende HTML-Gerüst
  const docType = '<!doctype html>';
  
  // Erstelle das HTML-Element mit dem lang-Attribut
  const html = {
    tag: 'html',
    attributes: { lang: 'de' },
    children: []
  };
  
  // Erstelle den Head-Bereich
  const head = {
    tag: 'head',
    children: [
      {
        tag: 'meta',
        attributes: { charset: 'UTF-8' }
      },
      {
        tag: 'meta',
        attributes: {
          name: 'viewport',
          content: 'width=device-width, initial-scale=1.0'
        }
      },
      {
        tag: 'meta',
        attributes: {
          name: 'description',
          content: 'Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.'
        }
      },
      {
        tag: 'meta',
        attributes: {
          name: 'theme-color',
          content: '#ffffff'
        }
      },
      {
        tag: 'link',
        attributes: {
          rel: 'icon',
          type: 'image/png',
          href: '/branding/staenderglobus-ios.png'
        }
      },
      {
        tag: 'link',
        attributes: {
          rel: 'apple-touch-icon',
          href: '/branding/staenderglobus-ios.png'
        }
      },
      {
        tag: 'title',
        children: ['TikTok LIVE Companion – Dokumentation']
      }
    ]
  };
  
  // Erstelle den Body-Bereich
  const body = {
    tag: 'body',
    children: [
      {
        tag: 'div',
        attributes: { id: 'root' }
      },
      {
        tag: 'script',
        attributes: {
          type: 'module',
          src: '/src/main.tsx'
        }
      }
    ]
  };
  
  // Füge Head und Body zum HTML-Element hinzu
  html.children.push(head);
  html.children.push(body);
  
  // Funktion zum Rekursive Erstellen von HTML aus dem Objektbaum
  function buildHTMLElement(element) {
    if (typeof element === 'string') {
      return element;
    }
    
    let htmlString = '';
    
    if (element.tag) {
      htmlString += `<${element.tag}`;
      
      // Füge Attribute hinzu
      if (element.attributes) {
        for (const [key, value] of Object.entries(element.attributes)) {
          htmlString += ` ${key}="${value}"`;
        }
      }
      
      // Behandle Selbstschließende Tags
      const selfClosingTags = ['meta', 'link', 'img', 'br', 'hr', 'input'];
      if (selfClosingTags.includes(element.tag)) {
        htmlString += ' />';
      } else {
        htmlString += '>';
        
        // Füge Kind-Elemente hinzu
        if (element.children) {
          for (const child of element.children) {
            htmlString += buildHTMLElement(child);
          }
        }
        
        htmlString += `</${element.tag}>`;
      }
    }
    
    return htmlString;
  }
  
  // Baue das komplette HTML-Dokument
  const htmlContent = docType + buildHTMLElement(html);
  
  return htmlContent;
}

// Hauptfunktion
function main() {
  // Prüfe ob ein Dateiname als Parameter übergeben wurde
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Fehler: Bitte geben Sie einen Dateinamen als Parameter an.');
    process.exit(1);
  }
  
  const fileName = args[0];
  
  try {
    // Erstelle das HTML-Dokument
    const htmlContent = createHTMLDocument();
    
    // Schreibe den Inhalt in die angegebene Datei
    writeFileSync(fileName, htmlContent, 'utf8');
    
    console.log(`HTML-Dokument erfolgreich erstellt und in '${fileName}' gespeichert.`);
  } catch (error) {
    console.error('Fehler beim Erstellen der HTML-Datei:', error.message);
    process.exit(1);
  }
}

// Führe die Hauptfunktion aus
main();
