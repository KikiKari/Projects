#!/usr/bin/env tclsh
# backup_dbs.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:tmp/backup_dbs.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Backup docs.db and tree.db with timestamp into /workspace/db/backups

# Get workspace path from environment or use default
set workspace [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : "/workspace"}]

# Create backup directory path
set backup_dir [file join $workspace "db" "backups"]

# Ensure backup_dir exists
if {![file exists $backup_dir]} {
    file mkdir $backup_dir
}

# Generate timestamp
set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]

# Process each database file
foreach db_name {"docs.db" "tree.db"} {
    set src [file join $workspace $db_name]
    if {[file exists $src] && [file isfile $src]} {
        set dest [file join $backup_dir "${timestamp}_${db_name}.bak"]
        file copy -force $src $dest
        puts "Backup created: $dest"
    } else {
        puts "Source db not found: $src"
    }
}
