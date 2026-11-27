#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "c5921357bd703e3685db007017b8b604d369200363b5533d1bb67a6139f027ce", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "perl6"}
# offscreen.html — portiert nach perl6
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use v6;

sub create-html-document($filename) {
    my $html = q:to/END/;
<!DOCTYPE html>
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

    spurt $filename, $html;
}

# Prüfe ob ein Dateiname übergeben wurde
if @*ARGS.elems != 1 {
    say "Verwendung: {$*PROGRAM-NAME} <dateiname>";
    exit 1;
}

my $output-file = @*ARGS[0];
create-html-document($output-file);
say "HTML-Dokument wurde in '$output-file' erstellt.";
