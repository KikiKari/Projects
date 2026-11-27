#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "513ed1fa4446276c9bb7541de50b84cc73858cc74894193149f08f0eb29aaaa6", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "perl6"}
# offscreen.html — portiert nach perl6
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use v6;

sub MAIN($output-file) {
    # Erzeuge das HTML-Dokument strukturiert
    my $html = qq:to/END/;
    <!doctype html>
    <html lang="de">
    <head>
      <meta charset="utf-8">
      <title>TikTok LIVE Companion Sprachausgabe</title>
    </head>
    <body>
      <script src="offscreen.js"></script>
    </body>
    </html>
    END

    # Schreibe das HTML in die angegebene Datei
    spurt $output-file, $html;
    
    say "HTML document written to $output-file";
}
