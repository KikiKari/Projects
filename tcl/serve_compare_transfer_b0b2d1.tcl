#!/usr/bin/env tclsh8.6
# serve_compare_transfer.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

package require http

set COMPARE_DIR "/home/openclaw/.openclaw/workspace/vscode/compare"
set TRANSFER_DIR "/home/openclaw/.openclaw/workspace/vscode/compare/transfer"
set HOST_IP "89.58.15.220"
set PORT "80"
set SELF_PATH [file normalize $argv0]

# Finde alle Dateien im Verzeichnis (ohne Unterverzeichnisse)
set FILES {}
set dirHandle [glob -nocomplain -directory $COMPARE_DIR -types f *]
foreach src $dirHandle {
    if {$src ne $SELF_PATH} {
        lappend FILES $src
    }
}

# Sortiere die Dateien
set FILES [lsort $FILES]

if {[llength $FILES] == 0} {
    puts "Keine Dateien in $COMPARE_DIR gefunden."
    exit 1
}

puts ""
puts "Bereitgestellte Dateien aus $COMPARE_DIR:"
foreach src $FILES {
    puts "- [file tail $src]"
}

puts ""
puts "Copy/Paste auf anderem Gateway (Download nach $TRANSFER_DIR):"
foreach src $FILES {
    set file [file tail $src]
    puts "curl -fL --retry 3 --connect-timeout 10 -o $TRANSFER_DIR/$file http://$HOST_IP:$PORT/$file"
}

puts ""
puts "Server auf Port $PORT aktiv. Beenden mit STRG+C."
puts ""

# Wechsle ins Verzeichnis und starte HTTP-Server
cd $COMPARE_DIR

# Einfacher HTTP-Server in Tcl
proc handle_request {sock addr port} {
    global COMPARE_DIR
    set request [gets $sock]
    if {[regexp {GET /([^ ]+)} $request -> filename]} {
        set filepath [file join $COMPARE_DIR $filename]
        if {[file exists $filepath] && [file isfile $filepath]} {
            set fp [open $filepath r]
            fconfigure $fp -translation binary
            set data [read $fp]
            close $fp
            
            puts $sock "HTTP/1.1 200 OK"
            puts $sock "Content-Length: [string length $data]"
            puts $sock "Content-Type: application/octet-stream"
            puts $sock ""
            puts -nonewline $sock $data
        } else {
            puts $sock "HTTP/1.1 404 Not Found"
            puts $sock "Content-Length: 0"
            puts $sock ""
        }
    } else {
        puts $sock "HTTP/1.1 400 Bad Request"
        puts $sock "Content-Length: 0"
        puts $sock ""
    }
    flush $sock
    close $sock
}

# Starte Server
socket -server handle_request $PORT
vwait forever
