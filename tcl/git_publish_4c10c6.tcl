#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "78ab511a82c52a8717653c835d5e9fac9a9f9aebcf0771b6a73461a2c188bc2c", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "tcl"}
# git_publish.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

package require fileutil
package require cmdline

set SKILLS_DIR [file join $env(HOME) .openclaw workspace skills]

proc git_commit {skill_path {message ""}} {
    global SKILLS_DIR
    
    if {$message eq ""} {
        set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        set message "[skill] Auto-update [file tail $skill_path] - $timestamp"
    }
    
    if {[catch {exec git add $skill_path}]} {
        return 0
    }
    
    if {[catch {exec git commit -m $message} result]} {
        return 0
    }
    
    return 1
}

proc clawhub_publish {skill_name} {
    global SKILLS_DIR
    
    set skill_path [file join $SKILLS_DIR $skill_name]
    
    if {[catch {exec clawhub publish $skill_path --slug $skill_name --version 1.0.0} result]} {
        return [list 0 $result]
    }
    
    return [list 1 $result]
}

proc batch_publish {} {
    global SKILLS_DIR
    
    # Check git status
    if {[catch {exec git status --short $SKILLS_DIR} result]} {
        puts "Error checking git status"
        return
    }
    
    set changed {}
    foreach line [split $result "\n"] {
        if {[string trim $line] ne "" && [string match "*skills/*" $line]} {
            set parts [split $line "/"]
            set skill_index [lsearch $parts "skills"]
            if {$skill_index >= 0 && $skill_index < [expr {[llength $parts] - 1}]} {
                set skill [lindex $parts [expr {$skill_index + 1}]]
                if {$skill ni $changed} {
                    lappend changed $skill
                }
            }
        }
    }
    
    puts "Changed skills: $changed"
    
    # Publish with delay
    set count 0
    foreach skill [lrange $changed 0 4] {  ;# Max 5 per batch
        if {$count > 0} {
            puts "Waiting 15min for rate limit..."
            # In real: after 900000
        }
        
        puts "Publishing $skill..."
        set commit_ok [git_commit [file join $SKILLS_DIR $skill]]
        if {$commit_ok} {
            foreach {pub_ok output} [clawhub_publish $skill] break
            set status [expr {$pub_ok ? "✓" : "✗"}]
            puts "  $status $output"
        }
        incr count
    }
}

proc main {} {
    global SKILLS_DIR
    
    set options {
        {skill.arg "" "Single skill to publish"}
        {all "Publish all changed"}
        {no-publish "Commit only"}
        {message.arg "" "Custom commit message"}
    }
    
    set usage ": git_publish.tcl \[options]\nOptions:"
    array set params [cmdline::getoptions argv $options $usage]
    
    if {$params(skill) ne ""} {
        set skill_path [file join $SKILLS_DIR $params(skill)]
        if {$params(no-publish)} {
            git_commit $skill_path $params(message)
        } else {
            git_commit $skill_path $params(message)
            clawhub_publish $params(skill)
        }
    } elseif {$params(all)} {
        batch_publish
    } else {
        puts "Use --skill <name> or --all"
    }
}

if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    main
}
