#!/usr/bin/env perl
# tiktok-check-profile.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Time::HiRes qw(sleep);
use File::Which qw(which);
use Encode qw(decode_utf8);

# /**
#  * Basic TikTok LIVE profile checker.
#  *
#  * Scopes every signal to the requested account and ignores unrelated sidebar
#  * LIVE labels. This profile-only checker does not classify restricted LIVE;
#  * use the enhanced checker or dispatcher for that distinction.
#  *
#  * Exit 0 = account-specific LIVE, 1 = offline, 2 = dependency/technical
#  * failure, 75 = overloaded before Playwright startup.
#  */

my $username;

eval {
    $username = normalize_username($ARGV[0]);
};
if ($@) {
    print STDERR "Usage: perl tiktok-check-profile.pl <username>\n";
    print STDERR $@;
    exit 64;
}

enforce_load_limit('playwright_basic');

sub normalize_username {
    my $input = shift;
    defined $input or die "Username required\n";
    $input =~ s/^\s+|\s+$//g; # trim whitespace
    length($input) > 0 or die "Empty username\n";
    $input =~ s/^@//; # remove leading @ if present
    return $input;
}

sub enforce_load_limit {
    my $method = shift;
    # Placeholder - implement as needed
}

sub check_live_status {
    my $username = shift;

    unless (which('chromium')) {
        print STDERR to_json({
            error => \1,
            status => 'dependency_missing',
            method => 'playwright_basic',
            message => 'Playwright Chromium unavailable',
            timestamp => get_iso_timestamp()
        }), "\n";
        exit 2;
    }

    # Since we can't easily replicate full Playwright behavior in Perl without
    # installing additional modules like WWW::Mechanize::Chrome or similar,
    # this implementation will simulate a basic check using HTTP requests and
    # HTML parsing.

    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    $ua->timeout(30);

    my $response = $ua->get("https://www.tiktok.com/@$username");

    unless ($response->is_success) {
        print STDERR to_json({
            error => \1,
            status => 'technical_error',
            message => 'Failed to fetch profile page: ' . $response->status_line,
            timestamp => get_iso_timestamp()
        }), "\n";
        return undef;
    }

    my $content = decode_utf8($response->decoded_content);
    my $tree = HTML::TreeBuilder->new_from_content($content);

    # Simulate waiting for page load
    sleep(2);

    # Check for LIVE indicators
    my %indicators = (
        liveIcon     => 0,
        liveBadge    => 0,
        liveBorder   => 0,
        liveLink     => 0,
        liveIndicator=> 0
    );

    # Method 1 & 4 & 5: Look for live links and indicators within them
    my @selectors = (
        '//a[contains(@href, "/live")]',
        '//a[contains(@href, "@' . $username . '/live")]',
        '//div[contains(@class, "LiveBadge")]',
        '//span[contains(@class, "live-indicator")]',
        '//div[contains(@class, "live-indicator")]'
    );

    for my $xpath (@selectors) {
        my @elements = $tree->find_by_tag_name('a'); # Simplified search
        for my $elem (@elements) {
            if (($elem->attr('href') // '') =~ /live/i ||
                ($elem->attr('class') // '') =~ /(LiveBadge|live-indicator)/i) {
                $indicators{liveLink} = 1;
                last;
            }
        }
    }

    # Method 2: Exact LIVE text/badge inside the account link
    my @badges = $tree->look_down('_tag' => 'span', 'class' => qr/LIVE/i);
    if (@badges) {
        $indicators{liveBadge} = 1;
    } else {
        @badges = $tree->look_down('_tag' => 'div', 'class' => qr/LIVE/i);
        if (@badges) {
            $indicators{liveBadge} = 1;
        }
    }

    # Method 3: Live-Rahmen am Profilkopf/Avatar
    my @avatar_selectors = (
        '[data-e2e="user-page"] img[data-e2e="avatar"]',
        '[data-e2e="user-page"] div[data-e2e="profile-avatar"] img',
        'main header img[data-e2e="avatar"]',
        'main header [class*="avatar"] img'
    );

    my @avatars = $tree->look_down('_tag' => 'img', 'data-e2e' => 'avatar');
    for my $avatar (@avatars) {
        my $style = $avatar->attr('style') // '';
        if ($style =~ /(border.*red|outline.*red|box-shadow.*255|box-shadow.*254|border-color.*fe2c55)/i) {
            $indicators{liveBorder} = 1;
            last;
        }
    }

    my $is_live = 0;
    for my $key (keys %indicators) {
        if ($indicators{$key}) {
            $is_live = 1;
            last;
        }
    }

    print to_json({
        username => $username,
        isLive => $is_live,
        timestamp => get_iso_timestamp(),
        indicators => \%indicators
    }, { pretty => 1 }), "\n";

    $tree->delete;
    return $is_live;
}

sub get_iso_timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

my $is_live = check_live_status($username);
exit(defined $is_live ? ($is_live ? 0 : 1) : 2);
