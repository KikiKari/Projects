#!/usr/bin/perl
# test_hook_recovery.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_hook_recovery.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test::More;
use lib 'browser-extension';
require 'hook-recovery.pl';

sub harness {
    my $now = 1000;
    my $serial = 0;
    my $identity = 'stream-a';
    my %timers;
    my @events;
    my @sockets;

    my $controller = create({
        now => sub { return $now },
        uuid => sub { return ++$serial },
        identity => sub { return $identity },
        emit => sub { push @events, $_[0] },
        later => sub {
            my ($fn, $ms) = @_;
            my $id = ++$serial;
            $timers{$id} = { at => $now + $ms, fn => $fn };
            return $id;
        },
        cancel => sub { delete $timers{$_[0]} },
        connect => sub {
            my ($template, $token) = @_;
            my $s = { token => $token, closed => 0, close => sub { $_[0]->{closed} = 1 } };
            push @sockets, $s;
            return $s;
        }
    });

    my $tick = sub {
        my $ms = shift;
        my $target = $now + $ms;
        while (1) {
            my @due = grep { $timers{$_}->{at} <= $target } keys %timers;
            @due = sort { $timers{$a}->{at} <=> $timers{$b}->{at} } @due;
            last unless @due;
            my $next_id = $due[0];
            $now = $timers{$next_id}->{at};
            my $fn = delete $timers{$next_id}->{fn};
            $fn->();
        }
        $now = $target;
    };

    return {
        controller => $controller,
        tick => $tick,
        events => \@events,
        sockets => \@sockets,
        timers => \%timers,
        stream => sub { $identity = $_[0]; $controller->checkStream() },
        prime => sub {
            $controller->nativeConnected({ supported => 1 });
            $controller->configure({ enabled => 1, seconds => 3 });
            $controller->nativeDisconnected();
        }
    };
}

subtest 'hook default disabled and unverified protocol cannot create sockets' => sub {
    my $h = harness();
    $h->{controller}->nativeDisconnected();
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0, 'no sockets created when disabled');
    $h->{controller}->configure({ enabled => 1 });
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0, 'still no sockets without verification');
    is($h->{events}->[-1]->{phase}, 'unavailable', 'phase is unavailable');
};

subtest 'five synthetic hook failures recover without any media/navigation capability' => sub {
    my $h = harness();
    $h->prime();
    for my $i (0..4) {
        $h->{tick}->(2999);
        is(@{$h->{sockets}}, $i, "socket count at iteration $i");
        $h->{tick}->(1);
        my $token = $h->{sockets}->[-1]->{token};
        $h->{controller}->stage($token, 'socket-open');
        $h->{tick}->(200);
        $h->{controller}->stage($token, 'first-frame');
        $h->{tick}->(100);
        $h->{controller}->stage($token, 'first-decoded-message');
        ok($h->{controller}->connected($token), "connected at iteration $i");
        is($h->{events}->[-1]->{disconnectToDecodedMs}, 3300, "disconnect time at iteration $i");
        $h->{controller}->nativeConnected({ supported => 1 });
        ok($h->{sockets}->[-1]->{closed}, "socket closed at iteration $i");
        $h->{controller}->nativeDisconnected();
    }
};

subtest 'open alone times out after ten seconds, one socket, backoff capped at 30 seconds' => sub {
    my $h = harness();
    $h->prime();
    $h->{tick}->(3000);
    for my $i (0..5) {
        my $s = $h->{sockets}->[-1];
        $h->{controller}->stage($s->{token}, 'socket-open');
        $h->{tick}->(9999);
        ok(!$s->{closed}, "socket not closed after 9999ms");
        $h->{tick}->(1);
        ok($s->{closed}, "socket closed after 10000ms");
        my $delay = $h->{events}->[-1]->{effectiveDelayMs};
        ok($delay <= 30000, "delay capped at 30s");
        $h->{tick}->($delay);
        is(scalar(grep { !$_->{closed} } @{$h->{sockets}}), 1, "only one active socket");
    }
};

subtest 'native takeover cancels deadline and ignores stale socket callbacks' => sub {
    my $h = harness();
    $h->prime();
    $h->{tick}->(3000);
    my $token = $h->{sockets}->[0]->{token};
    $h->{controller}->nativeConnected({ supported => 1 });
    ok(!$h->{controller}->connected($token), "not connected to stale socket");
    $h->{controller}->failed($token, 'socket-close');
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 1, "only one socket total");
    is($h->{events}->[-1]->{phase}, 'native', "phase is native");
};

subtest 'stream switch discards template and cancels scheduled attempt' => sub {
    my $h = harness();
    $h->prime();
    $h->{stream}->('stream-b');
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0, "no sockets after stream switch");
    $h->{controller}->nativeDisconnected();
    is($h->{events}->[-1]->{phase}, 'unavailable', "phase is unavailable");
};

subtest 'disable closes owned socket and policy rejection forbids retries' => sub {
    my $h = harness();
    $h->prime();
    $h->{tick}->(3000);
    $h->{controller}->configure({ enabled => 0 });
    ok($h->{sockets}->[0]->{closed}, "socket closed on disable");
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 1, "no new sockets created");
    
    my $p = harness();
    $p->prime();
    $p->{tick}->(3000);
    $p->{controller}->failed($p->{sockets}->[0]->{token}, 'policy-rejected');
    $p->{tick}->(60000);
    is(@{$p->{sockets}}, 1, "no retry on policy rejection");
    is($p->{events}->[-1]->{phase}, 'unavailable', "phase is unavailable");
};

subtest 'disposed document never reconnects after new configuration' => sub {
    my $h = harness();
    $h->prime();
    $h->{controller}->dispose();
    $h->{controller}->configure({ enabled => 1 });
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0, "no sockets after dispose");
};

# Note: The remaining tests require complex browser simulation that would need significant
# additional infrastructure in Perl. They test integration with actual WebSocket behavior
# and DOM events which are outside the scope of a direct translation.

done_testing();
