#!/usr/bin/env tclsh
# test_scanner_limits.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_scanner_limits.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Tcl does not have built-in support for modules like Node.js.
# We'll simulate the required functionality using procs and global variables.

# Simulate structuredClone by deep copying lists/dictionaries (basic implementation)
proc structuredClone {obj} {
    # For simplicity, assume obj is a dict or list that can be copied directly
    return $obj
}

# Simulate core module loading - we'll define necessary functions here
proc loadCore {} {
    # This would normally load content-core.js logic
    # For now, just provide stubs for what's needed
    proc recommendationCards {} {
        set cards {}
        for {set i 0} {$i < 301} {incr i} {
            lappend cards [dict create handle "creator$i" card [dict create]]
        }
        return $cards
    }

    proc recommendationItem {e p} {
        return [dict create handle [dict get $e handle] position $p title [string repeat "x" 300]]
    }

    proc text {str} {
        return $str
    }

    proc emit {type p} {
        global updates
        lappend updates [structuredClone $p]
        set updates $updates
    }

    proc emitRecommendationProgress {r status items} {
        global updates
        lappend updates [structuredClone [dict create status $status items $items]]
        set updates $updates
    }
}

# Simulate VM context execution with upvar and namespace evaluation
proc runCodeInContext {code contextVars} {
    # Create a temporary namespace to evaluate code
    set ns [namespace current]::tempCtx[expr {int(rand()*100000)}]
    namespace eval $ns {}

    # Import context variables into the namespace
    foreach {var val} $contextVars {
        namespace eval $ns [list variable $var $val]
    }

    # Evaluate the code in the new namespace
    namespace eval $ns $code

    # Return the scanRecommendations procedure from the namespace if it exists
    if {[namespace eval $ns {info procs scanRecommendations}] ne ""} {
        return [list $ns scanRecommendations]
    } else {
        error "scanRecommendations function not found"
    }
}

# Main test script
proc main {} {
    global argv0
    set scriptDir [file dirname [info script]]
    set root [file normalize "$scriptDir/.."]

    # Define sources to test
    set sources {
        {browser-extension/content.js {  function explicitCardSummary} true}
        {mobile-shared/webview-bridge.js {  function primaryVideo} false}
    }

    foreach src $sources {
        lassign $src file end browser

        set filePath [file join $root $file]
        if {![file exists $filePath]} {
            puts "SKIP missing source file: $file"
            continue
        }

        set fd [open $filePath r]
        set source [read $fd]
        close $fd

        # Find the relevant portion of the code
        set startIdx [string first "  async function scanRecommendations(run)" $source]
        if {$startIdx == -1} {
            error "Could not find scanRecommendations function in $file"
        }

        set endIdx [string first $end $source $startIdx]
        if {$endIdx == -1} {
            error "Could not find end marker '$end' in $file"
        }

        set code [string range $source $startIdx $endIdx]

        if {[string length $code] <= 100} {
            error "Extracted code too short in $file"
        }

        # Test different values of n
        foreach n {1 50 51 299 300 301} {
            set updates {}
            set cards [loadRecommendationCards]

            set run [dict create limit [expr {min($n, 300)}] sourceUrl "https://www.tiktok.com/@creator/live" runId "test" cancelled false]

            # Prepare context variables
            set contextVars [list \
                root {} \
                scrollX 0 \
                scrollY 0 \
                innerHeight 800 \
                location [dict create href [dict get $run sourceUrl]] \
                Date {} \
                MouseEvent {} \
                setTimeout {{fn} {uplevel #0 $fn; return 1}} \
                window [dict create scrollX 0 scrollY 0 innerHeight 800 scrollTo {} scrollBy {}] \
                scrollTo {} \
                scrollBy {} \
                activeRecommendationScan $run \
                RECOMMENDATION_SCAN_MAX_ROUNDS 12 \
                RECOMMENDATION_SCAN_MAX_MS 45000 \
                recommendationCards loadRecommendationCards \
                recommendationItem recommendationItem \
                text text \
                emit emit \
                emitRecommendationProgress emitRecommendationProgress \
            ]

            # Load core functionality
            loadCore

            # Run the code in context
            set result [runCodeInContext $code $contextVars]
            lassign $result ns scanProc

            # Call scanRecommendations
            namespace eval $ns [list $scanProc $run]

            # Assertions
            if {[llength $updates] == 0} {
                error "No updates recorded"
            }

            set lastUpdate [lindex $updates end]
            if {[dict get $lastUpdate status] ne "complete"} {
                error "Expected status 'complete', got '[dict get $lastUpdate status]'"
            }

            set items [dict get $lastUpdate items]
            if {[llength $items] != [expr {min($n, 300)}]} {
                error "Expected [expr {min($n, 300)}] items, got [llength $items]"
            }

            if {[llength $items] > 0} {
                set lastItem [lindex $items end]
                set pos [dict get $lastItem position]
                if {$pos != [expr {min($n, 300)}]} {
                    error "Last item position expected [expr {min($n, 300)}], got $pos"
                }
            }
        }

        puts "PASS synthetic production scan loop: $file; 1,50,51,299,300,301"
    }
}

# Helper procedures
proc loadRecommendationCards {} {
    set cards {}
    for {set i 0} {$i < 301} {incr i} {
        lappend cards [dict create handle "creator$i" card [dict create scrollIntoView {} dispatchEvent {}]]
    }
    return $cards
}

proc recommendationItem {e p} {
    return [dict create handle [dict get $e handle] position $p title [string repeat "x" 300]]
}

proc text {str} {
    return $str
}

proc emit {type p} {
    global updates
    lappend updates [structuredClone $p]
    set updates $updates
}

proc emitRecommendationProgress {r status items} {
    global updates
    lappend updates [structuredClone [dict create status $status items $items]]
    set updates $updates
}

# Run main
main
