#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "c98f08069d648d4677dd197b6d33d56ef8884591b093e1254aa049048264a2b0", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "perl5"}
# index.html — portiert nach perl5
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Prüfe, ob ein Dateiname als Parameter übergeben wurde
if (@ARGV != 1) {
    die "Verwendung: $0 <ausgabedatei>\n";
}

my $datei = $ARGV[0];

# Öffne die Ausgabedatei zum Schreiben
open(my $fh, '>', $datei) or die "Kann Datei '$datei' nicht öffnen: $!";

# Schreibe das HTML-Dokument
print $fh <<'HTML_HEAD';
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
HTML_HEAD

# Schließe die Datei
close($fh);

print "HTML-Datei erfolgreich erstellt: $datei\n";
