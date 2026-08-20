#!/usr/bin/perl
# test-skill-contract.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;

# Regression checks for the documented /tiktok_live normal flow.

my $script_dir = dirname(__FILE__);
my $skill_file = File::Spec->catfile($script_dir, "..", "SKILL.md");
my $canonical_command = "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url \@handle --quality auto --json";
my $node_command = $canonical_command;

# Read SKILL.md content
open my $fh, '<:encoding(UTF-8)', $skill_file or die "Cannot open $skill_file: $!";
my $text = do { local $/; <$fh> };
close $fh;

# Normalize text by collapsing whitespace
my $normalized_text = join(' ', split(/\s+/, $text));

# Test functions
sub test_dispatcher_is_the_documented_first_action {
    _assert_in($text, "Make the existing dispatcher the first action");
    _assert_in($normalized_text, "first tool call of the request");
    _assert_count($text, $canonical_command, 2);
}

sub test_slash_command_bypasses_the_model {
    my @expected = (
        "command-dispatch: tool",
        "command-tool: tiktok_live_command",
        "command-arg-mode: raw"
    );
    for my $exp (@expected) {
        _assert_in($text, $exp);
    }
}

sub test_no_preliminary_playwright_or_dependency_probe {
    my @expected = (
        "Before this dispatcher call, do not invoke or inspect",
        "`tiktok-check-profile.js`",
        "Do not attempt to install or repair browser dependencies",
        "failed preliminary tool call"
    );
    for my $exp (@expected) {
        _assert_in($normalized_text, $exp);
    }
}

sub test_direct_exec_without_shell_wrapper {
    my @expected = (
        "Invoke that executable directly as the exec command",
        "Do not invoke `bash`",
        "`bash -lc`",
        "wrapper must not be attempted in the first place"
    );
    for my $exp (@expected) {
        _assert_in($normalized_text, $exp);
    }
}

sub test_success_json_wins_over_trailing_diagnostics {
    my @expected = (
        "display the final stdout JSON before trailing stderr diagnostics",
        "regardless of its visual position",
        "the tool execution succeeded",
        "Never replace such a result with a generic tool-failure message",
        "`node_available`"
    );
    for my $exp (@expected) {
        _assert_in($normalized_text, $exp);
    }
}

sub test_auto_host_and_bounded_node_fallback {
    my @expected = (
        "tools.exec.host=auto",
        "omit both the `host` and `node` fields",
        "retry exactly once",
        "least-loaded connected paired node",
        "host=node",
        $node_command,
        "Never replace it with"
    );
    for my $exp (@expected) {
        _assert_in($text, $exp);
    }
    
    _assert_in($normalized_text, "`technical_error`, `dependency_missing`, or `overloaded`");
    _assert_not_in($text, "host=gateway");
    _assert_in($text, "Never start a second node retry");
    _assert_in($text, "never\nchange the global exec host");
    _assert_in($text, "runtime block occurs before the Node allowlist");
    _assert_count($text, $canonical_command, 2);
}

sub test_public_contract_covers_legacy_and_rich_formats {
    my $legacy = "\@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.\nVLC/MPV: not available\nMethod: <validated method>";
    _assert_in($text, $legacy);
    
    my $live = "\@<handle> is currently LIVE on TikTok.\nTitel: <room.title>";
    _assert_in($text, $live);
    
    my @expected = (
        "Stream-URLs:",
        "<label> \\(HLS\\):",
        "<label> \\(FLV\\):",
        "Live seit: <HH:MM UTC> \\(<Xh Ym>\\)",
        "exactly one URL and nothing else",
        "degrades to the legacy three lines including the `VLC/MPV:` URL",
        "No raw URL appears in plain text"
    );
    for my $exp (@expected) {
        _assert_regex_in($normalized_text, $exp);
    }
}

sub test_existing_capabilities_are_preserved {
    my @capabilities = (
        "Node", "browser", "file", "directory", "configuration",
        "dependency", "diagnostic tools remain available"
    );
    for my $cap (@capabilities) {
        _assert_in($text, $cap);
    }
}

sub test_no_response_flag_is_documented {
    _assert_not_in($text, "--response");
}

sub test_atomic_output_and_synchronized_audio {
    my @expected = (
        "send it atomically",
        "Preserve every returned URL byte-for-byte",
        "channel voice output set to `always`",
        "Do not invoke the `tts` tool",
        "do not emit `\\[\\[tts:text\\]\\]` wrappers",
        "visible text remains the authoritative source"
    );
    for my $exp (@expected) {
        _assert_in($normalized_text, $exp);
    }
}

# Helper assertion functions
sub _assert_in {
    my ($haystack, $needle) = @_;
    if (index($haystack, $needle) == -1) {
        die "Assertion failed: '$needle' not found in text\n";
    }
}

sub _assert_not_in {
    my ($haystack, $needle) = @_;
    if (index($haystack, $needle) != -1) {
        die "Assertion failed: '$needle' should not be in text\n";
    }
}

sub _assert_regex_in {
    my ($haystack, $pattern) = @_;
    if ($haystack !~ /$pattern/) {
        die "Assertion failed: pattern '$pattern' not found in text\n";
    }
}

sub _assert_count {
    my ($haystack, $needle, $expected_count) = @_;
    my $count = 0;
    $count++ while $haystack =~ /\Q$needle\E/g;
    if ($count != $expected_count) {
        die "Assertion failed: expected $expected_count occurrences of '$needle', got $count\n";
    }
}

# Run all tests
test_dispatcher_is_the_documented_first_action();
test_slash_command_bypasses_the_model();
test_no_preliminary_playwright_or_dependency_probe();
test_direct_exec_without_shell_wrapper();
test_success_json_wins_over_trailing_diagnostics();
test_auto_host_and_bounded_node_fallback();
test_public_contract_covers_legacy_and_rich_formats();
test_existing_capabilities_are_preserved();
test_no_response_flag_is_documented();
test_atomic_output_and_synchronized_audio();

print "All tests passed!\n";
