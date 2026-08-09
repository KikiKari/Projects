#!/usr/bin/env perl
# extract-tiktok-yt-dlp.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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
    my (@args) = @_;
    my @keys = qw(success method username url format error timestamp status);
    my %payload;
    for my $i (0 .. $#keys) {
        if (defined $args[$i] && $args[$i] ne '') {
            $payload{$keys[$i]} = $args[$i];
        }
    }
    if (exists $payload{success}) {
        $payload{success} = lc($payload{success}) eq 'true';
    }
    print STDERR to_json(\%payload, { utf8 => 1 }) . "\n";
}

if ($username !~ /^[A-Za-z0-9._]{1,24}$/) {
    print STDERR "Invalid TikTok username\n";
    exit 64;
}

my %valid_formats = map { $_ => 1 } qw(
    hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld
    hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld
    hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld
    hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld
    hls-sd/hls-ld/flv-sd/flv-ld
    hls-ld/flv-ld
    hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld
);
unless (exists $valid_formats{$format}) {
    print STDERR "Invalid yt-dlp format\n";
    exit 64;
}

my $load_per_cpu = qx(uname -s | grep -q Linux && cat /proc/loadavg | cut -d' ' -f1 | awk '{print \$1/' . (qx(nproc 2>/dev/null || echo 1) =~ s/\s+//r) . '}');
chomp $load_per_cpu;
$load_per_cpu = 0 if $load_per_cpu eq '';
my $max_load = $ENV{TIKTOK_MAX_LOAD_PER_CPU} // 1.5;
if ($load_per_cpu > $max_load) {
    emit_json("false", "yt-dlp", $username, "", $format, "host overloaded", $timestamp, "overloaded");
    exit 75;
}

unless (`which yt-dlp 2>/dev/null`) {
    emit_json("false", "yt-dlp", $username, "", $format, "yt-dlp not installed", $timestamp, "dependency_missing");
    exit 2;
}

my $live_url = "https://www.tiktok.com/\@$username/live";
my $stdout_file = "$tmp_dir/stdout.json";
my $stderr_file = "$tmp_dir/stderr.log";
my $exit_code = system("yt-dlp --no-warnings --dump-single-json --skip-download --format '$format' '$live_url' >'$stdout_file' 2>'$stderr_file'");

if ($exit_code != 0) {
    my $status = 'technical_error';
    my $code = 2;
    open my $fh, '<', $stderr_file or die "Cannot open $stderr_file: $!";
    my $stderr_content = do { local $/; <$fh> };
    close $fh;
    if ($stderr_content =~ /not currently live|No live cdn found|not available|private video/i) {
        $status = 'offline';
        $code = 1;
    }
    my $error_msg = substr($stderr_content, 0, 1000);
    emit_json("false", "yt-dlp", $username, "", $format, $error_msg, $timestamp, $status);
    exit $code;
}

my $url = '';
if (open my $fh, '<', $stdout_file) {
    my $json_text = do { local $/; <$fh> };
    close $fh;
    eval {
        my $data = decode_json($json_text);
        my @candidates;
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
        for my $value (@candidates) {
            my $low = lc($value);
            if ($value =~ /^https:\/\// && ($low =~ /\.m3u8/ || $low =~ /\.flv/) && $low !~ /only_audio=1/) {
                $url = $value;
                last;
            }
        }
    };
}

if (!$url) {
    emit_json("false", "yt-dlp", $username, "", $format, "could not extract HTTPS video URL", $timestamp, "offline");
    exit 1;
}

if ($json_flag eq '--json') {
    emit_json("true", "yt-dlp", $username, $url, $format, "", $timestamp, "live");
} else {
    print "$url\n";
}
