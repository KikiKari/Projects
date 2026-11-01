#!/usr/bin/env node
// status-overview.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createStatusOverview() {
    // Create the document structure
    const docType = '<!doctype html>';
    
    const html = {
        tag: 'html',
        attributes: { lang: 'de' },
        children: [
            {
                tag: 'head',
                children: [
                    {
                        tag: 'meta',
                        attributes: { charset: 'utf-8' }
                    },
                    {
                        tag: 'meta',
                        attributes: { 
                            name: 'viewport', 
                            content: 'width=device-width,initial-scale=1' 
                        }
                    },
                    {
                        tag: 'title',
                        children: ['STATUS-Overview']
                    },
                    {
                        tag: 'link',
                        attributes: { 
                            rel: 'stylesheet', 
                            href: 'status-overview.css' 
                        }
                    }
                ]
            },
            {
                tag: 'body',
                children: [
                    {
                        tag: 'main',
                        attributes: { 
                            id: 'grid', 
                            'aria-label': 'LIVE-Übersicht' 
                        }
                    },
                    {
                        tag: 'script',
                        attributes: { src: 'vendor-mpegts.js' }
                    },
                    {
                        tag: 'script',
                        attributes: { src: 'status-overview-player.js' }
                    }
                ]
            }
        ]
    };

    // Function to convert object structure to HTML string
    function renderElement(element) {
        if (typeof element === 'string') {
            return element;
        }

        const tag = element.tag || 'div';
        const attributes = element.attributes || {};
        const children = element.children || [];

        let attrString = '';
        for (const [key, value] of Object.entries(attributes)) {
            attrString += ` ${key}="${value}"`;
        }

        if (children.length === 0) {
            return `<${tag}${attrString}></${tag}>`;
        }

        let innerHTML = '';
        for (const child of children) {
            innerHTML += renderElement(child);
        }

        return `<${tag}${attrString}>${innerHTML}</${tag}>`;
    }

    // Generate the complete HTML
    const htmlContent = docType + renderElement(html);

    return htmlContent;
}

// Main execution
function main() {
    const args = process.argv.slice(2);
    
    if (args.length !== 1) {
        console.error('Usage: node script.js <output-file>');
        process.exit(1);
    }

    const outputFile = args[0];
    const htmlContent = createStatusOverview();

    try {
        fs.writeFileSync(outputFile, htmlContent, 'utf8');
        console.log(`Successfully wrote STATUS overview to ${outputFile}`);
    } catch (error) {
        console.error(`Error writing file: ${error.message}`);
        process.exit(1);
    }
}

main();
