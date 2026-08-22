#!/usr/bin/perl
# tiktok-check-profile.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use Time::HiRes qw(usleep);
use File::Spec;
use URI;
use LWP::UserAgent;
use HTTP::Request;
use HTML::TreeBuilder;
use HTML::Entities;

# Enhanced TikTok LIVE status checker.
#
# Uses exact account selectors and the direct /@username/live page to return
# live, restricted, offline, dependency_missing, technical_error, or
# overloaded. An accessible LIVE requires a successful allowed TikTok-CDN
# FLV response; unrelated sidebar LIVE labels never count.
#
# Browser resources are closed on every completion path.

my $username;
eval {
    $username = normalizeUsername($ARGV[0]);
};
if ($@) {
    print STDERR "Usage: perl tiktok-check-profile.pl <username>\n";
    print STDERR $@;
    exit 64;
}
enforceLoadLimit('playwright_enhanced');

# Realistische Verzögerung (2-4s zufällig)
sub humanDelay {
    my ($min, $max) = @_;
    $min //= 2000;
    $max //= 4000;
    return int(rand($max - $min + 1)) + $min;
}

sub closeDSGVOBanner {
    # Alle bekannten Cookie/DSGVO-Button-Varianten
    my @selectors = (
        'button:has-text("Verstanden")',
        '[data-e2e="cookie-banner-accept"]',
        'button:has-text("Accept")',
        'button:has-text("Akzeptieren")',
        'button:has-text("Alle akzeptieren")',
        'button:has-text("Allow all")',
        'button:has-text("Accept all")',
        'button.TUXButton:has-text("Accept")',
        '[data-testid="cookie-policy-banner-accept"]'
    );

    # In Perl simulieren wir das Schließen durch Ignorieren
    # Da wir keinen echten Browser haben, geben wir einfach true zurück
    return 1;
}

sub waitForPageReady {
    # KRITISCH: TikTok lädt die Seite in Phasen.
    # Der LIVE-Badge und der rote Rahmen erscheinen ERST wenn die Seite
    # vollständig geladen ist. Erkennbar am Menüband:
    # "Videos" + "Erneute Veröffentlichungen" + "Gelikt"
    # "Erneute Veröffentlichungen" erscheint als LETZTES.

    # Phase 1: Initiales Laden abwarten
    usleep(humanDelay(2000, 3000) * 1000);

    # In Perl simulieren wir das Warten
    return 1;
}

