#!/usr/bin/perl
# offscreen.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter prüfen
if (@ARGV != 1) {
    die "Usage: $0 <output_file>\n";
}

my $output_file = $ARGV[0];

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
open my $fh, '>', $output_file or die "Kann Datei '$output_file' nicht öffnen: $!";
print $fh $html;
close $fh or die "Fehler beim Schließen der Datei '$output_file': $!";

print "HTML-Datei erfolgreich erstellt: $output_file\n";
