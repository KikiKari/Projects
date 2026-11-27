// abstraction-provenance: {"artifact_sha256": "b04140d60d6e09898f2b57161a0e10e656c58dd68bcaf93020a0e81aca53ec2b", "source_sha256": "e07e663714dd74eaf25d7c73a2e4fae09e726ce450182ddaeb0637ae76e40ad5", "target_language": "c"}
// sidepanel.css — portiert nach c
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_to_file(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    // Write CSS content
    fprintf(file, ":root {\n");
    fprintf(file, "  color-scheme: light dark;\n");
    fprintf(file, "  font-family: Inter, \"Segoe UI\", system-ui, sans-serif;\n");
    fprintf(file, "  --accent: #fe2c55;\n");
    fprintf(file, "  --accent-dark: #d91f46;\n");
    fprintf(file, "  --surface: color-mix(in srgb, Canvas 94%%, CanvasText 6%%);\n");
    fprintf(file, "  --border: color-mix(in srgb, CanvasText 18%%, transparent);\n");
    fprintf(file, "  --muted: color-mix(in srgb, CanvasText 65%%, transparent);\n");
    fprintf(file, "  --good: #147d45;\n");
    fprintf(file, "  --warn: #a65f00;\n");
    fprintf(file, "  --bad: #b42318;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "* { box-sizing: border-box; }\n");
    fprintf(file, "body { margin: 0; background: Canvas; color: CanvasText; min-width: 300px; }\n");
    fprintf(file, "header { padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%%, Canvas), Canvas); border-bottom: 1px solid var(--border); }\n");
    fprintf(file, "h2 { margin: 0; font-size: 15px; }\n");
    fprintf(file, "main { padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }\n");
    fprintf(file, "section { min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%%, transparent); }\n");
    fprintf(file, ".section-title, .button-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n");
    fprintf(file, ".section-title { min-width: 0; flex-wrap: wrap; }\n");
    fprintf(file, ".title-actions { display: flex; min-width: 0; max-width: 100%%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px; }\n");
    fprintf(file, ".status-led { width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%%, transparent); }\n");
    fprintf(file, ".status-led.on { background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%%, transparent); }\n");
    fprintf(file, ".status-led.off { background: var(--bad); }\n");
    fprintf(file, ".button-row { justify-content: flex-start; flex-wrap: wrap; margin-top: 10px; }\n");
    fprintf(file, "button { border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }\n");
    fprintf(file, "button:disabled { cursor: not-allowed; opacity: .55; }\n");
    fprintf(file, ".compact { padding: 7px 9px; }\n");
    fprintf(file, ".settings-button { min-width: 34px; font-size: 17px; line-height: 1; }\n");
    fprintf(file, ".primary { color: white; background: var(--accent); }\n");
    fprintf(file, ".primary:hover { background: var(--accent-dark); }\n");
    fprintf(file, ".secondary { color: CanvasText; background: color-mix(in srgb, CanvasText 9%%, Canvas); border: 1px solid var(--border); }\n");
    fprintf(file, ".ghost { color: var(--muted); background: transparent; }\n");
    fprintf(file, ".danger-outline { color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%%, transparent); }\n");
    fprintf(file, "#enable-captions { width: 100%%; margin-top: 11px; }\n");
    fprintf(file, ".muted { color: var(--muted); }\n");
    fprintf(file, ".small { font-size: 12px; line-height: 1.45; }\n");
    fprintf(file, "#page-title { margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }\n");
    fprintf(file, ".status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px; }\n");
    fprintf(file, ".status { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n");
    fprintf(file, ".status-label { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; }\n");
    fprintf(file, ".status-value { display: block; margin-top: 3px; font-size: 12px; font-weight: 750; }\n");
    fprintf(file, ".good .status-value { color: var(--good); }\n");
    fprintf(file, ".warn .status-value { color: var(--warn); }\n");
    fprintf(file, ".bad .status-value { color: var(--bad); }\n");
    fprintf(file, ".count { min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800; }\n");
    fprintf(file, ".count-button { border: 1px solid color-mix(in srgb, var(--accent) 30%%, transparent); cursor: pointer; }\n");
    fprintf(file, ".count-button:hover, .count-button:focus-visible { background: color-mix(in srgb, var(--accent) 25%%, Canvas); }\n");
    fprintf(file, ".live-indicator { padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }\n");
    fprintf(file, ".live-indicator.active { background: color-mix(in srgb, var(--good) 16%%, Canvas); color: var(--good); }\n");
    fprintf(file, ".stats-grid .status-value { font-size: 16px; font-variant-numeric: tabular-nums; }\n");
    fprintf(file, ".chat-list { display: grid; gap: 6px; margin-top: 11px; }\n");
    fprintf(file, ".chat-list.empty { color: var(--muted); font-size: 12px; }\n");
    fprintf(file, ".chat-line { margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere; }\n");
    fprintf(file, ".chat-author { font-weight: 800; }\n");
    fprintf(file, ".player-controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px; }\n");
    fprintf(file, ".player-controls button { width: 100%%; }\n");
    fprintf(file, ".player-time { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }\n");
    fprintf(file, ".audio-controls { display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border); }\n");
    fprintf(file, ".control-label, .audio-meter-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px; }\n");
    fprintf(file, ".control-label output, .audio-meter-row strong { font-variant-numeric: tabular-nums; }\n");
    fprintf(file, "input[type=\"range\"] { width: 100%%; accent-color: var(--accent); }\n");
    fprintf(file, ".settings-grid { display: grid; gap: 7px; margin-top: 10px; }\n");
    fprintf(file, ".settings-grid label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n");
    fprintf(file, ".settings-grid label[hidden] { display: none; }\n");
    fprintf(file, "input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select { width: 100%%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n");
    fprintf(file, ".top-chatters { display: grid; gap: 6px; margin-top: 8px; }\n");
    fprintf(file, ".top-chatters.empty { color: var(--muted); font-size: 12px; }\n");
    fprintf(file, ".top-chatters-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px; }\n");
    fprintf(file, ".top-chatters-actions[hidden] { display: none; }\n");
    fprintf(file, ".top-chatter-link { padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700; }\n");
    fprintf(file, ".top-chatter-link:hover { text-decoration: underline; }\n");
    fprintf(file, ".chatter-row { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n");
    fprintf(file, ".chatter-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800; }\n");
    fprintf(file, ".chatter-metrics { color: var(--muted); font-size: 10px; white-space: nowrap; }\n");
    fprintf(file, ".mute-toggle { display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px; }\n");
    fprintf(file, "#recognize-song { width: 100%%; margin-top: 10px; }\n");
    fprintf(file, ".song-result { margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45; }\n");
    fprintf(file, ".song-result strong, .song-result span, .song-result a { display: block; }\n");
    fprintf(file, ".song-result a { margin-top: 4px; color: var(--accent); overflow-wrap: anywhere; }\n");
    fprintf(file, ".modal-backdrop { position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%%, transparent); overflow: auto; }\n");
    fprintf(file, ".modal { width: min(520px, 100%%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas; }\n");
    fprintf(file, ".audience-list, .chat-history-list, .recommendation-list { display: grid; gap: 7px; margin-top: 9px; }\n");
    fprintf(file, ".chat-history-row { padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere; }\n");
    fprintf(file, ".chat-history-meta { display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px; }\n");
    fprintf(file, ".audience-row { display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); }\n");
    fprintf(file, ".audience-row-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n");
    fprintf(file, ".audience-row select { width: auto; max-width: 170px; }\n");
    fprintf(file, ".audience-metrics { color: var(--muted); font-size: 10px; line-height: 1.45; }\n");
    fprintf(file, ".option-row { display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35; }\n");
    fprintf(file, ".option-row input { margin: 1px 0 0; accent-color: var(--accent); }\n");
    fprintf(file, ".auto-chat-refresh { align-items: center; }\n");
    fprintf(file, ".external-speech-trigger-row { align-items: center; }\n");
    fprintf(file, ".external-speech-trigger-row label { display: flex; align-items: center; gap: 7px; }\n");
    fprintf(file, ".external-speech-trigger-row input[type=\"text\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n");
    fprintf(file, ".auto-chat-refresh input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n");
    fprintf(file, ".quick-recover-setting input[type=\"number\"] { width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px; }\n");
    fprintf(file, ".audio-note { margin: 1px 0 0; }\n");
    fprintf(file, ".profile-info { display: grid; gap: 8px; margin-top: 11px; }\n");
    fprintf(file, ".profile-heading { margin: 0; font-size: 14px; font-weight: 800; }\n");
    fprintf(file, ".profile-handle, .profile-bio { margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap; }\n");
    fprintf(file, ".profile-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }\n");
    fprintf(file, ".profile-stat { padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas; }\n");
    fprintf(file, ".profile-stat strong, .profile-stat span { display: block; }\n");
    fprintf(file, ".profile-stat span { margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase; }\n");
    fprintf(file, ".summary-info { margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45; }\n");
    fprintf(file, ".summary-text { margin: 6px 0 0; white-space: pre-wrap; }\n");
    fprintf(file, ".recommendation-controls { display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px; }\n");
    fprintf(file, ".recommendation-controls label { display: grid; gap: 4px; color: var(--muted); font-size: 10px; }\n");
    fprintf(file, ".recommendation-list.empty { display: block; color: var(--muted); font-size: 12px; }\n");
    fprintf(file, ".recommendation-row { padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n");
    fprintf(file, ".recommendation-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }\n");
    fprintf(file, ".recommendation-name { min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere; }\n");
    fprintf(file, ".recommendation-viewers { flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }\n");
    fprintf(file, ".recommendation-description { margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere; }\n");
    fprintf(file, ".recommendation-link { display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700; }\n");
    fprintf(file, ".list { display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto; }\n");
    fprintf(file, ".list.empty { display: block; color: var(--muted); font-size: 12px; }\n");
    fprintf(file, ".item { padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; }\n");
    fprintf(file, ".item-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }\n");
    fprintf(file, ".item-title { font-size: 12px; font-weight: 800; }\n");
    fprintf(file, ".item-meta, .item-url, .caption-meta { color: var(--muted); font-size: 10px; }\n");
    fprintf(file, ".item-url { margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden; }\n");
    fprintf(file, ".copy { flex: 0 0 auto; padding: 6px 8px; }\n");
    fprintf(file, ".caption-text { margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4; }\n");
    fprintf(file, ".inline-status, .notice { min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px; }\n");
    fprintf(file, ".action-status { line-height: 1.4; }\n");
    fprintf(file, ".reset-note { margin: 7px 0 0; }\n");
    fprintf(file, ".notice { margin: 0 3px 8px; color: var(--bad); }\n");
    fprintf(file, "@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n");
    fprintf(file, "@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n\n");

    fprintf(file, "/* Header controls remain in one ordered group at the upper right. */\n");
    fprintf(file, ".section-title.header-controls { flex-wrap: nowrap; align-items: flex-start; }\n");
    fprintf(file, ".header-controls > .title-actions { margin-inline-start: auto; flex-wrap: nowrap; flex-shrink: 0; }\n");
    fprintf(file, ".header-controls > .title-actions input[type=\"checkbox\"] { margin: 0; }\n");
    fprintf(file, ".connection-status { display: flex; align-items: center; gap: 8px; }\n");

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_to_file(argv[1]);
    return 0;
}
