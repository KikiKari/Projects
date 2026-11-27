#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "7e115a6c5d5c02cc4fa9cabbd48860509ab5009d96ee4cb4dc30aefecd0135c1", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "javascript"}
// status-overview.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

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

    // Function to convert JSON structure to HTML string
    function buildHTML(element) {
        if (typeof element === 'string') {
            return element;
        }

        if (element.children && element.children.length > 0) {
            const childrenHTML = element.children.map(buildHTML).join('');
            const attrs = element.attributes ? 
                Object.entries(element.attributes)
                    .map(([key, value]) => `${key}="${value}"`)
                    .join(' ') : '';
            
            const openingTag = attrs ? `<${element.tag} ${attrs}>` : `<${element.tag}>`;
            return `${openingTag}${childrenHTML}</${element.tag}>`;
        } else {
            const attrs = element.attributes ? 
                Object.entries(element.attributes)
                    .map(([key, value]) => `${key}="${value}"`)
                    .join(' ') : '';
            
            const openingTag = attrs ? `<${element.tag} ${attrs}` : `<${element.tag}`;
            return `${openingTag}></${element.tag}>`;
        }
    }

    // Build the complete HTML document
    const htmlContent = docType + buildHTML(html);
    
    return htmlContent;
}

// Main execution
function main() {
    const outputPath = process.argv[2];
    
    if (!outputPath) {
        console.error('Bitte geben Sie einen Ausgabepfad an.');
        process.exit(1);
    }
    
    try {
        const htmlContent = createStatusOverview();
        fs.writeFileSync(outputPath, htmlContent, 'utf8');
        console.log(`HTML-Datei erfolgreich erstellt: ${path.resolve(outputPath)}`);
    } catch (error) {
        console.error('Fehler beim Erstellen der HTML-Datei:', error.message);
        process.exit(1);
    }
}

main();
