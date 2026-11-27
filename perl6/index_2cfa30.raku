#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "a0ca09cdc94f479f72d711f79a1b74db500f772da3ebabe9d97e7a2dd47180fe", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "perl6"}
# index.html — portiert nach perl6
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use v6;

sub MAIN($output-file) {
    # Erzeuge den HTML-Inhalt strukturiert
    my $html = q:to/HTML/;
    <!doctype html>
    <html lang="de">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
        <meta name="theme-color" content="#ffffff" />
        <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
        <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
        <title>TikTok LIVE Companion – Dokumentation</title>
      </head>
      <body>
        <div id="root"></div>
        <script type="module" src="/src/main.tsx"></script>
      </body>
    </html>
    HTML

    # Schreibe den Inhalt in die angegebene Datei
    spurt($output-file, $html);
}
