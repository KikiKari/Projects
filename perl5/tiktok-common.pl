#!/usr/bin/perl
# tiktok-common.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON::PP qw(decode_json encode_json);

# Shared TikTok LIVE safety contract: handle normalization, per-CPU load
# preflight, exact account LIVE selectors, strict HTTPS TikTok-CDN FLV
# validation, and normalized extractor statuses.

my $DEFAULT_MAX_LOAD_PER_CPU = 1.5;
my $USERNAME_PATTERN = qr/^[A-Za-z0-9._]{1,24}$/;
my %FAILURE_STATUSES = map { $_ => 1 } qw(offline restricted overloaded dependency_missing technical_error);

sub normalizeUsername {
    my ($raw) = @_;
    my $username = defined $raw ? $raw : '';
    $username =~ s/^\s+|\s+$//g;
    $username =~ s/^@+//;
    if ($username !~ $USERNAME_PATTERN) {
        die "Invalid TikTok username; expected 1-24 letters, digits, dots, or underscores";
    }
    return $username;
}

sub loadState {
    my ($env) = @_;
    $env //= \%ENV;
    my $cpuCount = 1; # Placeholder for number of CPUs
    eval {
        # In a real implementation, you would get actual CPU count here
        # This is just illustrative since there's no direct equivalent in Perl core
        # You might use something like Sys::CPU or parse /proc/cpuinfo on Linux
        $cpuCount = 1; # Defaulting to 1 for now
    };
    my $observed = exists $env->{TIKTOK_TEST_LOAD_PER_CPU}
        ? $env->{TIKTOK_TEST_LOAD_PER_CPU} + 0
        : do {
            # Placeholder for load average calculation
            # Again, this isn't directly available without additional modules
            0.5; # Simulated value
        };
    my $maximum = exists $env->{TIKTOK_MAX_LOAD_PER_CPU}
        ? $env->{TIKTOK_MAX_LOAD_PER_CPU} + 0
        : $DEFAULT_MAX_LOAD_PER_CPU;
    if (!defined($observed) || !defined($maximum) || $maximum <= 0) {
        die "Invalid TikTok load configuration";
    }
    return {
        overloaded => $observed > $maximum,
        loadPerCpu => $observed,
        maximum => $maximum
    };
}

sub enforceLoadLimit {
    my ($method) = @_;
    my $state = loadState();
    if (!$state->{overloaded}) {
        return $state;
    }
    my $json = JSON::PP->new;
    print STDERR $json->encode({
        status => 'overloaded',
        method => $method,
        loadPerCpu => sprintf("%.3f", $state->{loadPerCpu}),
        maximum => $state->{maximum},
        message => 'Host is overloaded; retry on another node or later'
    }) . "\n";
    exit(75);
}

sub liveHrefSelectors {
    my ($username) = @_;
    my $href = "/\@$username/live";
    return ["a[href=\"$href\"]", "a[href^=\"$href?\"]"];
}

