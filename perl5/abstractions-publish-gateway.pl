#!/usr/bin/perl
# abstractions-publish-gateway.js — portiert nach perl5
# Quelle: javascript, Projects@abstractions:javascript/abstractions-publish-gateway.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstractions-publish-gateway.sh — portiert nach javascript
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.

my $script_path = '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh';

# Remove the script name from @ARGV to pass only the arguments
my @args = @ARGV;

# Execute the script with the provided arguments
my $exit_code = system($script_path, @args);

# Check if the command executed successfully
if ($exit_code == -1) {
    die "Failed to execute script: $!\n";
} elsif ($exit_code & 127) {
    printf "Script died with signal %d, %s coredump\n",
        ($exit_code & 127), ($exit_code & 128) ? 'with' : 'without';
} else {
    my $exit_value = $exit_code >> 8;
    exit $exit_value;
}
