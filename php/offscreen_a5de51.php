<?php
// abstraction-provenance: {"artifact_sha256": "a32e34fb99aef5261026b59c2b8591db1bedd3dd2b84b21ce3b3a2a60702b503", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "php"}
// offscreen.html — portiert nach php
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
// TikTok LIVE Companion Sprachausgabe
function generateOffscreenHTML($outputFile = null) {
    $html = '<!doctype html>' . PHP_EOL;
    $html .= '<html lang="de">' . PHP_EOL;
    $html .= '<head>' . PHP_EOL;
    $html .= '  <meta charset="utf-8">' . PHP_EOL;
    $html .= '  <title>TikTok LIVE Companion Sprachausgabe</title>' . PHP_EOL;
    $html .= '</head>' . PHP_EOL;
    $html .= '<body>' . PHP_EOL;
    $html .= '  <script src="offscreen.js"></script>' . PHP_EOL;
    $html .= '</body>' . PHP_EOL;
    $html .= '</html>' . PHP_EOL;
    
    if ($outputFile) {
        file_put_contents($outputFile, $html);
        return "HTML wurde in $outputFile geschrieben";
    }
    
    return $html;
}

// Wenn das Skript direkt aufgerufen wird, generiere die HTML-Ausgabe
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    // Standardmäßig zur Browserausgabe
    header('Content-Type: text/html; charset=utf-8');
    echo generateOffscreenHTML();
}
?>
