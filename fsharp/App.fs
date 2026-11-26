// abstraction-provenance: {"artifact_sha256": "2811166157b6448a00ffdc4fd3942f415b236849c8e90a09ccb403ed79c7aa35", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "fsharp"}
// App.css — portiert nach fsharp
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: (string * string) list
}

type StyleSheet = CssRule list

let private formatRule (rule: CssRule) =
    let sb = StringBuilder()
    sb.Append(rule.Selector).Append(" {") |> ignore
    rule.Properties 
    |> List.iter (fun (prop, value) -> 
        sb.AppendLine() |> ignore
        sb.Append("  ").Append(prop).Append(": ").Append(value).Append(";") |> ignore)
    sb.AppendLine().Append("}") |> ignore
    sb.ToString()

let private formatStyleSheet (styleSheet: StyleSheet) =
    styleSheet
    |> List.map formatRule
    |> String.concat "\n\n"

let private createRule selector properties = { Selector = selector; Properties = properties }

let appCss : StyleSheet = [
    createRule ":root" [
        ("color-scheme", "dark")
        ("font-family", "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif")
        ("background", "#0b1020")
        ("color", "#eef2ff")
    ]
    
    createRule "*" [
        ("box-sizing", "border-box")
    ]
    
    createRule "body" [
        ("margin", "0")
        ("min-width", "320px")
        ("min-height", "100vh")
        ("background", "radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem), radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem), linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)")
    ]
    
    createRule ".page-shell" [
        ("min-height", "100vh")
        ("display", "grid")
        ("place-items", "center")
        ("padding", "2rem")
    ]
    
    createRule ".hero-card" [
        ("width", "min(100%, 56rem)")
        ("padding", "clamp(2rem, 6vw, 4.5rem)")
        ("border", "1px solid rgba(148, 163, 184, 0.28)")
        ("border-radius", "2rem")
        ("background", "rgba(15, 23, 42, 0.72)")
        ("box-shadow", "0 2rem 6rem rgba(0, 0, 0, 0.35)")
        ("backdrop-filter", "blur(18px)")
    ]
    
    createRule ".eyebrow" [
        ("margin", "0 0 1rem")
        ("color", "#67e8f9")
        ("font-size", "0.8rem")
        ("font-weight", "700")
        ("letter-spacing", "0.18em")
        ("text-transform", "uppercase")
    ]
    
    createRule "h1" [
        ("margin", "0")
        ("max-width", "12ch")
        ("font-size", "clamp(2.75rem, 8vw, 6rem)")
        ("line-height", "0.95")
        ("letter-spacing", "-0.06em")
    ]
    
    createRule ".lead" [
        ("margin", "1.5rem 0 0")
        ("max-width", "42rem")
        ("color", "#cbd5e1")
        ("font-size", "clamp(1.05rem, 2vw, 1.35rem)")
        ("line-height", "1.65")
    ]
    
    createRule ".link-grid" [
        ("display", "grid")
        ("gap", "0.85rem")
        ("margin-top", "2rem")
    ]
    
    createRule ".link-grid a" [
        ("display", "flex")
        ("align-items", "center")
        ("justify-content", "space-between")
        ("gap", "1rem")
        ("padding", "1rem 1.15rem")
        ("border", "1px solid rgba(148, 163, 184, 0.25)")
        ("border-radius", "1rem")
        ("color", "#f8fafc")
        ("text-decoration", "none")
        ("background", "rgba(255, 255, 255, 0.06)")
    ]
    
    createRule ".link-grid a:hover,\n.link-grid a:focus-visible" [
        ("border-color", "rgba(103, 232, 249, 0.75)")
        ("outline", "none")
        ("background", "rgba(103, 232, 249, 0.12)")
    ]
]

[<EntryPoint>]
let main argv =
    let filePath = 
        if argv.Length > 0 then argv.[0]
        else "App.css"
    
    try
        let cssContent = formatStyleSheet appCss
        File.WriteAllText(filePath, cssContent)
        printfn "CSS file successfully written to %s" filePath
        0
    with
    | ex ->
        eprintfn "Error writing CSS file: %s" ex.Message
        1
