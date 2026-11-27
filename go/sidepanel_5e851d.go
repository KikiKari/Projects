// abstraction-provenance: {"artifact_sha256": "0af3a3311fd4df3039fe8639716a0875068918e36c2480ed2fd3f2f31eef2d55", "source_sha256": "5e851dbbd6f8a85b568a8bbe7eddf23a83348f89559ecc9a3a4234558ee855d9", "target_language": "go"}
// sidepanel.css — portiert nach go
// Quelle: css, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	output := flag.String("output", "sidepanel.css", "Output file path")
	flag.Parse()

	css := generateCSS()
	
	err := os.WriteFile(*output, []byte(css), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
		os.Exit(1)
	}
}

func generateCSS() string {
	var builder strings.Builder
	
	builder.WriteString(":root {\n")
	builder.WriteString("  color-scheme: light dark;\n")
	builder.WriteString("  font-family: Inter, \"Segoe UI\", system-ui, sans-serif;\n")
	builder.WriteString("  --accent: #fe2c55;\n")
	builder.WriteString("  --accent-dark: #d91f46;\n")
	builder.WriteString("  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);\n")
	builder.WriteString("  --border: color-mix(in srgb, CanvasText 18%, transparent);\n")
	builder.WriteString("  --muted: color-mix(in srgb, CanvasText 65%, transparent);\n")
	builder.WriteString("  --good: #147d45;\n")
	builder.WriteString("  --warn: #a65f00;\n")
	builder.WriteString("  --bad: #b42318;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("* { box-sizing: border-box; }\n")
	builder.WriteString("body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }\n")
	builder.WriteString("header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }\n")
	builder.WriteString("h2 { margin: 0; font-size: 15px; }\n")
	builder.WriteString("main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }\n")
	builder.WriteString("section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }\n")
	
	builder.WriteString(".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n")
	builder.WriteString(".section-title { min-width: 0; flex-wrap: wrap; }\n")
	builder.WriteString(".title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }\n")
	
	builder.WriteString(".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }\n")
	builder.WriteString(".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }\n")
	builder.WriteString(".status-led.off { background: var(--bad); }\n")
	
	builder.WriteString(".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }\n")
	builder.WriteString("button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }\n")
	builder.WriteString("button:disabled { cursor: not-allowed; opacity: .55; }\n")
	builder.WriteString(".compact { padding: 7px 9px; }\n")
	builder.WriteString(".settings-button { min-width: 34px; font-size: 17px; line-height: 1; }\n")
	builder.WriteString(".primary { color: white; background: var(--accent); }\n")
	builder.WriteString(".primary:hover { background: var(--accent-dark); }\n")
	builder.WriteString(".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }\n")
	builder.WriteString(".ghost { color: var(--muted); background: transparent; }\n")
	builder.WriteString(".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }\n")
	builder.WriteString("#enable-captions { width: 100%; margin-top: 11px; }\n")
	builder.WriteString(".muted { color: var(--muted); }\n")
	builder.WriteString(".small { font-size: 12px; line-height: 1.45; }\n")
	builder.WriteString("#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }\n")
	
	builder.WriteString(".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }\n")
	builder.WriteString(".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n")
	builder.WriteString(".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }\n")
	builder.WriteString(".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }\n")
	builder.WriteString(".good .status-value { color: var(--good); }\n")
	builder.WriteString(".warn .status-value { color: var(--warn); }\n")
	builder.WriteString(".bad .status-value { color: var(--bad); }\n")
	
	builder.WriteString(".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }\n")
	builder.WriteString(".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer; }\n")
	builder.WriteString(".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%, Canvas); }\n")
	
	builder.WriteString(".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }\n")
	builder.WriteString(".live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }\n")
	builder.WriteString(".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }\n")
	
	builder.WriteString(".chat-list { display: grid; gap: 6px; margin-top: 11px; }\n")
	builder.WriteString(".chat-list.empty { color: var(--muted); font-size: 12px; }\n")
	builder.WriteString(".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }\n")
	builder.WriteString(".chat-author { font-weight: 800; }\n")
	
	builder.WriteString(".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }\n")
	builder.WriteString(".player-controls button { width: 100%; }\n")
	builder.WriteString(".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }\n")
	
	builder.WriteString(".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }\n")
	builder.WriteString(".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }\n")
	builder.WriteString(".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }\n")
	builder.WriteString("input[type=\"range\"] { width: 100%; accent-color: var(--accent); }\n")
	
	builder.WriteString(".settings-grid { display: grid; gap: 7px; margin-top: 10px; }\n")
	builder.WriteString(".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n")
	builder.WriteString(".settings-grid label[hidden] { display: none; }\n")
	builder.WriteString("input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n")
	
	builder.WriteString(".top-chatters { display: grid; gap: 6px; margin-top: 8px; }\n")
	builder.WriteString(".top-chatters.empty { color: var(--muted); font-size: 12px; }\n")
	builder.WriteString(".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }\n")
	builder.WriteString(".top-chatters-actions[hidden] { display: none; }\n")
	builder.WriteString(".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }\n")
	builder.WriteString(".top-chatter-link:hover { text-decoration: underline; }\n")
	builder.WriteString(".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n")
	builder.WriteString(".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }\n")
	builder.WriteString(".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }\n")
	builder.WriteString(".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }\n")
	builder.WriteString("#recognize-song { width: 100%; margin-top: 10px; }\n")
	builder.WriteString(".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }\n")
	builder.WriteString(".song-result strong, .song-result span, .song-result a { display: block; }\n")
	builder.WriteString(".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }\n")
	
	builder.WriteString(".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }\n")
	builder.WriteString(".modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }\n")
	builder.WriteString(".audience-list, .chat-history-list, .recommendation-list { display: grid; gap: 7px; margin-top: 9px; }\n")
	builder.WriteString(".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }\n")
	builder.WriteString(".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }\n")
	builder.WriteString(".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }\n")
	builder.WriteString(".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n")
	builder.WriteString(".audience-row select { width: auto; max-width: 170px; }\n")
	builder.WriteString(".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }\n")
	builder.WriteString(".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }\n")
	builder.WriteString(".option-row input { margin: 1px 0 0; accent-color: var(--accent); }\n")
	builder.WriteString(".auto-chat-refresh { align-items: center; }\n")
	builder.WriteString(".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n")
	builder.WriteString(".quick-recover-setting input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n")
	builder.WriteString(".audio-note { margin: 1px 0 0; }\n")
	
	builder.WriteString(".profile-info { display: grid; gap: 8px; margin-top: 11px; }\n")
	builder.WriteString(".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }\n")
	builder.WriteString(".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }\n")
	builder.WriteString(".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }\n")
	builder.WriteString(".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n")
	builder.WriteString(".profile-stat strong, .profile-stat span { display: block; }\n")
	builder.WriteString(".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }\n")
	builder.WriteString(".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }\n")
	builder.WriteString(".summary-text { margin: 6px 0 0; white-space: pre-wrap; }\n")
	
	builder.WriteString(".recommendation-controls { display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px; }\n")
	builder.WriteString(".recommendation-controls label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n")
	builder.WriteString(".recommendation-list.empty { display: block; color: var(--muted); font-size: 12px; }\n")
	builder.WriteString(".recommendation-row { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n")
	builder.WriteString(".recommendation-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }\n")
	builder.WriteString(".recommendation-name { min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere; }\n")
	builder.WriteString(".recommendation-viewers { flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }\n")
	builder.WriteString(".recommendation-description { margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere; }\n")
	builder.WriteString(".recommendation-link { display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700; }\n")
	
	builder.WriteString(".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }\n")
	builder.WriteString(".list.empty { display: block; color: var(--muted); font-size: 12px; }\n")
	builder.WriteString(".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n")
	builder.WriteString(".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n")
	builder.WriteString(".item-title { font-size: 12px; font-weight: 800; }\n")
	builder.WriteString(".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }\n")
	builder.WriteString(".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }\n")
	builder.WriteString(".copy { flex: 0 0 auto; padding: 6px 8px; }\n")
	builder.WriteString(".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }\n")
	builder.WriteString(".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }\n")
	builder.WriteString(".action-status { line-height: 1.4; }\n")
	builder.WriteString(".reset-note { margin: 7px 0 0; }\n")
	builder.WriteString(".notice { margin: 0 3px 8px; color: var(--bad); }\n")
	
	builder.WriteString("@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n")
	builder.WriteString("@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n")
	
	return builder.String()
}
