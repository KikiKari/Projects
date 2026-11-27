#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "84e6e5cc707507479e57ec0e528dfb5716b8443087433c73d4adceba5cb2519b", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "javascript"}
// offscreen.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createOffscreenHTML() {
  // Create document type declaration
  const doctype = '<!doctype html>';
  
  // Create html element with language attribute
  const html = {
    tagName: 'html',
    attributes: { lang: 'de' },
    children: []
  };
  
  // Create head section
  const head = {
    tagName: 'head',
    children: [
      {
        tagName: 'meta',
        attributes: { charset: 'utf-8' }
      },
      {
        tagName: 'title',
        children: ['TikTok LIVE Companion Sprachausgabe']
      }
    ]
  };
  
  // Create body section
  const body = {
    tagName: 'body',
    children: [
      {
        tagName: 'script',
        attributes: { src: 'offscreen.js' }
      }
    ]
  };
  
  // Assemble the complete structure
  html.children.push(head, body);
  
  // Render to HTML string
  let htmlString = doctype + '\n';
  htmlString += renderElement(html, 0);
  
  return htmlString;
}

function renderElement(element, indentLevel) {
  const indent = '  '.repeat(indentLevel);
  let result = '';
  
  if (element.tagName) {
    // Start tag with attributes
    let attrs = '';
    if (element.attributes) {
      for (const [key, value] of Object.entries(element.attributes)) {
        attrs += ` ${key}="${value}"`;
      }
    }
    
    // Self-closing tag or regular tag
    if (!element.children || element.children.length === 0) {
      result += `${indent}<${element.tagName}${attrs}>`;
      if (element.tagName !== 'meta') {
        result += `</${element.tagName}>`;
      }
      result += '\n';
    } else {
      // Opening tag
      result += `${indent}<${element.tagName}${attrs}>\n`;
      
      // Children
      if (typeof element.children[0] === 'string') {
        // Text content
        result += `${indent}  ${element.children[0]}\n`;
      } else {
        // Child elements
        for (const child of element.children) {
          result += renderElement(child, indentLevel + 1);
        }
      }
      
      // Closing tag
      result += `${indent}</${element.tagName}>\n`;
    }
  }
  
  return result;
}

// Main execution
if (require.main === module) {
  const outputPath = process.argv[2];
  
  if (!outputPath) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  try {
    const htmlContent = createOffscreenHTML();
    fs.writeFileSync(outputPath, htmlContent, 'utf8');
    console.log(`HTML file created successfully at: ${path.resolve(outputPath)}`);
  } catch (error) {
    console.error('Error writing file:', error.message);
    process.exit(1);
  }
}

module.exports = { createOffscreenHTML };
