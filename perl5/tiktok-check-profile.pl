#!/usr/bin/perl
# tiktok-check-profile.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use Time::HiRes qw(sleep);
use Sys::CPU;
use POSIX qw(uname);

# TikTok Live Status Checker
# Prüft ausschließlich profilgebundene Live-Indikatoren.
# Der allgemeine TikTok-Navigationspunkt "LIVE" ist kein Statussignal.
# Unterstützt @handle-Normalisierung und optionalen Node-Lastschutz
# via TIKTOK_MAX_LOAD_PER_CPU (Exit-Code 75 bei NODE_BUSY).

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $raw_username = $ARGV[0];
if (!defined $raw_username) {
    print STDERR "Usage: perl tiktok-check-profile.pl <username>\n";
    exit 1;
}

my $username = $raw_username;
$username =~ s/^@+//;
if (!$username) {
    print STDERR "Username must not be empty\n";
    exit 1;
}

sub reject_busy_node {
    my $limit = $ENV{'TIKTOK_MAX_LOAD_PER_CPU'};
    if (!defined($limit) || !looks_like_number($limit) || $limit <= 0) {
        return;
    }

    my $cpu_count = Sys::CPU::cpu_count() || 1;
    $cpu_count = ($cpu_count > 1) ? $cpu_count : 1;

    # In Perl gibt es kein direktes Äquivalent zu os.loadavg(), daher simulieren wir es
    my $load_avg = get_load_average();
    my $normalized_load = $load_avg / $cpu_count;

    if ($normalized_load > $limit) {
        my $msg = sprintf("NODE_BUSY normalizedLoad=%.2f limit=%s\n", $normalized_load, $limit);
        print STDERR $msg;
        exit 75;
    }
}

sub get_load_average {
    # Lese die Load-Average aus /proc/loadavg (Linux)
    if (-r '/proc/loadavg') {
        open(my $fh, '<', '/proc/loadavg') or return 0;
        my $line = <$fh>;
        close($fh);
        chomp $line;
        my @parts = split(/\s+/, $line);
        return $parts[0] if @parts;
    }
    return 0;
}

sub looks_like_number {
    my $val = shift;
    return defined($val) && $val =~ /^[+-]?\d+\.?\d*$/;
}

reject_busy_node();

# Da Perl keine native Browser-Automatisierung wie Playwright bietet,
# verwenden wir einen HTTP-Client (z.B. LWP::UserAgent) und analysieren
# das HTML. Allerdings ist dies nicht so zuverlässig wie ein echter
# Headless-Browser. Daher verwenden wir `curl` als externes Tool,
# um näher am Original zu bleiben.

sub check_live_status {
    my ($username) = @_;
    my $url = "https://www.tiktok.com/\@$username";

    # Speichere temporäre Daten in /tmp
    my $temp_html = "/tmp/tiktok_${username}_profile.html";
    my $screenshot_path = "/tmp/tiktok-${username}.png";

    # Entferne alte Dateien
    unlink $temp_html if -e $temp_html;

    # Nutze curl, um die Seite herunterzuladen
    my $cmd = qq(curl -L --compressed -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" "$url" -o "$temp_html" --max-time 30 2>/dev/null);
    system($cmd) == 0 or do {
        my $exit_code = $? >> 8;
        error_exit("Failed to fetch profile page with curl (exit code $exit_code)");
    };

    # Warte etwas, damit JavaScript ausgeführt werden kann
    sleep(2);

    # Lies den Inhalt der Seite
    open(my $fh, '<:encoding(UTF-8)', $temp_html) or error_exit("Cannot read temp file");
    local $/;
    my $html_content = <$fh>;
    close($fh);

    # Lösche temporäre Datei
    unlink $temp_html;

    # Debug-Screenshot (falls gewünscht)
    if ($ENV{'DEBUG'} eq '1') {
        my $screenshot_cmd = qq(timeout 10 xvfb-run -a firefox --screenshot "$screenshot_path" "$url" 2>/dev/null);
        system($screenshot_cmd);
    }

    # Indikatoren prüfen

    my $live_icon_visible = ($html_content =~ m/data-e2e=["']live-icon["']/i);
    my $live_badge_visible = ($html_content =~ m/LIVE/i && $html_content =~ m/(?:profile-avatar|creator-page-header).*?LIVE/is);

    # Suche nach rotem Rahmen oder ähnlichen visuellen Hinweisen
    my $has_live_border = 0;
    if ($html_content =~ m/(border-color|box-shadow|outline-color).*?(255|red|fe2c55|#fe2c)/i) {
        $has_live_border = 1;
    }

    # Suche nach Live-Link
    my $has_live_link = ($html_content =~ m/href=["'][^"']*\/\@$username\/live["']/i);

    # Suche nach Live-Indikator-Klassen
    my $live_indicator_visible = ($html_content =~ m/class.*?(?:live-indicator|LiveBadge)/i);

    my $is_live = $live_icon_visible || $live_badge_visible || $has_live_border || $has_live_link || $live_indicator_visible;

    my %result = (
        username => $username,
        isLive => $is_live ? JSON::true : JSON::false,
        timestamp => scalar(localtime()),
        indicators => {
            liveIcon => $live_icon_visible ? JSON::true : JSON::false,
            liveBadge => $live_badge_visible ? JSON::true : JSON::false,
            liveBorder => $has_live_border ? JSON::true : JSON::false,
            liveLink => $has_live_link ? JSON::true : JSON::false,
            liveIndicator => $live_indicator_visible ? JSON::true : JSON::false
        }
    );

    print encode_json(\%result) . "\n";
    return $is_live;
}

sub error_exit {
    my ($message) = @_;
    my %error_data = (
        error => JSON::true,
        message => $message,
        timestamp => scalar(localtime())
    );
    print STDERR encode_json(\%error_data) . "\n";
    exit 1;
}

eval {
    my $is_live = check_live_status($username);
    exit($is_live ? 0 : 1);
};

if ($@) {
    my %error_data = (
        error => JSON::true,
        message => "$@",
        timestamp => scalar(localtime())
    );
    print STDERR encode_json(\%error_data) . "\n";
    exit 1;
}
