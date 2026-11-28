// abstraction-provenance: {"artifact_sha256": "93dd922d3a90120bdaaf85eb806a01dd979f1c653de647a0ff7d5bc04b2b178b", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "fsharp"}
// popup.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/popup.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type MediaQuery = {
    Condition: string
    Rules: CssRule list
}

type Keyframes = {
    Name: string
    Frames: Map<string, Map<string, string>>
}

type StyleSheet = {
    Rules: CssRule list
    MediaQueries: MediaQuery list
    Keyframes: Keyframes list
}

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createMediaQuery condition rules =
    { Condition = condition; Rules = rules }

let createKeyframes name frames =
    { Name = name; Frames = Map.ofList frames }

let formatProperties (properties: Map<string, string>) =
    properties
    |> Map.toList
    |> List.map (fun (key, value) -> $"  {key}: {value};")
    |> String.concat "\n"

let formatRule rule =
    $"{rule.Selector} {{\n{formatProperties rule.Properties}\n}}"

let formatMediaQuery mq =
    let rules = mq.Rules |> List.map formatRule |> String.concat "\n\n"
    $"@media ({mq.Condition}) {{\n{rules}\n}}"

let formatKeyframes kf =
    let frames = 
        kf.Frames
        |> Map.toList
        |> List.map (fun (frame, props) ->
            let formattedProps = props |> Map.toList |> List.map (fun (k, v) -> $"    {k}: {v};") |> String.concat "\n"
            $"  {frame} {{\n{formattedProps}\n  }}")
        |> String.concat "\n"
    $"@keyframes {kf.Name} {{\n{frames}\n}}"

let formatStyleSheet (styleSheet: StyleSheet) =
    let rules = styleSheet.Rules |> List.map formatRule |> String.concat "\n\n"
    let mediaQueries = styleSheet.MediaQueries |> List.map formatMediaQuery |> String.concat "\n\n"
    let keyframes = styleSheet.Keyframes |> List.map formatKeyframes |> String.concat "\n\n"
    
    [rules; mediaQueries; keyframes]
    |> List.filter (not << String.IsNullOrEmpty)
    |> String.concat "\n\n"

