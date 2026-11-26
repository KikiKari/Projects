#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "2548248a18bd09728ee5d051068cdc50147953fd0a8c125fc123a47c0459a446", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "tcl"}
# extract-tiktok-streamlink.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Bounded fallback used by the enhanced extractor. Output is normalized again
# by tiktok-get-stream.js; standalone success must remain URL-only unless
# --json is requested. Exit 75 means preflight overload.
if {$argc < 1} {
    puts stderr "Missing username argument"
    exit 64
}

set USERNAME [string trimleft [lindex $argv 0] "@"]
set QUALITY [expr {$argc >= 2 ? [lindex $argv 1] : "best"}]
set JSON_FLAG [expr {$argc >= 3 ? [lindex $argv 2] : ""}]
set TIMESTAMP [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]

proc emit_json {args} {
    set keys [list success method username url quality author title error timestamp status]
    set payload {}
    foreach key $keys value $args {
        if {$value ne ""} {
            dict set payload $key $value
        }
    }
    if {[dict exists $payload success]} {
        dict set payload success [string is true -strict [dict get $payload success]]
    }
    puts [encoding convertfrom utf-8 [::json::encode $payload]]
}

# Validate username
if {![regexp {^[A-Za-z0-9._]{1,24}$} $USERNAME]} {
    puts stderr "Invalid TikTok username"
    exit 64
}

# Validate quality
set valid_qualities [list best worst original 1080p60 720p60 720p 540p 360p auto]
if {$QUALITY ni $valid_qualities} {
    puts stderr "Invalid stream quality"
    exit 64
}

# Check system load
if {[catch {exec uname}]} {
    set LOAD_PER_CPU 0.0
} else {
    if {[catch {exec cat /proc/loadavg} loadavg]} {
        set LOAD_PER_CPU 0.0
    } else {
        set load_val [lindex [split $loadavg] 0]
        if {[catch {exec nproc} cpu_count]} {
            set cpu_count 1
        }
        set cpu_count [expr {$cpu_count > 0 ? $cpu_count : 1}]
        set LOAD_PER_CPU [expr {double($load_val) / $cpu_count}]
    }
}

set MAX_LOAD [expr {[info exists env(TIKTOK_MAX_LOAD_PER_CPU)] ? $env(TIKTOK_MAX_LOAD_PER_CPU) : 1.5}]
if {$LOAD_PER_CPU > $MAX_LOAD} {
    emit_json false streamlink $USERNAME "" $QUALITY "" "" host\ overloaded $TIMESTAMP overloaded
    exit 75
}

# Check if streamlink exists
if {[catch {exec which streamlink}]} {
    emit_json false streamlink $USERNAME "" $QUALITY "" "" streamlink\ not\ installed $TIMESTAMP dependency_missing
    exit 2
}

set LIVE_URL "https://www.tiktok.com/@${USERNAME}/live"

# Set quality selector
switch $QUALITY {
    original { set SELECTOR "origin,uhd_60,hd_60,hd,sd,ld,best,worst" }
    auto { set SELECTOR "best,origin,uhd_60,hd_60,hd,sd,ld,worst" }
    1080p60 { set SELECTOR "uhd_60,hd_60,hd,sd,ld,worst" }
    720p60 { set SELECTOR "hd_60,hd,sd,ld,worst" }
    720p { set SELECTOR "hd,sd,ld,worst" }
    540p { set SELECTOR "sd,ld,worst" }
    360p { set SELECTOR "ld,worst" }
    default { set SELECTOR $QUALITY }
}

# Try streamlink with --json first
if {[catch {exec streamlink --json $LIVE_URL $SELECTOR} OUTPUT]} {
    set OUTPUT ""
}
set EXIT_CODE [expr {$OUTPUT eq "" ? 1 : 0}]

if {$EXIT_CODE != 0 || $OUTPUT eq ""} {
    if {[catch {exec streamlink --stream-url $LIVE_URL $SELECTOR} URL]} {
        set URL ""
    }
    if {$URL eq ""} {
        emit_json false streamlink $USERNAME "" $QUALITY "" "" streamlink\ failed\ or\ no\ stream\ found $TIMESTAMP offline
        exit 1
    }
    if {$JSON_FLAG eq "--json"} {
        emit_json true streamlink $USERNAME $URL $QUALITY "" "" "" $TIMESTAMP live
    } else {
        puts $URL
    }
    exit 0
}

# Parse JSON output
if {[catch {
    package require json
    set data [::json::json2dict $OUTPUT]
    set url [dict get $data url]
    set streams [dict get $data streams]
    if {$url eq "" && [dict size $streams] > 0} {
        foreach key [concat [list best worst] [dict keys $streams]] {
            if {[dict exists $streams $key]} {
                set stream_data [dict get $streams $key]
                if {[dict exists $stream_data url] && [dict get $stream_data url] ne ""} {
                    set url [dict get $stream_data url]
                    break
                }
            }
        }
    }
    set metadata [dict get $data metadata]
    set author [dict get $metadata author]
    set title [dict get $metadata title]
    list $url $author $title
} result]} {
    emit_json false streamlink $USERNAME "" $QUALITY "" "" invalid\ streamlink\ JSON $TIMESTAMP technical_error
    exit 2
}

lassign $result URL AUTHOR TITLE

if {$URL eq ""} {
    emit_json false streamlink $USERNAME "" $QUALITY $AUTHOR $TITLE could\ not\ extract\ stream\ URL $TIMESTAMP offline
    exit 1
}

if {$JSON_FLAG eq "--json"} {
    emit_json true streamlink $USERNAME $URL $QUALITY $AUTHOR $TITLE "" $TIMESTAMP live
} else {
    puts $URL
}
