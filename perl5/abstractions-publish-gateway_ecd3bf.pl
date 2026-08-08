#!/usr/bin/perl
# abstractions-publish-gateway.py — portiert nach perl5
# Quelle: python, Projects@abstractions:python/abstractions-publish-gateway.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
use strict;
use warnings;
use File::Spec;

sub main {
    # Define the path to the actual script
    my $script_path = '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh';
    
    # Check if the script exists
    unless (-e $script_path) {
        print STDERR "Error: Script not found at $script_path\n";
        exit 1;
    }
    
    # Execute the script with all passed arguments
    my @command = ($script_path, @ARGV);
    my $result = system(@command);
    
    if ($result == -1) {
        print STDERR "Error executing script: $!\n";
        exit 1;
    } else {
        my $exit_code = $result >> 8;
        exit $exit_code;
    }
}

main() unless caller;
