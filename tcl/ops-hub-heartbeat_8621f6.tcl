#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "9624bbf3afb16734c00f20f7e34f13195ad67d945a8e8cae55ba6cd76d201983", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "tcl"}
# ops-hub-heartbeat.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Port of ops-hub-heartbeat.js

# Funktion zum Lesen einer Datei
proc readFile {filename} {
    if {[catch {open $filename r} fh]} {
        error "Konnte $filename nicht öffnen: $fh"
    }
    set content [read $fh]
    close $fh
    return $content
}

# Funktion zum Schreiben einer Datei
proc writeFile {filename content} {
    if {[catch {open $filename w} fh]} {
        error "Konnte $filename nicht öffnen: $fh"
    }
    puts -nonewline $fh $content
    close $fh
}

# Aktualisiere den Statusbericht mit aktueller Zeit
# Ermittle das Verzeichnis des Skripts
set scriptDir [file dirname [info script]]
set statusPath [file join $scriptDir ../docs/ops-hub/status.md]

proc updateHeartbeat {} {
    global statusPath
    
    # Lies den Inhalt der Datei
    if {[catch {readFile $statusPath} content]} {
        puts stderr "❌ Konnte status.md nicht lesen: $content"
        return
    }
    
    # Aktuelle Zeit im deutschen Format (MESZ/MET)
    set now [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S" -timezone :Europe/Berlin]
    
    # Ersetze die Zeile mit dem Heartbeat
    regsub {(Letzter Heartbeat:) [^\n]*} $content "\\1 $now" updated
    
    # Schreibe den aktualisierten Inhalt zurück
    if {[catch {writeFile $statusPath $updated}]} {
        puts stderr "❌ Konnte status.md nicht schreiben: $updated"
    } else {
        puts "✅ Heartbeat aktualisiert: $now"
    }
}

# Führe die Funktion aus
updateHeartbeat
