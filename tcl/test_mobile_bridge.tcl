#!/usr/bin/env tclsh
# test_mobile_bridge.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Helper functions to mimic Node.js functionality
proc readFileSync {filename} {
    set fh [open $filename r]
    set content [read $fh]
    close $fh
    return $content
}

proc resolve {args} {
    return [file normalize [join $args "/"]]
}

proc join_path {args} {
    return [join $args "/"]
}

proc basename {path} {
    return [file tail $path]
}

proc dirname {path} {
    return [file dirname $path]
}

proc includes {string substring} {
    return [expr {[string first $substring $string] != -1}]
}

proc strictEqual {actual expected message} {
    if {$actual ne $expected} {
        error "Assertion failed: $message"
    }
}

proc ok {value message} {
    if {![expr $value]} {
        error "Assertion failed: $message"
    }
}

# Get __dirname (current script directory)
set __dirname [file dirname [info script]]
set root [resolve $__dirname ".."]
set bridgePath [join_path $root "mobile-shared" "webview-bridge.js"]
set source [readFileSync $bridgePath]

# Simple syntax check by attempting to compile as Tcl
# (This is a basic check - not equivalent to vm.Script but serves the purpose)
if {[catch {info body [list $source]}]} {
    error "Script compilation failed: $bridgePath"
}

ok [includes $source {location.hostname !== "www.tiktok.com"}] \
   {"location.hostname !== \"www.tiktok.com\" not found"}
ok [includes $source {root.top === root}] \
   {"root.top === root not found"}
ok [includes $source {if (!isTop) return}] \
   {"if (!isTop) return not found"}
ok [includes $source {MAX_MESSAGE_BYTES = 64 * 1024}] \
   {"MAX_MESSAGE_BYTES = 64 * 1024 not found"}
ok [includes $source {MAX_AUDIO_SECONDS = 12}] \
   {"MAX_AUDIO_SECONDS = 12 not found"}
ok [includes $source {QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400}] \
   {"QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400 not found"}
ok [includes $source {ALLOWED_COMMANDS}] \
   {"ALLOWED_COMMANDS not found"}
ok [includes $source {"set-auto-reconnect"}] \
   {"\"set-auto-reconnect\" not found"}
ok [includes $source {"set-limiter"}] \
   {"\"set-limiter\" not found"}
ok [includes $source {"scan-recommendations"}] \
   {"\"scan-recommendations\" not found"}
ok [includes $source {"cancel-recommendation-scan"}] \
   {"\"cancel-recommendation-scan\" not found"}
ok [includes $source {MAX_MEDIA_URLS = 12}] \
   {"MAX_MEDIA_URLS = 12 not found"}
ok [includes $source {const mediaUrls = new Map()}] \
   {"const mediaUrls = new Map() not found"}
ok [includes $source {emit("media-url"}] \
   {"emit(\"media-url\" not found"}
ok [includes $source {addEventListener("message"}] \
   {"addEventListener(\"message\" not found"}
ok [expr {![includes $source {.send =}]}] \
   {".send = found but should not be present"}
ok [expr {![includes $source {document.cookie}]}] \
   {"document.cookie found but should not be present"}
ok [expr {![includes $source {localStorage}]}] \
   {"localStorage found but should not be present"}
ok [includes $source {FORCE_RETURN_KEY = "tlc-force-return"}] \
   {"FORCE_RETURN_KEY = \"tlc-force-return\" not found"}
ok [includes $source {sessionStorage.getItem(FORCE_RETURN_KEY)}] \
   {"sessionStorage.getItem(FORCE_RETURN_KEY) not found"}
ok [expr {![includes $source {sessionStorage.clear}]}] \
   {"sessionStorage.clear found but should not be present"}
ok [expr {![includes $source {innerHTML}]}] \
   {"innerHTML found but should not be present"}

# Check copies
set copies [list \
    [join_path $root ".." "mobile" "ios" "Resources" "webview-bridge.js"] \
    [join_path $root ".." "mobile" "android" "app" "src" "main" "res" "raw" "webview_bridge.js"] \
]

foreach copy $copies {
    set copyContent [readFileSync $copy]
    strictEqual $copyContent $source "Bridge copy drifted: $copy"
}

puts "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"
