#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "223db990475980e1997deca16c3e926cb60ce6bc252db083a7f8d3441b350043", "source_sha256": "1af3533731f49a592a9bf1403bd2219e023d0d8fc974ae8ed0223565071239ed", "target_language": "tcl"}
# 3d.html — portiert nach tcl
# Quelle: html, Projects@MCP-Server-Monitor:public/3d.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of the 3D MCP Server Monitor visualization
# This script generates an interactive 3D visualization using Tk canvas

package require Tk

# Configuration data structure
array set SPEC {
    schichten {
        {name "Quellen" farbe "#5f6773" blocks {
            {id "mcp-domain" name "mcp.DOMAIN" untertitel "Streamable HTTP"}
            {id "docs-mcp" name "docs/mcp" untertitel "Anbieterdoku"}
            {id "well-known" name ".well-known" untertitel "OAuth-Metadaten"}
            {id "config-json" name "config.json" untertitel "claude_desktop_config"}
        }}
        {name "Sonde" farbe "#2481cc" blocks {
            {id "discovery-py" name "discovery.py" untertitel "sechs Pfade"}
            {id "config-py" name "config.py" untertitel "MSIX-Falle"}
        }}
        {name "Klassifikation" farbe "#6d5bd0" blocks {
            {id "state-py" name "state.py" untertitel "fuenf Zustaende"}
        }}
        {name "Ausgabe" farbe "#15803d" blocks {
            {id "report-py" name "report.py" untertitel "Textausgabe"}
            {id "server-py" name "server.py" untertitel "127.0.0.1"}
            {id "index-html" name "index.html" untertitel "statische Seite"}
        }}
    }
    kanten {
        {von "mcp-domain" nach "discovery-py" art "fluss"}
        {von "docs-mcp" nach "config-py" art "fluss"}
        {von "well-known" nach "discovery-py" art "fluss"}
        {von "config-json" nach "config-py" art "fluss"}
        {von "discovery-py" nach "state-py" art "fluss"}
        {von "config-py" nach "state-py" art "fluss"}
        {von "state-py" nach "report-py" art "fluss"}
    }
    kantenarten {
        {art "fluss" farbe "#6d5bd0" stil "voll" text "Fluss von unten nach oben"}
    }
}

# Global variables for 3D simulation
set D 26
set radius 82
set aspekt 1
set iso 1
set azimut [expr {3.14159/4}]
set elevation 0.62
set rotiert 1
set zoom_factor 1.0

# Camera settings
set camera_x 0
set camera_y 0
set camera_z 0

# Node selection tracking
set selected_node -1
set nodes {}
set node_by_id {}
set clickable_items {}

# Create main window
wm title . "MCP-Server-Monitor"
wm geometry . 1200x800

# Create main frame structure
frame .header -bg #fbfaf7
frame .content -bg #fbfaf7
frame .footer -bg #fbfaf7

pack .header -fill x -padx 10 -pady 5
pack .content -fill both -expand 1 -padx 10 -pady 5
pack .footer -fill x -padx 10 -pady 5

# Header elements
label .header.tech -text "Tk Canvas · Simulation" -font {Arial 10 bold} -fg #6d5bd0 -bg #fbfaf7
label .header.title -text "MCP-Server-Monitor" -font {Arial 24 bold} -bg #fbfaf7
label .header.desc -text "Warum fehlen die Tools? Vier Schichten von der Netz-Sonde bis zur Ausgabe — drehen, zoomen, Knoten auswählen." \
    -font {Arial 12} -fg #5f6773 -bg #fbfaf7 -wraplength 800

pack .header.tech -anchor w
pack .header.title -anchor w -pady 5
pack .header.desc -anchor w

# Main content area with canvas and sidebar
frame .content.main -bg #fbfaf7
frame .content.sidebar -bg #ffffff -relief solid -bd 1

pack .content.main -side left -fill both -expand 1 -padx {0 5}
pack .content.sidebar -side right -fill y -ipadx 10 -ipady 10

# Canvas for 3D visualization
canvas .content.main.canvas -width 800 -height 520 -bg #0e1420 -relief solid -bd 1
pack .content.main.canvas -fill both -expand 1

