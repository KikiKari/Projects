#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "6cb83c2d9d42b5253c3836425fac2e66de07ff7bdc7e896f5148411b190ec278", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc generateHTML { filename } {
    set htmlContent {}

    append htmlContent "<!DOCTYPE html>\n"
    append htmlContent "<html lang=\"de\">\n"
    append htmlContent "<head>\n"
    append htmlContent "<meta charset=\"utf-8\">\n"
    append htmlContent "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
    append htmlContent "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">\n"
    append htmlContent "<title>Weiterleitung zur 3D-Ansicht</title>\n"
    append htmlContent "<link rel=\"canonical\" href=\"3d.html\">\n"
    append htmlContent "<script>location.replace('3d.html');</script>\n"
    append htmlContent "</head>\n"
    append htmlContent "<body>\n"
    append htmlContent "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>\n"
    append htmlContent "</body>\n"
    append htmlContent "</html>\n"

    set fileHandle [open $filename w]
    puts -nonewline $fileHandle $htmlContent
    close $fileHandle
}

if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set outputFile [lindex $argv 0]
generateHTML $outputFile
