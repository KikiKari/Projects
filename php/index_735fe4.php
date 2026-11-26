<?php
// abstraction-provenance: {"artifact_sha256": "5afa848317e7841be81c3c7103e9895d557d0719b01c2af680cc9fa501d1aaaf", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "php"}
// index.html — portiert nach php
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateIndexHtml($filename) {
    $html = <<<HTML
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#0b1020" />
    <meta
      name="description"
      content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."
    />
    <link rel="apple-touch-icon" href="/logo192.png" />
    <!--
      manifest.json provides metadata used when your web app is installed on a
      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
    -->
    <link rel="manifest" href="/manifest.json" />
    <title>OpenClaw</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
    <!--
      This HTML file is a template.
      If you open it directly in the browser, you will see an empty page.

      You can add webfonts, meta tags, or analytics to this file.
      The build step will place the bundled scripts into the <body> tag.

      To begin the development, run `npm start` or `yarn start`.
      To create a production bundle, use `npm run build` or `yarn build`.
    -->
  </body>
  <script type="module" src="/src/index.jsx"></script>
</html>
HTML;

    file_put_contents($filename, $html);
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die Datei
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $outputFile = isset($argv[1]) ? $argv[1] : 'index.html';
    generateIndexHtml($outputFile);
    echo "Datei '$outputFile' wurde erfolgreich erstellt.\n";
}
?>