# Control buttons
frame .content.main.controls -bg #0e1420
pack .content.main.controls -side top -anchor ne -padx 5 -pady 5

button .content.main.controls.plus -text "+" -command {zoom 0.85} -width 3
button .content.main.controls.minus -text "−" -command {zoom 1.18} -width 3
button .content.main.controls.reset -text "Zurücksetzen" -command reset_view
button .content.main.controls.iso -text "Iso" -command toggle_projection -width 6

pack .content.main.controls.plus -side left -padx 2
pack .content.main.controls.minus -side left -padx 2
pack .content.main.controls.reset -side left -padx 2
pack .content.main.controls.iso -side left -padx 2

# Sidebar content
label .content.sidebar.title -text "AUSGEWÄHLTER KNOTEN" -font {Arial 8 bold} -fg #5f6773
label .content.sidebar.name -text "—" -font {Arial 16 bold} -anchor w
label .content.sidebar.sub -text "Knoten anklicken oder durchblättern" -font {Arial 10} -fg #5f6773 -anchor w

frame .content.sidebar.layer_frame
label .content.sidebar.layer_frame.label -text "SCHICHT" -font {Arial 8 bold} -fg #5f6773
label .content.sidebar.layer_frame.value -text "—" -font {Arial 10 bold} -anchor w
pack .content.sidebar.layer_frame.label -side left
pack .content.sidebar.layer_frame.value -side right -expand 1

frame .content.sidebar.id_frame
label .content.sidebar.id_frame.label -text "ID" -font {Arial 8 bold} -fg #5f6773
label .content.sidebar.id_frame.value -text "—" -font {Arial 10 bold} -anchor w
pack .content.sidebar.id_frame.label -side left
pack .content.sidebar.id_frame.value -side right -expand 1

frame .content.sidebar.nav
button .content.sidebar.nav.prev -text "←\nVorheriger" -command {select_node [expr {$selected_node - 1}]}
button .content.sidebar.nav.next -text "Nächster\n→" -command {select_node [expr {$selected_node + 1}]}
pack .content.sidebar.nav.prev -side left -expand 1 -fill x -padx 2
pack .content.sidebar.nav.next -side right -expand 1 -fill x -padx 2

pack .content.sidebar.title -anchor w -pady {0 5}
pack .content.sidebar.name -anchor w -pady 2
pack .content.sidebar.sub -anchor w -pady {0 10}
pack .content.sidebar.layer_frame -fill x -pady 2
pack .content.sidebar.id_frame -fill x -pady 2
pack .content.sidebar.nav -pady {10 0}

# Legend
frame .footer.legend -bg #fbfaf7
label .footer.legend.label -text "Fluss von unten nach oben" -font {Arial 10} -fg #5f6773
frame .footer.legend.line -width 30 -height 3 -bg #6d5bd0

pack .footer.legend.line -side left -padx {0 5}
pack .footer.legend.label -side left

pack .footer.legend -anchor w

# Footer note
label .footer.note -text "Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal." \
    -font {Arial 9} -fg #5f6773 -wraplength 1000 -justify left
pack .footer.note -anchor w -pady {5 0}

# 3D rendering functions
proc project_point {x y z} {
    global camera_x camera_y camera_z D aspekt iso
    
    # Simple orthographic projection for demonstration
    set scale [expr {$iso ? 8.0 : 5.0}]
    set px [expr {($x - $camera_x) * $scale}]
    set py [expr {($y - $camera_y) * $scale}]
    set pz [expr {($z - $camera_z) * $scale}]
    
    # Convert to screen coordinates (centered)
    set canvas_width [.content.main.canvas cget -width]
    set canvas_height [.content.main.canvas cget -height]
    
    set screen_x [expr {$canvas_width/2 + $px}]
    set screen_y [expr {$canvas_height/2 - $pz}]  ;# Note: y increases downward in canvas
    
    return [list $screen_x $screen_y]
}

