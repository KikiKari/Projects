#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "1715efc3ff3a4976490ff0ee8c25738f8321da96a45c50a01b0577460f471d83", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "javascript"}
// node-monitor.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
    const cssRules = [
        {
            selector: ':root',
            declarations: {
                '--bg': '#0d1117',
                '--surface': '#161b22',
                '--border': '#30363d',
                '--text': '#e6edf3',
                '--green': '#3fb950',
                '--red': '#f85149',
                '--accent': '#58a6ff'
            }
        },
        {
            selector: '*',
            declarations: {
                'box-sizing': 'border-box',
                'margin': '0',
                'padding': '0'
            }
        },
        {
            selector: 'body',
            declarations: {
                'background': 'var(--bg)',
                'color': 'var(--text)',
                'font-family': '-apple-system, sans-serif',
                'padding': '1.5rem'
            }
        },
        {
            selector: 'h1',
            declarations: {
                'color': 'var(--accent)',
                'margin-bottom': '1rem',
                'font-size': '1.2rem'
            }
        },
        {
            selector: 'canvas',
            declarations: {
                'display': 'block',
                'border': '1px solid var(--border)',
                'border-radius': '8px',
                'background': 'var(--surface)'
            }
        },
        {
            selector: '#log',
            declarations: {
                'margin-top': '1rem',
                'height': '140px',
                'overflow-y': 'auto',
                'background': 'var(--surface)',
                'border': '1px solid var(--border)',
                'border-radius': '8px',
                'padding': '.75rem',
                'font-size': '.78rem',
                'font-family': 'monospace',
                'color': '#8b949e'
            }
        },
        {
            selector: '#log .err',
            declarations: {
                'color': 'var(--red)'
            }
        },
        {
            selector: '#log .ok',
            declarations: {
                'color': 'var(--green)'
            }
        }
    ];

    let cssContent = `\
/* abstraction-provenance: {"artifact_sha256": "37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "css"} */
/* node-monitor.html — portiert nach css */
/* Quelle: html, OpenClaw@main:examples/node-monitor.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

`;

    for (const rule of cssRules) {
        cssContent += `${rule.selector} {\n`;
        for (const [property, value] of Object.entries(rule.declarations)) {
            cssContent += `  ${property}: ${value};\n`;
        }
        cssContent += `}\n\n`;
    }

    return cssContent.trim();
}

function writeToFile(content, outputPath) {
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(outputPath, content);
}

// Hauptprogramm
if (require.main === module) {
    const outputPath = process.argv[2];
    if (!outputPath) {
        console.error('Verwendung: node-monitor-css.js <ausgabedatei>');
        process.exit(1);
    }

    try {
        const cssContent = generateCSS();
        writeToFile(cssContent, outputPath);
        console.log(`CSS erfolgreich generiert und gespeichert unter: ${outputPath}`);
    } catch (error) {
        console.error('Fehler beim Generieren der CSS-Datei:', error.message);
        process.exit(1);
    }
}

module.exports = { generateCSS, writeToFile };
