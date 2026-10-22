#!/usr/bin/perl
# test_vlc_switch.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use JSON;

# Simulate JavaScript objects and functions using hashes and subroutines
my $native = { muted => 0, paused => 0, pause => sub { $_[0]->{paused} = 1; }, play => sub { $_[0]->{paused} = 0; return {}; } };
my $fallback = { muted => 0, paused => 0 };
my @media = ($native, $fallback);
my $unrelatedVideo = { %$native };
my $speechAudio = { %$native };
my $surface = { querySelectorAll => sub { 
    my $selector = shift;
    die "Assertion failed: selector mismatch" unless $selector eq 'video';
    return \@media;
} };

$fallback->{closest} = sub { return { parentElement => $surface }; };

my $gain = { value => 0.7 };
my %listeners = ();
my $changed;

# Mock DOM environment
my $document = {
    querySelectorAll => sub { die "Must not globally suppress page media"; },
    documentElement => {},
    addEventListener => sub { my ($name, $fn) = @_; $listeners{$name} = $fn; },
    removeEventListener => sub { my $name = shift; delete $listeners{$name}; }
};

# MutationObserver mock
my $MutationObserver = sub {
    my $fn = shift;
    $changed = $fn;
    return { observe => sub {}, disconnect => sub {} };
};

# Create context similar to vm.createContext
my $context = {
    audioPipeline => { video => $native, outputGain => { gain => $gain } },
    document => $document,
    MutationObserver => $MutationObserver
};

# Read content.js file
my $content_js_path = File::Spec->catfile(File::Spec->updir(), 'browser-extension', 'content.js');
open my $fh, '<', $content_js_path or die "Cannot open $content_js_path: $!";
my $source = do { local $/; <$fh> };
close $fh;

# Extract relevant code snippets
my $start_suppress = index($source, '  function suppressNativeAudio(');
my $end_suppress = index($source, '  async function playMediaFallback(');
my $suppress_code = substr($source, $start_suppress, $end_suppress - $start_suppress);

# Execute the extracted code in our context (simulated)
eval $suppress_code;
die "Error in suppressNativeAudio code: $@" if $@;

# Call suppressNativeAudio function
my $release = $context->{suppressNativeAudio}->($fallback);

# Assertions
assert_equal($native->{muted}, 1, "native.muted should be true");
assert_equal($native->{paused}, 1, "native.paused should be true");
assert_equal($gain->{value}, 0, "gain.value should be 0");
assert_equal($fallback->{muted}, 0, "fallback.muted should be false");
assert_equal($fallback->{paused}, 0, "fallback.paused should be false");

$native->{paused} = 0;
$listeners{play}->() if exists $listeners{play};
assert_equal($native->{paused}, 1, "native.paused should be true after play event");

my $replacement = { %$native, muted => 0, paused => 0 };
push @media, $replacement;
$changed->() if defined $changed;
assert_equal($replacement->{muted}, 1, "replacement.muted should be true");
assert_equal($replacement->{paused}, 1, "replacement.paused should be true");

$release->();
assert_equal($native->{muted}, 0, "native.muted should be false after release");
assert_equal($native->{paused}, 0, "native.paused should be false after release");
assert_equal($gain->{value}, 0.7, "gain.value should be 0.7 after release");
assert_equal(scalar(keys %listeners), 0, "listeners should be empty after release");
assert_equal($unrelatedVideo->{paused}, 0, "unrelatedVideo.paused should be false");
assert_equal($speechAudio->{paused}, 0, "speechAudio.paused should be false");

$context->{audioPipeline}->{video} = $unrelatedVideo;
my $releaseUnrelated = $context->{suppressNativeAudio}->($fallback);
assert_equal($gain->{value}, 0.7, "Unrelated audio pipeline must remain unchanged");
$releaseUnrelated->();

# Read background.js file
my $background_js_path = File::Spec->catfile(File::Spec->updir(), 'browser-extension', 'background.js');
open my $bg_fh, '<', $background_js_path or die "Cannot open $background_js_path: $!";
my $background = do { local $/; <$bg_fh> };
close $bg_fh;

my $normal_start = index($background, 'async function openNormalLive(');
my $normal_end = index($background, 'chrome.sidePanel.setPanelBehavior');
my $normal = substr($background, $normal_start, $normal_end - $normal_start);

# Simple pattern matching (basic implementation)
if ($normal =~ /await chrome\.tabs\.update\(tabId, \{ url: normalLiveUrl\(handle\) \}\)/) {
    # Match found
} else {
    die "Pattern match failed: await chrome.tabs.update...";
}

unless ($normal =~ /if \(reloading\)/) {
    # Does not match - good
} else {
    die "Pattern should not match: if (reloading)";
}

if ($source =~ /if \(holder\?\.isConnected\) return holder\.querySelector\("video"\)/) {
    # Match found
} else {
    die "Pattern match failed: if (holder?.isConnected) return holder.querySelector...";
}

print "PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused\n";

# Exercise switch functionality
exercise_switch();

