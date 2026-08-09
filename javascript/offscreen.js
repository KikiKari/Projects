#!/usr/bin/env node
// offscreen.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
// auch in: 2 weiteren Fundstellen
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function createOffscreenHTML() {
  // Create document structure
  const docType = '<!doctype html>\n';
  
  // Create html element with lang attribute
  const html = {
    tag: 'html',
    attributes: { lang: 'de' },
    children: []
  };
  
  // Create head element
  const head = {
    tag: 'head',
    children: [
      {
        tag: 'meta',
        attributes: { charset: 'utf-8' },
        children: []
      },
      {
        tag: 'title',
        children: ['TikTok LIVE Companion Sprachausgabe']
      }
    ]
  };
  
  // Create body element
  const body = {
    tag: 'body',
    children: [
      {
        tag: 'script',
        attributes: { src: 'offscreen.js' },
        children: []
      }
    ]
  };
  
  // Assemble the complete document structure
  html.children.push(head, body);
  
  // Convert structure to HTML string
  function renderElement(element) {
    if (typeof element === 'string') {
      return element;
    }
    
    const tag = element.tag;
    const attributes = element.attributes || {};
    const children = element.children || [];
    
    let htmlString = `<${tag}`;
    
    // Add attributes
    for (const [key, value] of Object.entries(attributes)) {
      htmlString += ` ${key}="${value}"`;
    }
    
    if (children.length === 0) {
      htmlString += '></' + tag + '>';
    } else {
      htmlString += '>';
      for (const child of children) {
        htmlString += renderElement(child);
      }
      htmlString += '</' + tag + '>';
    }
    
    return htmlString;
  }
  
  // Generate the complete HTML document
  const htmlContent = docType + renderElement(html) + '\n';
  
  return htmlContent;
}

// Main execution
if (process.argv.length < 3) {
  console.error('Usage: node ' + process.argv[1] + ' <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];
const htmlContent = createOffscreenHTML();

try {
  writeFileSync(outputFile, htmlContent);
  console.log('Successfully wrote offscreen.html to ' + outputFile);
} catch (error) {
  console.error('Error writing file:', error.message);
  process.exit(1);
}
