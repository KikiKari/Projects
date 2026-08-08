#!/usr/bin/env tclsh
# TelegramMonitorCompanion.ps1 — portiert nach tcl
# Quelle: powershell, Projects@Telegram-Monitor:TelegramMonitorCompanion.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Telegram Monitor Companion — Starter
#
# Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
# bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
# Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
# gestartet — dann wird nur das Fenster geoeffnet.
#
# Aufruf:
#   tclsh TelegramMonitorCompanion.tcl              starten und oeffnen
#   tclsh TelegramMonitorCompanion.tcl -Stop        beenden
#   tclsh TelegramMonitorCompanion.tcl -Status      nachsehen, ob er laeuft
#   tclsh TelegramMonitorCompanion.tcl -Port 9000   anderer Port
#   tclsh TelegramMonitorCompanion.tcl -Console     mit sichtbarem Fenster (Fehlersuche)

package require Tcl 8.6
package require http

# Default-Werte
set Port 8765
set Interval 120
set Stop 0
set Status 0
set Console 0
set NoBrowser 0

# Kommandozeilenargumente parsen
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch -exact -- $arg {
        -Port {
            incr i
            set Port [lindex $argv $i]
        }
        -Stop {
            set Stop 1
        }
        -Status {
            set Status 1
        }
        -Console {
            set Console 1
        }
        -NoBrowser {
            set NoBrowser 1
        }
        -Interval {
            incr i
            set Interval [lindex $argv $i]
        }
        default {
            puts "Unbekanntes Argument: $arg"
            exit 1
        }
    }
}

# Globale Variablen
set Root [file dirname [info script]]
set PidFile [file join $Root data companion.pid]
set LogFile [file join $Root data companion.log]
set Url "http://127.0.0.1:$Port"

proc Write-Step {msg} {
    puts "  $msg"
}

proc Test-Monitor {url} {
    set status 0
    if {[catch {
        set token [http::geturl ${url}/api/status -timeout 2000]
        set status [http::status $token]
        set code [http::ncode $token]
        http::cleanup $token
        if {$status eq "ok" && $code == 200} {
            return 1
        }
    } err]} {
        # Fehler beim HTTP-Request
    }
    return 0
}

proc Get-MonitorProcess {pidFile} {
    if {![file exists $pidFile]} {
        return ""
    }
    set fh [open $pidFile r]
    set id [gets $fh]
    close $fh
    if {$id eq "" || ![string is integer -strict $id]} {
        return ""
    }
    # Prüfen, ob Prozess existiert (unterstützt nur Unix/Linux hier)
    if {[catch {exec ps -p $id}]} {
        return ""
    }
    return $id
}

# ---------------------------------------------------------------- beenden ---
if {$Stop} {
    set pid [Get-MonitorProcess $PidFile]
    if {$pid ne ""} {
        if {[catch {exec kill $pid}]} {
            Write-Step "Konnte Monitor nicht beenden (PID $pid)."
        } else {
            Write-Step "Monitor beendet (PID $pid)."
        }
    } else {
        Write-Step "Es lief kein Monitor aus diesem Starter."
    }
    if {[file exists $PidFile]} {
        file delete $PidFile
    }
    exit 0
}

# ----------------------------------------------------------------- Status ---
if {$Status} {
    if {[Test-Monitor $Url]} {
        set pid [Get-MonitorProcess $PidFile]
        if {$pid ne ""} {
            Write-Step "Monitor laeuft auf $Url  (PID $pid)."
        } else {
            Write-Step "Monitor laeuft auf $Url."
        }
    } else {
        Write-Step "Auf $Url antwortet nichts."
    }
    exit 0
}

# ------------------------------------------------------------------ Start ---
puts ""
puts "  Telegram Monitor Companion"
puts "  --------------------------"

