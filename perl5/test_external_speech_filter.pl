#!/usr/bin/perl
# test_external_speech_filter.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;

# Mock the required functions from content-core.js
sub shouldFilterExternalSpeechTrigger {
    my ($text, $enabled, $prefixes) = @_;
    $prefixes //= '.';
    return 0 unless $enabled;
    my $trimmed_text = $text;
    $trimmed_text =~ s/^\s+//;
    for my $prefix (split //, $prefixes) {
        if (index($trimmed_text, $prefix) == 0) {
            return 1;
        }
    }
    return 0;
}

sub normalizeExternalSpeechTriggerCharacters {
    my ($text) = @_;
    return '.' unless defined $text;
    $text =~ s/^\s+|\s+$//g;
    $text =~ s/["' ]//g;
    $text =~ s/[!]+$//;
    return $text;
}

# Tests
for my $enabled (0, 1) {
    for my $text ('.Text', '. Text', '  .Text', "\t\n. Text", 'Normal', 'Ein Satz. Noch einer', '') {
        my $expected = $enabled && $text =~ /^\s*\./ ? 1 : 0;
        is(shouldFilterExternalSpeechTrigger($text, $enabled), $expected, sprintf('enabled=%s, text="%s"', $enabled, $text));
    }
}

# 0PE-187: individual literal prefixes, commas and semicolons are not separators
for my $enabled (0, 1) {
    for my $text ('.Hallo', ',Hallo', '- Hallo', '  , Hallo') {
        is(shouldFilterExternalSpeechTrigger($text, $enabled, '.,-'), $enabled, "prefix test: $text");
    }
    for my $text ('Hallo, zusammen.', 'Normal-Text', 'Hallo', '.') {
        is(shouldFilterExternalSpeechTrigger($text, $enabled, ',-'), 0, "non-prefix test: $text");
    }
    is(shouldFilterExternalSpeechTrigger(';Hallo', $enabled, ';'), $enabled, "semicolon prefix");
    is(shouldFilterExternalSpeechTrigger('[Hallo', $enabled, '['), $enabled, "bracket prefix");
    is(shouldFilterExternalSpeechTrigger('Hallo', $enabled, '['), 0, "no bracket prefix");
}

# 0PE-187: five Unicode scalar triggers, paste sanitization and explicit empty selection
is(normalizeExternalSpeechTriggerCharacters(undef), '.', 'undefined input');
is(normalizeExternalSpeechTriggerCharacters(''), '', 'empty string input');
is(normalizeExternalSpeechTriggerCharacters('.,-;:!' ), '.,-;:', 'punctuation with exclamation');
is(normalizeExternalSpeechTriggerCharacters(' a1 "\'.,- '), '.,-', 'mixed with spaces and quotes');
is(normalizeExternalSpeechTriggerCharacters('😀😁😂😃😄😅'), '😀😁😂😃😄', 'Unicode emojis');
is(shouldFilterExternalSpeechTrigger('😀Hallo', 1, '😀'), 1, 'Unicode prefix match');
is(shouldFilterExternalSpeechTrigger('.Hallo', 1, ''), 0, 'empty prefixes');
is(shouldFilterExternalSpeechTrigger('.Hallo', 1, ','), 0, 'wrong prefix');

done_testing();
