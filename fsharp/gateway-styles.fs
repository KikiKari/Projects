// abstraction-provenance: {"artifact_sha256": "a582b9a19a21bdde87b45e17e60700ba13722009904bffafc6f46cf0a6eb90df", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "fsharp"}
// gateway-styles.css — portiert nach fsharp
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type CssDocument = {
    Comments: string list
    Variables: Map<string, string>
    Rules: CssRule list
}

module CssGenerator =
    let private formatProperty (key: string) (value: string) =
        $"  {key}: {value};"

    let private formatRule (rule: CssRule) =
        let props = rule.Properties |> Map.toList |> List.map (fun (k, v) -> formatProperty k v)
        $"{rule.Selector} {{\n{String.concat "\n" props}\n}}"

    let private formatVariable (key: string) (value: string) =
        $"  {key}: {value};"

    let generate (doc: CssDocument) =
        let sb = StringBuilder()
        
        // Add comments
        doc.Comments |> List.iter (fun comment -> 
            sb.AppendLine("/* " + comment + " */") |> ignore)
        sb.AppendLine() |> ignore
        
        // Add universal selector
        let universalRule = doc.Rules |> List.find (fun r -> r.Selector = "*, *::before, *::after")
        sb.AppendLine(formatRule universalRule).AppendLine() |> ignore
        
        // Add root variables
        sb.AppendLine(":root {")
        doc.Variables |> Map.toList |> List.iter (fun (k, v) -> 
            sb.AppendLine(formatVariable k v) |> ignore)
        sb.AppendLine("}").AppendLine() |> ignore
        
        // Add remaining rules in order
        doc.Rules 
        |> List.filter (fun r -> r.Selector <> "*, *::before, *::after")
        |> List.iter (fun rule -> 
            sb.AppendLine(formatRule rule).AppendLine() |> ignore)
        
        sb.ToString()

let createGatewayStyles() =
    {
        Comments = ["OpenClaw Gateway Dashboard"]
        Variables = 
            Map [
                "--bg", "#0d1117"
                "--surface", "#161b22"
                "--border", "#30363d"
                "--text", "#e6edf3"
                "--muted", "#8b949e"
                "--green", "#3fb950"
                "--yellow", "#d29922"
                "--red", "#f85149"
                "--accent", "#58a6ff"
            ]
        Rules = [
            {
                Selector = "*, *::before, *::after"
                Properties = 
                    Map [
                        "box-sizing", "border-box"
                        "margin", "0"
                        "padding", "0"
                    ]
            }
            {
                Selector = "body"
                Properties = 
                    Map [
                        "background", "var(--bg)"
                        "color", "var(--text)"
                        "font-family", "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
                        "min-height", "100vh"
                    ]
            }
            {
                Selector = "header"
                Properties = 
                    Map [
                        "display", "flex"
                        "align-items", "center"
                        "gap", "1rem"
                        "padding", "1.25rem 2rem"
                        "border-bottom", "1px solid var(--border)"
                        "background", "var(--surface)"
                    ]
            }
            {
                Selector = "header h1"
                Properties = 
                    Map [
                        "font-size", "1.25rem"
                        "color", "var(--accent)"
                    ]
            }
            {
                Selector = ".badge"
                Properties = 
                    Map [
                        "padding", ".25rem .75rem"
                        "border-radius", "999px"
                        "font-size", ".75rem"
                        "font-weight", "600"
                        "background", "var(--border)"
                        "color", "var(--muted)"
                    ]
            }
            {
                Selector = ".badge.ok"
                Properties = 
                    Map [
                        "background", "#1a3a2a"
                        "color", "var(--green)"
                    ]
            }
            {
                Selector = ".badge.warn"
                Properties = 
                    Map [
                        "background", "#3a2e0a"
                        "color", "var(--yellow)"
                    ]
            }
            {
                Selector = ".badge.error"
                Properties = 
                    Map [
                        "background", "#3a1010"
                        "color", "var(--red)"
                    ]
            }
            {
                Selector = "main"
                Properties = 
                    Map [
                        "padding", "2rem"
                        "max-width", "960px"
                        "margin", "0 auto"
                    ]
            }
            {
                Selector = ".grid"
                Properties = 
                    Map [
                        "display", "grid"
                        "grid-template-columns", "repeat(auto-fit, minmax(260px, 1fr))"
                        "gap", "1rem"
                        "margin-bottom", "2rem"
                    ]
            }
            {
                Selector = ".card"
                Properties = 
                    Map [
                        "background", "var(--surface)"
                        "border", "1px solid var(--border)"
                        "border-radius", "8px"
                        "padding", "1.25rem"
                        "position", "relative"
                    ]
            }
            {
                Selector = ".card h2"
                Properties = 
                    Map [
                        "font-size", "1rem"
                        "margin-bottom", ".25rem"
                    ]
            }
            {
                Selector = ".card .endpoint"
                Properties = 
                    Map [
                        "font-size", ".8rem"
                        "color", "var(--muted)"
                    ]
            }
            {
                Selector = ".status-dot"
                Properties = 
                    Map [
                        "position", "absolute"
                        "top", "1.25rem"
                        "right", "1.25rem"
                        "width", "10px"
                        "height", "10px"
                        "border-radius", "50%"
                        "background", "var(--border)"
                    ]
            }
            {
                Selector = ".status-dot.green"
                Properties = 
                    Map [
                        "background", "var(--green)"
                        "box-shadow", "0 0 6px var(--green)"
                    ]
            }
            {
                Selector = ".status-dot.red"
                Properties = 
                    Map [
                        "background", "var(--red)"
                        "box-shadow", "0 0 6px var(--red)"
                    ]
            }
            {
                Selector = ".metrics h2"
                Properties = 
                    Map [
                        "font-size", "1rem"
                        "margin-bottom", "1rem"
                    ]
            }
            {
                Selector = "table"
                Properties = 
                    Map [
                        "width", "100%"
                        "border-collapse", "collapse"
                        "font-size", ".875rem"
                    ]
            }
            {
                Selector = "th, td"
                Properties = 
                    Map [
                        "padding", ".625rem 1rem"
                        "text-align", "left"
                        "border-bottom", "1px solid var(--border)"
                    ]
            }
            {
                Selector = "th"
                Properties = 
                    Map [
                        "color", "var(--muted)"
                        "font-weight", "500"
                    ]
            }
            {
                Selector = "tr:last-child td"
                Properties = 
                    Map [
                        "border-bottom", "none"
                    ]
            }
        ]
    }

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Usage: %s <output-file>" (System.Reflection.Assembly.GetExecutingAssembly().Location)
        1
    else
        try
            let document = createGatewayStyles()
            let cssContent = CssGenerator.generate document
            File.WriteAllText(argv.[0], cssContent)
            printfn "CSS file generated successfully: %s" argv.[0]
            0
        with
        | ex ->
            eprintfn "Error generating CSS file: %s" ex.Message
            1
