#!/usr/bin/env tclsh8.6
# git_publish.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

package require Tcl 8.6
package require json

set SKILLS_DIR [file join $env(HOME) .openclaw workspace skills]

proc git_commit {skill_path {message ""}} {
    global SKILLS_DIR
    if {$message eq ""} {
        set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        set message "\[skill\] Auto-update [file tail $skill_path] - $timestamp"
    }
    
    set parent_dir [file dirname $SKILLS_DIR]
    if {[catch {exec git add $skill_path} result]} {
        puts "git add failed: $result"
        return 0
    }
    
    if {[catch {exec git commit -m $message} result]} {
        puts "git commit failed: $result"
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
    if {[catch {exec git status --short $SKILLS_DIR} result]} {
        puts "git status failed: $result"
        return
    }
    
    set changed {}
    foreach line [split $result "\n"] {
        if {[string trim $line] ne "" && [string match "*skills/*" $line]} {
            set skill [lindex [split [string range $line [string first "skills/" $line] end] "/"] 1]
            if {$skill ni $changed} {
                lappend changed $skill
            }
        }
    }
    
    puts "Changed skills: $changed"
    
    set count 0
    foreach skill [lrange $changed 0 4] {
        if {$count > 0} {
            puts "Waiting 15min for rate limit..."
            # In real: after 900000
        }
        
        puts "Publishing $skill..."
        set commit_ok [git_commit [file join $SKILLS_DIR $skill]]
        if {$commit_ok} {
            lassign [clawhub_publish $skill] pub_ok output
            set status [expr {$pub_ok ? "✓" : "✗"}]
            puts "  $status $output"
        }
        incr count
    }
}

proc main {} {
    global SKILLS_DIR argv
    
    set skill ""
    set all 0
    set no_publish 0
    set message ""
    
    # Simple argument parsing
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -- $arg {
            "--skill" {
                incr i
                set skill [lindex $argv $i]
            }
            "--all" {
                set all 1
            }
            "--no-publish" {
                set no_publish 1
            }
            "--message" {
                incr i
                set message [lindex $argv $i]
            }
            default {
                puts "Unknown argument: $arg"
                return
            }
        }
    }
    
    if {$skill ne ""} {
        set skill_path [file join $SKILLS_DIR $skill]
        if {$no_publish} {
            git_commit $skill_path $message
        } else {
            git_commit $skill_path $message
            clawhub_publish $skill
        }
    } elseif {$all} {
        batch_publish
    } else {
        puts "Use --skill <name> or --all"
    }
}

if {[info script] eq $argv0} {
    main
}
