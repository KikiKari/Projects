#!/usr/bin/perl
# test_peak_limiter.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;

# Mocking required modules and functions
package ContentCore;
sub createPeakLimiter {
    my ($rate) = @_;
    # Simplified mock implementation
    return {
        delaySamples => int(0.005 * $rate),
        process => sub {
            my ($self, $input, $output, $enabled, $strength) = @_;
            # Simplified processing logic
            for my $ch (0 .. $#{$input}) {
                for my $i (0 .. $#{$input->[$ch]}) {
                    $output->[$ch][$i] = $input->[$ch][$i] * ($enabled ? 0.9 : 1.0);
                }
            }
        }
    };
}

sub limiterStrengthToDbfs {
    my ($strength) = @_;
    return -($strength / 100.0) * 60; # Simplified conversion
}

package main;

sub render {
    my ($signal, $strength, $rate, $enabled) = @_;
    $rate //= 48000;
    $enabled //= 1;

    my $kernel = ContentCore::createPeakLimiter($rate);
    my @output;
    for my $channel (@$signal) {
        push @output, [ (0) x (scalar(@$channel) + $kernel->{delaySamples}) ];
    }

    for (my $start = 0; $start < @{$output[0]}; $start += 128) {
        my $length = List::Util::min(128, @{$output[0]} - $start);
        my @input;
        for my $channel (@$signal) {
            my @segment = map { $channel->[$start + $_] // 0 } 0 .. $length - 1;
            push @input, \@segment;
        }
        my @suboutputs;
        for my $channel (@output) {
            push @suboutputs, [ @{$channel}[ $start .. $start + $length - 1 ] ];
        }
        $kernel->{process}->($kernel, \@input, \@suboutputs, $enabled, $strength);
        for my $i (0 .. $#suboutputs) {
            for my $j (0 .. $#{$suboutputs[$i]}) {
                $output[$i][$start + $j] = $suboutputs[$i][$j];
            }
        }
    }

    return { output => \@output, delay => $kernel->{delaySamples} };
}

sub peak {
    my ($channel) = @_;
    my $max = 0;
    for my $value (@$channel) {
        my $abs_value = abs($value);
        $max = $abs_value if $abs_value > $max;
    }
    return $max;
}

foreach my $rate (44100, 48000, 96000) {
    subtest "isolated and high-frequency peaks are bounded at $rate Hz" => sub {
        my @signal = (0) x $rate;
        $signal[1] = 1;
        $signal[127] = -1;
        for my $i (1000 .. 1099) {
            $signal[$i] = sin(2 * 3.141592653589793 * 8000 * $i / $rate);
        }
        my $previous = 1;
        foreach my $strength (25, 75, 100) {
            my $result = render([\@signal], $strength, $rate);
            my $output = $result->{output};
            my $delay = $result->{delay};
            my $measured = peak($output->[0]);
            my $ceiling = 10 ** (ContentCore::limiterStrengthToDbfs($strength) / 20);
            ok($measured <= $ceiling + 1e-7, "$measured exceeds $ceiling");
            ok($measured < $previous, "higher strength must attenuate more");
            ok($delay / $rate <= 0.01);
            $previous = $measured;
        }
    };
}

subtest "bypass preserves every sample with the documented delay" => sub {
    my @signal = map { sin($_ * 0.7) * 0.8 } 0 .. 9999;
    my $result = render([\@signal], 100, 48000, 0);
    my $output = $result->{output};
    my $delay = $result->{delay};
    is([ @{$output->[0]}[$delay .. $#{$output->[0]}] ], \@signal);
};

subtest "quiet speech-band signal is not permanently attenuated" => sub {
    my @signal = map { 0.01 * sin($_ * 2 * 3.141592653589793 * 200 / 48000) } 0 .. 47999;
    my $result = render([\@signal], 100);
    my $output = $result->{output};
    my $delay = $result->{delay};
    is([ @{$output->[0]}[$delay .. $#{$output->[0]}] ], \@signal);
};

subtest "linked stereo gain preserves balance and limits either channel" => sub {
    my @left = (0) x 1000; $left[127] = 0.5;
    my @right = (0) x 1000; $right[127] = 1;
    my $result = render([\@left, \@right], 100);
    my $output = $result->{output};
    my $delay = $result->{delay};
    is($output->[0][127 + $delay] * 2, $output->[1][127 + $delay]);
    ok(peak($output->[1]) <= 10 ** (-30 / 20) + 1e-7);
};

subtest "gain recovers after a transient and invalid samples cannot poison the graph" => sub {
    my @signal = (0) x 48000; $signal[10] = 1;
    $signal[100] = 'NaN'; $signal[200] = 'Inf';
    for my $i (24000 .. $#signal) { $signal[$i] = 0.01; }
    my $result = render([\@signal], 100);
    my $output = $result->{output};
    ok(all { defined $_ && $_ != 'Inf' && $_ != 'NaN' } @$output[0]);
    ok($output->[0][40000] > 0.00999);
};

subtest "empty input drains delayed audio and then returns to silence" => sub {
    my $kernel = ContentCore::createPeakLimiter(48000);
    my @block = (0.01) x 128;
    my @out = (0) x 128;
    $kernel->{process}->($kernel, [\@block], [\@out], 1, 100);
    for my $n (0 .. 3) {
        $kernel->{process}->($kernel, [], [\@out], 1, 100);
    }
    is(peak(\@out), 0);
};

done_testing();
