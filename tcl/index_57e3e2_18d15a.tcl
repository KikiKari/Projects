#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "ecb77445ddfec95e4537e133c00c4c6bf13c0d1cb0ffd248a6c08e6007305c70", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "tcl"}
# index_57e3e2.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/index_57e3e2.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Erzeugt die CSS-Datei index_57e3e2.css
# Portiert von CSS zu Tcl 8.6

proc write_css {filename} {
    set css [open $filename w]
    
    puts $css "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */"
    puts $css "/* index.html \u2014 portiert nach css */"
    puts $css "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */"
    puts $css "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    puts $css ""
    
    # Root
    puts $css ":root {"
    puts $css "  color-scheme: light;"
    puts $css "}"
    puts $css ""
    
    # Universal selector
    puts $css "* {"
    puts $css "  box-sizing: border-box;"
    puts $css "}"
    puts $css ""
    
    # Body
    puts $css "body {"
    puts $css "  margin: 0;"
    puts $css "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;"
    puts $css "  background: #f7f7f5;"
    puts $css "  color: #1d1c1a;"
    puts $css "}"
    puts $css ""
    
    # Wrap
    puts $css ".wrap {"
    puts $css "  max-width: 880px;"
    puts $css "  margin: 0 auto;"
    puts $css "  padding: 20px 16px 60px;"
    puts $css "}"
    puts $css ""
    
    # Headings
    puts $css "h1 {"
    puts $css "  font-size: 22px;"
    puts $css "  margin: 0 0 2px;"
    puts $css "}"
    puts $css ""
    
    # Sub heading
    puts $css ".sub {"
    puts $css "  color: #6b6a66;"
    puts $css "  font-size: 13px;"
    puts $css "  margin-bottom: 16px;"
    puts $css "}"
    puts $css ""
    
    # Bar
    puts $css ".bar {"
    puts $css "  display: flex;"
    puts $css "  gap: 10px;"
    puts $css "  align-items: center;"
    puts $css "  margin-bottom: 16px;"
    puts $css "  flex-wrap: wrap;"
    puts $css "}"
    puts $css ""
    
    # Buttons
    puts $css "button {"
    puts $css "  font-size: 13px;"
    puts $css "  font-weight: 600;"
    puts $css "  padding: 7px 13px;"
    puts $css "  border: 1px solid #d9d8d3;"
    puts $css "  border-radius: 8px;"
    puts $css "  background: #fff;"
    puts $css "  cursor: pointer;"
    puts $css "}"
    puts $css ""
    
    puts $css "button:hover {"
    puts $css "  background: #f2f1ec;"
    puts $css "}"
    puts $css ""
    
    puts $css "button.primary {"
    puts $css "  background: #1d1c1a;"
    puts $css "  color: #fff;"
    puts $css "  border-color: #1d1c1a;"
    puts $css "}"
    puts $css ""
    
    # Note
    puts $css ".note {"
    puts $css "  background: #fffdf4;"
    puts $css "  border: 1px solid #f0e9c8;"
    puts $css "  border-radius: 10px;"
    puts $css "  padding: 12px 14px;"
    puts $css "  font-size: 13px;"
    puts $css "  color: #4a4734;"
    puts $css "  margin-bottom: 16px;"
    puts $css "  line-height: 1.5;"
    puts $css "}"
    puts $css ""
    
    # Section
    puts $css ".section {"
    puts $css "  background: #fff;"
    puts $css "  border: 1px solid #e8e7e3;"
    puts $css "  border-radius: 12px;"
    puts $css "  margin-bottom: 14px;"
    puts $css "  overflow: hidden;"
    puts $css "}"
    puts $css ""
    
    puts $css ".section > h2 {"
    puts $css "  font-size: 15px;"
    puts $css "  margin: 0;"
    puts $css "  padding: 13px 16px;"
    puts $css "  border-bottom: 1px solid #efeee9;"
    puts $css "  display: flex;"
    puts $css "  align-items: center;"
    puts $css "  gap: 9px;"
    puts $css "}"
    puts $css ""
    
    puts $css ".section > h2 .badge {"
    puts $css "  margin-left: auto;"
    puts $css "  font-size: 12px;"
    puts $css "  font-weight: 600;"
    puts $css "  background: #efeee9;"
    puts $css "  color: #5a5852;"
    puts $css "  padding: 2px 9px;"
    puts $css "  border-radius: 20px;"
    puts $css "}"
    puts $css ""
    
    # Body content
    puts $css ".body {"
    puts $css "  padding: 8px 16px 14px;"
    puts $css "  font-size: 14px;"
    puts $css "}"
    puts $css ""
    
    # Muted text
    puts $css ".muted {"
    puts $css "  color: #8a8884;"
    puts $css "}"
    puts $css ""
    
    # Error text
    puts $css ".err {"
    puts $css "  color: #c0392b;"
    puts $css "}"
    puts $css ""
    
    # Key-value pairs
    puts $css ".kv {"
    puts $css "  display: flex;"
    puts $css "  justify-content: space-between;"
    puts $css "  padding: 4px 0;"
    puts $css "  border-bottom: 1px solid #f4f3ee;"
    puts $css "}"
    puts $css ""
    
    puts $css ".kv:last-child {"
    puts $css "  border: none;"
    puts $css "}"
    puts $css ""
    
    puts $css ".kv .k {"
    puts $css "  color: #6b6a66;"
    puts $css "}"
    puts $css ""
    
    puts $css ".kv .v {"
    puts $css "  font-weight: 600;"
    puts $css "}"
    puts $css ""
    
    # Links
    puts $css "a {"
    puts $css "  color: #2b5cc4;"
    puts $css "  text-decoration: none;"
    puts $css "}"
    puts $css ""
    
    puts $css "a:hover {"
    puts $css "  text-decoration: underline;"
    puts $css "}"
    puts $css ""
    
    # Modal
    puts $css ".modal {"
    puts $css "  position: fixed;"
    puts $css "  inset: 0;"
    puts $css "  background: rgba(0, 0, 0, .35);"
    puts $css "  display: none;"
    puts $css "  align-items: flex-start;"
    puts $css "  justify-content: center;"
    puts $css "  padding: 40px 16px;"
    puts $css "  overflow: auto;"
    puts $css "}"
    puts $css ""
    
    puts $css ".modal.open {"
    puts $css "  display: flex;"
    puts $css "}"
    puts $css ""
    
    # Card
    puts $css ".card {"
    puts $css "  background: #fff;"
    puts $css "  border-radius: 14px;"
    puts $css "  max-width: 560px;"
    puts $css "  width: 100%;"
    puts $css "  padding: 20px;"
    puts $css "}"
    puts $css ""
    
    puts $css ".card h3 {"
    puts $css "  margin: 0 0 4px;"
    puts $css "  font-size: 17px;"
    puts $css "}"
    puts $css ""
    
    puts $css ".card p.hint {"
    puts $css "  margin: 0 0 16px;"
    puts $css "  font-size: 12px;"
    puts $css "  color: #8a8884;"
    puts $css "}"
    puts $css ""
    
    # Form fields
    puts $css ".field {"
    puts $css "  margin-bottom: 12px;"
    puts $css "}"
    puts $css ""
    
    puts $css ".field label {"
    puts $css "  display: block;"
    puts $css "  font-size: 12px;"
    puts $css "  font-weight: 600;"
    puts $css "  color: #5a5852;"
    puts $css "  margin-bottom: 3px;"
    puts $css "}"
    puts $css ""
    
    puts $css ".field input {"
    puts $css "  width: 100%;"
    puts $css "  font-size: 13px;"
    puts $css "  padding: 7px 9px;"
    puts $css "  border: 1px solid #d9d8d3;"
    puts $css "  border-radius: 7px;"
    puts $css "  font-family: ui-monospace, Menlo, monospace;"
    puts $css "}"
    puts $css ""
    
    puts $css ".field .desc {"
    puts $css "  font-size: 11px;"
    puts $css "  color: #a8a6a1;"
    puts $css "  margin-top: 2px;"
    puts $css "}"
    puts $css ""
    
    # Actions
    puts $css ".actions {"
    puts $css "  display: flex;"
    puts $css "  gap: 10px;"
    puts $css "  justify-content: flex-end;"
    puts $css "  margin-top: 8px;"
    puts $css "}"
    puts $css ""
    
    # Warning
    puts $css ".warn {"
    puts $css "  background: #fdf3f3;"
    puts $css "  border: 1px solid #f3d9d9;"
    puts $css "  color: #9a3b3b;"
    puts $css "  border-radius: 8px;"
    puts $css "  padding: 10px 12px;"
    puts $css "  font-size: 12px;"
    puts $css "  margin-bottom: 14px;"
    puts $css "}"
    
    close $css
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ziel_datei>"
    exit 1
}

set target_file [lindex $argv 0]
write_css $target_file
