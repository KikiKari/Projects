#!/usr/bin/env tclsh
# sidepanel.css — portiert nach tcl
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/sidepanel.css
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# sidepanel.css in Tcl/Tk
# Generates CSS content dynamically and writes to a file

proc generate_css {} {
    set css ""

    # Root variables
    append css ":root {\n"
    append css "  color-scheme: light dark;\n"
    append css {  font-family: Inter, "Segoe UI", system-ui, sans-serif;} \n
    append css "  --accent: #fe2c55;\n"
    append css "  --accent-dark: #d91f46;\n"
    append css "  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);\n"
    append css "  --border: color-mix(in srgb, CanvasText 18%, transparent);\n"
    append css "  --muted: color-mix(in srgb, CanvasText 65%, transparent);\n"
    append css "  --good: #147d45;\n"
    append css "  --warn: #a65f00;\n"
    append css "  --bad: #b42318;\n"
    append css "}\n\n"

    # Universal selector
    append css "* { box-sizing: border-box; }\n"
    
    # Body
    append css "body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }\n"
    
    # Header
    append css "header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }\n"
    
    # Headings
    append css "h2 { margin: 0; font-size: 15px; }\n"
    
    # Main content
    append css "main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }\n"
    
    # Sections
    append css "section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }\n"
    
    # Section titles and button rows
    append css ".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n"
    append css ".section-title { min-width: 0; flex-wrap: wrap; }\n"
    
    # Title actions
    append css ".title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }\n"
    
    # Status LED
    append css ".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }\n"
    append css ".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }\n"
    append css ".status-led.off { background: var(--bad); }\n"
    
    # Button row
    append css ".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }\n"
    
    # Buttons
    append css "button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }\n"
    append css "button:disabled { cursor: not-allowed; opacity: .55; }\n"
    append css ".compact { padding: 7px 9px; }\n"
    append css ".primary { color: white; background: var(--accent); }\n"
    append css ".primary:hover { background: var(--accent-dark); }\n"
    append css ".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }\n"
    append css ".ghost { color: var(--muted); background: transparent; }\n"
    append css ".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }\n"
    
    # Enable captions
    append css "#enable-captions { width: 100%; margin-top: 11px; }\n"
    
    # Text styles
    append css ".muted { color: var(--muted); }\n"
    append css ".small { font-size: 12px; line-height: 1.45; }\n"
    
    # Page title
    append css "#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }\n"
    
    # Status grid
    append css ".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }\n"
    append css ".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n"
    append css ".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }\n"
    append css ".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }\n"
    append css ".good .status-value { color: var(--good); }\n"
    append css ".warn .status-value { color: var(--warn); }\n"
    append css ".bad .status-value { color: var(--bad); }\n"
    
    # Count elements
    append css ".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }\n"
    append css ".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer; }\n"
    append css ".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%, Canvas); }\n"
    
    # Live indicator
    append css ".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }\n"
    append css ".live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }\n"
    
    # Stats grid
    append css ".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }\n"
    
    # Chat list
    append css ".chat-list { display: grid; gap: 6px; margin-top: 11px; }\n"
    append css ".chat-list.empty { color: var(--muted); font-size: 12px; }\n"
    append css ".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }\n"
    append css ".chat-author { font-weight: 800; }\n"
    
    # Player controls
    append css ".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }\n"
    append css ".player-controls button { width: 100%; }\n"
    append css ".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }\n"
    
    # Audio controls
    append css ".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }\n"
    append css ".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }\n"
    append css ".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }\n"
    append css {input[type="range"] { width: 100%; accent-color: var(--accent); }} \n
    
    # Settings grid
    append css ".settings-grid { display: grid; gap: 7px; margin-top: 10px; }\n"
    append css ".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n"
    append css ".settings-grid label[hidden] { display: none; }\n"
    append css {input[type="url"], input[type="password"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }} \n
    
    # Top chatters
    append css ".top-chatters { display: grid; gap: 6px; margin-top: 8px; }\n"
    append css ".top-chatters.empty { color: var(--muted); font-size: 12px; }\n"
    append css ".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }\n"
    append css ".top-chatters-actions[hidden] { display: none; }\n"
    append css ".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }\n"
    append css ".top-chatter-link:hover { text-decoration: underline; }\n"
    append css ".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n"
    append css ".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }\n"
    append css ".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }\n"
    append css ".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }\n"
    
    # Recognize song
    append css "#recognize-song { width: 100%; margin-top: 10px; }\n"
    append css ".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }\n"
    append css ".song-result strong, .song-result span, .song-result a { display: block; }\n"
    append css ".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }\n"
    
    # Modal
    append css ".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }\n"
    append css ".modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }\n"
    
    # Audience and chat history
    append css ".audience-list, .chat-history-list { display: grid; gap: 7px; margin-top: 9px; }\n"
    append css ".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }\n"
    append css ".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }\n"
    append css ".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }\n"
    append css ".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n"
    append css ".audience-row select { width: auto; max-width: 170px; }\n"
    append css ".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }\n"
    
    # Option row
    append css ".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }\n"
    append css ".option-row input { margin: 1px 0 0; accent-color: var(--accent); }\n"
    append css ".auto-chat-refresh { align-items: center; }\n"
    append css ".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n"
    append css ".audio-note { margin: 1px 0 0; }\n"
    
    # Profile info
    append css ".profile-info { display: grid; gap: 8px; margin-top: 11px; }\n"
    append css ".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }\n"
    append css ".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }\n"
    append css ".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }\n"
    append css ".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n"
    append css ".profile-stat strong, .profile-stat span { display: block; }\n"
    append css ".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }\n"
    
    # Summary info
    append css ".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }\n"
    append css ".summary-text { margin: 6px 0 0; white-space: pre-wrap; }\n"
    
    # List
    append css ".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }\n"
    append css ".list.empty { display: block; color: var(--muted); font-size: 12px; }\n"
    append css ".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n"
    append css ".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n"
    append css ".item-title { font-size: 12px; font-weight: 800; }\n"
    append css ".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }\n"
    append css ".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }\n"
    append css ".copy { flex: 0 0 auto; padding: 6px 8px; }\n"
    append css ".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }\n"
    
    # Inline status and notice
    append css ".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }\n"
    append css ".action-status { line-height: 1.4; }\n"
    append css ".reset-note { margin: 7px 0 0; }\n"
    append css ".notice { margin: 0 3px 8px; color: var(--bad); }\n"
    
    # Media queries
    append css "@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n"
    append css "@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n"
    
    return $css
}

# Main execution
if {$argc != 1} {
    puts "Usage: $argv0 <output_file>"
    exit 1
}

set output_file [lindex $argv 0]
set css_content [generate_css]

# Write to file
if {[catch {open $output_file w} file_handle]} {
    puts "Error: Could not open file $output_file for writing"
    exit 1
}

puts $file_handle $css_content
close $file_handle

puts "CSS file generated successfully: $output_file"
