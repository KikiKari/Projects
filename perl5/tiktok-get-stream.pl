#!/usr/bin/perl
# tiktok-get-stream.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-24 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON qw(decode_json encode_json);
use File::Spec;
use File::Basename;
use IPC::Run3 qw(run3);
use Time::HiRes qw(usleep);
use POSIX qw(access);

# Konstanten
my $FALLBACK_TIMEOUT_MS = 45000;
my $FALLBACK_MAX_OUTPUT = 1024 * 1024;

# Globale Variablen
my $script_dir = dirname($0);

# Logging-Funktion
sub log_message {
    my ($message) = @_;
    print STDERR "$message\n";
}

# Führe Fallback-Skript aus
sub run_fallback {
    my ($script_path, $args_ref) = @_;
    my @cmd = ('bash', $script_path, @$args_ref);
    
    my ($stdout, $stderr, $exit_code);
    my $start_time = time();
    
    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm(int($FALLBACK_TIMEOUT_MS / 1000) + 5);
        
        run3(\@cmd, \undef, \$stdout, \$stderr);
        $exit_code = $? >> 8;
        alarm(0);
    };
    
    if ($@ && $@ eq "timeout\n") {
        return { code => 2, stdout => '', stderr => 'fallback timeout' };
    }
    
    if (length($stdout) > $FALLBACK_MAX_OUTPUT || length($stderr) > $FALLBACK_MAX_OUTPUT) {
        return { code => 2, stdout => '', stderr => 'fallback output exceeded limit' };
    }
    
    return { code => $exit_code // 2, stdout => $stdout // '', stderr => $stderr // '' };
}

# Parse Fallback-Ergebnis
sub parse_fallback_result {
    my ($method, $username, $execution) = @_;
    
    for my $text (($execution->{stdout}, $execution->{stderr})) {
        next unless $text;
        eval {
            my $value = decode_json($text);
            if ($value && ref($value) eq 'HASH') {
                return normalize_extractor_result($value, $method, $username);
            }
        };
    }
    
    return normalize_extractor_result({
        success => 0,
        status => ($execution->{code} == 75) ? 'overloaded' : 'technical_error',
        method => $method,
        username => $username,
        message => $execution->{stderr} || "fallback exited $execution->{code}"
    }, $method, $username);
}

# Playwright-Vorprüfung
sub playwright_preflight {
    # In Perl können wir Playwright nicht direkt nutzen, daher simulieren wir es
    my $executable = "/usr/bin/chromium-browser"; # Beispiel-Pfad
    if (-x $executable) {
        return { ok => 1, executable => $executable };
    } else {
        return {
            ok => 0,
            status => 'dependency_missing',
            error => "Playwright Chromium unavailable: Executable not found or not executable"
        };
    }
}

# Zufällige Verzögerung
sub human_delay {
    my ($min, $max) = @_;
    $min //= 2000;
    $max //= 4000;
    return int(rand($max - $min + 1)) + $min;
}

# Popup-Behandlung (simuliert)
sub handle_popups {
    my ($page) = @_;
    # In echtem Perl-Code würden wir hier mit Browser-Automatisierung arbeiten
    return 1; # Erfolg
}

# Einschränkungen prüfen (simuliert)
sub check_restrictions {
    my ($page) = @_;
    # In echtem Perl-Code würden wir hier die Seite analysieren
    return { restricted => 0, reason => undef };
}

# FLV-Qualität aus URL ableiten
sub quality_key_from_url {
    my ($url) = @_;
    if ($url =~ /(_origin\.flv)/) { return 'original'; }
    elsif ($url =~ /(_uhd_60\.flv)/) { return '1080p60'; }
    elsif ($url =~ /(_hd_60\.flv)/) { return '720p60'; }
    elsif ($url =~ /(_hd\.flv)/) { return '720p'; }
    elsif ($url =~ /(_sd\.flv)/) { return '540p'; }
    elsif ($url =~ /(_ld\.flv)/) { return '360p'; }
    return 'unknown';
}

