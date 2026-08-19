#!/usr/bin/env tclsh
# App.css — portiert nach tcl
# Quelle: css, OpenClaw@main:src/App.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Tcl-Programm zur Erzeugung eines CSS-Dokuments aus strukturierten Daten
# Portiert von einer CSS-Datei zu Tcl-Datenstrukturen und String-Erstellung

proc create_css_document {} {
    # Definiere Root-Variablen
    set root_vars [dict create \
        color-scheme "dark" \
        font-family {Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif} \
        background "#0b1020" \
        color "#eef2ff" \
    ]

    # Sammle alle CSS-Regeln in einer Liste
    set rules [list]

    # :root Regel
    lappend rules [list ":root" $root_vars]

    # Universelle Regel
    lappend rules [list "*" [dict create box-sizing "border-box"]]

    # Body Regel
    lappend rules [list "body" [dict create \
        margin 0 \
        min-width "320px" \
        min-height "100vh" \
        background [join [list \
            "radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem)" \
            "radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem)" \
            "linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)" \
        ] ",\n    "] \
    ]]

    # Page Shell Regel
    lappend rules [list ".page-shell" [dict create \
        min-height "100vh" \
        display "grid" \
        place-items "center" \
        padding "2rem" \
    ]]

    # Hero Card Regel
    lappend rules [list ".hero-card" [dict create \
        width "min(100%, 56rem)" \
        padding "clamp(2rem, 6vw, 4.5rem)" \
        border "1px solid rgba(148, 163, 184, 0.28)" \
        border-radius "2rem" \
        background "rgba(15, 23, 42, 0.72)" \
        box-shadow "0 2rem 6rem rgba(0, 0, 0, 0.35)" \
        backdrop-filter "blur(18px)" \
    ]]

    # Eyebrow Regel
    lappend rules [list ".eyebrow" [dict create \
        margin "0 0 1rem" \
        color "#67e8f9" \
        font-size "0.8rem" \
        font-weight 700 \
        letter-spacing "0.18em" \
        text-transform "uppercase" \
    ]]

    # H1 Regel
    lappend rules [list "h1" [dict create \
        margin 0 \
        max-width "12ch" \
        font-size "clamp(2.75rem, 8vw, 6rem)" \
        line-height "0.95" \
        letter-spacing "-0.06em" \
    ]]

    # Lead Regel
    lappend rules [list ".lead" [dict create \
        margin "1.5rem 0 0" \
        max-width "42rem" \
        color "#cbd5e1" \
        font-size "clamp(1.05rem, 2vw, 1.35rem)" \
        line-height "1.65" \
    ]]

    # Link Grid Container
    lappend rules [list ".link-grid" [dict create \
        display "grid" \
        gap "0.85rem" \
        margin-top "2rem" \
    ]]

    # Link Grid Anchor Elemente
    lappend rules [list ".link-grid a" [dict create \
        display "flex" \
        align-items "center" \
        justify-content "space-between" \
        gap "1rem" \
        padding "1rem 1.15rem" \
        border "1px solid rgba(148, 163, 184, 0.25)" \
        border-radius "1rem" \
        color "#f8fafc" \
        text-decoration "none" \
        background "rgba(255, 255, 255, 0.06)" \
    ]]

    # Hover & Focus Pseudoklassen
    lappend rules [list ".link-grid a:hover,\n.link-grid a:focus-visible" [dict create \
        border-color "rgba(103, 232, 249, 0.75)" \
        outline "none" \
        background "rgba(103, 232, 249, 0.12)" \
    ]]

    return $rules
}

proc format_css_rules {rules} {
    set output ""
    
    foreach rule $rules {
        lassign $rule selector properties
        
        append output "$selector {\n"
        
        dict for {property value} $properties {
            # Behandle Spezialfälle wie font-family mit Anführungszeichen
            if {$property eq "font-family"} {
                append output "  $property: $value;\n"
            } else {
                append output "  $property: $value;\n"
            }
        }
        
        append output "}\n\n"
    }
    
    return $output
}

proc main {args} {
    if {[llength $args] != 1} {
        puts stderr "Verwendung: [info script] <ausgabedatei>"
        exit 1
    }
    
    set output_file [lindex $args 0]
    
    # Erzeuge CSS-Regeln
    set rules [create_css_document]
    
    # Formatieren zum CSS-Text
    set css_content [format_css_rules $rules]
    
    # Schreibe in Datei
    set fh [open $output_file w]
    puts -nonewline $fh $css_content
    close $fh
    
    puts "CSS erfolgreich geschrieben nach: $output_file"
}

# Wenn das Skript direkt aufgerufen wird, führe main aus
if {[info script] eq $argv0} {
    main {*}$argv
}
