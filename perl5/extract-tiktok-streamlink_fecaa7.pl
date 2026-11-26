#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "09c87bbd41193395a92acb788320ad44950b99afa9469329b9c1473dbf496c83", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "perl5"}
# extract-tiktok-streamlink.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use Time::Piece;

# Bounded fallback used by the enhanced extractor. Output is normalized again
# by tiktok-get-stream.js; standalone success must remain URL-only unless
# --json is requested. Exit 75 means preflight overload.

my $USERNAME = $ARGV[0] // '';
$USERNAME =~ s/^@//;
my $QUALITY = $ARGV[1] // 'best';
my $JSON_FLAG = $ARGV[2] // '';
my $TIMESTAMP = gmtime->strftime('%Y-%m-%dT%H:%M:%SZ');

sub emit_json {
    my %payload = @_;
    print encode_json(\%payload) . "\n";
}

if ($USERNAME !~ /^[A-Za-z0-9._]{1,24}$/) {
    warn "Invalid TikTok username\n";
    exit 64;
}

unless ($QUALITY =~ /^(best|worst|original|1080p60|720p60|720p|540p|360p|auto)$/) {
    warn "Invalid stream quality\n";
    exit 64;
}

# Get load per CPU (approximation using uptime)
my $load_per_cpu = 0;
if (open(my $fh, '<', '/proc/loadavg')) {
    my $line = <$fh>;
    close $fh;
    if ($line =~ /^([\d.]+)/) {
        my $load = $1;
        my $cpus = 1;
        if (open(my $cpu_fh, '<', '/proc/cpuinfo')) {
            my $count = 0;
            while (<$cpu_fh>) {
                $count++ if /^processor\s+:/;
            }
            close $cpu_fh;
            $cpus = $count || 1;
        }
        $load_per_cpu = $load / $cpus;
    }
} else {
    # Fallback if /proc/loadavg is not available
    $load_per_cpu = 0;
}

my $max_load = $ENV{'TIKTOK_MAX_LOAD_PER_CPU'} // 1.5;
if ($load_per_cpu > $max_load) {
    emit_json(
        success => JSON::false,
        method => "streamlink",
        username => $USERNAME,
        quality => $QUALITY,
        error => "host overloaded",
        timestamp => $TIMESTAMP,
        status => "overloaded"
    );
    exit 75;
}

# Check if streamlink exists
unless (`which streamlink 2>/dev/null`) {
    emit_json(
        success => JSON::false,
        method => "streamlink",
        username => $USERNAME,
        quality => $QUALITY,
        error => "streamlink not installed",
        timestamp => $TIMESTAMP,
        status => "dependency_missing"
    );
    exit 2;
}

my $LIVE_URL = "https://www.tiktok.com/\@$USERNAME/live";

# Quality selector mapping
my %selector_map = (
    'original' => 'origin,uhd_60,hd_60,hd,sd,ld,best,worst',
    'auto' => 'best,origin,uhd_60,hd_60,hd,sd,ld,worst',
    '1080p60' => 'uhd_60,hd_60,hd,sd,ld,worst',
    '720p60' => 'hd_60,hd,sd,ld,worst',
    '720p' => 'hd,sd,ld,worst',
    '540p' => 'sd,ld,worst',
    '360p' => 'ld,worst'
);

my $SELECTOR = $selector_map{$QUALITY} // $QUALITY;

# Try to get JSON output first
my $output = `streamlink --json '$LIVE_URL' '$SELECTOR' 2>/dev/null`;
my $exit_code = $? >> 8;

if ($exit_code != 0 || !$output) {
    # Fallback to stream-url
    my $url = `streamlink --stream-url '$LIVE_URL' '$SELECTOR' 2>/dev/null`;
    chomp $url;
    if ($? >> 8 != 0 || !$url) {
        emit_json(
            success => JSON::false,
            method => "streamlink",
            username => $USERNAME,
            quality => $QUALITY,
            error => "streamlink failed or no stream found",
            timestamp => $TIMESTAMP,
            status => "offline"
        );
        exit 1;
    }
    
    if ($JSON_FLAG eq "--json") {
        emit_json(
            success => JSON::true,
            method => "streamlink",
            username => $USERNAME,
            url => $url,
            quality => $QUALITY,
            timestamp => $TIMESTAMP,
            status => "live"
        );
    } else {
        print "$url\n";
    }
    exit 0;
}

# Parse JSON output
my $parsed_data;
eval {
    $parsed_data = decode_json($output);
};
if ($@) {
    emit_json(
        success => JSON::false,
        method => "streamlink",
        username => $USERNAME,
        quality => $QUALITY,
        error => "invalid streamlink JSON",
        timestamp => $TIMESTAMP,
        status => "technical_error"
    );
    exit 2;
}

# Extract URL from parsed data
my $url = $parsed_data->{url} // '';
my $streams = $parsed_data->{streams} // {};
my $metadata = $parsed_data->{metadata} // {};

if (!$url && ref($streams) eq 'HASH') {
    my @keys = ('best', 'worst', keys %$streams);
    for my $key (@keys) {
        my $value = $streams->{$key};
        if (ref($value) eq 'HASH' && $value->{url}) {
            $url = $value->{url};
            last;
        }
    }
}

my $author = $metadata->{author} // '';
my $title = $metadata->{title} // '';

if (!$url) {
    emit_json(
        success => JSON::false,
        method => "streamlink",
        username => $USERNAME,
        quality => $QUALITY,
        author => $author,
        title => $title,
        error => "could not extract stream URL",
        timestamp => $TIMESTAMP,
        status => "offline"
    );
    exit 1;
}

if ($JSON_FLAG eq "--json") {
    emit_json(
        success => JSON::true,
        method => "streamlink",
        username => $USERNAME,
        url => $url,
        quality => $QUALITY,
        author => $author,
        title => $title,
        timestamp => $TIMESTAMP,
        status => "live"
    );
} else {
    print "$url\n";
}