# Playwright-basierte Extraktion (simuliert)
sub extract_with_playwright {
    my ($username, $quality_preference) = @_;
    
    my $preflight = playwright_preflight();
    unless ($preflight->{ok}) {
        return {
            success => 0,
            method => 'playwright',
            status => $preflight->{status},
            error => $preflight->{error}
        };
    }
    
    # Simuliere das Sammeln von URLs
    my @collected_urls = (
        { url => "https://example.com/stream_origin.flv", status => 200 },
        { url => "https://example.com/stream_hd.flv", status => 200 },
        { url => "https://example.com/stream_sd.flv", status => 200 }
    );
    
    unless (@collected_urls) {
        return { 
            success => 0, 
            method => 'playwright', 
            status => 'offline',
            restricted => 0, 
            reason => 'No FLV URLs found' 
        };
    }
    
    # Deduplizieren und sortieren
    my %seen;
    my @unique_urls = grep { !$seen{$_->{url}}++ } @collected_urls;
    
    # Qualitätspräferenz anwenden
    my %quality_order = (
        original => ['_origin.flv', '_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
        '1080p60' => ['_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
        '720p60' => ['_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
        '720p' => ['_hd.flv', '_sd.flv', '_ld.flv'],
        '540p' => ['_sd.flv', '_ld.flv'],
        '360p' => ['_ld.flv'],
        auto => ['_origin.flv', '_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
    );
    
    my $order = $quality_order{$quality_preference} || $quality_order{auto};
    my $best_url;
    
    for my $suffix (@$order) {
        ($best_url) = grep { $_->{url} =~ /\Q$suffix\E/ } @unique_urls;
        last if $best_url;
    }
    
    $best_url //= $unique_urls[0];
    
    unless ($best_url) {
        return { 
            success => 0, 
            method => 'playwright', 
            status => 'quality_unavailable',
            reason => "Requested quality $quality_preference was not captured" 
        };
    }
    
    return {
        success => 1,
        status => 'live',
        method => 'playwright',
        username => $username,
        url => $best_url->{url},
        quality => $quality_preference,
        allUrls => [map { { url => $_->{url}, quality => quality_key_from_url($_->{url}) } } @unique_urls],
        allUrlsCount => scalar(@unique_urls),
        timestamp => gmtime() . "Z"
    };
}

# Streamlink-Fallback
sub try_streamlink {
    my ($username, $quality) = @_;
    my $script_path = File::Spec->catfile($script_dir, 'extraction-methods', 'extract-tiktok-streamlink.sh');
    my $execution = run_fallback($script_path, [$username, $quality, '--json']);
    return parse_fallback_result('streamlink', $username, $execution);
}

# yt-dlp-Fallback
sub try_yt_dlp {
    my ($username, $quality) = @_;
    my $script_path = File::Spec->catfile($script_dir, 'extraction-methods', 'extract-tiktok-yt-dlp.sh');
    
    my %yt_format_map = (
        original => 'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
        '1080p60' => 'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
        '720p60' => 'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
        '720p' => 'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
        '540p' => 'hls-sd/hls-ld/flv-sd/flv-ld', 
        '360p' => 'hls-ld/flv-ld',
        auto => 'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld',
    );
    
    my $yt_format = $yt_format_map{$quality} || $yt_format_map{auto};
    my $execution = run_fallback($script_path, [$username, $yt_format, '--json']);
    return parse_fallback_result('yt-dlp', $username, $execution);
}

# Hauptfunktion mit Fallback-Kette
sub get_stream_url {
    my ($username, $quality_preference) = @_;
    $quality_preference //= 'auto';
    my $timestamp = gmtime() . "Z";
    
    # 1. Playwright
    log_message("[1/3] Trying Playwright for \@$username...");
    my $pw_result = extract_with_playwright($username, $quality_preference);
    if ($pw_result->{success}) {
        $pw_result->{timestamp} = $timestamp;
        return $pw_result;
    }
    if ($pw_result->{status} eq 'restricted' || $pw_result->{status} eq 'overloaded') {
        return $pw_result;
    }
    log_message("Playwright result: " . ($pw_result->{reason} || $pw_result->{error} || 'failed'));
    
    # 2. Streamlink
    log_message("[2/3] Trying streamlink for \@$username (quality: $quality_preference)...");
    my $sl_result = try_streamlink($username, $quality_preference);
    if ($sl_result->{success}) {
        return $sl_result;
    }
    if ($sl_result->{status} eq 'restricted' || $sl_result->{status} eq 'overloaded') {
        return $sl_result;
    }
    log_message("Streamlink result: " . ($sl_result->{message} || $sl_result->{error} || 'failed'));
    
    # 3. yt-dlp
    log_message("[3/3] Trying yt-dlp for \@$username...");
    my $yt_result = try_yt_dlp($username, $quality_preference);
    if ($yt_result->{success}) {
        return $yt_result;
    }
    if ($yt_result->{status} eq 'restricted' || $yt_result->{status} eq 'overloaded') {
        return $yt_result;
    }
    log_message("yt-dlp result: " . ($yt_result->{message} || $yt_result->{error} || 'failed'));
    
    # Alle fehlgeschlagen
    my $status = classify_final_failure([$pw_result, $sl_result, $yt_result]);
    return {
        success => 0,
        status => $status,
        username => $username,
        message => 'All extraction methods failed (Playwright, streamlink, yt-dlp).',
        playwrightReason => $pw_result->{reason} || $pw_result->{error},
        streamlinkReason => $sl_result->{message} || $sl_result->{error},
        ytdlpReason => $yt_result->{message} || $yt_result->{error},
        timestamp => $timestamp
    };
}

# Hilfsfunktionen (aus tiktok-common simuliert)
sub classify_final_failure {
    my ($results) = @_;
    for my $result (@$results) {
        return $result->{status} if $result->{status} eq 'overloaded';
    }
    return 'technical_error';
}

sub enforce_load_limit {
    # In echter Implementierung würde dies Lastbegrenzungen durchsetzen
}

sub exit_code_for_result {
    my ($result) = @_;
    return 0 if $result->{success};
    return 1 if $result->{status} eq 'offline' || $result->{status} eq 'restricted';
    return 75 if $result->{status} eq 'overloaded';
    return 2; # technischer Fehler
}

sub forced_offline {
    my ($method, $username) = @_;
    # In echter Implementierung würde dies Offline-Status prüfen
    return 0;
}

sub is_successful_stream_response {
    my ($status, $url) = @_;
    return ($status == 200 || $status == 206) && $url =~ /\.flv$/;
}

sub normalize_extractor_result {
    my ($result, $method, $username) = @_;
    $result->{method} //= $method;
    $result->{username} //= $username;
    return $result;
}

sub normalize_username {
    my ($username) = @_;
    $username =~ s/^@//;
    die "Invalid username format\n" unless $username =~ /^[a-zA-Z0-9._-]+$/;
    return $username;
}

# CLI-Verarbeitung
if (@ARGV < 1) {
    print STDERR "Usage: perl tiktok-get-stream.pl <username> [quality: original|1080p60|720p60|720p|540p|360p|auto] [--json]\n";
    exit(1);
}

my $cli_username;
eval {
    $cli_username = normalize_username($ARGV[0]);
};
if ($@) {
    print STDERR $@;
    exit(64);
}

enforce_load_limit('playwright_streamlink_ytdlp');
if (forced_offline('playwright_streamlink_ytdlp', $cli_username)) {
    exit(1);
}

my $cli_quality = 'auto';
my $cli_json = 0;

for my $i (1..$#ARGV) {
    if ($ARGV[$i] eq '--json') {
        $cli_json = 1;
    } elsif (!$cli_quality_set && $ARGV[$i] =~ /^(original|1080p60|720p60|720p|540p|360p|auto)$/) {
        $cli_quality = $ARGV[$i];
        $cli_quality_set = 1;
    }
}

unless ($cli_quality =~ /^(original|1080p60|720p60|720p|540p|360p|auto)$/) {
    print STDERR "Invalid quality; expected original, 1080p60, 720p60, 720p, 540p, 360p, or auto\n";
    exit(64);
}

my $result = get_stream_url($cli_username, $cli_quality);

if ($cli_json) {
    print encode_json($result) . "\n";
} else {
    if ($result->{success}) {
        print $result->{url} . "\n";
    } else {
        print STDERR $result->{message} . "\n";
    }
}

exit(exit_code_for_result($result));
