<?php
// abstraction-provenance: {"artifact_sha256": "06039a8a97d897c4215c95b239005cfa3024e254591027f09c20d8b40579f7e7", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "php"}
// index.html — portiert nach php
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateIndexHtml($outputFile) {
    $html = '<!doctype html>' . PHP_EOL;
    $html .= '<html lang="de">' . PHP_EOL;
    $html .= '  <head>' . PHP_EOL;
    $html .= '    <meta charset="UTF-8" />' . PHP_EOL;
    $html .= '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />' . PHP_EOL;
    $html .= '    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />' . PHP_EOL;
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

    file_put_contents($outputFile, $html);
}

// Beispielaufruf:
// generateIndexHtml('index.html');
?>