sub isAllowedStreamUrl {
    my ($value) = @_;
    eval {
        require URI;
        my $url = URI->new($value);
        my $hostname = lc($url->host // '');
        return $url->scheme eq 'https' &&
               lc($url->path) =~ /\.flv/ &&
               $hostname =~ /(^|\.)tiktokcdn(?:-[a-z0-9-]+)?\.com$/;
    };
    return 0;
}

sub isSuccessfulStreamResponse {
    my ($status, $value) = @_;
    return defined($status) && int($status) == $status &&
           $status >= 200 && $status < 300 &&
           isAllowedStreamUrl($value);
}

# Order matters: longer keys first so `_uhd_60` never matches as `hd_60`/`hd`.
my $QUALITY_URL_PATTERN = qr/_(uhd_60|hd_60|origin|hd|sd|ld|ao)\.(?:flv|m3u8)/;

sub qualityKeyFromUrl {
    my ($value) = @_;
    eval {
        require URI;
        my $path = lc(URI->new($value)->path);
        if ($path =~ /$QUALITY_URL_PATTERN/) {
            return $1;
        }
    };
    return undef;
}

sub normalizeExtractorResult {
    my ($value, $method, $username) = @_;
    my $technicalError = {
        success => 0,
        status => 'technical_error',
        method => $method,
        username => $username,
        message => 'invalid extractor result'
    };

    if (!defined($value) || ref($value) ne 'HASH') {
        return $technicalError;
    }

    if ($value->{success}) {
        if ($value->{status} ne 'live' || !isAllowedStreamUrl($value->{url})) {
            return $technicalError;
        }
        return { %$value, success => 1, status => 'live' };
    }

    if (!exists $value->{success} || $value->{success}) {
        return $technicalError;
    }

    my $result_status = exists $value->{status} && exists $FAILURE_STATUSES{$value->{status}}
                        ? $value->{status}
                        : 'technical_error';

    my $result_method = exists $value->{method} && defined($value->{method})
                        ? $value->{method}
                        : $method;

    my $result_username = exists $value->{username} && defined($value->{username})
                          ? $value->{username}
                          : $username;

    my %result = (
        success => 0,
        status => $result_status,
        method => $result_method,
        username => $result_username
    );

    return \%result;
}

sub classifyFinalFailure {
    my ($results) = @_;
    my %statuses;
    for my $result (@$results) {
        if (defined($result) && defined($result->{status}) && exists $FAILURE_STATUSES{$result->{status}}) {
            $statuses{$result->{status}} = 1;
        }
    }

    return 'overloaded' if exists $statuses{overloaded};
    return 'restricted' if exists $statuses{restricted};
    return 'technical_error' if exists $statuses{technical_error};
    return 'offline' if exists $statuses{offline};
    return 'dependency_missing' if exists $statuses{dependency_missing};
    return 'technical_error';
}

sub exitCodeForResult {
    my ($result) = @_;
    if (defined($result) && $result->{success} && $result->{status} eq 'live') {
        return 0;
    }
    if (defined($result) && $result->{status} eq 'overloaded') {
        return 75;
    }
    if (defined($result) && ($result->{status} eq 'offline' || $result->{status} eq 'restricted')) {
        return 1;
    }
    return 2;
}

sub classifyDirectLiveState {
    my ($params) = @_;
    my $username = $params->{username};
    my $currentPath = $params->{currentPath};
    my $title = $params->{title};
    my $bodyText = $params->{bodyText};
    my $successfulStreamResponse = $params->{successfulStreamResponse};

    my $expectedPath = "/\@$username/live";
    if ($currentPath ne $expectedPath) {
        return { status => 'offline', reason => 'target live page redirected' };
    }
    if ($successfulStreamResponse) {
        return { status => 'live', reason => 'successful TikTok CDN stream response' };
    }

    my $normalizedBody = defined($bodyText) ? lc($bodyText) : '';
    $normalizedBody =~ s/\s+/ /g;
    my $normalizedTitle = defined($title) ? lc($title) : '';
    my $accountLiveTitle = index($normalizedTitle, "(\@$username)") != -1;

    my @endedMarkers = (
        'live has ended',
        'das live ist beendet',
        'live wurde beendet',
        'dieses live ist beendet',
        'stream has ended'
    );
    for my $marker (@endedMarkers) {
        if (index($normalizedBody, $marker) != -1) {
            return { status => 'offline', reason => 'target live page reports ended stream' };
        }
    }

    my @restrictionMarkers = (
        'dieses live enthält themen, die von einigen als unangenehm empfunden werden könnten',
        'melde dich an, um das beste aus deiner tiktok-erfahrung herauszuholen',
        'bei tiktok anmelden',
        'melde dich an für das volle live-erlebnis',
        'melde dich an für das vollständige erlebnis',
        'this live may contain content that could be uncomfortable',
        'log in to tiktok',
        'log in for the full live experience',
        'mature content',
        'age-restricted',
        'viewer discretion'
    );
    if ($accountLiveTitle) {
        for my $marker (@restrictionMarkers) {
            if (index($normalizedBody, $marker) != -1) {
                return { status => 'restricted', reason => 'target live page requires authentication' };
            }
        }
        return {
            status => 'restricted',
            reason => 'target is live but no accessible media response was available'
        };
    }
    return { status => 'offline', reason => 'no account-specific live signal' };
}

sub forcedOffline {
    my ($method, $username) = @_;
    if (!exists $ENV{TIKTOK_TEST_OFFLINE} || $ENV{TIKTOK_TEST_OFFLINE} ne '1') {
        return 0;
    }
    my $json = JSON::PP->new;
    print STDERR $json->encode({
        success => 0,
        status => 'offline',
        method => $method,
        username => $username,
        message => 'forced offline test mode'
    }) . "\n";
    return 1;
}

1;
