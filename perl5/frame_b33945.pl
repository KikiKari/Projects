#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "acb387567b89ae3e3d22811590fb1cbcb3e0f7600369174a80bc655a0af8bd57", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "perl5"}
# frame.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename qw(dirname);
use File::Path qw(make_path);

sub usage {
    print STDERR <<'EOF';
Usage:
  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.sh video.mp4 --out /tmp/frame.jpg
  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.sh video.mp4 --index 0 --out /tmp/frame0.png
EOF
    exit 2;
}

usage() if @ARGV == 0 || $ARGV[0] eq '-h' || $ARGV[0] eq '--help';

my $in = shift @ARGV;

my ($time, $index, $out);
GetOptions(
    'time=s'  => \$time,
    'index=s' => \$index,
    'out=s'   => \$out,
) or usage();

if (!defined $in || !-f $in) {
    print STDERR "File not found: $in\n" if defined $in;
    usage();
}

if (!defined $out || $out eq '') {
    print STDERR "Missing --out\n";
    usage();
}

my $outdir = dirname($out);
make_path($outdir) or die "Could not create directory $outdir: $!";

my @cmd;
if (defined $index && $index ne '') {
    @cmd = (
        'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-i', $in,
        '-vf', "select=eq(n\\,$index)",
        '-vframes', '1',
        $out
    );
} elsif (defined $time && $time ne '') {
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

system(@cmd) == 0 or die "ffmpeg command failed: $?";

print "$out\n";
