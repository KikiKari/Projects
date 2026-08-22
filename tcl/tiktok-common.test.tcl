#!/usr/bin/env tclsh
# tiktok-common.test.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.test.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Tcl does not have a direct equivalent to Node.js's assert module
# We'll implement basic assertion functionality
proc assert_equal {actual expected msg} {
    if {$actual ne $expected} {
        error "Assertion failed: $msg\nExpected: $expected\nActual: $actual"
    }
}

proc assert_true {value msg} {
    if {!$value} {
        error "Assertion failed: $msg"
    }
}

proc assert_false {value msg} {
    if {$value} {
        error "Assertion failed: $msg"
    }
}

proc assert_null {value msg} {
    if {$value ne "" && $value ne "null"} {
        error "Assertion failed: $msg\nExpected null, got: $value"
    }
}

# Mock the required functions from tiktok-common
# These would normally be sourced from another file
source tiktok-common.tcl

# Test implementation
proc run_tests {} {
    # normalizeUsername tests
    assert_equal [normalizeUsername {@example_creator}] {example_creator} \
        "normalizeUsername with @ should strip @"
    assert_equal [normalizeUsername { example_creator }] {example_creator} \
        "normalizeUsername with spaces should trim"
    
    # This would need to throw an error - we'll test it separately
    set caught_error 0
    if {[catch {normalizeUsername {example_creator;id}}]} {
        set caught_error 1
    }
    if {!$caught_error} {
        error "normalizeUsername should throw on invalid characters"
    }
    
    # liveHrefSelectors test
    set selectors [liveHrefSelectors {example_creator}]
    set expected {"a[href=\"/@example_creator/live\"]" "a[href^=\"/@example_creator/live?\"]"}
    assert_equal [join $selectors] [join $expected] \
        "liveHrefSelectors should return correct selectors"
    
    # loadState test
    set env(TIKTOK_TEST_LOAD_PER_CPU) 2
    set env(TIKTOK_MAX_LOAD_PER_CPU) 1.5
    set state [loadState]
    assert_true [$state overloaded] \
        "loadState should detect overload when test > max"
    
    # isAllowedStreamUrl tests
    assert_true [isAllowedStreamUrl {https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x}] \
        "isAllowedStreamUrl should allow valid HTTPS TikTok URLs"
    assert_false [isAllowedStreamUrl {https://attacker.example/path/tiktokcdn/video.flv}] \
        "isAllowedStreamUrl should reject non-TikTok domains"
    assert_false [isAllowedStreamUrl {http://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv}] \
        "isAllowedStreamUrl should reject HTTP URLs"
    
    # isSuccessfulStreamResponse tests
    set allowedUrl {https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x}
    assert_true [isSuccessfulStreamResponse 200 $allowedUrl] \
        "isSuccessfulStreamResponse should accept 200"
    assert_true [isSuccessfulStreamResponse 206 $allowedUrl] \
        "isSuccessfulStreamResponse should accept 206"
    assert_false [isSuccessfulStreamResponse 404 $allowedUrl] \
        "isSuccessfulStreamResponse should reject 404"
    
    # normalizeExtractorResult tests
    set result [normalizeExtractorResult [dict create success false status offline] streamlink example_creator]
    assert_equal [dict get $result status] offline \
        "normalizeExtractorResult should preserve offline status"
    
    # classifyFinalFailure test
    set failure_result [classifyFinalFailure [list [dict create status offline] [dict create status dependency_missing]]]
    assert_equal $failure_result offline \
        "classifyFinalFailure should return first significant status"
    
    # exitCodeForResult tests
    assert_equal [exitCodeForResult [dict create success false status restricted]] 1 \
        "exitCodeForResult should return 1 for restricted"
    assert_equal [exitCodeForResult [dict create success false status technical_error]] 2 \
        "exitCodeForResult should return 2 for technical_error"
    
    # classifyDirectLiveState tests
    set state_dict [dict create username example_creator currentPath /@example_creator/live \
        title {Example (@example_creator) is LIVE - TikTok LIVE} \
        bodyText {Dieses LIVE enthält Themen, die unangenehm sein könnten.} \
        successfulStreamResponse false]
    set classified [classifyDirectLiveState $state_dict]
    assert_equal [dict get $classified status] restricted \
        "classifyDirectLiveState should classify restricted content"
    
    set state_dict2 [dict create username example_creator currentPath /@example_creator/live \
        title {Example (@example_creator) is LIVE - TikTok LIVE} \
        bodyText {LIVE has ended} successfulStreamResponse false]
    set classified2 [classifyDirectLiveState $state_dict2]
    assert_equal [dict get $classified2 status] offline \
        "classifyDirectLiveState should classify ended live as offline"
    
    set state_dict3 [dict create username example_creator currentPath /@example_creator/live \
        title {Example (@example_creator) is LIVE - TikTok LIVE} \
        bodyText {Suggested LIVE creators} successfulStreamResponse true]
    set classified3 [classifyDirectLiveState $state_dict3]
    assert_equal [dict get $classified3 status] live \
        "classifyDirectLiveState should classify active live correctly"
    
    puts "All tests passed!"
}

# Run the tests and handle errors
if {[catch {run_tests} error_result]} {
    puts stderr $error_result
    exit 1
}
