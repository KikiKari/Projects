#!/usr/bin/perl
# offscreen.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter prüfen
if (@ARGV != 1) {
    print STDERR "Aufruf: $0 <Ausgabedatei>\n";
    exit 1;
}

my $datei = $ARGV[0];

# HTML-Struktur erzeugen
my $html = <<'HTML';
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
HTML

# In Datei schreiben
open my $fh, '>', $datei or die "Kann Datei '$datei' nicht öffnen: $!";
print $fh $html;
close $fh or die "Fehler beim Schließen der Datei '$datei': $!";

print "HTML-Datei wurde erfolgreich erstellt: $datei\n";
