#!/usr/bin/env tclsh8.6
# test-skill-contract.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Regression checks for /tiktok_live_mon routing and monitor actions.

package require fileutil

set SKILL [file normalize [file join [file dirname [file dirname [info script]]] "SKILL.md"]]
set DISPATCHER "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url @name --quality auto --json"
set CONTROLLER "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok-monitorctl.sh"

# Read the skill file content
set fh [open $SKILL r]
set text [read $fh]
close $fh
set normalized_text [string map {"\n" " " "\r" " " "\t" " "} $text]
regsub -all {\s+} $normalized_text " " normalized_text

# Test procedures
proc test_bare_handle_uses_dispatcher_as_first_tool_call {} {
    global text normalized_text DISPATCHER
    if {[string first "dispatcher exec must be the first tool call" $normalized_text] == -1} {
        error "FAIL: dispatcher exec must be the first tool call not found"
    }
    if {[string first $DISPATCHER $text] == -1} {
        error "FAIL: DISPATCHER not found in text"
    }
    if {[string first "A bare handle never starts a daemon" $text] == -1} {
        error "FAIL: A bare handle never starts a daemon not found"
    }
}

proc test_slash_command_bypasses_the_model {} {
    global text
    set expected_list [list \
        "command-dispatch: tool" \
        "command-tool: tiktok_live_mon_command" \
        "command-arg-mode: raw"]
    
    foreach expected $expected_list {
        if {[string first $expected $text] == -1} {
            error "FAIL: $expected not found"
        }
    }
}

proc test_no_preliminary_playwright_or_dependency_probe {} {
    global normalized_text
    set expected_list [list \
        "Before this dispatcher call, do not invoke or inspect" \
        "`tiktok-check-profile.js`" \
        "Do not attempt to install or repair browser dependencies" \
        "failed preliminary tool call"]
    
    foreach expected $expected_list {
        if {[string first $expected $normalized_text] == -1} {
            error "FAIL: $expected not found"
        }
    }
}

proc test_direct_exec_without_shell_wrapper {} {
    global normalized_text
    set expected_list [list \
        "Invoke that executable directly as the exec command" \
        "Do not invoke `bash`" \
        "`bash -lc`" \
        "wrapper must not be attempted in the first place"]
    
    foreach expected $expected_list {
        if {[string first $expected $normalized_text] == -1} {
            error "FAIL: $expected not found"
        }
    }
}

proc test_success_json_wins_over_trailing_diagnostics {} {
    global normalized_text
    set expected_list [list \
        "display the final stdout JSON before trailing stderr diagnostics" \
        "regardless of its visual position" \
        "the tool execution succeeded" \
        "Never replace such a result with a generic tool-failure message" \
        "`node_available`"]
    
    foreach expected $expected_list {
        if {[string first $expected $normalized_text] == -1} {
            error "FAIL: $expected not found"
        }
    }
}

proc test_running_dispatcher_is_polled_without_restart {} {
    global text
    set expected_list [list \
        "Start exactly one dispatcher exec per request" \
        "do not rerun exec" \
        {sessionId: "NAME"} \
        "Continue polling that same name until completion"]
    
    foreach expected $expected_list {
        if {[string first $expected $text] == -1} {
            error "FAIL: $expected not found"
        }
    }
}

proc test_monitor_actions_remain_controller_backed {} {
    global text CONTROLLER
    set actions [list "start" "status" "stop"]
    
    foreach action $actions {
        set cmd "$CONTROLLER $action @name"
        if {[string first $cmd $text] == -1} {
            error "FAIL: $cmd not found"
        }
    }
    
    if {[string first "prevents duplicate active monitors" $text] == -1} {
        error "FAIL: prevents duplicate active monitors not found"
    }
    
    if {[string first "Without the current word `start`" $text] == -1} {
        error "FAIL: Without the current word `start` not found"
    }
}

proc test_one_shot_response_contract_covers_all_statuses {} {
    global text normalized_text
    set legacy "@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.\nVLC/MPV: not available\nMethod: <method>"
    
    if {[string first $legacy $text] == -1} {
        error "FAIL: legacy format not found"
    }
    
    set live_text "@<handle> is currently LIVE on TikTok.\nTitel: <room.title>"
    if {[string first $live_text $text] == -1} {
        error "FAIL: live text format not found"
    }
    
    set expected_list [list \
        "Stream-URLs:" \
        "<label> (HLS):" \
        "<label> (FLV):" \
        "exactly one URL and nothing else" \
        "No raw URL appears in plain text"]
    
    foreach expected $expected_list {
        if {[string first $expected $normalized_text] == -1} {
            error "FAIL: $expected not found"
        }
    }
    
    set statuses [list "live" "offline" "restricted" "overloaded" "dependency_missing" "technical_error"]
    
    foreach status $statuses {
        if {[string first $status $text] == -1} {
            error "FAIL: status $status not found"
        }
    }
}

proc test_invalid_current_input_is_not_taken_from_history {} {
    global text
    if {[string first "Derive the action, handle, hours, and poll interval only" $text] == -1} {
        error "FAIL: Derive the action, handle, hours, and poll interval only not found"
    }
    
    if {[string first "Never take them from" $text] == -1} {
        error "FAIL: Never take them from not found"
    }
}

# Main test execution
if {[catch {
    test_bare_handle_uses_dispatcher_as_first_tool_call
    test_slash_command_bypasses_the_model
    test_no_preliminary_playwright_or_dependency_probe
    test_direct_exec_without_shell_wrapper
    test_success_json_wins_over_trailing_diagnostics
    test_running_dispatcher_is_polled_without_restart
    test_monitor_actions_remain_controller_backed
    test_one_shot_response_contract_covers_all_statuses
    test_invalid_current_input_is_not_taken_from_history
    puts "All tests passed."
} error]} {
    puts $error
    exit 1
}
