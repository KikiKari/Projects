#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createRedirectHtml() {
    const html = `<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0; url=3d.html">
<title>Weiterleitung zur 3D-Ansicht</title>
<link rel="canonical" href="3d.html">
<script>location.replace('3d.html');</script>
</head>
<body>
<p><a href="3d.html">3D-Ansicht öffnen</a></p>
</body>
</html>`;
    
    return html;
}

function main() {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Verwendung: node ' + path.basename(process.argv[1]) + ' <ausgabedatei>');
        process.exit(1);
    }
    
    const htmlContent = createRedirectHtml();
    
    try {
        fs.writeFileSync(outputFile, htmlContent, 'utf8');
        console.log('HTML-Datei erfolgreich erstellt: ' + outputFile);
    } catch (error) {
        console.error('Fehler beim Schreiben der Datei:', error.message);
        process.exit(1);
    }
}

main();
