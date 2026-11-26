#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "45d0e84e6e8f1826bd3c27d093d2fa2ef75b59e459bb543764b0baf33e7842bc", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "tcl"}
# extract-tiktok-yt-dlp.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Bounded fallback used by the enhanced extractor. Temporary files are cleaned
# on every exit and output is normalized again by tiktok-get-stream.js.
# Standalone overload exits 75 before yt-dlp starts.

package require Tcl 8.6
package require json
package require platform

# Set strict mode equivalent
if {[info exists env(TCL_STRICT)]} {
    interp bgerror {} {puts stderr $::errorInfo; exit 1}
}

proc emit_json {args} {
    set keys [list success method username url format error timestamp status]
    array set payload {}
    
    foreach key $keys value $args {
        if {$value ne ""} {
            set payload($key) $value
        }
    }
    
    if {[info exists payload(success)]} {
        set payload(success) [string is true -strict $payload(success)]
    }
    
    puts [::json::write object {*}[array get payload]]
}

proc get_load_per_cpu {} {
    if {[catch {exec uptime} result]} {
        return 0.0
    }
    
    # Extract load average from uptime output
    if {[regexp {load averages?: ([0-9.]+)} $result -> load_avg]} {
        set cpu_count [llength [split [exec sysctl -n hw.ncpu 2>/dev/null || echo 1] \n]]
        if {$cpu_count <= 0} {set cpu_count 1}
        return [expr {$load_avg / $cpu_count}]
    }
    return 0.0
}

proc validate_username {username} {
    if {![regexp {^[A-Za-z0-9._]{1,24}$} $username]} {
        puts stderr "Invalid TikTok username"
        exit 64
    }
}

proc validate_format {format} {
    set valid_formats {
        {hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld}
        {hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld}
        {hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld}
        {hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld}
        {hls-sd/hls-ld/flv-sd/flv-ld}
        {hls-ld/flv-ld}
        {hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld}
    }
    
    foreach pattern $valid_formats {
        if {$format eq $pattern} {
            return
        }
    }
    
    puts stderr "Invalid yt-dlp format"
    exit 64
}

proc cleanup_tmp_dir {tmp_dir} {
    if {[file exists $tmp_dir]} {
        file delete -force $tmp_dir
    }
}

proc get_timestamp {} {
    return [clock format [clock seconds] -gmt true -format "%Y-%m-%dT%H:%M:%SZ"]
}

proc extract_url_from_json {json_file} {
    if {![file exists $json_file]} {
        return ""
    }
    
    if {[catch {set fp [open $json_file r]}]} {
        return ""
    }
    
    set json_data [read $fp]
    close $fp
    
    if {[catch {set data [::json::json2dict $json_data]} result]} {
        return ""
    }
    
    set candidates {}
    
    # Check direct url field
    if {[dict exists $data url]} {
        lappend candidates [dict get $data url]
    }
    
    # Check formats array
    if {[dict exists $data formats]} {
        set formats [dict get $data formats]
        if {[llength $formats] > 0 && [llength [lindex $formats 0]] > 1} {
            # It's a list of dicts
            foreach item $formats {
                if {[dict exists $item url]} {
                    lappend candidates [dict get $item url]
                }
            }
        }
    }
    
    # Filter candidates
    foreach value $candidates {
        set low [string tolower $value]
        if {[string match https://* $value] && 
            ([string match *.m3u8* $low] || [string match *.flv* $low]) && 
            ![string match *only_audio=1* $value]} {
            return $value
        }
    }
    
    return ""
}

# Main script logic
if {$argc < 1} {
    puts stderr "Usage: $argv0 <username> \[format\] \[--json\]"
    exit 64
}

set USERNAME [string trimleft [lindex $argv 0] "@"]
set FORMAT [lindex $argv 1]
if {$FORMAT eq ""} {
    set FORMAT "best"
}
set JSON_FLAG [lindex $argv 2]
set TIMESTAMP [get_timestamp]

# Create temporary directory
set TMP_DIR [exec mktemp -d /tmp/tiktok-yt-dlp.XXXXXX]
set cleanup_registered 0

# Setup cleanup trap
proc setup_cleanup {tmp_dir_var} {
    upvar $tmp_dir_var tmp_dir
    proc cleanup_handler {} [subst {
        cleanup_tmp_dir $tmp_dir
    }]
    if {[info commands tcl_exit_handler] eq ""} {
        proc tcl_exit_handler {} {
            cleanup_handler
        }
    }
}

setup_cleanup TMP_DIR

# Validate inputs
validate_username $USERNAME
validate_format $FORMAT

# Check system load
set LOAD_PER_CPU [get_load_per_cpu]
set MAX_LOAD [expr {[info exists env(TIKTOK_MAX_LOAD_PER_CPU)] ? $env(TIKTOK_MAX_LOAD_PER_CPU) : 1.5}]

if {$LOAD_PER_CPU > $MAX_LOAD} {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "host overloaded" $TIMESTAMP "overloaded"
    exit 75
}

# Check if yt-dlp is installed
if {[catch {exec which yt-dlp}]} {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "yt-dlp not installed" $TIMESTAMP "dependency_missing"
    exit 2
}

# Run yt-dlp
set LIVE_URL "https://www.tiktok.com/@${USERNAME}/live"
set STDOUT_FILE "$TMP_DIR/stdout.json"
set STDERR_FILE "$TMP_DIR/stderr.log"

if {[catch {exec yt-dlp --no-warnings --dump-single-json --skip-download --format $FORMAT $LIVE_URL > $STDOUT_FILE 2> $STDERR_FILE} result]} {
    set EXIT_CODE [lindex [split $result] end]
} else {
    set EXIT_CODE 0
}

if {$EXIT_CODE != 0} {
    if {[file exists $STDERR_FILE]} {
        set fp [open $STDERR_FILE r]
        set stderr_content [read $fp 1000]
        close $fp
        
        if {[regexp -nocase {(not currently live|No live cdn found|not available|private video)} $stderr_content]} {
            set STATUS offline
            set CODE 1
        } else {
            set STATUS technical_error
            set CODE 2
        }
        
        emit_json "false" "yt-dlp" $USERNAME "" $FORMAT $stderr_content $TIMESTAMP $STATUS
        exit $CODE
    }
}

# Extract URL
set URL [extract_url_from_json $STDOUT_FILE]

if {$URL eq ""} {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "could not extract HTTPS video URL" $TIMESTAMP "offline"
    exit 1
}

if {$JSON_FLAG eq "--json"} {
    emit_json "true" "yt-dlp" $USERNAME $URL $FORMAT "" $TIMESTAMP "live"
} else {
    puts $URL
}

# Cleanup
cleanup_tmp_dir $TMP_DIR
exit 0
