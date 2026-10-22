#!/usr/bin/perl
# test_hook_recovery.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_hook_recovery.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use lib 'browser-extension';
use HookRecovery;
use ProtoMain;

sub harness {
    my $now = 1000;
    my $serial = 0;
    my $identity = 'stream-a';
    my %timers;
    my @events;
    my @sockets;

    my $controller = HookRecovery::create({
        now => sub { return $now },
        uuid => sub { return '' . (++$serial) },
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
        my $ms = $_[0];
        my $target = $now + $ms;
        while (1) {
            my @due = grep { $timers{$_}->{at} <= $target } keys %timers;
            @due = sort { $timers{$a}->{at} <=> $timers{$b}->{at} } @due;
            last unless @due;
            my $next_id = $due[0];
            my $next = $timers{$next_id};
            $now = $next->{at};
            delete $timers{$next_id};
            $next->{fn}->();
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
    is(@{$h->{sockets}}, 0);
    $h->{controller}->configure({ enabled => 1 });
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0);
    is($h->{events}->[-1]->{phase}, 'unavailable');
};

subtest 'five synthetic hook failures recover without any media/navigation capability' => sub {
    my $h = harness();
    $h->{prime}->();
    for my $i (0..4) {
        $h->{tick}->(2999);
        is(@{$h->{sockets}}, $i);
        $h->{tick}->(1);
        my $token = $h->{sockets}->[-1]->{token};
        $h->{controller}->stage($token, 'socket-open');
        $h->{tick}->(200);
        $h->{controller}->stage($token, 'first-frame');
        $h->{tick}->(100);
        $h->{controller}->stage($token, 'first-decoded-message');
        is($h->{controller}->connected($token), 1);
        is($h->{events}->[-1]->{disconnectToDecodedMs}, 3300);
        $h->{controller}->nativeConnected({ supported => 1 });
        is($h->{sockets}->[-1]->{closed}, 1);
        $h->{controller}->nativeDisconnected();
    }
};

subtest 'open alone times out after ten seconds, one socket, backoff capped at 30 seconds' => sub {
    my $h = harness();
    $h->{prime}->();
    $h->{tick}->(3000);
    for my $i (0..5) {
        my $s = $h->{sockets}->[-1];
        $h->{controller}->stage($s->{token}, 'socket-open');
        $h->{tick}->(9999);
        is($s->{closed}, 0);
        $h->{tick}->(1);
        is($s->{closed}, 1);
        my $delay = $h->{events}->[-1]->{effectiveDelayMs};
        ok($delay <= 30000);
        $h->{tick}->($delay);
        is(scalar(grep { !$_->{closed} } @{$h->{sockets}}), 1);
    }
};

subtest 'native takeover cancels deadline and ignores stale socket callbacks' => sub {
    my $h = harness();
    $h->{prime}->();
    $h->{tick}->(3000);
    my $token = $h->{sockets}->[0]->{token};
    $h->{controller}->nativeConnected({ supported => 1 });
    is($h->{controller}->connected($token), 0);
    $h->{controller}->failed($token, 'socket-close');
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 1);
    is($h->{events}->[-1]->{phase}, 'native');
};

subtest 'stream switch discards template and cancels scheduled attempt' => sub {
    my $h = harness();
    $h->{prime}->();
    $h->{stream}->('stream-b');
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0);
    $h->{controller}->nativeDisconnected();
    is($h->{events}->[-1]->{phase}, 'unavailable');
};

subtest 'disable closes owned socket and policy rejection forbids retries' => sub {
    my $h = harness();
    $h->{prime}->();
    $h->{tick}->(3000);
    $h->{controller}->configure({ enabled => 0 });
    is($h->{sockets}->[0]->{closed}, 1);
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 1);
    
    my $p = harness();
    $p->{prime}->();
    $p->{tick}->(3000);
    $p->{controller}->failed($p->{sockets}->[0]->{token}, 'policy-rejected');
    $p->{tick}->(60000);
    is(@{$p->{sockets}}, 1);
    is($p->{events}->[-1]->{phase}, 'unavailable');
};

subtest 'disposed document never reconnects after new configuration' => sub {
    my $h = harness();
    $h->{prime}->();
    $h->{controller}->dispose();
    $h->{controller}->configure({ enabled => 1 });
    $h->{tick}->(60000);
    is(@{$h->{sockets}}, 0);
};

subtest 'ACK and heartbeat encoder round trips supported dialect and rejects malformed controls' => sub {
    is(ProtoMain::inspectTransportControl(ProtoMain::encodeTransport('hb'))->{type}, 'hb');
    my $ack = ProtoMain::inspectTransportControl(ProtoMain::encodeTransport('ack', '18446744073709551615', 'opaque'));
    is($ack->{id}, '18446744073709551615');
    is($ack->{payload}, 'opaque');
    is(ProtoMain::inspectTransportControl(ProtoMain::encodeTransport('ack', 0)), undef);
    is(ProtoMain::inspectTransportControl(ProtoMain::encodeTransport('hb', 1)), undef);
    is(ProtoMain::inspectTransportControl(pack("C", 255)), undef);
    like(dies { ProtoMain::encodeTransport('ack', -1) }, qr/RangeError/);
};

done_testing();
