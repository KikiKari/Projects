// abstraction-provenance: {"artifact_sha256": "cabb6d1673edd8e5612bcc89ca2ab4b2bfdd16751bd7e7cf50a90c15adfed954", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "fsharp"}
// node-monitor.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type CssVariable = { Name: string; Value: string }
type CssRule = { Selector: string; Properties: (string * string) list }
type CssDocument = { Variables: CssVariable list; Rules: CssRule list }

let createCssVariable name value = { Name = name; Value = value }
let createCssRule selector properties = { Selector = selector; Properties = properties }

let formatVariables variables =
    variables
    |> List.map (fun v -> $"  {v.Name}: {v.Value};")
    |> String.concat "\n"

let formatRule rule =
    let props = 
        rule.Properties
        |> List.map (fun (name, value) -> $"  {name}: {value};")
        |> String.concat "\n"
    $"{rule.Selector} {{\n{props}\n}}"

let generateCss (doc: CssDocument) =
    let varsSection = 
        if doc.Variables.IsEmpty then ""
        else $":root {{\n{formatVariables doc.Variables}\n}}\n\n"
    
    let rulesSection = 
        doc.Rules
        |> List.map formatRule
        |> String.concat "\n\n"
    
    varsSection + rulesSection

let document = {
    Variables = [
        createCssVariable "--bg" "#0d1117"
        createCssVariable "--surface" "#161b22"
        createCssVariable "--border" "#30363d"
        createCssVariable "--text" "#e6edf3"
        createCssVariable "--green" "#3fb950"
        createCssVariable "--red" "#f85149"
        createCssVariable "--accent" "#58a6ff"
    ]
    Rules = [
        createCssRule "*" [
            ("box-sizing", "border-box")
            ("margin", "0")
            ("padding", "0")
        ]
        createCssRule "body" [
            ("background", "var(--bg)")
            ("color", "var(--text)")
            ("font-family", "-apple-system, sans-serif")
            ("padding", "1.5rem")
        ]
        createCssRule "h1" [
            ("color", "var(--accent)")
            ("margin-bottom", "1rem")
            ("font-size", "1.2rem")
        ]
        createCssRule "canvas" [
            ("display", "block")
            ("border", "1px solid var(--border)")
            ("border-radius", "8px")
            ("background", "var(--surface)")
        ]
        createCssRule "#log" [
            ("margin-top", "1rem")
            ("height", "140px")
            ("overflow-y", "auto")
            ("background", "var(--surface)")
            ("border", "1px solid var(--border)")
            ("border-radius", "8px")
            ("padding", ".75rem")
            ("font-size", ".78rem")
            ("font-family", "monospace")
            ("color", "#8b949e")
        ]
        createCssRule "#log .err" [
            ("color", "var(--red)")
        ]
        createCssRule "#log .ok" [
            ("color", "var(--green)")
        ]
    ]
}

[<EntryPoint>]
let main argv =
    let cssContent = generateCss document
    
    let filePath = 
        if argv.Length > 0 then argv.[0]
        else "node-monitor.css"
    
    File.WriteAllText(filePath, cssContent)
    printfn "CSS file generated: %s" filePath
    0
