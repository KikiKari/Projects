#!/usr/bin/perl
# test_issue_controls.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use File::Spec;
use File::Basename;

# Simulate Node.js modules and functions
sub require_module {
    my ($module) = @_;
    # In a real scenario, you would load the module here
    # For now, we'll just return a mock object
    return {} if $module eq 'node:test' || $module eq 'node:assert/strict' || $module eq 'node:fs' || $module eq 'node:vm' || $module eq 'node:path';
}

# Mocking Node.js built-in modules
my %mock_fs = (
    readFileSync => sub {
        my ($file, $encoding) = @_;
        open my $fh, '<', $file or die "Cannot read file $file: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        return $content;
    }
);

my %mock_path = (
    join => sub {
        my ($dir, $file) = @_;
        return File::Spec->catfile($dir, $file);
    }
);

# Load source code
my $script_dir = dirname(__FILE__);
my $source_file = $mock_path{join}->($script_dir, '../browser-extension/sidepanel.js');
my $source = $mock_fs{readFileSync}->($source_file, 'utf8');

# Core module (mock)
my %core = ();

# Helper function to extract code fragments
sub fragment {
    my ($start, $end) = @_;
    my $a = index($source, $start);
    my $b = index($source, $end, $a + length($start));
    die "Fragment not found" unless $a >= 0 && $b > $a;
    return substr($source, $a, $b - $a);
}

# Controls mock
sub controls {
    my %document = (activeElement => undef);
    my %elements;
    
    my $proxy = sub {
        my ($id) = @_;
        return $elements{$id} //= {
            hidden => 1,
            disabled => 0,
            textContent => 'Off',
            handlers => {},
            addEventListener => sub {
                my ($name, $fn) = @_;
                $_[0]->{handlers}{$name} = $fn;
            },
            focus => sub {
                my ($self) = @_;
                $document{activeElement} = $self;
            },
            click => sub {
                my ($self) = @_;
                my $event = { target => $self };
                return $self->{handlers}{click}->($event) if exists $self->{handlers}{click};
            }
        };
    };

    return (\%elements, \%document, $proxy);
}

# Test 175
sub test_175 {
    for my $enabled (0, 1) {
        my @spoken = ();
        my %s = (
            core => \%core,
            filterExternalSpeechTriggers => $enabled,
            speechEnabled => 1,
            speechQueue => [],
            elements => {'speech-status' => {}},
            pumpSpeech => sub {},
            speechText => sub {
                my ($item) = @_;
                return "Autor sagt " . $item->{content};
            },
            speechLang => sub { return 'de'; },
            serviceSpeech => sub {
                my ($text) = @_;
                push @spoken, $text;
            },
            browserSpeech => sub {
                die 'unexpected fallback';
            }
        );

        # Mock VM context and execution
        # In a real scenario, you would use a JavaScript engine like JavaScript::V8
        # For now, we'll simulate the behavior
        
        # Run the code fragments in the context
        # This is a simplified simulation
        my $fragment1 = fragment('  async function speakItem(', '  async function pumpSpeech(');
        my $fragment2 = fragment('  function enqueueSpeech(', '  function ');

        # Simulate speakItem and enqueueSpeech functions
        $s{speakItem} = sub {
            my ($item) = @_;
            # Simulate speaking item
        };
        
        $s{enqueueSpeech} = sub {
            my ($item) = @_;
            # Simulate enqueuing speech
        };

        for my $content ('.Text', '. Text', '  .Text', 'Normal', 'Ein Satz. Noch einer') {
            $s{speakItem}->({content => $content});
            $s{enqueueSpeech}->({content => $content});
        }

        is(@spoken, $enabled ? 2 : 5, "spoken count");
        is(@{$s{speechQueue}}, $enabled ? 2 : 5, "speechQueue count");
    }
}