# Python suchen
set exe ""
set pre {}
foreach cand {{py {-3}} {python {}} {python3 {}}} {
    lassign $cand e a
    if {![catch {exec which $e}]} {
        set exe $e
        set pre $a
        break
    }
}
if {$exe eq ""} {
    puts ""
    puts "  Python wurde nicht gefunden."
    puts "  Herunterladen: https://www.python.org/downloads/"
    puts "  Beim Installieren \"Add python.exe to PATH\" ankreuzen."
    puts ""
    puts -nonewline "  Eingabetaste zum Schliessen"
    flush stdout
    gets stdin
    exit 1
}
Write-Step "Python: $exe [join $pre]"

if {[Test-Monitor $Url]} {
    Write-Step "Monitor laeuft bereits auf $Url — wird nicht erneut gestartet."
} else {
    # Verzeichnis für PID-Datei erstellen
    set pidDir [file dirname $PidFile]
    if {![file exists $pidDir]} {
        file mkdir $pidDir
    }

    set args [concat $pre [list server.py --port $Port --poll-interval $Interval --no-browser]]

    set pid ""
    if {$Console} {
        if {[catch {
            set pid [exec $exe {*}$args >@stdout 2>@stderr &]
        } err]} {
            puts "Fehler beim Starten des Monitors: $err"
            exit 1
        }
    } else {
        # Ohne Fenster, Ausgabe in die Protokolldatei
        if {[catch {
            set pid [exec $exe {*}$args >$LogFile 2>@stderr &]
        } err]} {
            puts "Fehler beim Starten des Monitors: $err"
            exit 1
        }
    }

    # PID speichern
    set fh [open $PidFile w]
    puts $fh $pid
    close $fh

    Write-Step "Gestartet (PID $pid), warte auf Antwort ..."

    set ok 0
    for {set i 1} {$i <= 40} {incr i} {
        after 500
        if {[Test-Monitor $Url]} {
            set ok 1
            break
        }
        # Prüfen, ob Prozess noch läuft (vereinfacht)
        if {[catch {exec ps -p $pid}]} {
            break
        }
    }

    if {!$ok} {
        puts ""
        puts "  Der Monitor hat nicht geantwortet."
        if {[file exists "${LogFile}.err"]} {
            puts "  Letzte Zeilen der Fehlerausgabe:"
            set fh [open "${LogFile}.err" r]
            set lines [split [read $fh] "\n"]
            close $fh
            set total [llength $lines]
            set start [expr {$total - 15}]
            if {$start < 0} {set start 0}
            for {set j $start} {$j < $total} {incr j} {
                puts "    [lindex $lines $j]"
            }
        }
        puts ""
        puts "  Nochmal mit sichtbarem Fenster:  tclsh TelegramMonitorCompanion.tcl -Console"
        puts -nonewline "  Eingabetaste zum Schliessen"
        flush stdout
        gets stdin
        exit 1
    }
    Write-Step "Antwortet."
}

if {$NoBrowser} {
    Write-Step "Bereit: $Url"
    exit 0
}

# Browser erkennen und starten
set edge "/usr/bin/microsoft-edge"
set chrome "/usr/bin/google-chrome"
set firefox "/usr/bin/firefox"

if {[file executable $edge]} {
    exec $edge "--app=$Url" &
    Write-Step "Als eigenes Fenster geoeffnet (Edge)."
} elseif {[file executable $chrome]} {
    exec $chrome "--app=$Url" &
    Write-Step "Als eigenes Fenster geoeffnet (Chrome)."
} elseif {[file executable $firefox]} {
    exec $firefox "--new-window" "$Url" &
    Write-Step "Als eigenes Fenster geoeffnet (Firefox)."
} else {
    # Fallback: Standardbrowser
    exec xdg-open "$Url" &
    Write-Step "Im Standardbrowser geoeffnet."
}

puts ""
puts "  Laeuft im Hintergrund auf $Url"
puts "  Beenden:  tclsh TelegramMonitorCompanion.tcl -Stop"
puts ""
