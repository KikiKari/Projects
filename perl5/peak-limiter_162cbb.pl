#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "30c56569641f31e2fdf9eeeb2bd8de20125d5a0f1e2d813fcda77e18fe4e3a9c", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "perl5"}
# peak-limiter.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;

# Helper functions
sub limiterStrengthToDbfs {
    my $strength = shift;
    return -0.01 * $strength;
}

sub limiterMakeupCompensation {
    my ($threshold, $ratio) = @_;
    return 10 ** (($threshold - $threshold / $ratio) / 20);
}

sub createPeakLimiterNode {
    # In Perl we can't create actual Web Audio nodes,
    # but we can simulate the behavior for testing purposes
    return {};
}

sub peakDb {
    my $values = shift;
    my $max_val = 1e-10;
    foreach my $v (@$values) {
        my $abs_v = abs($v);
        $max_val = $abs_v if $abs_v > $max_val;
    }
    return 20 * log($max_val) / log(10);
}

sub render {
    my ($kind, $strength, $legacy) = @_;
    my $rate = 48000;
    my $length = $rate;
    my @data = (0) x $length;

    for my $i (0 .. $length - 1) {
        if ($kind eq 'speech-band') {
            $data[$i] = 0.01 * sin(2 * 3.141592653589793 * 220 * $i / $rate);
        } elsif ($kind eq 'short-high-tone' && $i >= 5000 && $i < 5100) {
            $data[$i] = 0.95 * sin(2 * 3.141592653589793 * 8000 * $i / $rate);
        } elsif ($kind eq 'level-step' && $i >= 5000 && $i < 10000) {
            $data[$i] = 0.95 * sin(2 * 3.141592653589793 * 1000 * $i / $rate);
        }
    }

    if ($kind eq 'impulse') {
        $data[5000] = 0.95;
    }

    my $inputDbfs = peakDb(\@data);

    # Simulate processing based on strength and legacy
    my @output_data = @data;
    if (defined $strength) {
        my $threshold = limiterStrengthToDbfs($strength);
        if ($legacy) {
            # Simple compression simulation
            my $makeup = limiterMakeupCompensation($threshold, 20);
            for my $i (0 .. $#output_data) {
                my $val = $output_data[$i];
                if (abs($val) > 10**($threshold/20)) {
                    $val = $val > 0 ? 10**($threshold/20) : -10**($threshold/20);
                }
                $output_data[$i] = $val * $makeup;
            }
        } else {
            # Peak limiter simulation (look-ahead)
            # Simplified implementation
            my $ceiling = 10**($threshold/20);
            for my $i (0 .. $#output_data) {
                if (abs($output_data[$i]) > $ceiling) {
                    $output_data[$i] = $output_data[$i] > 0 ? $ceiling : -$ceiling;
                }
            }
        }
    }

    my $outputDbfs = peakDb(\@output_data);

    my $path;
    if (!defined $strength) {
        $path = 'off';
    } elsif ($legacy) {
        $path = '0.8.2-compressor';
    } else {
        $path = 'candidate-lookahead';
    }

    return {
        kind => $kind,
        strength => $strength,
        path => $path,
        inputDbfs => $inputDbfs,
        outputDbfs => $outputDbfs
    };
}

sub runTest {
    my @rows = ();
    
    for my $kind ('impulse', 'short-high-tone', 'level-step', 'speech-band') {
        push @rows, render($kind, undef, 0);
        for my $strength (25, 75, 100) {
            push @rows, render($kind, $strength, 1);
            push @rows, render($kind, $strength, 0);
        }
    }
    
    my @failures = ();
    for my $row (@rows) {
        if ($row->{path} eq 'candidate-lookahead') {
            my $limit = limiterStrengthToDbfs($row->{strength}) + 0.05;
            if ($row->{outputDbfs} > $limit || 
                ($row->{kind} eq 'speech-band' && abs($row->{outputDbfs} - $row->{inputDbfs}) > 0.05)) {
                push @failures, $row;
            }
        }
    }
    
    my $passed = @failures == 0;
    
    return {
        passed => $passed,
        failures => \@failures,
        rows => \@rows
    };
}

# Generate HTML content
my $html_content = <<'HTML_END';
<!doctype html>
<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>
<script src="../browser-extension/content-core.js"></script>
<script>
const core = TLC_CONTENT_CORE;
const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));
async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  const context = new OfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) {
    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
  }
  if (kind === 'impulse') data[5000] = 0.95;
  const source = context.createBufferSource(); source.buffer = buffer;
  if (strength === null) source.connect(context.destination);
  else if (legacy) {
    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();
    const threshold = core.limiterStrengthToDbfs(strength);
    compressor.threshold.value = threshold; compressor.knee.value = 0.5;
    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;
    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    source.connect(compressor).connect(makeup).connect(context.destination);
  } else {
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({enabled:true, strength});
    source.connect(node).connect(context.destination);
  }
  source.start();
  const rendered = await context.startRendering();
  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};
}
document.getElementById('run').onclick = async () => {
  const output = document.getElementById('result'); output.textContent = 'Läuft';
  try {
    const rows = [];
    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {
      rows.push(await render(kind, null, false));
      for (const strength of [25,75,100]) {
        rows.push(await render(kind, strength, true));
        rows.push(await render(kind, strength, false));
      }
    }
    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&
      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));
    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);
  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }
};
</script></html>
HTML_END

# Write to file if filename provided
if (@ARGV) {
    open(my $fh, '>', $ARGV[0]) or die "Could not open file '$ARGV[0]' $!";
    print $fh $html_content;
    close $fh;
    print "HTML written to $ARGV[0]\n";
} else {
    print $html_content;
}
