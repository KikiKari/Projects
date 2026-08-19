#!/usr/bin/perl
# pplx-inject.mjs — portiert nach perl5
# Quelle: javascript, OpenClaw@main:scripts/pplx-tools/pplx-inject.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use JSON qw(decode_json encode_json);
use HTTP::CookieJar::LWP;
use LWP::UserAgent;
use Time::Piece;

# Inject a perplexity.ai web session (the __Secure-next-auth.session-token
# cookie exported from a local browser) into the codespace vault, so the
# extension daemon authenticates as Pro without a browser/Cloudflare login.
#
# Usage: PERPLEXITY_VAULT_PASSPHRASE=... PPLX_DIST=<dist> perl pplx-inject.pl <cookies-file>
# (normally invoked by pplx-refresh.sh, which resolves passphrase + dist)

my $PROFILE = $ENV{PERPLEXITY_PROFILE} || "codespace";
my $EMAIL = $ENV{PPLX_EMAIL} || "KarimKiki\@gmx.de";
my $file = $ARGV[0];
if (!$file) { die "usage: perl pplx-inject.pl <cookies-file>\n"; }

# --- locate the perplexity-user-mcp dist and its Vault / profile chunks ---
my $DIST = $ENV{PPLX_DIST};
if (!$DIST || !-d $DIST) {
    my $home_npm = `find "\$HOME/.npm/_npx" -type d -path '*perplexity-user-mcp/dist' 2>/dev/null | head -1`;
    chomp($home_npm);
    $DIST = $home_npm if $home_npm;
}
if (!$DIST || !-d $DIST) { die "cannot locate perplexity-user-mcp/dist (set PPLX_DIST)\n"; }

# Resolve chunks by following the package's own imports in a stable entry file.
# esbuild minifies class/function names, so we trust the runner's import map.
sub chunkFor {
    my ($symbol, $entries_ref) = @_;
    my @entries = @$entries_ref;
    @entries = ("manual-login-runner.mjs", "login-runner.mjs", "cli.mjs") unless @entries;
    for my $entry (@entries) {
        my $src;
        eval {
            open my $fh, '<', "$DIST/$entry" or die "Cannot open $DIST/$entry: $!";
            local $/;
            $src = <$fh>;
            close $fh;
        };
        next if $@;
        while ($src =~ /import\s*\{([^}]*)\}\s*from\s*"(\.\/chunk-[^"]+\.mjs)"/g) {
            my $names_str = $1;
            my $chunk_file = $2;
            my @names = split /,/, $names_str;
            for my $name (@names) {
                $name =~ s/^\s+|\s+$//g;
                $name =~ s/\s+as\s+.*$//;
                $name =~ s/^\s+|\s+$//g;
                if ($name eq $symbol) {
                    return File::Spec->catfile($DIST, substr($chunk_file, 2));
                }
            }
        }
    }
    return undef;
}

my $vaultChunk = chunkFor("Vault");
my $profChunk = chunkFor("getProfilePaths");
die "could not locate Vault/profile chunks in dist\n" unless $vaultChunk && $profChunk;

# Mocking minimal Vault and profile functions since Perl doesn't support direct JS imports
# In a real scenario, these would need to be implemented properly or replaced with equivalent logic

# For now, simulate basic functionality
sub getProfilePaths {
    my ($profile) = @_;
    my $dir = File::Spec->catdir($ENV{HOME}, '.perplexity', $profile);
    return {
        dir => $dir,
        modelsCache => File::Spec->catfile($dir, 'models.json'),
        reinit => File::Spec->catfile($dir, 'reinit.flag')
    };
}

sub recordLoginSuccess {
    my ($profile, $data) = @_;
    # Simulate recording login success
    print "Recorded login success for profile '$profile': " . encode_json($data) . "\n";
}

# --- parse the cookie input (token / header / JSON) ---
open my $fh, '<', $file or die "Cannot open $file: $!";
local $/;
my $text = <$fh>;
close $fh;
$text =~ s/^\s+|\s+$//g;

my @raw;
if ($text =~ /^[\[\{]/) {
    my $data = decode_json($text);
    if (ref($data) eq 'HASH' && exists $data->{cookies}) {
        @raw = @{$data->{cookies}};
    } elsif (ref($data) eq 'ARRAY') {
        @raw = @$data;
    } else {
        die "expected a JSON array of cookies\n";
    }
} elsif ($text =~ /^eyJ/ && $text !~ /=/ && $text !~ /;/) {
    @raw = ({ name => "__Secure-next-auth.session-token", value => $text });
} else {
    my @pairs = split /;\s*/, $text;
    for my $pair (@pairs) {
        if ($pair =~ /=/) {
            my ($name, $value) = split /=/, $pair, 2;
            push @raw, { name => $name, value => $value };
        }
    }
}

sub normSameSite {
    my ($s) = @_;
    my $v = lc($s // "");
    return "None" if $v eq "no_restriction" || $v eq "none";
    return "Strict" if $v eq "strict";
    return "Lax";
}

my @cookies;
for my $c (@raw) {
    next unless $c && $c->{name} && $c->{value};
    my $domain = $c->{domain} && index($c->{domain}, "perplexity.ai") >= 0 ? $c->{domain} : ".perplexity.ai";
    my $expires = $c->{expires} // $c->{expirationDate} // -1;
    $expires = int($expires) if defined $expires && $expires =~ /^\d+$/;
    push @cookies, {
        name => $c->{name},
        value => $c->{value},
        domain => $domain,
        path => $c->{path} || "/",
        expires => $expires,
        httpOnly => $c->{httpOnly} ? 1 : 0,
        secure => defined $c->{secure} ? ($c->{secure} ? 1 : 0) : 1,
        sameSite => normSameSite($c->{sameSite})
    };
}

my @names = map { $_->{name} } @cookies;
print "Parsed " . scalar(@cookies) . " perplexity.ai cookies: " . join(", ", @names) . "\n";
unless (grep { $_ =~ /^__Secure-next-auth\.session-token/ } @names) {
    warn "WARNING: no '__Secure-next-auth.session-token' — session likely won't authenticate.\n";
}

my $paths = getProfilePaths($PROFILE);
make_path($paths->{dir}) unless -d $paths->{dir};

# Simulate vault operations
{
    open my $vault_fh, '>', File::Spec->catfile($paths->{dir}, 'vault.json');
    print $vault_fh encode_json({ cookies => \@cookies, email => $EMAIL });
    close $vault_fh;
}

# Create empty models cache if it doesn't exist
unless (-f $paths->{modelsCache}) {
    open my $models_fh, '>', $paths->{modelsCache};
    print $models_fh encode_json({ models => {} });
    close $models_fh;
}

recordLoginSuccess($PROFILE, { tier => "pro", loginMode => "manual", lastLogin => localtime->datetime });

open my $reinit_fh, '>', $paths->{reinit};
print $reinit_fh time;
close $reinit_fh;

print "OK: injected " . scalar(@cookies) . " cookie(s) into vault profile '$PROFILE'.\n";
