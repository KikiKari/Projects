#!/usr/bin/env tclsh8.6
# sync_agent_cron.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_cron.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_cron.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# 
# ClawHub ↔ Git Sync Agent - Cron Version mit Dry-Run + Auto-Sync
# 

# Set up paths
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"
set LOG_FILE "/home/openclaw/.openclaw/workspace/logs/sync-agent.log"
set STATE_FILE "/home/openclaw/.openclaw/workspace/db/sync_state.json"

# Load helper functions
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.tcl

proc file_mtime {path} {
    set max_mtime 0
    catch {
        set files [glob -nocomplain -dir $path -types f **]
        foreach file $files {
            if {![string match "*.git*" $file]} {
                set mtime [file mtime $file]
                if {$mtime > $max_mtime} {
                    set max_mtime $mtime
                }
            }
        }
    }
    return $max_mtime
}

proc write_to_log {message {level "INFO"}} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    set fh [open $::LOG_FILE a]
    puts $fh $entry
    close $fh
}

# Override log function
proc log {msg {level INFO}} {
    write_to_log $msg $level
}

# Start logging
write_to_log "======================================================================"
write_to_log "CLAWHUB ↔ GIT SYNC AGENT - CRON LAUF"
write_to_log "Zeitstempel: [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]"
write_to_log "======================================================================"

# Get skill directories
proc get_skill_dirs {dir} {
    set skills {}
    catch {
        foreach d [glob -nocomplain -dir $dir *] {
            if {[file isdirectory $d] && ![string match ".*" [file tail $d]]} {
                lappend skills [file tail $d]
            }
        }
    }
    return $skills
}

set clawhub_skills [get_skill_dirs $CLAWHUB_DIR]
set git_skills [get_skill_dirs $GIT_DIR]

# DRY-RUN: Analyze changes
write_to_log ""
write_to_log "\[DRY-RUN\] Analysiere Änderungen..."

array set changes_detected {
    new_in_clawhub {}
    new_in_git {}
    clawhub_newer {}
    git_newer {}
    synced {}
}

# 1. New skills
set new_in_clawhub {}
foreach skill $clawhub_skills {
    if {$skill ni $git_skills && ![string match ".*" $skill]} {
        lappend new_in_clawhub $skill
    }
}
set new_in_git {}
foreach skill $git_skills {
    if {$skill ni $clawhub_skills && ![string match ".*" $skill]} {
        lappend new_in_git $skill
    }
}
set changes_detected(new_in_clawhub) $new_in_clawhub
set changes_detected(new_in_git) $new_in_git

# 2. Check existing
set in_both {}
foreach skill $clawhub_skills {
    if {$skill in $git_skills} {
        lappend in_both $skill
    }
}

foreach skill $in_both {
    set c_mtime [file_mtime "$CLAWHUB_DIR/$skill"]
    set g_mtime [file_mtime "$GIT_DIR/$skill"]
    set diff [expr {$c_mtime - $g_mtime}]
    
    if {abs($diff) > 60} {
        if {$diff > 0} {
            lappend changes_detected(clawhub_newer) [list $skill $diff]
        } else {
            lappend changes_detected(git_newer) [list $skill [expr {abs($diff)}]]
        }
    } else {
        lappend changes_detected(synced) $skill
    }
}

# Report
set total_changes [expr {[llength $new_in_clawhub] + [llength $new_in_git] + [llength $changes_detected(clawhub_newer)] + [llength $changes_detected(git_newer)]}]
write_to_log "Neu in ClawHub: [llength $new_in_clawhub]"
write_to_log "Neu in Git: [llength $new_in_git]"
write_to_log "ClawHub neuer: [llength $changes_detected(clawhub_newer)]"
write_to_log "Git neuer: [llength $changes_detected(git_newer)]"
write_to_log "Synchron: [llength $changes_detected(synced)]"

if {$total_changes == 0} {
    write_to_log ""
    write_to_log "✅ Keine Änderungen erkannt. Sync nicht nötig."
    write_to_log "======================================================================"
    exit 0
}

write_to_log ""
write_to_log "🔄 $total_changes Änderungen erkannt - starte Synchronisation..."

