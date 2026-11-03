#!/usr/bin/env tclsh
# status-overview-panel.css — portiert nach tcl
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
# Erzeugt: 2026-11-03 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erstellung der CSS-Datei 'status-overview-panel.css'
# Dieses Skript generiert dynamisch die benötigte CSS-Struktur und speichert sie in eine Datei.

proc write_css_file {filename} {
    set css_content {
.overview-row { display:grid; grid-template-columns:24px minmax(0,1fr) 11px 22px auto; gap:7px; align-items:center; margin:6px 0; }
.overview-row input { min-width:0; width:100%; }
.overview-state { width:11px; height:11px; border-radius:50%; background:#888; }
.overview-state.online { background:var(--good); box-shadow:0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent); }
.overview-state.offline { background:var(--bad); box-shadow:0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }
.overview-state.checking, .overview-state.error { background:var(--warn); }
.overview-count { font-size:11px; text-align:center; font-variant-numeric:tabular-nums; }
.overview-actions { display:grid; grid-template-columns:44px repeat(2,minmax(0,1fr)); gap:6px; align-items:stretch; }
.overview-actions button { min-width:0; padding:8px 2px; font-size:11px; white-space:nowrap; }

#overview-rows { display:flex; flex-direction:column; }
.monitor-settings > label:not(.option-row) { display:block; margin:12px 0; }
.monitor-settings .option-row input { appearance:auto; width:13px; height:13px; min-width:13px; background:none; }
.overview-link { padding:8px 0; border-bottom:1px solid #bbb; overflow-wrap:anywhere; }
.overview-link p { margin:4px 0; }

.overview-row .overview-retry { width:24px; min-width:24px; height:26px; min-height:26px; padding:0; background-image:var(--icon-reset); background-size:20px; background-position:center; background-repeat:no-repeat; }

.top-setting input { appearance:auto; -webkit-appearance:checkbox; width:13px; height:13px; min-width:13px; background:none; }

.overview-visually-hidden { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap; border:0; }
.overview-row\[hidden\] { display:none; }
    }

    # Entferne führende Leerzeichen aus jeder Zeile (Tcl-Formatierung)
    set lines [split $css_content "\n"]
    set cleaned_lines {}
    foreach line $lines {
        lappend cleaned_lines [string trim $line]
    }
    set final_content [join $cleaned_lines "\n"]

    # Schreibe den bereinigten Inhalt in die angegebene Datei
    set fh [open $filename w]
    puts $fh $final_content
    close $fh
}

# Hauptprogramm: Prüfe Kommandozeilenargument
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css_file $output_file
puts "CSS-Datei erfolgreich erstellt: $output_file"
