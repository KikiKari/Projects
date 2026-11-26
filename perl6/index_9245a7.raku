#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "619e912690b5d6402bc70fe5891d93e83a84da4d1dddd251e72dd3eef30260d0", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "perl6"}
# index.html — portiert nach perl6
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

sub create-html($filename) {
    my $html = q:to/END_HTML/;
    <!DOCTYPE html>
    <html lang="de">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=3d.html">
    <title>Weiterleitung zur 3D-Ansicht</title>
    <link rel="canonical" href="3d.html">
    <script>location.replace('3d.html');</script>
    </head>
    <body>
    <p><a href="3d.html">3D-Ansicht öffnen</a></p>
    </body>
    </html>
    END_HTML

    spurt $filename, $html;
}

sub MAIN($output-file = "index.html") {
    create-html($output-file);
    say "HTML file created: $output-file";
}
