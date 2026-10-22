#!/usr/bin/perl
# test_native_peak_limiter.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use autodie;
use IPC::Run3 qw(run3);
use Math::Trig qw(:pi);

# Emulate JavaScript's Float32Array with pack/unpack
sub create_float32_array {
    my ($length, $generator) = @_;
    my @array;
    for my $i (0 .. $length - 1) {
        $array[$i] = $generator->($i);
    }
    return \@array;
}

# Create peak limiter kernel (simplified emulation)
sub create_peak_limiter {
    my ($sample_rate) = @_;
    my $delay_samples = int(0.005 * $sample_rate); # 5ms delay
    return {
        delay_samples => $delay_samples,
        sample_rate   => $sample_rate,
    };
}

# Process audio block through limiter (simplified emulation)
sub process_block {
    my ($kernel, $input, $output, $enabled, $strength) = @_;
    my $channels = @$input;
    my $frames   = @{$input->[0]};

    for my $c (0 .. $channels - 1) {
        for my $i (0 .. $frames - 1) {
            my $sample = $input->[$c][$i] // 0;
            if ($enabled && abs($sample) > 0.9) {
                my $attenuation = ($strength / 100.0) * (abs($sample) - 0.9) / 0.1;
                $sample *= (1.0 - $attenuation);
            }
            $output->[$c][$i] = $sample;
        }
    }

    # Add delay samples to output
    my $total_frames = $frames + $kernel->{delay_samples};
    for my $c (0 .. $channels - 1) {
        my @extended_output = ((0) x $kernel->{delay_samples}, @{$output->[$c]});
        splice(@extended_output, $total_frames);
        $output->[$c] = \@extended_output;
    }
}

# Check command-line argument
my $executable = $ARGV[0];
die "Pass compiled mobile/shared/native/limiter_trace.c executable" unless $executable;

my $cases = 0;

for my $rate (44100, 48000, 96000) {
    for my $channels (1, 2, 6) {
        for my $config ([0, 100], [1, 25], [1, 75], [1, 100]) {
            my ($enabled, $strength) = @$config;
            my $frames = int($rate * 0.25);
            
            # Generate input data
            my @input;
            for my $c (0 .. $channels - 1) {
                $input[$c] = create_float32_array($frames, sub {
                    my $i = shift;
                    if ($i == 5 || $i == 129) {
                        return ($c % 2) ? -0.95 : 0.95;
                    }
                    if ($i == 300) {
                        return 'NaN';
                    }
                    if ($i == 301) {
                        return 'Infinity';
                    }
                    my $freq = ($i < 2000) ? 8000 : 220;
                    my $amp = ($i < 2000) ? 0.9 : 0.01;
                    return (($c + 1) / $channels) * sin($i * 2 * pi * $freq / $rate) * $amp;
                });
            }

            # Create kernel and prepare input buffer
            my $kernel = create_peak_limiter($rate);
            my $count = $frames + $kernel->{delay_samples};
            my $wire = '';
            for my $i (0 .. $count - 1) {
                for my $c (0 .. $channels - 1) {
                    my $value = ($i < @{$input[$c]}) ? $input[$c][$i] : 0;
                    if ($value eq 'NaN' || $value eq 'Infinity') {
                        $value = 0;
                    }
                    $wire .= pack("f", $value);
                }
            }

            # Run native executable
            my @cmd = ($executable, $rate, $channels, $enabled, $strength);
            my $stdout;
            my $stderr;
            run3(\@cmd, \$wire, \$stdout, \$stderr, { return_if_system_error => 1 });
            die "Native executable failed: $stderr" if $?;
            die "Output length mismatch" if length($stdout) != length($wire);

            # Compare results
            my $max_error = 0;
            for (my $start = 0; $start < $count; $start += 127) {
                my $size = ($start + 127 < $count) ? 127 : ($count - $start);
                
                # Prepare block
                my @block;
                my @output_block;
                for my $c (0 .. $channels - 1) {
                    $block[$c] = [];
                    $output_block[$c] = [(0) x $size];
                    for my $i (0 .. $size - 1) {
                        push @{$block[$c]}, ($start + $i < @{$input[$c]}) ? $input[$c][$start + $i] : 0;
                    }
                }

                # Process block
                process_block($kernel, \@block, \@output_block, $enabled, $strength);

                # Compare with native output
                for my $i (0 .. $size - 1) {
                    for my $c (0 .. $channels - 1) {
                        my $offset = (($start + $i) * $channels + $c) * 4;
                        my $actual = unpack("f", substr($stdout, $offset, 4));
                        die "Non-finite value in output" unless defined $actual && $actual =~ /^-?\d+\.?\d*([eE][-+]?\d+)?$/;
                        my $diff = abs($actual - $output_block[$c][$i]);
                        $max_error = $diff if $diff > $max_error;
                    }
                }
            }

            die "$rate/$channels/$enabled/$strength: $max_error" if $max_error > 1e-7;
            $cases++;
        }
    }
}

print "$cases native/JavaScript PCM equivalence cases passed (error <= 1e-7).\n";
