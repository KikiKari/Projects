#!/usr/bin/env tclsh8.6
# collect_compare_bundle.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

set ROOT "/home/openclaw/.openclaw"
set OUT_DIR "${ROOT}/workspace/vscode/compare"
set TRANSFER_DIR "${OUT_DIR}/transfer"
set MD_FILE "${OUT_DIR}/local-gateway-config.md"
set TREE_FILE "${OUT_DIR}/tree.txt"
set BACKUP_FILE "/home/openclaw/openclaw-backup.tar.gz"

# Datum und Zeit ermitteln
set NOW_LOCAL [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"]
set NOW_UTC [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]

# Hostname ermitteln
if {[catch {exec hostname -f} HOST]} {
    set HOST [exec hostname]
}

set OPENCLAW_JSON "${ROOT}/openclaw.json"
set EXEC_APPROVALS_JSON "${ROOT}/exec-approvals.json"
set GATEWAY_SYSTEMD_ENV "${ROOT}/gateway.systemd.env"
set DOT_ENV "${ROOT}/.env"
set CONFIG_DIR "${ROOT}/.config"
set AGENTS_DIR "${ROOT}/agents"

# Verzeichnisse erstellen
file mkdir $OUT_DIR
file mkdir $TRANSFER_DIR

# Prüfen ob 'tree' installiert ist
if {[catch {exec which tree}]} {
    puts "Fehler: 'tree' ist nicht installiert."
    exit 1
}

# Funktion zum Anhängen einer Datei an die Markdown-Datei
proc append_file_verbatim {label path lang md_file} {
    set fp [open $md_file a]
    puts $fp ""
    puts $fp "## $label"
    puts $fp ""
    puts $fp "Pfad: \`$path\`"
    puts $fp ""
    puts $fp "\`\`\`$lang"
    if {[file exists $path]} {
        set file_handle [open $path r]
        set content [read $file_handle]
        close $file_handle
        puts $fp $content
    } else {
        puts $fp "\[FEHLT\] $path"
    }
    puts $fp ""
    puts $fp "\`\`\`"
    close $fp
}

# Funktion zum Anhängen der Umgebungsvariablen
proc append_env_verbatim {md_file} {
    set fp [open $md_file a]
    puts $fp ""
    puts $fp "## Umgebungsvariablen (env)"
    puts $fp ""
    puts $fp "\`\`\`text"
    foreach {key value} [array get env] {
        puts $fp "$key=$value"
    }
    puts $fp "\`\`\`"
    close $fp
}

# Funktion zum Anhängen aller Dateien eines Verzeichnisses
proc append_dir_files_verbatim {section dir md_file} {
    set fp [open $md_file a]
    puts $fp ""
    puts $fp "## $section"
    puts $fp ""
    if {![file isdirectory $dir]} {
        puts $fp "\[FEHLT\] $dir"
        close $fp
        return
    }
    puts $fp "Basisverzeichnis: \`$dir\`"
    close $fp

    # Alle Dateien im Verzeichnis und Unterverzeichnissen finden
    set files [exec find $dir -type f | sort]
    foreach f $files {
        set fp [open $md_file a]
        puts $fp ""
        puts $fp "### Datei: \`$f\`"
        puts $fp ""
        puts $fp "\`\`\`text"
        set file_handle [open $f r]
        set content [read $file_handle]
        close $file_handle
        puts $fp $content
        puts $fp ""
        puts $fp "\`\`\`"
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
append_file_verbatim "openclaw.json" $OPENCLAW_JSON "json" $MD_FILE
append_file_verbatim "exec-approvals.json" $EXEC_APPROVALS_JSON "json" $MD_FILE
append_file_verbatim "gateway.systemd.env" $GATEWAY_SYSTEMD_ENV "dotenv" $MD_FILE
append_file_verbatim ".env" $DOT_ENV "dotenv" $MD_FILE
append_env_verbatim $MD_FILE
append_dir_files_verbatim ".config (alle Dateien rekursiv)" $CONFIG_DIR $MD_FILE
append_dir_files_verbatim "agents (alle Dateien rekursiv)" $AGENTS_DIR $MD_FILE

# Baumstruktur erstellen
exec tree -a -L 6 $ROOT > $TREE_FILE

# Backup erstellen
exec openclaw backup create --output $BACKUP_FILE --verify
exec cp $BACKUP_FILE $OUT_DIR

puts "OK"
puts "Erzeugt:"
puts "- $MD_FILE"
puts "- $TREE_FILE"
puts "- $BACKUP_FILE"
puts "- $TRANSFER_DIR (leer)"
