#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "ce72d23c943eeb2ccc134a7e11ca8479df46e061cb548a72426a3d8555cac91d", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "perl5"}
# extract-tiktok-yt-dlp.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Temp qw(tempdir);
use POSIX qw(strftime);

my $username = $ARGV[0] // '';
$username =~ s/^@//;
my $format = $ARGV[1] // 'best';
my $json_flag = $ARGV[2] // '';
my $timestamp = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
my $tmp_dir = tempdir('/tmp/tiktok-yt-dlp.XXXXXX', CLEANUP => 1);

sub emit_json {
    my %payload = @_;
    my $json = JSON->new->utf8->encode(\%payload);
    print STDERR "$json\n";
}

if ($username !~ /^[A-Za-z0-9._]{1,24}$/) {
    print STDERR "Invalid TikTok username\n";
    exit 64;
}

my @valid_formats = (
    'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
    'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
    'hls-sd/hls-ld/flv-sd/flv-ld',
    'hls-ld/flv-ld',
    'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld'
);
my $format_valid = 0;
for my $valid (@valid_formats) {
    if ($format eq $valid) {
        $format_valid = 1;
        last;
    }
}
unless ($format_valid) {
    print STDERR "Invalid yt-dlp format\n";
    exit 64;
}

open(my $load_fh, '-|', 'uptime') or die "Can't run uptime: $!";
my $load_line = <$load_fh>;
close($load_fh);
my @loads = ($load_line =~ /load averages?: ([\d.]+), ([\d.]+), ([\d.]+)/);
my $load_per_cpu = $loads[0] / ($ENV{TIKTOK_MAX_LOAD_PER_CPU} || 1.5);
my $max_load = $ENV{TIKTOK_MAX_LOAD_PER_CPU} // 1.5;

if ($load_per_cpu > $max_load) {
    emit_json(
        success => JSON::false,
        method => 'yt-dlp',
        username => $username,
        url => '',
        format => $format,
        error => 'host overloaded',
        timestamp => $timestamp,
        status => 'overloaded'
    );
    exit 75;
}

unless (`which yt-dlp 2>/dev/null`) {
    emit_json(
        success => JSON::false,
        method => 'yt-dlp',
        username => $username,
        url => '',
        format => $format,
        error => 'yt-dlp not installed',
        timestamp => $timestamp,
        status => 'dependency_missing'
    );
    exit 2;
}

my $live_url = "https://www.tiktok.com/\@$username/live";
my $stdout_file = "$tmp_dir/stdout.json";
my $stderr_file = "$tmp_dir/stderr.log";

my $exit_code = system("yt-dlp --no-warnings --dump-single-json --skip-download --format '$format' '$live_url' >'$stdout_file' 2>'$stderr_file'");

if ($exit_code != 0) {
    open(my $fh, '<', $stderr_file) or die "Cannot read stderr file: $!";
    my $stderr_content = do { local $/; <$fh> };
    close($fh);
    
    my $status = 'technical_error';
    my $code = 2;
    if ($stderr_content =~ /not currently live|No live cdn found|not available|private video/i) {
        $status = 'offline';
        $code = 1;
    }
    
    my $error_msg = substr($stderr_content, 0, 1000);
    emit_json(
        success => JSON::false,
        method => 'yt-dlp',
        username => $username,
        url => '',
        format => $format,
        error => $error_msg,
        timestamp => $timestamp,
        status => $status
    );
    exit $code;
}

open(my $json_fh, '<', $stdout_file) or die "Cannot read stdout file: $!";
my $json_text = do { local $/; <$json_fh> };
close($json_fh);

my $data = eval { decode_json($json_text) };
if ($@) {
    emit_json(
        success => JSON::false,
        method => 'yt-dlp',
        username => $username,
        url => '',
        format => $format,
        error => 'could not parse JSON response',
        timestamp => $timestamp,
        status => 'offline'
    );
    exit 1;
}

my @candidates = ();
if (exists $data->{url} && defined $data->{url}) {
    push @candidates, $data->{url};
}
if (exists $data->{formats} && ref $data->{formats} eq 'ARRAY') {
    for my $item (@{$data->{formats}}) {
        if (ref $item eq 'HASH' && exists $item->{url} && defined $item->{url}) {
            push @candidates, $item->{url};
        }
    }
}

my $url = '';
for my $value (@candidates) {
    my $low = lc($value);
    if ($value =~ /^https:\/\// && ($low =~ /\.m3u8/ || $low =~ /\.flv/) && $low !~ /only_audio=1/) {
        $url = $value;
        last;
    }
}

if (!$url) {
    emit_json(
        success => JSON::false,
        method => 'yt-dlp',
        username => $username,
        url => '',
        format => $format,
        error => 'could not extract HTTPS video URL',
        timestamp => $timestamp,
        status => 'offline'
    );
    exit 1;
}

if ($json_flag eq '--json') {
    emit_json(
        success => JSON::true,
        method => 'yt-dlp',
        username => $username,
        url => $url,
        format => $format,
        error => '',
        timestamp => $timestamp,
        status => 'live'
    );
} else {
    print "$url\n";
}
