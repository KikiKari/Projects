// abstraction-provenance: {"artifact_sha256": "4c6f8db3d0a0930d82ff0162cec8092f31af40089c27822e12acf20341dd2891", "source_sha256": "e07e663714dd74eaf25d7c73a2e4fae09e726ce450182ddaeb0637ae76e40ad5", "target_language": "fsharp"}
// sidepanel.css — portiert nach fsharp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/sidepanel.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/sidepanel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type StyleSheet = CssRule list

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let addProperty rule property value =
    { rule with Properties = Map.add property value rule.Properties }

let generateCss rules =
    rules
    |> List.map (fun rule ->
        let props = 
            rule.Properties 
            |> Map.toList 
            |> List.map (fun (key, value) -> $"  {key}: {value};")
            |> String.concat "\n"
        $"{rule.Selector} {{\n{props}\n}}"
    )
    |> String.concat "\n\n"

let rootRules = [
    createRule ":root" [
        ("color-scheme", "light dark")
        ("font-family", """Inter, "Segoe UI", system-ui, sans-serif""")
        ("--accent", "#fe2c55")
        ("--accent-dark", "#d91f46")
        ("--surface", "color-mix(in srgb, Canvas 94%, CanvasText 6%)")
        ("--border", "color-mix(in srgb, CanvasText 18%, transparent)")
        ("--muted", "color-mix(in srgb, CanvasText 65%, transparent)")
        ("--good", "#147d45")
        ("--warn", "#a65f00")
        ("--bad", "#b42318")
    ]
]

