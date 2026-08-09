#!/usr/bin/env perl
# extract-tiktok-streamlink.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use POSIX qw(strftime);

my $username = $ARGV[0] // "";
$username =~ s/^@//;
my $quality = $ARGV[1] // "best";
my $json_flag = $ARGV[2] // "";
my $timestamp = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);

sub emit_json {
    my (@values) = @_;
    my @keys = qw(success method username url quality author title error timestamp status);
    my %payload;
    for my $i (0 .. $#keys) {
        if ($i <= $#values && defined $values[$i] && $values[$i] ne "") {
            $payload{$keys[$i]} = $values[$i];
        }
    }
    if (exists $payload{success}) {
        $payload{success} = lc($payload{success}) eq "true" ? JSON::true : JSON::false;
    }
    print encode_json(\%payload) . "\n";
}

if ($username !~ /^[A-Za-z0-9._]{1,24}$/) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "Invalid TikTok username", $timestamp, "invalid_input");
    exit 64;
}

my %valid_qualities = map { $_ => 1 } qw(best worst original 1080p60 720p60 720p 540p 360p auto);
if (!exists $valid_qualities{$quality}) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "Invalid stream quality", $timestamp, "invalid_input");
    exit 64;
}

my $load_per_cpu = (split ' ', `cat /proc/loadavg`)[0] / (`nproc` || 1);
my $max_load = $ENV{TIKTOK_MAX_LOAD_PER_CPU} // 1.5;
if ($load_per_cpu > $max_load) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "host overloaded", $timestamp, "overloaded");
    exit 75;
}

unless (`which streamlink 2>/dev/null`) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "streamlink not installed", $timestamp, "dependency_missing");
    exit 2;
}

my $live_url = "https://www.tiktok.com/\@$username/live";
my %selector_map = (
    "original" => "origin,uhd_60,hd_60,hd,sd,ld,best,worst",
    "auto" => "best,origin,uhd_60,hd_60,hd,sd,ld,worst",
    "1080p60" => "uhd_60,hd_60,hd,sd,ld,worst",
    "720p60" => "hd_60,hd,sd,ld,worst",
    "720p" => "hd,sd,ld,worst",
    "540p" => "sd,ld,worst",
    "360p" => "ld,worst"
);
my $selector = $selector_map{$quality} // $quality;

my $output = `streamlink --json '$live_url' '$selector' 2>/dev/null`;
my $exit_code = $? >> 8;
if ($exit_code != 0 || !$output) {
    my $url = `streamlink --stream-url '$live_url' '$selector' 2>/dev/null`;
    chomp $url;
    if ($? >> 8 != 0 || !$url) {
        emit_json("false", "streamlink", $username, "", $quality, "", "", "streamlink failed or no stream found", $timestamp, "offline");
        exit 1;
    }
    if ($json_flag eq "--json") {
        emit_json("true", "streamlink", $username, $url, $quality, "", "", "", $timestamp, "live");
    } else {
        print "$url\n";
    }
    exit 0;
}

my $parsed_data;
eval {
    my $data = decode_json($output);
    my $url = $data->{url} // "";
    my $streams = $data->{streams};
    if (!$url && ref($streams) eq "HASH") {
        for my $key ("best", "worst", keys %$streams) {
            my $value = $streams->{$key};
            if (ref($value) eq "HASH" && $value->{url}) {
                $url = $value->{url};
                last;
            }
        }
    }
    my $metadata = $data->{metadata} // {};
    $parsed_data = {
        url => $url,
        author => $metadata->{author} // "",
        title => $metadata->{title} // ""
    };
};
if ($@) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "invalid streamlink JSON", $timestamp, "technical_error");
    exit 2;
}

my $url = $parsed_data->{url} // "";
my $author = $parsed_data->{author} // "";
my $title = $parsed_data->{title} // "";
if (!$url) {
    emit_json("false", "streamlink", $username, "", $quality, $author, $title, "could not extract stream URL", $timestamp, "offline");
    exit 1;
}
if ($json_flag eq "--json") {
    emit_json("true", "streamlink", $username, $url, $quality, $author, $title, "", $timestamp, "live");
} else {
    print "$url\n";
}