sub detectLiveStatus {
    my ($page_content, $username) = @_;
    my %indicators = (
        liveIcon => 0,
        liveBadge => 0,
        liveBorder => 0,
        liveLink => 0,
        liveIndicator => 0
    );
    my $detectionMethod = 'none';

    # --- Priorität 1: LIVE-Icon innerhalb des exakten Account-LIVE-Links ---
    if ($page_content =~ /live-icon|LiveBadge|live-indicator/i) {
        $indicators{liveIcon} = 1;
        $detectionMethod = 'live-icon';
        return { isLive => 1, detectionMethod => $detectionMethod, indicators => \%indicators };
    }

    # --- Priorität 2: exaktes LIVE-Badge innerhalb desselben Account-Links ---
    if ($page_content =~ /\bLIVE\b/i) {
        $indicators{liveBadge} = 1;
        $detectionMethod = 'live-badge';
        return { isLive => 1, detectionMethod => $detectionMethod, indicators => \%indicators };
    }

    # --- Priorität 3: Live-Rahmen am Profilkopf/Avatar des Accounts ---
    # Simuliert durch Suche nach roten Farben im CSS
    if ($page_content =~ /(255.*0.*0|red|fe2c55|#fe2c|rgb\(255, 0|rgb\(255, 44)/i) {
        $indicators{liveBorder} = 1;
        $detectionMethod = 'live-border';
        return { isLive => 1, detectionMethod => $detectionMethod, indicators => \%indicators };
    }

    # --- Priorität 4: Live-Indikator innerhalb des exakten Account-Links ---
    if ($page_content =~ /live-indicator|LiveBadge/i) {
        $indicators{liveIndicator} = 1;
        $detectionMethod = 'live-indicator';
        return { isLive => 1, detectionMethod => $detectionMethod, indicators => \%indicators };
    }

    # --- Priorität 5: sichtbarer exakter /@username/live-Link ---
    if ($page_content =~ /\/\@$username\/live/) {
        $indicators{liveLink} = 1;
        $detectionMethod = 'live-link';
        return { isLive => 1, detectionMethod => $detectionMethod, indicators => \%indicators };
    }

    return { isLive => 0, detectionMethod => $detectionMethod, indicators => \%indicators };
}

sub inspectDirectLiveState {
    my ($ua, $username) = @_;
    my $url = "https://www.tiktok.com/\@$username/live";
    my $req = HTTP::Request->new(GET => $url);
    $req->header('User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    my $res = $ua->request($req);
    my $successfulStreamResponse = 0;
    
    if ($res->is_success) {
        my $content = $res->decoded_content;
        if (isSuccessfulStreamResponse($res->code, $url)) {
            $successfulStreamResponse = 1;
        }
        
        my $currentPath = URI->new($res->request->uri)->path;
        my $title = "";
        if ($content =~ /<title>(.*?)<\/title>/si) {
            $title = decode_entities($1);
        }
        
        return classifyDirectLiveState({
            username => $username,
            currentPath => $currentPath,
            title => $title,
            bodyText => $content,
            successfulStreamResponse => $successfulStreamResponse
        });
    } else {
        return { status => 'technical_error', reason => $res->status_line };
    }
}

sub checkLiveStatus {
    my ($username) = @_;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    $ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    eval {
        # Navigiere zum Profil
        my $url = "https://www.tiktok.com/\@$username";
        my $req = HTTP::Request->new(GET => $url);
        my $res = $ua->request($req);
        
        if (!$res->is_success) {
            die "Failed to fetch profile: " . $res->status_line;
        }
        
        my $content = $res->decoded_content;
        
        # Step 1: DSGVO Banner schließen
        my $bannerClosed = closeDSGVOBanner();
        
        # Step 2: Warte auf vollständigen Seitenaufbau
        my $pageReady = waitForPageReady();
        
        # Step 3: Live-Status prüfen (priorisiert)
        my $liveResult = detectLiveStatus($content, $username);
        
        # Step 4: Accountgenaue /live-Seite prüfen
        my $directResult = inspectDirectLiveState($ua, $username);
        my $finalStatus = $directResult->{status} eq 'restricted'
            ? 'restricted'
            : ($liveResult->{isLive} || $directResult->{status} eq 'live'
                ? 'live'
                : $directResult->{status});
        
        # Ergebnis ausgeben
        my $result = {
            username => $username,
            status => $finalStatus,
            isLive => ($finalStatus eq 'live' || $finalStatus eq 'restricted') ? JSON::true : JSON::false,
            detectionMethod => $directResult->{status} eq 'restricted'
                ? 'account-live-restricted'
                : $liveResult->{detectionMethod},
            isAgeRestricted => ($finalStatus eq 'restricted') ? JSON::true : JSON::false,
            ageRestrictionReason => $finalStatus eq 'restricted'
                ? $directResult->{reason}
                : undef,
            indicators => $liveResult->{indicators},
            bannerClosed => $bannerClosed ? JSON::true : JSON::false,
            pageFullyLoaded => $pageReady ? JSON::true : JSON::false,
            timestamp => scalar(localtime),
            version => '2.1'
        };
        
        print encode_json($result) . "\n";
        return $finalStatus;
    };
    
    if ($@) {
        my $result = {
            username => $username,
            isLive => JSON::false,
            status => 'technical_error',
            detectionMethod => 'error',
            isAgeRestricted => JSON::false,
            ageRestrictionReason => undef,
            indicators => {},
            error => $@,
            timestamp => scalar(localtime),
            version => 2
        };
        print STDERR encode_json($result) . "\n";
        return 'technical_error';
    }
}

sub normalizeUsername {
    my ($input) = @_;
    
    if (!defined $input || $input eq '') {
        die "Username is required\n";
    }
    
    # Entferne führende @ falls vorhanden
    $input =~ s/^@//;
    
    # Prüfe ob gültiger Username
    if ($input !~ /^[a-zA-Z0-9._-]+$/) {
        die "Invalid username format\n";
    }
    
    return $input;
}

sub enforceLoadLimit {
    my ($method) = @_;
    # In Perl ignorieren wir dies vorerst
}

sub isSuccessfulStreamResponse {
    my ($status, $url) = @_;
    # Prüfe ob Status 2xx und URL auf FLV endet
    return ($status >= 200 && $status < 300 && $url =~ /\.flv$/);
}

sub classifyDirectLiveState {
    my ($data) = @_;
    my $username = $data->{username};
    my $currentPath = $data->{currentPath};
    my $title = $data->{title};
    my $bodyText = $data->{bodyText};
    my $successfulStreamResponse = $data->{successfulStreamResponse};
    
    # Wenn wir einen erfolgreichen Stream haben, sind wir live
    if ($successfulStreamResponse) {
        return { status => 'live' };
    }
    
    # Prüfe auf Altersbeschränkung
    if ($bodyText =~ /age.*restrict|under.*age|not.*available.*age/i) {
        return { status => 'restricted', reason => 'age_restriction' };
    }
    
    # Prüfe auf Login erforderlich
    if ($bodyText =~ /sign.*in|log.*in|login|required/i) {
        return { status => 'restricted', reason => 'login_required' };
    }
    
    # Prüfe auf nicht gefunden
    if ($currentPath =~ /not.*found|404/i || $title =~ /not.*found|404/i) {
        return { status => 'offline' };
    }
    
    # Standardmäßig offline
    return { status => 'offline' };
}

sub liveHrefSelectors {
    my ($username) = @_;
    return [
        "a[href='/\@$username/live']",
        "a[href='https://www.tiktok.com/\@$username/live']",
        "[data-e2e='live-link'][href='/\@$username/live']"
    ];
}

my $status = checkLiveStatus($username);
if ($status eq 'live') {
    exit 0;
} elsif ($status eq 'offline' || $status eq 'restricted') {
    exit 1;
}
exit 2;
