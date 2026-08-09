#!/usr/bin/env python3
# sidepanel.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:release/0.7.0/tiktok-live-companion-extension-0.7.0/sidepanel.css
# auch in: Projects@TikTok-Live-Companion:release/0.6.0/tiktok-live-companion-extension-0.6.0/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.0/tiktok-live-companion-extension-0.7.0/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:release/0.6.0/tiktok-live-companion-extension-0.6.0/sidepanel.css
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the complete CSS content as a string"""
    css_parts = []
    
    # Root variables
    css_parts.append(':root {')
    css_parts.append('  color-scheme: light dark;')
    css_parts.append('  font-family: Inter, "Segoe UI", system-ui, sans-serif;')
    css_parts.append('  --accent: #fe2c55;')
    css_parts.append('  --accent-dark: #d91f46;')
    css_parts.append('  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);')
    css_parts.append('  --border: color-mix(in srgb, CanvasText 18%, transparent);')
    css_parts.append('  --muted: color-mix(in srgb, CanvasText 65%, transparent);')
    css_parts.append('  --good: #147d45;')
    css_parts.append('  --warn: #a65f00;')
    css_parts.append('  --bad: #b42318;')
    css_parts.append('}')
    css_parts.append('')
    
    # Universal selector
    css_parts.append('* { box-sizing: border-box; }')
    css_parts.append('')
    
    # Body styles
    css_parts.append('body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }')
    css_parts.append('')
    
    # Header styles
    css_parts.append('header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }')
    css_parts.append('h2 { margin: 0; font-size: 15px; }')
    css_parts.append('')
    
    # Main content
    css_parts.append('main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }')
    css_parts.append('section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }')
    css_parts.append('')
    
    # Section title and button row
    css_parts.append('.section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }')
    css_parts.append('.section-title { min-width: 0; flex-wrap: wrap; }')
    css_parts.append('.title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }')
    css_parts.append('')
    
    # Status LED
    css_parts.append('.status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }')
    css_parts.append('.status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }')
    css_parts.append('.status-led.off { background: var(--bad); }')
    css_parts.append('')
    
    # Button row
    css_parts.append('.button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }')
    css_parts.append('')
    
    # Buttons
    css_parts.append('button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }')
    css_parts.append('button:disabled { cursor: not-allowed; opacity: .55; }')
    css_parts.append('.compact { padding: 7px 9px; }')
    css_parts.append('.primary { color: white; background: var(--accent); }')
    css_parts.append('.primary:hover { background: var(--accent-dark); }')
    css_parts.append('.secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }')
    css_parts.append('.ghost { color: var(--muted); background: transparent; }')
    css_parts.append('.danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }')
    css_parts.append('')
    
    # Enable captions button
    css_parts.append('#enable-captions { width: 100%; margin-top: 11px; }')
    css_parts.append('.muted { color: var(--muted); }')
    css_parts.append('.small { font-size: 12px; line-height: 1.45; }')
    css_parts.append('#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }')
    css_parts.append('')
    
    # Status grid
    css_parts.append('.status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }')
    css_parts.append('.status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }')
    css_parts.append('.status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }')
    css_parts.append('.status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }')
    css_parts.append('.good .status-value { color: var(--good); }')
    css_parts.append('.warn .status-value { color: var(--warn); }')
    css_parts.append('.bad .status-value { color: var(--bad); }')
    css_parts.append('')
    
    # Count and live indicator
    css_parts.append('.count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }')
    css_parts.append('.live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }')
    css_parts.append('.live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }')
    css_parts.append('.stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }')
    css_parts.append('')
    
    # Chat list
    css_parts.append('.chat-list { display: grid; gap: 6px; margin-top: 11px; }')
    css_parts.append('.chat-list.empty { color: var(--muted); font-size: 12px; }')
    css_parts.append('.chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }')
    css_parts.append('.chat-author { font-weight: 800; }')
    css_parts.append('')
    
    # Player controls
    css_parts.append('.player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }')
    css_parts.append('.player-controls button { width: 100%; }')
    css_parts.append('.player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }')
    css_parts.append('')
    
    # Audio controls
    css_parts.append('.audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }')
    css_parts.append('.control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }')
    css_parts.append('.control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }')
    css_parts.append('input[type="range"] { width: 100%; accent-color: var(--accent); }')
    css_parts.append('')
    
    # Settings grid
    css_parts.append('.settings-grid { display: grid; gap: 7px; margin-top: 10px; }')
    css_parts.append('.settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }')
    css_parts.append('input[type="url"], input[type="password"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }')
    css_parts.append('')
    
    # Top chatters
    css_parts.append('.top-chatters { display: grid; gap: 6px; margin-top: 8px; }')
    css_parts.append('.top-chatters.empty { color: var(--muted); font-size: 12px; }')
    css_parts.append('.chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }')
    css_parts.append('.chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }')
    css_parts.append('.chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }')
    css_parts.append('.mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }')
    css_parts.append('')
    
    # Recognize song
    css_parts.append('#recognize-song { width: 100%; margin-top: 10px; }')
    css_parts.append('.song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }')
    css_parts.append('.song-result strong, .song-result span, .song-result a { display: block; }')
    css_parts.append('.song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }')
    css_parts.append('')
    
    # Modal
    css_parts.append('.modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }')
    css_parts.append('.modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }')
    css_parts.append('')
    
    # Audience list
    css_parts.append('.audience-list { display: grid; gap: 7px; margin-top: 9px; }')
    css_parts.append('.audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }')
    css_parts.append('.audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }')
    css_parts.append('.audience-row select { width: auto; max-width: 170px; }')
    css_parts.append('.audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }')
    css_parts.append('')
    
    # Option row
    css_parts.append('.option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }')
    css_parts.append('.option-row input { margin: 1px 0 0; accent-color: var(--accent); }')
    css_parts.append('.audio-note { margin: 1px 0 0; }')
    css_parts.append('')
    
    # Profile info
    css_parts.append('.profile-info { display: grid; gap: 8px; margin-top: 11px; }')
    css_parts.append('.profile-heading { margin: 0; font-size: 14px; font-weight: 800; }')
    css_parts.append('.profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }')
    css_parts.append('.profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }')
    css_parts.append('.profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }')
    css_parts.append('.profile-stat strong, .profile-stat span { display: block; }')
    css_parts.append('.profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }')
    css_parts.append('')
    
    # Summary info
    css_parts.append('.summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }')
    css_parts.append('.summary-text { margin: 6px 0 0; white-space: pre-wrap; }')
    css_parts.append('')
    
    # List
    css_parts.append('.list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }')
    css_parts.append('.list.empty { display: block; color: var(--muted); font-size: 12px; }')
    css_parts.append('.item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }')
    css_parts.append('.item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }')
    css_parts.append('.item-title { font-size: 12px; font-weight: 800; }')
    css_parts.append('.item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }')
    css_parts.append('.item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }')
    css_parts.append('.copy { flex: 0 0 auto; padding: 6px 8px; }')
    css_parts.append('.caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }')
    css_parts.append('.inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }')
    css_parts.append('.action-status { line-height: 1.4; }')
    css_parts.append('.reset-note { margin: 7px 0 0; }')
    css_parts.append('.quality-details { margin-top: 5px; color: var(--muted); font-size: 10px; line-height: 1.4; }')
    css_parts.append('.quality-active { border-color: color-mix(in srgb, var(--good) 55%, var(--border)); }')
    css_parts.append('.notice { margin: 0 3px 8px; color: var(--bad); }')
    css_parts.append('')
    
    # Media queries
    css_parts.append('@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }')
    css_parts.append('@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }')
    
    return '\n'.join(css_parts)

def main():
    """Main function to write CSS to file"""
    if len(sys.argv) != 2:
        print("Usage: python sidepanel_css_generator.py <output_file>")
        sys.exit(1)
    
    output_file = Path(sys.argv[1])
    css_content = generate_css()
    
    try:
        output_file.write_text(css_content, encoding='utf-8')
        print(f"CSS file successfully written to: {output_file}")
    except Exception as e:
        print(f"Error writing CSS file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
