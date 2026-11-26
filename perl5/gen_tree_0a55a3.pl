#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "0243ccb02f3ac69b44c4203dab76370af929a10380d65aa8dd0b3743ef9269d2", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "perl5"}
# gen_tree.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use POSIX qw(strftime);

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

my $ROOT = "/workspace";
my $OUT = "/workspace/important/openclaw-tree.txt";
my $MAX_DEPTH = 6;

sub collect {
    my ($path, $prefix, $depth) = @_;
    $prefix //= "";
    $depth //= 1;
    
    my @lines = ();
    my @entries;
    
    # Try to read directory entries
    if (opendir(my $dh, $path)) {
        @entries = readdir($dh);
        closedir($dh);
        # Filter out . and .., then sort
        @entries = sort grep { $_ ne '.' && $_ ne '..' } @entries;
    } else {
        return @lines; # Return empty list on error
    }
    
    my $total = scalar @entries;
    for my $i (0..$#entries) {
        my $name = $entries[$i];
        my $is_last = ($i == $#entries);
        my $connector = $is_last ? "└── " : "├── ";
        push @lines, $prefix . $connector . $name;
        
        my $full = File::Spec->catfile($path, $name);
        if ($depth < $MAX_DEPTH && -d $full && !-l $full) {
            my $next_prefix = $prefix . ($is_last ? "    " : "│   ");
            push @lines, collect($full, $next_prefix, $depth + 1);
        }
    }
    
    return @lines;
}

my @body = collect($ROOT);
my $timestamp = strftime("%Y-%m-%dT%H:%M:%S", localtime);
my $header = 
    "# OpenClaw Workspace Tree\n" .
    "# Generiert: $timestamp\n" .
    "# Befehl: tree -a -L 6 $ROOT (emuliert via gen_tree.py)\n" .
    "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

my $content = $header . ".\n" . join("\n", @body) . "\n";

open(my $fh, '>:encoding(UTF-8)', $OUT) or die "Could not open file '$OUT': $!";
print $fh $content;
close($fh);

my $line_count = scalar(@body) + 1;
my $byte_count = length($content);
print "written $OUT: $line_count lines, $byte_count bytes\n";
