// abstraction-provenance: {"artifact_sha256": "bb2e7923a222bc9b817c4912a1271cd5fbfc9d9036d880a982b04b3c8c2a1db4", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "fsharp"}
// index_58ad28.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

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

type StyleSheet = {
    RootRules: CssRule list
    MediaQueries: MediaQuery list
    RegularRules: CssRule list
}

let createCssRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createMediaQuery condition rules =
    { Condition = condition; Rules = rules }

let createStyleSheet rootRules mediaQueries regularRules =
    { RootRules = rootRules; MediaQueries = mediaQueries; RegularRules = regularRules }

let rootRules = [
    createCssRule ":root" [
        "--bg", "#ffffff"
        "--soft", "#f6f7f9"
        "--line", "#e3e6ea"
        "--text", "#16191d"
        "--muted", "#5f6773"
        "--tg", "#2481cc"
        "--tg-soft", "#e8f2fb"
        "--tt", "#fe2c55"
        "--ok", "#15803d"
        "--ok-soft", "#e7f6ec"
        "--warn", "#b45309"
        "--warn-soft", "#fdf3e3"
        "color-scheme", "light"
    ]
]

let mediaQueries = [
    createMediaQuery "(prefers-color-scheme: dark)" [
        createCssRule ":root" [
            "--bg", "#0f1115"
            "--soft", "#171a21"
            "--line", "#262b36"
            "--text", "#f2f4f8"
            "--muted", "#9aa3b2"
            "--tg-soft", "#132a3d"
            "--ok-soft", "#12261a"
            "--warn-soft", "#2c2110"
            "color-scheme", "dark"
        ]
    ]
]

let regularRules = [
    createCssRule "*" [("box-sizing", "border-box")]
    
    createCssRule "body" [
        ("margin", "0")
        ("background", "var(--bg)")
        ("color", "var(--text)")
        ("font", "16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif")
    ]
    
    createCssRule ".wrap" [
        ("max-width", "820px")
        ("margin", "0 auto")
        ("padding", "0 20px 72px")
    ]
    
    createCssRule "header" [
        ("padding", "64px 0 40px")
        ("border-bottom", "1px solid var(--line)")
        ("margin-bottom", "8px")
    ]
    
    createCssRule "h1" [
        ("font-size", "34px")
        ("line-height", "1.2")
        ("margin", "0 0 12px")
        ("letter-spacing", "-0.02em")
    ]
    
    createCssRule ".lede" [
        ("font-size", "18px")
        ("color", "var(--muted)")
        ("margin", "0 0 22px")
        ("max-width", "60ch")
    ]
    
    createCssRule "h2" [
        ("font-size", "13px")
        ("margin", "44px 0 14px")
        ("text-transform", "uppercase")
        ("letter-spacing", "0.06em")
        ("color", "var(--muted)")
        ("font-weight", "650")
    ]
    
    createCssRule "h3" [
        ("font-size", "17px")
        ("margin", "26px 0 6px")
    ]
    
    createCssRule "p" [
        ("margin", "0 0 14px")
        ("max-width", "68ch")
    ]
    
    createCssRule ".badges" [
        ("display", "flex")
        ("gap", "7px")
        ("flex-wrap", "wrap")
        ("margin-bottom", "22px")
    ]
    
    createCssRule ".badge" [
        ("font-size", "12px")
        ("font-weight", "650")
        ("padding", "4px 11px")
        ("border-radius", "99px")
        ("background", "var(--soft)")
        ("color", "var(--muted)")
        ("border", "1px solid var(--line)")
    ]
    
    createCssRule ".badge.on" [
        ("background", "var(--ok-soft)")
        ("color", "var(--ok)")
        ("border-color", "transparent")
    ]
    
    createCssRule ".cta" [
        ("display", "flex")
        ("gap", "10px")
        ("flex-wrap", "wrap")
    ]
    
    createCssRule ".btn" [
        ("display", "inline-block")
        ("font-weight", "650")
        ("font-size", "15px")
        ("padding", "11px 20px")
        ("border-radius", "9px")
        ("text-decoration", "none")
        ("border", "1px solid var(--line)")
        ("background", "var(--bg)")
        ("color", "var(--text)")
    ]
    
    createCssRule ".btn.primary" [
        ("background", "var(--tg)")
        ("border-color", "var(--tg)")
        ("color", "#fff")
    ]
    
    createCssRule ".btn:hover" [
        ("border-color", "var(--tg)")
    ]
    
    createCssRule ".grid" [
        ("display", "grid")
        ("grid-template-columns", "repeat(auto-fit, minmax(230px, 1fr)")
        ("gap", "14px")
    ]
    
    createCssRule ".card" [
        ("border", "1px solid var(--line)")
        ("border-radius", "12px")
        ("padding", "16px 18px")
        ("background", "var(--bg)")
    ]
    
    createCssRule ".card h3" [
        ("margin-top", "0")
        ("font-size", "15.5px")
    ]
    
    createCssRule ".card p" [
        ("font-size", "14px")
        ("color", "var(--muted)")
        ("margin", "0")
    ]
    
    createCssRule "ol.steps" [
        ("list-style", "none")
        ("counter-reset", "s")
        ("padding", "0")
        ("margin", "0")
    ]
    
    createCssRule "ol.steps li" [
        ("counter-increment", "s")
        ("position", "relative")
        ("padding", "0 0 20px 40px")
        ("border-left", "2px solid var(--line)")
        ("margin-left", "11px")
    ]
    
    createCssRule "ol.steps li:last-child" [
        ("border-left-color", "transparent")
        ("padding-bottom", "0")
    ]
    
    createCssRule "ol.steps li::before" [
        ("content", "counter(s)")
        ("position", "absolute")
        ("left", "-13px")
        ("top", "0")
        ("width", "24px")
        ("height", "24px")
        ("border-radius", "50%")
        ("background", "var(--tg)")
        ("color", "#fff")
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "center")
        ("font-size", "12px")
        ("font-weight", "700")
    ]
    
    createCssRule "ol.steps b" [
        ("display", "block")
        ("margin-bottom", "3px")
    ]
    
    createCssRule "ol.steps p" [
        ("font-size", "14.5px")
        ("color", "var(--muted)")
        ("margin", "0 0 8px")
    ]
    
    createCssRule "code" [
        ("background", "var(--soft)")
        ("padding", "2px 7px")
        ("border-radius", "5px")
        ("font-size", "13.5px")
        ("font-family", "ui-monospace, SFMono-Regular, Menlo, monospace")
        ("word-break", "break-word")
    ]
    
    createCssRule "pre" [
        ("background", "var(--soft)")
        ("border", "1px solid var(--line)")
        ("border-radius", "10px")
        ("padding", "13px 15px")
        ("overflow-x", "auto")
        ("margin", "0 0 14px")
    ]
    
    createCssRule "pre code" [
        ("background", "none")
        ("padding", "0")
        ("font-size", "13.5px")
        ("line-height", "1.7")
    ]
    
    createCssRule "table" [
        ("width", "100%")
        ("border-collapse", "collapse")
        ("font-size", "14.5px")
        ("margin", "0 0 16px")
    ]
    
    createCssRule "th, td" [
        ("text-align", "left")
        ("padding", "9px 11px")
        ("border-bottom", "1px solid var(--line)")
        ("vertical-align", "top")
    ]
    
    createCssRule "th" [
        ("color", "var(--muted)")
        ("font-size", "12px")
        ("text-transform", "uppercase")
        ("letter-spacing", "0.04em")
        ("font-weight", "650")
    ]
    
    createCssRule ".note" [
        ("border-left", "3px solid var(--warn)")
        ("background", "var(--warn-soft)")
        ("border-radius", "0 9px 9px 0")
        ("padding", "13px 16px")
        ("margin", "0 0 16px")
        ("font-size", "14.5px")
    ]
    
    createCssRule ".note b" [
        ("display", "block")
        ("margin-bottom", "3px")
    ]
    
    createCssRule "a" [("color", "var(--tg)")]
    
    createCssRule "footer" [
        ("margin-top", "52px")
        ("padding-top", "22px")
        ("border-top", "1px solid var(--line)")
        ("font-size", "13.5px")
        ("color", "var(--muted)")
    ]
]