let generatePopupCss() =
    let rootRules = [
        createRule ":root" [
            "--bg", "#0f1115"
            "--card", "#171a21"
            "--line", "#262b36"
            "--text", "#f2f4f8"
            "--muted", "#9aa3b2"
            "--accent", "#fe2c55"
            "--ok", "#22c55e"
            "color-scheme", "dark"
        ]
        createRule "*" [("box-sizing", "border-box")]
        createRule "body" [
            "margin", "0"
            "width", "420px"
            "max-height", "600px"
            "overflow", "auto"
            "background", "var(--bg)"
            "color", "var(--text)"
            "font", "14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif"
        ]
        createRule ".wrap" [
            "padding", "12px"
        ]
        createRule "header" [
            "display", "flex"
            "gap", "8px"
            "align-items", "center"
            "margin-bottom", "10px"
        ]
        createRule "h1" [
            "font-size", "14px"
            "margin", "0"
            "font-weight", "650"
            "flex", "1"
        ]
        createRule ".badge" [
            "font-size", "11px"
            "font-weight", "700"
            "padding", "3px 9px"
            "border-radius", "99px"
            "background", "#2a2f3a"
            "color", "var(--muted)"
            "display", "inline-flex"
            "align-items", "center"
            "gap", "5px"
        ]
        createRule ".badge.live" [
            "background", "var(--accent)"
            "color", "#fff"
        ]
        createRule ".badge .dot" [
            "width", "6px"
            "height", "6px"
            "border-radius", "50%"
            "background", "currentColor"
        ]
        createRule ".badge.live .dot" [
            "animation", "pulse 1.6s infinite"
        ]
        createRule ".row" [
            "display", "flex"
            "gap", "6px"
            "flex-wrap", "wrap"
            "align-items", "center"
            "margin-bottom", "8px"
        ]
        createRule "input, select, button" [
            "font", "inherit"
            "border-radius", "7px"
            "border", "1px solid var(--line)"
            "background", "var(--card)"
            "color", "var(--text)"
            "padding", "6px 9px"
        ]
        createRule "button" [
            "cursor", "pointer"
            "font-weight", "600"
        ]
        createRule "button.primary" [
            "background", "var(--accent)"
            "border-color", "var(--accent)"
            "color", "#fff"
        ]
        createRule ".player" [
            "position", "relative"
            "width", "100%"
            "aspect-ratio", "9/16"
            "max-height", "360px"
            "background", "#000"
            "border-radius", "10px"
            "overflow", "hidden"
            "border", "1px solid var(--line)"
            "margin", "8px 0"
        ]
        createRule ".player iframe" [
            "position", "absolute"
            "inset", "0"
            "width", "100%"
            "height", "100%"
            "border", "0"
        ]
        createRule ".placeholder" [
            "position", "absolute"
            "inset", "0"
            "display", "flex"
            "flex-direction", "column"
            "gap", "6px"
            "align-items", "center"
            "justify-content", "center"
            "color", "var(--muted)"
            "text-align", "center"
            "padding", "16px"
            "font-size", "13px"
        ]
        createRule ".card" [
            "background", "var(--card)"
            "border", "1px solid var(--line)"
            "border-radius", "10px"
            "padding", "10px 12px"
            "margin-bottom", "8px"
        ]
        createRule "h2" [
            "font-size", "11px"
            "text-transform", "uppercase"
            "letter-spacing", ".05em"
            "color", "var(--muted)"
            "margin", "0 0 6px"
            "font-weight", "650"
        ]
        createRule ".meta" [
            "color", "var(--muted)"
            "font-size", "12.5px"
        ]
        createRule ".strong" [
            "color", "var(--text)"
            "font-weight", "600"
        ]
        createRule ".stream" [
            "display", "flex"
            "gap", "8px"
            "padding", "5px 0"
            "border-bottom", "1px solid var(--line)"
            "font-size", "12.5px"
        ]
        createRule ".stream:last-child" [
            "border-bottom", "0"
        ]
        createRule ".stream .when" [
            "color", "var(--muted)"
            "white-space", "nowrap"
            "font-variant-numeric", "tabular-nums"
        ]
        createRule ".stream .t" [
            "flex", "1"
            "min-width", "0"
            "overflow", "hidden"
            "text-overflow", "ellipsis"
            "white-space", "nowrap"
        ]
        createRule ".stream.now" [
            "color", "var(--accent)"
            "font-weight", "650"
        ]
        createRule ".err" [
            "background", "#3a1d22"
            "border", "1px solid #5c2a33"
            "color", "#ffb4c0"
            "padding", "8px 10px"
            "border-radius", "8px"
            "font-size", "12.5px"
            "margin-bottom", "8px"
        ]
        createRule ".note" [
            "font-size", "11.5px"
            "color", "var(--muted)"
            "line-height", "1.4"
            "margin-top", "8px"
        ]
        createRule "a" [
            "color", "var(--accent)"
        ]
    ]

    let lightModeQuery = createMediaQuery "prefers-color-scheme: light" [
        createRule ":root" [
            "--bg", "#fff"
            "--card", "#f6f7f9"
            "--line", "#e3e6ea"
            "--text", "#16191d"
            "--muted", "#6b7280"
        ]
        createRule ".err" [
            "background", "#fdeceb"
            "border-color", "#f5c6c2"
            "color", "#b91c1c"
        ]
    ]

    let pulseKeyframes = createKeyframes "pulse" [
        "0%, 100%", [("opacity", "1")]
        "50%", [("opacity", ".25")]
    ]

    {
        Rules = rootRules
        MediaQueries = [lightModeQuery]
        Keyframes = [pulseKeyframes]
    }

[<EntryPoint>]
let main argv =
    if Array.length argv <> 1 then
        printfn "Usage: %s <output-file>" (System.Reflection.Assembly.GetEntryAssembly().GetName().Name)
        1
    else
        try
            let outputPath = argv.[0]
            let styleSheet = generatePopupCss()
            let cssContent = formatStyleSheet styleSheet
            
            // Add comments at the beginning
            let headerComment = 
                "/* abstraction-provenance: {\"artifact_sha256\": \"9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9\", \"source_sha256\": \"460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94\", \"target_language\": \"css\"} */\n" +
                "/* popup.html — portiert nach css */\n" +
                "/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */\n" +
                "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n"
            
            File.WriteAllText(outputPath, headerComment + cssContent, Encoding.UTF8)
            printfn "CSS file generated successfully: %s" outputPath
            0
        with
        | ex ->
            eprintfn "Error generating CSS file: %s" ex.Message
            1
