<?php
// abstraction-provenance: {"artifact_sha256": "eac140a6638423c026cc2de281e971752a4228b0407f45390a2d4ae38c2bae56", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "php"}
// status-overview.html — portiert nach php
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
// status-overview.php

function generateStatusOverview($outputFile) {
    $html = '<!doctype html>' . PHP_EOL;
    $html .= '<html lang="de">' . PHP_EOL;
    $html .= '<head>' . PHP_EOL;
    $html .= '<meta charset="utf-8">' . PHP_EOL;
    $html .= '<meta name="viewport" content="width=device-width,initial-scale=1">' . PHP_EOL;
    $html .= '<title>STATUS-Overview</title>' . PHP_EOL;
    $html .= '<link rel="stylesheet" href="status-overview.css">' . PHP_EOL;
    $html .= '</head>' . PHP_EOL;
    $html .= '<body>' . PHP_EOL;
    $html .= '<main id="grid" aria-label="LIVE-Übersicht"></main>' . PHP_EOL;
    $html .= '<script src="vendor-mpegts.js"></script>' . PHP_EOL;
    $html .= '<script src="status-overview-player.js"></script>' . PHP_EOL;
    $html .= '</body>' . PHP_EOL;
    $html .= '</html>' . PHP_EOL;

    file_put_contents($outputFile, $html);
}

// Wenn das Skript direkt aufgerufen wird, erzeuge die Datei
if (basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    $outputFilename = $argv[1] ?? 'status-overview.html';
    generateStatusOverview($outputFilename);
}
?>
