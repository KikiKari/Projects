#!/usr/bin/perl
# test_android_recovery.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_android_recovery.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use File::Spec;
use File::Basename;

# Helper to resolve paths like Node.js path.resolve
sub resolve_path {
    my @parts = @_;
    my $resolved = File::Spec->rel2abs(File::Spec->catfile(@parts));
    return $resolved;
}

# Get __dirname equivalent
my $script_path = __FILE__;
my $dirname = dirname($script_path);

# Raw directory path
my $raw_dir = resolve_path($dirname, '../../mobile/android/app/src/main/res/raw');

# Setup function
sub setup {
    my ($ios) = @_;
    $ios //= 0;

    # State variables
    my $now = 10000;
    my $plays = 0;
    my $seq = 0;
    my %timers = ();
    my @intervals = ();
    my %listeners = ();
    my @events = ();

    # Video mock
    my $video = {
        clientWidth => 100,
        clientHeight => 100,
        currentTime => 1,
        paused => 0,
        ended => 0,
        readyState => 4,
        dataset => {},
        addEventListener => sub {
            my ($n, $f) = @_;
            $listeners{$n} = $f;
        },
        play => sub {
            $plays++;
            return Promise->new(sub { $_[0]->('resolved') });
        },
        textTracks => [],
    };

    # Root object
    my $root = {
        location => {
            origin => 'https://www.tiktok.com',
            pathname => '/@creator/live',
        },
        crypto => {
            randomUUID => sub {
                $seq++;
                my $uuid_suffix = sprintf("%012d", $seq);
                return "11111111-1111-1111-1111-$uuid_suffix";
            }
        },
        Date => 'DateMock', # Placeholder for Date class override
        document => {
            scripts => [],
            body => { innerText => '' },
            querySelectorAll => sub {
                my ($s) = @_;
                return $s eq 'video' ? [$video] : [];
            },
            querySelector => sub { return undef; }
        },
        tlcBridge => {
            postMessage => sub {
                my ($s) = @_;
                push @events, ref($s) ? $s : eval { decode_json($s) };
            }
        },
        addEventListener => sub {
            my ($n, $f) = @_;
            $listeners{$n} = $f;
        },
        postMessage => sub {
            my ($m) = @_;
            push @events, $m;
        },
        setInterval => sub {
            my ($f) = @_;
            push @intervals, $f;
            return scalar(@intervals);
        },
        clearInterval => sub { },
        setTimeout => sub {
            my ($f, $ms) = @_;
            $seq++;
            $timers{$seq} = { f => $f, at => $now + $ms };
            return $seq;
        },
        clearTimeout => sub {
            my ($id) = @_;
            delete $timers{$id};
        }
    };

    if ($ios) {
        delete $root->{tlcBridge};
        $root->{webkit} = {
            messageHandlers => {
                tlcBridge => {
                    postMessage => sub {
                        my ($m) = @_;
                        push @events, $m;
                    }
                }
            }
        };
    }

    $root->{top} = $root;

    # Load script content
    my $script_file = File::Spec->catfile($raw_dir, 'android_recovery.js');
    open my $fh, '<:encoding(UTF-8)', $script_file or die "Cannot read file $script_file: $!";
    my $script_content = do { local $/; <$fh> };
    close $fh;

    # Mock vm.runInNewContext - we'll just execute the code directly here
    # In a real scenario, you'd need a JS interpreter or sandbox
    # For now, we assume it populates $root with TLC_MOBILE_RECOVERY

    # Simulate loading script into context (placeholder)
    # This is where actual JavaScript execution would happen
    # We'll simulate by manually setting up the API if needed

    # Return interface
    return {
        dispatch => sub {
            my ($data) = @_;
            my $event = {
                source => $root,
                origin => $root->{location}->{origin},
                data => { source => "tiktok-live-companion", %$data }
            };
            if (exists $listeners{message}) {
                $listeners{message}->($event);
            }
        },
        root => $root,
        video => $video,
        events => \@events,
        timers => \%timers,
        get_plays => sub { return $plays },
        tick => sub {
            my ($ms) = @_;
            $now += $ms;
            for my $f (@intervals) {
                $f->();
            }
            my @to_delete = ();
            for my $id (keys %timers) {
                my $t = $timers{$id};
                if ($t->{at} <= $now) {
                    push @to_delete, $id;
                    $t->{f}->();
                }
            }
            for my $id (@to_delete) {
                delete $timers{$id};
            }
        },
        api => $root->{TLC_MOBILE_RECOVERY} || {}
    };
}

# Test cases
sub test_player_recovery_waits_configured_interval_once_and_never_touches_navigation {
    my $s = setup();
    $s->{api}->{command}('set-auto-reconnect', { enabled => 1, delaySeconds => 3 });
    $s->{api}->{recover}('stalled');
    is(keys %{$s->{timers}}, 1, 'Timer should be set');
    $s->{tick}(2999);
    is($s->{get_plays}(), 0, 'Should not have played yet');
    $s->{tick}(1);
    is($s->{get_plays}(), 1, 'Should have played after delay');
    is($s->{root}->{location}->{pathname}, '/@creator/live', 'Pathname unchanged');
}

sub test_user_pause_and_vlc_cancel_pending_recovery {
    for my $cmd ('pause', 'set-vlc-active') {
        my $s = setup();
        $s->{api}->{command}('set-auto-reconnect', { enabled => 1 });
        $s->{api}->{recover}('stalled');
        $s->{api}->{command}($cmd, { active => 1 });
        $s->{tick}(4000);
        is($s->{get_plays}(), 0, "Recovery canceled by $cmd");
    }
}

