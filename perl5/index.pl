#!/usr/bin/perl
# index.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Funktion zum Erstellen des HTML-Dokuments
sub create_html {
    my $output_file = shift;
    
    # Öffne die Ausgabedatei zum Schreiben
    open(my $fh, '>', $output_file) or die "Kann Datei '$output_file' nicht öffnen: $!";
    
    # Schreibe den DOCTYPE
    print $fh "<!doctype html>\n";
    
    # Beginne mit dem HTML-Tag
    print $fh "<html lang=\"de\">\n";
    
    # Schreibe den Head-Bereich
    print $fh "  <head>\n";
    print $fh "    <meta charset=\"UTF-8\" />\n";
    print $fh "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n";
    print $fh "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n";
    print $fh "    <meta name=\"theme-color\" content=\"#ffffff\" />\n";
    print $fh "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n";
    print $fh "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n";
    print $fh "    <title>TikTok LIVE Companion – Dokumentation</title>\n";
    print $fh "  </head>\n";
    
    # Schreibe den Body-Bereich
    print $fh "  <body>\n";
    print $fh "    <div id=\"root\"></div>\n";
    print $fh "    <script type=\"module\" src=\"/src/main.tsx\"></script>\n";
    print $fh "  </body>\n";
    
    # Schließe das HTML-Tag
    print $fh "</html>\n";
    
    # Schließe die Datei
    close($fh);
}

# Hauptprogramm
sub main {
    # Prüfe, ob ein Parameter übergeben wurde
    if (@ARGV != 1) {
        die "Verwendung: $0 <ausgabedatei>\n";
    }
    
    my $output_file = $ARGV[0];
    create_html($output_file);
    
    print "HTML-Datei erfolgreich erstellt: $output_file\n";
}

# Starte das Hauptprogramm
main();
