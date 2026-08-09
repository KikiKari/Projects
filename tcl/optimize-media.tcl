#!/usr/bin/env tclsh
# optimize-media.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require fileutil
package require img::png
package require img::jpeg

# Funktion zur Konvertierung von PNG nach WebP und AVIF
# Da Tcl keine direkten Bibliotheken für WebP/AVIF hat, verwenden wir externe Tools
proc convert_image {source_file target_file format quality} {
    # Prüfen ob cwebp (für WebP) oder avifenc (für AVIF) verfügbar ist
    if {$format eq "webp"} {
        if {[catch {exec cwebp -quiet -q $quality $source_file -o $target_file}]} {
            error "Konvertierung nach WebP fehlgeschlagen"
        }
    } elseif {$format eq "avif"} {
        if {[catch {exec avifenc --quiet --quality $quality $source_file -o $target_file}]} {
            error "Konvertierung nach AVIF fehlgeschlagen"
        }
    }
}

# Hauptverzeichnis festlegen
set directory [file normalize [file join [file dirname [info script]] ".." "public" "media"]]

# Alle Dateien im Verzeichnis durchlaufen
foreach file [glob -nocomplain -directory $directory "*.png"] {
    set basename [file rootname [file tail $file]]
    set webp_file [file join $directory "${basename}.webp"]
    set avif_file [file join $directory "${basename}.avif"]
    
    # Konvertierung zu WebP
    if {[catch {convert_image $file $webp_file "webp" 84} err]} {
        puts stderr "Fehler bei WebP-Konvertierung von $file: $err"
    }
    
    # Konvertierung zu AVIF
    if {[catch {convert_image $file $avif_file "avif" 58} err]} {
        puts stderr "Fehler bei AVIF-Konvertierung von $file: $err"
    }
}

puts "WebP- und AVIF-Derivate erzeugt."
