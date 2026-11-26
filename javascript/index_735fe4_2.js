#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "b573ab3ca8e098fdfc952c27e4d675e175b00095797448d52da0fb0f2c0aa159", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Create the HTML document structure
const doc = {
  doctype: '<!DOCTYPE html>',
  html: {
    attrs: { lang: 'de' },
    head: {
      children: [
        { tag: 'meta', attrs: { charset: 'utf-8' } },
        { tag: 'link', attrs: { rel: 'icon', href: '/favicon.ico' } },
        { tag: 'meta', attrs: { name: 'viewport', content: 'width=device-width, initial-scale=1' } },
        { tag: 'meta', attrs: { name: 'theme-color', content: '#0b1020' } },
        { 
          tag: 'meta',
          attrs: { 
            name: 'description',
            content: 'OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.'
          }
        },
        { tag: 'link', attrs: { rel: 'apple-touch-icon', href: '/logo192.png' } },
        { 
          tag: '!--',
          content: '\n      manifest.json provides metadata used when your web app is installed on a\n      user\'s mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/\n    '
        },
        { tag: 'link', attrs: { rel: 'manifest', href: '/manifest.json' } },
        { tag: 'title', content: 'OpenClaw' }
      ]
    },
    body: {
      children: [
        { 
          tag: 'noscript', 
          content: 'You need to enable JavaScript to run this app.' 
        },
        { 
          tag: 'div', 
          attrs: { id: 'root' } 
        },
        {
          tag: '!--',
          content: '\n      This HTML file is a template.\n      If you open it directly in the browser, you will see an empty page.\n\n      You can add webfonts, meta tags, or analytics to this file.\n      The build step will place the bundled scripts into the <body> tag.\n\n      To begin the development, run `npm start` or `yarn start`.\n      To create a production bundle, use `npm run build` or `yarn build`.\n    '
        }
      ]
    },
    scripts: [
      { tag: 'script', attrs: { type: 'module', src: '/src/index.jsx' } }
    ]
  }
};

// Function to generate HTML string from structure
function generateHTML(doc) {
  let html = doc.doctype + '\n';
  html += generateElement('html', doc.html.attrs, doc.html);
  return html;
}

function generateElement(tag, attrs = {}, element = {}) {
  let html = '';
  
  if (tag === '!-') {
    // Handle comments
    html += '<!--' + element.content + '-->\n';
    return html;
  }
  
  html += '<' + tag;
  
  // Add attributes
  if (attrs) {
    for (const [key, value] of Object.entries(attrs)) {
      html += ' ' + key + '="' + value + '"';
    }
  }
  
  html += '>';
  
  // Add content if exists
  if (element.content) {
    html += element.content;
  }
  
  // Add children if they exist
  if (element.children) {
    html += '\n';
    for (const child of element.children) {
      if (child.tag) {
        html += '  ' + generateElement(child.tag, child.attrs, child).trim() + '\n';
      }
    }
  }
  
  html += '</' + tag + '>\n';
  
  return html;
}

// Generate the complete HTML
let outputHTML = doc.doctype + '\n';
outputHTML += '<html lang="' + doc.html.attrs.lang + '">\n';
outputHTML += '  <head>\n';

// Add head elements
for (const child of doc.html.head.children) {
  if (child.tag === 'title') {
    outputHTML += '    <title>' + child.content + '</title>\n';
  } else if (child.tag === '!-') {
    outputHTML += '    ' + '<!--' + child.content + '-->\n';
  } else {
    outputHTML += '    <' + child.tag;
    for (const [key, value] of Object.entries(child.attrs)) {
      outputHTML += ' ' + key + '="' + value + '"';
    }
    outputHTML += ' />\n';
  }
}

outputHTML += '  </head>\n';
outputHTML += '  <body>\n';

// Add body elements
for (const child of doc.html.body.children) {
  if (child.tag === '!-') {
    outputHTML += '    ' + '<!--' + child.content + '-->\n';
  } else {
    outputHTML += '    <' + child.tag;
    if (child.attrs) {
      for (const [key, value] of Object.entries(child.attrs)) {
        outputHTML += ' ' + key + '="' + value + '"';
      }
    }
    if (child.content) {
      outputHTML += '>' + child.content + '</' + child.tag + '>\n';
    } else {
      outputHTML += '></' + child.tag + '>\n';
    }
  }
}

outputHTML += '  </body>\n';

// Add script elements
for (const script of doc.html.scripts) {
  outputHTML += '  <' + script.tag;
  for (const [key, value] of Object.entries(script.attrs)) {
    outputHTML += ' ' + key + '="' + value + '"';
  }
  outputHTML += '></' + script.tag + '>\n';
}

outputHTML += '</html>\n';

// Write to file if argument provided
if (process.argv[2]) {
  const outputPath = process.argv[2];
  writeFileSync(outputPath, outputHTML);
  console.log(`HTML file generated at ${outputPath}`);
} else {
  console.log(outputHTML);
}
