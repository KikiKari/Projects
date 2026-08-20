#!/usr/bin/perl
# test-skill-contract.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use Test::More;

# Regression checks for /tiktok_live_mon routing and monitor actions.

my $script_dir = dirname(__FILE__);
my $skill_file = File::Spec->catfile($script_dir, "..", "SKILL.md");
my $dispatcher = "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url \@name --quality auto --json";
my $controller = "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok-monitorctl.sh";

# Read SKILL.md content
open my $fh, '<:encoding(UTF-8)', $skill_file or die "Cannot open $skill_file: $!";
my $text = do { local $/; <$fh> };
close $fh;
my $normalized_text = join(' ', split(/\s+/, $text));

# Test cases
sub test_bare_handle_uses_dispatcher_as_first_tool_call {
    like($normalized_text, qr/dispatcher exec must be the first tool call/, "dispatcher exec must be the first tool call");
    like($text, qr/\Q$dispatcher\E/, "Dispatcher path found in text");
    like($text, qr/A bare handle never starts a daemon/, "Daemon message found");
}

sub test_slash_command_bypasses_the_model {
    my @expected = (
        "command-dispatch: tool",
        "command-tool: tiktok_live_mon_command",
        "command-arg-mode: raw"
    );
    
    for my $expected (@expected) {
        like($text, qr/\Q$expected\E/, "Slash command bypass: $expected");
    }
}

sub test_no_preliminary_playwright_or_dependency_probe {
    my @expected = (
        "Before this dispatcher call, do not invoke or inspect",
        "`tiktok-check-profile.js`",
        "Do not attempt to install or repair browser dependencies",
        "failed preliminary tool call"
    );
    
    for my $expected (@expected) {
        like($normalized_text, qr/\Q$expected\E/, "No preliminary probe: $expected");
    }
}

sub test_direct_exec_without_shell_wrapper {
    my @expected = (
        "Invoke that executable directly as the exec command",
        "Do not invoke `bash`",
        "`bash -lc`",
        "wrapper must not be attempted in the first place"
    );
    
    for my $expected (@expected) {
        like($normalized_text, qr/\Q$expected\E/, "Direct exec without shell wrapper: $expected");
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
    
    for my $expected (@expected) {
        like($normalized_text, qr/\Q$expected\E/, "Success JSON wins: $expected");
    }
}

sub test_running_dispatcher_is_polled_without_restart {
    my @expected = (
        "Start exactly one dispatcher exec per request",
        "do not rerun exec",
        'sessionId: "NAME"',
        "Continue polling that same name until completion"
    );
    
    for my $expected (@expected) {
        like($text, qr/\Q$expected\E/, "Running dispatcher polled: $expected");
    }
}

sub test_monitor_actions_remain_controller_backed {
    for my $action (qw(start status stop)) {
        like($text, qr/\Q$controller $action \@name\E/, "Controller backed action: $action");
    }
    
    like($text, qr/prevents duplicate active monitors/, "Duplicate prevention mentioned");
    like($text, qr/Without the current word `start`/, "Start word context mentioned");
}

sub test_one_shot_response_contract_covers_all_statuses {
    my $legacy = "\@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.\nVLC/MPV: not available\nMethod: <method>";
    like($text, qr/\Q$legacy\E/, "Legacy response format found");
    
    my $live = "\@<handle> is currently LIVE on TikTok.\nTitel: <room.title>";
    like($text, qr/\Q$live\E/, "Live response format found");
    
    my @expected = (
        "Stream-URLs:",
        "<label> (HLS):",
        "<label> (FLV):",
        "exactly one URL and nothing else",
        "No raw URL appears in plain text"
    );
    
    for my $expected (@expected) {
        like($normalized_text, qr/\Q$expected\E/, "Stream URLs format: $expected");
    }
    
    my @statuses = qw(live offline restricted overloaded dependency_missing technical_error);
    for my $status (@statuses) {
        like($text, qr/\Q$status\E/, "Status $status found");
    }
}

sub test_invalid_current_input_is_not_taken_from_history {
    like($text, qr/Derive the action, handle, hours, and poll interval only/, "Input derivation instruction found");
    like($text, qr/Never take them from/, "History warning found");
}

# Run all tests
test_bare_handle_uses_dispatcher_as_first_tool_call();
test_slash_command_bypasses_the_model();
test_no_preliminary_playwright_or_dependency_probe();
test_direct_exec_without_shell_wrapper();
test_success_json_wins_over_trailing_diagnostics();
test_running_dispatcher_is_polled_without_restart();
test_monitor_actions_remain_controller_backed();
test_one_shot_response_contract_covers_all_statuses();
test_invalid_current_input_is_not_taken_from_history();

done_testing();
