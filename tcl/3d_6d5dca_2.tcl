#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "a20fea42dc872e86c1c708b24785b7d524b69ea76c1dde0769c10718a8fa88d7", "source_sha256": "6d5dca1c8e19dae2ce42eb7176af64667ccb1401e8cd9c26f7687d201f7eeca8", "target_language": "tcl"}
# 3d.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:public/3d.html
# auch in: Projects@TikTok-Live-Companion-Android:public/3d.html
# auch in: Projects@TikTok-Live-Companion-iOS:public/3d.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:public/3d.html
# auch in: 1 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of the 3D architecture visualization
# This script generates an interactive 3D diagram using Tk canvas

package require Tk

# Configuration data
set SPEC {
    "schichten": [
        {
            "name": "Quelle",
            "farbe": "#5f6773",
            "blocks": [
                {"id": "tiktok-live-tab", "name": "TikTok-LIVE-Tab", "untertitel": "oeffentliche Seite"},
                {"id": "oeffentliche-dom-daten", "name": "oeffentliche DOM-Daten", "untertitel": "gelesen"},
                {"id": "eingebettete-metadaten", "name": "eingebettete Metadaten", "untertitel": "JSON"}
            ]
        },
        {
            "name": "Beobachtung",
            "farbe": "#2481cc",
            "blocks": [
                {"id": "content-js", "name": "content.js", "untertitel": "isolierte Welt"},
                {"id": "websocket-hook", "name": "WebSocket-Hook", "untertitel": "passiv"}
            ]
        },
        {
            "name": "Zustand",
            "farbe": "#6d5bd0",
            "blocks": [
                {"id": "background-js", "name": "background.js", "untertitel": "Filter + Zustand"},
                {"id": "storage-session", "name": "storage.session", "untertitel": "fluechtig"}
            ]
        },
        {
            "name": "Ausgabe",
            "farbe": "#fe2c55",
            "blocks": [
                {"id": "seitenpanel", "name": "Seitenpanel", "untertitel": "textContent"},
                {"id": "vorlesen", "name": "Vorlesen", "untertitel": "lokal"},
                {"id": "playersteuerung", "name": "Playersteuerung", "untertitel": "vorhandener Player"}
            ]
        },
        {
            "name": "Doku",
            "farbe": "#0f766e",
            "blocks": [
                {"id": "docs-de", "name": "docs/de", "untertitel": "deutsch"},
                {"id": "docs-en", "name": "docs/en", "untertitel": "englisch"},
                {"id": "vercel-site", "name": "Vercel-Site", "untertitel": "statisch"}
            ]
        }
    ],
    "kanten": [
        {"von": "tiktok-live-tab", "nach": "content-js", "art": "fluss"},
        {"von": "oeffentliche-dom-daten", "nach": "websocket-hook", "art": "fluss"},
        {"von": "eingebettete-metadaten", "nach": "content-js", "art": "fluss"},
        {"von": "content-js", "nach": "background-js", "art": "fluss"},
        {"von": "websocket-hook", "nach": "storage-session", "art": "fluss"},
        {"von": "background-js", "nach": "seitenpanel", "art": "fluss"},
        {"von": "storage-session", "nach": "vorlesen", "art": "fluss"},
        {"von": "seitenpanel", "nach": "docs-de", "art": "fluss"},
        {"von": "vorlesen", "nach": "docs-en", "art": "fluss"},
        {"von": "playersteuerung", "nach": "vercel-site", "art": "fluss"}
    ],
    "kantenarten": [
        {"art": "fluss", "farbe": "#fe2c55", "stil": "voll", "text": "Fluss von unten nach oben"}
    ]
}

# Create main window
wm title . "TikTok LIVE Companion — Interaktive Architektur"
wm geometry . 1200x800

# Create styles
ttk::style theme use clam

# Create main frame
set wrap [ttk::frame .wrap]
pack $wrap -fill both -expand 1 -padx 22 -pady 34

# Header
ttk::label $wrap.technik -text "Tk Canvas" -font {Arial 12 bold} -foreground #fe2c55
ttk::label $wrap.title -text "TikTok LIVE Companion" -font {Arial 24 bold} 
ttk::label $wrap.lede -text "Die Schichtsicht der Browser-Erweiterung: Quelle, Beobachtung, Zustand, Ausgabe." -font {Arial 14}

pack $wrap.technik -anchor w
pack $wrap.title -fill x -pady 10
pack $wrap.lede -fill x -pady 5

# Create main content area
set raster [ttk::frame $wrap.raster]
pack $raster -fill both -expand 1 -pady 10

