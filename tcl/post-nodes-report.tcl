#!/usr/bin/env tclsh
# post-nodes-report.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/post-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/post-nodes-report.js
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Pfade
set DASHBOARD_PATH [file join [file dirname [file dirname [info script]]] dashboards nodes-overview.md]
set REPORT_LOG [file join [file dirname [file dirname [info script]]] logs nodes-report.log]

# Farbcodes
array set C [list \
  green  "\033\[32m" \
  yellow "\033\[33m" \
  red    "\033\[31m" \
  reset  "\033\[0m" \
]

proc postReport {} {
  global DASHBOARD_PATH REPORT_LOG C
  
  # Inhalt lesen
  if {[catch {open $DASHBOARD_PATH r} fh]} {
    puts stderr "${C(red)}❌ Fehler beim Lesen der Dashboard-Datei:${C(reset)} $fh"
    return
  }
  
  set content [read $fh]
  close $fh
  
  # JSON-kompatibel machen: Zeilenumbrüche escapen
  regsub -all {\n} $content "\\n" json_content
  regsub -all {"} $json_content "\\\"" escaped_content
  
  # Nachricht über OpenClaw senden
  set messageCmd "openclaw message send --target=main --message \"$escaped_content\""
  
  if {[catch {exec {*}$messageCmd} result options]} {
    set errorMsg [dict get $options -errorcode]
    puts stderr "${C(red)}❌ Fehler beim Senden der Nachricht:${C(reset)} $errorMsg"
    set log_fh [open $REPORT_LOG a]
    puts $log_fh "\[[clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]\] Failed to post: $errorMsg"
    close $log_fh
  } else {
    puts "${C(green)}✅ Report erfolgreich im 'main'-Channel gepostet.${C(reset)}"
    set log_fh [open $REPORT_LOG a]
    puts $log_fh "\[[clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]\] Report posted."
    close $log_fh
  }
}

# Hauptausführung
puts "${C(yellow)}📤 Sende Nodes-Übersicht in 'main'...${C(reset)}"
postReport
