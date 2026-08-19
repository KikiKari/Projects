#!/usr/bin/env tclsh
# serve_compare_transfer.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

set compareDir "/home/openclaw/.openclaw/workspace/vscode/compare"
set transferDir "/home/openclaw/.openclaw/workspace/vscode/compare/transfer"
set hostIP "152.53.145.65"
set port "80"
set selfPath [file normalize $argv0]

# Finde alle Dateien im Vergleichsverzeichnis außer diesem Skript
set files {}
set dirEntries [glob -nocomplain -dir $compareDir *]
foreach entry $dirEntries {
    if {[file isfile $entry] && ($entry ne $selfPath)} {
        lappend files $entry
    }
}

# Sortiere die Dateien alphabetisch
set files [lsort $files]

if {[llength $files] == 0} {
    puts "Keine Dateien in $compareDir gefunden."
    exit 1
}

puts ""
puts "Bereitgestellte Dateien aus $compareDir:"
foreach src $files {
    puts "- [file tail $src]"
}

puts ""
puts "Copy/Paste auf anderem Gateway (Download nach $transferDir):"
foreach src $files {
    set file [file tail $src]
    puts "curl -fL --retry 3 --connect-timeout 10 -o $transferDir/$file http://$hostIP:$port/$file"
}

puts ""
puts "Server auf Port $port aktiv. Beenden mit STRG+C."
puts ""

# Wechsle ins Vergleichsverzeichnis und starte HTTP-Server
cd $compareDir

# Erstelle einen einfachen HTTP-Server
proc handleRequest {sock addr port} {
    if {[catch {gets $sock request} line]} {
        close $sock
        return
    }
    
    # Parse die Anfragezeile
    if {[regexp {GET /([^ ]*)} $line -> filename]} {
        set filepath [file join [pwd] $filename]
        
        # Prüfe ob Datei existiert und ist lesbar
        if {[file exists $filepath] && [file readable $filepath] && [file isfile $filepath]} {
            if {[catch {open $filepath r} fd]} {
                puts $sock "HTTP/1.0 403 Forbidden"
                puts $sock "Content-Type: text/plain"
                puts $sock ""
                puts $sock "403 Forbidden"
                flush $sock
                close $sock
                return
            }
            
            # Bestimme den Content-Type
            set ext [string tolower [file extension $filepath]]
            switch $ext {
                .html - .htm {
                    set contentType "text/html"
                }
                .css {
                    set contentType "text/css"
                }
                .js {
                    set contentType "application/javascript"
                }
                .json {
                    set contentType "application/json"
                }
                .png {
                    set contentType "image/png"
                }
                .jpg - .jpeg {
                    set contentType "image/jpeg"
                }
                .gif {
                    set contentType "image/gif"
                }
                default {
                    set contentType "application/octet-stream"
                }
            }
            
            # Lese die Dateigröße
            set filesize [file size $filepath]
            
            # Sende HTTP-Header
            puts $sock "HTTP/1.0 200 OK"
            puts $sock "Content-Type: $contentType"
            puts $sock "Content-Length: $filesize"
            puts $sock ""
            flush $sock
            
            # Sende den Dateiinhalt
            if {$ext eq ".png" || $ext eq ".jpg" || $ext eq ".jpeg" || $ext eq ".gif"} {
                # Für Binärdateien
                close $fd
                set fd [open $filepath rb]
                fconfigure $sock -translation binary
                fconfigure $fd -translation binary
                set data [read $fd]
                puts -nonewline $sock $data
            } else {
                # Für Textdateien
                while {[gets $fd line] >= 0} {
                    puts $sock $line
                }
            }
            flush $sock
            close $fd
        } else {
            puts $sock "HTTP/1.0 404 Not Found"
            puts $sock "Content-Type: text/plain"
            puts $sock ""
            puts $sock "404 Not Found"
            flush $sock
        }
    } else {
        puts $sock "HTTP/1.0 400 Bad Request"
        puts $sock "Content-Type: text/plain"
        puts $sock ""
        puts $sock "400 Bad Request"
        flush $sock
    }
    
    close $sock
}

# Starte den Server
if {[catch {socket -server handleRequest $port 0.0.0.0} serverSocket]} {
    puts "Fehler beim Starten des Servers: $serverSocket"
    exit 1
}

puts "HTTP-Server läuft auf 0.0.0.0:$port"

# Warte auf eingehende Verbindungen
vwait forever
