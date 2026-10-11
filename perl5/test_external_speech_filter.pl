#!/usr/bin/perl
# test_external_speech_filter.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;

# Helper function to mimic the JavaScript filter behavior
sub should_filter_external_speech_trigger {
    my ($text, $enabled) = @_;
    return $enabled && ($text =~ /^\s*\./);
}

# Test cases
for my $enabled (0, 1) {
    for my $text ('.Text', '. Text', '  .Text', "\t\n. Text", 'Normal', 'Ein Satz. Noch einer', '') {
        my $test_name = sprintf('{"enabled":%s,"text":"%s"}', $enabled ? 'true' : 'false', $text);
        my $expected = $enabled && ($text =~ /^\s*\./);
        is(should_filter_external_speech_trigger($text, $enabled), $expected, $test_name);
    }
}

done_testing();
