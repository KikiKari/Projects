#!/usr/bin/env tclsh
# test_sidepanel_player_guard.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_sidepanel_player_guard.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Tcl does not have built-in modules for fs, vm, assert, or path like Node.js.
# We need to implement or simulate their behavior using available Tcl commands.

# Simulate reading file content
proc readFileSync {filename} {
    if {[catch {open $filename r} fileId]} {
        error "Could not open file: $filename"
    }
    set content [read $fileId]
    close $fileId
    return $content
}

# Simulate path joining (basic implementation)
proc joinPath {args} {
    return [join $args "/"]
}

# Get directory name of the current script
set __dirname [file dirname $argv0]

# Read source file
set source [readFileSync [joinPath $__dirname "../browser-extension/sidepanel.js"]]

# Find indices of functions
set start [string first "  async function refreshPlayer()" $source]
set end [string first "  function setButtonBusy" $source $start]

# Basic assertion
if {$start == -1 || $end <= $start} {
    error "Function boundaries not found in source"
}

# Extract the relevant code snippet
set codeSnippet [string range $source $start $end-1]

# Global variables to simulate JavaScript context
set activeTabId 1
set activeIsTikTok true
set playerContextGeneration 0
set calls 0
set reply ""
set rendered {}

# Mock send function
proc send {} {
    global calls reply
    incr calls
    # In JS this returns a Promise that resolves when reply is called
    # In Tcl we'll simulate by storing the continuation
    return "pending"
}

# Mock renderPlayer function
proc renderPlayer {state} {
    global rendered
    lappend rendered $state
}

# Define refreshPlayer procedure based on extracted code
# Note: This is a simplified translation assuming the logic can be replicated
proc refreshPlayer {} {
    global activeTabId activeIsTikTok playerContextGeneration calls reply rendered

    # Only proceed if activeIsTikTok is true
    if {!$activeIsTikTok} {
        return
    }

    # Increment generation before async operation
    incr playerContextGeneration

    # Store current context at time of call
    set contextTabId $activeTabId
    set contextGeneration $playerContextGeneration

    # Simulate async send and wait for reply
    set status [send]
    
    # Wait for reply (simulated here as immediate execution)
    # In real scenario would involve event loop or callbacks
    
    # When reply comes back, check if context still matches
    after idle [list handleReply $contextTabId $contextGeneration]
}

proc handleReply {contextTabId contextGeneration} {
    global activeTabId playerContextGeneration rendered reply
    
    # Check if context is still valid
    if {$contextTabId == $activeTabId && $contextGeneration == $playerContextGeneration} {
        # Render the player state
        renderPlayer "playing:true"
    } else {
        # Ignore stale response
    }
}

# Main test procedure
proc main {} {
    global activeTabId activeIsTikTok playerContextGeneration calls rendered reply codeSnippet

    # Reset state
    set activeTabId 1
    set activeIsTikTok true
    set playerContextGeneration 0
    set calls 0
    set rendered {}

    # First call - should be ignored due to tab change
    set pending [refreshPlayer]
    set activeTabId 2
    # Simulate reply coming back after tab changed
    set reply {response: {playerState: {playing: true}}}
    # No rendering expected because tab changed
    
    # Check rendered length is 0
    if {[llength $rendered] != 0} {
        error "FAIL: Old tab response must be ignored"
    }

    # Change to non-TikTok tab - should not poll
    set activeIsTikTok false
    refreshPlayer
    if {$calls != 1} {
        error "FAIL: Non-TikTok tabs must not be polled"
    }

    # Change back to TikTok tab
    set activeIsTikTok true
    set pending [refreshPlayer]
    set reply {response: {playerState: {playing: true}}}
    # Should render now
    
    # Check rendered length is 1
    if {[llength $rendered] != 1} {
        error "FAIL: Current tab response must render"
    }

    # Another call with context invalidation
    set pending [refreshPlayer]
    set activeTabId 3
    incr playerContextGeneration
    set activeTabId 2
    incr playerContextGeneration
    set reply {response: {playerState: {playing: false}}}
    # Should not revive old response
    
    # Check rendered length is still 1
    if {[llength $rendered] != 1} {
        error "FAIL: Returning to the same tab must not revive an old response"
    }

    # Check source contains expected pattern
    if {![regexp {async function refresh\(\)\s*\{\s*playerContextGeneration\+\+;} $codeSnippet]} {
        error "FAIL: Context invalidation must precede asynchronous tab lookup"
    }

    puts "PASS: stale tab response ignored, non-TikTok polling skipped, current response rendered"
}

# Run main test and catch errors
if {[catch {main} error]} {
    puts stderr $error
    exit 1
}
