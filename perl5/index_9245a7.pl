#!/usr/bin/perl
# index.html — portiert nach perl5
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter prüfen
if (@ARGV != 1) {
    die "Usage: $0 <output_file>\n";
}

my $output_file = $ARGV[0];

# HTML-Inhalt generieren
my $html_content = generate_html();

# In Datei schreiben
open(my $fh, '>', $output_file) or die "Kann Datei '$output_file' nicht öffnen: $!";
print $fh $html_content;
close($fh);

sub generate_html {
    my $html = '';
    
    # DOCTYPE
    $html .= '<!DOCTYPE html>' . "\n";
    
    # Öffnendes HTML-Tag mit Sprachattribut
    $html .= '<html lang="de">' . "\n";
    
    # Head-Bereich
    $html .= '<head>' . "\n";
    
    # Meta-Tags
    $html .= '  <meta charset="utf-8">' . "\n";
    $html .= '  <meta name="viewport" content="width=device-width, initial-scale=1">' . "\n";
    $html .= '  <meta http-equiv="refresh" content="0; url=3d.html">' . "\n";
    
    # Titel
    $html .= '  <title>Weiterleitung zur 3D-Ansicht</title>' . "\n";
    
    # Link-Tag
    $html .= '  <link rel="canonical" href="3d.html">' . "\n";
    
    # Script-Tag
    $html .= '  <script>location.replace(\'3d.html\');</script>' . "\n";
    
    $html .= '</head>' . "\n";
    
    # Body-Bereich
    $html .= '<body>' . "\n";
    $html .= '  <p><a href="3d.html">3D-Ansicht öffnen</a></p>' . "\n";
    $html .= '</body>' . "\n";
    
    # Schließendes HTML-Tag
    $html .= '</html>' . "\n";
    
    return $html;
}
