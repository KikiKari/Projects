#!/usr/bin/perl
# index.css — portiert nach perl5
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Prüfe, ob ein Dateiname als Parameter übergeben wurde
if (@ARGV != 1) {
    die "Verwendung: $0 <ausgabedatei>\n";
}

my $dateiname = $ARGV[0];

# Öffne die Ausgabedatei zum Schreiben
open(my $fh, '>', $dateiname) or die "Kann Datei '$dateiname' nicht öffnen: $!\n";

# Schreibe den CSS-Inhalt in die Datei
print $fh <<'CSS';
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
CSS

# Schließe die Datei
close($fh);

print "CSS-Datei erfolgreich erstellt: $dateiname\n";
