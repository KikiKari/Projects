#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Helper function to get __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Create the HTML structure
function createHTML() {
  // Create document type declaration
  const docType = '<!DOCTYPE html>';
  
  // Create html element with lang attribute
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
        attributes: { charset: 'utf-8' }
      },
      {
        tag: 'link',
        attributes: { rel: 'icon', href: '/favicon.ico' }
      },
      {
        tag: 'meta',
        attributes: { 
          name: 'viewport', 
          content: 'width=device-width, initial-scale=1' 
        }
      },
      {
        tag: 'meta',
        attributes: { 
          name: 'theme-color', 
          content: '#0b1020' 
        }
      },
      {
        tag: 'meta',
        attributes: { 
          name: 'description', 
          content: 'OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.' 
        }
      },
      {
        tag: 'link',
        attributes: { 
          rel: 'apple-touch-icon', 
          href: '/logo192.png' 
        }
      },
      {
        tag: 'link',
        attributes: { 
          rel: 'manifest', 
          href: '/manifest.json' 
        },
        comment: 'manifest.json provides metadata used when your web app is installed on a\n      user\'s mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/'
      },
      {
        tag: 'title',
        children: ['OpenClaw']
      }
    ]
  };
  
  // Create body section
  const body = {
    tag: 'body',
    children: [
      {
        tag: 'noscript',
        children: ['You need to enable JavaScript to run this app.']
      },
      {
        tag: 'div',
        attributes: { id: 'root' }
      },
      {
        comment: 'This HTML file is a template.\n      If you open it directly in the browser, you will see an empty page.\n\n      You can add webfonts, meta tags, or analytics to this file.\n      The build step will place the bundled scripts into the <body> tag.\n\n      To begin the development, run `npm start` or `yarn start`.\n      To create a production bundle, use `npm run build` or `yarn build`.'
      }
    ]
  };
  
  // Add script tag
  const script = {
    tag: 'script',
    attributes: { 
      type: 'module', 
      src: '/src/index.jsx' 
    }
  };
  
  // Build the complete structure
  html.children.push(head);
  html.children.push(body);
  html.children.push(script);
  
  return { docType, html };
}

// Render HTML element recursively
function renderElement(element, indent = '') {
  if (element.comment) {
    const commentLines = element.comment.split('\n');
    const formattedComment = commentLines.map(line => `<!--${line}-->`).join('\n' + indent);
    
    if (!element.tag) {
      return `${indent}${formattedComment}`;
    }
    
    // If it has both comment and tag, render comment first
    let result = `${indent}${formattedComment}\n`;
    
    const attrs = Object.entries(element.attributes || {})
      .map(([key, value]) => `${key}="${value}"`)
      .join(' ');
    
    if (element.children && element.children.length > 0) {
      const tagOpen = attrs ? `<${element.tag} ${attrs}>` : `<${element.tag}>`;
      result += `${indent}${tagOpen}\n`;
      
      const childIndent = indent + '  ';
      for (const child of element.children) {
        if (typeof child === 'string') {
          result += `${childIndent}${child}\n`;
        } else {
          result += renderElement(child, childIndent) + '\n';
        }
      }
      
      result += `${indent}</${element.tag}>`;
    } else {
      const tag = attrs ? `<${element.tag} ${attrs} />` : `<${element.tag} />`;
      result += `${indent}${tag}`;
    }
    
    return result;
  }
  
  if (!element.tag) {
    return '';
  }
  
  const attrs = Object.entries(element.attributes || {})
    .map(([key, value]) => `${key}="${value}"`)
    .join(' ');
  
  if (element.children && element.children.length > 0) {
    const tagOpen = attrs ? `<${element.tag} ${attrs}>` : `<${element.tag}>`;
    let result = `${indent}${tagOpen}`;
    
    // Check if all children are text nodes
    const allText = element.children.every(child => typeof child === 'string');
    
    if (allText) {
      result += element.children.join('');
      result += `</${element.tag}>`;
      return result;
    }
    
    result += '\n';
    
    const childIndent = indent + '  ';
    for (const child of element.children) {
      if (typeof child === 'string') {
        result += `${childIndent}${child}\n`;
      } else {
        result += renderElement(child, childIndent) + '\n';
      }
    }
    
    result += `${indent}</${element.tag}>`;
    return result;
  } else {
    const tag = attrs ? `<${element.tag} ${attrs} />` : `<${element.tag} />`;
    return `${indent}${tag}`;
  }
}

// Generate the complete HTML document
function generateHTMLDocument() {
  const { docType, html } = createHTML();
  const htmlContent = renderElement(html);
  return `${docType}\n${htmlContent}\n`;
}

// Main execution
function main() {
  const args = process.argv.slice(2);
  const outputFile = args[0] || join(__dirname, 'index.html');
  
  try {
    const htmlDocument = generateHTMLDocument();
    writeFileSync(outputFile, htmlDocument);
    console.log(`HTML file generated successfully: ${outputFile}`);
  } catch (error) {
    console.error('Error generating HTML file:', error.message);
    process.exit(1);
  }
}

main();
