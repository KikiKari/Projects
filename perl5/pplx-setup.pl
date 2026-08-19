#!/usr/bin/env perl
# pplx-setup.sh — portiert nach perl5
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Glob ':glob';
use File::Spec;
use Cwd 'abs_path';

# One-time (idempotent): make sure the Perplexity VS Code extension daemon can
# find a Chromium. The daemon uses its OWN bundled patchright, which pins a
# specific chromium revision; install exactly that revision.

my $home = $ENV{HOME} // die "HOME environment variable not set\n";

# Find the latest patchright directory
my @extpr_dirs = bsd_glob("$home/.vscode-remote/extensions/nskha.perplexity-vscode-*/dist/node_modules/patchright");
@extpr_dirs = sort { version_compare($a, $b) } @extpr_dirs;

my $extpr = @extpr_dirs ? $extpr_dirs[-1] : undef;

if (!defined $extpr) {
    print "[setup] extension patchright not found — is the Perplexity extension installed?\n";
    exit 0;
}

# Try to get the executable path
my $exp = `node -e "const {chromium}=require('$extpr');console.log(chromium.executablePath())" 2>/dev/null`;
chomp $exp;
$exp ||= '';

if ($exp ne '' && -x $exp) {
    print "[setup] daemon browser already present: $exp\n";
    exit 0;
}

print "[setup] installing matching chromium for the extension daemon (expected: " . ($exp || 'unknown') . ")...\n";
system("node", "$extpr/cli.js", "install", "chromium") == 0 or die "Failed to install chromium\n";
print "[setup] done.\n";

sub version_compare {
    my ($a, $b) = @_;
    # Extract version numbers from paths like "...perplexity-vscode-1.2.3/..."
    my ($ver_a) = $a =~ /perplexity-vscode-(\d+(?:\.\d+)*)/;
    my ($ver_b) = $b =~ /perplexity-vscode-(\d+(?:\.\d+)*)/;
    
    return 0 if !defined $ver_a && !defined $ver_b;
    return -1 if !defined $ver_a;
    return 1 if !defined $ver_b;
    
    # Compare version strings
    my @parts_a = split /\./, $ver_a;
    my @parts_b = split /\./, $ver_b;
    
    for my $i (0 .. $#parts_a) {
        return -1 if $i > $#parts_b;
        my $cmp = $parts_a[$i] <=> $parts_b[$i];
        return $cmp if $cmp != 0;
    }
    
    return @parts_a <=> @parts_b;
}
