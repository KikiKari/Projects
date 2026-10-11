#!/usr/bin/perl
# test_background_runtime.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_background_runtime.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_background_runtime.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_background_runtime.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use File::Spec;
use File::Basename;
use lib dirname(__FILE__) . '/../browser-extension';
require 'content-core.pl';
require 'export-privacy.pl';

subtest '0PE-170: startup retry backs off, caps at three attempts and ignores stale documents' => sub {
  my $state = newEmbedSession("test", "creator", 1000);
  my $observe = sub {
    my ($now, $status, $documentId, $documentStartedAtMs) = @_;
    $documentId //= "a";
    $documentStartedAtMs //= 1000;
    my $result = advanceEmbedSession($state, { status => $status, documentId => $documentId, documentStartedAtMs => $documentStartedAtMs }, $now);
    $state = $result->{session};
    return $result->{action};
  };
  is($observe->(2000, "server-error"), "none");
  is($state->{nextAttemptAtMs}, 4000);
  is($observe->(3999, "server-error"), "none");
  is($observe->(4000, "server-error"), "reload");
  is($state->{attempt}, 2);
  is($observe->(5000, "playing"), "none");
  is($state->{phase}, "loading", "old document cannot complete a newer attempt");
  $observe->(6000, "unavailable", "b", 4500);
  is($state->{nextAttemptAtMs}, 10000);
  is($observe->(10000, "unavailable", "b", 4500), "reload");
  $observe->(11000, "server-error", "c", 10500);
  is($state->{phase}, "failed");
  is($state->{attempt}, 3);
  is($observe->(100000, "server-error", "c", 10500), "none");
};

subtest '0PE-170: playback before retry cancels it, while login/ended/gesture never reload' => sub {
  my $observation = sub {
    my ($status) = @_;
    return { status => $status, documentId => "a", documentStartedAtMs => 1000 };
  };
  my $initial = newEmbedSession("test", "creator", 1000);
  my $waiting = advanceEmbedSession($initial, $observation->("server-error"), 2000)->{session};
  my $recovered = advanceEmbedSession($waiting, $observation->("playing"), 3000);
  is($recovered->{session}->{phase}, "playing");
  is($recovered->{session}->{nextAttemptAtMs}, undef);
  for my $status ("login-required", "ended", "awaiting-gesture") {
    my $result = advanceEmbedSession($waiting, $observation->($status), 6000);
    is($result->{action}, "none");
    is($result->{session}->{nextAttemptAtMs}, undef);
  }
  is(advanceEmbedSession({ %$initial, phase => "cancelled" }, $observation->("server-error"), 100000)->{action}, "none");
  is(classifyEmbedObservation({ text => "Server error" }), "server-error");
  is(classifyEmbedObservation({ text => "LIVE is unavailable" }), "unavailable");
  is(classifyEmbedObservation({ text => "Melde dich an für das vollständige Erlebnis" }), "login-required");
  is(classifyEmbedObservation({ playing => 1, readyState => 4 }), "playing");
  is(classifyEmbedObservation({ paused => 1, readyState => 4 }), "awaiting-gesture");
};

done_testing();
