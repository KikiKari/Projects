#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "629c68833e6321a46c1a6cb8b85ee4450eb44afb3588a1df9ac3372da5d4f742", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "perl5"}
# status-overview.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Erzeuge HTML-Dokument für STATUS-Overview

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

# Prüfe ob Parameter für Dateiausgabe übergeben wurde
if (@ARGV != 1) {
    print STDERR "Verwendung: $0 <ausgabedatei>\n";
    exit 1;
}

my $ausgabedatei = $ARGV[0];

# Schreibe HTML in Datei
open(my $fh, '>', $ausgabedatei) or die "Kann Datei '$ausgabedatei' nicht öffnen: $!";
print $fh $html;
close($fh) or die "Fehler beim Schließen der Datei: $!";

print "HTML-Dokument erfolgreich in '$ausgabedatei' geschrieben.\n";
