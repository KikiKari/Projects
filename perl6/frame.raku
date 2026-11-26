#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "fa1e258ae1292ab255e8a26318bd53c538ca6cec5ea8fa220636ed9eee17e4f8", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "perl6"}
# frame.sh — portiert nach perl6
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

sub usage() {
    note q:to/EOF/;
    Usage:
      frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

    Examples:
      frame.sh video.mp4 --out /tmp/frame.jpg
      frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
      frame.sh video.mp4 --index 0 --out /tmp/frame0.png
    EOF
    exit 2;
}

sub MAIN($in? is copy, *@args) {
    if !$in || $in eq '-h' || $in eq '--help' {
        usage();
    }

    my $time = "";
    my $index = "";
    my $out = "";

    my @argv = @args;
    while @argv.elems > 0 {
        given @argv[0] {
            when '--time' {
                $time = @argv[1] // "";
                @argv.shift; @argv.shift;
            }
            when '--index' {
                $index = @argv[1] // "";
                @argv.shift; @argv.shift;
            }
            when '--out' {
                $out = @argv[1] // "";
                @argv.shift; @argv.shift;
            }
            default {
                note "Unknown arg: $_";
                usage();
            }
        }
    }

    if !"$in".IO.f {
        note "File not found: $in";
        exit 1;
    }

    if $out eq "" {
        note "Missing --out";
        usage();
    }

    # Create directory for output file
    my $outdir = $out.IO.dirname;
    unless $outdir eq '.' {
        mkdir $outdir unless $outdir.IO.d;
    }

    my @cmd;
    if $index ne "" {
        @cmd = <ffmpeg -hide_banner -loglevel error -y -i>, $in, 
               <-vf select=eq(n\,>, $index, <-vframes 1>, $out;
    } elsif $time ne "" {
        @cmd = <ffmpeg -hide_banner -loglevel error -y -ss>, $time,
               <-i>, $in, <-frames:v 1>, $out;
    } else {
        @cmd = <ffmpeg -hide_banner -loglevel error -y -i>, $in,
               <-vf select=eq(n\,0) -vframes 1>, $out;
    }

    run(@cmd);
    say $out;
}
