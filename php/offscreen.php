<?php
// abstraction-provenance: {"artifact_sha256": "e85b38d809f19f3a8f1495b4e6355c3d679bd23e878e8291b0b47ebde97f68c5", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "php"}
// offscreen.html — portiert nach php
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
// TikTok LIVE Companion Sprachausgabe
// Offscreen-Dokument Generator

// Setze den Content-Type fuer HTML
header('Content-Type: text/html; charset=utf-8');

// Funktion zum Erstellen des Offscreen-HTML-Dokuments
function generateOffscreenDocument() {
    // Erstelle das HTML-Dokument strukturiert
    $html = '<!doctype html>' . "\n";
    $html .= '<html lang="de">' . "\n";
    $html .= '<head>' . "\n";
    $html .= '  <meta charset="utf-8">' . "\n";
    $html .= '  <title>TikTok LIVE Companion Sprachausgabe</title>' . "\n";
    $html .= '</head>' . "\n";
    $html .= '<body>' . "\n";
    $html .= '  <script src="offscreen.js"></script>' . "\n";
    $html .= '</body>' . "\n";
    $html .= '</html>';
    
    return $html;
}

// Wenn ein Dateiparameter uebergeben wird, schreibe in Datei
if (isset($argv[1])) {
    $filename = $argv[1];
    $content = generateOffscreenDocument();
    file_put_contents($filename, $content);
} else {
    // Ansonsten gib das Dokument direkt aus
    echo generateOffscreenDocument();
}
?>
