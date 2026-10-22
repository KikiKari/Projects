#!/usr/bin/perl
# test_android_recovery.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_android_recovery.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Basename;
use JSON;

# Simulate Node.js modules and functions
sub require_module {
    my ($module) = @_;
    # In a real scenario, this would load the module
    # For now, we'll just return a hashref with the required functions
    if ($module eq 'node:test') {
        return { test => \&test };
    } elsif ($module eq 'node:assert/strict') {
        return { equal => \&assert_equal, ok => \&assert_ok, match => \&assert_match, deepEqual => \&assert_deep_equal };
    } elsif ($module eq 'node:vm') {
        return { runInNewContext => \&run_in_new_context };
    } elsif ($module eq 'node:fs') {
        return { readFileSync => \&read_file_sync };
    } elsif ($module eq 'node:path') {
        return { resolve => \&path_resolve, join => \&path_join };
    }
    return {};
}

# Mock functions for Node.js built-ins
sub test {
    my ($name, $callback) = @_;
    print "Running test: $name\n";
    $callback->();
}

sub assert_equal {
    my ($actual, $expected, $message) = @_;
    die "Assertion failed: $message\n" unless $actual eq $expected;
}

sub assert_ok {
    my ($value, $message) = @_;
    die "Assertion failed: $message\n" unless $value;
}

sub assert_match {
    my ($value, $regex, $message) = @_;
    die "Assertion failed: $message\n" unless $value =~ /$regex/;
}

sub assert_deep_equal {
    my ($actual, $expected, $message) = @_;
    die "Assertion failed: $message\n" unless $actual eq $expected;
}

sub run_in_new_context {
    my ($code, $context) = @_;
    # This is a simplified version - in reality, you'd need a proper VM
    # For now, we'll just return the context
    return $context;
}

sub read_file_sync {
    my ($path, $encoding) = @_;
    open my $fh, '<', $path or die "Cannot read file $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub path_resolve {
    my @parts = @_;
    return File::Spec->rel2abs(File::Spec->catfile(@parts));
}

sub path_join {
    my @parts = @_;
    return File::Spec->catfile(@parts);
}

# Main code
my $raw = path_resolve(dirname(__FILE__), '../../mobile/android/app/src/main/res/raw');

