#!/usr/bin/env tclsh8.6
# build_artifact.py — portiert nach tcl
# Quelle: python, Projects@Telegram-Monitor:build_artifact.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Baut aus web/artifact_template.html + data/latest.json die fertige
# Uebersichtsseite telegram-monitor-uebersicht.html (eine Datei, offline nutzbar).
#
#   python cli.py scan --json > /tmp/scan.json     # optional: frische Daten
#   tclsh build_artifact.tcl

package require json

set ROOT [file dirname [file normalize $argv0]]
set TEMPLATE [file join $ROOT "web" "artifact_template.html"]
set DATA [file join $ROOT "data" "latest.json"]
set OUT [file join [file dirname $ROOT] "telegram-monitor-uebersicht.html"]

proc build {{data_path ""} {out_path ""}} {
    global TEMPLATE DATA OUT
    
    if {$data_path eq ""} {
        set data_path $DATA
    }
    if {$out_path eq ""} {
        set out_path $OUT
    }
    
    set fh [open $TEMPLATE r]
    set tpl [read $fh]
    close $fh
    
    set fh [open $data_path r]
    set json_data [read $fh]
    close $fh
    
    set data [::json::json2dict $json_data]
    set payload [string map [list "</" "<\\/"] [::json::write object {*}$data]]
    
    set html [string map [list "/*__DATA__*/{}" $payload] $tpl]
    
    set fh [open $out_path w]
    puts -nonewline $fh $html
    close $fh
    
    return $out_path
}

if {[info script] eq $argv0} {
    set data_arg $DATA
    if {$argc > 0} {
        set data_arg [lindex $argv 0]
    }
    set path [build $data_arg]
    set size [file size $path]
    puts "geschrieben: $path ($size Bytes)"
}
