#!/usr/bin/perl
# test_sync.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/test_sync.py
# auch in: OpenClaw@gateway2:scripts/test_sync.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Test für Sync-Script

use lib '/home/openclaw/.openclaw/workspace/scripts';
require 'sync_clawhub_git.pl';

# Test: db-maintainer ClawHub → Git (DRY-RUN)
print "=== TEST: db-maintainer sync (DRY-RUN) ===\n";
my $skill = "db-maintainer";
my $result = sync_to_git($skill, 1); # dry_run = true
print "Result: " . ($result ? 'SUCCESS' : 'FAILED') . "\n";
print "\n=== LOG-Inhalt ===\n";
open(my $fh, '<', '/home/openclaw/.openclaw/workspace/logs/sync.log') or die "Kann Log-Datei nicht öffnen: $!";
while (my $line = <$fh>) {
    print $line;
}
close($fh);
