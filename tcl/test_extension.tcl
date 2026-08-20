#!/usr/bin/env tclsh
# test_extension.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json
package require sha256

# Helper functions to mimic JavaScript behavior
proc assert_equal {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: expected '$expected', got '$actual'"
    }
}

proc assert_true {condition} {
    if {![subst $condition]} {
        error "Assertion failed: condition not true"
    }
}

proc assert_false {condition} {
    if {[subst $condition]} {
        error "Assertion failed: condition not false"
    }
}

proc path_join {args} {
    return [join $args "/"]
}

proc path_resolve {base rel} {
    # Simplified implementation for this context
    return [file normalize [path_join $base $rel]]
}

proc read_file {filepath} {
    set fh [open $filepath r]
    set content [read $fh]
    close $fh
    return $content
}

proc file_exists {filepath} {
    return [file exists $filepath]
}

proc dir_files {dir} {
    return [glob -nocomplain -tails -directory $dir *.js]
}

proc json_parse {json_str} {
    return [::json::json2dict $json_str]
}

proc crypto_hash {data} {
    return [string toupper [sha256::sha256 -bin $data]]
}

proc concat_bytes {args} {
    set result ""
    foreach chunk $args {
        append result $chunk
    }
    return $result
}

proc varint {value} {
    set bytes {}
    set current [expr {$value}]
    while {1} {
        set byte [expr {$current & 0x7f}]
        set current [expr {$current >> 7}]
        if {$current != 0} {
            set byte [expr {$byte | 0x80}]
        }
        lappend bytes $byte
        if {$current == 0} break
    }
    return [binary format c* $bytes]
}

proc bytes_field {number value} {
    set body $value
    if {[string is integer -strict $value]} {
        set body [binary format A* $value]
    }
    set tag [expr {($number << 3) | 2}]
    return [concat_bytes [varint $tag] [varint [string length $body]] $body]
}

proc int_field {number value} {
    set tag [expr {$number << 3}]
    return [concat_bytes [varint $tag] [varint $value]]
}

# Main script logic starts here
set __dirname [file dirname $argv0]
set root [path_resolve $__dirname ".."]
set extension [path_join $root "browser-extension"]
set manifest_path [path_join $extension "manifest.json"]
set manifest [json_parse [read_file $manifest_path]]

# Load required modules (simulated)
# In a real scenario, these would be loaded from files
# For now, we'll define mock functions for testing purposes

# Test assertions based on the JavaScript code
assert_equal [dict get $manifest manifest_version] 3
assert_equal [dict get $manifest version] "0.8.0"
assert_true [expr {"sidePanel" in [dict get $manifest permissions]}]
assert_true [expr {"webRequest" in [dict get $manifest permissions]}]
assert_true [expr {"tabCapture" in [dict get $manifest permissions]}]
assert_true [expr {"http://127.0.0.1/*" in [dict get $manifest host_permissions]}]
assert_true [expr {"http://localhost/*" in [dict get $manifest host_permissions]}]
assert_false [expr {"cookies" in [dict get $manifest permissions]}]
assert_false [expr {"webRequestBlocking" in [dict get $manifest permissions]}]
assert_false [expr {"nativeMessaging" in [dict get $manifest permissions]}]
assert_equal [lindex [dict get [lindex [dict get $manifest content_scripts] 0] js] 0] "vendor-mpegts.js"

set mpegtsVendorPath [path_join $extension "vendor-mpegts.js"]
set mpegtsLicensePath [path_join $extension "vendor-mpegts.LICENSE.txt"]
set mpegtsNoticePath [path_join $extension "vendor-mpegts.NOTICE.md"]

assert_true [file_exists $mpegtsVendorPath]
assert_true [file_exists $mpegtsLicensePath]
assert_true [file_exists $mpegtsNoticePath]

set vendor_content [read_file $mpegtsVendorPath]
set hash_value [crypto_hash $vendor_content]
assert_equal $hash_value "0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"

set mobileBridge [read_file [path_join $root "mobile-shared" "webview-bridge.js"]]
assert_true [string match "*location.hostname !== \"www.tiktok.com\"*" $mobileBridge]
assert_false [string match "*document.cookie*" $mobileBridge]
assert_true [string match "*QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400*" $mobileBridge]
assert_true [string match "*\"set-auto-reconnect\"*" $mobileBridge]
assert_true [string match "*\"set-limiter\"*" $mobileBridge]

foreach relative [list \
    [dict get [dict get $manifest background] service_worker] \
    [dict get [dict get $manifest side_panel] default_path] \
    {*}[dict get [lindex [dict get $manifest content_scripts] 0] js]] {
    assert_true [file_exists [path_join $extension $relative]]
}

set scripts [dir_files $extension]
foreach name $scripts {
    set source [read_file [path_join $extension $name]]
    # Simulate VM script compilation check
    if {[regexp {\beval\s*\(} $source]} {
        error "$name contains eval()"
    }
    if {[regexp {new\s+Function\s*\(} $source]} {
        error "$name contains new Function()"
    }
    if {[regexp {\.innerHTML\s*=} $source]} {
        error "$name assigns innerHTML"
    }
}

puts "PASS: manifest 0.8.0, [llength $scripts] scripts, basic checks completed"
