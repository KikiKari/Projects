// abstraction-provenance: {"artifact_sha256": "4d0c16e0ecfcfe51ebfc5e051e9750ede40f6c03eeeb19c4ca536b3f6acb2605", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "fsharp"}
// status-overview-panel.css — portiert nach fsharp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

// CSS to F# translation for generating status-overview-panel.css

open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type StyleSheet = CssRule list

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let generateCss (rules: StyleSheet) : string =
    rules
    |> List.map (fun rule ->
        let props = 
            rule.Properties
            |> Map.toList
            |> List.map (fun (key, value) -> sprintf "  %s:%s;" key value)
            |> String.concat "\n"
        sprintf "%s {\n%s\n}" rule.Selector props)
    |> String.concat "\n\n"

let stylesheet : StyleSheet = [
    createRule ".overview-row" [
        ("display", "grid")
        ("grid-template-columns", "24px minmax(0,1fr) 11px 22px auto")
        ("gap", "7px")
        ("align-items", "center")
        ("margin", "6px 0")
    ]
    
    createRule ".overview-row input" [
        ("min-width", "0")
        ("width", "100%")
    ]
    
    createRule ".overview-state" [
        ("width", "11px")
        ("height", "11px")
        ("border-radius", "50%")
        ("background", "#888")
    ]
    
    createRule ".overview-state.online" [
        ("background", "var(--good)")
        ("box-shadow", "0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent)")
    ]
    
    createRule ".overview-state.offline" [
        ("background", "var(--bad)")
        ("box-shadow", "0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)")
    ]
    
    createRule ".overview-state.checking, .overview-state.error" [
        ("background", "var(--warn)")
    ]
    
    createRule ".overview-count" [
        ("font-size", "11px")
        ("text-align", "center")
        ("font-variant-numeric", "tabular-nums")
    ]
    
    createRule ".overview-actions" [
        ("display", "grid")
        ("grid-template-columns", "44px repeat(2,minmax(0,1fr))")
        ("gap", "6px")
        ("align-items", "stretch")
    ]
    
    createRule ".overview-actions button" [
        ("min-width", "0")
        ("padding", "8px 2px")
        ("font-size", "11px")
        ("white-space", "nowrap")
    ]
    
    createRule "#overview-rows" [
        ("display", "flex")
        ("flex-direction", "column")
    ]
    
    createRule ".monitor-settings > label:not(.option-row)" [
        ("display", "block")
        ("margin", "12px 0")
    ]
    
    createRule ".monitor-settings .option-row input" [
        ("appearance", "auto")
        ("width", "13px")
        ("height", "13px")
        ("min-width", "13px")
        ("background", "none")
    ]
    
    createRule ".overview-link" [
        ("padding", "8px 0")
        ("border-bottom", "1px solid #bbb")
        ("overflow-wrap", "anywhere")
    ]
    
    createRule ".overview-link p" [
        ("margin", "4px 0")
    ]
    
    createRule ".overview-row .overview-retry" [
        ("width", "24px")
        ("min-width", "24px")
        ("height", "26px")
        ("min-height", "26px")
        ("padding", "0")
        ("background-image", "var(--icon-reset)")
        ("background-size", "20px")
        ("background-position", "center")
        ("background-repeat", "no-repeat")
    ]
    
    createRule ".top-setting input" [
        ("appearance", "auto")
        ("-webkit-appearance", "checkbox")
        ("width", "13px")
        ("height", "13px")
        ("min-width", "13px")
        ("background", "none")
    ]
    
    createRule ".overview-visually-hidden" [
        ("position", "absolute")
        ("width", "1px")
        ("height", "1px")
        ("padding", "0")
        ("margin", "-1px")
        ("overflow", "hidden")
        ("clip", "rect(0,0,0,0)")
        ("white-space", "nowrap")
        ("border", "0")
    ]
    
    createRule ".overview-row[hidden]" [
        ("display", "none")
    ]
]

[<EntryPoint>]
let main args =
    let cssContent = generateCss stylesheet
    match args with
    | [||] -> 
        printfn "%s" cssContent
        0
    | [|filename|] -> 
        File.WriteAllText(filename, cssContent)
        0
    | _ -> 
        eprintfn "Usage: program [<output-file>]"
        1
