#!/usr/bin/env node
// gateway-dashboard.html — portiert nach javascript
// Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createHTMLDocument() {
  // Create the document structure
  const docType = '<!DOCTYPE html>';
  
  // Create HTML elements
  const html = {
    tag: 'html',
    attrs: { lang: 'en' },
    children: [
      {
        tag: 'head',
        children: [
          { tag: 'meta', attrs: { charset: 'UTF-8' } },
          { tag: 'meta', attrs: { name: 'viewport', content: 'width=device-width, initial-scale=1.0' } },
          { tag: 'title', children: ['OpenClaw — Gateway Dashboard'] },
          { tag: 'link', attrs: { rel: 'stylesheet', href: 'gateway-styles.css' } }
        ]
      },
      {
        tag: 'body',
        children: [
          {
            tag: 'header',
            children: [
              { tag: 'h1', children: ['OpenClaw Cluster'] },
              { tag: 'span', attrs: { id: 'cluster-status', class: 'badge' }, children: ['Checking...'] }
            ]
          },
          {
            tag: 'main',
            children: [
              {
                tag: 'section',
                attrs: { class: 'grid' },
                children: [
                  {
                    tag: 'div',
                    attrs: { class: 'card', id: 'gw1' },
                    children: [
                      { tag: 'h2', children: ['Gateway 1'] },
                      { tag: 'p', attrs: { class: 'endpoint' }, children: ['gateway1.openclaw.internal'] },
                      { tag: 'div', attrs: { class: 'status-dot' } }
                    ]
                  },
                  {
                    tag: 'div',
                    attrs: { class: 'card', id: 'gw2' },
                    children: [
                      { tag: 'h2', children: ['Gateway 2'] },
                      { tag: 'p', attrs: { class: 'endpoint' }, children: ['gateway2.openclaw.internal'] },
                      { tag: 'div', attrs: { class: 'status-dot' } }
                    ]
                  }
                ]
              },
              {
                tag: 'section',
                attrs: { class: 'metrics' },
                children: [
                  { tag: 'h2', children: ['Node Metrics'] },
                  {
                    tag: 'table',
                    children: [
                      {
                        tag: 'thead',
                        children: [
                          {
                            tag: 'tr',
                            children: [
                              { tag: 'th', children: ['Node'] },
                              { tag: 'th', children: ['Latency'] },
                              { tag: 'th', children: ['Requests'] },
                              { tag: 'th', children: ['Status'] }
                            ]
                          }
                        ]
                      },
                      {
                        tag: 'tbody',
                        attrs: { id: 'metrics-body' },
                        children: [
                          {
                            tag: 'tr',
                            children: [
                              { tag: 'td', attrs: { colspan: '4' }, children: ['Loading...'] }
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
            tag: 'script',
            children: [`
    const GATEWAY_URL = window.OPENCLAW_URL || "http://localhost:8080";

    async function pollStatus() {
      try {
        const res = await fetch(\`\${GATEWAY_URL}/health\`);
        const ok = res.ok;
        document.getElementById("cluster-status").textContent = ok ? "Online" : "Degraded";
        document.getElementById("cluster-status").className = \`badge \${ok ? "ok" : "warn"}\`;
        document.querySelectorAll(".status-dot").forEach(d => d.className = \`status-dot \${ok ? "green" : "red"}\`);
      } catch {
        document.getElementById("cluster-status").textContent = "Offline";
        document.getElementById("cluster-status").className = "badge error";
      }
    }

    pollStatus();
    setInterval(pollStatus, 5000);
`]
          }
        ]
      }
    ]
  };

  // Function to convert element tree to HTML string
  function elementToString(element, indent = 0) {
    if (typeof element === 'string') {
      return element.trim();
    }

    const spaces = '  '.repeat(indent);
    
    if (!element.tag) {
      return '';
    }

    let result = '';
    
    if (element.tag === 'script' && element.children && element.children.length > 0) {
      result += `${spaces}<${element.tag}`;
      if (element.attrs) {
        for (const [key, value] of Object.entries(element.attrs)) {
          result += ` ${key}="${value}"`;
        }
      }
      result += '>\n';
      result += element.children.join('').trim();
      result += `\n${spaces}</${element.tag}>\n`;
    } else {
      result += `${spaces}<${element.tag}`;
      
      if (element.attrs) {
        for (const [key, value] of Object.entries(element.attrs)) {
          result += ` ${key}="${value}"`;
        }
      }
      
      if (!element.children || element.children.length === 0) {
        result += '>\n';
      } else {
        result += '>\n';
        for (const child of element.children) {
          result += elementToString(child, indent + 1);
        }
        result += `${spaces}</${element.tag}>\n`;
      }
    }
    
    return result;
  }

  // Build the complete HTML document
  let htmlString = docType + '\n';
  htmlString += elementToString(html);
  
  return htmlString;
}

// Main execution
function main() {
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  const htmlContent = createHTMLDocument();
  
  try {
    fs.writeFileSync(outputFile, htmlContent);
    console.log(`Dashboard HTML written to ${outputFile}`);
  } catch (error) {
    console.error(`Error writing file: ${error.message}`);
    process.exit(1);
  }
}

main();
