#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "4b51a73e3fc01fac3a74d3d009f549d04b24134ccba4c60cd5df49583eb86a91", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "tcl"}
# periodensystem.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/periodensystem.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Abstraction provenance: {"artifact_sha256": "57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "tcl"}
# periodensystem.html — portiert nach css
# Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

proc write_css_file {filename} {
    set file_handle [open $filename w]
    
    puts $file_handle "/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */"
    puts $file_handle "/* periodensystem.html — portiert nach css */"
    puts $file_handle "/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */"
    puts $file_handle "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    puts $file_handle ""
    
    # Reset and base styles
    puts $file_handle "* { box-sizing: border-box; margin: 0; padding: 0; }"
    puts $file_handle ":root {"
    puts $file_handle "  --bg: #fafaf7;"
    puts $file_handle "  --surface: #ffffff;"
    puts $file_handle "  --border: rgba(0,0,0,0.12);"
    puts $file_handle "  --text: #1a1a1a;"
    puts $file_handle "  --text-muted: #666;"
    puts $file_handle "}"
    
    # Dark mode support
    puts $file_handle "@media (prefers-color-scheme: dark) {"
    puts $file_handle "  :root {"
    puts $file_handle "    --bg: #1a1a1a;"
    puts $file_handle "    --surface: #242424;"
    puts $file_handle "    --border: rgba(255,255,255,0.15);"
    puts $file_handle "    --text: #f0f0f0;"
    puts $file_handle "    --text-muted: #aaa;"
    puts $file_handle "  }"
    puts $file_handle "}"
    
    # Body styles
    puts $file_handle "body {"
    puts $file_handle "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;"
    puts $file_handle "  background: var(--bg);"
    puts $file_handle "  color: var(--text);"
    puts $file_handle "  padding: 24px;"
    puts $file_handle "  max-width: 1100px;"
    puts $file_handle "  margin: 0 auto;"
    puts $file_handle "  line-height: 1.5;"
    puts $file_handle "}"
    
    # Header styles
    puts $file_handle "h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }"
    puts $file_handle ".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }"
    
    # Detail panel styles
    puts $file_handle ".detail {"
    puts $file_handle "  background: var(--surface);"
    puts $file_handle "  border: 1px solid var(--border);"
    puts $file_handle "  border-radius: 12px;"
    puts $file_handle "  padding: 16px 20px;"
    puts $file_handle "  min-height: 110px;"
    puts $file_handle "  display: flex;"
    puts $file_handle "  align-items: center;"
    puts $file_handle "  gap: 20px;"
    puts $file_handle "  margin-bottom: 16px;"
    puts $file_handle "}"
    
    puts $file_handle ".detail-empty {"
    puts $file_handle "  color: var(--text-muted);"
    puts $file_handle "  font-size: 14px;"
    puts $file_handle "  text-align: center;"
    puts $file_handle "  width: 100%;"
    puts $file_handle "}"
    
    # Symbol box styles
    puts $file_handle ".symbol-box {"
    puts $file_handle "  font-size: 40px;"
    puts $file_handle "  font-weight: 500;"
    puts $file_handle "  line-height: 1;"
    puts $file_handle "  width: 80px;"
    puts $file_handle "  height: 80px;"
    puts $file_handle "  display: flex;"
    puts $file_handle "  align-items: center;"
    puts $file_handle "  justify-content: center;"
    puts $file_handle "  border-radius: 8px;"
    puts $file_handle "  flex-shrink: 0;"
    puts $file_handle "}"
    
    # Info section styles
    puts $file_handle ".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }"
    
    puts $file_handle ".info-meta {"
    puts $file_handle "  font-size: 13px;"
    puts $file_handle "  color: var(--text-muted);"
    puts $file_handle "  display: grid;"
    puts $file_handle "  grid-template-columns: repeat(2, minmax(0, 1fr));"
    puts $file_handle "  gap: 4px 24px;"
    puts $file_handle "}"
    
    puts $file_handle ".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }"
    
    # Grid styles
    puts $file_handle ".grid {"
    puts $file_handle "  display: grid;"
    puts $file_handle "  grid-template-columns: repeat(18, minmax(0, 1fr));"
    puts $file_handle "  gap: 3px;"
    puts $file_handle "}"
    
    puts $file_handle ".fgrid { margin-top: 8px; }"
    
    # Cell styles
    puts $file_handle ".cell {"
    puts $file_handle "  aspect-ratio: 1;"
    puts $file_handle "  border-radius: 4px;"
    puts $file_handle "  padding: 3px;"
    puts $file_handle "  display: flex;"
    puts $file_handle "  flex-direction: column;"
    puts $file_handle "  align-items: center;"
    puts $file_handle "  justify-content: center;"
    puts $file_handle "  cursor: pointer;"
    puts $file_handle "  font-family: inherit;"
    puts $file_handle "  line-height: 1;"
    puts $file_handle "  transition: transform 0.12s ease;"
    puts $file_handle "  border: 0;"
    puts $file_handle "  position: relative;"
    puts $file_handle "  overflow: hidden;"
    puts $file_handle "}"
    
    puts $file_handle ".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }"
    puts $file_handle ".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }"
    puts $file_handle ".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }"
    
    puts $file_handle ".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }"
    puts $file_handle ".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }"
    
    # Marker cell styles
    puts $file_handle ".cell-marker {"
    puts $file_handle "  cursor: default;"
    puts $file_handle "  font-size: 9px;"
    puts $file_handle "  font-weight: 500;"
    puts $file_handle "  border: 1px dashed currentColor;"
    puts $file_handle "  background: transparent !important;"
    puts $file_handle "}"
    
    puts $file_handle ".cell-marker:hover { transform: none; box-shadow: none; }"
    
    # Category color classes
    puts $file_handle ".cat-am { background: #FCEBEB; color: #501313; }"
    puts $file_handle ".cat-em { background: #FAEEDA; color: #412402; }"
    puts $file_handle ".cat-tm { background: #E6F1FB; color: #042C53; }"
    puts $file_handle ".cat-ptm { background: #F1EFE8; color: #2C2C2A; }"
    puts $file_handle ".cat-hm { background: #E1F5EE; color: #04342C; }"
    puts $file_handle ".cat-nm { background: #EAF3DE; color: #173404; }"
    puts $file_handle ".cat-h { background: #EEEDFE; color: #26215C; }"
    puts $file_handle ".cat-eg { background: #FBEAF0; color: #4B1528; }"
    puts $file_handle ".cat-la { background: #FAECE7; color: #4A1B0C; }"
    puts $file_handle ".cat-ac { background: #F5C4B3; color: #4A1B0C; }"
    
    # Dark mode category colors
    puts $file_handle "@media (prefers-color-scheme: dark) {"
    puts $file_handle "  .cat-am { background: #791F1F; color: #F7C1C1; }"
    puts $file_handle "  .cat-em { background: #633806; color: #FAC775; }"
    puts $file_handle "  .cat-tm { background: #0C447C; color: #B5D4F4; }"
    puts $file_handle "  .cat-ptm { background: #444441; color: #D3D1C7; }"
    puts $file_handle "  .cat-hm { background: #085041; color: #9FE1CB; }"
    puts $file_handle "  .cat-nm { background: #27500A; color: #C0DD97; }"
    puts $file_handle "  .cat-h { background: #3C3489; color: #CECBF6; }"
    puts $file_handle "  .cat-eg { background: #72243E; color: #F4C0D1; }"
    puts $file_handle "  .cat-la { background: #712B13; color: #F5C4B3; }"
    puts $file_handle "  .cat-ac { background: #993C1D; color: #F5C4B3; }"
    puts $file_handle "}"
    
    # Legend styles
    puts $file_handle ".legend {"
    puts $file_handle "  display: grid;"
    puts $file_handle "  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));"
    puts $file_handle "  gap: 8px 16px;"
    puts $file_handle "  margin-top: 24px;"
    puts $file_handle "  font-size: 12px;"
    puts $file_handle "  color: var(--text-muted);"
    puts $file_handle "}"
    
    puts $file_handle ".legend-item { display: flex; align-items: center; gap: 8px; }"
    
    puts $file_handle ".legend-swatch {"
    puts $file_handle "  width: 14px;"
    puts $file_handle "  height: 14px;"
    puts $file_handle "  border-radius: 3px;"
    puts $file_handle "  flex-shrink: 0;"
    puts $file_handle "}"
    
    close $file_handle
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: [info script] <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
write_css_file $output_file
