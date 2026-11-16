#!/usr/bin/env perl
# abstractions-manager-cron.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Fcntl qw(:flock);
use IPC::Open3;
use Symbol 'gensym';

# Set PATH
$ENV{PATH} = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin";

# Load environment variables
my $env_file = "/home/openclaw/.openclaw/.env";
if (-f $env_file) {
    open(my $fh, '<', $env_file) or die "Cannot open $env_file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/;  # Skip comments
        next if $line =~ /^\s*$/;  # Skip empty lines
        if ($line =~ /^([^=]+)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            # Remove quotes if present
            $value =~ s/^["'](.*)["']$/$1/;
            $ENV{$key} = $value;
        }
    }
    close($fh);
}

# Check required environment variable
die "OPENROUTER_API_KEY fehlt\n" unless defined $ENV{OPENROUTER_API_KEY};

# Set GITHUB_TOKEN with fallback logic
$ENV{GITHUB_TOKEN} //= $ENV{GH_TOKEN} // $ENV{GH_ACCESS_TOKEN} // '';

# Lock file path
my $lock_file = "/home/openclaw/.openclaw/locks/abstractions-manager.lock";

# Open lock file
open(my $lock_fh, '>', $lock_file) or die "Cannot create lock file $lock_file: $!";

# Try to get exclusive lock (non-blocking)
unless (flock($lock_fh, LOCK_EX | LOCK_NB)) {
    die "Another instance is already running\n";
}

# Script to execute
my $script = "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py";

# Check if script exists
die "Script not found: $script\n" unless -f $script;

# Execute the Python script with passed arguments
my @cmd = ('/usr/bin/python3', $script, @ARGV);

# Redirect stderr to stdout for consistent error handling
my $stderr = gensym;
my $pid = open3(\*STDIN, \*STDOUT, $stderr, @cmd);

# Wait for process completion
waitpid($pid, 0);
my $exit_code = $? >> 8;

# Close lock file (automatically released)
close($lock_fh);

# Exit with the same code as the executed script
exit($exit_code);