let styleSheet = createStyleSheet rootRules mediaQueries regularRules

let formatProperties (properties: Map<string, string>) =
    properties
    |> Map.toList
    |> List.map (fun (key, value) -> $"  {key}: {value};")
    |> String.concat "\n"

let formatRule (rule: CssRule) =
    $"{rule.Selector} {{\n{formatProperties rule.Properties}\n}}"

let formatMediaQuery (mq: MediaQuery) =
    $"@media {mq.Condition} {{\n{mq.Rules |> List.map formatRule |> String.concat "\n\n"}\n}}"

let generateCss (stylesheet: StyleSheet) =
    let sb = StringBuilder()
    
    // Add comments
    sb.AppendLine("/* abstraction-provenance: {\"artifact_sha256\": \"537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f\", \"source_sha256\": \"58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3\", \"target_language\": \"css\"} */") |> ignore
    sb.AppendLine("/* index.html — portiert nach css */") |> ignore
    sb.AppendLine("/* Quelle: html, Projects@Telegram-Monitor:public/index.html */") |> ignore
    sb.AppendLine("/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */") |> ignore
    sb.AppendLine() |> ignore
    
    // Root rules
    stylesheet.RootRules |> List.iter (fun rule ->
        sb.AppendLine(formatRule rule) |> ignore
        sb.AppendLine() |> ignore
    )
    
    // Media queries
    stylesheet.MediaQueries |> List.iter (fun mq ->
        sb.AppendLine(formatMediaQuery mq) |> ignore
        sb.AppendLine() |> ignore
    )
    
    // Regular rules
    stylesheet.RegularRules |> List.iter (fun rule ->
        sb.AppendLine(formatRule rule) |> ignore
        sb.AppendLine() |> ignore
    )
    
    sb.ToString()

[<EntryPoint>]
let main args =
    if args.Length <> 1 then
        printfn "Usage: program <output-file>"
        1
    else
        let cssContent = generateCss styleSheet
        File.WriteAllText(args.[0], cssContent)
        0
