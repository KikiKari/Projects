// abstraction-provenance: {"artifact_sha256": "496be580d6e4574a16fa349cc3c6fed9e52e4917774c73d3c0ab285bb96d4fd4", "source_sha256": "5e851dbbd6f8a85b568a8bbe7eddf23a83348f89559ecc9a3a4234558ee855d9", "target_language": "java"}
// sidepanel.css — portiert nach java
// Quelle: css, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class SidePanelCSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Bitte geben Sie den Pfad zur Ausgabedatei an.");
            System.exit(1);
        }
        
        String outputPath = args[0];
        generateCSS(outputPath);
    }

    private static void generateCSS(String outputPath) {
        StringBuilder css = new StringBuilder();
        
        // Root styles
        css.append(":root {\n");
        css.append("  color-scheme: light dark;\n");
        css.append("  font-family: Inter, \"Segoe UI\", system-ui, sans-serif;\n");
        css.append("  --accent: #fe2c55;\n");
        css.append("  --accent-dark: #d91f46;\n");
        css.append("  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);\n");
        css.append("  --border: color-mix(in srgb, CanvasText 18%, transparent);\n");
        css.append("  --muted: color-mix(in srgb, CanvasText 65%, transparent);\n");
        css.append("  --good: #147d45;\n");
        css.append("  --warn: #a65f00;\n");
        css.append("  --bad: #b42318;\n");
        css.append("}\n\n");
        
        // Universal selector
        css.append("* { box-sizing: border-box; }\n\n");
        
        // Body styles
        css.append("body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }\n\n");
        
        // Header styles
        css.append("header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }\n\n");
        
        // Heading styles
        css.append("h2 { margin: 0; font-size: 15px; }\n\n");
        
        // Main content styles
        css.append("main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }\n\n");
        
        // Section styles
        css.append("section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }\n\n");
        
        // Section title and button row styles
        css.append(".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n\n");
        css.append(".section-title { min-width: 0; flex-wrap: wrap; }\n\n");
        
        // Title actions styles
        css.append(".title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }\n\n");
        
        // Status LED styles
        css.append(".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }\n\n");
        css.append(".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }\n\n");
        css.append(".status-led.off { background: var(--bad); }\n\n");
        
        // Button row styles
        css.append(".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }\n\n");
        
        // Button styles
        css.append("button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }\n\n");
        css.append("button:disabled { cursor: not-allowed; opacity: .55; }\n\n");
        css.append(".compact { padding: 7px 9px; }\n\n");
        css.append(".settings-button { min-width: 34px; font-size: 17px; line-height: 1; }\n\n");
        css.append(".primary { color: white; background: var(--accent); }\n\n");
        css.append(".primary:hover { background: var(--accent-dark); }\n\n");
        css.append(".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }\n\n");
        css.append(".ghost { color: var(--muted); background: transparent; }\n\n");
        css.append(".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }\n\n");
        
        // Enable captions styles
        css.append("#enable-captions { width: 100%; margin-top: 11px; }\n\n");
        
        // Text styles
        css.append(".muted { color: var(--muted); }\n\n");
        css.append(".small { font-size: 12px; line-height: 1.45; }\n\n");
        
        // Page title styles
        css.append("#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }\n\n");
        
        // Status grid styles
        css.append(".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }\n\n");
        css.append(".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n\n");
        css.append(".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }\n\n");
        css.append(".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }\n\n");
        css.append(".good .status-value { color: var(--good); }\n\n");
        css.append(".warn .status-value { color: var(--warn); }\n\n");
        css.append(".bad .status-value { color: var(--bad); }\n\n");
        
        // Count styles
        css.append(".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }\n\n");
        css.append(".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer; }\n\n");
        css.append(".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%, Canvas); }\n\n");
        
        // Live indicator styles
        css.append(".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }\n\n");
        css.append(".live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }\n\n");
        
        // Stats grid styles
        css.append(".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }\n\n");
        
        // Chat list styles
        css.append(".chat-list { display: grid; gap: 6px; margin-top: 11px; }\n\n");
        css.append(".chat-list.empty { color: var(--muted); font-size: 12px; }\n\n");
        css.append(".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }\n\n");
        css.append(".chat-author { font-weight: 800; }\n\n");
        
        // Player controls styles
        css.append(".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }\n\n");
        css.append(".player-controls button { width: 100%; }\n\n");
        css.append(".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }\n\n");
        
        // Audio controls styles
        css.append(".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }\n\n");
        css.append(".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }\n\n");
        css.append(".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }\n\n");
        css.append("input[type=\"range\"] { width: 100%; accent-color: var(--accent); }\n\n");
        
        // Settings grid styles
        css.append(".settings-grid { display: grid; gap: 7px; margin-top: 10px; }\n\n");
        css.append(".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n\n");
        css.append(".settings-grid label[hidden] { display: none; }\n\n");
        
        // Input styles
        css.append("input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n\n");
        
        // Top chatters styles
        css.append(".top-chatters { display: grid; gap: 6px; margin-top: 8px; }\n\n");
        css.append(".top-chatters.empty { color: var(--muted); font-size: 12px; }\n\n");
        css.append(".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }\n\n");
        css.append(".top-chatters-actions[hidden] { display: none; }\n\n");
        css.append(".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }\n\n");
        css.append(".top-chatter-link:hover { text-decoration: underline; }\n\n");
        css.append(".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n\n");
        css.append(".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }\n\n");
        css.append(".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }\n\n");
        css.append(".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }\n\n");
        
        // Recognize song styles
        css.append("#recognize-song { width: 100%; margin-top: 10px; }\n\n");
        css.append(".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }\n\n");
        css.append(".song-result strong, .song-result span, .song-result a { display: block; }\n\n");
        css.append(".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }\n\n");
        
        // Modal styles
        css.append(".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }\n\n");
        css.append(".modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }\n\n");
        
        // List styles
        css.append(".audience-list, .chat-history-list, .recommendation-list { display: grid; gap: 7px; margin-top: 9px; }\n\n");
        css.append(".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }\n\n");
        css.append(".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }\n\n");
        css.append(".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }\n\n");
        css.append(".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n\n");
        css.append(".audience-row select { width: auto; max-width: 170px; }\n\n");
        css.append(".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }\n\n");
        
        // Option row styles
        css.append(".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }\n\n");
        css.append(".option-row input { margin: 1px 0 0; accent-color: var(--accent); }\n\n");
        css.append(".auto-chat-refresh { align-items: center; }\n\n");
        css.append(".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n\n");
        css.append(".quick-recover-setting input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n\n");
        css.append(".audio-note { margin: 1px 0 0; }\n\n");
        
        // Profile info styles
        css.append(".profile-info { display: grid; gap: 8px; margin-top: 11px; }\n\n");
        css.append(".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }\n\n");
        css.append(".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }\n\n");
        css.append(".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }\n\n");
        css.append(".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n\n");
        css.append(".profile-stat strong, .profile-stat span { display: block; }\n\n");
        css.append(".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }\n\n");
        
        // Summary info styles
        css.append(".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }\n\n");
        css.append(".summary-text { margin: 6px 0 0; white-space: pre-wrap; }\n\n");
        
        // Recommendation controls styles
        css.append(".recommendation-controls { display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px; }\n\n");
        css.append(".recommendation-controls label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n\n");
        css.append(".recommendation-list.empty { display: block; color: var(--muted); font-size: 12px; }\n\n");
        css.append(".recommendation-row { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n\n");
        css.append(".recommendation-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }\n\n");
        css.append(".recommendation-name { min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere; }\n\n");
        css.append(".recommendation-viewers { flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }\n\n");
        css.append(".recommendation-description { margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere; }\n\n");
        css.append(".recommendation-link { display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700; }\n\n");
        
        // List styles
        css.append(".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }\n\n");
        css.append(".list.empty { display: block; color: var(--muted); font-size: 12px; }\n\n");
        css.append(".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n\n");
        css.append(".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n\n");
        css.append(".item-title { font-size: 12px; font-weight: 800; }\n\n");
        css.append(".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }\n\n");
        css.append(".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }\n\n");
        css.append(".copy { flex: 0 0 auto; padding: 6px 8px; }\n\n");
        css.append(".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }\n\n");
        
        // Inline status and notice styles
        css.append(".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }\n\n");
        css.append(".action-status { line-height: 1.4; }\n\n");
        css.append(".reset-note { margin: 7px 0 0; }\n\n");
        css.append(".notice { margin: 0 3px 8px; color: var(--bad); }\n\n");
        
        // Media queries
        css.append("@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n\n");
        css.append("@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n");
        
        try {
            Files.write(Paths.get(outputPath), css.toString().getBytes());
            System.out.println("CSS file successfully generated at: " + outputPath);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
