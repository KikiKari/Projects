#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "2391c803dbd0bb33ff61ee75a809a0867e5bf83b9742ffa2a2a345509f72c9a4", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "tcl"}
# frame.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc usage {} {
    puts stderr {Usage:
  frame.tcl <video-file> \[--time HH:MM:SS\] \[--index N\] --out /path/to/frame.jpg

Examples:
  frame.tcl video.mp4 --out /tmp/frame.jpg
  frame.tcl video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.tcl video.mp4 --index 0 --out /tmp/frame0.png}
    exit 2
}

# Prüfe auf Hilfe-Argumente oder leeres erstes Argument
if {$argc == 0 || [lindex $argv 0] eq "-h" || [lindex $argv 0] eq "--help"} {
    usage
}

set in [lindex $argv 0]
set argv [lrange $argv 1 end]

set time ""
set index ""
set out ""

# Parse command line arguments
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --time {
            incr i
            if {$i >= [llength $argv]} {
                puts stderr "Missing value for --time"
                usage
            }
            set time [lindex $argv $i]
        }
        --index {
            incr i
            if {$i >= [llength $argv]} {
                puts stderr "Missing value for --index"
                usage
            }
            set index [lindex $argv $i]
        }
        --out {
            incr i
            if {$i >= [llength $argv]} {
                puts stderr "Missing value for --out"
                usage
            }
            set out [lindex $argv $i]
        }
        default {
            puts stderr "Unknown arg: $arg"
            usage
        }
    }
}

# Prüfe ob Eingabedatei existiert
if {![file exists $in]} {
    puts stderr "File not found: $in"
    exit 1
}

# Prüfe ob Ausgabepfad angegeben wurde
if {$out eq ""} {
    puts stderr "Missing --out"
    usage
}

# Erstelle Zielverzeichnis
set outdir [file dirname $out]
if {![file exists $outdir]} {
    file mkdir $outdir
}

# Führe ffmpeg-Befehl entsprechend den Optionen aus
if {$index ne ""} {
    # Extrahiere Frame bei spezifischem Index
    exec ffmpeg -hide_banner -loglevel error -y \
        -i $in \
        -vf "select=eq(n\\,$index)" \
        -vframes 1 \
        $out
} elseif {$time ne ""} {
    # Extrahiere Frame zu bestimmtem Zeitpunkt
    exec ffmpeg -hide_banner -loglevel error -y \
        -ss $time \
        -i $in \
        -frames:v 1 \
        $out
} else {
    # Extrahiere ersten Frame (Standardfall)
    exec ffmpeg -hide_banner -loglevel error -y \
        -i $in \
        -vf "select=eq(n\\,0)" \
        -vframes 1 \
        $out
}

puts $out
