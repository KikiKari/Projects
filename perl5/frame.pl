#!/usr/bin/env perl
# frame.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path);
use Pod::Usage;

my $usage = sub {
    print STDERR <<'EOF';
Usage:
  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.sh video.mp4 --out /tmp/frame.jpg
  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.sh video.mp4 --index 0 --out /tmp/frame0.png
EOF
    exit 2;
};

my $help = 0;
my $time = "";
my $index = "";
my $out = "";

GetOptions(
    'help|h'  => \$help,
    'time=s'  => \$time,
    'index=s' => \$index,
    'out=s'   => \$out,
) or $usage->();

if ($help || @ARGV == 0) {
    $usage->();
}

my $in = $ARGV[0];

if (!defined $in || !-f $in) {
    print STDERR "File not found: $in\n";
    exit 1;
}

if ($out eq "") {
    print STDERR "Missing --out\n";
    $usage->();
}

my $outdir = dirname($out);
make_path($outdir) unless -d $outdir;

my @cmd;
if ($index ne "") {
    @cmd = (
        'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-i', $in,
        '-vf', "select=eq(n\\,$index)",
        '-vframes', '1',
        $out
    );
} elsif ($time ne "") {
    @cmd = (
        'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-ss', $time,
        '-i', $in,
        '-frames:v', '1',
        $out
    );
} else {
    @cmd = (
        'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-i', $in,
        '-vf', 'select=eq(n\\,0)',
        '-vframes', '1',
        $out
    );
}

system(@cmd) == 0 or die "ffmpeg failed: $?";

print "$out\n";
