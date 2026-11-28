#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "b5675b5334ed18afaf9e42ec1a3f76db8ff2971b151b1bfcd0168414966dfaa5", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "javascript"}
// peak-limiter_4ced2c.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');

function generateCSS() {
    let css = '';
    
    // Add the comments at the top
    css += '/* abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "css"} */\n';
    css += '/* peak-limiter.html — portiert nach css */\n';
    css += '/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */\n';
    css += '/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n';
    
    // Body styles
    css += 'body {\n';
    css += '  font: 16px system-ui;\n';
    css += '  max-width: 1000px;\n';
    css += '  margin: 40px auto;\n';
    css += '  padding: 20px;\n';
    css += '}\n\n';
    
    // Pre styles
    css += 'pre {\n';
    css += '  white-space: pre-wrap;\n';
    css += '}\n\n';
    
    // Button styles
    css += 'button {\n';
    css += '  padding: 12px;\n';
    css += '}\n';
    
    return css;
}

function main() {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Bitte geben Sie eine Ausgabedatei als Parameter an.');
        process.exit(1);
    }
    
    const cssContent = generateCSS();
    
    try {
        fs.writeFileSync(outputFile, cssContent, 'utf8');
        console.log(`CSS erfolgreich in ${outputFile} geschrieben.`);
    } catch (error) {
        console.error('Fehler beim Schreiben der Datei:', error.message);
        process.exit(1);
    }
}

main();
