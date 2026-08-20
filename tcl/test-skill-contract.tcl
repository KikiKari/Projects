#!/usr/bin/env tclsh8.6
# test-skill-contract.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Regression checks for the documented /tiktok_live normal flow.

package require fileutil
package require cmdline
package require json

namespace eval SkillContractTests {
    variable text
    variable normalized_text
    
    proc setUpClass {} {
        variable text
        variable normalized_text
        
        # Get script directory and resolve SKILL.md path
        set script_dir [file dirname [file normalize $::argv0]]
        set skill_file [file join [file dirname $script_dir] "SKILL.md"]
        
        # Read SKILL.md content
        set fh [open $skill_file r]
        set text [read $fh]
        close $fh
        
        # Normalize whitespace
        set normalized_text [regsub -all {\s+} $text " "]
    }
    
    proc assertIn {expected container msg} {
        if {[string first $expected $container] == -1} {
            error "$msg: '$expected' not found"
        }
    }
    
    proc assertNotIn {unexpected container msg} {
        if {[string first $unexpected $container] != -1} {
            error "$msg: '$unexpected' should not be present"
        }
    }
    
    proc assertEquals {actual expected msg} {
        if {$actual != $expected} {
            error "$msg: expected $expected, got $actual"
        }
    }
    
    proc test_dispatcher_is_the_documented_first_action {} {
        variable text
        variable normalized_text
        
        set canonical_command "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url @handle --quality auto --json"
        
        assertIn "Make the existing dispatcher the first action" $text "First action check failed"
        assertIn "first tool call of the request" $normalized_text "Tool call position check failed"
        assertEquals [regexp -all $canonical_command $text] 2 "Command count mismatch"
    }
    
    proc test_slash_command_bypasses_the_model {} {
        variable text
        
        foreach expected {
            "command-dispatch: tool"
            "command-tool: tiktok_live_command" 
            "command-arg-mode: raw"
        } {
            assertIn $expected $text "Slash command bypass check failed for: $expected"
        }
    }
    
    proc test_no_preliminary_playwright_or_dependency_probe {} {
        variable normalized_text
        
        foreach expected {
            "Before this dispatcher call, do not invoke or inspect"
            "`tiktok-check-profile.js`"
            "Do not attempt to install or repair browser dependencies"
            "failed preliminary tool call"
        } {
            assertIn $expected $normalized_text "Preliminary probe check failed for: $expected"
        }
    }
    
    proc test_direct_exec_without_shell_wrapper {} {
        variable normalized_text
        
        foreach expected {
            "Invoke that executable directly as the exec command"
            "Do not invoke `bash`"
            "`bash -lc`"
            "wrapper must not be attempted in the first place"
        } {
            assertIn $expected $normalized_text "Direct exec check failed for: $expected"
        }
    }
    
    proc test_success_json_wins_over_trailing_diagnostics {} {
        variable normalized_text
        
        foreach expected {
            "display the final stdout JSON before trailing stderr diagnostics"
            "regardless of its visual position"
            "the tool execution succeeded"
            "Never replace such a result with a generic tool-failure message"
            "`node_available`"
        } {
            assertIn $expected $normalized_text "JSON precedence check failed for: $expected"
        }
    }
    
    proc test_auto_host_and_bounded_node_fallback {} {
        variable text
        variable normalized_text
        
        set canonical_command "/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url @handle --quality auto --json"
        set node_command $canonical_command
        
        foreach expected {
            "tools.exec.host=auto"
            "omit both the `host` and `node` fields"
            "retry exactly once"
            "least-loaded connected paired node"
            "host=node"
            "Never replace it with"
        } {
            assertIn $expected $text "Auto host fallback check failed for: $expected"
        }
        
        assertIn "`technical_error`, `dependency_missing`, or `overloaded`" $normalized_text "Error types check failed"
        assertNotIn "host=gateway" $text "Gateway host should not be present"
        assertIn "Never start a second node retry" $text "Second retry check failed"
        assertIn "never\nchange the global exec host" $text "Global host change check failed"
        assertIn "runtime block occurs before the Node allowlist" $text "Runtime block check failed"
        assertEquals [regexp -all $canonical_command $text] 2 "Command count mismatch in auto host test"
    }
    
    proc test_public_contract_covers_legacy_and_rich_formats {} {
        variable text
        variable normalized_text
        
        set legacy "@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.\nVLC/MPV: not available\nMethod: <validated method>"
        
        assertIn $legacy $text "Legacy format check failed"
        assertIn "@<handle> is currently LIVE on TikTok.\nTitel: <room.title>" $text "LIVE format check failed"
        
        foreach expected {
            "Stream-URLs:"
            "<label> (HLS):"
            "<label> (FLV):"
            "Live seit: <HH:MM UTC> (<Xh Ym>)"
            "exactly one URL and nothing else"
            "degrades to the legacy three lines including the `VLC/MPV:` URL"
            "No raw URL appears in plain text"
        } {
            assertIn $expected $normalized_text "Rich formats check failed for: $expected"
        }
    }
    
    proc test_existing_capabilities_are_preserved {} {
        variable text
        
        foreach capability {
            "Node" "browser" "file" "directory" "configuration"
            "dependency" "diagnostic tools remain available"
        } {
            assertIn $capability $text "Capability preservation check failed for: $capability"
        }
    }
    
    proc test_no_response_flag_is_documented {} {
        variable text
        assertNotIn "--response" $text "Response flag should not be documented"
    }
    
    proc test_atomic_output_and_synchronized_audio {} {
        variable normalized_text
        
        foreach expected {
            "send it atomically"
            "Preserve every returned URL byte-for-byte"
            "channel voice output set to `always`"
            "Do not invoke the `tts` tool"
            "do not emit `[[tts:text]]` wrappers"
            "visible text remains the authoritative source"
        } {
            assertIn $expected $normalized_text "Atomic output check failed for: $expected"
        }
    }
    
    proc runTests {} {
        setUpClass
        
        # Run all test methods
        foreach test_proc [info procs test_*] {
            puts "Running $test_proc..."
            if {[catch {$test_proc} error]} {
                puts "FAIL: $test_proc - $error"
                return 1
            }
        }
        puts "All tests passed!"
        return 0
    }
}

# Main execution
if {[info script] eq $::argv0} {
    exit [SkillContractTests::runTests]
}
