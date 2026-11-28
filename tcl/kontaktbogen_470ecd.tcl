#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "effb632778c3724d7f00ae696c800353fceac1fb099c431b5a03afe2eaaffe41", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "tcl"}
# kontaktbogen.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/kontaktbogen.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Tcl-Programm zur Erzeugung der CSS-Datei kontaktbogen.css
# Portiert von CSS nach Tcl 8.6

proc write_css_file {filename} {
    set fp [open $filename w]
    
    puts $fp "/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */"
    puts $fp "/* kontaktbogen.html — portiert nach css */"
    puts $fp "/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */"
    puts $fp "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    puts $fp ""
    
    puts $fp ":root {"
    puts $fp "  --bg: #FAF8F4;"
    puts $fp "  --ink: #1B1A17;"
    puts $fp "  --muted: #6E6A61;"
    puts $fp "  --line: #E5E1D8;"
    puts $fp "  --accent: #A8542F;"
    puts $fp "  --accent-2: #2E7D7B;"
    puts $fp "  --surface: #fff;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "* {"
    puts $fp "  box-sizing: border-box;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "body {"
    puts $fp "  margin: 0;"
    puts $fp "  font-family: 'Hanken Grotesk', system-ui, sans-serif;"
    puts $fp "  background: var(--bg);"
    puts $fp "  color: var(--ink);"
    puts $fp "  line-height: 1.5;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "header {"
    puts $fp "  padding: 2.5rem 2rem 1rem;"
    puts $fp "  border-bottom: 1px solid var(--line);"
    puts $fp "  background: var(--surface);"
    puts $fp "  position: sticky;"
    puts $fp "  top: 0;"
    puts $fp "  z-index: 10;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "header h1 {"
    puts $fp "  margin: 0 0 .5rem;"
    puts $fp "  font-family: 'Newsreader', Georgia, serif;"
    puts $fp "  font-weight: 400;"
    puts $fp "  font-size: 2.25rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "header p {"
    puts $fp "  margin: .25rem 0;"
    puts $fp "  color: var(--muted);"
    puts $fp "  max-width: 80ch;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".legend {"
    puts $fp "  display: flex;"
    puts $fp "  gap: 1rem;"
    puts $fp "  flex-wrap: wrap;"
    puts $fp "  margin-top: .75rem;"
    puts $fp "  font-size: .8125rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".pill {"
    puts $fp "  padding: .15rem .6rem;"
    puts $fp "  border-radius: 999px;"
    puts $fp "  border: 1px solid var(--line);"
    puts $fp "  background: #fff;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".pill.pflicht {"
    puts $fp "  border-color: var(--accent);"
    puts $fp "  color: var(--accent);"
    puts $fp "  font-weight: 600;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".pill.auswahl {"
    puts $fp "  border-color: var(--accent-2);"
    puts $fp "  color: var(--accent-2);"
    puts $fp "  font-weight: 600;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "main {"
    puts $fp "  padding: 2rem;"
    puts $fp "  max-width: 1400px;"
    puts $fp "  margin: 0 auto;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "section {"
    puts $fp "  margin: 2.5rem 0;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "section h2 {"
    puts $fp "  font-family: 'Newsreader', serif;"
    puts $fp "  font-weight: 400;"
    puts $fp "  font-size: 1.5rem;"
    puts $fp "  margin: 0 0 .25rem;"
    puts $fp "  display: flex;"
    puts $fp "  align-items: center;"
    puts $fp "  gap: .75rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp "section .sub {"
    puts $fp "  color: var(--muted);"
    puts $fp "  font-size: .875rem;"
    puts $fp "  margin: 0 0 1.25rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".grid {"
    puts $fp "  display: grid;"
    puts $fp "  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));"
    puts $fp "  gap: 1rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card {"
    puts $fp "  background: var(--surface);"
    puts $fp "  border: 1px solid var(--line);"
    puts $fp "  border-radius: 10px;"
    puts $fp "  overflow: hidden;"
    puts $fp "  display: flex;"
    puts $fp "  flex-direction: column;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card .imgwrap {"
    puts $fp "  aspect-ratio: 1;"
    puts $fp "  background: #f1eee7;"
    puts $fp "  display: flex;"
    puts $fp "  align-items: center;"
    puts $fp "  justify-content: center;"
    puts $fp "  overflow: hidden;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card img {"
    puts $fp "  width: 100%;"
    puts $fp "  height: 100%;"
    puts $fp "  object-fit: contain;"
    puts $fp "  background: #fff;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card .meta {"
    puts $fp "  padding: .6rem .75rem .75rem;"
    puts $fp "  font-size: .78125rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card .name {"
    puts $fp "  font-family: 'JetBrains Mono', monospace;"
    puts $fp "  font-size: .6875rem;"
    puts $fp "  color: var(--muted);"
    puts $fp "  word-break: break-all;"
    puts $fp "  line-height: 1.3;"
    puts $fp "  margin-bottom: .35rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card .dims {"
    puts $fp "  color: var(--muted);"
    puts $fp "  font-size: .6875rem;"
    puts $fp "  margin-bottom: .35rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".card .prompt {"
    puts $fp "  color: var(--ink);"
    puts $fp "  font-size: .75rem;"
    puts $fp "  line-height: 1.35;"
    puts $fp "  font-style: italic;"
    puts $fp "  border-top: 1px solid var(--line);"
    puts $fp "  padding-top: .4rem;"
    puts $fp "  margin-top: .35rem;"
    puts $fp "  max-height: 5.5em;"
    puts $fp "  overflow: hidden;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".tag {"
    puts $fp "  display: inline-block;"
    puts $fp "  padding: .1rem .45rem;"
    puts $fp "  border-radius: 999px;"
    puts $fp "  font-size: .6875rem;"
    puts $fp "  background: #F1EEE7;"
    puts $fp "  color: var(--muted);"
    puts $fp "  margin-right: .25rem;"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".tag.p {"
    puts $fp "  background: #F1E5DD;"
    puts $fp "  color: var(--accent);"
    puts $fp "}"
    puts $fp ""
    
    puts $fp ".tag.a {"
    puts $fp "  background: #DEEDEC;"
    puts $fp "  color: var(--accent-2);"
    puts $fp "}"
    
    close $fp
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css_file $output_file
