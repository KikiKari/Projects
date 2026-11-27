// abstraction-provenance: {"artifact_sha256": "4e6820202cdf33a6259be56adcdd74973e523654c859a22d06b5ea385c98f33c", "source_sha256": "5e851dbbd6f8a85b568a8bbe7eddf23a83348f89559ecc9a3a4234558ee855d9", "target_language": "c"}
// sidepanel.css — portiert nach c
// Quelle: css, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char* selector;
    char* properties;
} CSSRule;

typedef struct {
    char* variable;
    char* value;
} CSSVariable;

void writeCSSRule(FILE* file, const char* selector, const char* properties) {
    fprintf(file, "%s { %s }\n", selector, properties);
}

void writeCSSVariable(FILE* file, const char* variable, const char* value) {
    fprintf(file, "  %s: %s;\n", variable, value);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output-file>\n", argv[0]);
        return 1;
    }

    FILE* file = fopen(argv[1], "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    // Write CSS header comment
    fprintf(file, "/* Generated CSS file */\n\n");

    // :root variables
    fprintf(file, ":root {\n");
    writeCSSVariable(file, "color-scheme", "light dark");
    writeCSSVariable(file, "font-family", "Inter, \"Segoe UI\", system-ui, sans-serif");
    writeCSSVariable(file, "--accent", "#fe2c55");
    writeCSSVariable(file, "--accent-dark", "#d91f46");
    writeCSSVariable(file, "--surface", "color-mix(in srgb, Canvas 94%%, CanvasText 6%%)");
    writeCSSVariable(file, "--border", "color-mix(in srgb, CanvasText 18%%, transparent)");
    writeCSSVariable(file, "--muted", "color-mix(in srgb, CanvasText 65%%, transparent)");
    writeCSSVariable(file, "--good", "#147d45");
    writeCSSVariable(file, "--warn", "#a65f00");
    writeCSSVariable(file, "--bad", "#b42318");
    fprintf(file, "}\n\n");

    // Universal selector
    writeCSSRule(file, "*", "box-sizing: border-box");

    // Body styles
    writeCSSRule(file, "body", "margin: 0; background: Canvas; color: CanvasText; min-width: 300px");

    // Header styles
    writeCSSRule(file, "header", "padding: 11px 18px; background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas); border-bottom: 1px solid var(--border)");

    // Heading styles
    writeCSSRule(file, "h2", "margin: 0; font-size: 15px");

    // Main content styles
    writeCSSRule(file, "main", "padding: 14px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px");

    // Section styles
    writeCSSRule(file, "section", "min-width: 0; padding: 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 13px; box-shadow: 0 5px 20px color-mix(in srgb, CanvasText 6%, transparent)");

    // Section title and button row styles
    writeCSSRule(file, ".section-title, .button-row", "display: flex; align-items: center; justify-content: space-between; gap: 8px");
    writeCSSRule(file, ".section-title", "min-width: 0; flex-wrap: wrap");
    writeCSSRule(file, ".title-actions", "display: flex; min-width: 0; max-width: 100%; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 6px");

    // Status LED styles
    writeCSSRule(file, ".status-led", "width: 11px; height: 11px; flex: 0 0 11px; border-radius: 50%; background: var(--bad); box-shadow: 0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)");
    writeCSSRule(file, ".status-led.on", "background: var(--good); box-shadow: 0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent)");
    writeCSSRule(file, ".status-led.off", "background: var(--bad)");

    // Button row styles
    writeCSSRule(file, ".button-row", "justify-content: flex-start; flex-wrap: wrap; margin-top: 10px");

    // Button styles
    writeCSSRule(file, "button", "border: 0; border-radius: 9px; padding: 9px 11px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer");
    writeCSSRule(file, "button:disabled", "cursor: not-allowed; opacity: .55");
    writeCSSRule(file, ".compact", "padding: 7px 9px");
    writeCSSRule(file, ".settings-button", "min-width: 34px; font-size: 17px; line-height: 1");
    writeCSSRule(file, ".primary", "color: white; background: var(--accent)");
    writeCSSRule(file, ".primary:hover", "background: var(--accent-dark)");
    writeCSSRule(file, ".secondary", "color: CanvasText; background: color-mix(in srgb, CanvasText 9%, Canvas); border: 1px solid var(--border)");
    writeCSSRule(file, ".ghost", "color: var(--muted); background: transparent");
    writeCSSRule(file, ".danger-outline", "color: var(--bad); border-color: color-mix(in srgb, var(--bad) 45%, transparent)");
    writeCSSRule(file, "#enable-captions", "width: 100%; margin-top: 11px");

    // Text styles
    writeCSSRule(file, ".muted", "color: var(--muted)");
    writeCSSRule(file, ".small", "font-size: 12px; line-height: 1.45");
    writeCSSRule(file, "#page-title", "margin: 0; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis");

    // Status grid styles
    writeCSSRule(file, ".status-grid", "display: grid; grid-template-columns: 1fr 1fr; gap: 7px; margin-top: 11px");
    writeCSSRule(file, ".status", "padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas");
    writeCSSRule(file, ".status-label", "display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em");
    writeCSSRule(file, ".status-value", "display: block; margin-top: 3px; font-size: 12px; font-weight: 750");
    writeCSSRule(file, ".good .status-value", "color: var(--good)");
    writeCSSRule(file, ".warn .status-value", "color: var(--warn)");
    writeCSSRule(file, ".bad .status-value", "color: var(--bad)");

    // Count styles
    writeCSSRule(file, ".count", "min-width: 25px; padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--accent) 15%, Canvas); color: var(--accent); text-align: center; font-size: 11px; font-weight: 800");
    writeCSSRule(file, ".count-button", "border: 1px solid color-mix(in srgb, var(--accent) 30%, transparent); cursor: pointer");
    writeCSSRule(file, ".count-button:hover, .count-button:focus-visible", "background: color-mix(in srgb, var(--accent) 25%, Canvas)");

    // Live indicator styles
    writeCSSRule(file, ".live-indicator", "padding: 3px 7px; border-radius: 999px; background: color-mix(in srgb, var(--muted) 15%, Canvas); color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase");
    writeCSSRule(file, ".live-indicator.active", "background: color-mix(in srgb, var(--good) 16%, Canvas); color: var(--good)");
    writeCSSRule(file, ".stats-grid .status-value", "font-size: 16px; font-variant-numeric: tabular-nums");

    // Chat list styles
    writeCSSRule(file, ".chat-list", "display: grid; gap: 6px; margin-top: 11px");
    writeCSSRule(file, ".chat-list.empty", "color: var(--muted); font-size: 12px");
    writeCSSRule(file, ".chat-line", "margin: 0; padding: 7px 8px; border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--border)); border-radius: 6px; background: Canvas; font-size: 12px; line-height: 1.4; overflow-wrap: anywhere");
    writeCSSRule(file, ".chat-author", "font-weight: 800");

    // Player controls styles
    writeCSSRule(file, ".player-controls", "display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; margin-top: 11px");
    writeCSSRule(file, ".player-controls button", "width: 100%");
    writeCSSRule(file, ".player-time", "font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums");

    // Audio controls styles
    writeCSSRule(file, ".audio-controls", "display: grid; gap: 7px; margin-top: 12px; padding-top: 11px; border-top: 1px solid var(--border)");
    writeCSSRule(file, ".control-label, .audio-meter-row", "display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11px");
    writeCSSRule(file, ".control-label output, .audio-meter-row strong", "font-variant-numeric: tabular-nums");
    writeCSSRule(file, "input[type=\"range\"]", "width: 100%; accent-color: var(--accent)");

    // Settings grid styles
    writeCSSRule(file, ".settings-grid", "display: grid; gap: 7px; margin-top: 10px");
    writeCSSRule(file, ".settings-grid label", "display: grid; gap: 4px; color: var(--muted); font-size: 10px");
    writeCSSRule(file, ".settings-grid label[hidden]", "display: none");
    writeCSSRule(file, "input[type=\"url\"], input[type=\"text\"], input[type=\"password\"], input[type=\"number\"], select", "width: 100%; min-width: 0; padding: 7px 8px; border: 1px solid var(--border); border-radius: 7px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px");

    // Top chatters styles
    writeCSSRule(file, ".top-chatters", "display: grid; gap: 6px; margin-top: 8px");
    writeCSSRule(file, ".top-chatters.empty", "color: var(--muted); font-size: 12px");
    writeCSSRule(file, ".top-chatters-actions", "display: flex; justify-content: flex-end; gap: 9px; margin-top: 7px");
    writeCSSRule(file, ".top-chatters-actions[hidden]", "display: none");
    writeCSSRule(file, ".top-chatter-link", "padding: 0; color: var(--accent); background: transparent; border: 0; border-radius: 0; font-weight: 700");
    writeCSSRule(file, ".top-chatter-link:hover", "text-decoration: underline");

    // Chatter row styles
    writeCSSRule(file, ".chatter-row", "display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: center; gap: 7px; padding: 7px 8px; border: 1px solid var(--border); border-radius: 8px; background: Canvas");
    writeCSSRule(file, ".chatter-name", "min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px; font-weight: 800");
    writeCSSRule(file, ".chatter-metrics", "color: var(--muted); font-size: 10px; white-space: nowrap");
    writeCSSRule(file, ".mute-toggle", "display: flex; align-items: center; gap: 4px; color: var(--muted); font-size: 10px");

    // Song recognition styles
    writeCSSRule(file, "#recognize-song", "width: 100%; margin-top: 10px");
    writeCSSRule(file, ".song-result", "margin-top: 9px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas; font-size: 11px; line-height: 1.45");
    writeCSSRule(file, ".song-result strong, .song-result span, .song-result a", "display: block");
    writeCSSRule(file, ".song-result a", "margin-top: 4px; color: var(--accent); overflow-wrap: anywhere");

    // Modal styles
    writeCSSRule(file, ".modal-backdrop", "position: fixed; inset: 0; z-index: 100; padding: 14px; background: color-mix(in srgb, CanvasText 42%, transparent); overflow: auto");
    writeCSSRule(file, ".modal", "width: min(520px, 100%); max-height: calc(100vh - 28px); margin: 0 auto; overflow: auto; background: Canvas");

    // List styles
    writeCSSRule(file, ".audience-list, .chat-history-list, .recommendation-list", "display: grid; gap: 7px; margin-top: 9px");
    writeCSSRule(file, ".chat-history-row", "padding: 8px 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface); font-size: 11px; line-height: 1.4; overflow-wrap: anywhere");
    writeCSSRule(file, ".chat-history-meta", "display: block; margin-bottom: 3px; color: var(--muted); font-size: 10px");
    writeCSSRule(file, ".audience-row", "display: grid; gap: 6px; padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: var(--surface)");
    writeCSSRule(file, ".audience-row-head", "display: flex; align-items: center; justify-content: space-between; gap: 8px");
    writeCSSRule(file, ".audience-row select", "width: auto; max-width: 170px");
    writeCSSRule(file, ".audience-metrics", "color: var(--muted); font-size: 10px; line-height: 1.45");

    // Option row styles
    writeCSSRule(file, ".option-row", "display: flex; align-items: flex-start; gap: 7px; margin-top: 8px; color: var(--muted); font-size: 11px; line-height: 1.35");
    writeCSSRule(file, ".option-row input", "margin: 1px 0 0; accent-color: var(--accent)");
    writeCSSRule(file, ".auto-chat-refresh", "align-items: center");
    writeCSSRule(file, ".auto-chat-refresh input[type=\"number\"]", "width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px");
    writeCSSRule(file, ".quick-recover-setting input[type=\"number\"]", "width: 48px; margin-left: 3px; padding: 3px 4px; border: 1px solid var(--border); border-radius: 6px; background: Canvas; color: CanvasText; font: inherit; font-size: 11px");
    writeCSSRule(file, ".audio-note", "margin: 1px 0 0");

    // Profile styles
    writeCSSRule(file, ".profile-info", "display: grid; gap: 8px; margin-top: 11px");
    writeCSSRule(file, ".profile-heading", "margin: 0; font-size: 14px; font-weight: 800");
    writeCSSRule(file, ".profile-handle, .profile-bio", "margin: 0; color: var(--muted); font-size: 11px; line-height: 1.45; white-space: pre-wrap");
    writeCSSRule(file, ".profile-stats", "display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px");
    writeCSSRule(file, ".profile-stat", "padding: 7px; border: 1px solid var(--border); border-radius: 8px; background: Canvas");
    writeCSSRule(file, ".profile-stat strong, .profile-stat span", "display: block");
    writeCSSRule(file, ".profile-stat span", "margin-top: 2px; color: var(--muted); font-size: 9px; text-transform: uppercase");

    // Summary styles
    writeCSSRule(file, ".summary-info", "margin-top: 10px; padding-top: 9px; border-top: 1px solid var(--border); font-size: 11px; line-height: 1.45");
    writeCSSRule(file, ".summary-text", "margin: 6px 0 0; white-space: pre-wrap");

    // Recommendation styles
    writeCSSRule(file, ".recommendation-controls", "display: grid; grid-template-columns: minmax(70px, .7fr) minmax(150px, 1.3fr); gap: 8px; margin-top: 10px");
    writeCSSRule(file, ".recommendation-controls label", "display: grid; gap: 4px; color: var(--muted); font-size: 10px");
    writeCSSRule(file, ".recommendation-list.empty", "display: block; color: var(--muted); font-size: 12px");
    writeCSSRule(file, ".recommendation-row", "padding: 9px; border: 1px solid var(--border); border-radius: 9px; background: Canvas");
    writeCSSRule(file, ".recommendation-head", "display: flex; align-items: flex-start; justify-content: space-between; gap: 8px");
    writeCSSRule(file, ".recommendation-name", "min-width: 0; margin: 0; font-size: 11px; font-weight: 800; overflow-wrap: anywhere");
    writeCSSRule(file, ".recommendation-viewers", "flex: 0 0 auto; color: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums");
    writeCSSRule(file, ".recommendation-description", "margin: 5px 0 0; color: var(--muted); font-size: 10px; line-height: 1.4; overflow-wrap: anywhere");
    writeCSSRule(file, ".recommendation-link", "display: inline-block; margin-top: 6px; color: var(--accent); font-size: 11px; font-weight: 700");

    // List styles
    writeCSSRule(file, ".list", "display: grid; gap: 8px; margin-top: 11px; max-height: 300px; overflow: auto");
    writeCSSRule(file, ".list.empty", "display: block; color: var(--muted); font-size: 12px");
    writeCSSRule(file, ".item", "padding: 10px; border: 1px solid var(--border); border-radius: 9px; background: Canvas");
    writeCSSRule(file, ".item-head", "display: flex; align-items: center; justify-content: space-between; gap: 8px");
    writeCSSRule(file, ".item-title", "font-size: 12px; font-weight: 800");
    writeCSSRule(file, ".item-meta, .item-url, .caption-meta", "color: var(--muted); font-size: 10px");
    writeCSSRule(file, ".item-url", "margin-top: 6px; overflow-wrap: anywhere; max-height: 42px; overflow: hidden");
    writeCSSRule(file, ".copy", "flex: 0 0 auto; padding: 6px 8px");
    writeCSSRule(file, ".caption-text", "margin: 5px 0 0; white-space: pre-wrap; font-size: 12px; line-height: 1.4");

    // Status and notice styles
    writeCSSRule(file, ".inline-status, .notice", "min-height: 17px; margin: 9px 0 0; color: var(--muted); font-size: 11px");
    writeCSSRule(file, ".action-status", "line-height: 1.4");
    writeCSSRule(file, ".reset-note", "margin: 7px 0 0");
    writeCSSRule(file, ".notice", "margin: 0 3px 8px; color: var(--bad)");

    // Media queries
    fprintf(file, "@media (min-width: 430px) { .speech-settings { grid-template-columns: 1fr 1fr; } .speech-settings label:first-child { grid-column: 1 / -1; } }\n");
    fprintf(file, "@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }\n");

    fclose(file);
    return 0;
}
