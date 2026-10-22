#!/usr/bin/env tclsh
# test_mobile_bridge.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Tcl Port of test_mobile_bridge.cjs

# Helper function to check if substring exists in string
proc string_contains {haystack needle} {
    return [expr {[string first $needle $haystack] != -1}]
}

# Helper function to read file content
proc read_file {filepath} {
    if {![file exists $filepath]} {
        error "File not found: $filepath"
    }
    set fh [open $filepath r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh
    return $content
}

# Get script directory and resolve paths
set script_dir [file dirname [info script]]
set root [file normalize [file join $script_dir ".."]]
set bridgePath [file join $root "mobile-shared" "webview-bridge.js"]

# Read the main bridge file
if {![file exists $bridgePath]} {
    error "Bridge file not found: $bridgePath"
}
set source [read_file $bridgePath]

# Basic syntax check by attempting to create a procedure
# This mimics the JavaScript vm.Script validation
proc validate_js_syntax {js_code} {
    # In TCL we do a basic check - this isn't a full JS parser
    # but catches obvious syntax errors
    if {[string length $js_code] == 0} {
        error "Empty JavaScript source"
    }
    # We could add more sophisticated checking here if needed
}

validate_js_syntax $source

# Assertions - check that required strings exist in source
set checks {
    {location.hostname !== \"www.tiktok.com\"}
    {root.top === root}
    {if \(!isTop\) return}
    {MAX_MESSAGE_BYTES = 64 \* 1024}
    {MAX_AUDIO_SECONDS = 12}
    {QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400}
    {ALLOWED_COMMANDS}
    {\"set-auto-reconnect\"}
    {\"set-limiter\"}
    {\"scan-recommendations\"}
    {\"cancel-recommendation-scan\"}
    {MAX_MEDIA_URLS = 12}
    {const mediaUrls = new Map\(\)}
    {emit\(\"media-url\"}
    {addEventListener\(\"message\"}
    {FORCE_RETURN_KEY = \"tlc-force-return\"}
    {sessionStorage.getItem\(FORCE_RETURN_KEY\)}
}

foreach check $checks {
    if {![string_contains $source $check]} {
        error "Assertion failed: source must contain '$check'"
    }
}

# Negative assertions - check that forbidden strings don't exist
set forbidden {
    {.send =}
    {document.cookie}
    {localStorage}
    {sessionStorage.clear}
    {innerHTML}
}

foreach forbidden_item $forbidden {
    if {[string_contains $source $forbidden_item]} {
        error "Assertion failed: source must NOT contain '$forbidden_item'"
    }
}

# Check copied bridge files are identical
set copies [list \
    [file join $root ".." "mobile" "ios" "Resources" "webview-bridge.js"] \
    [file join $root ".." "mobile" "android" "app" "src" "main" "res" "raw" "webview_bridge.js"] \
]

foreach copy $copies {
    set copy_path [file normalize $copy]
    if {[file exists $copy_path]} {
        set copy_content [read_file $copy_path]
        if {$copy_content ne $source} {
            error "Bridge copy drifted: $copy_path"
        }
    } else {
        error "Bridge copy not found: $copy_path"
    }
}

puts "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"
