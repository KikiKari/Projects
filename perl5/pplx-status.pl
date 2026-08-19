#!/usr/bin/env perl
# pplx-status.sh — portiert nach perl5
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-status.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json);
use File::Spec;
use File::Basename;

# Quick status of the codespace Perplexity daemon session.

my $CFG = $ENV{'PERPLEXITY_CONFIG_DIR'} // (glob('~/.perplexity-mcp'))[0];
my $PROFILE = $ENV{'PERPLEXITY_PROFILE'} // 'codespace';
my $STAT = File::Spec->catfile($CFG, 'profiles', $PROFILE, 'daemon-status.json');

if (-f $STAT) {
    open my $fh, '<', $STAT or die "Cannot open $STAT: $!";
    my $json_text = do { local $/; <$fh> };
    close $fh;
    
    my $data = decode_json($json_text);
    print to_json($data, { pretty => 1 }), "\n";
} else {
    print "no daemon-status.json at $STAT\n";
}

print "--- recent auth lines ---\n";
my $log_file = File::Spec->catfile($CFG, 'daemon.log');
if (-f $log_file) {
    open my $fh, '<', $log_file or die "Cannot open $log_file: $!";
    my @lines = <$fh>;
    close $fh;
    
    # Filter lines matching the patterns (case insensitive)
    my @filtered = grep { 
        /Authenticated as user/i || 
        /Account tier/i || 
        /Injected .* cookies/i || 
        /Reinit requested/i || 
        /not-logged-in/i 
    } @lines;
    
    # Print last 6 lines
    my $count = scalar @filtered;
    my $start = ($count > 6) ? $count - 6 : 0;
    for my $i ($start .. $count - 1) {
        print $filtered[$i];
    }
}
