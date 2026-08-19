#!/usr/bin/env perl
# pplx-refresh.sh — portiert nach perl5
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-refresh.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use JSON;

# Refresh the codespace Perplexity session from a locally-exported cookie.
#
# Usage:
#   ./pplx-refresh.sh [cookie-file]
#
# cookie-file defaults to ~/pplx-cookies.txt. Put your local browser's
# __Secure-next-auth.session-token value (raw), or the whole Cookie header,
# or a JSON cookie export, into that file first.
#
# Steps: ensure daemon browser -> read daemon passphrase -> inject into vault
#        -> trigger reinit -> verify authenticated.

my $here = dirname(abs_path($0));
my $cfg = $ENV{PERPLEXITY_CONFIG_DIR} // "$ENV{HOME}/.perplexity-mcp";
my $profile = $ENV{PERPLEXITY_PROFILE} // "codespace";
my $cookie_file = $ARGV[0] // "$ENV{HOME}/pplx-cookies.txt";

unless (-s $cookie_file) {
    print STDERR "✗ Cookie file empty/missing: $cookie_file\n";
    print STDERR "  Export __Secure-next-auth.session-token from your local browser\n";
    print STDERR "  (DevTools → Application → Cookies → www.perplexity.ai) into that file.\n";
    exit 1;
}

# 1. ensure the extension daemon has a usable browser (idempotent)
system("bash", "$here/pplx-setup.sh");
die "Setup failed: $?" if $? != 0;

# 2. daemon pid + vault passphrase (never guessed — read from the live daemon)
my $lock = "$cfg/daemon.lock";
unless (-f $lock) {
    print STDERR "✗ no daemon.lock at $lock — is the extension running?\n";
    exit 1;
}
open my $fh, '<', $lock or die "Cannot open $lock: $!";
my $json_text = do { local $/; <$fh> };
close $fh;
my $data = decode_json($json_text);
my $pid = $data->{pid};

unless (kill(0, $pid)) {
    print STDERR "✗ daemon pid $pid not running\n";
    exit 1;
}

my $pass = '';
{
    open my $env_fh, '<', "/proc/$pid/environ" or die "Cannot open /proc/$pid/environ: $!";
    local $/;
    my $env_data = <$env_fh>;
    close $env_fh;
    my @env_vars = split("\0", $env_data);
    for my $var (@env_vars) {
        if ($var =~ /^PERPLEXITY_VAULT_PASSPHRASE=(.*)$/) {
            $pass = $1;
            last;
        }
    }
}
unless ($pass) {
    print STDERR "✗ no PERPLEXITY_VAULT_PASSPHRASE in daemon env\n";
    exit 1;
}

# 3. locate the perplexity-user-mcp dist (populate npx cache if needed)
my $dist = '';
{
    opendir(my $dh, "$ENV{HOME}/.npm/_npx") or die "Cannot open directory: $!";
    while (readdir $dh) {
        my $entry = $_;
        next unless -d "$ENV{HOME}/.npm/_npx/$entry";
        my $full_path = "$ENV{HOME}/.npm/_npx/$entry";
        opendir(my $sub_dh, $full_path) or next;
        while (readdir $sub_dh) {
            my $sub_entry = $_;
            if (-d "$full_path/$sub_entry" && $sub_entry eq 'dist') {
                if ($full_path =~ /perplexity-user-mcp/) {
                    $dist = "$full_path/$sub_entry";
                    last;
                }
            }
        }
        closedir $sub_dh;
        last if $dist;
    }
    closedir $dh;
}

unless ($dist) {
    system("npx", "-y", "perplexity-user-mcp", "--version");
    # Try again after installing
    opendir(my $dh, "$ENV{HOME}/.npm/_npx") or die "Cannot open directory: $!";
    while (readdir $dh) {
        my $entry = $_;
        next unless -d "$ENV{HOME}/.npm/_npx/$entry";
        my $full_path = "$ENV{HOME}/.npm/_npx/$entry";
        opendir(my $sub_dh, $full_path) or next;
        while (readdir $sub_dh) {
            my $sub_entry = $_;
            if (-d "$full_path/$sub_entry" && $sub_entry eq 'dist') {
                if ($full_path =~ /perplexity-user-mcp/) {
                    $dist = "$full_path/$sub_entry";
                    last;
                }
            }
        }
        closedir $sub_dh;
        last if $dist;
    }
    closedir $dh;
}

# 4. inject
{
    local %ENV = %ENV;
    $ENV{PERPLEXITY_VAULT_PASSPHRASE} = $pass;
    $ENV{PERPLEXITY_CONFIG_DIR} = $cfg;
    $ENV{PERPLEXITY_PROFILE} = $profile;
    $ENV{PPLX_DIST} = $dist;
    system("node", "$here/pplx-inject.mjs", $cookie_file);
    die "Inject failed: $?" if $? != 0;
}

# 5. trigger daemon reinit
{
    open my $fh, '>', "$cfg/profiles/$profile/.reinit" or die "Cannot write .reinit: $!";
    print $fh time();
    close $fh;
}
print "→ reinit triggered, waiting for daemon...\n";

# 6. verify
my $stat = "$cfg/profiles/$profile/daemon-status.json";
for my $i (1..20) {
    sleep(1.5);
    my ($auth, $tier);
    eval {
        open my $fh, '<', $stat or die "Cannot open $stat: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        my $json_data = decode_json($content);
        $auth = $json_data->{authenticated};
        $tier = $json_data->{tier};
    };
    if (defined($auth) && $auth eq 'True') {
        print "✅ authenticated — tier: $tier\n";
        exit 0;
    }
}
print STDERR "⚠️  not authenticated yet. Check: tail -20 $cfg/daemon.log\n";
exit 1;
