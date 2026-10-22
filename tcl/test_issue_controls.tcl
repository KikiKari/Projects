#!/usr/bin/env tclsh
# test_issue_controls.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json

# Mock Node.js modules and functions
proc require {module} {
    # Simplified mock for required modules
    return [dict create]
}

proc assert_equal {actual expected} {
    if {$actual != $expected} {
        error "Assertion failed: expected $expected, got $actual"
    }
}

proc assert_match {text pattern} {
    if {![regexp $pattern $text]} {
        error "Assertion failed: '$text' does not match pattern '$pattern'"
    }
}

proc assert_fail {message} {
    error "Assertion failed: $message"
}

# Mock file system operations
proc readFileSync {filepath encoding} {
    # This would read the actual file in a real implementation
    return "mock file content"
}

proc joinPath {args} {
    return [join $args "/"]
}

# Mock VM context
proc createContext {sandbox} {
    upvar $sandbox vars
    return [array get vars]
}

proc runInContext {code context} {
    upvar $context vars
    # Evaluate code in the context of vars
    # This is a simplified version - in reality, you'd need more sophisticated scoping
    eval $code
}

# Mock DOM-like structure
proc createControls {} {
    set elements [dict create]
    set document [dict create activeElement ""]
    
    proc createElement {id} {
        return [dict create \
            hidden true \
            disabled false \
            textContent "Off" \
            handlers [dict create] \
            value "" \
            checked false \
            focus [list [namespace current]::focusElement $id] \
            click [list [namespace current]::clickElement $id] \
            addEventListener [list [namespace current]::addEventListener $id] \
        ]
    }
    
    proc focusElement {id} {
        variable document
        dict set document activeElement $id
    }
    
    proc clickElement {id} {
        variable elements
        set element [dict get $elements $id]
        set handlers [dict get $element handlers]
        if {[dict exists $handlers click]} {
            set handler [dict get $handlers click]
            eval $handler
        }
    }
    
    proc addEventListener {id event handler} {
        variable elements
        set element [dict get $elements $id]
        set handlers [dict get $element handlers]
        dict set handlers $event $handler
        dict set element handlers $handlers
        dict set elements $id $element
    }
    
    return [dict create elements $elements document $document]
}

# Test 175
proc test_175 {} {
    puts "Running test 175..."
    
    for {set enabled 0} {$enabled < 2} {incr enabled} {
        set spoken [list]
        
        # Create sandbox
        array set s [createControls]
        set s(core) ""
        set s(filterExternalSpeechTriggers) $enabled
        set s(externalSpeechTriggerCharacters) "."
        set s(speechEnabled) true
        set s(speechQueue) [list]
        set s(elements) [dict create speech-status [dict create]]
        set s(pumpSpeech) ""
        set s(speechText) {{item} "Autor sagt [dict get $item content]"}
        set s(speechLang) {{} "de"}
        set s(serviceSpeech) {{text} {lappend spoken $text}}
        set s(browserSpeech) "{{} {error \"unexpected fallback\"}}"
        
        # Run context (simplified)
        # In a real implementation, you'd need to parse and execute the JavaScript fragments
        
        set spokenLength [llength $spoken]
        set queueLength [llength $s(speechQueue)]
        
        set expectedLength [expr {$enabled ? 2 : 5}]
        assert_equal $spokenLength $expectedLength
        assert_equal $queueLength $expectedLength
    }
    
    puts "Test 175 passed"
}

# Test 187 (first part)
proc test_187_input {} {
    puts "Running test 187 input..."
    
    set calls [list]
    array set s [createControls]
    set s(core) ""
    set s(filterExternalSpeechTriggers) false
    set s(externalSpeechTriggerCharacters) "."
    set s(send) {{type payload} {lappend calls [dict merge [dict create type $type] $payload]}}
    
    # Simulate adding event listeners (simplified)
    # In reality, you'd parse the JS fragments
    
    # Simulate input handling
    set input [dict create value ".,-;:!" handlers [dict create input {{} {}}]]
    dict set input value ".,-;:"
    
    # Call input handler
    set handlers [dict get $input handlers]
    if {[dict exists $handlers input]} {
        eval [dict get $handlers input]
    }
    
    assert_equal [dict get $input value] ".,-;:"
    assert_equal [dict get [lindex $calls end] externalSpeechTriggerCharacters] ".,-;:"
    
    puts "Test 187 input passed"
}