proc draw_3d_box {x y z width height depth color} {
    global nodes
    
    # Project corners
    set corners {}
    foreach dx {-1 1} {
        foreach dy {-1 1} {
            foreach dz {-1 1} {
                set px [expr {$x + $dx * $width/2}]
                set py [expr {$y + $dy * $height/2}]
                set pz [expr {$z + $dz * $depth/2}]
                lappend corners [project_point $px $py $pz]
            }
        }
    }
    
    # Draw visible faces (simplified)
    set coords {}
    foreach {x1 y1} [lindex $corners 0] break
    foreach {x2 y2} [lindex $corners 1] break
    foreach {x3 y3} [lindex $corners 3] break
    foreach {x4 y4} [lindex $corners 2] break
    
    # Front face
    set item [.content.main.canvas create polygon $x1 $y1 $x2 $y2 $x4 $y4 $x3 $y3 \
              -fill $color -outline #0e1420 -width 1]
    
    return $item
}

proc draw_3d_text {x y z text {subtitle ""}} {
    set coords [project_point $x $y $z]
    foreach {sx sy} $coords break
    
    set item [.content.main.canvas create text $sx $sy -text $text -fill white -font {Arial 10 bold}]
    
    if {$subtitle != ""} {
        .content.main.canvas create text $sx [expr {$sy + 15}] -text $subtitle -fill #cccccc -font {Arial 8}
    }
    
    return $item
}

proc update_camera {} {
    global azimut elevation radius camera_x camera_y camera_z
    
    set camera_x [expr {$radius * cos($elevation) * sin($azimut)}]
    set camera_y [expr {$radius * sin($elevation)}]
    set camera_z [expr {$radius * cos($elevation) * cos($azimut)}]
}

proc render_scene {} {
    .content.main.canvas delete all
    
    # Draw grid
    for {set i -5} {$i <= 5} {incr i} {
        set start [project_point [expr {$i * 10}] -24 [expr {-5 * 10}]]
        set end [project_point [expr {$i * 10}] -24 [expr {5 * 10}]]
        .content.main.canvas create line [lindex $start 0] [lindex $start 1] [lindex $end 0] [lindex $end 1] \
            -fill #25324a
        
        set start [project_point [expr {-5 * 10}] -24 [expr {$i * 10}]]
        set end [project_point [expr {5 * 10}] -24 [expr {$i * 10}]]
        .content.main.canvas create line [lindex $start 0] [lindex $start 1] [lindex $end 0] [lindex $end 1] \
            -fill #1a2333
    }
    
    # Draw nodes
    global nodes selected_node clickable_items
    set clickable_items {}
    
    set node_index 0
    foreach node $nodes {
        array set n $node
        set item [draw_3d_box $n(x) $n(y) $n(z) 7.4 1.7 4.2 $n(color)]
        draw_3d_text $n(x) [expr {$n(y) + 2}] $n(z) $n(name) $n(untertitel)
        
        # Store reference for click detection
        lappend clickable_items [list $item $node_index]
        incr node_index
    }
    
    # Highlight selected node
    if {$selected_node >= 0 && $selected_node < [llength $nodes]} {
        array set sel_node [lindex $nodes $selected_node]
        # Could add highlighting here
    }
}

proc build_scene {} {
    global SPEC nodes node_by_id
    
    set BW 7.4
    set BD 4.2
    set BH 1.7
    set LUFT 1.3
    set ABSTAND 11.4
    set START -17
    
    set layer_index 0
    foreach layer $SPEC(schichten) {
        array set l $layer
        set y [expr {$START + $layer_index * $ABSTAND}]
        
        set block_count [llength $l(blocks)]
        set spalten [expr {max(1, int(ceil($block_count / 2.0)))}]
        set reihen [expr {$block_count <= 1 ? 1 : 2}]
        set gx [expr {$spalten*$BW + ($spalten-1)*$LUFT}]
        set gz [expr {$reihen*$BD + ($reihen-1)*$LUFT}]
        
        set block_index 0
        foreach block $l(blocks) {
            array set b $block
            
            set sp [expr {$block_index % $spalten}]
            set re [expr {int($block_index / $spalten)}]
            set x [expr {-$gx/2 + $BW/2 + $sp*($BW+$LUFT)}]
            set z [expr {-$gz/2 + $BD/2 + $re*($BD+$LUFT)}]
            
            set id [expr {$b(id) != "" ? $b(id) : \
                         [regsub -all {^-|-$} [regsub -all {[^a-z0-9]+} [string tolower $b(name)] "-"] ""]}]
            
            lappend nodes [list id $id name $b(name) untertitel $b(untertitel) \
                          schicht $l(name) x $x y $y z $z color $l(farbe)]
            
            set node_by_id($id) [expr {[llength $nodes] - 1}]
            incr block_index
        }
        incr layer_index
    }
    
    # Draw connections
    foreach edge $SPEC(kanten) {
        array set e $edge
        if {[info exists node_by_id($e(von))] && [info exists node_by_id($e(nach))]} {
            set from_idx $node_by_id($e(von))
            set to_idx $node_by_id($e(nach))
            
            array set from_node [lindex $nodes $from_idx]
            array set to_node [lindex $nodes $to_idx]
            
            set from_coords [project_point $from_node(x) [expr {$from_node(y) + 0.9}] $from_node(z)]
            set to_coords [project_point $to_node(x) [expr {$to_node(y) - 0.9}] $to_node(z)]
            
            foreach {fx fy} $from_coords break
            foreach {tx ty} $to_coords break
            
            .content.main.canvas create line $fx $fy $tx $ty -fill #6d5bd0 -width 2
        }
    }
}

proc select_node {index} {
    global nodes selected_node
    
    set len [llength $nodes]
    if {$len == 0} return
    
    set selected_node [expr {((($index % $len) + $len) % $len)}]
    set node [lindex $nodes $selected_node]
    
    array set n $node
    .content.sidebar.name configure -text $n(name)
    .content.sidebar.sub configure -text [expr {$n(untertitel) != "" ? $n(untertitel) : "—"}]
    .content.sidebar.layer_frame.value configure -text $n(schicht)
    .content.sidebar.id_frame.value configure -text $n(id)
    
    render_scene
}

proc zoom {factor} {
    global zoom_factor
    set zoom_factor [expr {max(0.3, min(3.0, $zoom_factor * $factor))}]
    render_scene
}

proc reset_view {} {
    global azimut elevation zoom_factor iso
    set azimut [expr {3.14159/4}]
    set elevation 0.62
    set zoom_factor 1.0
    set iso 1
    .content.main.controls.iso configure -text "Iso"
    render_scene
}

proc toggle_projection {} {
    global iso
    set iso [expr {!$iso}]
    .content.main.controls.iso configure -text [expr {$iso ? "Iso" : "Persp"}]
    render_scene
}

proc rotate_view {} {
    global rotiert azimut
    if {$rotiert} {
        set azimut [expr {$azimut + 0.02}]
        update_camera
        render_scene
    }
    after 50 rotate_view
}

# Mouse handling for rotation
bind .content.main.canvas <ButtonPress-1> {set ::dragging 1; set ::last_x %x; set ::last_y %y}
bind .content.main.canvas <B1-Motion> {
    if {[info exists ::dragging]} {
        set dx [expr {%x - $::last_x}]
        set dy [expr {%y - $::last_y}]
        set ::azimut [expr {$::azimut - $dx * 0.01}]
        set ::elevation [expr {max(0.1, min(1.5, $::elevation + $dy * 0.01))}]
        set ::last_x %x
        set ::last_y %y
        update_camera
        render_scene
    }
}
bind .content.main.canvas <ButtonRelease-1> {unset ::dragging}

# Mouse wheel zoom
bind .content.main.canvas <MouseWheel> {
    if {%D > 0} {
        zoom 0.9
    } else {
        zoom 1.1
    }
}

# Click handling for node selection
bind .content.main.canvas <ButtonPress-1> {
    # In a real implementation, you would do hit testing here
    # For now we'll just cycle through nodes for demonstration
    select_node [expr {$::selected_node + 1}]
}

# Initialize the scene
build_scene
update_camera
render_scene
select_node 0

# Start animation loop
rotate_view

# Handle window resize
bind . <Configure> {
    after idle {
        if {[winfo exists .content.main.canvas]} {
            render_scene
        }
    }
}
