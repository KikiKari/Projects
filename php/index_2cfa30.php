<?php
// abstraction-provenance: {"artifact_sha256": "85a3f060c2acf95bd065d274d67c6175a9da7b68216171a2ad47989481b54fb2", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "php"}
// index.html — portiert nach php
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
// Funktion zum Erstellen des HTML-Dokuments
function createHtmlDocument() {
    $html = '<!doctype html>' . PHP_EOL;
    $html .= '<html lang="de">' . PHP_EOL;
    $html .= '  <head>' . PHP_EOL;
    $html .= '    <meta charset="UTF-8" />' . PHP_EOL;
    $html .= '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />' . PHP_EOL;
    $html .= '    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />' . PHP_EOL;
    $html .= '    <meta name="theme-color" content="#ffffff" />' . PHP_EOL;
    $html .= '    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />' . PHP_EOL;
    $html .= '    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />' . PHP_EOL;
    $html .= '    <title>TikTok LIVE Companion – Dokumentation</title>' . PHP_EOL;
    $html .= '  </head>' . PHP_EOL;
    $html .= '  <body>' . PHP_EOL;
    $html .= '    <div id="root"></div>' . PHP_EOL;
    $html .= '    <script type="module" src="/src/main.tsx"></script>' . PHP_EOL;
    $html .= '  </body>' . PHP_EOL;
    $html .= '</html>' . PHP_EOL;
    
    return $html;
}

// Funktion zum Schreiben des HTML-Dokuments in eine Datei
function writeHtmlToFile($filename) {
    $content = createHtmlDocument();
    file_put_contents($filename, $content);
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die Datei
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    // Standard-Dateiname, kann über Kommandozeilenparameter überschrieben werden
    $outputFile = 'index.html';
    
    // Prüfe, ob ein Dateiname als Parameter übergeben wurde
    if (isset($argv[1])) {
        $outputFile = $argv[1];
    }
    
    writeHtmlToFile($outputFile);
    echo "HTML-Dokument wurde erfolgreich in '$outputFile' geschrieben." . PHP_EOL;
}
?>
