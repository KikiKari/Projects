#!/usr/bin/env tclsh
# test_external_speech_filter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Tcl does not have a direct equivalent to Node.js's test framework,
# so we'll implement a basic testing framework here.

# Global variables to track test results
set total_tests 0
set passed_tests 0
set failed_tests 0

# Simple test procedure
proc test {description expected actual} {
    global total_tests passed_tests failed_tests
    incr total_tests
    if {$expected eq $actual} {
        incr passed_tests
        # puts "PASS: $description"
    } else {
        incr failed_tests
        puts "FAIL: $description - Expected '$expected', got '$actual'"
    }
}

# Mock implementation of shouldFilterExternalSpeechTrigger
proc shouldFilterExternalSpeechTrigger {text enabled {prefixes "."}} {
    if {!$enabled} {
        return false
    }
    set trimmed_text [string trimleft $text]
    foreach prefix [split $prefixes ""] {
        if {[string index $trimmed_text 0] eq $prefix} {
            return true
        }
    }
    return false
}

# Mock implementation of normalizeExternalSpeechTriggerCharacters
proc normalizeExternalSpeechTriggerCharacters {text} {
    if {$text eq "" || $text eq "undefined"} {
        return "."
    }
    
    # Remove leading/trailing whitespace
    set text [string trim $text]
    
    # Keep only specific characters: .,-;: and Unicode emojis (represented as single chars here)
    # For simplicity, we'll just keep the allowed punctuation marks
    set result ""
    foreach char [split $text ""] {
        if {[string match {[.,\-;:]} $char] || [string is emoji $char]} {
            append result $char
        }
    }
    
    # Limit to first 5 characters (scalar values)
    return [string range $result 0 4]
}

# Since Tcl doesn't have native emoji support, we'll create a helper
proc string_is_emoji {char} {
    # Simplified check - in reality this would be more complex
    # Here we just assume some unicode ranges represent emojis
    # This is a placeholder implementation
    return 0
}

# Main test cases from the original JavaScript file

# Basic filtering tests
foreach enabled [list false true] {
    foreach text [list ".Text" ". Text" "  .Text" "\t\n. Text" "Normal" "Ein Satz. Noch einer" ""] {
        set expected [expr {$enabled && ([string index [string trimleft $text] 0] eq ".")}]
        set result [shouldFilterExternalSpeechTrigger $text $enabled]
        test "Basic test: enabled=$enabled, text='$text'" $expected $result
    }
}

# 0PE-187: individual literal prefixes, commas and semicolons are not separators
foreach enabled [list false true] {
    foreach text [list ".Hallo" ",Hallo" "- Hallo" "  , Hallo"] {
        set result [shouldFilterExternalSpeechTrigger $text $enabled ".,-"]
        set expected $enabled
        test "Prefix test 1: enabled=$enabled, text='$text'" $expected $result
    }
    
    foreach text [list "Hallo, zusammen." "Normal-Text" "Hallo" "."] {
        set result [shouldFilterExternalSpeechTrigger $text $enabled ",-"]
        test "Prefix test 2: enabled=$enabled, text='$text'" false $result
    }
    
    set result [shouldFilterExternalSpeechTrigger ";Hallo" $enabled ";"]
    set expected $enabled
    test "Semicolon prefix: enabled=$enabled" $expected $result
    
    set result [shouldFilterExternalSpeechTrigger "\[Hallo" $enabled "\["]
    set expected $enabled
    test "Bracket prefix: enabled=$enabled" $expected $result
    
    set result [shouldFilterExternalSpeechTrigger "Hallo" $enabled "\["]
    test "Non-bracket text: enabled=$enabled" false $result
}

# 0PE-187: five Unicode scalar triggers, paste sanitization and explicit empty selection
test "Normalize undefined" "." [normalizeExternalSpeechTriggerCharacters "undefined"]
test "Normalize empty string" "" [normalizeExternalSpeechTriggerCharacters ""]
test "Normalize punctuation" ".,-;:" [normalizeExternalSpeechTriggerCharacters ".,-;:!\?"]
test "Normalize with spaces and quotes" ".,-" [normalizeExternalSpeechTriggerCharacters " a1 \"'.,- "]

# Emoji normalization test (simplified)
# In real implementation, this would handle actual Unicode emojis
test "Normalize emojis" "....." [normalizeExternalSpeechTriggerCharacters "😀😁😂😃😄😅"]

set result [shouldFilterExternalSpeechTrigger "😀Hallo" true "😀"]
test "Emoji trigger" true $result

set result [shouldFilterExternalSpeechTrigger ".Hallo" true ""]
test "Empty prefixes" false $result

set result [shouldFilterExternalSpeechTrigger ".Hallo" true ","]
test "Mismatched prefix" false $result

# Print summary
puts "$total_tests tests run: $passed_tests passed, $failed_tests failed"

if {$failed_tests > 0} {
    exit 1
} else {
    exit 0
}
