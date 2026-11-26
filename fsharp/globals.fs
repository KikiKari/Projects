// abstraction-provenance: {"artifact_sha256": "c6c7af56708b064d436c1fd815491dafb76c8ed79fbcdc446a1fbefeef93559d", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "fsharp"}
// globals.css — portiert nach fsharp
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssVariable = {
    Name: string
    Value: string
}

type CssRule = {
    Selector: string
    Properties: (string * string) list
}

type MediaQuery = {
    Condition: string
    Rules: CssRule list
}

type Keyframes = {
    Name: string
    Frames: (string * (string * string) list) list
}

type StyleSheet = {
    Imports: string list
    Variables: CssVariable list
    ThemeVariables: CssVariable list
    Rules: CssRule list
    MediaQueries: MediaQuery list
    Keyframes: Keyframes list
}

let createVariable name value = { Name = name; Value = value }
let createRule selector properties = { Selector = selector; Properties = properties }
let createMediaQuery condition rules = { Condition = condition; Rules = rules }
let createKeyframes name frames = { Name = name; Frames = frames }

let formatVariable (var: CssVariable) =
    $"--{var.Name}: {var.Value};"

let formatRule (rule: CssRule) =
    let props = rule.Properties |> List.map (fun (name, value) -> $"  {name}: {value};") |> String.concat "\n"
    $"{rule.Selector} {{\n{props}\n}}"

let formatMediaQuery (mq: MediaQuery) =
    let rules = mq.Rules |> List.map formatRule |> String.concat "\n\n"
    $"@media {mq.Condition} {{\n{rules}\n}}"

let formatKeyframes (kf: Keyframes) =
    let frames = kf.Frames |> List.map (fun (percentage, props) ->
        let propsStr = props |> List.map (fun (name, value) -> $"    {name}: {value};") |> String.concat "\n"
        $"  {percentage} {{\n{propsStr}\n  }}"
    ) |> String.concat "\n\n"
    $"@keyframes {kf.Name} {{\n{frames}\n}}"

let formatStyleSheet (stylesheet: StyleSheet) =
    let sb = StringBuilder()
    
    // Imports
    stylesheet.Imports |> List.iter (fun imp -> sb.AppendLine($"@import \"{imp}\";") |> ignore)
    sb.AppendLine() |> ignore
    
    // Root variables
    sb.AppendLine(":root {") |> ignore
    stylesheet.Variables |> List.iter (fun var -> 
        sb.AppendLine($"  {formatVariable var}") |> ignore)
    sb.AppendLine("}") |> ignore
    sb.AppendLine() |> ignore
    
    // Theme variables
    sb.AppendLine("@theme inline {") |> ignore
    stylesheet.ThemeVariables |> List.iter (fun var -> 
        sb.AppendLine($"  --color-{var.Name}: var(--{var.Name});") |> ignore)
    sb.AppendLine("}") |> ignore
    sb.AppendLine() |> ignore
    
    // Regular rules
    stylesheet.Rules |> List.iter (fun rule -> 
        sb.AppendLine(formatRule rule) |> ignore
        sb.AppendLine() |> ignore)
    
    // Media queries
    stylesheet.MediaQueries |> List.iter (fun mq -> 
        sb.AppendLine(formatMediaQuery mq) |> ignore
        sb.AppendLine() |> ignore)
    
    // Keyframes
    stylesheet.Keyframes |> List.iter (fun kf -> 
        sb.AppendLine(formatKeyframes kf) |> ignore
        sb.AppendLine() |> ignore)
    
    sb.ToString()

