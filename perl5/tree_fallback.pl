#!/usr/bin/env perl
# tree_fallback.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:db-maintainer/scripts/tree_fallback.py
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use POSIX qw(strftime);
use File::Path qw(make_path);

# Konfiguration
my $WORKSPACE = "/workspace";
my $DEPTH = 6;
my %SKIP = map { $_ => 1 } qw(.git node_modules __pycache__ venv .cache .npm .local);
my $OUT_DIR = File::Spec->catdir($WORKSPACE, "important");
my $OUT_FILE = File::Spec->catfile($OUT_DIR, "openclaw-tree.txt");

sub walk {
    my ($path, $prefix, $depth) = @_;
    $prefix //= "";
    $depth //= 0;
    
    my @lines = ();
    return @lines if $depth >= $DEPTH;
    
    # Verzeichnisinhalt lesen und sortieren
    opendir(my $dh, $path) or return @lines;
    my @entries = readdir($dh);
    closedir($dh);
    
    # Filtern und Sortieren
    @entries = grep { !exists $SKIP{$_} && $_ ne '.' && $_ ne '..' } @entries;
    @entries = sort {
        # Verzeichnisse zuerst, dann nach Name
        my $a_is_dir = -d File::Spec->catfile($path, $a);
        my $b_is_dir = -d File::Spec->catfile($path, $b);
        !$a_is_dir <=> !$b_is_dir || $a cmp $b
    } @entries;
    
    for my $i (0 .. $#entries) {
        my $entry = $entries[$i];
        my $last = ($i == $#entries);
        my $connector = $last ? "└── " : "├── ";
        my $full_entry_path = File::Spec->catfile($path, $entry);
        my $suffix = (-d $full_entry_path) ? "/" : "";
        push @lines, "${prefix}${connector}${entry}${suffix}";
        
        if (-d $full_entry_path && !-l $full_entry_path) {
            my $extension = $last ? "    " : "│   ";
            push @lines, walk($full_entry_path, $prefix . $extension, $depth + 1);
        }
    }
    
    return @lines;
}

sub main {
    my @lines = ($WORKSPACE);
    push @lines, walk($WORKSPACE);
    my $body = join("\n", @lines) . "\n";
    my $timestamp = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    my $header = "# OpenClaw Workspace Tree\n"
               . "# Generiert: ${timestamp}\n"
               . "# Fallback (tree binary nicht verfuegbar), Tiefe ${DEPTH}\n"
               . "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
    
    # Ausgabeverzeichnis erstellen
    make_path($OUT_DIR, { verbose => 0 });
    
    # In Datei schreiben
    open(my $fh, '>', $OUT_FILE) or die "Kann $OUT_FILE nicht öffnen: $!";
    print $fh $header . $body;
    close($fh);
    
    print "openclaw-tree.txt aktualisiert (Fallback): ${OUT_FILE} (" . scalar(@lines) . " Einträge)\n";
}

main() if __FILE__ eq $0;