# REAL SYNCHRONIZATION
array set results {
    synced_to_git {}
    synced_to_clawhub {}
    up_to_date {}
    errors {}
}

# 1. NEW in ClawHub → to Git
foreach skill $new_in_clawhub {
    if {[catch {
        if {[validate_skill "$CLAWHUB_DIR/$skill"]} {
            write_to_log "→ Synchronisiere $skill zu Git..."
            if {[sync_to_git $skill 0]} {
                set git_path "$GIT_DIR/$skill"
                cd $git_path
                exec git init -q 2>/dev/null
                exec git add . -f 2>/dev/null
                set commit_msg "Initial: $skill"
                exec git commit -m $commit_msg -q 2>/dev/null
                lappend results(synced_to_git) $skill
                write_to_log "  ✓ $skill synchronisiert"
            }
        } else {
            lappend results(errors) "$skill (invalid)"
        }
    } err]} {
        write_to_log "  ✗ ERROR: $skill - $err" "ERROR"
        lappend results(errors) "$skill"
    }
}

# 2. NEW in Git → to ClawHub
foreach skill $new_in_git {
    if {[catch {
        if {[validate_skill "$GIT_DIR/$skill"]} {
            write_to_log "→ Synchronisiere $skill zu ClawHub..."
            if {[sync_to_clawhub $skill 0]} {
                lappend results(synced_to_clawhub) $skill
                write_to_log "  ✓ $skill synchronisiert"
            }
        } else {
            lappend results(errors) "$skill (invalid)"
        }
    } err]} {
        write_to_log "  ✗ ERROR: $skill - $err" "ERROR"
        lappend results(errors) "$skill"
    }
}

# 3. Updates
foreach item $changes_detected(clawhub_newer) {
    set skill [lindex $item 0]
    set diff [lindex $item 1]
    if {[catch {
        write_to_log "→ Update $skill (ClawHub +[format "%.0f" $diff]s neuer)..."
        if {[sync_to_git $skill 0]} {
            set git_path "$GIT_DIR/$skill"
            cd $git_path
            exec git add . -f 2>/dev/null
            set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]
            set commit_msg "Sync from ClawHub: $dt"
            exec git commit -m $commit_msg -q 2>/dev/null
            lappend results(synced_to_git) $skill
            write_to_log "  ✓ $skill aktualisiert"
        }
    } err]} {
        write_to_log "  ✗ ERROR: $skill - $err" "ERROR"
        lappend results(errors) "$skill"
    }
}

foreach item $changes_detected(git_newer) {
    set skill [lindex $item 0]
    set diff [lindex $item 1]
    if {[catch {
        write_to_log "→ Update $skill (Git +[format "%.0f" $diff]s neuer)..."
        if {[sync_to_clawhub $skill 0]} {
            lappend results(synced_to_clawhub) $skill
            write_to_log "  ✓ $skill aktualisiert"
        }
    } err]} {
        write_to_log "  ✗ ERROR: $skill - $err" "ERROR"
        lappend results(errors) "$skill"
    }
}

set results(up_to_date) $changes_detected(synced)

# SUMMARY
write_to_log ""
write_to_log "======================================================================"
write_to_log "SYNCHRONISATION ABGESCHLOSSEN"
write_to_log "======================================================================"
write_to_log "Zu Git synchronisiert:     [llength $results(synced_to_git)]"
write_to_log "Zu ClawHub synchronisiert: [llength $results(synced_to_clawhub)]"
write_to_log "Bereits aktuell:           [llength $results(up_to_date)]"
write_to_log "Fehler:                    [llength $results(errors)]"
if {[llength $results(errors)] > 0} {
    write_to_log "  Fehlerhafte: [join $results(errors) ", "]"
}
write_to_log "======================================================================"

# Save state
file mkdir [file dirname $STATE_FILE]
set state(last_run) [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
set state(results) $results
array set state_data {}
foreach {key value} [array get changes_detected] {
    if {[llength $value] > 0} {
        set state_data($key) [llength $value]
    } else {
        set state_data($key) $value
    }
}
set state(changes_detected) [array get state_data]

set fh [open $STATE_FILE w]
puts $fh [json::encode $state]
close $fh
write_to_log "State gespeichert: $STATE_FILE"
