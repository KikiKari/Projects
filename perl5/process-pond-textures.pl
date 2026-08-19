#!/usr/bin/perl
# process-pond-textures.py — portiert nach perl5
# Quelle: python, Onboarding@main:scripts/process-pond-textures.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use Image::Magick;

my $BASE = "public/media/pond";
my $OUT = "public/media/pond/processed";

make_path($OUT);

sub key_out {
    my ($path, $out, $mode, $feather) = @_;
    $feather //= 2.0;

    my $im = Image::Magick->new();
    $im->Read($path);
    $im->Set(colorspace => 'RGB');

    my ($width, $height) = $im->Get('width', 'height');
    my @pixels = $im->GetPixels(width => $width, height => $height, map => 'RGB');

    my @alpha;
    for (my $i = 0; $i < @pixels; $i += 3) {
        my ($r, $g, $b) = @pixels[$i, $i+1, $i+2];

        if ($mode eq "green") {
            my $lum = ($r + $g + $b) / 3.0;
            my $bg = $lum < 40.0;
            push @alpha, $bg ? 0 : 255;
        } elsif ($mode eq "white") {
            my $mn = ($r < $g) ? (($r < $b) ? $r : $b) : (($g < $b) ? $g : $b);
            my $mx = ($r > $g) ? (($r > $b) ? $r : $b) : (($g > $b) ? $g : $b);
            my $white = ($mn > 218.0) && (($mx - $mn) < 28.0);
            push @alpha, $white ? 0 : 255;
        } else {
            die "Unknown mode: $mode";
        }
    }

    my $alpha_im = Image::Magick->new(size => "${width}x${height}");
    $alpha_im->Read('xc:black');
    $alpha_im->Set(type => 'Grayscale');
    $alpha_im->Set(pixels => \@alpha, map => 'I');

    # Feather the mask edges to avoid hard aliasing.
    $alpha_im->Blur(sigma => $feather / 2.0);

    $im->Set(matte => 'true');
    $im->Composite(image => $alpha_im, compose => 'CopyOpacity');

    # Bound to content to keep the plane tight and reduce empty texels.
    my @bbox = $alpha_im->GetBoundingBox();
    if (@bbox) {
        $im->Crop(width => $bbox[2], height => $bbox[3], x => $bbox[0], y => $bbox[1]);
    }

    $im->Write(filename => $out, compression => 'Zip');
    my ($out_width, $out_height) = $im->Get('width', 'height');
    printf "%s -> %s [%dx%d] (%s)\n", (split '/', $path)[-1], (split '/', $out)[-1], $out_width, $out_height, $mode;
}

# Lily pads
key_out("$BASE/blaetter/12130585.webp", "$OUT/leaf-a.png", "green");
key_out("$BASE/blaetter/48178242.webp", "$OUT/leaf-b.png", "white");

# Blossoms with white backgrounds -> clean cutouts (only these two key cleanly)
key_out("$BASE/blueten/78370994.webp", "$OUT/blossom-a.png", "white", 3.0);
key_out("$BASE/blueten/70017289.webp", "$OUT/blossom-b.png", "white", 3.0);

print "done\n";
