#!/usr/bin/env tclsh
# 3d_053a4a.py — portiert nach tcl
# Quelle: python, Projects@abstractions:python/3d_053a4a.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of 3d.html — portiert nach Tcl 8.6
# Quelle: html, Projects@python-hardener:public/3d.html
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# This script creates a 3D visualization using Tk canvas for Python Hardener architecture

package require Tk

# Create the main window
wm title . "Python Hardener — Interaktive Architektur"
wm geometry . 1200x800

# Create main frame
ttk::frame .main
pack .main -fill both -expand 1

# Create toolbar
ttk::frame .toolbar
pack .toolbar -fill x -padx 10 -pady 5

ttk::button .toolbar.plus -text "+" -command {zoom 0.85}
ttk::button .toolbar.minus -text "-" -command {zoom 1.18}
ttk::button .toolbar.reset -text "Zurücksetzen" -command reset_view
ttk::button .toolbar.iso -text "Iso" -command toggle_projection

pack .toolbar.plus .toolbar.minus .toolbar.reset .toolbar.iso -side left -padx 2

# Create canvas for 3D visualization
canvas .c -width 800 -height 600 -bg #0e1420
pack .c -fill both -expand 1 -padx 10 -pady 5

# Create info panel
ttk::frame .info
pack .info -fill x -padx 10 -pady 5

ttk::label .info.title -text "Ausgewählter Knoten" -font "Helvetica 10 bold"
ttk::label .info.name -text "—" -font "Helvetica 12 bold"
ttk::label .info.subtitle -text "Knoten anklicken oder durchblättern" -font "Helvetica 10"
ttk::label .info.layer_label -text "Schicht:" -font "Helvetica 9"
ttk::label .info.layer -text "—" -font "Helvetica 9 bold"
ttk::label .info.id_label -text "ID:" -font "Helvetica 9"
ttk::label .info.id -text "—" -font "Helvetica 9 bold"

pack .info.title -anchor w
pack .info.name -anchor w
pack .info.subtitle -anchor w
pack .info.layer_label .info.layer -anchor w -side left
pack .info.id_label .info.id -anchor w -side left -padx {10 0}

# Create navigation buttons
ttk::frame .nav
pack .nav -fill x -padx 10 -pady 5

ttk::button .nav.prev -text "←\nVorheriger" -command {select_node -1}
ttk::button .nav.next -text "Nächster\n→" -command {select_node 1}

pack .nav.prev .nav.next -side left -fill x -expand 1 -padx 2

# Legend frame
ttk::frame .legend
pack .legend -fill x -padx 10 -pady 5

ttk::label .legend.title -text "Legende:" -font "Helvetica 10 bold"
pack .legend.title -side left

# Data structure for the architecture
set spec {
    schichten {
        {name "Eingaben" farbe "#5f6773" blocks {
            {id "job-runner-py" name "job_runner.py" untertitel "Cronjob"}
            {id "report-db-py" name "report_db.py" untertitel "SQL"}
        }}
        {name "Laeufe" farbe "#2481cc" blocks {
            {id "with-skill" name "with_skill" untertitel "mit Skill"}
            {id "without-skill" name "without_skill" untertitel "Gegenprobe"}
        }}
        {name "Pruefung" farbe "#6d5bd0" blocks {
            {id "ast-assertions" name "AST-Assertions" untertitel "Syntaxbaum"}
            {id "not-contains" name "not_contains" untertitel "Textregel"}
            {id "grading" name "Grading" untertitel "je Behauptung"}
        }}
        {name "Ergebnis" farbe "#b45309" blocks {
            {id "benchmark-json" name "benchmark.json" untertitel "pass_rate"}
            {id "timing-json" name "timing.json" untertitel "Laufzeit"}
            {id "eval-review-html" name "eval-review.html" untertitel "Gegenueberstellung"}
        }}
    }
    kanten {
        {von "job-runner-py" nach "with-skill" art "fluss"}
        {von "report-db-py" nach "without-skill" art "fluss"}
        {von "with-skill" nach "ast-assertions" art "fluss"}
        {von "without-skill" nach "not-contains" art "fluss"}
        {von "ast-assertions" nach "benchmark-json" art "fluss"}
        {von "not-contains" nach "timing-json" art "fluss"}
        {von "grading" nach "eval-review-html" art "fluss"}
    }
    kantenarten {
        {art "fluss" farbe "#b45309" stil "voll" text "Fluss von unten nach oben"}
    }
}

# Global variables for 3D view
set nodes {}
set connections {}
set selected_node -1
set camera_x 0
set camera_y 0
set camera_z 100
set zoom_factor 1.0
set isometric 1

