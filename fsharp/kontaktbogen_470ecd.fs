// abstraction-provenance: {"artifact_sha256": "276ee1d0d07ec08d272f2ba4116a855fafd18475833c31bc4ab7b11c416a6ea4", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "fsharp"}
// kontaktbogen.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type CssDocument = {
    Variables: Map<string, string>
    Rules: CssRule list
}

let createCssRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createCssDocument variables rules =
    { Variables = Map.ofList variables; Rules = rules }

let formatCss (doc: CssDocument) =
    let sb = StringBuilder()
    
    // Write variables
    sb.AppendLine(":root {") |> ignore
    doc.Variables
    |> Map.iter (fun key value -> 
        sb.AppendFormat("  {0}: {1};", key, value) |> ignore
        sb.AppendLine() |> ignore)
    sb.AppendLine("}") |> ignore
    sb.AppendLine() |> ignore
    
    // Write rules
    for rule in doc.Rules do
        sb.AppendFormat("{0} {{", rule.Selector) |> ignore
        sb.AppendLine() |> ignore
        rule.Properties
        |> Map.iter (fun prop value ->
            sb.AppendFormat("  {0}: {1};", prop, value) |> ignore
            sb.AppendLine() |> ignore)
        sb.AppendLine("}") |> ignore
        sb.AppendLine() |> ignore
    
    sb.ToString()

let generateKontaktbogenCss() =
    let variables = [
        "--bg", "#FAF8F4"
        "--ink", "#1B1A17"
        "--muted", "#6E6A61"
        "--line", "#E5E1D8"
        "--accent", "#A8542F"
        "--accent-2", "#2E7D7B"
        "--surface", "#fff"
    ]
    
    let rules = [
        createCssRule "*" [
            "box-sizing", "border-box"
        ]
        
        createCssRule "body" [
            "margin", "0"
            "font-family", "'Hanken Grotesk', system-ui, sans-serif"
            "background", "var(--bg)"
            "color", "var(--ink)"
            "line-height", "1.5"
        ]
        
        createCssRule "header" [
            "padding", "2.5rem 2rem 1rem"
            "border-bottom", "1px solid var(--line)"
            "background", "var(--surface)"
            "position", "sticky"
            "top", "0"
            "z-index", "10"
        ]
        
        createCssRule "header h1" [
            "margin", "0 0 .5rem"
            "font-family", "'Newsreader', Georgia, serif"
            "font-weight", "400"
            "font-size", "2.25rem"
        ]
        
        createCssRule "header p" [
            "margin", ".25rem 0"
            "color", "var(--muted)"
            "max-width", "80ch"
        ]
        
        createCssRule ".legend" [
            "display", "flex"
            "gap", "1rem"
            "flex-wrap", "wrap"
            "margin-top", ".75rem"
            "font-size", ".8125rem"
        ]
        
        createCssRule ".pill" [
            "padding", ".15rem .6rem"
            "border-radius", "999px"
            "border", "1px solid var(--line)"
            "background", "#fff"
        ]
        
        createCssRule ".pill.pflicht" [
            "border-color", "var(--accent)"
            "color", "var(--accent)"
            "font-weight", "600"
        ]
        
        createCssRule ".pill.auswahl" [
            "border-color", "var(--accent-2)"
            "color", "var(--accent-2)"
            "font-weight", "600"
        ]
        
        createCssRule "main" [
            "padding", "2rem"
            "max-width", "1400px"
            "margin", "0 auto"
        ]
        
        createCssRule "section" [
            "margin", "2.5rem 0"
        ]
        
        createCssRule "section h2" [
            "font-family", "'Newsreader', serif"
            "font-weight", "400"
            "font-size", "1.5rem"
            "margin", "0 0 .25rem"
            "display", "flex"
            "align-items", "center"
            "gap", ".75rem"
        ]
        
        createCssRule "section .sub" [
            "color", "var(--muted)"
            "font-size", ".875rem"
            "margin", "0 0 1.25rem"
        ]
        
        createCssRule ".grid" [
            "display", "grid"
            "grid-template-columns", "repeat(auto-fill, minmax(240px, 1fr))"
            "gap", "1rem"
        ]
        
        createCssRule ".card" [
            "background", "var(--surface)"
            "border", "1px solid var(--line)"
            "border-radius", "10px"
            "overflow", "hidden"
            "display", "flex"
            "flex-direction", "column"
        ]
        
        createCssRule ".card .imgwrap" [
            "aspect-ratio", "1"
            "background", "#f1eee7"
            "display", "flex"
            "align-items", "center"
            "justify-content", "center"
            "overflow", "hidden"
        ]
        
        createCssRule ".card img" [
            "width", "100%"
            "height", "100%"
            "object-fit", "contain"
            "background", "#fff"
        ]
        
        createCssRule ".card .meta" [
            "padding", ".6rem .75rem .75rem"
            "font-size", ".78125rem"
        ]
        
        createCssRule ".card .name" [
            "font-family", "'JetBrains Mono', monospace"
            "font-size", ".6875rem"
            "color", "var(--muted)"
            "word-break", "break-all"
            "line-height", "1.3"
            "margin-bottom", ".35rem"
        ]
        
        createCssRule ".card .dims" [
            "color", "var(--muted)"
            "font-size", ".6875rem"
            "margin-bottom", ".35rem"
        ]
        
        createCssRule ".card .prompt" [
            "color", "var(--ink)"
            "font-size", ".75rem"
            "line-height", "1.35"
            "font-style", "italic"
            "border-top", "1px solid var(--line)"
            "padding-top", ".4rem"
            "margin-top", ".35rem"
            "max-height", "5.5em"
            "overflow", "hidden"
        ]
        
        createCssRule ".tag" [
            "display", "inline-block"
            "padding", ".1rem .45rem"
            "border-radius", "999px"
            "font-size", ".6875rem"
            "background", "#F1EEE7"
            "color", "var(--muted)"
            "margin-right", ".25rem"
        ]
        
        createCssRule ".tag.p" [
            "background", "#F1E5DD"
            "color", "var(--accent)"
        ]
        
        createCssRule ".tag.a" [
            "background", "#DEEDEC"
            "color", "var(--accent-2)"
        ]
    ]
    
    createCssDocument variables rules

[<EntryPoint>]
let main argv =
    let cssDoc = generateKontaktbogenCss()
    let cssContent = formatCss cssDoc
    
    match argv with
    | [| filename |] ->
        File.WriteAllText(filename, cssContent)
        printfn "CSS file written to %s" filename
    | _ ->
        printfn "%s" cssContent
    
    0
