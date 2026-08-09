#!/usr/bin/env tclsh
# extract-tiktok-streamlink.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Bounded fallback used by the enhanced extractor. Output is normalized again
# by tiktok-get-stream.js; standalone success must remain URL-only unless
# --json is requested. Exit 75 means preflight overload.

proc emit_json {args} {
    set keys [list success method username url quality author title error timestamp status]
    set payload [dict create]
    foreach key $keys value $args {
        if {$value ne ""} {
            dict set payload $key $value
        }
    }
    if {[dict exists $payload success]} {
        set success [dict get $payload success]
        if {[string tolower $success] eq "true"} {
            dict set payload success true
        } else {
            dict set payload success false
        }
    }
    puts [encoding convertfrom utf-8 [exec python3 -c {
import json
import sys
print(json.dumps(eval(sys.argv[1]), ensure_ascii=False))
} [list [dict get $payload]]]]
}

proc get_load_avg {} {
    set loadavg [exec cat /proc/loadavg]
    set load [lindex [split $loadavg " "] 0]
    return [expr {double($load)}]
}

proc get_cpu_count {} {
    if {[catch {exec nproc} result]} {
        return 1
    }
    return $result
}

proc validate_username {username} {
    if {![regexp {^[A-Za-z0-9._]{1,24}$} $username]} {
        return 0
    }
    return 1
}

proc validate_quality {quality} {
    set valid_qualities [list best worst original 1080p60 720p60 720p 540p 360p auto]
    if {$quality in $valid_qualities} {
        return 1
    }
    return 0
}

proc get_stream_selector {quality} {
    switch $quality {
        original {
            return "origin,uhd_60,hd_60,hd,sd,ld,best,worst"
        }
        auto {
            return "best,origin,uhd_60,hd_60,hd,sd,ld,worst"
        }
        1080p60 {
            return "uhd_60,hd_60,hd,sd,ld,worst"
        }
        720p60 {
            return "hd_60,hd,sd,ld,worst"
        }
        720p {
            return "hd,sd,ld,worst"
        }
        540p {
            return "sd,ld,worst"
        }
        360p {
            return "ld,worst"
        }
        default {
            return $quality
        }
    }
}

proc get_timestamp {} {
    return [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
}

proc parse_streamlink_json {json_str} {
    set script {
import json, sys
data = json.load(sys.stdin)
url = data.get("url", "")
streams = data.get("streams", {})
if not url and isinstance(streams, dict):
    for key in ("best", "worst", *streams.keys()):
        value = streams.get(key)
        if isinstance(value, dict) and value.get("url"):
            url = value["url"]
            break
metadata = data.get("metadata", {})
print(json.dumps({"url": url, "author": metadata.get("author", ""), "title": metadata.get("title", "")}))
}
    return [exec python3 -c $script << $json_str]
}

proc extract_fields {json_str} {
    set script {
import json, sys
d=json.load(sys.stdin)
print(d.get("url",""))
print(d.get("author",""))
print(d.get("title",""))
}
    set result [split [exec python3 -c $script << $json_str] "\n"]
    return $result
}

proc main {argv} {
    set timestamp [get_timestamp]
    
    if {[llength $argv] < 1} {
        puts stderr "Invalid TikTok username"
        exit 64
    }
    
    set username [string trimleft [lindex $argv 0] "@"]
    set quality [lindex $argv 1]
    if {$quality eq ""} {
        set quality "best"
    }
    set json_flag [lindex $argv 2]
    
    if {![validate_username $username]} {
        puts stderr "Invalid TikTok username"
        exit 64
    }
    
    if {![validate_quality $quality]} {
        puts stderr "Invalid stream quality"
        exit 64
    }
    
    set cpu_count [get_cpu_count]
    if {$cpu_count < 1} {
        set cpu_count 1
    }
    set load_per_cpu [expr {[get_load_avg] / $cpu_count}]
    set max_load 1.5
    if {[info exists ::env(TIKTOK_MAX_LOAD_PER_CPU)]} {
        set max_load $::env(TIKTOK_MAX_LOAD_PER_CPU)
    }
    
    if {$load_per_cpu > $max_load} {
        emit_json false streamlink $username "" $quality "" "" "host overloaded" $timestamp "overloaded"
        exit 75
    }
    
    if {[catch {exec which streamlink} result]} {
        emit_json false streamlink $username "" $quality "" "" "streamlink not installed" $timestamp "dependency_missing"
        exit 2
    }
    
    set live_url "https://www.tiktok.com/@${username}/live"
    set selector [get_stream_selector $quality]
    
    if {[catch {exec streamlink --json $live_url $selector} output]} {
        set output ""
    }
    
    if {$output eq ""} {
        if {[catch {exec streamlink --stream-url $live_url $selector} url]} {
            set url ""
        }
        if {$url eq ""} {
            emit_json false streamlink $username "" $quality "" "" "streamlink failed or no stream found" $timestamp "offline"
            exit 1
        }
        if {$json_flag eq "--json"} {
            emit_json true streamlink $username $url $quality "" "" "" $timestamp "live"
        } else {
            puts $url
        }
        exit 0
    }
    
    if {[catch {parse_streamlink_json $output} parsed]} {
        emit_json false streamlink $username "" $quality "" "" "invalid streamlink JSON" $timestamp "technical_error"
        exit 2
    }
    
    if {[catch {extract_fields $parsed} fields]} {
        emit_json false streamlink $username "" $quality "" "" "could not extract fields" $timestamp "technical_error"
        exit 2
    }
    
    set url [lindex $fields 0]
    set author [lindex $fields 1]
    set title [lindex $fields 2]
    
    if {$url eq ""} {
        emit_json false streamlink $username "" $quality $author $title "could not extract stream URL" $timestamp "offline"
        exit 1
    }
    
    if {$json_flag eq "--json"} {
        emit_json true streamlink $username $url $quality $author $title "" $timestamp "live"
    } else {
        puts $url
    }
}

main $argv
