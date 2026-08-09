#!/usr/bin/env tclsh8.6
# extract-tiktok-yt-dlp.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json

# Bounded fallback used by the enhanced extractor. Temporary files are cleaned
# on every exit and output is normalized again by tiktok-get-stream.js.
# Standalone overload exits 75 before yt-dlp starts.

set username [lindex $argv 0]
if {[string index $username 0] eq "@"} {
    set username [string range $username 1 end]
}
set format [expr {[llength $argv] > 1 ? [lindex $argv 1] : "best"}]
set json_flag [expr {[llength $argv] > 2 ? [lindex $argv 2] : ""}]

# Get current timestamp in UTC
set timestamp [clock format [clock seconds] -gmt true -format "%Y-%m-%dT%H:%M:%SZ"]

# Create temporary directory
set tmp_dir [exec mktemp -d /tmp/tiktok-yt-dlp.XXXXXX]

# Cleanup function
proc cleanup {dir} {
    if {[file exists $dir]} {
        file delete -force $dir
    }
}

# Register cleanup on exit
proc exit_handler {dir} {
    cleanup $dir
    exit [info exists ::exit_code] ? $::exit_code : 0
}
set ::exit_code 0

# Set up trap for cleanup
proc trap_exit {dir} {
    if {[info commands trap] ne ""} {
        trap "cleanup $dir" EXIT
    } else {
        # Fallback for older Tcl versions
        set ::atexit_script "cleanup $dir"
    }
}
trap_exit $tmp_dir

proc emit_json {args} {
    set keys {success method username url format error timestamp status}
    array set payload {}
    foreach {k v} [lzip $keys $args] {
        if {$v ne ""} {
            set payload($k) $v
        }
    }
    if {[info exists payload(success)]} {
        set payload(success) [string is true -strict $payload(success)]
    }
    puts stderr [::json::write object {*}[array get payload]]
}

# Validate username
if {![regexp {^[A-Za-z0-9._]{1,24}$} $username]} {
    puts stderr "Invalid TikTok username"
    set ::exit_code 64
    cleanup $tmp_dir
    exit $::exit_code
}

# Validate format
set valid_formats {
    {hls-origin hls-pull hls-uhd_60 hls-hd_60 hls-hd hls-sd hls-ld flv-origin flv-hd flv-ld}
    {hls-uhd_60 hls-hd_60 hls-hd hls-sd hls-ld flv-hd flv-ld}
    {hls-hd_60 hls-hd hls-sd hls-ld flv-hd flv-ld}
    {hls-hd hls-sd hls-ld flv-hd flv-sd flv-ld}
    {hls-sd hls-ld flv-sd flv-ld}
    {hls-ld flv-ld}
    {hls-origin hls-hd hls-sd hls-ld hls-pull flv-origin flv-hd flv-ld}
}

set format_valid 0
foreach valid_list $valid_formats {
    if {[lsearch -exact $valid_list $format] != -1} {
        set format_valid 1
        break
    }
}

if {!$format_valid} {
    puts stderr "Invalid yt-dlp format"
    set ::exit_code 64
    cleanup $tmp_dir
    exit $::exit_code
}

# Check system load
set load_per_cpu [exec python3 -c {import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))}]
set max_load [expr {[info exists ::env(TIKTOK_MAX_LOAD_PER_CPU)] ? $::env(TIKTOK_MAX_LOAD_PER_CPU) : 1.5}]

if {[expr {$load_per_cpu > $max_load}]} {
    emit_json "false" "yt-dlp" $username "" $format "host overloaded" $timestamp "overloaded"
    set ::exit_code 75
    cleanup $tmp_dir
    exit $::exit_code
}

# Check if yt-dlp is installed
if {[catch {exec which yt-dlp}]} {
    emit_json "false" "yt-dlp" $username "" $format "yt-dlp not installed" $timestamp "dependency_missing"
    set ::exit_code 2
    cleanup $tmp_dir
    exit $::exit_code
}

set live_url "https://www.tiktok.com/@${username}/live"

# Run yt-dlp command
set stdout_file "$tmp_dir/stdout.json"
set stderr_file "$tmp_dir/stderr.log"

if {[catch {exec yt-dlp --no-warnings --dump-single-json --skip-download --format $format $live_url > $stdout_file 2> $stderr_file} result]} {
    set exit_code [lindex [split $result " "] end]
} else {
    set exit_code 0
}

if {$exit_code != 0} {
    set stderr_content [exec head -c 1000 $stderr_file]
    if {[regexp -nocase {not currently live|No live cdn found|not available|private video} $stderr_content]} {
        set status offline
        set code 1
    } else {
        set status technical_error
        set code 2
    }
    emit_json "false" "yt-dlp" $username "" $format $stderr_content $timestamp $status
    set ::exit_code $code
    cleanup $tmp_dir
    exit $::exit_code
}

# Extract URL from JSON
set url ""
if {[file exists $stdout_file] && [file size $stdout_file] > 0} {
    if {![catch {exec python3 -c {
import json, sys
d=json.load(sys.stdin)
candidates=[]
if isinstance(d.get("url"), str):
    candidates.append(d["url"])
for item in d.get("formats", []) or []:
    if isinstance(item, dict) and isinstance(item.get("url"), str):
        candidates.append(item["url"])
for value in candidates:
    low = value.lower()
    if value.startswith("https://") and (".m3u8" in low or ".flv" in low) and "only_audio=1" not in low:
        print(value)
        break
} < $stdout_file} url_output]} {
        set url [string trim $url_output]
    }
}

if {$url eq ""} {
    emit_json "false" "yt-dlp" $username "" $format "could not extract HTTPS video URL" $timestamp "offline"
    set ::exit_code 1
    cleanup $tmp_dir
    exit $::exit_code
}

if {$json_flag eq "--json"} {
    emit_json "true" "yt-dlp" $username $url $format "" $timestamp "live"
} else {
    puts $url
}

cleanup $tmp_dir