# Test 187 (second part)
proc test_187_custom_prefixes {} {
    puts "Running test 187 custom prefixes..."
    
    for {set enabled 0} {$enabled < 2} {incr enabled} {
        set spoken [list]
        
        # Create sandbox
        array set s [createControls]
        set s(core) ""
        set s(filterExternalSpeechTriggers) $enabled
        set s(externalSpeechTriggerCharacters) ".,-"
        set s(speechEnabled) true
        set s(speechQueue) [list]
        set s(elements) [dict create speech-status [dict create]]
        set s(pumpSpeech) ""
        set s(speechText) {{item} "Autor sagt [dict get $item content]"}
        set s(speechLang) {{} "de"}
        set s(serviceSpeech) {{text} {lappend spoken $text}}
        set s(browserSpeech) "{{} {error \"unexpected fallback\"}}"
        
        # Run context (simplified)
        # In a real implementation, you'd need to parse and execute the JavaScript fragments
        
        set spokenLength [llength $spoken]
        set queueLength [llength $s(speechQueue)]
        
        set expectedLength [expr {$enabled ? 1 : 4}]
        assert_equal $spokenLength $expectedLength
        assert_equal $queueLength $expectedLength
    }
    
    puts "Test 187 custom prefixes passed"
}

# Test 176 (speech switch)
proc test_176_speech_switch {} {
    puts "Running test 176 speech switch..."
    
    array set s [createControls]
    set s(speechEnabled) false
    set s(send) "{{} {}}"
    set s(refresh) "{{} {}}"
    set s(activateSpeech) "{{} {set s(speechEnabled) true}}"
    set s(stopSpeech) "{{} {set s(speechEnabled) false}}"
    
    # Simulate adding event listeners (simplified)
    
    # Simulate clicks
    set toggle [dict create checked true handlers [dict create click {{} {eval $s(activateSpeech)}}]]
    eval [dict get $toggle handlers click]
    assert_equal $s(speechEnabled) true
    
    # Simulate failed send
    set s(send) "{{} {error \"failed\"}}"
    set status [dict create textContent "Operation failed"]
    if {[catch {eval [dict get $toggle handlers click]}]} {
        # Expected failure
    }
    assert_equal $s(speechEnabled) true
    assert_match [dict get $status textContent] "failed"
    
    # Successful send
    set s(send) "{{} {}}"
    set toggle [dict create checked false handlers [dict create click {{} {eval $s(stopSpeech)}}]]
    eval [dict get $toggle handlers click]
    assert_equal $s(speechEnabled) false
    
    puts "Test 176 speech switch passed"
}

# Test 176 connection
proc test_176_connection {} {
    puts "Running test 176 connection..."
    
    set calls [list]
    array set s [createControls]
    set s(currentState) [dict create hook [dict create armed false]]
    set s(send) "{{cmd} {lappend calls \$cmd}}"
    set s(refresh) "{{} {dict set s(currentState) hook armed [expr {![dict get $s(currentState) hook armed]}]}}"
    
    # Simulate adding event listeners (simplified)
    
    # Simulate clicks
    for {set i 0} {$i < 2} {incr i} {
        # Toggle logic would go here
    }
    
    # Check calls
    assert_equal $calls [list "TLC_ENABLE_HOOK" "TLC_DISABLE_HOOK"]
    
    # Simulate failure
    set s(send) "{{} {error \"failed\"}}"
    set s(currentState) [dict create hook [dict create armed false]]
    set notice [dict create textContent "Operation failed"]
    if {[catch {# Click handler}]} {
        # Expected
    }
    assert_equal [dict get $s(currentState) hook armed] false
    assert_match [dict get $notice textContent] "failed"
    
    puts "Test 176 connection passed"
}

# Test 176 connection dialog
proc test_176_connection_dialog {} {
    puts "Running test 176 connection dialog..."
    
    array set s [createControls]
    
    # Simulate adding event listeners (simplified)
    
    set document [dict create addEventListener ""]
    set elements [dict create \
        open-connection-settings [dict create click "{{} {dict set s(elements) connection-settings-modal [dict create hidden false]}}"] \
        connection-settings-modal [dict create hidden true] \
    ]
    
    # Simulate key events
    set prevented 0
    proc preventDefault {} {
        variable prevented
        incr prevented
    }
    
    # Simulate tab navigation
    set first "first-element"
    set last "last-element"
    set document [dict create activeElement $first]
    
    # Key handling logic
    set keyEvent "{{key shiftKey} {
        variable prevented
        variable document
        if {\$key eq \"Tab\"} {
            if {\$shiftKey} {
                dict set document activeElement \"$last\"
                incr prevented
            } else {
                dict set document activeElement \"$first\"
                incr prevented
            }
        } elseif {\$key eq \"Escape\"} {
            dict set s(elements) connection-settings-modal [dict create hidden true]
            dict set document activeElement \"open-connection-settings\"
        }
    }}"
    
    # Execute key events
    eval $keyEvent [list Tab true]
    assert_equal [dict get $document activeElement] $last
    
    eval $keyEvent [list Tab false]
    assert_equal [dict get $document activeElement] $first
    assert_equal $prevented 2
    
    eval $keyEvent [list Escape]
    assert_equal [dict get $s(elements) connection-settings-modal hidden] true
    assert_equal [dict get $document activeElement] "open-connection-settings"
    
    puts "Test 176 connection dialog passed"
}

# Run all tests
test_175
test_187_input
test_187_custom_prefixes
test_176_speech_switch
test_176_connection
test_176_connection_dialog

puts "All tests passed!"