# Create canvas area (simulating 3D view)
set canvas_frame [ttk::labelframe $raster.buehne -text "Architektur Diagramm" -padding 10]
set canvas [canvas $canvas_frame.canvas -width 800 -height 520 -bg #0e1420]

# Create control buttons
set knoepfe [ttk::frame $canvas_frame.knoepfe]
ttk::button $knoepfe.plus -text "+" -width 3 -command {zoom_out}
ttk::button $knoeppe.minus -text "−" -width 3 -command {zoom_in}
ttk::button $knoepfe.reset -text "Zurücksetzen" -command {reset_view}
ttk::button $knoepfe.iso -text "Iso" -state pressed

pack $knoepfe.plus $knoeppe.minus $knoepfe.reset $knoepfe.iso -side left -padx 2

# Pack canvas and controls
pack $knoepfe -side top -anchor ne
pack $canvas -fill both -expand 1 -pady 10

# Create info panel
set karte [ttk::labelframe $raster.karte -text "Ausgewählter Knoten" -padding 10 -width 288]
$karte configure -height [expr {[winfo reqheight $canvas_frame] - 20}]

ttk::label $karte.name -text "—" -font {Arial 16 bold}
ttk::label $karte.sub -text "Knoten anklicken oder durchblättern" -font {Arial 12} -foreground gray

# Info fields
set info_frame [ttk::frame $karte.info]
ttk::label $info_frame.schicht_label -text "Schicht:" -font {Arial 10 bold} -foreground gray
ttk::label $info_frame.schicht_value -text "—" -font {Arial 10 bold}
ttk::label $info_frame.id_label -text "ID:" -font {Arial 10 bold} -foreground gray
ttk::label $info_frame.id_value -text "—" -font {Arial 10 bold}

grid $info_frame.schicht_label $info_frame.schicht_value -sticky w -padx 5 -pady 2
grid $info_frame.id_label $info_frame.id_value -sticky w -padx 5 -pady 2

# Navigation buttons
set nav_frame [ttk::frame $karte.nav]
ttk::button $nav_frame.prev -text "←\nVorheriger" -command {select_prev}
ttk::button $nav_frame.next -text "Nächster\n→" -command {select_next}
pack $nav_frame.prev $nav_frame.next -side left -fill x -expand 1 -padx 5

# Legend
set legend_frame [ttk::frame $wrap.legend]
ttk::label $legend_frame.label -text "Fluss von unten nach oben" -font {Arial 11} -foreground #fe2c55

# Footer
ttk::label $wrap.footer -text "Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal." -font {Arial 10} -foreground gray

# Pack everything
pack $canvas_frame -side left -fill both -expand 1 -padx 5
pack $karte -side right -fill y -padx 5
pack $karte.name -anchor w -pady 2
pack $karte.sub -anchor w -pady 2
pack $info_frame -anchor w -pady 10
pack $nav_frame -fill x -pady 10
pack $legend_frame -anchor w -pady 10
pack $legend_frame.label -side left
pack $wrap.footer -anchor w -pady 10

# Pack raster
pack $raster -fill both -expand 1

# Data structures for our visualization
array set nodes {}
array set connections {}
set current_selection -1
set node_list {}

# Initialize the diagram
proc init_diagram {} {
    global canvas nodes connections node_list current_selection SPEC
    
    # Clear canvas
    $canvas delete all
    
    # Draw grid
    draw_grid
    
    # Parse specification and create visual elements
    set layer_y_offset 0
    set layer_height 100
    set block_width 120
    set block_height 60
    set block_spacing 20
    
    # Process layers
    set layer_index 0
    foreach layer [$SPEC get schichten] {
        set layer_name [$layer get name]
        set layer_color [$layer get farbe]
        
        # Draw layer background
        set layer_y [expr {50 + $layer_index * ($layer_height + 40)}]
        $canvas create rectangle 20 $layer_y 780 [expr {$layer_y + 30}] \
            -fill [adjust_color $layer_color 0.4] -outline "" 
        
        $canvas create text 40 [expr {$layer_y + 15}] -text $layer_name \
            -fill white -font {Arial 10 bold}
        
        # Process blocks in this layer
        set block_index 0
        foreach block [$layer get blocks] {
            set block_id [dict get $block id]
            set block_name [dict get $block name]
            set block_subtitle [dict get $block untertitel]
            
            # Calculate position
            set x [expr {50 + ($block_index % 3) * ($block_width + $block_spacing)}]
            set y [expr {$layer_y + 40}]
            
            # Create block
            set rect_id [$canvas create rectangle $x $y [expr {$x + $block_width}] [expr {$y + $block_height}] \
                -fill $layer_color -outline black -width 2]
            
            # Add label
            $canvas create text [expr {$x + $block_width/2}] [expr {$y + 20}] \
                -text $block_name -fill white -font {Arial 10 bold}
                
            if {$block_subtitle ne ""} {
                $canvas create text [expr {$x + $block_width/2}] [expr {$y + 40}] \
                    -text $block_subtitle -fill #cccccc -font {Arial 8}
            }
            
            # Store node information
            dict set nodes $rect_id [list \
                id $block_id \
                name $block_name \
                subtitle $block_subtitle \
                layer $layer_name \
                color $layer_color \
                x $x y $y]
                
            lappend node_list $rect_id
            incr block_index
        }
        
        incr layer_index
    }
    
    # Draw connections
    draw_connections
    
    # Select first node
    if {[llength $node_list] > 0} {
        select_node [lindex $node_list 0]
    }
}

# Draw grid helper
proc draw_grid {} {
    global canvas
    
    # Draw grid lines
    for {set i 0} {$i <= 800} {incr i 50} {
        $canvas create line $i 0 $i 520 -fill #25324a -dash {2 4}
    }
    for {set i 0} {$i <= 520} {incr i 50} {
        $canvas create line 0 $i 800 $i -fill #25324a -dash {2 4}
    }
}

# Draw connections between nodes
proc draw_connections {} {
    global canvas nodes connections SPEC
    
    foreach edge [$SPEC get kanten] {
        set from_id [dict get $edge von]
        set to_id [dict get $edge nach]
        
        # Find the actual canvas items for these IDs
        set from_item -1
        set to_item -1
        
        foreach item [dict keys $nodes] {
            set node_info [dict get $nodes $item]
            if {[dict get $node_info id] eq $from_id} {
                set from_item $item
            }
            if {[dict get $node_info id] eq $to_id} {
                set to_item $item
            }
        }
        
        if {$from_item != -1 && $to_item != -1} {
            set from_coords [$canvas coords $from_item]
            set to_coords [$canvas coords $to_item]
            
            # Get center points
            set from_x [expr {([lindex $from_coords 0] + [lindex $from_coords 2]) / 2}]
            set from_y [lindex $from_coords 1]  ;# Top of from block
            
            set to_x [expr {([lindex $to_coords 0] + [lindex $to_coords 2]) / 2}]
            set to_y [lindex $to_coords 3]      ;# Bottom of to block
            
            # Draw connection line
            set line_id [$canvas create line $from_x $from_y $to_x $to_y \
                -fill #fe2c55 -width 2 -arrow last]
                
            dict set connections $line_id [list from $from_item to $to_item]
        }
    }
}

# Adjust color brightness
proc adjust_color {color factor} {
    # Simple color adjustment - in real implementation would parse hex and adjust RGB values
    return $color
}

# Select a node
proc select_node {item} {
    global canvas nodes current_selection
    
    # Reset previous selection
    if {$current_selection != -1} {
        set prev_info [dict get $nodes $current_selection]
        set prev_color [dict get $prev_info color]
        $canvas itemconfigure $current_selection -width 2
    }
    
    # Highlight selected node
    $canvas itemconfigure $item -width 4 -outline white
    
    # Update info panel
    set node_info [dict get $nodes $item]
    update_info_panel $node_info
    
    set current_selection $item
}

# Update info panel with node details
proc update_info_panel {node_info} {
    global karte
    
    $karte.name configure -text [dict get $node_info name]
    $karte.sub configure -text [dict get $node_info subtitle]
    $info_frame.schicht_value configure -text [dict get $node_info layer]
    $info_frame.id_value configure -text [dict get $node_info id]
}

# Navigation functions
proc select_prev {} {
    global node_list current_selection
    
    if {[llength $node_list] == 0} return
    
    set idx [lsearch $node_list $current_selection]
    if {$idx == -1} {
        set idx 0
    } else {
        incr idx -1
        if {$idx < 0} {
            set idx [expr {[llength $node_list] - 1}]
        }
    }
    
    select_node [lindex $node_list $idx]
}

proc select_next {} {
    global node_list current_selection
    
    if {[llength $node_list] == 0} return
    
    set idx [lsearch $node_list $current_selection]
    if {$idx == -1} {
        set idx 0
    } else {
        incr idx
        if {$idx >= [llength $node_list]} {
            set idx 0
        }
    }
    
    select_node [lindex $node_list $idx]
}

# View controls
proc zoom_in {} {
    # Placeholder for zoom functionality
}

proc zoom_out {} {
    # Placeholder for zoom functionality
}

proc reset_view {} {
    # Reset view to initial state
    init_diagram
}

# Mouse event handlers
proc handle_click {x y} {
    global canvas node_list
    
    # Find clicked item
    set items [$canvas find overlapping $x $y $x $y]
    
    foreach item $items {
        if {[lsearch $node_list $item] != -1} {
            select_node $item
            break
        }
    }
}

# Bind mouse events
bind $canvas <Button-1> {handle_click %x %y}

# Initialize the application
init_diagram

# Start the event loop
tkwait window .
