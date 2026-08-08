#!/usr/bin/env tclsh8.6
# abstractions-publish-gateway.sh — portiert nach tcl
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.tcl
#
# Pusht den Stand von workspace/git/Abstraktionen/ auf den
# gateway{1,2}-abstractions-Branch.
#
# Exit-Codes:
#   0 = Erfolg (gepusht ODER nichts zu tun)
#   1 = Unerwarteter Branch
#   2 = Secret im Diff gefunden
#   3 = Git-Operation fehlgeschlagen
#   4 = Repo-Pfad nicht erreichbar oder kein Git-Repo

package require Tcl 8.6

set ABSTRACTIONS_REPO "/home/openclaw/.openclaw/workspace/git/Abstraktionen"
set LOG_DIR "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
file mkdir $LOG_DIR
set LOG_FILE [format "%s/%s.log" $LOG_DIR [clock format [clock seconds] -format "%Y-%m-%d"]]

proc log {msg} {
    global LOG_FILE
    set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set log_line "\[$ts\] $msg"
    puts $log_line
    set fh [open $LOG_FILE a]
    puts $fh $log_line
    close $fh
}

# --- Schritt 1: Repo erreichbar? ---
if {![file isdirectory $ABSTRACTIONS_REPO]} {
    log "STATUS=error CODE=4 REASON=repo-unreachable PATH=$ABSTRACTIONS_REPO"
    exit 4
}

if {[catch {cd $ABSTRACTIONS_REPO}]} {
    log "STATUS=error CODE=4 REASON=repo-unreachable PATH=$ABSTRACTIONS_REPO"
    exit 4
}

if {![file isdirectory ".git"]} {
    log "STATUS=error CODE=4 REASON=not-a-git-repo PATH=$ABSTRACTIONS_REPO"
    exit 4
}

# --- Schritt 2: Branch ermitteln ---
if {[catch {exec git branch --show-current} BRANCH]} {
    log "STATUS=error CODE=3 REASON=git-branch-failed"
    exit 3
}

if {$BRANCH ne "gateway1-abstractions" && $BRANCH ne "gateway2-abstractions"} {
    log "STATUS=error CODE=1 REASON=unexpected-branch BRANCH=$BRANCH"
    exit 1
}
log "STATUS=info STEP=branch-detected BRANCH=$BRANCH"

# --- Schritt 3: Hat sich was geändert? ---
if {[catch {exec git status --porcelain} STATUS_OUTPUT]} {
    log "STATUS=error CODE=3 REASON=git-status-failed"
    exit 3
}

if {$STATUS_OUTPUT eq ""} {
    log "STATUS=skip REASON=no-changes BRANCH=$BRANCH"
    exit 0
}

set CHANGED_COUNT [llength [split $STATUS_OUTPUT "\n"]]
if {$CHANGED_COUNT > 0 && [string index $STATUS_OUTPUT end] eq ""} {
    incr CHANGED_COUNT -1
}
log "STATUS=info STEP=changes-detected COUNT=$CHANGED_COUNT BRANCH=$BRANCH"

# --- Schritt 4: Secret-Scan auf geänderte Dateien ---
set SECRET_PATTERNS {(?:sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|ntn_[A-Za-z0-9]{30,}|secret_[A-Za-z0-9]{30,}|tvly-[A-Za-z0-9-]{20,}|nvapi-[A-Za-z0-9]{30,}|tskey-[A-Za-z0-9-]{20,}|xoxb-[A-Za-z0-9-]{20,}|xapp-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{30,})}

set SECRET_HITS ""
foreach line [split $STATUS_OUTPUT "\n"] {
    if {$line eq ""} continue
    set file_path [string range $line 3 end]
    if {[file isfile $file_path]} {
        set fh [open $file_path r]
        set content [read $fh]
        close $fh
        if {[regexp $SECRET_PATTERNS $content matched_pattern]} {
            set match [string range $matched_pattern 0 9]
            append SECRET_HITS " $file_path\[$match...\]"
        }
    }
}

if {$SECRET_HITS ne ""} {
    log "STATUS=error CODE=2 REASON=secrets-found HITS=$SECRET_HITS"
    exit 2
}
log "STATUS=info STEP=secret-scan-clean"

# --- Schritt 5: Stage + Commit ---
if {[catch {exec git add -A} result]} {
    log "STATUS=error CODE=3 REASON=git-add-failed"
    puts $result
    exit 3
} else {
    puts $result
}

set COMMIT_MSG "auto: abstractions-sync [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]"
if {[catch {exec git commit -m $COMMIT_MSG} result]} {
    if {[catch {exec git status --porcelain} status_result] || $status_result ne ""} {
        log "STATUS=error CODE=3 REASON=git-commit-failed"
        puts $result
        exit 3
    } else {
        log "STATUS=skip REASON=nothing-staged-after-add"
        exit 0
    }
} else {
    puts $result
}

if {[catch {exec git log -1 --format=%h} COMMIT_HASH]} {
    log "STATUS=error CODE=3 REASON=git-log-failed"
    exit 3
}
log "STATUS=info STEP=commit-created HASH=$COMMIT_HASH MSG=\"$COMMIT_MSG\""

# --- Schritt 6: Push ---
if {[catch {exec git push} result]} {
    log "STATUS=error CODE=3 REASON=git-push-failed BRANCH=$BRANCH HASH=$COMMIT_HASH"
    puts $result
    exit 3
} else {
    puts $result
}

# --- Erfolg ---
log "STATUS=ok BRANCH=$BRANCH COUNT=$CHANGED_COUNT HASH=$COMMIT_HASH"
puts ""
puts "=== SUMMARY ==="
puts "Branch:  $BRANCH"
puts "Files:   $CHANGED_COUNT"
puts "Commit:  $COMMIT_HASH"
puts "Status:  OK - gepusht nach origin/$BRANCH"
exit 0
