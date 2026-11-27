#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "244832012a286fba0b5f74ea5edd19d2d6eacac504b5f7848e2d0a882099d2e2", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "perl6"}
# status-overview.html — portiert nach perl6
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use v6;

# This script generates the status-overview.html file
# It creates a complete HTML document with proper DOCTYPE and structure

sub MAIN($output-file = "status-overview.html") {
    # Define the HTML structure as a string
    my $html-content = q:to/END_HTML/;
    <!doctype html>
    <html lang="de">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>STATUS-Overview</title>
        <link rel="stylesheet" href="status-overview.css">
    </head>
    <body>
        <main id="grid" aria-label="LIVE-Übersicht"></main>
        <script src="vendor-mpegts.js"></script>
        <script src="status-overview-player.js"></script>
    </body>
    </html>
    END_HTML

    # Write the content to the specified output file
    spurt $output-file, $html-content;
    
    say "Generated $output-file";
}
