#!/usr/bin/perl
# status-overview.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use HTML::Entities;

# Parameter für die Ausgabedatei
my $output_file = shift @ARGV or die "Usage: $0 <output-file>\n";

# Erstellen des HTML-Dokuments
my $html = <<'EOF';
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
EOF

# Schreiben in die Ausgabedatei
open my $fh, '>', $output_file or die "Kann Datei '$output_file' nicht öffnen: $!\n";
print $fh $html;
close $fh or die "Fehler beim Schließen der Datei '$output_file': $!\n";

print "HTML-Datei wurde erfolgreich erstellt: $output_file\n";
