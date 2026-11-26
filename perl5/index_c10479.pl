#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "10b8ae6bad281c612238802707bb9aba8d2cd39194a9f78f3d807182ca08780c", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "perl5"}
# index.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# TikTok LIVE Companion Dokumentation Generator

sub generate_html {
    my $output_file = shift || 'index.html';

    open(my $fh, '>', $output_file) or die "Kann Datei '$output_file' nicht öffnen: $!";

    print $fh <<'EOF';
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
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
EOF

    close($fh);
    print "HTML-Dokument wurde erfolgreich in '$output_file' generiert.\n";
}

# Hauptprogramm
if (@ARGV && $ARGV[0] eq '--help') {
    print "Verwendung: $0 [Ausgabedatei]\n";
    print "Erzeugt die TikTok LIVE Companion Dokumentationsseite.\n";
    exit 0;
}

my $output_filename = $ARGV[0] || 'index.html';
generate_html($output_filename);