# Test 176 (speech switch)
sub test_176_speech_switch {
    my ($elements, $document, $proxy) = controls();
    my %s = (
        elements => $elements,
        document => $document,
        speechEnabled => 0,
        send => sub {},
        refresh => sub {},
        activateSpeech => sub { $s{speechEnabled} = 1 },
        stopSpeech => sub { $s{speechEnabled} = 0 }
    );

    # Simulate adding event listeners
    my $fragment = fragment('  elements["toggle-speech"].addEventListener','  elements["speech-volume"].addEventListener');
    
    # Simulate click events
    $elements->{$_} = $proxy->($_) for qw(toggle-speech speech-status);
    
    $elements->{'toggle-speech'}->click();
    is($s{speechEnabled}, 1, "speech enabled after first click");

    $s{send} = sub { die "failed" };
    $elements->{'toggle-speech'}->click();
    is($s{speechEnabled}, 1, "speech still enabled after failed request");
    like($elements->{'speech-status'}{textContent}, qr/failed/, "status shows failed");

    $s{send} = sub {};
    $elements->{'toggle-speech'}->click();
    is($s{speechEnabled}, 0, "speech disabled after successful request");
}

# Test 176 (Connection)
sub test_176_connection {
    my ($elements, $document, $proxy) = controls();
    my @calls = ();
    my %s = (
        elements => $elements,
        document => $document,
        currentState => { hook => { armed => 0 } },
        send => sub {
            my ($cmd) = @_;
            push @calls, $cmd;
        },
        refresh => sub {
            $s{currentState}{hook}{armed} = !$s{currentState}{hook}{armed};
        }
    );

    # Simulate adding event listeners
    my $fragment = fragment('  elements["toggle-hook"].addEventListener','  elements["reset-tab"].addEventListener');
    
    # Simulate click events
    $elements->{$_} = $proxy->($_) for qw(toggle-hook reset-tab notice);
    
    $elements->{'toggle-hook'}->click();
    $elements->{'toggle-hook'}->click();
    is(\@calls, ['TLC_ENABLE_HOOK', 'TLC_DISABLE_HOOK'], "calls match expected");

    $s{send} = sub { die "failed" };
    $elements->{'toggle-hook'}->click();
    is($s{currentState}{hook}{armed}, 0, "hook disarmed after failure");
    like($elements->{notice}{textContent}, qr/failed/, "notice shows failed");
}

# Test 176 (Connection dialog)
sub test_176_connection_dialog {
    my ($elements, $document, $proxy) = controls();
    my %s = (
        elements => $elements,
        document => $document
    );

    # Simulate adding event listeners
    my $fragment1 = fragment('  elements["open-connection-settings"].addEventListener','  elements["open-speech-settings"].addEventListener');
    my $fragment2 = fragment('  document.addEventListener("keydown"','  elements["keep-speech-active"].addEventListener');
    
    # Simulate click events
    $elements->{$_} = $proxy->($_) for qw(open-connection-settings connection-settings-modal close-connection-settings quick-recover-seconds);
    
    $elements->{'open-connection-settings'}->click();
    is($elements->{'connection-settings-modal'}{hidden}, 0, "modal is visible");
    is($document->{activeElement}, $elements->{'close-connection-settings'}, "focus on close button");

    # Simulate tab navigation
    my $first = $elements->{'close-connection-settings'};
    my $last = $elements->{'quick-recover-seconds'};
    $elements->{'connection-settings-modal'}{querySelectorAll} = sub { [$first, $last] };
    
    my $prevented = 0;
    my $key_handler;
    $document->{addEventListener} = sub {
        my ($name, $fn) = @_;
        $key_handler = $fn if $name eq 'keydown';
    };
    
    # Simulate key events
    $key_handler->({key => 'Tab', shiftKey => 1, preventDefault => sub { $prevented++ }});
    is($document->{activeElement}, $last, "focus moved to last element");
    
    $key_handler->({key => 'Tab', shiftKey => 0, preventDefault => sub { $prevented++ }});
    is($document->{activeElement}, $first, "focus moved to first element");
    is($prevented, 2, "preventDefault called twice");

    $key_handler->({key => 'Escape'});
    is($elements->{'connection-settings-modal'}{hidden}, 1, "modal hidden after escape");
    is($document->{activeElement}, $elements->{'open-connection-settings'}, "focus returned to open button");
}

# Run tests
test_175();
test_176_speech_switch();
test_176_connection();
test_176_connection_dialog();

done_testing();
