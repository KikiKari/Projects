#!/usr/bin/env tclsh
# icon-controls.css — portiert nach tcl
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

proc generate_css_document {filename} {
    set icon_styles {plastisch glass linear}
    set icons {
        auto-chat-refresh-counter browser captions chat-counter fullscreen
        mute off on pip play player protection-slider recommendation-counter
        report reset settings status stop unmute volume-slider
    }

    set file_handle [open $filename w]

    # Generate style definitions for each icon style
    foreach style $icon_styles {
        puts $file_handle "html\[data-icon-style=\"$style\"\] \{"
        foreach icon $icons {
            puts $file_handle "  --icon-$icon:url\(\"icons/$style/$icon.png\"\);"
        }
        puts $file_handle "\}"
    }

    # Generate base control styles
    puts $file_handle {
button[data-control-icon]::before,.control-icon::before {
  content:"";
  display:inline-block;
  width:32px;
  height:32px;
  flex:0 0 32px;
  background:var(--control-icon) center/contain no-repeat;
  vertical-align:middle;
  margin-inline-end:0;
  pointer-events:none;
}

button[data-control-icon] {
  min-height:44px;
  min-width:44px;
  font-size:0;
  display:inline-flex;
  align-items:center;
  justify-content:center;
}

button[data-control-icon][hidden] {
  display:none;
}

input[type="checkbox"] {
  appearance:none;
  -webkit-appearance:none;
  width:44px;
  height:44px;
  min-width:44px;
  border:0;
  background:var(--icon-off) center/40px no-repeat;
  cursor:pointer;
  vertical-align:middle;
}

input[type="checkbox"]:checked {
  background-image:var(--icon-on);
}

input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible {
  outline:2px solid #1769df;
  outline-offset:2px;
}

input[type="checkbox"]:disabled {
  opacity:.45;
  cursor:default;
}

.control-icon {
  display:inline-flex;
  align-items:center;
}

input[type="range"] {
  min-height:32px;
}

.icon-style-setting {
  display:flex;
  align-items:center;
  gap:8px;
}
}

    # Generate icon-specific control definitions
    foreach icon $icons {
        puts $file_handle "\[data-control-icon=\"$icon\"\] \{ --control-icon:var(--icon-$icon); \}"
    }

    close $file_handle
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

generate_css_document [lindex $argv 0]
