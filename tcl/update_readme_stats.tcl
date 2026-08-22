#!/usr/bin/env tclsh
# update_readme_stats.py — portiert nach tcl
# Quelle: python, OpenClaw@main:scripts/update_readme_stats.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Fetch ClawHub stats and update README.md download counts and security status.

package require http
package require json
package require regexp

set API_BASE "https://clawhub.ai/api/v1"
set TOKEN [expr {[info exists env(CLAWHUB_TOKEN)] ? $env(CLAWHUB_TOKEN) : ""}]

array set SKILLS {
    "Cluster Gateway"           "cluster-gateway"
    "MCP Tool Utils"            "mcp-tool-utils"
    "Reports Creator"           "reports-creator"
    "Relay Node"                "relay-node"
    "JSON Utils"                "json-utils"
    "Log Collector"             "log-collector"
    "TikTok Live Monitor"       "tiktok-live-monitor"
    "Doc Scraper"               "doc-scraper"
    "Workspace Database Manager" "workspace-database-manager"
    "Scripting Utils"           "scripting-utils"
}

proc fetch_skill {slug} {
    global API_BASE TOKEN
    set url "${API_BASE}/skills/${slug}"
    set headers [list]
    if {$TOKEN ne ""} {
        lappend headers "Authorization" "Bearer ${TOKEN}"
    }
    lappend headers "Accept" "application/json"
    
    set token [http::geturl $url -headers $headers -timeout 10000]
    set status [http::status $token]
    if {$status eq "ok"} {
        set data [http::data $token]
        http::cleanup $token
        return [json::json2dict $data]
    } else {
        set error [http::error $token]
        http::cleanup $token
        error "HTTP Error: $error"
    }
}

proc parse_skill {data} {
    # Extract skill data
    if {[dict exists $data skill]} {
        set skill_dict [dict get $data skill]
    } else {
        set skill_dict [dict create]
    }
    
    if {[dict exists $skill_dict stats]} {
        set stats_dict [dict get $skill_dict stats]
    } else {
        set stats_dict [dict create]
    }
    
    set downloads [expr {[dict exists $stats_dict downloads] ? [dict get $stats_dict downloads] : 0}]
    
    # Get version
    if {[dict exists $data latestVersion]} {
        set latest_version_dict [dict get $data latestVersion]
        set version [expr {[dict exists $latest_version_dict version] ? [dict get $latest_version_dict version] : "1.0.0"}]
    } else {
        set version "1.0.0"
    }
    
    # Format version
    if {![string match "v*" $version]} {
        set version "v${version}"
    }
    
    # Security status
    set security "✅ Pass"
    if {[dict exists $data moderation]} {
        set mod_dict [dict get $data moderation]
        if {[dict exists $mod_dict isMalwareBlocked] && [dict get $mod_dict isMalwareBlocked]} {
            set security "🚫 Blocked"
        } else {
            set security "🔍 Review"
        }
    }
    
    return [dict create \
        downloads $downloads \
        version $version \
        security $security]
}

proc main {} {
    global SKILLS
    
    array set stats {}
    set errors 0
    
    foreach {name slug} [array get SKILLS] {
        if {[catch {
            set data [fetch_skill $slug]
            set s [parse_skill $data]
            set stats($slug) $s
            puts "  OK  ${slug}: [dict get $s downloads] downloads, [dict get $s version], [dict get $s security]"
        } err]} {
            puts stderr "  ERR ${slug}: $err"
            incr errors
        }
    }
    
    if {[array size stats] == 0} {
        puts stderr "No data fetched — aborting."
        exit 1
    }
    
    set fh [open "README.md" r]
    set content [read $fh]
    close $fh
    
    foreach {name slug} [array get SKILLS] {
        if {![info exists stats($slug)]} {
            continue
        }
        
        set dl [dict get $stats($slug) downloads]
        # Escape special regex characters in the name
        set escaped_name [regsub -all {([][{}()+*?.^$\\|-])} $name {\\\1}]
        set pattern "(\\|\\s*\\\[?${escaped_name}\\]?[^|]*\\|[^|]*\\|)\\s*\\d+\\s*(\\|)"
        regsub -all -nocase $pattern $content "\\1 ${dl} \\2" new_content
        
        if {$new_content ne $content} {
            set content $new_content
            puts "  Updated: ${name} -> ${dl}"
        }
    }
    
    set fh [open "README.md" w]
    puts $fh $content
    close $fh
    
    puts "Done: [array size stats] skills, ${errors} errors."
}

main
