#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Ermittle das Verzeichnis des aktuellen Skripts
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Funktion zum Erstellen eines HTML-Dokuments
function createHtmlDocument() {
  // Erstelle das HTML-Dokument mit allen erforderlichen Elementen
  const html = `<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>`;

  return html;
}

// Hauptfunktion
function main() {
  // Prüfe, ob ein Dateiname als Argument übergeben wurde
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Bitte geben Sie einen Dateinamen als Argument an.');
    process.exit(1);
  }
  
  try {
    // Erstelle das HTML-Dokument
    const htmlContent = createHtmlDocument();
    
    // Schreibe den Inhalt in die angegebene Datei
    fs.writeFileSync(outputFile, htmlContent);
    
    console.log(`HTML-Datei erfolgreich erstellt: ${outputFile}`);
  } catch (error) {
    console.error('Fehler beim Erstellen der HTML-Datei:', error.message);
    process.exit(1);
  }
}

// Führe die Hauptfunktion aus
main();