# Initialize the 3D visualization
proc init_3d_view {} {
    global spec nodes connections
    
    # Clear canvas
    .c delete all
    
    # Draw grid
    draw_grid
    
    # Create nodes from spec
    set y_offset 0
    set layer_height 100
    set node_width 80
    set node_height 40
    
    foreach layer [$spec schichten] {
        set layer_name [dict get $layer dict name]
        set layer_color [dict get $layer dict farbe]
        set blocks [dict get $layer dict blocks]
        
        set x_offset 100
        foreach block $blocks {
            set id [dict get $block dict id]
            set name [dict get $block dict name]
            set subtitle [dict get $block dict untertitel]
            
            # Draw node
            set x [expr {$x_offset + 50}]
            set y [expr {150 + $y_offset}]
            set rect [.c create rectangle [expr {$x - $node_width/2}] [expr {$y - $node_height/2}] \
                     [expr {$x + $node_width/2}] [expr {$y + $node_height/2}] \
                     -fill $layer_color -outline #0e1420 -width 2]
            
            # Draw text
            .c create text $x $y -text $name -fill white -font "Helvetica 10 bold"
            if {$subtitle ne ""} {
                .c create text $x [expr {$y + 15}] -text $subtitle -fill #cccccc -font "Helvetica 8"
            }
            
            # Store node info
            lappend nodes [list $id $name $subtitle $layer_name $rect $x $y]
            
            set x_offset [expr {$x_offset + 120}]
        }
        
        set y_offset [expr {$y_offset + $layer_height}]
    }
    
    # Draw connections
    foreach edge [$spec kanten] {
        set from_id [dict get $edge dict von]
        set to_id [dict get $edge dict nach]
        
        # Find nodes
        set from_node {}
        set to_node {}
        foreach node $nodes {
            if {[lindex $node 0] eq $from_id} {
                set from_node $node
            }
            if {[lindex $node 0] eq $to_id} {
                set to_node $node
            }
        }
        
        if {$from_node ne {} && $to_node ne {}} {
            set from_x [lindex $from_node 5]
            set from_y [lindex $from_node 6]
            set to_x [lindex $to_node 5]
            set to_y [lindex $to_node 6]
            
            # Draw connection line
            .c create line $from_x $from_y $to_x $to_y -fill #b45309 -width 2 -arrow last
        }
    }
    
    # Select first node
    if {[llength $nodes] > 0} {
        select_node_index 0
    }
}

# Draw grid background
proc draw_grid {} {
    for {set i 0} {$i < 800} {incr i 50} {
        .c create line $i 0 $i 600 -fill #25324a -dash {2 4}
        .c create line 0 $i 800 $i -fill #25324a -dash {2 4}
    }
}

# Select node by index
proc select_node_index {index} {
    global nodes selected_node
    
    if {$index < 0} {
        set index [expr {[llength $nodes] - 1}]
    } elseif {$index >= [llength $nodes]} {
        set index 0
    }
    
    # Deselect previous node
    if {$selected_node >= 0 && $selected_node < [llength $nodes]} {
        set prev_node [lindex $nodes $selected_node]
        set rect_id [lindex $prev_node 4]
        .c itemconfig $rect_id -width 2
    }
    
    set selected_node $index
    
    # Select new node
    if {$selected_node >= 0 && $selected_node < [llength $nodes]} {
        set node [lindex $nodes $selected_node]
        set rect_id [lindex $node 4]
        .c itemconfig $rect_id -width 4 -outline white
        
        # Update info panel
        .info.name configure -text [lindex $node 1]
        .info.subtitle configure -text [lindex $node 2]
        .info.layer configure -text [lindex $node 3]
        .info.id configure -text [lindex $node 0]
    }
}

# Select next/previous node
proc select_node {direction} {
    global selected_node
    select_node_index [expr {$selected_node + $direction}]
}

# Zoom function
proc zoom {factor} {
    global zoom_factor
    set zoom_factor [expr {$zoom_factor * $factor}]
    # In a real implementation, this would redraw the scene with scaling
}

# Reset view
proc reset_view {} {
    global zoom_factor isometric
    set zoom_factor 1.0
    set isometric 1
    .toolbar.iso configure -text "Iso"
    init_3d_view
}

# Toggle projection
proc toggle_projection {} {
    global isometric
    set isometric [expr {!$isometric}]
    if {$isometric} {
        .toolbar.iso configure -text "Iso"
    } else {
        .toolbar.iso configure -text "Persp"
    }
    # In a real implementation, this would switch between projections
}

# Initialize the application
init_3d_view

# Add legend items
foreach art [$spec kantenarten] {
    set color [dict get $art dict farbe]
    set text [dict get $art dict text]
    
    ttk::frame .legend.item[llength [.legend children]]
    .legend.item[expr {[llength [.legend children]] - 1}] configure -height 20
    
    canvas .legend.item[expr {[llength [.legend children]] - 1}].line -width 30 -height 10 -bg #0f1115 -highlightthickness 0
    .legend.item[expr {[llength [.legend children]] - 1}].line create line 5 5 25 5 -fill $color -width 3
    
    ttk::label .legend.item[expr {[llength [.legend children]] - 1}].text -text $text -font "Helvetica 9"
    
    pack .legend.item[expr {[llength [.legend children]] - 1}].line .legend.item[expr {[llength [.legend children]] - 1}].text -side left
    pack .legend.item[expr {[llength [.legend children]] - 1}] -side left -padx 5
}

# Add footer
ttk::label .footer -text "Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal." -font "Helvetica 8" -foreground gray
pack .footer -fill x -padx 10 -pady {10 0}

# Event bindings for canvas interaction would go here in a full implementation

# Start the Tk event loop
tkwait window .
