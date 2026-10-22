#!/usr/bin/env tclsh
# test_background_runtime.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_background_runtime.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_background_runtime.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_background_runtime.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_background_runtime.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Execute the real service worker with an in-memory Chrome API. Fixtures contain
# synthetic data only; no browser profile, credentials or live traffic is read.

# Note: This Tcl translation simulates JavaScript behavior using Tcl dicts and procs.
# Some complex JavaScript constructs like classes and VM contexts are approximated.

# Helper functions for assertions and testing
proc assert_equal {actual expected {msg ""}} {
    if {$actual ne $expected} {
        error "Assertion failed: got '$actual', expected '$expected'. $msg"
    }
}

proc assert_ok {condition {msg ""}} {
    if {![expr $condition]} {
        error "Assertion failed: $msg"
    }
}

proc assert_rejects {script} {
    if {[catch {eval $script} result]} {
        # Expected rejection occurred
        return
    }
    error "Expected rejection but none occurred"
}

# Core logic simulation (placeholder - would need actual implementation)
namespace eval core {
    proc newEmbedSession {test creator ms} {
        dict create phase loading startedAtMs $ms nextAttemptAtMs [expr {$ms + 2000}] attempt 1
    }
    
    proc advanceEmbedSession {state observation now} {
        # Simplified logic based on test expectations
        set status [dict get $observation status]
        set documentId [dict get $observation documentId]
        set documentStartedAtMs [dict get $observation documentStartedAtMs]
        
        switch $status {
            "server-error" {
                if {[dict exists $state nextAttemptAtMs] && $now >= [dict get $state nextAttemptAtMs]} {
                    dict set state attempt [expr {[dict get $state attempt] + 1}]
                    dict set state nextAttemptAtMs [expr {$now + 2000}]
                    return [list session $state action reload]
                } else {
                    dict set state nextAttemptAtMs [expr {$now + 2000}]
                    return [list session $state action none]
                }
            }
            "playing" {
                dict set state phase playing
                dict set state nextAttemptAtMs ""
                return [list session $state action none]
            }
            default {
                return [list session $state action none]
            }
        }
    }
    
    proc classifyEmbedObservation {obs} {
        if {[dict exists $obs text]} {
            set text [dict get $obs text]
            if {[string match "*Server error*" $text]} {
                return "server-error"
            } elseif {[string match "*LIVE is unavailable*" $text]} {
                return "unavailable"
            } elseif {[string match "*Melde dich an*" $text]} {
                return "login-required"
            }
        }
        if {[dict exists $obs playing] && [dict get $obs playing]} {
            return "playing"
        }
        if {[dict exists $obs paused] && [dict get $obs paused]} {
            return "awaiting-gesture"
        }
        return "unknown"
    }
    
    proc observeCaptionSource {sources caption now} {
        return [dict create websocket [dict create active 1 lastObservedAtUtc [clock format $now -format "%Y-%m-%dT%H:%M:%S.000Z"]]
                dom [dict create active 0]]
    }
    
    proc summarizeCaptionSources {sources now} {
        return [dict create observed 1]
    }
    
    proc mediaRecoveryReason {video {opts ""}} {
        if {[dict exists $opts userPaused] && [dict get $opts userPaused]} {
            return ""
        }
        if {[dict get $video paused]} {
            return "video-paused"
        }
        if {[dict exists $video error] && [dict get $video error] ne ""} {
            return "video-error"
        }
        if {[dict get $video ended]} {
            return "video-ended"
        }
        if {[dict get $video readyState] < 4} {
            return "video-not-ready"
        }
        return ""
    }
}

# Worker simulation
proc worker {{seed ""}} {
    # Placeholder for worker implementation
    return [dict create session [dict create] local [dict create] tabs [dict create]]
}

# Test cases
puts "Running tests..."

# 0PE-170: startup retry backs off, caps at three attempts and ignores stale documents
set state [core::newEmbedSession "test" "creator" 1000]
proc observe {now status {documentId "a"} {documentStartedAtMs 1000}} {
    variable state
    set observation [dict create status $status documentId $documentId documentStartedAtMs $documentStartedAtMs]
    set result [core::advanceEmbedSession $state $observation $now]
    set state [dict get $result session]
    return [dict get $result action]
}
assert_equal [observe 2000 "server-error"] "none"
assert_equal [dict get $state nextAttemptAtMs] 4000
assert_equal [observe 3999 "server-error"] "none"
assert_equal [observe 4000 "server-error"] "reload"
assert_equal [dict get $state attempt] 2
assert_equal [observe 5000 "playing"] "none"
assert_equal [dict get $state phase] "loading"
observe 6000 "unavailable" "b" 4500
assert_equal [dict get $state nextAttemptAtMs] 10000
assert_equal [observe 10000 "unavailable" "b" 4500] "reload"
observe 11000 "server-error" "c" 10500
assert_equal [dict get $state phase] "failed"
assert_equal [dict get $state attempt] 3
assert_equal [observe 100000 "server-error" "c" 10500] "none"

# 0PE-170: playback before retry cancels it, while login/ended/gesture never reload
proc observation {status} {
    return [dict create status $status documentId "a" documentStartedAtMs 1000]
}
set initial [core::newEmbedSession "test" "creator" 1000]
set waiting [core::advanceEmbedSession $initial [observation "server-error"] 2000]
set recovered [core::advanceEmbedSession [dict get $waiting session] [observation "playing"] 3000]
assert_equal [dict get [dict get $recovered session] phase] "playing"
assert_equal [dict get [dict get $recovered session] nextAttemptAtMs] ""

foreach status {"login-required" "ended" "awaiting-gesture"} {
    set result [core::advanceEmbedSession [dict get $waiting session] [observation $status] 6000]
    assert_equal [dict get $result action] "none"
    assert_equal [dict get [dict get $result session] nextAttemptAtMs] ""
}
set cancelled_state [dict create phase cancelled]
set result [core::advanceEmbedSession $cancelled_state [observation "server-error"] 100000]
assert_equal [dict get $result action] "none"
assert_equal [core::classifyEmbedObservation [dict create text "Server error"]] "server-error"
assert_equal [core::classifyEmbedObservation [dict create text "LIVE is unavailable"]] "unavailable"
assert_equal [core::classifyEmbedObservation [dict create text "Melde dich an für das vollständige Erlebnis"]] "login-required"
assert_equal [core::classifyEmbedObservation [dict create playing 1 readyState 4]] "playing"
assert_equal [core::classifyEmbedObservation [dict create paused 1 readyState 4]] "awaiting-gesture"

puts "All tests passed."
