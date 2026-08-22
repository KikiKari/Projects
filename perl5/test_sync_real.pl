#!/usr/bin/perl
# test_sync_real.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/test_sync_real.py
# auch in: OpenClaw@gateway2:scripts/test_sync_real.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Test echte Synchronisation

use lib '/home/openclaw/.openclaw/workspace/scripts';
require sync_clawhub_git;

# Test: db-maintainer ClawHub → Git (ECHT)
print "=== TEST: db-maintainer sync (REAL) ===\n";
my $skill = "db-maintainer";
my $result = sync_clawhub_git::sync_to_git($skill, 0);  # dry_run = false
print "Result: " . ($result ? "SUCCESS" : "FAILED") . "\n";

# Prüfe Ergebnis
my $target = "/home/openclaw/.openclaw/workspace/git/skills/db-maintainer";
if (-d $target) {
    print "\n✅ Git-Repo erstellt: $target\n";
    
    # Rekursiv durch das Verzeichnis gehen und Baumstruktur ausgeben
    sub list_dir {
        my ($dir, $level) = @_;
        opendir(my $dh, $dir) or die "Konnte Verzeichnis $dir nicht öffnen: $!";
        my @entries = readdir($dh);
        closedir($dh);
        
        for my $entry (sort @entries) {
            next if $entry eq '.' or $entry eq '..';
            my $full_path = "$dir/$entry";
            my $indent = " " x (2 * $level);
            
            if (-d $full_path) {
                print "${indent}${entry}/\n";
                list_dir($full_path, $level + 1);
            } else {
                print "${indent}  ${entry}\n";
            }
        }
    }
    
    list_dir($target, 0);
}
