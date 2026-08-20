#!/usr/bin/perl
# test_node3.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/test_node3.sh
# auch in: OpenClaw@gateway2:scripts/test_node3.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Env qw(@PATH);
use IPC::Run3;

# Test Node 3 Connection
$ENV{OPENCLAW_ALLOW_INSECURE_PRIVATE_WS} = 1;
print "Starting node connection test...\n";

my @cmd = ('timeout', '15', '/usr/local/bin/openclaw', 'node', 'run', '--host', '152.53.145.65', '--port', '18789');
my ($stdout, $stderr, $exit_code);

eval {
    run3(\@cmd, \$stdin, \$stdout, \$stderr);
    $exit_code = $? >> 8;
};

if ($@) {
    print "Error running command: $@\n";
    exit 1;
}

print $stdout if defined $stdout;
print $stderr if defined $stderr;
print "Exit code: $exit_code\n";
