#!/bin/bash
# index.html — portiert nach shell
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
output_file="${1:-}"

if [[ -z "$output_file" ]]; then
  echo "Fehler: Keine Ausgabedatei angegeben." >&2
  echo "Verwendung: $0 <ausgabedatei>" >&2
  exit 1
fi

# Erzeuge das HTML-Dokument Schritt fuer Schritt
{
  echo '<!DOCTYPE html>'
  echo '<html lang="de">'
  echo '  <head>'
  echo '    <meta charset="utf-8" />'
  echo '    <link rel="icon" href="/favicon.ico" />'
  echo '    <meta name="viewport" content="width=device-width, initial-scale=1" />'
  echo '    <meta name="theme-color" content="#0b1020" />'
  echo '    <meta'
  echo '      name="description"'
  echo '      content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."'
  echo '    />'
  echo '    <link rel="apple-touch-icon" href="/logo192.png" />'
  echo '    <!--'
  echo '      manifest.json provides metadata used when your web app is installed on a'
  echo '      user'"'"'s mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/'
  echo '    -->'
  echo '    <link rel="manifest" href="/manifest.json" />'
  echo '    <title>OpenClaw</title>'
  echo '  </head>'
  echo '  <body>'
  echo '    <noscript>You need to enable JavaScript to run this app.</noscript>'
  echo '    <div id="root"></div>'
  echo '    <!--'
  echo '      This HTML file is a template.'
  echo '      If you open it directly in the browser, you will see an empty page.'
  echo ''
  echo '      You can add webfonts, meta tags, or analytics to this file.'
  echo '      The build step will place the bundled scripts into the <body> tag.'
  echo ''
  echo '      To begin the development, run `npm start` or `yarn start`.'
  echo '      To create a production bundle, use `npm run build` or `yarn build`.'
  echo '    -->'
  echo '  </body>'
  echo '  <script type="module" src="/src/index.jsx"></script>'
  echo '</html>'
} > "$output_file"

echo "HTML-Datei wurde erfolgreich erstellt: $output_file"
