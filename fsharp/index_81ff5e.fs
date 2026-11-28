// abstraction-provenance: {"artifact_sha256": "b797fa69b6904361b8c89570d9489b57c352da4c40c3ebf93023c574e4cf6107", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "fsharp"}
// index_81ff5e.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_81ff5e.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

// Abstraction provenance: {"artifact_sha256": "6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9", "source_sha256": "81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12", "target_language": "F#"}
// index.html — portiert nach F#
// Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: (string * string) list
}

type CssDocument = {
    Variables: (string * string) list
    Rules: CssRule list
}

let createCssDocument variables rules = { Variables = variables; Rules = rules }

let createRule selector properties = { Selector = selector; Properties = properties }

let formatCss (doc: CssDocument) =
    let sb = StringBuilder()
    
    // Write root variables
    sb.AppendLine(":root {") |> ignore
    doc.Variables 
    |> List.iter (fun (key, value) -> 
        sb.AppendFormat("  {0}: {1};", key, value) |> ignore
        sb.AppendLine() |> ignore)
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine() |> ignore
    
    // Write rules
    doc.Rules 
    |> List.iter (fun rule ->
        sb.AppendFormat("{0} {{", rule.Selector) |> ignore
        sb.AppendLine() |> ignore
        rule.Properties 
        |> List.iter (fun (prop, value) -> 
            sb.AppendFormat("  {0}: {1};", prop, value) |> ignore
            sb.AppendLine() |> ignore)
        sb.AppendLine("}") |> ignore
        sb.AppendLine() |> ignore)
    
    sb.ToString()

let generateCssDocument() =
    let variables = [
        ("color-scheme", "light")
        ("--ink", "#1b1c1f")
        ("--muted", "#6c6e75")
        ("--faint", "#9a9ca3")
        ("--card", "#fff")
        ("--line", "#e9eaee")
        ("--accent", "#5b5bd6")
        ("--accent2", "#7c5cff")
        ("--ok", "#22a06b")
        ("--err", "#e0533d")
        ("--radius", "16px")
        ("--shadow", "0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06)")
    ]
    
    let rules = [
        createRule "*" [("box-sizing", "border-box")]
        
        createRule "body" [
            ("margin", "0")
            ("font-family", "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif")
            ("color", "var(--ink)")
            ("min-height", "100vh")
            ("background", "radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%), linear-gradient(180deg, #eef1f6, #f7f7f8 42%)")
            ("background-attachment", "fixed")
        ]
        
        createRule ".wrap" [
            ("max-width", "820px")
            ("margin", "0 auto")
            ("padding", "24px 18px 70px")
        ]
        
        createRule ".brand" [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "12px")
            ("margin-bottom", "4px")
        ]
        
        createRule ".mark" [
            ("width", "32px")
            ("height", "32px")
            ("border-radius", "9px")
            ("background", "linear-gradient(135deg, var(--accent), var(--accent2))")
            ("box-shadow", "0 4px 12px rgba(91, 91, 214, 0.35)")
            ("position", "relative")
            ("flex", "0 0 auto")
        ]
        
        createRule ".mark:after" [
            ("content", "\"\"")
            ("position", "absolute")
            ("inset", "8px")
            ("border-radius", "4px")
            ("border", "2px solid rgba(255, 255, 255, 0.92)")
        ]
        
        createRule "h1" [
            ("font-size", "21px")
            ("margin", "0")
            ("font-weight", "700")
        ]
        
        createRule ".sub" [
            ("color", "var(--muted)")
            ("font-size", "13px")
            ("margin", "2px 0 16px")
        ]
        
        createRule ".card" [
            ("background", "var(--card)")
            ("border", "1px solid var(--line)")
            ("border-radius", "var(--radius)")
            ("box-shadow", "var(--shadow)")
            ("padding", "16px")
            ("margin-bottom", "14px")
        ]
        
        createRule ".card h2" [
            ("font-size", "14px")
            ("margin", "0 0 10px")
        ]
        
        createRule "label.lab" [
            ("display", "block")
            ("font-size", "12px")
            ("font-weight", "600")
            ("color", "var(--muted)")
            ("margin", "8px 0 3px")
        ]
        
        createRule "input" [
            ("width", "100%")
            ("font-size", "13px")
            ("padding", "8px 10px")
            ("border", "1px solid var(--line)")
            ("border-radius", "9px")
            ("font-family", "ui-monospace, Menlo, Consolas, monospace")
            ("background", "#fff")
        ]
        
        createRule "textarea" [
            ("width", "100%")
            ("font-size", "13px")
            ("padding", "8px 10px")
            ("border", "1px solid var(--line)")
            ("border-radius", "9px")
            ("font-family", "ui-monospace, Menlo, Consolas, monospace")
            ("background", "#fff")
            ("min-height", "90px")
            ("white-space", "pre")
            ("overflow", "auto")
        ]
        
        createRule ".row" [
            ("display", "flex")
            ("gap", "8px")
            ("flex-wrap", "wrap")
            ("align-items", "center")
        ]
        
        createRule ".btn" [
            ("font-size", "13px")
            ("font-weight", "600")
            ("padding", "8px 14px")
            ("border", "1px solid var(--line)")
            ("border-radius", "10px")
            ("background", "#fff")
            ("cursor", "pointer")
            ("box-shadow", "var(--shadow)")
            ("transition", "transform 0.1s")
        ]
        
        createRule ".btn:hover" [
            ("transform", "translateY(-1px)")
        ]
        
        createRule ".btn.primary" [
            ("background", "linear-gradient(135deg, var(--accent), var(--accent2))")
            ("color", "#fff")
            ("border-color", "transparent")
        ]
        
        createRule ".btn.sm" [
            ("padding", "5px 9px")
            ("font-size", "12px")
        ]
        
        createRule ".msg" [
            ("font-size", "12px")
            ("margin-left", "6px")
        ]
        
        createRule ".msg.ok" [
            ("color", "var(--ok)")
        ]
        
        createRule ".msg.err" [
            ("color", "var(--err)")
        ]
        
        createRule ".prov" [
            ("border", "1px solid var(--line)")
            ("border-radius", "12px")
            ("padding", "10px 12px")
            ("margin-bottom", "10px")
        ]
        
        createRule ".prov h3" [
            ("margin", "0 0 6px")
            ("font-size", "13.5px")
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
        ]
        
        createRule ".kv" [
            ("display", "grid")
            ("grid-template-columns", "180px 1fr auto")
            ("gap", "6px")
            ("margin", "4px 0")
            ("align-items", "center")
        ]
        
        createRule ".kv input" [
            ("font-size", "12px")
            ("padding", "5px 7px")
        ]
        
        createRule ".kv .k" [
            ("color", "var(--muted)")
            ("font-weight", "600")
        ]
        
        createRule ".muted" [
            ("color", "var(--faint)")
            ("font-size", "13px")
        ]
        
        createRule ".hide" [
            ("display", "none")
        ]
        
        createRule ".foot" [
            ("color", "var(--faint)")
            ("font-size", "11.5px")
            ("text-align", "center")
            ("margin-top", "18px")
            ("line-height", "1.5")
        ]
        
        createRule "a" [
            ("color", "var(--accent)")
        ]
    ]
    
    createCssDocument variables rules

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Usage: program <output-file>"
        1
    else
        try
            let cssDoc = generateCssDocument()
            let cssContent = formatCss cssDoc
            File.WriteAllText(argv.[0], cssContent)
            0
        with
        | ex ->
            printfn "Error writing file: %s" ex.Message
            1
