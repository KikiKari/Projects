// abstraction-provenance: {"artifact_sha256": "a6458e99fbd3d97fef19ff3fd901a9633152125ee9ec3e57577718c752b0f308", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "fsharp"}
// index_5f1051.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_5f1051.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type StyleSheet = {
    Rules: CssRule list
    Comments: string list
}

module CssGenerator =
    let private formatProperty (key, value) =
        sprintf "    %s: %s;" key value

    let private formatRule rule =
        let properties = 
            rule.Properties
            |> Map.toList
            |> List.map formatProperty
            |> String.concat "\n"
        sprintf "%s {\n%s\n}" rule.Selector properties

    let generateCss (stylesheet: StyleSheet) =
        let commentBlock = 
            stylesheet.Comments
            |> List.map (fun c -> sprintf "/* %s */" c)
            |> String.concat "\n"
        
        let rules = 
            stylesheet.Rules
            |> List.map formatRule
            |> String.concat "\n\n"
        
        if String.IsNullOrEmpty(commentBlock) then
            rules
        else
            sprintf "%s\n\n%s" commentBlock rules

module StyleSheetBuilder =
    let createRule selector properties =
        { Selector = selector; Properties = Map.ofList properties }
    
    let createStyleSheet comments rules =
        { Rules = rules; Comments = comments }

let createIndexStylesheet() =
    let comments = [
        "abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"}"
        "index.html — portiert nach css"
        "Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html"
        "auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html"
        "Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py"
    ]
    
    let rules = [
        createRule "body" [
            ("background-color", "white")
            ("color", "black")
            ("margin", "0")
            ("padding", "0")
            ("font-family", "Arial, sans-serif")
        ]
        
        createRule "table" [
            ("border-collapse", "collapse")
        ]
        
        createRule ".globalnav-container" [
            ("width", "780px")
            ("border", "0")
            ("cellpadding", "0")
            ("cellspacing", "0")
        ]
        
        createRule ".header-left" [
            ("vertical-align", "top")
            ("text-align", "left")
        ]
        
        createRule ".header-right" [
            ("vertical-align", "top")
            ("text-align", "right")
        ]
        
        createRule ".logo-link" [
            ("text-decoration", "none")
            ("border", "0")
        ]
        
        createRule ".logo-image" [
            ("border", "0")
        ]
        
        createRule ".hosted-by" [
            ("font-size", "1px")
            ("text-decoration", "none")
        ]
        
        createRule ".active-state-logo" [
            ("border", "0")
            ("title", "\"This site is hosted by ActiveState\"")
        ]
        
        createRule "#globalnav" [
            ("clear", "both")
        ]
        
        createRule "#globalnav ul" [
            ("list-style-type", "none")
            ("margin", "0")
            ("padding", "0")
            ("overflow", "hidden")
        ]
        
        createRule "#globalnav li" [
            ("float", "left")
        ]
        
        createRule "#globalnav a" [
            ("display", "block")
            ("padding", "8px 16px")
            ("text-decoration", "none")
            ("color", "#000")
        ]
        
        createRule "#globalnav a.here" [
            ("background-color", "#3163CE")
            ("color", "white")
        ]
        
        createRule ".divider-top" [
            ("border-top", "2px solid #3163CE")
            ("width", "780px")
        ]
        
        createRule ".search-table" [
            ("width", "780px")
            ("border", "0")
            ("cellpadding", "2")
            ("cellspacing", "0")
        ]
        
        createRule ".search-container" [
            ("display", "table-cell")
            ("vertical-align", "middle")
            ("margin", "0px")
        ]
        
        createRule ".search-form" [
            ("display", "inline")
        ]
        
        createRule ".search-input" [
            ("size", "20")
            ("maxlength", "255")
            ("value", "\"\"")
        ]
        
        createRule ".submit-button" [
            ("border", "0")
        ]
        
        createRule ".hidden-input" [
            ("display", "none")
        ]
        
        createRule ".banner" [
            ("text-align", "right")
            ("font-weight", "bold")
            ("margin", "0")
        ]
        
        createRule ".divider-yellow" [
            ("border-top", "1px solid #FFCE00")
            ("margin-bottom", "2px")
            ("width", "780px")
        ]
        
        createRule ".content-table" [
            ("width", "780px")
            ("border", "0")
            ("cellpadding", "0")
            ("cellspacing", "0")
        ]
        
        createRule ".keylist" [
            ("margin", "0")
            ("padding", "0")
        ]
        
        createRule ".keylist dt" [
            ("font-weight", "bold")
            ("margin-top", "10px")
        ]
        
        createRule ".keylist dd" [
            ("margin-left", "20px")
            ("margin-bottom", "10px")
        ]
        
        createRule ".footer" [
            ("text-align", "center")
            ("clear", "both")
        ]
        
        createRule ".footer small" [
            ("font-size", "12px")
        ]
        
        createRule ".footer a" [
            ("text-decoration", "none")
            ("color", "#000")
        ]
        
        createRule ".footer a:hover" [
            ("text-decoration", "underline")
        ]
        
        createRule ".clear" [
            ("clear", "both")
        ]
    ]
    
    StyleSheetBuilder.createStyleSheet comments rules

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Verwendung: %s <ausgabedatei>" argv.[0]
        1
    else
        try
            let stylesheet = createIndexStylesheet()
            let cssContent = CssGenerator.generateCss stylesheet
            File.WriteAllText(argv.[0], cssContent, Encoding.UTF8)
            printfn "CSS-Datei erfolgreich erstellt: %s" argv.[0]
            0
        with
        | ex ->
            printfn "Fehler beim Erstellen der CSS-Datei: %s" ex.Message
            1