let generalRules = [
    createRule "*" [("box-sizing", "border-box")]
    createRule "body" [
        ("margin", "0")
        ("background", "Canvas")
        ("color", "CanvasText")
        ("min-width", "300px")
    ]
    createRule "header" [
        ("padding", "11px 18px")
        ("background", "linear-gradient(135deg, color-mix(in srgb, var(--accent) 18%, Canvas), Canvas)")
        ("border-bottom", "1px solid var(--border)")
    ]
    createRule "h2" [
        ("margin", "0")
        ("font-size", "15px")
    ]
    createRule "main" [
        ("padding", "14px")
        ("display", "grid")
        ("grid-template-columns", "minmax(0, 1fr)")
        ("gap", "12px")
    ]
    createRule "section" [
        ("min-width", "0")
        ("padding", "14px")
        ("background", "var(--surface)")
        ("border", "1px solid var(--border)")
        ("border-radius", "13px")
        ("box-shadow", "0 5px 20px color-mix(in srgb, CanvasText 6%, transparent)")
    ]
    createRule ".section-title, .button-row" [
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "space-between")
        ("gap", "8px")
    ]
    createRule ".section-title" [
        ("min-width", "0")
        ("flex-wrap", "wrap")
    ]
    createRule ".title-actions" [
        ("display", "flex")
        ("min-width", "0")
        ("max-width", "100%")
        ("align-items", "center")
        ("justify-content", "flex-end")
        ("flex-wrap", "wrap")
        ("gap", "6px")
    ]
    createRule ".status-led" [
        ("width", "11px")
        ("height", "11px")
        ("flex", "0 0 11px")
        ("border-radius", "50%")
        ("background", "var(--bad)")
        ("box-shadow", "0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)")
    ]
    createRule ".status-led.on" [
        ("background", "var(--good)")
        ("box-shadow", "0 0 0 3px color-mix(in srgb, var(--good) 17%, transparent)")
    ]
    createRule ".status-led.off" [
        ("background", "var(--bad)")
    ]
    createRule ".button-row" [
        ("justify-content", "flex-start")
        ("flex-wrap", "wrap")
        ("margin-top", "10px")
    ]
    createRule "button" [
        ("border", "0")
        ("border-radius", "9px")
        ("padding", "9px 11px")
        ("font", "inherit")
        ("font-size", "12px")
        ("font-weight", "700")
        ("cursor", "pointer")
    ]
    createRule "button:disabled" [
        ("cursor", "not-allowed")
        ("opacity", ".55")
    ]
    createRule ".compact" [("padding", "7px 9px")]
    createRule ".settings-button" [
        ("min-width", "34px")
        ("font-size", "17px")
        ("line-height", "1")
    ]
    createRule ".primary" [
        ("color", "white")
        ("background", "var(--accent)")
    ]
    createRule ".primary:hover" [("background", "var(--accent-dark)")]
    createRule ".secondary" [
        ("color", "CanvasText")
        ("background", "color-mix(in srgb, CanvasText 9%, Canvas)")
        ("border", "1px solid var(--border)")
    ]
    createRule ".ghost" [
        ("color", "var(--muted)")
        ("background", "transparent")
    ]
    createRule ".danger-outline" [
        ("color", "var(--bad)")
        ("border-color", "color-mix(in srgb, var(--bad) 45%, transparent)")
    ]
    createRule "#enable-captions" [
        ("width", "100%")
        ("margin-top", "11px")
    ]
    createRule ".muted" [("color", "var(--muted)")]
    createRule ".small" [
        ("font-size", "12px")
        ("line-height", "1.45")
    ]
    createRule "#page-title" [
        ("margin", "0")
        ("font-size", "12px")
        ("white-space", "nowrap")
        ("overflow", "hidden")
        ("text-overflow", "ellipsis")
    ]
    createRule ".status-grid" [
        ("display", "grid")
        ("grid-template-columns", "1fr 1fr")
        ("gap", "7px")
        ("margin-top", "11px")
    ]
    createRule ".status" [
        ("padding", "9px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "Canvas")
    ]
    createRule ".status-label" [
        ("display", "block")
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("text-transform", "uppercase")
        ("letter-spacing", ".06em")
    ]
    createRule ".status-value" [
        ("display", "block")
        ("margin-top", "3px")
        ("font-size", "12px")
        ("font-weight", "750")
    ]
    createRule ".good .status-value" [("color", "var(--good)")]
    createRule ".warn .status-value" [("color", "var(--warn)")]
    createRule ".bad .status-value" [("color", "var(--bad)")]
    createRule ".count" [
        ("min-width", "25px")
        ("padding", "3px 7px")
        ("border-radius", "999px")
        ("background", "color-mix(in srgb, var(--accent) 15%, Canvas)")
        ("color", "var(--accent)")
        ("text-align", "center")
        ("font-size", "11px")
        ("font-weight", "800")
    ]
    createRule ".count-button" [
        ("border", "1px solid color-mix(in srgb, var(--accent) 30%, transparent)")
        ("cursor", "pointer")
    ]
    createRule ".count-button:hover, .count-button:focus-visible" [
        ("background", "color-mix(in srgb, var(--accent) 25%, Canvas)")
    ]
    createRule ".live-indicator" [
        ("padding", "3px 7px")
        ("border-radius", "999px")
        ("background", "color-mix(in srgb, var(--muted) 15%, Canvas)")
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("font-weight", "800")
        ("text-transform", "uppercase")
    ]
    createRule ".live-indicator.active" [
        ("background", "color-mix(in srgb, var(--good) 16%, Canvas)")
        ("color", "var(--good)")
    ]
    createRule ".stats-grid .status-value" [
        ("font-size", "16px")
        ("font-variant-numeric", "tabular-nums")
    ]
    createRule ".chat-list" [
        ("display", "grid")
        ("gap", "6px")
        ("margin-top", "11px")
    ]
    createRule ".chat-list.empty" [
        ("color", "var(--muted)")
        ("font-size", "12px")
    ]
    createRule ".chat-line" [
        ("margin", "0")
        ("padding", "7px 8px")
        ("border-left", "3px solid color-mix(in srgb, var(--accent) 45%, var(--border))")
        ("border-radius", "6px")
        ("background", "Canvas")
        ("font-size", "12px")
        ("line-height", "1.4")
        ("overflow-wrap", "anywhere")
    ]
    createRule ".chat-author" [("font-weight", "800")]
    createRule ".player-controls" [
        ("display", "grid")
        ("grid-template-columns", "repeat(2, minmax(0, 1fr))")
        ("gap", "7px")
        ("margin-top", "11px")
    ]
    createRule ".player-controls button" [("width", "100%")]
    createRule ".player-time" [
        ("font-size", "13px")
        ("font-weight", "800")
        ("font-variant-numeric", "tabular-nums")
    ]
    createRule ".audio-controls" [
        ("display", "grid")
        ("gap", "7px")
        ("margin-top", "12px")
        ("padding-top", "11px")
        ("border-top", "1px solid var(--border)")
    ]
    createRule ".control-label, .audio-meter-row" [
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "space-between")
        ("gap", "8px")
        ("font-size", "11px")
    ]
    createRule ".control-label output, .audio-meter-row strong" [
        ("font-variant-numeric", "tabular-nums")
    ]
    createRule """input[type="range"]""" [("width", "100%"); ("accent-color", "var(--accent)")]
    createRule ".settings-grid" [
        ("display", "grid")
        ("gap", "7px")
        ("margin-top", "10px")
    ]
    createRule ".settings-grid label" [
        ("display", "grid")
        ("gap", "4px")
        ("color", "var(--muted)")
        ("font-size", "10px")
    ]
    createRule ".settings-grid label[hidden]" [("display", "none")]
    createRule """input[type="url"], input[type="text"], input[type="password"], input[type="number"], select""" [
        ("width", "100%")
        ("min-width", "0")
        ("padding", "7px 8px")
        ("border", "1px solid var(--border)")
        ("border-radius", "7px")
        ("background", "Canvas")
        ("color", "CanvasText")
        ("font", "inherit")
        ("font-size", "11px")
    ]
    createRule ".top-chatters" [
        ("display", "grid")
        ("gap", "6px")
        ("margin-top", "8px")
    ]
    createRule ".top-chatters.empty" [
        ("color", "var(--muted)")
        ("font-size", "12px")
    ]
    createRule ".top-chatters-actions" [
        ("display", "flex")
        ("justify-content", "flex-end")
        ("gap", "9px")
        ("margin-top", "7px")
    ]
    createRule ".top-chatters-actions[hidden]" [("display", "none")]
    createRule ".top-chatter-link" [
        ("padding", "0")
        ("color", "var(--accent)")
        ("background", "transparent")
        ("border", "0")
        ("border-radius", "0")
        ("font-weight", "700")
    ]
    createRule ".top-chatter-link:hover" [("text-decoration", "underline")]
    createRule ".chatter-row" [
        ("display", "grid")
        ("grid-template-columns", "minmax(0, 1fr) auto auto")
        ("align-items", "center")
        ("gap", "7px")
        ("padding", "7px 8px")
        ("border", "1px solid var(--border)")
        ("border-radius", "8px")
        ("background", "Canvas")
    ]
    createRule ".chatter-name" [
        ("min-width", "0")
        ("overflow", "hidden")
        ("text-overflow", "ellipsis")
        ("white-space", "nowrap")
        ("font-size", "11px")
        ("font-weight", "800")
    ]
    createRule ".chatter-metrics" [
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("white-space", "nowrap")
    ]
    createRule ".mute-toggle" [
        ("display", "flex")
        ("align-items", "center")
        ("gap", "4px")
        ("color", "var(--muted)")
        ("font-size", "10px")
    ]
    createRule "#recognize-song" [
        ("width", "100%")
        ("margin-top", "10px")
    ]
    createRule ".song-result" [
        ("margin-top", "9px")
        ("padding", "9px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "Canvas")
        ("font-size", "11px")
        ("line-height", "1.45")
    ]
    createRule ".song-result strong, .song-result span, .song-result a" [("display", "block")]
    createRule ".song-result a" [
        ("margin-top", "4px")
        ("color", "var(--accent)")
        ("overflow-wrap", "anywhere")
    ]
    createRule ".modal-backdrop" [
        ("position", "fixed")
        ("inset", "0")
        ("z-index", "100")
        ("padding", "14px")
        ("background", "color-mix(in srgb, CanvasText 42%, transparent)")
        ("overflow", "auto")
    ]
    createRule ".modal" [
        ("width", "min(520px, 100%)")
        ("max-height", "calc(100vh - 28px)")
        ("margin", "0 auto")
        ("overflow", "auto")
        ("background", "Canvas")
    ]
    createRule ".audience-list, .chat-history-list, .recommendation-list" [
        ("display", "grid")
        ("gap", "7px")
        ("margin-top", "9px")
    ]
    createRule ".chat-history-row" [
        ("padding", "8px 9px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "var(--surface)")
        ("font-size", "11px")
        ("line-height", "1.4")
        ("overflow-wrap", "anywhere")
    ]
    createRule ".chat-history-meta" [
        ("display", "block")
        ("margin-bottom", "3px")
        ("color", "var(--muted)")
        ("font-size", "10px")
    ]
    createRule ".audience-row" [
        ("display", "grid")
        ("gap", "6px")
        ("padding", "9px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "var(--surface)")
    ]
    createRule ".audience-row-head" [
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "space-between")
        ("gap", "8px")
    ]
    createRule ".audience-row select" [
        ("width", "auto")
        ("max-width", "170px")
    ]
    createRule ".audience-metrics" [
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("line-height", "1.45")
    ]
    createRule ".option-row" [
        ("display", "flex")
        ("align-items", "flex-start")
        ("gap", "7px")
        ("margin-top", "8px")
        ("color", "var(--muted)")
        ("font-size", "11px")
        ("line-height", "1.35")
    ]
    createRule ".option-row input" [
        ("margin", "1px 0 0")
        ("accent-color", "var(--accent)")
    ]
    createRule ".auto-chat-refresh" [("align-items", "center")]
    createRule ".external-speech-trigger-row" [("align-items", "center")]
    createRule ".external-speech-trigger-row label" [
        ("display", "flex")
        ("align-items", "center")
        ("gap", "7px")
    ]
    createRule ".external-speech-trigger-row input[type=\"text\"]" [
        ("width", "48px")
        ("margin-left", "3px")
        ("padding", "3px 4px")
        ("border", "1px solid var(--border)")
        ("border-radius", "6px")
        ("background", "Canvas")
        ("color", "CanvasText")
        ("font", "inherit")
        ("font-size", "11px")
    ]
    createRule ".auto-chat-refresh input[type=\"number\"]" [
        ("width", "48px")
        ("margin-left", "3px")
        ("padding", "3px 4px")
        ("border", "1px solid var(--border)")
        ("border-radius", "6px")
        ("background", "Canvas")
        ("color", "CanvasText")
        ("font", "inherit")
        ("font-size", "11px")
    ]
    createRule ".quick-recover-setting input[type=\"number\"]" [
        ("width", "48px")
        ("margin-left", "3px")
        ("padding", "3px 4px")
        ("border", "1px solid var(--border)")
        ("border-radius", "6px")
        ("background", "Canvas")
        ("color", "CanvasText")
        ("font", "inherit")
        ("font-size", "11px")
    ]
    createRule ".audio-note" [("margin", "1px 0 0")]
    createRule ".profile-info" [
        ("display", "grid")
        ("gap", "8px")
        ("margin-top", "11px")
    ]
    createRule ".profile-heading" [
        ("margin", "0")
        ("font-size", "14px")
        ("font-weight", "800")
    ]
    createRule ".profile-handle, .profile-bio" [
        ("margin", "0")
        ("color", "var(--muted)")
        ("font-size", "11px")
        ("line-height", "1.45")
        ("white-space", "pre-wrap")
    ]
    createRule ".profile-stats" [
        ("display", "grid")
        ("grid-template-columns", "repeat(3, minmax(0, 1fr))")
        ("gap", "6px")
    ]
    createRule ".profile-stat" [
        ("padding", "7px")
        ("border", "1px solid var(--border)")
        ("border-radius", "8px")
        ("background", "Canvas")
    ]
    createRule ".profile-stat strong, .profile-stat span" [("display", "block")]
    createRule ".profile-stat span" [
        ("margin-top", "2px")
        ("color", "var(--muted)")
        ("font-size", "9px")
        ("text-transform", "uppercase")
    ]
    createRule ".summary-info" [
        ("margin-top", "10px")
        ("padding-top", "9px")
        ("border-top", "1px solid var(--border)")
        ("font-size", "11px")
        ("line-height", "1.45")
    ]
    createRule ".summary-text" [
        ("margin", "6px 0 0")
        ("white-space", "pre-wrap")
    ]
    createRule ".recommendation-controls" [
        ("display", "grid")
        ("grid-template-columns", "minmax(70px, .7fr) minmax(150px, 1.3fr)")
        ("gap", "8px")
        ("margin-top", "10px")
    ]
    createRule ".recommendation-controls label" [
        ("display", "grid")
        ("gap", "4px")
        ("color", "var(--muted)")
        ("font-size", "10px")
    ]
    createRule ".recommendation-list.empty" [
        ("display", "block")
        ("color", "var(--muted)")
        ("font-size", "12px")
    ]
    createRule ".recommendation-row" [
        ("padding", "9px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "Canvas")
    ]
    createRule ".recommendation-head" [
        ("display", "flex")
        ("align-items", "flex-start")
        ("justify-content", "space-between")
        ("gap", "8px")
    ]
    createRule ".recommendation-name" [
        ("min-width", "0")
        ("margin", "0")
        ("font-size", "11px")
        ("font-weight", "800")
        ("overflow-wrap", "anywhere")
    ]
    createRule ".recommendation-viewers" [
        ("flex", "0 0 auto")
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("font-variant-numeric", "tabular-nums")
    ]
    createRule ".recommendation-description" [
        ("margin", "5px 0 0")
        ("color", "var(--muted)")
        ("font-size", "10px")
        ("line-height", "1.4")
        ("overflow-wrap", "anywhere")
    ]
    createRule ".recommendation-link" [
        ("display", "inline-block")
        ("margin-top", "6px")
        ("color", "var(--accent)")
        ("font-size", "11px")
        ("font-weight", "700")
    ]
    createRule ".list" [
        ("display", "grid")
        ("gap", "8px")
        ("margin-top", "11px")
        ("max-height", "300px")
        ("overflow", "auto")
    ]
    createRule ".list.empty" [
        ("display", "block")
        ("color", "var(--muted)")
        ("font-size", "12px")
    ]
    createRule ".item" [
        ("padding", "10px")
        ("border", "1px solid var(--border)")
        ("border-radius", "9px")
        ("background", "Canvas")
    ]
    createRule ".item-head" [
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "space-between")
        ("gap", "8px")
    ]
    createRule ".item-title" [
        ("font-size", "12px")
        ("font-weight", "800")
    ]
    createRule ".item-meta, .item-url, .caption-meta" [
        ("color", "var(--muted)")
        ("font-size", "10px")
    ]
    createRule ".item-url" [
        ("margin-top", "6px")
        ("overflow-wrap", "anywhere")
        ("max-height", "42px")
        ("overflow", "hidden")
    ]
    createRule ".copy" [
        ("flex", "0 0 auto")
        ("padding", "6px 8px")
    ]
    createRule ".caption-text" [
        ("margin", "5px 0 0")
        ("white-space", "pre-wrap")
        ("font-size", "12px")
        ("line-height", "1.4")
    ]
    createRule ".inline-status, .notice" [
        ("min-height", "17px")
        ("margin", "9px 0 0")
        ("color", "var(--muted)")
        ("font-size", "11px")
    ]
    createRule ".action-status" [("line-height", "1.4")]
    createRule ".reset-note" [("margin", "7px 0 0")]
    createRule ".notice" [
        ("margin", "0 3px 8px")
        ("color", "var(--bad)")
    ]
    createRule "@media (min-width: 430px)" [
        (".speech-settings", "{ grid-template-columns: 1fr 1fr; }")
        (".speech-settings label:first-child", "{ grid-column: 1 / -1; }")
    ]
    createRule "@media (prefers-reduced-motion: reduce)" [
        ("*", "{ scroll-behavior: auto !important; }")
    ]
    createRule "/* Header controls remain in one ordered group at the upper right. */\n.section-title.header-controls" [
        ("flex-wrap", "nowrap")
        ("align-items", "flex-start")
    ]
    createRule ".header-controls > .title-actions" [
        ("margin-inline-start", "auto")
        ("flex-wrap", "nowrap")
        ("flex-shrink", "0")
    ]
    createRule ".header-controls > .title-actions input[type=\"checkbox\"]" [("margin", "0")]
    createRule ".connection-status" [
        ("display", "flex")
        ("align-items", "center")
        ("gap", "8px")
    ]
]

let allRules = rootRules @ generalRules

let writeCssToFile filename =
    let cssContent = generateCss allRules
    File.WriteAllText(filename, cssContent)
    printfn "CSS file written to %s" filename

[<EntryPoint>]
let main argv =
    let filename = 
        if argv.Length > 0 then argv.[0]
        else "sidepanel.css"
    
    writeCssToFile filename
    0
