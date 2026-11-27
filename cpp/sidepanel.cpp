// abstraction-provenance: {"artifact_sha256": "ca990551921a101c200024fda9e32ff13b444da5a979e3252899844dec1bcb01", "source_sha256": "e07e663714dd74eaf25d7c73a2e4fae09e726ce450182ddaeb0637ae76e40ad5", "target_language": "cpp"}
// sidepanel.css — portiert nach cpp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void generateCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << " for writing." << std::endl;
        return;
    }

    file << ":root {\n";
    file << "  color-scheme: light dark;\n";
    file << "  font-family: Inter, \"Segoe UI\", system-ui, sans-serif;\n";
    file << "  --accent: #fe2c55;\n";
    file << "  --accent-dark: #d91f46;\n";
    file << "  --surface: color-mix(in srgb, Canvas 94%, CanvasText 6%);\n";
    file << "  --border: color-mix(in srgb, CanvasText 18%, transparent);\n";
    file << "  --muted: color-mix(in srgb, CanvasText 65%, transparent);\n";
    file << "  --good: #147d45;\n";
    file << "  --warn: #a65f00;\n";
    file << "  --bad: #b42318;\n";
    file << "}\n\n";

    file << "* { box-sizing: border-box; }\n";
    file << "body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }\n";
    file << "header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border); }\n";
    file << "h2 { margin: 0; font-size: 15px; }\n";
    file << "main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }\n";
    file << "section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent); }\n";
    file << ".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n";
    file << ".section-title { min-width: 0; flex-wrap: wrap; }\n";
    file << ".title-actions { display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }\n";
    file << ".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }\n";
    file << ".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent); }\n";
    file << ".status-led.off { background: var(--bad); }\n";
    file << ".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }\n";
    file << "button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }\n";
    file << "button:disabled { cursor: not-allowed; opacity: .55; }\n";
    file << ".compact { padding: 7px 9px; }\n";
    file << ".settings-button { min-width: 34px; font-size: 17px; line-height: 1; }\n";
    file << ".primary { color: white; background: var(--accent); }\n";
    file << ".primary:hover { background: var(--accent-dark); }\n";
    file << ".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border); }\n";
    file << ".ghost { color: var(--muted); background: transparent; }\n";
    file << ".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent); }\n";
    file << "#enable-captions { width: 100%; margin-top: 11px; }\n";
    file << ".muted { color: var(--muted); }\n";
    file << ".small { font-size: 12px; line-height: 1.45; }\n";
    file << "#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }\n";
    file << ".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }\n";
    file << ".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n";
    file << ".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }\n";
    file << ".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }\n";
    file << ".good .status-value { color: var(--good); }\n";
    file << ".warn .status-value { color: var(--warn); }\n";
    file << ".bad .status-value { color: var(--bad); }\n";
    file << ".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }\n";
    file << ".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer; }\n";
    file << ".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%, Canvas); }\n";
    file << ".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }\n";
    file << ".live-indicator.active { background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good); }\n";
    file << ".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }\n";
    file << ".chat-list { display: grid; gap: 6px; margin-top: 11px; }\n";
    file << ".chat-list.empty { color: var(--muted); font-size: 12px; }\n";
    file << ".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }\n";
    file << ".chat-author { font-weight: 800; }\n";
    file << ".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }\n";
    file << ".player-controls button { width: 100%; }\n";
    file << ".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }\n";
    file << ".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }\n";
    file << ".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }\n";
    file << ".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }\n";
    file << "input[type=\"range\"] { width: 100%; accent-color: var(--accent); }\n";
    file << ".settings-grid { display: grid; gap: 7px; margin-top: 10px; }\n";
    file << ".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n";
    file << ".settings-grid label[hidden] { display: none; }\n";
    file << "input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select { width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n";
    file << ".top-chatters { display: grid; gap: 6px; margin-top: 8px; }\n";
    file << ".top-chatters.empty { color: var(--muted); font-size: 12px; }\n";
    file << ".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }\n";
    file << ".top-chatters-actions[hidden] { display: none; }\n";
    file << ".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }\n";
    file << ".top-chatter-link:hover { text-decoration: underline; }\n";
    file << ".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n";
    file << ".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }\n";
    file << ".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }\n";
    file << ".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }\n";
    file << "#recognize-song { width: 100%; margin-top: 10px; }\n";
    file << ".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }\n";
    file << ".song-result strong, .song-result span, .song-result a { display: block; }\n";
    file << ".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }\n";
    file << ".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto; }\n";
    file << ".modal { width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }\n";
    file << ".audience-list, .chat-history-list, .recommendation-list { display: grid; gap: 7px; margin-top: 9px; }\n";
    file << ".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }\n";
    file << ".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }\n";
    file << ".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }\n";
    file << ".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n";
    file << ".audience-row select { width: auto; max-width: 170px; }\n";
    file << ".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }\n";
    file << ".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }\n";
    file << ".option-row input { margin: 1px 0 0; accent-color: var(--accent); }\n";
    file << ".auto-chat-refresh { align-items: center; }\n";
    file << ".external-speech-trigger-row { align-items: center; }\n";
    file << ".external-speech-trigger-row label { display: flex; align-items: center; gap: 7px; }\n";
    file << ".external-speech-trigger-row input[type=\"text\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n";
    file << ".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n";
    file << ".quick-recover-setting input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n";
    file << ".audio-note { margin: 1px 0 0; }\n";
    file << ".profile-info { display: grid; gap: 8px; margin-top: 11px; }\n";
    file << ".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }\n";
    file << ".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }\n";
    file << ".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }\n";
    file << ".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n";
    file << ".profile-stat strong, .profile-stat span { display: block; }\n";
    file << ".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }\n";
    file << ".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }\n";
    file << ".summary-text { margin: 6px 0 0; white-space: pre-wrap; }\n";
    file << ".recommendation-controls { display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px; }\n";
    file << ".recommendation-controls label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n";
    file << ".recommendation-list.empty { display: block; color: var(--muted); font-size: 12px; }\n";
    file << ".recommendation-row { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n";
    file << ".recommendation-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }\n";
    file << ".recommendation-name { min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere; }\n";
    file << ".recommendation-viewers { flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }\n";
    file << ".recommendation-description { margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere; }\n";
    file << ".recommendation-link { display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700; }\n";
    file << ".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }\n";
    file << ".list.empty { display: block; color: var(--muted); font-size: 12px; }\n";
    file << ".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n";
    file << ".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n";
    file << ".item-title { font-size: 12px; font-weight: 800; }\n";
    file << ".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }\n";
    file << ".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }\n";
    file << ".copy { flex: 0 0 auto; padding: 6px 8px; }\n";
    file << ".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }\n";
    file << ".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }\n";
    file << ".action-status { line-height: 1.4; }\n";
    file << ".reset-note { margin: 7px 0 0; }\n";
    file << ".notice { margin: 0 3px 8px; color: var(--bad); }\n";
    file << "@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n";
    file << "@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n\n";

    file << "/* Header controls remain in one ordered group at the upper right. */\n";
    file << ".section-title.header-controls { flex-wrap: nowrap; align-items: flex-start; }\n";
    file << ".header-controls > .title-actions { margin-inline-start: auto; flex-wrap: nowrap; flex-shrink: 0; }\n";
    file << ".header-controls > .title-actions input[type=\"checkbox\"] { margin: 0; }\n";
    file << ".connection-status { display: flex; align-items: center; gap: 8px; }\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>" << std::endl;
        return 1;
    }

    generateCSS(argv[1]);
    return 0;
}
