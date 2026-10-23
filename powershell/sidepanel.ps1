#!/usr/bin/env pwsh
# sidepanel.css — portiert nach powershell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the sidepanel.css file from structured data.
.DESCRIPTION
    This script generates a CSS file by defining structured rules and converting them into valid CSS syntax.
    It mirrors the structure of the original CSS document using PowerShell's data structures.
.PARAMETER OutputPath
    The path where the generated CSS file will be saved.
.EXAMPLE
    .\Generate-SidePanelCss.ps1 -OutputPath "sidepanel.css"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Define CSS rules as PowerShell objects
$cssRules = @(
    # Root variables
    @{
        selector = ":root"
        properties = @{
            "color-scheme" = "light dark"
            "font-family" = "Inter, `"Segoe UI`", system-ui, sans-serif"
            "--accent" = "#fe2c55"
            "--accent-dark" = "#d91f46"
            "--surface" = "color-mix(in srgb, Canvas 94%, CanvasText 6%)"
            "--border" = "color-mix(in srgb, CanvasText 18%, transparent)"
            "--muted" = "color-mix(in srgb, CanvasText 65%, transparent)"
            "--good" = "#147d45"
            "--warn" = "#a65f00"
            "--bad" = "#b42318"
        }
    },
    # Universal and body styles
    @{ selector = "*"; properties = @{ "box-sizing" = "border-box" } },
    @{ selector = "body"; properties = @{ 
        margin = "0"
        background = "Canvas"
        color = "CanvasText"
        "min-width" = "300px"
    }},
    # Header
    @{ selector = "header"; properties = @{ 
        padding = "11px 18px"
        background = "linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas)"
        "border-bottom" = "1px solid var(--border)"
    }},
    @{ selector = "h2"; properties = @{ 
        margin = "0"
        "font-size" = "15px"
    }},
    # Main layout
    @{ selector = "main"; properties = @{ 
        padding = "14px"
        display = "grid"
        "grid-template-columns" = "minmax(0, 1fr)"
        gap = "12px"
    }},
    # Sections
    @{ selector = "section"; properties = @{ 
        "min-width" = "0"
        padding = "14px"
        background = "var(--surface)"
        border = "1px solid var(--border)"
        "border-radius" = "13px"
        "box-shadow" = "0 5px 20px color-mix(in srgb, CanvasText 6%, transparent)"
    }},
    # Section titles and buttons
    @{ selector = ".section-title, .button-row"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        "justify-content" = "space-between"
        gap = "8px"
    }},
    @{ selector = ".section-title"; properties = @{ 
        "min-width" = "0"
        "flex-wrap" = "wrap"
    }},
    @{ selector = ".title-actions"; properties = @{ 
        display = "flex"
        "min-width" = "0"
        "max-width" = "100%"
        "align-items" = "center"
        "justify-content" = "flex-end"
        "flex-wrap" = "wrap"
        gap = "6px"
    }},
    # Status LED
    @{ selector = ".status-led"; properties = @{ 
        width = "11px"
        height = "11px"
        "flex" = "0 0 11px"
        "border-radius" = "50%"
        background = "var(--bad)"
        "box-shadow" = "0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)"
    }},
    @{ selector = ".status-led.on"; properties = @{ 
        background = "var(--good)"
        "box-shadow" = "0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent)"
    }},
    @{ selector = ".status-led.off"; properties = @{ 
        background = "var(--bad)"
    }},
    # Buttons
    @{ selector = ".button-row"; properties = @{ 
        "justify-content" = "flex-start"
        "flex-wrap" = "wrap"
        "margin-top" = "10px"
    }},
    @{ selector = "button"; properties = @{ 
        border = "0"
        "border-radius" = "9px"
        padding = "9px 11px"
        font = "inherit"
        "font-size" = "12px"
        "font-weight" = "700"
        cursor = "pointer"
    }},
    @{ selector = "button:disabled"; properties = @{ 
        cursor = "not-allowed"
        opacity = ".55"
    }},
    @{ selector = ".compact"; properties = @{ 
        padding = "7px 9px"
    }},
    @{ selector = ".settings-button"; properties = @{ 
        "min-width" = "34px"
        "font-size" = "17px"
        "line-height" = "1"
    }},
    @{ selector = ".primary"; properties = @{ 
        color = "white"
        background = "var(--accent)"
    }},
    @{ selector = ".primary:hover"; properties = @{ 
        background = "var(--accent-dark)"
    }},
    @{ selector = ".secondary"; properties = @{ 
        color = "CanvasText"
        background = "color-mix(in srgb, CanvasText 9%, Canvas)"
        border = "1px solid var(--border)"
    }},
    @{ selector = ".ghost"; properties = @{ 
        color = "var(--muted)"
        background = "transparent"
    }},
    @{ selector = ".danger-outline"; properties = @{ 
        color = "var(--bad)"
        "border-color" = "color-mix(in srgb, var(--bad) 45%, transparent)"
    }},
    @{ selector = "#enable-captions"; properties = @{ 
        width = "100%"
        "margin-top" = "11px"
    }},
    # Text styles
    @{ selector = ".muted"; properties = @{ 
        color = "var(--muted)"
    }},
    @{ selector = ".small"; properties = @{ 
        "font-size" = "12px"
        "line-height" = "1.45"
    }},
    @{ selector = "#page-title"; properties = @{ 
        margin = "0"
        "font-size" = "12px"
        "white-space" = "nowrap"
        overflow = "hidden"
        "text-overflow" = "ellipsis"
    }},
    # Status grid
    @{ selector = ".status-grid"; properties = @{ 
        display = "grid"
        "grid-template-columns" = "1fr 1fr"
        gap = "7px"
        "margin-top" = "11px"
    }},
    @{ selector = ".status"; properties = @{ 
        padding = "9px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "Canvas"
    }},
    @{ selector = ".status-label"; properties = @{ 
        display = "block"
        color = "var(--muted)"
        "font-size" = "10px"
        "text-transform" = "uppercase"
        "letter-spacing" = ".06em"
    }},
    @{ selector = ".status-value"; properties = @{ 
        display = "block"
        "margin-top" = "3px"
        "font-size" = "12px"
        "font-weight" = "750"
    }},
    @{ selector = ".good .status-value"; properties = @{ 
        color = "var(--good)"
    }},
    @{ selector = ".warn .status-value"; properties = @{ 
        color = "var(--warn)"
    }},
    @{ selector = ".bad .status-value"; properties = @{ 
        color = "var(--bad)"
    }},
    # Count elements
    @{ selector = ".count"; properties = @{ 
        "min-width" = "25px"
        padding = "3px 7px"
        "border-radius" = "999px"
        background = "color-mix(in srgb, var(--accent) 15%, Canvas)"
        color = "var(--accent)"
        "text-align" = "center"
        "font-size" = "11px"
        "font-weight" = "800"
    }},
    @{ selector = ".count-button"; properties = @{ 
        border = "1px solid color-mix(in srgb, var(--accent) 30%, transparent)"
        cursor = "pointer"
    }},
    @{ selector = ".count-button:hover, .count-button:focus-visible"; properties = @{ 
        background = "color-mix(in srgb, var(--accent) 25%, Canvas)"
    }},
    # Live indicator
    @{ selector = ".live-indicator"; properties = @{ 
        padding = "3px 7px"
        "border-radius" = "999px"
        background = "color-mix(in srgb, var(--muted) 15%, Canvas)"
        color = "var(--muted)"
        "font-size" = "10px"
        "font-weight" = "800"
        "text-transform" = "uppercase"
    }},
    @{ selector = ".live-indicator.active"; properties = @{ 
        background = "color-mix(in srgb, var(--good) 16%, Canvas)"
        color = "var(--good)"
    }},
    @{ selector = ".stats-grid .status-value"; properties = @{ 
        "font-size" = "16px"
        "font-variant-numeric" = "tabular-nums"
    }},
    # Chat list
    @{ selector = ".chat-list"; properties = @{ 
        display = "grid"
        gap = "6px"
        "margin-top" = "11px"
    }},
    @{ selector = ".chat-list.empty"; properties = @{ 
        color = "var(--muted)"
        "font-size" = "12px"
    }},
    @{ selector = ".chat-line"; properties = @{ 
        margin = "0"
        padding = "7px 8px"
        "border-left" = "3px solid color-mix(in srgb, var(--accent) 45%, var(--border))"
        "border-radius" = "6px"
        background = "Canvas"
        "font-size" = "12px"
        "line-height" = "1.4"
        "overflow-wrap" = "anywhere"
    }},
    @{ selector = ".chat-author"; properties = @{ 
        "font-weight" = "800"
    }},
    # Player controls
    @{ selector = ".player-controls"; properties = @{ 
        display = "grid"
        "grid-template-columns" = "repeat(2, minmax(0, 1fr))"
        gap = "7px"
        "margin-top" = "11px"
    }},
    @{ selector = ".player-controls button"; properties = @{ 
        width = "100%"
    }},
    @{ selector = ".player-time"; properties = @{ 
        "font-size" = "13px"
        "font-weight" = "800"
        "font-variant-numeric" = "tabular-nums"
    }},
    # Audio controls
    @{ selector = ".audio-controls"; properties = @{ 
        display = "grid"
        gap = "7px"
        "margin-top" = "12px"
        "padding-top" = "11px"
        "border-top" = "1px solid var(--border)"
    }},
    @{ selector = ".control-label, .audio-meter-row"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        "justify-content" = "space-between"
        gap = "8px"
        "font-size" = "11px"
    }},
    @{ selector = ".control-label output, .audio-meter-row strong"; properties = @{ 
        "font-variant-numeric" = "tabular-nums"
    }},
    @{ selector = "input[type=`"range`"]"; properties = @{ 
        width = "100%"
        "accent-color" = "var(--accent)"
    }},
    # Settings grid
    @{ selector = ".settings-grid"; properties = @{ 
        display = "grid"
        gap = "7px"
        "margin-top" = "10px"
    }},
    @{ selector = ".settings-grid label"; properties = @{ 
        display = "grid"
        gap = "4px"
        color = "var(--muted)"
        "font-size" = "10px"
    }},
    @{ selector = ".settings-grid label[hidden]"; properties = @{ 
        display = "none"
    }},
    # Input fields
    @{ selector = "input[type=`"url`"], input[type=`"text`"], input[type=`"password`"], input[type=`"number`"], select"; properties = @{ 
        width = "100%"
        "min-width" = "0"
        padding = "7px 8px"
        border = "1px solid var(--border)"
        "border-radius" = "7px"
        background = "Canvas"
        color = "CanvasText"
        font = "inherit"
        "font-size" = "11px"
    }},
    # Top chatters
    @{ selector = ".top-chatters"; properties = @{ 
        display = "grid"
        gap = "6px"
        "margin-top" = "8px"
    }},
    @{ selector = ".top-chatters.empty"; properties = @{ 
        color = "var(--muted)"
        "font-size" = "12px"
    }},
    @{ selector = ".top-chatters-actions"; properties = @{ 
        display = "flex"
        "justify-content" = "flex-end"
        gap = "9px"
        "margin-top" = "7px"
    }},
    @{ selector = ".top-chatters-actions[hidden]"; properties = @{ 
        display = "none"
    }},
    # Top chatter link
    @{ selector = ".top-chatter-link"; properties = @{ 
        padding = "0"
        color = "var(--accent)"
        background = "transparent"
        border = "0"
        "border-radius" = "0"
        "font-weight" = "700"
    }},
    @{ selector = ".top-chatter-link:hover"; properties = @{ 
        "text-decoration" = "underline"
    }},
    # Chatter row
    @{ selector = ".chatter-row"; properties = @{ 
        display = "grid"
        "grid-template-columns" = "minmax(0, 1fr) auto auto"
        "align-items" = "center"
        gap = "7px"
        padding = "7px 8px"
        border = "1px solid var(--border)"
        "border-radius" = "8px"
        background = "Canvas"
    }},
    @{ selector = ".chatter-name"; properties = @{ 
        "min-width" = "0"
        overflow = "hidden"
        "text-overflow" = "ellipsis"
        "white-space" = "nowrap"
        "font-size" = "11px"
        "font-weight" = "800"
    }},
    @{ selector = ".chatter-metrics"; properties = @{ 
        color = "var(--muted)"
        "font-size" = "10px"
        "white-space" = "nowrap"
    }},
    # Mute toggle
    @{ selector = ".mute-toggle"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        gap = "4px"
        color = "var(--muted)"
        "font-size" = "10px"
    }},
    # Recognize song
    @{ selector = "#recognize-song"; properties = @{ 
        width = "100%"
        "margin-top" = "10px"
    }},
    @{ selector = ".song-result"; properties = @{ 
        "margin-top" = "9px"
        padding = "9px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "Canvas"
        "font-size" = "11px"
        "line-height" = "1.45"
    }},
    @{ selector = ".song-result strong, .song-result span, .song-result a"; properties = @{ 
        display = "block"
    }},
    @{ selector = ".song-result a"; properties = @{ 
        "margin-top" = "4px"
        color = "var(--accent)"
        "overflow-wrap" = "anywhere"
    }},
    # Modal backdrop
    @{ selector = ".modal-backdrop"; properties = @{ 
        position = "fixed"
        inset = "0"
        "z-index" = "100"
        padding = "14px"
        background = "color-mix(in srgb, CanvasText 42%, transparent)"
        overflow = "auto"
    }},
    @{ selector = ".modal"; properties = @{ 
        width = "min(520px, 100%)"
        "max-height" = "calc(100vh - 28px)"
        margin = "0 auto"
        overflow = "auto"
        background = "Canvas"
    }},
    # Lists
    @{ selector = ".audience-list, .chat-history-list, .recommendation-list"; properties = @{ 
        display = "grid"
        gap = "7px"
        "margin-top" = "9px"
    }},
    # Chat history
    @{ selector = ".chat-history-row"; properties = @{ 
        padding = "8px 9px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "var(--surface)"
        "font-size" = "11px"
        "line-height" = "1.4"
        "overflow-wrap" = "anywhere"
    }},
    @{ selector = ".chat-history-meta"; properties = @{ 
        display = "block"
        "margin-bottom" = "3px"
        color = "var(--muted)"
        "font-size" = "10px"
    }},
    # Audience row
    @{ selector = ".audience-row"; properties = @{ 
        display = "grid"
        gap = "6px"
        padding = "9px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "var(--surface)"
    }},
    @{ selector = ".audience-row-head"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        "justify-content" = "space-between"
        gap = "8px"
    }},
    @{ selector = ".audience-row select"; properties = @{ 
        width = "auto"
        "max-width" = "170px"
    }},
    @{ selector = ".audience-metrics"; properties = @{ 
        color = "var(--muted)"
        "font-size" = "10px"
        "line-height" = "1.45"
    }},
    # Option rows
    @{ selector = ".option-row"; properties = @{ 
        display = "flex"
        "align-items" = "flex-start"
        gap = "7px"
        "margin-top" = "8px"
        color = "var(--muted)"
        "font-size" = "11px"
        "line-height" = "1.35"
    }},
    @{ selector = ".option-row input"; properties = @{ 
        margin = "1px 0 0"
        "accent-color" = "var(--accent)"
    }},
    @{ selector = ".auto-chat-refresh"; properties = @{ 
        "align-items" = "center"
    }},
    @{ selector = ".external-speech-trigger-row"; properties = @{ 
        "align-items" = "center"
    }},
    @{ selector = ".external-speech-trigger-row label"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        gap = "7px"
    }},
    @{ selector = ".external-speech-trigger-row input[type=`"text`"]"; properties = @{ 
        width = "48px"
        "margin-left" = "3px"
        padding = "3px 4px"
        border = "1px solid var(--border)"
        "border-radius" = "6px"
        background = "Canvas"
        color = "CanvasText"
        font = "inherit"
        "font-size" = "11px"
    }},
    @{ selector = ".auto-chat-refresh input[type=`"number`"]"; properties = @{ 
        width = "48px"
        "margin-left" = "3px"
        padding = "3px 4px"
        border = "1px solid var(--border)"
        "border-radius" = "6px"
        background = "Canvas"
        color = "CanvasText"
        font = "inherit"
        "font-size" = "11px"
    }},
    @{ selector = ".quick-recover-setting input[type=`"number`"]"; properties = @{ 
        width = "48px"
        "margin-left" = "3px"
        padding = "3px 4px"
        border = "1px solid var(--border)"
        "border-radius" = "6px"
        background = "Canvas"
        color = "CanvasText"
        font = "inherit"
        "font-size" = "11px"
    }},
    @{ selector = ".audio-note"; properties = @{ 
        margin = "1px 0 0"
    }},
    # Profile info
    @{ selector = ".profile-info"; properties = @{ 
        display = "grid"
        gap = "8px"
        "margin-top" = "11px"
    }},
    @{ selector = ".profile-heading"; properties = @{ 
        margin = "0"
        "font-size" = "14px"
        "font-weight" = "800"
    }},
    @{ selector = ".profile-handle, .profile-bio"; properties = @{ 
        margin = "0"
        color = "var(--muted)"
        "font-size" = "11px"
        "line-height" = "1.45"
        "white-space" = "pre-wrap"
    }},
    @{ selector = ".profile-stats"; properties = @{ 
        display = "grid"
        "grid-template-columns" = "repeat(3, minmax(0, 1fr))"
        gap = "6px"
    }},
    @{ selector = ".profile-stat"; properties = @{ 
        padding = "7px"
        border = "1px solid var(--border)"
        "border-radius" = "8px"
        background = "Canvas"
    }},
    @{ selector = ".profile-stat strong, .profile-stat span"; properties = @{ 
        display = "block"
    }},
    @{ selector = ".profile-stat span"; properties = @{ 
        "margin-top" = "2px"
        color = "var(--muted)"
        "font-size" = "9px"
        "text-transform" = "uppercase"
    }},
    # Summary info
    @{ selector = ".summary-info"; properties = @{ 
        "margin-top" = "10px"
        "padding-top" = "9px"
        "border-top" = "1px solid var(--border)"
        "font-size" = "11px"
        "line-height" = "1.45"
    }},
    @{ selector = ".summary-text"; properties = @{ 
        margin = "6px 0 0"
        "white-space" = "pre-wrap"
    }},
    # Recommendation controls
    @{ selector = ".recommendation-controls"; properties = @{ 
        display = "grid"
        "grid-template-columns" = "minmax(70px, .7fr) minmax(150px, 1.3fr)"
        gap = "8px"
        "margin-top" = "10px"
    }},
    @{ selector = ".recommendation-controls label"; properties = @{ 
        display = "grid"
        gap = "4px"
        color = "var(--muted)"
        "font-size" = "10px"
    }},
    @{ selector = ".recommendation-list.empty"; properties = @{ 
        display = "block"
        color = "var(--muted)"
        "font-size" = "12px"
    }},
    @{ selector = ".recommendation-row"; properties = @{ 
        padding = "9px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "Canvas"
    }},
    @{ selector = ".recommendation-head"; properties = @{ 
        display = "flex"
        "align-items" = "flex-start"
        "justify-content" = "space-between"
        gap = "8px"
    }},
    @{ selector = ".recommendation-name"; properties = @{ 
        "min-width" = "0"
        margin = "0"
        "font-size" = "11px"
        "font-weight" = "800"
        "overflow-wrap" = "anywhere"
    }},
    @{ selector = ".recommendation-viewers"; properties = @{ 
        "flex" = "0 0 auto"
        color = "var(--muted)"
        "font-size" = "10px"
        "font-variant-numeric" = "tabular-nums"
    }},
    @{ selector = ".recommendation-description"; properties = @{ 
        "margin-top" = "5px"
        color = "var(--muted)"
        "font-size" = "10px"
        "line-height" = "1.4"
        "overflow-wrap" = "anywhere"
    }},
    @{ selector = ".recommendation-link"; properties = @{ 
        display = "inline-block"
        "margin-top" = "6px"
        color = "var(--accent)"
        "font-size" = "11px"
        "font-weight" = "700"
    }},
    # List styles
    @{ selector = ".list"; properties = @{ 
        display = "grid"
        gap = "8px"
        "margin-top" = "11px"
        "max-height" = "300px"
        overflow = "auto"
    }},
    @{ selector = ".list.empty"; properties = @{ 
        display = "block"
        color = "var(--muted)"
        "font-size" = "12px"
    }},
    @{ selector = ".item"; properties = @{ 
        padding = "10px"
        border = "1px solid var(--border)"
        "border-radius" = "9px"
        background = "Canvas"
    }},
    @{ selector = ".item-head"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        "justify-content" = "space-between"
        gap = "8px"
    }},
    @{ selector = ".item-title"; properties = @{ 
        "font-size" = "12px"
        "font-weight" = "800"
    }},
    @{ selector = ".item-meta, .item-url, .caption-meta"; properties = @{ 
        color = "var(--muted)"
        "font-size" = "10px"
    }},
    @{ selector = ".item-url"; properties = @{ 
        "margin-top" = "6px"
        "overflow-wrap" = "anywhere"
        "max-height" = "42px"
        overflow = "hidden"
    }},
    @{ selector = ".copy"; properties = @{ 
        "flex" = "0 0 auto"
        padding = "6px 8px"
    }},
    @{ selector = ".caption-text"; properties = @{ 
        "margin-top" = "5px"
        "white-space" = "pre-wrap"
        "font-size" = "12px"
        "line-height" = "1.4"
    }},
    # Status and notice
    @{ selector = ".inline-status, .notice"; properties = @{ 
        "min-height" = "17px"
        "margin-top" = "9px"
        color = "var(--muted)"
        "font-size" = "11px"
    }},
    @{ selector = ".action-status"; properties = @{ 
        "line-height" = "1.4"
    }},
    @{ selector = ".reset-note"; properties = @{ 
        "margin-top" = "7px"
    }},
    @{ selector = ".notice"; properties = @{ 
        margin = "0 3px 8px"
        color = "var(--bad)"
    }},
    # Media queries
    @{ selector = "@media (min-width: 430px) { .speech-settings }"; properties = @{ 
        "grid-template-columns" = "1fr 1fr"
    }},
    @{ selector = "@media (min-width: 430px) { .speech-settings label:first-child }"; properties = @{ 
        "grid-column" = "1 / -1"
    }},
    @{ selector = "@media (prefers-reduced-motion: reduce) { * }"; properties = @{ 
        "scroll-behavior" = "auto !important"
    }},
    # Header controls specific
    @{ selector = ".section-title.header-controls"; properties = @{ 
        "flex-wrap" = "nowrap"
        "align-items" = "flex-start"
    }},
    @{ selector = ".header-controls > .title-actions"; properties = @{ 
        "margin-inline-start" = "auto"
        "flex-wrap" = "nowrap"
        "flex-shrink" = "0"
    }},
    @{ selector = ".header-controls > .title-actions input[type=`"checkbox`"]"; properties = @{ 
        margin = "0"
    }},
    @{ selector = ".connection-status"; properties = @{ 
        display = "flex"
        "align-items" = "center"
        gap = "8px"
    }}
)

# Function to convert rule object to CSS string
function Convert-ToCssString {
    param([array]$rules)
    
    $cssLines = @()
    
    foreach ($rule in $rules) {
        if ($rule.selector -like "@media*") {
            # Handle media query blocks
            $mediaQuery = $rule.selector
            $properties = ($rule.properties.GetEnumerator() | ForEach-Object {
                "    $($_.Key): $($_.Value);"
            }) -join "`n"
            $cssLines += "$mediaQuery {"
            $cssLines += $properties
            $cssLines += "}"
        } else {
            # Regular rule
            $properties = ($rule.properties.GetEnumerator() | ForEach-Object {
                "  $($_.Key): $($_.Value);"
            }) -join "`n"
            $cssLines += "$($rule.selector) {"
            $cssLines += $properties
            $cssLines += "}"
        }
    }
    
    return ($cssLines -join "`n`n")
}

# Generate CSS content
$cssContent = Convert-ToCssString -rules $cssRules

# Write to file
Set-Content -Path $OutputPath -Value $cssContent -Encoding UTF8

Write-Host "CSS file generated successfully at: $OutputPath"