sub setup {
    my ($ios) = @_;
    my $now = 10000;
    my $plays = 0;
    my $seq = 0;
    my %timers = ();
    my @intervals = ();
    my %listeners = ();
    my @events = ();

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
        textTracks => []
    };

    my $root = {
        location => { origin => 'https://www.tiktok.com', pathname => '/@creator/live' },
        crypto => { randomUUID => sub { return sprintf("11111111-1111-1111-1111-%012d", ++$seq) } },
        Date => {
            now => sub { return $now }
        },
        document => {
            scripts => [],
            body => { innerText => '' },
            querySelectorAll => sub {
                my ($s) = @_;
                return $s eq 'video' ? [$video] : [];
            },
            querySelector => sub { return undef }
        },
        tlcBridge => {
            postMessage => sub {
                my ($s) = @_;
                push @events, decode_json($s);
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
        clearInterval => sub {},
        setTimeout => sub {
            my ($f, $ms) = @_;
            my $id = ++$seq;
            $timers{$id} = { f => $f, at => $now + $ms };
            return $id;
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

    my $code = read_file_sync(path_join($raw, 'android_recovery.js'), 'utf8');
    run_in_new_context($code, $root);

    return {
        dispatch => sub {
            my ($data) = @_;
            my $event_data = { source => $root, origin => $root->{location}->{origin}, data => { source => "tiktok-live-companion", %$data } };
            $listeners{message}->($event_data);
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
            for my $id (keys %timers) {
                my $t = $timers{$id};
                if ($t->{at} <= $now) {
                    delete $timers{$id};
                    $t->{f}->();
                }
            }
        },
        api => $root->{TLC_MOBILE_RECOVERY}
    };
}

# Test cases
test('player recovery waits configured interval once and never touches navigation', sub {
    my $s = setup();
    $s->{api}->{command}('set-auto-reconnect', { enabled => 1, delaySeconds => 3 });
    $s->{api}->{recover}('stalled');
    assert_equal(scalar(keys %{$s->{timers}}), 1, 'Timer should be set');
    $s->{tick}(2999);
    assert_equal($s->{get_plays}(), 0, 'Should not have played yet');
    $s->{tick}(1);
    assert_equal($s->{get_plays}(), 1, 'Should have played');
    assert_equal($s->{root}->{location}->{pathname}, '/@creator/live', 'Pathname should not change');
});

test('user pause and VLC cancel pending recovery', sub {
    for my $cmd ('pause', 'set-vlc-active') {
        my $s = setup();
        $s->{api}->{command}('set-auto-reconnect', { enabled => 1 });
        $s->{api}->{recover}('stalled');
        $s->{api}->{command}($cmd, { active => 1 });
        $s->{tick}(4000);
        assert_equal($s->{get_plays}(), 0, "Should not play after $cmd");
    }
});

test('media progress cancels attempt without replacing media', sub {
    my $s = setup();
    $s->{api}->{command}('set-auto-reconnect', { enabled => 1 });
    $s->{api}->{recover}('waiting');
    $s->{video}->{currentTime} = 2;
    $s->{tick}(3000);
    assert_equal($s->{get_plays}(), 0, 'Should not play after media progress');
});

test('caption websocket activity expires independently from menu', sub {
    my $s = setup();
    $s->{dispatch}({ type => "caption", caption => { contents => [{ lang => "de", text => "test" }] } });
    my @caption_events = grep { $_->{type} eq "caption-state" } @{$s->{events}};
    my $last_event = $caption_events[-1];
    assert_equal($last_event->{payload}->{websocket}, 1, 'Websocket should be active');
    $s->{tick}(16000);
    @caption_events = grep { $_->{type} eq 'caption-state' } @{$s->{events}};
    $last_event = $caption_events[-1];
    assert_equal($last_event->{payload}->{websocket}, 0, 'Websocket should be inactive');
    assert_equal($last_event->{payload}->{activityTtlMs}, 15000, 'Activity TTL should be 15000');
});

test('Android uses byte-identical browser controller and protocol parser', sub {
    my @files = (
        ['hook_recovery.js', 'hook-recovery.js'],
        ['recovery_hook.js', 'hook.js'],
        ['proto_main.js', 'proto-main.js']
    );
    
    for my $pair (@files) {
        my ($mobile, $browser) = @$pair;
        my $mobile_content = read_file_sync(path_join($raw, $mobile));
        my $browser_content = read_file_sync(path_resolve(dirname(__FILE__), '../browser-extension', $browser));
        assert_deep_equal($mobile_content, $browser_content, "Files $mobile and $browser should be identical");
    }
});

test('iOS WebKit bridge receives correlated recovery observations', sub {
    my $s = setup(1);
    $s->{tick}(1000);
    my ($e) = grep { $_->{type} eq 'player-observation' } @{$s->{events}};
    assert_ok($e, 'Should have player observation event');
    assert_equal($e->{payload}->{frameKind}, 'top', 'Frame kind should be top');
    assert_match($e->{payload}->{documentId}, qr/^[a-f0-9-]{36}$/, 'Document ID should be UUID format');
    $s->{dispatch}({ type => 'caption', caption => { text => 'ios-caption' } });
    my @caption_events = grep { $_->{type} eq 'caption' } @{$s->{events}};
    my $last_caption = $caption_events[-1];
    assert_equal($last_caption->{payload}->{text}, 'ios-caption', 'Caption text should match');
});

test('iOS and Android inject identical recovery implementations', sub {
    my $ios = path_resolve(dirname(__FILE__), '../../mobile/ios/Resources');
    my @files = (
        ['android_recovery.js', 'mobile-recovery.js'],
        ['hook_recovery.js', 'hook-recovery.js'],
        ['recovery_hook.js', 'recovery-hook.js'],
        ['export_privacy.js', 'export-privacy.js'],
        ['proto_main.js', 'proto-main.js'],
        ['content_core.js', 'content-core.js']
    );
    
    for my $pair (@files) {
        my ($a, $b) = @$pair;
        my $android_content = read_file_sync(path_join($raw, $a));
        my $ios_content = read_file_sync(path_join($ios, $b));
        assert_deep_equal($android_content, $ios_content, "Files $a and $b should be identical");
    }
});

test('Connection off stops Companion chat delivery, on resumes without touching player', sub {
    for my $ios (0, 1) {
        my $s = setup($ios);
        $s->{api}->{command}('set-connection', { enabled => 0 });
        $s->{dispatch}({ type => 'chat-message', chatMessage => { content => 'hidden from Companion' } });
        my @chat_events = grep { $_->{type} eq 'chat' } @{$s->{events}};
        assert_equal(scalar(@chat_events), 0, 'Should not deliver chat when connection is off');
        $s->{api}->{command}('set-connection', { enabled => 1 });
        $s->{dispatch}({ type => 'chat-message', chatMessage => { content => 'visible' } });
        @chat_events = grep { $_->{type} eq 'chat' } @{$s->{events}};
        assert_equal(scalar(@chat_events), 1, 'Should deliver chat when connection is on');
        assert_equal($s->{get_plays}(), 0, 'Should not affect player');
    }
});

# Simple Promise implementation for Perl
package Promise;
sub new {
    my ($class, $executor) = @_;
    my $self = {};
    bless $self, $class;
    $executor->(sub { $self->{resolved} = 1 });
    return $self;
}
