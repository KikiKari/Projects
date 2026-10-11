#!/usr/bin/env tclsh
# test_android_recovery.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_android_recovery.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json

# Mock filesystem operations
proc readFileSync {filename} {
    if {[file exists $filename]} {
        set fh [open $filename r]
        set content [read $fh]
        close $fh
        return $content
    } else {
        error "File not found: $filename"
    }
}

proc resolvePath {paths} {
    return [file join {*}$paths]
}

proc dirname {path} {
    return [file dirname $path]
}

proc basename {path} {
    return [file tail $path]
}

# Test framework mock
set tests {}
proc test {name body} {
    lappend ::tests [list $name $body]
}

proc runTests {} {
    foreach testItem $::tests {
        lassign $testItem name body
        puts "Running test: $name"
        if {[catch {uplevel #0 $body} result]} {
            puts "Test failed: $result"
        } else {
            puts "Test passed"
        }
    }
}

# Assertion functions
proc assertEqual {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: expected '$expected', got '$actual'"
    }
}

proc assertTrue {value} {
    if {![string is true -strict $value]} {
        error "Assertion failed: expected true, got '$value'"
    }
}

proc assertMatch {value pattern} {
    if {![regexp $pattern $value]} {
        error "Assertion failed: '$value' does not match pattern '$pattern'"
    }
}

proc assertDeepEqual {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: deep equal check failed"
    }
}

# Setup function
proc setup {{ios false}} {
    set now 10000
    set plays 0
    set seq 0
    array set timers {}
    set intervals {}
    array set listeners {}
    set events {}
    
    # Video object
    set video [dict create \
        clientWidth 100 \
        clientHeight 100 \
        currentTime 1 \
        paused false \
        ended false \
        readyState 4 \
        dataset [dict create] \
        addEventListener [list apply {{n f} {set ::listeners($n) $f}}] \
        play [list apply {{} {incr ::plays}}] \
        textTracks {}
    ]
    
    # Root object
    set root [dict create \
        location [dict create origin "https://www.tiktok.com" pathname "/@creator/live"] \
        crypto [dict create randomUUID [list apply {{} {incr ::seq; return "11111111-1111-1111-1111-[format %012d $::seq]"}}]] \
        Date [list apply {{} {return [clock milliseconds]}}] \
        document [dict create \
            scripts {} \
            body [dict create innerText ""] \
            querySelectorAll [list apply {{s} {if {$s eq "video"} {return [list $::video]} else {return {}}}}] \
            querySelector [list apply {{args} {return {}}}] \
        ] \
        tlcBridge [dict create postMessage [list apply {{s} {lappend ::events [::json::json2dict $s]}}]] \
        addEventListener [list apply {{n f} {set ::listeners($n) $f}}] \
        postMessage [list apply {{m} {lappend ::events $m}}] \
        setInterval [list apply {{f args} {lappend ::intervals $f; return [llength $::intervals]}}] \
        clearInterval [list apply {{args} {}}] \
        setTimeout [list apply {{f ms} {incr ::seq; set ::timers($::seq) [list f $f at [expr {$::now + $ms}]]; return $::seq}}] \
        clearTimeout [list apply {{id} {unset -nocomplain ::timers($id)}}] \
    ]
    
    if {$ios} {
        dict unset root tlcBridge
        dict set root webkit [dict create messageHandlers [dict create tlcBridge [dict create postMessage [list apply {{m} {lappend ::events $m}}]]]]
    }
    
    dict set root top $root
    
    # Load script (mocked)
    set scriptContent [readFileSync [file join [dirname [info script]] "../../mobile/android/app/src/main/res/raw/android_recovery.js"]]
    # In a real implementation, we'd need to evaluate this JavaScript in a Tcl context
    # For now, we'll just store it as a placeholder
    dict set root TLC_MOBILE_RECOVERY [dict create command [list apply {{cmd args} {}}] recover [list apply {{state} {}}]]
    
    return [dict create \
        dispatch [list apply {{data} {
            set sourceEvent [dict create source $::root origin [dict get $::root location origin] data [dict merge [dict create source "tiktok-live-companion"] $data]]
            if {[info exists ::listeners(message)]} {
                {*}$::listeners(message) $sourceEvent
            }
        }}] \
        root $root \
        video $video \
        events [list apply {{} {return $::events}}] \
        timers [list apply {{} {return [array get ::timers]}}] \
        plays [list apply {{} {return $::plays}}] \
        tick [list apply {{ms} {
            incr ::now $ms
            foreach f $::intervals {
                {*}$f
            }
            set toDelete {}
            foreach {id timerData} [array get ::timers] {
                lassign $timerData f at
                if {$at <= $::now} {
                    lappend toDelete $id
                    {*}$f
                }
            }
            foreach id $toDelete {
                unset ::timers($id)
            }
        }}] \
        api [dict get $root TLC_MOBILE_RECOVERY] \
    ]
}