let globalsCss = {
    Imports = ["tailwindcss"]
    Variables = [
        createVariable "bg" "#faf8f4"
        createVariable "surface" "#ffffff"
        createVariable "surface-2" "#f1eee7"
        createVariable "ink" "#1b1a17"
        createVariable "ink-2" "#3c3a34"
        createVariable "muted" "#6e6a61"
        createVariable "line" "#e5e1d8"
        createVariable "line-strong" "#d4cfc3"
        createVariable "accent" "#a8542f"
        createVariable "accent-press" "#8e4526"
        createVariable "accent-tint" "#f1e5dd"
        createVariable "on-accent" "#ffffff"
        createVariable "accent-2" "#2e7d7b"
        createVariable "accent-2-press" "#225e5b"
        createVariable "accent-3" "#c77d2e"
        createVariable "footer-bg" "#191815"
        createVariable "footer-fg" "#efeae0"
        createVariable "footer-muted" "#9a958a"
        createVariable "success" "#2e7d5b"
        createVariable "danger" "#9e3f32"
        createVariable "font-display" "\"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif"
        createVariable "font-sans" "\"Segoe UI\", Inter, system-ui, -apple-system, sans-serif"
        createVariable "font-mono" "\"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace"
        createVariable "space-1" "0.25rem"
        createVariable "space-2" "0.5rem"
        createVariable "space-3" "0.75rem"
        createVariable "space-4" "1rem"
        createVariable "space-5" "1.25rem"
        createVariable "space-6" "1.5rem"
        createVariable "space-8" "2rem"
        createVariable "space-10" "2.5rem"
        createVariable "space-12" "3rem"
        createVariable "space-16" "4rem"
        createVariable "space-20" "5rem"
        createVariable "space-24" "6rem"
        createVariable "space-30" "7.5rem"
        createVariable "radius-sm" "0.375rem"
        createVariable "radius-md" "0.625rem"
        createVariable "radius-lg" "1.125rem"
        createVariable "radius-pill" "999px"
        createVariable "shadow-sm" "0 1px 2px rgb(27 26 23 / 6%)"
        createVariable "shadow-md" "0 10px 30px -16px rgb(27 26 23 / 22%)"
        createVariable "shadow-lg" "0 34px 70px -34px rgb(27 26 23 / 32%)"
        createVariable "container" "75rem"
        createVariable "motion-fast" "180ms"
        createVariable "motion-base" "350ms"
        createVariable "motion-slow" "800ms"
        createVariable "ease-out" "cubic-bezier(0.22, 0.61, 0.36, 1)"
    ]
    ThemeVariables = [
        createVariable "bg" "var(--bg)"
        createVariable "surface" "var(--surface)"
        createVariable "surface-2" "var(--surface-2)"
        createVariable "ink" "var(--ink)"
        createVariable "ink-2" "var(--ink-2)"
        createVariable "muted" "var(--muted)"
        createVariable "line" "var(--line)"
        createVariable "line-strong" "var(--line-strong)"
        createVariable "accent" "var(--accent)"
        createVariable "accent-2" "var(--accent-2)"
        createVariable "accent-3" "var(--accent-3)"
        createVariable "font-display" "var(--font-display)"
        createVariable "font-sans" "var(--font-sans)"
        createVariable "font-mono" "var(--font-mono)"
    ]
    Rules = [
        createRule "*" [("box-sizing", "border-box")]
        createRule "html" [("scroll-behavior", "smooth")]
        createRule "body" [
            ("margin", "0")
            ("background", "var(--bg)")
            ("color", "var(--ink)")
            ("font-family", "var(--font-sans)")
            ("line-height", "1.5")
            ("-webkit-font-smoothing", "antialiased")
        ]
        createRule "a" [("color", "inherit")]
        createRule "button, input, textarea" [("font", "inherit")]
        createRule "::selection" [
            ("background", "var(--accent-tint)")
            ("color", "var(--ink)")
        ]
        createRule ".display" [
            ("font-family", "var(--font-display)")
            ("font-weight", "400")
            ("letter-spacing", "-0.022em")
        ]
        createRule ".eyebrow" [
            ("font-family", "var(--font-mono)")
            ("font-size", "0.75rem")
            ("letter-spacing", "0.16em")
            ("text-transform", "uppercase")
        ]
        createRule ".focus-ring:focus-visible" [
            ("outline", "2px solid var(--accent)")
            ("outline-offset", "4px")
        ]
        createRule ".content-auto" [
            ("content-visibility", "auto")
            ("contain-intrinsic-size", "1px 800px")
        ]
    ]
    MediaQueries = [
        createMediaQuery "(prefers-reduced-motion: reduce)" [
            createRule "html" [("scroll-behavior", "auto")]
            createRule "*, *::before, *::after" [
                ("animation-duration", "0.01ms !important")
                ("animation-iteration-count", "1 !important")
                ("scroll-behavior", "auto !important")
                ("transition-duration", "0.01ms !important")
            ]
        ]
    ]
    Keyframes = [
        createKeyframes "dropfall" [
            ("0%", [("transform", "translateY(0)"); ("opacity", "0")])
            ("10%", [("opacity", "0.9")])
            ("90%", [("opacity", "0.7")])
            ("100%", [("transform", "translateY(110vh)"); ("opacity", "0")])
        ]
    ]
}

[<EntryPoint>]
let main argv =
    let outputPath = if argv.Length > 0 then argv.[0] else "globals.css"
    let cssContent = formatStyleSheet globalsCss
    File.WriteAllText(outputPath, cssContent)
    printfn "CSS file generated at %s" outputPath
    0
