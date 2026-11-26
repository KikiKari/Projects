#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "2fccc8b0b9db9db9ce051802f8ada4a4dd27a98f1803ed1a4a91168276e755b6", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "tcl"}
# collect_compare_bundle.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

set ROOT "/home/openclaw/.openclaw"
set OUT_DIR "${ROOT}/workspace/vscode/compare"
set TRANSFER_DIR "${OUT_DIR}/transfer"
set MD_FILE "${OUT_DIR}/local-gateway-config.md"
set TREE_FILE "${OUT_DIR}/tree.txt"
set BACKUP_FILE "/home/openclaw/openclaw-backup.tar.gz"

# Zeitstempel erzeugen
set NOW_LOCAL [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"]
set NOW_UTC [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]

# Hostname bestimmen
if {[catch {exec hostname -f} HOST]} {
    set HOST [exec hostname]
}

set OPENCLAW_JSON "${ROOT}/openclaw.json"
set EXEC_APPROVALS_JSON "${ROOT}/exec-approvals.json"
set GATEWAY_SYSTEMD_ENV "${ROOT}/gateway.systemd.env"
set DOT_ENV "${ROOT}/.env"
set CONFIG_DIR "${ROOT}/.config"
set AGENTS_DIR "${ROOT}/agents"

# Ausgabeverzeichnisse erstellen
file mkdir $OUT_DIR
file mkdir $TRANSFER_DIR

# Prüfen ob tree installiert ist
if {[catch {exec which tree}]} {
    puts stderr "Fehler: 'tree' ist nicht installiert."
    exit 1
}

# Hilfsfunktion zum Anhängen von Dateiinhalten
proc append_file_verbatim {label path {lang "text"}} {
    global MD_FILE
    set fp [open $MD_FILE a]
    
    puts $fp ""
    puts $fp "## $label"
    puts $fp ""
    puts $fp "Pfad: \`$path\`"
    puts $fp ""
    puts $fp "```$lang"
    
    if {[file exists $path] && [file isfile $path]} {
        set file_fp [open $path r]
        while {[gets $file_fp line] >= 0} {
            puts $fp $line
        }
        close $file_fp
    } else {
        puts $fp "\[FEHLT\] $path"
    }
    
    puts $fp ""
    puts $fp "```"
    close $fp
}

# Hilfsfunktion zum Anhängen der Umgebungsvariablen
proc append_env_verbatim {} {
    global MD_FILE
    set fp [open $MD_FILE a]
    
    puts $fp ""
    puts $fp "## Umgebungsvariablen (env)"
    puts $fp ""
    puts $fp "```text"
    
    foreach var [lsort [array names ::env]] {
        puts $fp "$var=$::env($var)"
    }
    
    puts $fp "```"
    close $fp
}

# Hilfsfunktion zum Anhängen aller Dateien eines Verzeichnisses
proc append_dir_files_verbatim {section dir} {
    global MD_FILE
    set fp [open $MD_FILE a]
    
    puts $fp ""
    puts $fp "## $section"
    puts $fp ""
    
    if {![file exists $dir] || ![file isdirectory $dir]} {
        puts $fp "\[FEHLT\] $dir"
        close $fp
        return
    }
    
    puts $fp "Basisverzeichnis: \`$dir\`"
    close $fp
    
    # Alle Dateien im Verzeichnis finden und sortieren
    set files [list]
    proc find_files {dir} {
        global files
        foreach item [glob -nocomplain -dir $dir *] {
            if {[file isfile $item]} {
                lappend files $item
            } elseif {[file isdirectory $item]} {
                find_files $item
            }
        }
    }
    
    find_files $dir
    set files [lsort $files]
    
    foreach f $files {
        set fp [open $MD_FILE a]
        puts $fp ""
        puts $fp "### Datei: \`$f\`"
        puts $fp ""
        puts $fp "```text"
        
        set file_fp [open $f r]
        while {[gets $file_fp line] >= 0} {
            puts $fp $line
        }
        close $file_fp
        
        puts $fp ""
        puts $fp "```"
        close $fp
    }
}

# Markdown-Datei initial erstellen
set fp [open $MD_FILE w]
puts $fp "# Lokaler Gateway-Konfigurationsstand"
puts $fp ""
puts $fp "Generiert: $NOW_LOCAL"
puts $fp "UTC: $NOW_UTC"
puts $fp "Host: $HOST"
puts $fp ""
puts $fp "Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten."
close $fp

# Dateien anhängen
append_file_verbatim "openclaw.json" $OPENCLAW_JSON "json"
append_file_verbatim "exec-approvals.json" $EXEC_APPROVALS_JSON "json"
append_file_verbatim "gateway.systemd.env" $GATEWAY_SYSTEMD_ENV "dotenv"
append_file_verbatim ".env" $DOT_ENV "dotenv"
append_env_verbatim
append_dir_files_verbatim ".config (alle Dateien rekursiv)" $CONFIG_DIR
append_dir_files_verbatim "agents (alle Dateien rekursiv)" $AGENTS_DIR

# Baumstruktur erzeugen
exec tree -a -L 6 $ROOT > $TREE_FILE

# Backup erstellen
exec openclaw backup create --output $BACKUP_FILE --verify

# Backup kopieren
file copy -force $BACKUP_FILE $OUT_DIR

puts "OK"
puts "Erzeugt:"
puts "- $MD_FILE"
puts "- $TREE_FILE"
puts "- $BACKUP_FILE"
puts "- $TRANSFER_DIR (leer)"
