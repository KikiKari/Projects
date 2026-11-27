#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "9e86e7b38dc403a5701b72ae30d05c86e30102187af519b31d84b7147cd57931", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "perl5"}
# offscreen.html — portiert nach perl5
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter prüfen
my $output_file = $ARGV[0] or die "Usage: $0 <output_file>\n";

# HTML-Struktur erstellen
my $html = <<'EOF';
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
EOF

# In Datei schreiben
open my $fh, '>', $output_file or die "Kann Datei '$output_file' nicht öffnen: $!\n";
print $fh $html;
close $fh or die "Fehler beim Schließen der Datei: $!\n";
