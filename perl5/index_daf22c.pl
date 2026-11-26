#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "4ad65551f446d7d21135b4627032133b12931556c5953bebbdbca8292d3dfe1d", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "perl5"}
# index.css — portiert nach perl5
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Prüfen, ob ein Dateiname übergeben wurde
if (@ARGV != 1) {
    die "Verwendung: $0 <dateiname>\n";
}

my $dateiname = $ARGV[0];

# Öffnen der Ausgabedatei
open(my $fh, '>', $dateiname) or die "Kann Datei '$dateiname' nicht öffnen: $!";

# Schreiben der CSS-Regeln
print $fh "body {\n";
print $fh "  margin: 0;\n";
print $fh "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',\n";
print $fh "    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',\n";
print $fh "    sans-serif;\n";
print $fh "  -webkit-font-smoothing: antialiased;\n";
print $fh "  -moz-osx-font-smoothing: grayscale;\n";
print $fh "}\n\n";

print $fh "code {\n";
print $fh "  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',\n";
print $fh "    monospace;\n";
print $fh "}\n";

# Schließen der Datei
close($fh) or die "Kann Datei '$dateiname' nicht schließen: $!";

print "CSS-Datei erfolgreich erstellt: $dateiname\n";
