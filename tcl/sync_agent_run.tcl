#!/usr/bin/env tclsh8.6
# sync_agent_run.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_run.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_run.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# ClawHub ↔ Git Sync Agent - Produktionslauf

lappend auto_path /home/openclaw/.openclaw/workspace/scripts
package require json

source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.tcl

set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"

proc file_mtime {path} {
    set files {}
    catch {
        set dirlist [glob -nocomplain -directory $path -types f -r *]
        foreach f $dirlist {
            if {![string match "*.git*" $f]} {
                lappend files $f
            }
        }
    }
    
    if {[llength $files] == 0} {
        return 0
    }
    
    set mtimes {}
    foreach f $files {
        if {[catch {file mtime $f} mtime]} {
            continue
        }
        lappend mtimes $mtime
    }
    
    if {[llength $mtimes] == 0} {
        return 0
    }
    
    return [tcl::mathfunc::max {*}$mtimes]
}

proc get_directories {dir} {
    set result {}
    catch {
        set items [glob -nocomplain -directory $dir *]
        foreach item $items {
            if {[file isdirectory $item] && ![string match ".*" [file tail $item]]} {
                lappend result [file tail $item]
            }
        }
    }
    return $result
}

log [string repeat "=" 70]
log "CLAWHUB ↔ GIT SYNC AGENT - PRODUKTIONS-LAUF"
log "Zeitstempel: [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]"
log [string repeat "=" 70]

set clawhub_skills [get_directories $CLAWHUB_DIR]
set git_skills [get_directories $GIT_DIR]

array set results [
    list \
    synced_to_git {} \
    synced_to_clawhub {} \
    up_to_date {} \
    errors {}
]

# 1. NEU in ClawHub → zu Git syncen
log "\n\[PHASE 1\] ClawHub → Git Synchronisation"
log [string repeat "-" 40]

set new_in_clawhub {}
foreach skill $clawhub_skills {
    if {$skill ni $git_skills} {
        lappend new_in_clawhub $skill
    }
}
set new_in_clawhub [lsort $new_in_clawhub]

foreach skill $new_in_clawhub {
    if {[catch {
        if {[validate_skill [file join $CLAWHUB_DIR $skill]]} {
            log "→ Synchronisiere $skill zu Git..."
            if {[sync_to_git $skill 0]} {
                # Git init
                set git_path [file join $GIT_DIR $skill]
                cd $git_path
                exec git init -q 2>/dev/null
                exec git add . -f 2>/dev/null
                set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]
                exec git commit -m "Initial: $skill" -q 2>/dev/null
                lappend results(synced_to_git) $skill
                log "  ✓ $skill synchronisiert & Git initialisiert"
            } else {
                lappend results(errors) "$skill (sync failed)"
            }
        } else {
            lappend results(errors) "$skill (invalid)"
        }
    } errmsg]} {
        log "  ✗ ERROR: $skill - $errmsg" "ERROR"
        lappend results(errors) "$skill (exception)"
    }
}

# 2. In beiden - prüfe Änderungen
log "\n\[PHASE 2\] Prüfe existierende Skills auf Änderungen"
log [string repeat "-" 40]

set in_both {}
foreach skill $clawhub_skills {
    if {$skill in $git_skills} {
        lappend in_both $skill
    }
}
set in_both [lsort $in_both]

foreach skill $in_both {
    if {[catch {
        set c_mtime [file_mtime [file join $CLAWHUB_DIR $skill]]
        set g_mtime [file_mtime [file join $GIT_DIR $skill]]
        set diff [expr {$c_mtime - $g_mtime}]
        
        if {abs($diff) > 60} {
            if {$diff > 0} {
                log "→ $skill: ClawHub neuer (+[format "%.0f" $diff]s) → sync zu Git"
                if {[sync_to_git $skill 0]} {
                    set git_path [file join $GIT_DIR $skill]
                    cd $git_path
                    exec git add . -f 2>/dev/null
                    set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]
                    exec git commit -m "Sync from ClawHub: $dt" -q 2>/dev/null
                    lappend results(synced_to_git) $skill
                } else {
                    lappend results(errors) "$skill (update failed)"
                }
            } else {
                log "→ $skill: Git neuer (+[format "%.0f" [expr {abs($diff)}]]s) → sync zu ClawHub"
                if {[sync_to_clawhub $skill 0]} {
                    lappend results(synced_to_clawhub) $skill
                } else {
                    lappend results(errors) "$skill (update failed)"
                }
            }
        } else {
            lappend results(up_to_date) $skill
        }
    } errmsg]} {
        log "  ✗ ERROR: $skill - $errmsg" "ERROR"
        lappend results(errors) "$skill (exception)"
    }
}

# ZUSAMMENFASSUNG
log "\n[string repeat "=" 70]"
log "SYNCHRONISATION ABGESCHLOSSEN"
log [string repeat "=" 70]
log "Zu Git synchronisiert:     [llength $results(synced_to_git)]"
if {[llength $results(synced_to_git)] > 0} {
    log "  [join $results(synced_to_git) ", "]"
}
log "Zu ClawHub synchronisiert: [llength $results(synced_to_clawhub)]"
if {[llength $results(synced_to_clawhub)] > 0} {
    log "  [join $results(synced_to_clawhub) ", "]"
}
log "Bereits aktuell:           [llength $results(up_to_date)]"
log "Fehler:                    [llength $results(errors)]"
if {[llength $results(errors)] > 0} {
    log "  [join $results(errors) ", "]"
}
log [string repeat "=" 70]

# Speichere State
set STATE_FILE "/home/openclaw/.openclaw/workspace/db/sync_state.json"
file mkdir [file dirname $STATE_FILE]
set now [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
set state [dict create \
    last_run $now \
    results [dict create \
        synced_to_git $results(synced_to_git) \
        synced_to_clawhub $results(synced_to_clawhub) \
        up_to_date $results(up_to_date) \
        errors $results(errors) \
    ] \
]
set fp [open $STATE_FILE w]
puts $fp [::json::write indented $state]
close $fp
log "State gespeichert: $STATE_FILE"
