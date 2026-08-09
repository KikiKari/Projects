#!/usr/bin/perl
# optimize-media.mjs — portiert nach perl5
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Find;
use File::Basename;
use Image::Magick;

# Verzeichnis festlegen
my $directory = "public/media";

# Alle Dateien im Verzeichnis durchsuchen
opendir(my $dh, $directory) or die "Konnte Verzeichnis nicht öffnen: $!";
my @files = readdir($dh);
closedir($dh);

foreach my $file (@files) {
    # Nur PNG-Dateien verarbeiten
    next unless $file =~ /\.png$/;
    
    my $source = "$directory/$file";
    my $stem = basename($file, ".png");
    
    # WebP-Erstellung
    my $webp_image = Image::Magick->new;
    $webp_image->Read($source);
    $webp_image->Set quality => 84;
    $webp_image->Write("$directory/$stem.webp");
    
    # AVIF-Erstellung
    my $avif_image = Image::Magick->new;
    $avif_image->Read($source);
    $avif_image->Set quality => 58;
    $avif_image->Write("$directory/$stem.avif");
}

print "WebP- und AVIF-Derivate erzeugt.\n";
