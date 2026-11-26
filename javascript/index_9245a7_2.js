#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "112194ea2db8e8709d639dec8dbd87026711f898850c9f8fcbfbfb36e4e458f2", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createRedirectHtml(targetUrl = '3d.html') {
  // Create document structure
  const docType = '<!DOCTYPE html>';
  
  // Build HTML elements
  const html = {
    lang: 'de',
    children: []
  };
  
  // Head section
  const head = {
    children: [
      { tag: 'meta', attributes: { charset: 'utf-8' } },
      { tag: 'meta', attributes: { name: 'viewport', content: 'width=device-width, initial-scale=1' } },
      { tag: 'meta', attributes: { 'http-equiv': 'refresh', content: `0; url=${targetUrl}` } },
      { tag: 'title', children: ['Weiterleitung zur 3D-Ansicht'] },
      { tag: 'link', attributes: { rel: 'canonical', href: targetUrl } },
      { 
        tag: 'script', 
        children: [`location.replace('${targetUrl}');`] 
      }
    ]
  };
  
  // Body section
  const body = {
    children: [
      {
        tag: 'p',
        children: [
          {
            tag: 'a',
            attributes: { href: targetUrl },
            children: ['3D-Ansicht öffnen']
          }
        ]
      }
    ]
  };
  
  html.children.push(head, body);
  
  // Render to string
  function renderElement(element, indent = '') {
    if (typeof element === 'string') {
      return element;
    }
    
    if (element.tag) {
      let result = indent + '<' + element.tag;
      
      // Add attributes
      if (element.attributes) {
        for (const [key, value] of Object.entries(element.attributes)) {
          result += ` ${key}="${value}"`;
        }
      }
      
      // Handle self-closing tags
      const selfClosingTags = ['meta', 'link'];
      if (selfClosingTags.includes(element.tag)) {
        result += '>';
        return result;
      }
      
      result += '>';
      
      // Add children
      if (element.children && element.children.length > 0) {
        const isInline = element.children.every(child => typeof child === 'string');
        const newIndent = isInline ? '' : indent + '  ';
        
        for (const child of element.children) {
          if (!isInline) result += '\n';
          result += renderElement(child, newIndent);
        }
        
        if (!isInline) result += '\n' + indent;
      }
      
      result += `</${element.tag}>`;
      return result;
    }
    
    return '';
  }
  
  // Generate complete HTML
  let htmlString = docType + '\n';
  htmlString += '<html';
  if (html.lang) htmlString += ` lang="${html.lang}"`;
  htmlString += '>\n';
  
  for (const child of html.children) {
    htmlString += renderElement(child, '  ') + '\n';
  }
  
  htmlString += '</html>';
  
  return htmlString;
}

// Main execution
if (require.main === module) {
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  try {
    const htmlContent = createRedirectHtml();
    fs.writeFileSync(outputFile, htmlContent, 'utf8');
    console.log(`HTML file created: ${outputFile}`);
  } catch (error) {
    console.error('Error writing file:', error.message);
    process.exit(1);
  }
}

module.exports = { createRedirectHtml };
