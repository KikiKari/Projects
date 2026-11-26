#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "e61896fa8830d77810af762845d02c0d802f25159ddd0dacdd2cda898a6aaacd", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "tcl"}
# icon-controls.css — portiert nach tcl
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl script to generate CSS file with icon controls
# Usage: tclsh icon-controls.tcl <output-file>

proc generate_css {filename} {
    set css ""
    
    # Add comment header
    append css "/* Generated CSS for icon controls */\n\n"
    
    # Define icon styles
    foreach style {plastisch glass linear} {
        append css "html\[data-icon-style=\"$style\"\] \{\n"
        foreach icon {auto-chat-refresh-counter browser captions chat-counter fullscreen mute off on pip play player protection-slider recommendation-counter report reset settings status stop unmute volume-slider} {
            append css "  --icon-$icon:url\(\"icons/$style/$icon.png\"\);\n"
        }
        append css "\}\n\n"
    }
    
    # Add button and control styles
    append css {
button[data-control-icon]::before,
.control-icon::before {
  content: "";
  display: inline-block;
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  background: var(--control-icon) center/contain no-repeat;
  vertical-align: middle;
  margin-inline-end: 0;
  pointer-events: none;
}

button[data-control-icon] {
  min-height: 44px;
  min-width: 44px;
  font-size: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

button[data-control-icon][hidden] {
  display: none;
}

input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 44px;
  height: 44px;
  min-width: 44px;
  border: 0;
  background: var(--icon-off) center/40px no-repeat;
  cursor: pointer;
  vertical-align: middle;
}

input[type="checkbox"]:checked {
  background-image: var(--icon-on);
}

input[type="checkbox"]:focus-visible,
button[data-control-icon]:focus-visible {
  outline: 2px solid #1769df;
  outline-offset: 2px;
}

input[type="checkbox"]:disabled {
  opacity: .45;
  cursor: default;
}

.control-icon {
  display: inline-flex;
  align-items: center;
}

input[type="range"] {
  min-height: 32px;
}

.icon-style-setting {
  display: flex;
  align-items: center;
  gap: 8px;
}

}
    
    # Add individual control icon definitions
    foreach icon {auto-chat-refresh-counter browser captions chat-counter fullscreen mute off on pip play player protection-slider recommendation-counter report reset settings status stop unmute volume-slider} {
        append css "\[data-control-icon=\"$icon\"\] \{ --control-icon:var\(--icon-$icon\); \}\n"
    }
    
    # Write to file
    set fh [open $filename w]
    puts -nonewline $fh $css
    close $fh
    
    puts "CSS file generated: $filename"
}

# Main execution
if {$argc != 1} {
    puts "Usage: tclsh [file tail $argv0] <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
generate_css $output_file
