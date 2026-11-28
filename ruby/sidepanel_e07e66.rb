#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "08610c9b3718af61aaf0621d2f03ac672a74e808d969f1aa9885c632499512c9", "source_sha256": "e07e663714dd74eaf25d7c73a2e4fae09e726ce450182ddaeb0637ae76e40ad5", "target_language": "ruby"}
# sidepanel.css — portiert nach ruby
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# CSS generation script for sidepanel styles
# This script generates the complete CSS structure programmatically

class CSSGenerator
  def initialize
    @rules = {}
  end

  def add_rule(selector, properties = {})
    @rules[selector] = properties
  end

  def add_nested_rule(parent_selector, child_selector, properties = {})
    full_selector = "#{parent_selector} #{child_selector}"
    @rules[full_selector] = properties
  end

  def generate_css
    css_lines = []
    
    # Root variables
    css_lines << ":root {"
    css_lines << "  color-scheme: light dark;"
    css_lines << "  font-family: Inter, \"Segoe UI\", system-ui, sans-serif;"
    css_lines << "  --accent: #fe2c55;"
    css_lines << "  --accent-dark: #d91f46;"
    css_lines << "  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);"
    css_lines << "  --border: color-mix(in srgb, CanvasText 18%, transparent);"
    css_lines << "  --muted: color-mix(in srgb, CanvasText 65%, transparent);"
    css_lines << "  --good: #147d45;"
    css_lines << "  --warn: #a65f00;"
    css_lines << "  --bad: #b42318;"
    css_lines << "}"
    css_lines << ""

    # Universal rule
    css_lines << "* { box-sizing: border-box; }"
    css_lines << ""

    # Body rule
    css_lines << "body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }"
    css_lines << ""

    # Header rules
    css_lines << "header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }"
    css_lines << ""
    css_lines << "h2 { margin: 0; font-size: 15px; }"
    css_lines << ""

    # Main content rules
    css_lines << "main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }"
    css_lines << ""

    # Section rules
    css_lines << "section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }"
    css_lines << ""

    # Section title and button row
    css_lines << ".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }"
    css_lines << ".section-title { min-width: 0; flex-wrap: wrap; }"
    css_lines << ""

    # Title actions
    css_lines << ".title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }"
    css_lines << ""

    # Status LED rules
    css_lines << ".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }"
    css_lines << ".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }"
    css_lines << ".status-led.off { background: var(--bad); }"
    css_lines << ""

    # Button row
    css_lines << ".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }"
    css_lines << ""

    # Button rules
    css_lines << "button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }"
    css_lines << "button:disabled { cursor: not-allowed; opacity: .55; }"
    css_lines << ".compact { padding: 7px 9px; }"
    css_lines << ".settings-button { min-width: 34px; font-size: 17px; line-height: 1; }"
    css_lines << ".primary { color: white; background: var(--accent); }"
    css_lines << ".primary:hover { background: var(--accent-dark); }"
    css_lines << ".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }"
    css_lines << ".ghost { color: var(--muted); background: transparent; }"
    css_lines << ".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }"
    css_lines << ""

    # Captions button
    css_lines << "#enable-captions { width: 100%; margin-top: 11px; }"
    css_lines << ""

    # Text styles
    css_lines << ".muted { color: var(--muted); }"
    css_lines << ".small { font-size: 12px; line-height: 1.45; }"
    css_lines << ""

    # Page title
    css_lines << "#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }"
    css_lines << ""

    # Status grid
    css_lines << ".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }"
    css_lines << ".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }"
    css_lines << ".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }"
    css_lines << ".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }"
    css_lines << ".good .status-value { color: var(--good); }"
    css_lines << ".warn .status-value { color: var(--warn); }"
    css_lines << ".bad .status-value { color: var(--bad); }"
    css_lines << ""

    # Count elements
    css_lines << ".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }"
    css_lines << ".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer; }"
    css_lines << ".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%, Canvas); }"
    css_lines << ""

    # Live indicator
    css_lines << ".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }"
    css_lines << ".live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }"
    css_lines << ""

    # Stats grid
    css_lines << ".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }"
    css_lines << ""

    # Chat list
    css_lines << ".chat-list { display: grid; gap: 6px; margin-top: 11px; }"
    css_lines << ".chat-list.empty { color: var(--muted); font-size: 12px; }"
    css_lines << ".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }"
    css_lines << ".chat-author { font-weight: 800; }"
    css_lines << ""

    # Player controls
    css_lines << ".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }"
    css_lines << ".player-controls button { width: 100%; }"
    css_lines << ".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }"
    css_lines << ""

    # Audio controls
    css_lines << ".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }"
    css_lines << ".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }"
    css_lines << ".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }"
    css_lines << "input[type=\"range\"] { width: 100%; accent-color: var(--accent); }"
    css_lines << ""

    # Settings grid
    css_lines << ".settings-grid { display: grid; gap: 7px; margin-top: 10px; }"
    css_lines << ".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }"
    css_lines << ".settings-grid label[hidden] { display: none; }"
    css_lines << "input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }"
    css_lines << ""

    # Top chatters
    css_lines << ".top-chatters { display: grid; gap: 6px; margin-top: 8px; }"
    css_lines << ".top-chatters.empty { color: var(--muted); font-size: 12px; }"
    css_lines << ".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }"
    css_lines << ".top-chatters-actions[hidden] { display: none; }"
    css_lines << ".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }"
    css_lines << ".top-chatter-link:hover { text-decoration: underline; }"
    css_lines << ".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }"
    css_lines << ".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }"
    css_lines << ".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }"
    css_lines << ".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }"
    css_lines << ""

    # Recognize song
    css_lines << "#recognize-song { width: 100%; margin-top: 10px; }"
    css_lines << ".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }"
    css_lines << ".song-result strong, .song-result span, .song-result a { display: block; }"
    css_lines << ".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }"
    css_lines << ""

    # Modal backdrop
    css_lines << ".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }"
    css_lines << ".modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }"
    css_lines << ""

    # Lists
    css_lines << ".audience-list, .chat-history-list, .recommendation-list { display: grid; gap: 7px; margin-top: 9px; }"
    css_lines << ".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }"
    css_lines << ".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }"
    css_lines << ".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }"
    css_lines << ".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }"
    css_lines << ".audience-row select { width: auto; max-width: 170px; }"
    css_lines << ".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }"
    css_lines << ""

    # Option rows
    css_lines << ".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }"
    css_lines << ".option-row input { margin: 1px 0 0; accent-color: var(--accent); }"
    css_lines << ".auto-chat-refresh { align-items: center; }"
    css_lines << ".external-speech-trigger-row { align-items: center; }"
    css_lines << ".external-speech-trigger-row label { display: flex; align-items: center; gap: 7px; }"
    css_lines << ".external-speech-trigger-row input[type=\"text\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }"
    css_lines << ".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }"
    css_lines << ".quick-recover-setting input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }"
    css_lines << ".audio-note { margin: 1px 0 0; }"
    css_lines << ""

    # Profile info
    css_lines << ".profile-info { display: grid; gap: 8px; margin-top: 11px; }"
    css_lines << ".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }"
    css_lines << ".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }"
    css_lines << ".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }"
    css_lines << ".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }"
    css_lines << ".profile-stat strong, .profile-stat span { display: block; }"
    css_lines << ".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }"
    css_lines << ""

    # Summary info
    css_lines << ".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }"
    css_lines << ".summary-text { margin: 6px 0 0; white-space: pre-wrap; }"
    css_lines << ""

    # Recommendation controls
    css_lines << ".recommendation-controls { display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px; }"
    css_lines << ".recommendation-controls label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }"
    css_lines << ".recommendation-list.empty { display: block; color: var(--muted); font-size: 12px; }"
    css_lines << ".recommendation-row { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }"
    css_lines << ".recommendation-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }"
    css_lines << ".recommendation-name { min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere; }"
    css_lines << ".recommendation-viewers { flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }"
    css_lines << ".recommendation-description { margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere; }"
    css_lines << ".recommendation-link { display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700; }"
    css_lines << ""

    # Generic list
    css_lines << ".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }"
    css_lines << ".list.empty { display: block; color: var(--muted); font-size: 12px; }"
    css_lines << ".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }"
    css_lines << ".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }"
    css_lines << ".item-title { font-size: 12px; font-weight: 800; }"
    css_lines << ".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }"
    css_lines << ".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }"
    css_lines << ".copy { flex: 0 0 auto; padding: 6px 8px; }"
    css_lines << ".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }"
    css_lines << ""

    # Status and notice elements
    css_lines << ".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }"
    css_lines << ".action-status { line-height: 1.4; }"
    css_lines << ".reset-note { margin: 7px 0 0; }"
    css_lines << ".notice { margin: 0 3px 8px; color: var(--bad); }"
    css_lines << ""

    # Media queries
    css_lines << "@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }"
    css_lines << "@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }"
    css_lines << ""

    # Header controls comment and rules
    css_lines << "/* Header controls remain in one ordered group at the upper right. */"
    css_lines << ".section-title.header-controls { flex-wrap: nowrap; align-items: flex-start; }"
    css_lines << ".header-controls > .title-actions { margin-inline-start: auto; flex-wrap: nowrap; flex-shrink: 0; }"
    css_lines << ".header-controls > .title-actions input[type=\"checkbox\"] { margin: 0; }"
    css_lines << ".connection-status { display: flex; align-items: center; gap: 8px; }"

    css_lines.join("\n")
  end
end

# Generate CSS and write to file if argument provided
if ARGV.length > 0
  generator = CSSGenerator.new
  File.write(ARGV[0], generator.generate_css)
else
  generator = CSSGenerator.new
  puts generator.generate_css
end
