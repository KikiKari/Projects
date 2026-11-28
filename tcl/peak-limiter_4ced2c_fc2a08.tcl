#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "88f566aa8297d6e86aa92f2432e6f558354daef9b6675f26e43d4246b86ed0cc", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "tcl"}
# peak-limiter_4ced2c.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "tcl"}
# peak-limiter.html — portiert nach css
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

proc generate_css {} {
    set css ""

    # body styles
    append css "body {\n"
    append css "  font: 16px system-ui;\n"
    append css "  max-width: 1000px;\n"
    append css "  margin: 40px auto;\n"
    append css "  padding: 20px;\n"
    append css "}\n\n"

    # pre styles
    append css "pre {\n"
    append css "  white-space: pre-wrap;\n"
    append css "}\n\n"

    # button styles
    append css "button {\n"
    append css "  padding: 12px;\n"
    append css "}\n"

    return $css
}

proc write_css_to_file {filename} {
    set css [generate_css]
    set fh [open $filename w]
    puts $fh $css
    close $fh
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css_to_file $output_file
