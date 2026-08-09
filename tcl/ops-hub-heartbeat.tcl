#!/usr/bin/env tclsh
# ops-hub-heartbeat.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Aktualisiere den Statusbericht mit aktueller Zeit
set statusPath [file join [file dirname [file dirname [info script]]] docs ops-hub status.md]

proc updateHeartbeat {} {
    global statusPath
    
    # Lies den Inhalt der Datei
    if {[catch {open $statusPath r} fd]} {
        puts stderr "❌ Konnte status.md nicht lesen: $fd"
        return
    }
    
    set content [read $fd]
    close $fd
    
    # Aktuelle Zeit im deutschen Format (Europe/Berlin)
    set now [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S" -timezone :Europe/Berlin]
    
    # Ersetze die Zeile mit dem Heartbeat
    regsub {(Letzter Heartbeat:) [^\n]*} $content "\\1 $now" updated
    
    # Schreibe den aktualisierten Inhalt zurück
    if {[catch {open $statusPath w} fd]} {
        puts stderr "❌ Konnte status.md nicht schreiben: $fd"
        return
    }
    
    puts -nonewline $fd $updated
    close $fd
    
    puts "✅ Heartbeat aktualisiert: $now"
}

updateHeartbeat