sub exercise_switch {
    # Read sidepanel.js file
    my $sidepanel_js_path = File::Spec->catfile(File::Spec->updir(), 'browser-extension', 'sidepanel.js');
    open my $sp_fh, '<', $sidepanel_js_path or die "Cannot open $sidepanel_js_path: $!";
    my $panel = do { local $/; <$sp_fh> };
    close $sp_fh;

    my $click_start = index($panel, '  elements["player-vlc-frame"].addEventListener("click"');
    my $click_end = index($panel, '  elements["player-volume"].addEventListener', $click_start);
    my $click_code = substr($panel, $click_start, $click_end - $click_start);

    my $click;
    my $starts = 0;
    my $button = { addEventListener => sub { my ($event, $fn) = @_; $click = $fn; } };

    my $panel_context = {
        elements => { 'player-vlc-frame' => $button },
        installVlcIfNeeded => sub { die "Internal replacement must not wait for desktop installation"; },
        runPlayer => sub { 
            my ($action, $target) = @_;
            die "Action mismatch" unless $action eq 'play-vlc-source';
            die "Target mismatch" unless $target eq $button;
            $starts++;
        }
    };

    # Execute click code
    eval $click_code;
    die "Error in click code: $@" if $@;

    # Simulate click
    $click->() if defined $click;
    assert_equal($starts, 1, 'VLC click dispatches internal player immediately');

    my $large_native = { 
        closest => sub { return undef; }, 
        getBoundingClientRect => sub { return { width => 1000, height => 1000 }; } 
    };
    my $small_replacement = { 
        closest => sub { return {}; }, 
        getBoundingClientRect => sub { return { width => 100, height => 100 }; } 
    };

    my $selection = {
        activeMediaFallbackItem => {},
        mediaFallbackRunning => 0,
        document => {
            querySelector => sub { return $small_replacement; },
            querySelectorAll => sub { return [$large_native, $small_replacement]; }
        },
        primaryVideo => sub {
            # This will be replaced by the code from content.js
        }
    };

    my $primary_start = index($source, '  function primaryVideo()');
    my $primary_end = index($source, '  function playerToggleControl()');
    my $primary_code = substr($source, $primary_start, $primary_end - $primary_start);

    # Execute primaryVideo code
    eval $primary_code;
    die "Error in primaryVideo code: $@" if $@;

    # Now we can call primaryVideo
    my $result = $selection->{primaryVideo}->();
    assert_equal($result, $small_replacement, 'Active replacement wins regardless of video size');

    $selection->{activeMediaFallbackItem} = undef;
    $selection->{mediaFallbackRunning} = 1;
    $result = $selection->{primaryVideo}->();
    assert_equal($result, $small_replacement, 'Starting replacement owns player controls');

    $selection->{mediaFallbackRunning} = 0;
    $result = $selection->{primaryVideo}->();
    assert_equal($result, $large_native, 'Inactive replacement excluded from native selection');

    my $navigated = 0;
    my $ctx = {
        chrome => {
            tabs => {
                get => sub { return { url => 'https://www.tiktok.com/@test/live' }; },
                update => sub { $navigated++; }
            }
        },
        getState => sub { return {}; },
        pageHandle => sub { return 'test'; },
        cancelEmbedSession => sub {},
        cancelRecoveryForModeChange => sub {},
        closeEmbedChatSource => sub {},
        armLiveTab => sub {},
        normalLiveUrl => sub { return 'https://www.tiktok.com/@test/live'; },
        openNormalLive => sub {
            # This will be replaced by the code from background.js
        }
    };

    # Execute normal code
    eval $normal;
    die "Error in normal code: $@" if $@;

    # Call openNormalLive
    $ctx->{openNormalLive}->(1);
    assert_equal($navigated, 1, 'Normal must navigate even from the same LIVE URL');

    my $released = 0;
    my $removed = 0;
    my $created = 0;
    my $video = {
        pause => sub {},
        removeAttribute => sub {},
        load => sub {}
    };

    my $player = {
        mediaFallbackRunning => 0,
        mediaFallbackPageUrl => 'live',
        location => { href => 'live' },
        attemptedMediaFallbackUrls => {},
        activeMediaFallbackItem => undef,
        releaseNativeAudio => undef,
        mediaFallbackCandidates => sub { return $_[0]; },
        mediaFallbackKey => sub { return $_[0]->{url}; },
        ensureMediaFallbackVideo => sub { $created++; return $video; },
        suppressNativeAudio => sub { return sub { $released++; }; },
        setMediaFallbackStatus => sub {},
        destroyMediaFallbackPlayer => sub {},
        tryMediaUrl => sub { return { ok => 0, reason => 'test failure' }; },
        getPlayerState => sub { return {}; },
        document => { getElementById => sub { return { remove => sub { $removed++; } }; } },
        playMediaFallback => sub {
            # This will be replaced by the code from content.js
        }
    };

    my $play_start = index($source, '  async function playMediaFallback(');
    my $play_end = index($source, '  async function configureLimiter(');
    my $play_code = substr($source, $play_start, $play_end - $play_start);

    # Execute playMediaFallback code
    eval $play_code;
    die "Error in playMediaFallback code: $@" if $@;

    # Call playMediaFallback with empty array
    my $result_empty = $player->{playMediaFallback}->([]);
    assert_equal($created, 0, 'No sources must not cover the native player');

    # Call playMediaFallback with test data
    my $result_test = $player->{playMediaFallback}->([{ url => 'test', quality => 'test' }]);
    assert_equal($result_test->{activated}, 0, 'Activated should be false');
    assert_equal($released, 1, 'Failed startup restores native audio');
    assert_equal($removed, 1, 'Failed startup removes replacement');
    assert_equal($player->{mediaFallbackRunning}, 0, 'mediaFallbackRunning should be false');

    print "PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay\n";
}

sub assert_equal {
    my ($actual, $expected, $message) = @_;
    if ($actual ne $expected) {
        die "Assertion failed: $message (got: $actual, expected: $expected)";
    }
}