sub test_media_progress_cancels_attempt_without_replacing_media {
    my $s = setup();
    $s->{api}->{command}('set-auto-reconnect', { enabled => 1 });
    $s->{api}->{recover}('waiting');
    $s->{video}->{currentTime} = 2;
    $s->{tick}(3000);
    is($s->{get_plays}(), 0, 'Recovery canceled due to media progress');
}

sub test_caption_websocket_activity_expires_independently_from_menu {
    my $s = setup();
    $s->{dispatch}({ type => "caption", caption => { contents => [{ lang => "de", text => "test" }] } });
    my @caption_events = grep { $_->{type} eq 'caption-state' } @{$s->{events}};
    ok(@caption_events > 0, 'Caption state event exists');
    my $last_event = $caption_events[-1];
    is($last_event->{payload}->{websocket}, 1, 'Websocket active initially');
    $s->{tick}(16000);
    @caption_events = grep { $_->{type} eq 'caption-state' } @{$s->{events}};
    $last_event = $caption_events[-1];
    is($last_event->{payload}->{websocket}, '', 'Websocket inactive after timeout');
    is($last_event->{payload}->{activityTtlMs}, 15000, 'Correct TTL');
}

sub test_android_uses_byte_identical_browser_controller_and_protocol_parser {
    my @pairs = (
        ['hook_recovery.js', 'hook-recovery.js'],
        ['recovery_hook.js', 'hook.js'],
        ['proto_main.js', 'proto-main.js']
    );
    my $browser_ext_dir = resolve_path($dirname, '../browser-extension');
    for my $pair (@pairs) {
        my ($mobile, $browser) = @$pair;
        my $mobile_path = File::Spec->catfile($raw_dir, $mobile);
        my $browser_path = File::Spec->catfile($browser_ext_dir, $browser);
        open my $fh1, '<:raw', $mobile_path or die "Cannot read $mobile_path: $!";
        open my $fh2, '<:raw', $browser_path or die "Cannot read $browser_path: $!";
        my $content1 = do { local $/; <$fh1> };
        my $content2 = do { local $/; <$fh2> };
        close $fh1;
        close $fh2;
        is($content1, $content2, "$mobile matches $browser");
    }
}

sub test_ios_webkit_bridge_receives_correlated_recovery_observations {
    my $s = setup(1);
    $s->{tick}(1000);
    my ($e) = grep { $_->{type} eq 'player-observation' } @{$s->{events}};
    ok($e, 'Player observation event found');
    is($e->{payload}->{frameKind}, 'top', 'Frame kind correct');
    like($e->{payload}->{documentId}, qr/^[a-f0-9-]{36}$/, 'Document ID valid UUID');
    $s->{dispatch}({ type => 'caption', caption => { text => 'ios-caption' } });
    my @caption_events = grep { $_->{type} eq 'caption' } @{$s->{events}};
    my $last_caption = $caption_events[-1];
    is($last_caption->{payload}->{text}, 'ios-caption', 'Caption received correctly');
}

sub test_ios_and_android_inject_identical_recovery_implementations {
    my $ios_dir = resolve_path($dirname, '../../mobile/ios/Resources');
    my @pairs = (
        ['android_recovery.js', 'mobile-recovery.js'],
        ['hook_recovery.js', 'hook-recovery.js'],
        ['recovery_hook.js', 'recovery-hook.js'],
        ['export_privacy.js', 'export-privacy.js'],
        ['proto_main.js', 'proto-main.js'],
        ['content_core.js', 'content-core.js']
    );
    for my $pair (@pairs) {
        my ($a, $b) = @$pair;
        my $path_a = File::Spec->catfile($raw_dir, $a);
        my $path_b = File::Spec->catfile($ios_dir, $b);
        open my $fh1, '<:raw', $path_a or die "Cannot read $path_a: $!";
        open my $fh2, '<:raw', $path_b or die "Cannot read $path_b: $!";
        my $content1 = do { local $/; <$fh1> };
        my $content2 = do { local $/; <$fh2> };
        close $fh1;
        close $fh2;
        is($content1, $content2, "$a matches $b");
    }
}

sub test_connection_off_stops_companion_chat_delivery_on_resumes_without_touching_player {
    for my $ios (0, 1) {
        my $s = setup($ios);
        $s->{api}->{command}('set-connection', { enabled => 0 });
        $s->{dispatch}({ type => 'chat-message', chatMessage => { content => 'hidden from Companion' } });
        my @chat_events = grep { $_->{type} eq 'chat' } @{$s->{events}};
        is(scalar(@chat_events), 0, 'Chat blocked when connection disabled');
        $s->{api}->{command}('set-connection', { enabled => 1 });
        $s->{dispatch}({ type => 'chat-message', chatMessage => { content => 'visible' } });
        @chat_events = grep { $_->{type} eq 'chat' } @{$s->{events}};
        is(scalar(@chat_events), 1, 'Chat delivered when connection enabled');
        is($s->{get_plays}(), 0, 'No playback triggered');
    }
}

# Run tests
test_player_recovery_waits_configured_interval_once_and_never_touches_navigation();
test_user_pause_and_vlc_cancel_pending_recovery();
test_media_progress_cancels_attempt_without_replacing_media();
test_caption_websocket_activity_expires_independently_from_menu();
test_android_uses_byte_identical_browser_controller_and_protocol_parser();
test_ios_webkit_bridge_receives_correlated_recovery_observations();
test_ios_and_android_inject_identical_recovery_implementations();
test_connection_off_stops_companion_chat_delivery_on_resumes_without_touching_player();

done_testing();
