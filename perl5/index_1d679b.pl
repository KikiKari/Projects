#!/usr/bin/perl
# index.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter: Name der Ausgabedatei
my $output_file = shift @ARGV or die "Usage: $0 <output_file>\n";

# Öffne die Ausgabedatei zum Schreiben
open my $fh, '>', $output_file or die "Kann Datei '$output_file' nicht öffnen: $!\n";

# Schreibe das HTML-Dokument strukturiert
print $fh "<!doctype html>\n";
print $fh "<html lang=\"de\">\n";
print $fh "  <head>\n";
print $fh "    <meta charset=\"UTF-8\" />\n";
print $fh "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n";
print $fh "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n";
print $fh "    <meta name=\"theme-color\" content=\"#ffffff\" />\n";
print $fh "    <title>TikTok LIVE Companion – Dokumentation</title>\n";
print $fh "  </head>\n";
print $fh "  <body>\n";
print $fh "    <div id=\"root\"></div>\n";
print $fh "    <script type=\"module\" src=\"/src/main.tsx\"></script>\n";
print $fh "  </body>\n";
print $fh "</html>\n";

# Schließe die Datei
close $fh or warn "Konnte Datei '$output_file' nicht schließen: $!\n";
