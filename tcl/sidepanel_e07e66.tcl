#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "394349335625e4180da33dfd04866d3379b5b9eb3625a91c6f2fd15124d4d8fd", "source_sha256": "e07e663714dd74eaf25d7c73a2e4fae09e726ce450182ddaeb0637ae76e40ad5", "target_language": "tcl"}
# sidepanel.css — portiert nach tcl
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# sidepanel.tcl - Generates sidepanel.css from structured data
#
# This script builds the CSS by defining each rule as a dictionary of properties,
# then serializing them into valid CSS syntax. The result is written to a file
# specified by the first command-line argument.

proc write_css {filename} {
    set rules [list]

    # Root variables and global styles
    lappend rules ":root" {
        color-scheme "light dark"
        font-family {Inter, "Segoe UI", system-ui, sans-serif}
        --accent "#fe2c55"
        --accent-dark "#d91f46"
        --surface {color-mix(in srgb, Canvas 94%, CanvasText 6%)}
        --border {color-mix(in srgb, CanvasText 18%, transparent)}
        --muted {color-mix(in srgb, CanvasText 65%, transparent)}
        --good "#147d45"
        --warn "#a65f00"
        --bad "#b42318"
    }
    lappend rules "*" {
        box-sizing "border-box"
    }
    lappend rules "body" {
        margin "0"
        background "Canvas"
        color "CanvasText"
        min-width "300px"
    }
    lappend rules "header" {
        padding "11px 18px"
        background {linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas)}
        border-bottom "1px solid var(--border)"
    }
    lappend rules "h2" {
        margin "0"
        font-size "15px"
    }
    lappend rules "main" {
        padding "14px"
        display "grid"
        grid-template-columns "minmax(0, 1fr)"
        gap "12px"
    }
    lappend rules "section" {
        min-width "0"
        padding "14px"
        background "var(--surface)"
        border "1px solid var(--border)"
        border-radius "13px"
        box-shadow {0 5px 20px color-mix(in srgb, CanvasText 6%, transparent)}
    }
    lappend rules ".section-title, .button-row" {
        display "flex"
        align-items "center"
        justify-content "space-between"
        gap "8px"
    }
    lappend rules ".section-title" {
        min-width "0"
        flex-wrap "wrap"
    }
    lappend rules ".title-actions" {
        display "flex"
        min-width "0"
        max-width "100%"
        align-items "center"
        justify-content "flex-end"
        flex-wrap "wrap"
        gap "6px"
    }
    lappend rules ".status-led" {
        width "11px"
        height "11px"
        flex "0 0 11px"
        border-radius "50%"
        background "var(--bad)"
        box-shadow {0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)}
    }
    lappend rules ".status-led.on" {
        background "var(--good)"
        box-shadow {0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent)}
    }
    lappend rules ".status-led.off" {
        background "var(--bad)"
    }
    lappend rules ".button-row" {
        justify-content "flex-start"
        flex-wrap "wrap"
        margin-top "10px"
    }
    lappend rules "button" {
        border "0"
        border-radius "9px"
        padding "9px 11px"
        font "inherit"
        font-size "12px"
        font-weight "700"
        cursor "pointer"
    }
    lappend rules "button:disabled" {
        cursor "not-allowed"
        opacity ".55"
    }
    lappend rules ".compact" {
        padding "7px 9px"
    }
    lappend rules ".settings-button" {
        min-width "34px"
        font-size "17px"
        line-height "1"
    }
    lappend rules ".primary" {
        color "white"
        background "var(--accent)"
    }
    lappend rules ".primary:hover" {
        background "var(--accent-dark)"
    }
    lappend rules ".secondary" {
        color "CanvasText"
        background {color-mix(in srgb, CanvasText 9%, Canvas)}
        border "1px solid var(--border)"
    }
    lappend rules ".ghost" {
        color "var(--muted)"
        background "transparent"
    }
    lappend rules ".danger-outline" {
        color "var(--bad)"
        border-color {color-mix(in srgb, var(--bad) 45%, transparent)}
    }
    lappend rules "#enable-captions" {
        width "100%"
        margin-top "11px"
    }
    lappend rules ".muted" {
        color "var(--muted)"
    }
    lappend rules ".small" {
        font-size "12px"
        line-height "1.45"
    }
    lappend rules "#page-title" {
        margin "0"
        font-size "12px"
        white-space "nowrap"
        overflow "hidden"
        text-overflow "ellipsis"
    }
    lappend rules ".status-grid" {
        display "grid"
        grid-template-columns "1fr 1fr"
        gap "7px"
        margin-top "11px"
    }
    lappend rules ".status" {
        padding "9px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "Canvas"
    }
    lappend rules ".status-label" {
        display "block"
        color "var(--muted)"
        font-size "10px"
        text-transform "uppercase"
        letter-spacing ".06em"
    }
    lappend rules ".status-value" {
        display "block"
        margin-top "3px"
        font-size "12px"
        font-weight "750"
    }
    lappend rules ".good .status-value" {
        color "var(--good)"
    }
    lappend rules ".warn .status-value" {
        color "var(--warn)"
    }
    lappend rules ".bad .status-value" {
        color "var(--bad)"
    }
    lappend rules ".count" {
        min-width "25px"
        padding "3px 7px"
        border-radius "999px"
        background {color-mix(in srgb, var(--accent) 15%, Canvas)}
        color "var(--accent)"
        text-align "center"
        font-size "11px"
        font-weight "800"
    }
    lappend rules ".count-button" {
        border {1px solid color-mix(in srgb, var(--accent) 30%, transparent)}
        cursor "pointer"
    }
    lappend rules ".count-button:hover, .count-button:focus-visible" {
        background {color-mix(in srgb, var(--accent) 25%, Canvas)}
    }
    lappend rules ".live-indicator" {
        padding "3px 7px"
        border-radius "999px"
        background {color-mix(in srgb, var(--muted) 15%, Canvas)}
        color "var(--muted)"
        font-size "10px"
        font-weight "800"
        text-transform "uppercase"
    }
    lappend rules ".live-indicator.active" {
        background {color-mix(in srgb, var(--good) 16%, Canvas)}
        color "var(--good)"
    }
    lappend rules ".stats-grid .status-value" {
        font-size "16px"
        font-variant-numeric "tabular-nums"
    }
    lappend rules ".chat-list" {
        display "grid"
        gap "6px"
        margin-top "11px"
    }
    lappend rules ".chat-list.empty" {
        color "var(--muted)"
        font-size "12px"
    }
    lappend rules ".chat-line" {
        margin "0"
        padding "7px 8px"
        border-left {3px solid color-mix(in srgb, var(--accent) 45%, var(--border))}
        border-radius "6px"
        background "Canvas"
        font-size "12px"
        line-height "1.4"
        overflow-wrap "anywhere"
    }
    lappend rules ".chat-author" {
        font-weight "800"
    }
    lappend rules ".player-controls" {
        display "grid"
        grid-template-columns "repeat(2, minmax(0, 1fr))"
        gap "7px"
        margin-top "11px"
    }
    lappend rules ".player-controls button" {
        width "100%"
    }
    lappend rules ".player-time" {
        font-size "13px"
        font-weight "800"
        font-variant-numeric "tabular-nums"
    }
    lappend rules ".audio-controls" {
        display "grid"
        gap "7px"
        margin-top "12px"
        padding-top "11px"
        border-top "1px solid var(--border)"
    }
    lappend rules ".control-label, .audio-meter-row" {
        display "flex"
        align-items "center"
        justify-content "space-between"
        gap "8px"
        font-size "11px"
    }
    lappend rules ".control-label output, .audio-meter-row strong" {
        font-variant-numeric "tabular-nums"
    }
    lappend rules {input[type="range"]} {
        width "100%"
        accent-color "var(--accent)"
    }
    lappend rules ".settings-grid" {
        display "grid"
        gap "7px"
        margin-top "10px"
    }
    lappend rules ".settings-grid label" {
        display "grid"
        gap "4px"
        color "var(--muted)"
        font-size "10px"
    }
    lappend rules ".settings-grid label[hidden]" {
        display "none"
    }
    lappend rules {input[type="url"], input[type="text"], input[type="password"], input[type="number"], select} {
        width "100%"
        min-width "0"
        padding "7px 8px"
        border "1px solid var(--border)"
        border-radius "7px"
        background "Canvas"
        color "CanvasText"
        font "inherit"
        font-size "11px"
    }
    lappend rules ".top-chatters" {
        display "grid"
        gap "6px"
        margin-top "8px"
    }
    lappend rules ".top-chatters.empty" {
        color "var(--muted)"
        font-size "12px"
    }
    lappend rules ".top-chatters-actions" {
        display "flex"
        justify-content "flex-end"
        gap "9px"
        margin-top "7px"
    }
    lappend rules ".top-chatters-actions[hidden]" {
        display "none"
    }
    lappend rules ".top-chatter-link" {
        padding "0"
        color "var(--accent)"
        background "transparent"
        border "0"
        border-radius "0"
        font-weight "700"
    }
    lappend rules ".top-chatter-link:hover" {
        text-decoration "underline"
    }
    lappend rules ".chatter-row" {
        display "grid"
        grid-template-columns "minmax(0, 1fr) auto auto"
        align-items "center"
        gap "7px"
        padding "7px 8px"
        border "1px solid var(--border)"
        border-radius "8px"
        background "Canvas"
    }
    lappend rules ".chatter-name" {
        min-width "0"
        overflow "hidden"
        text-overflow "ellipsis"
        white-space "nowrap"
        font-size "11px"
        font-weight "800"
    }
    lappend rules ".chatter-metrics" {
        color "var(--muted)"
        font-size "10px"
        white-space "nowrap"
    }
    lappend rules ".mute-toggle" {
        display "flex"
        align-items "center"
        gap "4px"
        color "var(--muted)"
        font-size "10px"
    }
    lappend rules "#recognize-song" {
        width "100%"
        margin-top "10px"
    }
    lappend rules ".song-result" {
        margin-top "9px"
        padding "9px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "Canvas"
        font-size "11px"
        line-height "1.45"
    }
    lappend rules ".song-result strong, .song-result span, .song-result a" {
        display "block"
    }
    lappend rules ".song-result a" {
        margin-top "4px"
        color "var(--accent)"
        overflow-wrap "anywhere"
    }
    lappend rules ".modal-backdrop" {
        position "fixed"
        inset "0"
        z-index "100"
        padding "14px"
        background {color-mix(in srgb, CanvasText 42%, transparent)}
        overflow "auto"
    }
    lappend rules ".modal" {
        width "min(520px, 100%)"
        max-height "calc(100vh - 28px)"
        margin "0 auto"
        overflow "auto"
        background "Canvas"
    }
    lappend rules ".audience-list, .chat-history-list, .recommendation-list" {
        display "grid"
        gap "7px"
        margin-top "9px"
    }
    lappend rules ".chat-history-row" {
        padding "8px 9px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "var(--surface)"
        font-size "11px"
        line-height "1.4"
        overflow-wrap "anywhere"
    }
    lappend rules ".chat-history-meta" {
        display "block"
        margin-bottom "3px"
        color "var(--muted)"
        font-size "10px"
    }
    lappend rules ".audience-row" {
        display "grid"
        gap "6px"
        padding "9px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "var(--surface)"
    }
    lappend rules ".audience-row-head" {
        display "flex"
        align-items "center"
        justify-content "space-between"
        gap "8px"
    }
    lappend rules ".audience-row select" {
        width "auto"
        max-width "170px"
    }
    lappend rules ".audience-metrics" {
        color "var(--muted)"
        font-size "10px"
        line-height "1.45"
    }
    lappend rules ".option-row" {
        display "flex"
        align-items "flex-start"
        gap "7px"
        margin-top "8px"
        color "var(--muted)"
        font-size "11px"
        line-height "1.35"
    }
    lappend rules ".option-row input" {
        margin "1px 0 0"
        accent-color "var(--accent)"
    }
    lappend rules ".auto-chat-refresh" {
        align-items "center"
    }
    lappend rules ".external-speech-trigger-row" {
        align-items "center"
    }
    lappend rules ".external-speech-trigger-row label" {
        display "flex"
        align-items "center"
        gap "7px"
    }
    lappend rules ".external-speech-trigger-row input[type=\"text\"]" {
        width "48px"
        margin-left "3px"
        padding "3px 4px"
        border "1px solid var(--border)"
        border-radius "6px"
        background "Canvas"
        color "CanvasText"
        font "inherit"
        font-size "11px"
    }
    lappend rules ".auto-chat-refresh input[type=\"number\"]" {
        width "48px"
        margin-left "3px"
        padding "3px 4px"
        border "1px solid var(--border)"
        border-radius "6px"
        background "Canvas"
        color "CanvasText"
        font "inherit"
        font-size "11px"
    }
    lappend rules ".quick-recover-setting input[type=\"number\"]" {
        width "48px"
        margin-left "3px"
        padding "3px 4px"
        border "1px solid var(--border)"
        border-radius "6px"
        background "Canvas"
        color "CanvasText"
        font "inherit"
        font-size "11px"
    }
    lappend rules ".audio-note" {
        margin "1px 0 0"
    }
    lappend rules ".profile-info" {
        display "grid"
        gap "8px"
        margin-top "11px"
    }
    lappend rules ".profile-heading" {
        margin "0"
        font-size "14px"
        font-weight "800"
    }
    lappend rules ".profile-handle, .profile-bio" {
        margin "0"
        color "var(--muted)"
        font-size "11px"
        line-height "1.45"
        white-space "pre-wrap"
    }
    lappend rules ".profile-stats" {
        display "grid"
        grid-template-columns "repeat(3, minmax(0, 1fr))"
        gap "6px"
    }
    lappend rules ".profile-stat" {
        padding "7px"
        border "1px solid var(--border)"
        border-radius "8px"
        background "Canvas"
    }
    lappend rules ".profile-stat strong, .profile-stat span" {
        display "block"
    }
    lappend rules ".profile-stat span" {
        margin-top "2px"
        color "var(--muted)"
        font-size "9px"
        text-transform "uppercase"
    }
    lappend rules ".summary-info" {
        margin-top "10px"
        padding-top "9px"
        border-top "1px solid var(--border)"
        font-size "11px"
        line-height "1.45"
    }
    lappend rules ".summary-text" {
        margin "6px 0 0"
        white-space "pre-wrap"
    }
    lappend rules ".recommendation-controls" {
        display "grid"
        grid-template-columns "minmax(70px, .7fr) minmax(150px, 1.3fr)"
        gap "8px"
        margin-top "10px"
    }
    lappend rules ".recommendation-controls label" {
        display "grid"
        gap "4px"
        color "var(--muted)"
        font-size "10px"
    }
    lappend rules ".recommendation-list.empty" {
        display "block"
        color "var(--muted)"
        font-size "12px"
    }
    lappend rules ".recommendation-row" {
        padding "9px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "Canvas"
    }
    lappend rules ".recommendation-head" {
        display "flex"
        align-items "flex-start"
        justify-content "space-between"
        gap "8px"
    }
    lappend rules ".recommendation-name" {
        min-width "0"
        margin "0"
        font-size "11px"
        font-weight "800"
        overflow-wrap "anywhere"
    }
    lappend rules ".recommendation-viewers" {
        flex "0 0 auto"
        color "var(--muted)"
        font-size "10px"
        font-variant-numeric "tabular-nums"
    }
    lappend rules ".recommendation-description" {
        margin "5px 0 0"
        color "var(--muted)"
        font-size "10px"
        line-height "1.4"
        overflow-wrap "anywhere"
    }
    lappend rules ".recommendation-link" {
        display "inline-block"
        margin-top "6px"
        color "var(--accent)"
        font-size "11px"
        font-weight "700"
    }
    lappend rules ".list" {
        display "grid"
        gap "8px"
        margin-top "11px"
        max-height "300px"
        overflow "auto"
    }
    lappend rules ".list.empty" {
        display "block"
        color "var(--muted)"
        font-size "12px"
    }
    lappend rules ".item" {
        padding "10px"
        border "1px solid var(--border)"
        border-radius "9px"
        background "Canvas"
    }
    lappend rules ".item-head" {
        display "flex"
        align-items "center"
        justify-content "space-between"
        gap "8px"
    }
    lappend rules ".item-title" {
        font-size "12px"
        font-weight "800"
    }
    lappend rules ".item-meta, .item-url, .caption-meta" {
        color "var(--muted)"
        font-size "10px"
    }
    lappend rules ".item-url" {
        margin-top "6px"
        overflow-wrap "anywhere"
        max-height "42px"
        overflow "hidden"
    }
    lappend rules ".copy" {
        flex "0 0 auto"
        padding "6px 8px"
    }
    lappend rules ".caption-text" {
        margin "5px 0 0"
        white-space "pre-wrap"
        font-size "12px"
        line-height "1.4"
    }
    lappend rules ".inline-status, .notice" {
        min-height "17px"
        margin "9px 0 0"
        color "var(--muted)"
        font-size "11px"
    }
    lappend rules ".action-status" {
        line-height "1.4"
    }
    lappend rules ".reset-note" {
        margin "7px 0 0"
    }
    lappend rules ".notice" {
        margin "0 3px 8px"
        color "var(--bad)"
    }

    # Media queries
    lappend rules "@media (min-width: 430px)" {
        ".speech-settings" {
            grid-template-columns "1fr 1fr"
        }
        ".speech-settings label:first-child" {
            grid-column "1 / -1"
        }
    }
    lappend rules "@media (prefers-reduced-motion: reduce)" {
        "*" {
            scroll-behavior "auto !important"
        }
    }

    # Additional comments
    lappend rules "/* Header controls remain in one ordered group at the upper right. */\n.section-title.header-controls" {
        flex-wrap "nowrap"
        align-items "flex-start"
    }
    lappend rules ".header-controls > .title-actions" {
        margin-inline-start "auto"
        flex-wrap "nowrap"
        flex-shrink "0"
    }
    lappend rules ".header-controls > .title-actions input[type=\"checkbox\"]" {
        margin "0"
    }
    lappend rules ".connection-status" {
        display "flex"
        align-items "center"
        gap "8px"
    }

    # Serialize rules to CSS string
    set css ""
    foreach {selector props} $rules {
        append css "$selector {\n"
        dict for {prop value} $props {
            append css "  $prop: $value;\n"
        }
        append css "}\n\n"
    }

    # Write to file
    set fh [open $filename w]
    puts -nonewline $fh $css
    close $fh
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}
write_css [lindex $argv 0]
