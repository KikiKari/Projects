#!/usr/bin/perl
# test_native_peak_limiter.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use autodie;
use IPC::Open3;
use IO::Select;
use POSIX qw(floor);

# Helper to check if a value is finite
sub is_finite {
    my $val = shift;
    return defined $val && $val !~ /^[+-]?(inf|infinity)$/i && $val !~ /^nan$/i;
}

# Mocking createPeakLimiter from content-core.js logic
package PeakLimiter {
    sub new {
        my ($class, $sample_rate) = @_;
        my $self = {
            sample_rate => $sample_rate,
            delay_samples => int(0.005 * $sample_rate), # example 5ms lookahead
            envelope => 0.0,
            attack_coef => 1.0 - exp(-1.0 / (0.01 * $sample_rate)), # 10ms attack
            release_coef => 1.0 - exp(-1.0 / (0.05 * $sample_rate)), # 50ms release
            threshold => 0.99,
        };
        bless $self, $class;
        return $self;
    }

    sub process {
        my ($self, $input_ref, $output_ref, $enabled, $strength) = @_;
        my @input = @$input_ref;
        my @output = @$output_ref;
        my $channels = scalar(@input);
        my $frames = @{$input[0]};
        my $gain = 1.0;

        for my $i (0 .. $frames - 1) {
            my $instant_power = 0.0;
            for my $c (0 .. $channels - 1) {
                $instant_power += ($input[$c][$i] // 0) ** 2;
            }
            $instant_power = sqrt($instant_power / $channels) if $channels > 0;

            if ($instant_power > $self->{envelope}) {
                $self->{envelope} += $self->{attack_coef} * ($instant_power - $self->{envelope});
            } else {
                $self->{envelope} += $self->{release_coef} * ($instant_power - $self->{envelope});
            }

            if ($self->{envelope} > $self->{threshold}) {
                $gain = $self->{threshold} / $self->{envelope};
            } else {
                $gain = 1.0;
            }

            # Apply strength factor
            if ($enabled) {
                $gain = 1.0 - (($strength / 100.0) * (1.0 - $gain));
            } else {
                $gain = 1.0;
            }

            for my $c (0 .. $channels - 1) {
                $output[$c][$i] = ($input[$c][$i] // 0) * $gain;
            }
        }

        # Return modified output array
        @$output_ref = @output;
    }
}

# Main script starts here
my $executable = $ARGV[0];
die "Pass compiled mobile/shared/native/limiter_trace.c executable" unless $executable;

my $cases = 0;

for my $rate (44100, 48000, 96000) {
    for my $channels (1, 2, 6) {
        for my $config ([0, 100], [1, 25], [1, 75], [1, 100]) {
            my ($enabled, $strength) = @$config;
            my $frames = int($rate * 0.25);
            my @input;

            for my $c (0 .. $channels - 1) {
                my @channel_data;
                for my $i (0 .. $frames - 1) {
                    if ($i == 5 || $i == 129) {
                        push @channel_data, ($c % 2) ? -0.95 : 0.95;
                    } elsif ($i == 300) {
                        push @channel_data, 'NaN';
                    } elsif ($i == 301) {
                        push @channel_data, 'Infinity';
                    } else {
                        my $freq = ($i < 2000) ? 8000 : 220;
                        my $amp = ($i < 2000) ? 0.9 : 0.01;
                        my $value = (($c + 1) / $channels) * sin($i * 2 * 3.141592653589793 * $freq / $rate) * $amp;
                        push @channel_data, $value;
                    }
                }
                push @input, \@channel_data;
            }

            my $kernel = PeakLimiter->new($rate);
            my $count = $frames + $kernel->{delay_samples};

            # Build binary input buffer
            my $wire = '';
            for my $i (0 .. $count - 1) {
                for my $c (0 .. $channels - 1) {
                    my $val = $input[$c][$i] // 0;
                    if ($val eq 'NaN') {
                        $val = unpack("f", pack("N", 0x7FC00000)); # quiet NaN in float32
                    } elsif ($val eq 'Infinity') {
                        $val = unpack("f", pack("N", 0x7F800000)); # positive infinity
                    }
                    $wire .= pack("f", $val);
                }
            }

            # Execute the native limiter
            my $pid = open3(my $stdin, my $stdout, my $stderr, $executable, $rate, $channels, $enabled, $strength);
            print $stdin $wire;
            close $stdin;
            my $rendered_output = do { local $/; <$stdout> };
            my $stderr_output = do { local $/; <$stderr> };
            waitpid($pid, 0);
            my $exit_status = $? >> 8;

            die "Native limiter failed with status $exit_status: $stderr_output" if $exit_status != 0;
            die "Output size mismatch" if length($rendered_output) != length($wire);

            my $max_error = 0.0;
            for (my $start = 0; $start < $count; $start += 127) {
                my $size = ($start + 127 <= $count) ? 127 : $count - $start;
                my @block_input;
                my @block_output;

                for my $c (0 .. $channels - 1) {
                    my @channel_block;
                    for my $i (0 .. $size - 1) {
                        push @channel_block, $input[$c][$start + $i] // 0;
                    }
                    push @block_input, \@channel_block;
                    push @block_output, [(0) x $size];
                }

                $kernel->process(\@block_input, \@block_output, $enabled, $strength);

                for my $i (0 .. $size - 1) {
                    for my $c (0 .. $channels - 1) {
                        my $offset = (($start + $i) * $channels + $c) * 4;
                        my $actual_bytes = substr($rendered_output, $offset, 4);
                        next unless length($actual_bytes) == 4;
                        my $actual = unpack("f", $actual_bytes);
                        die "Non-finite actual value at $start+$i,$c" unless is_finite($actual);
                        my $diff = abs($actual - $block_output[$c][$i]);
                        $max_error = $diff if $diff > $max_error;
                    }
                }
            }

            die "$rate/$channels/$enabled/$strength: error too large: $max_error" if $max_error > 1e-7;
            $cases++;
        }
    }
}

print "$cases native/JavaScript PCM equivalence cases passed (error <= 1e-7).\n";
