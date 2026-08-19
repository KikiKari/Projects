#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';

function createHtmlDocument() {
  // Create document
  const docType = '<!DOCTYPE html>';
  const html = {
    tag: 'html',
    attributes: { lang: 'de' },
    children: []
  };

  // Create head section
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
          content: 'Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.' 
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

  // Create body section
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

  html.children.push(head);
  html.children.push(body);

  return { docType, html };
}

function renderElement(element, indent = '') {
  if (typeof element === 'string') {
    return indent + element;
  }

  if (!element.tag) {
    return '';
  }

  const tagName = element.tag;
  const attributes = element.attributes || {};
  const children = element.children || [];

  // Build opening tag
  let attrString = '';
  for (const [key, value] of Object.entries(attributes)) {
    attrString += ` ${key}="${value}"`;
  }

  // Self-closing tags
  const selfClosingTags = ['meta', 'link', 'img', 'input', 'br', 'hr'];
  if (selfClosingTags.includes(tagName)) {
    return `${indent}<${tagName}${attrString} />`;
  }

  // Regular tags with content
  let result = `${indent}<${tagName}${attrString}>`;
  
  if (children.length > 0) {
    const nextIndent = indent + '  ';
    const childContent = children.map(child => renderElement(child, nextIndent)).join('\n');
    if (childContent.includes('\n')) {
      result += '\n' + childContent + '\n' + indent;
    } else {
      result += childContent;
    }
  }
  
  result += `</${tagName}>`;
  return result;
}

function generateHtml({ docType, html }) {
  const htmlContent = renderElement(html);
  return `${docType}\n${htmlContent}\n`;
}

// Main execution
function main() {
  const outputPath = process.argv[2];
  
  if (!outputPath) {
    console.error('Bitte geben Sie einen Ausgabepfad an.');
    process.exit(1);
  }

  try {
    const htmlStructure = createHtmlDocument();
    const htmlContent = generateHtml(htmlStructure);
    
    // Ensure directory exists
    const outputDir = path.dirname(outputPath);
    if (outputDir !== '.') {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    
    fs.writeFileSync(outputPath, htmlContent, 'utf8');
    console.log(`HTML-Dokument erfolgreich erstellt: ${outputPath}`);
  } catch (error) {
    console.error('Fehler beim Erstellen des HTML-Dokuments:', error.message);
    process.exit(1);
  }
}

main();