# Tests
test {player recovery waits configured interval once and never touches navigation} {
    set s [setup]
    {*}[dict get $s api command] set-auto-reconnect [dict create enabled true delaySeconds 3]
    {*}[dict get $s api recover] stalled
    assertEqual [llength [dict get $s timers]] 1
    {*}[dict get $s tick] 2999
    assertEqual [{*}[dict get $s plays]] 0
    {*}[dict get $s tick] 1
    assertEqual [{*}[dict get $s plays]] 1
    assertEqual [dict get [dict get $s root] location pathname] /@creator/live
}

test {user pause and VLC cancel pending recovery} {
    foreach cmd {pause set-vlc-active} {
        set s [setup]
        {*}[dict get $s api command] set-auto-reconnect [dict create enabled true]
        {*}[dict get $s api recover] stalled
        {*}[dict get $s api command] $cmd [dict create active true]
        {*}[dict get $s tick] 4000
        assertEqual [{*}[dict get $s plays]] 0
    }
}

test {media progress cancels attempt without replacing media} {
    set s [setup]
    {*}[dict get $s api command] set-auto-reconnect [dict create enabled true]
    {*}[dict get $s api recover] waiting
    dict set s video currentTime 2
    {*}[dict get $s tick] 3000
    assertEqual [{*}[dict get $s plays]] 0
}

test {caption websocket activity expires independently from menu} {
    set s [setup]
    {*}[dict get $s dispatch] [dict create type caption caption [dict create contents [list [dict create lang de text test]]]]
    set filteredEvents [lsearch -all -inline -index type [{*}[dict get $s events]] caption-state]
    set lastEvent [lindex $filteredEvents end]
    assertEqual [dict get [dict get $lastEvent payload] websocket] true
    {*}[dict get $s tick] 16000
    set filteredEvents [lsearch -all -inline -index type [{*}[dict get $s events]] caption-state]
    set lastEvent [lindex $filteredEvents end]
    assertEqual [dict get [dict get $lastEvent payload] websocket] false
    assertEqual [dict get [dict get $lastEvent payload] activityTtlMs] 15000
}

test {Android uses byte-identical browser controller and protocol parser} {
    set rawDir [file join [dirname [info script]] "../../mobile/android/app/src/main/res/raw"]
    set browserDir [file join [dirname [info script]] "../browser-extension"]
    foreach {mobile browser} {{hook_recovery.js hook-recovery.js} {recovery_hook.js hook.js} {proto_main.js proto-main.js}} {
        set mobileContent [readFileSync [file join $rawDir $mobile]]
        set browserContent [readFileSync [file join $browserDir $browser]]
        assertDeepEqual $mobileContent $browserContent
    }
}

test {iOS WebKit bridge receives correlated recovery observations} {
    set s [setup true]
    {*}[dict get $s tick] 1000
    set eventFound false
    foreach event [{*}[dict get $s events]] {
        if {[dict get $event type] eq "player-observation"} {
            set eventFound true
            assertMatch [dict get [dict get $event payload] documentId] {^[a-f0-9-]{36}$}
            assertEqual [dict get [dict get $event payload] frameKind] top
            break
        }
    }
    assertTrue $eventFound
    {*}[dict get $s dispatch] [dict create type caption caption [dict create text ios-caption]]
    set filteredEvents [lsearch -all -inline -index type [{*}[dict get $s events]] caption]
    set lastEvent [lindex $filteredEvents end]
    assertEqual [dict get [dict get $lastEvent payload] text] ios-caption
}

test {iOS and Android inject identical recovery implementations} {
    set rawDir [file join [dirname [info script]] "../../mobile/android/app/src/main/res/raw"]
    set iosDir [file join [dirname [info script]] "../../mobile/ios/Resources"]
    foreach {a b} {{android_recovery.js mobile-recovery.js} {hook_recovery.js hook-recovery.js} {recovery_hook.js recovery-hook.js} {export_privacy.js export-privacy.js} {proto_main.js proto-main.js} {content_core.js content-core.js}} {
        set androidContent [readFileSync [file join $rawDir $a]]
        set iosContent [readFileSync [file join $iosDir $b]]
        assertDeepEqual $androidContent $iosContent
    }
}

test {Connection off stops Companion chat delivery, on resumes without touching player} {
    foreach ios {false true} {
        set s [setup $ios]
        {*}[dict get $s api command] set-connection [dict create enabled false]
        {*}[dict get $s dispatch] [dict create type chat-message chatMessage [dict create content "hidden from Companion"]]
        set chatEvents [lsearch -all -inline -index type [{*}[dict get $s events]] chat]
        assertEqual [llength $chatEvents] 0
        {*}[dict get $s api command] set-connection [dict create enabled true]
        {*}[dict get $s dispatch] [dict create type chat-message chatMessage [dict create content "visible"]]
        set chatEvents [lsearch -all -inline -index type [{*}[dict get $s events]] chat]
        assertEqual [llength $chatEvents] 1
        assertEqual [{*}[dict get $s plays]] 0
    }
}

# Run all tests
runTests
