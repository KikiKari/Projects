// abstraction-provenance: {"artifact_sha256": "e2063945c8a4b7ecbaf57cc93be01e18ec3bc20f0db59ba8ea9c99d033a37f94", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "fsharp"}
// status-overview.css — portiert nach fsharp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type StyleSheet = CssRule list

let createCssRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let styleSheet : StyleSheet = [
    createCssRule "*" [
        ("box-sizing", "border-box")
    ]
    
    createCssRule "html,body" [
        ("margin", "0")
        ("min-height", "100%")
        ("background", "#101015")
        ("color", "#fff")
        ("font", "14px system-ui,sans-serif")
    ]
    
    createCssRule "body" [
        ("display", "flex")
        ("flex-direction", "column")
        ("height", "100vh")
    ]
    
    createCssRule "header" [
        ("display", "flex")
        ("gap", "1em")
        ("align-items", "baseline")
        ("padding", "0 12px")
    ]
    
    createCssRule "h1" [
        ("font-size", "17px")
        ("margin", "8px 0")
    ]
    
    createCssRule "header p" [
        ("font-size", "12px")
        ("color", "#bbb")
        ("margin", "0")
    ]
    
    createCssRule "main" [
        ("flex", "1")
        ("min-height", "0")
        ("display", "grid")
        ("grid-template-columns", "repeat(3,minmax(0,1fr))")
        ("grid-template-rows", "repeat(3,minmax(0,1fr))")
        ("gap", "4px")
        ("padding", "0")
    ]
    
    createCssRule ".tile" [
        ("min-width", "0")
        ("min-height", "0")
        ("display", "flex")
        ("flex-direction", "column")
        ("background", "#202026")
        ("border", "1px solid #393940")
    ]
    
    createCssRule ".tile h2" [
        ("font-size", "13px")
        ("margin", "3px 8px")
    ]
    
    createCssRule ".tile video" [
        ("min-height", "0")
        ("width", "100%")
        ("flex", "1")
        ("object-fit", "contain")
        ("background", "#000")
    ]
    
    createCssRule ".tile p" [
        ("font-size", "11px")
        ("margin", "3px 8px")
        ("color", "#ddd")
    ]
    
    createCssRule "main.grid2" [
        ("grid-template-columns", "repeat(2,minmax(0,1fr))")
        ("grid-template-rows", "repeat(2,minmax(0,1fr))")
    ]
    
    createCssRule ".tile[hidden]" [
        ("display", "none")
    ]
]

let formatCssRule (rule: CssRule) =
    let props = rule.Properties |> Map.toList |> List.map (fun (k, v) -> $"  {k}: {v}")
    $"{rule.Selector} {{{Environment.NewLine}{String.concat ";" props}{Environment.NewLine}}}"

let generateCss (styleSheet: StyleSheet) =
    styleSheet 
    |> List.map formatCssRule
    |> String.concat Environment.NewLine

let writeCssToFile filePath =
    let cssContent = generateCss styleSheet
    File.WriteAllText(filePath, cssContent)
    printfn "CSS file written to %s" filePath

// Main entry point - expects output file path as command line argument
[<EntryPoint>]
let main argv =
    match argv with
    | [| outputPath |] -> 
        writeCssToFile outputPath
        0
    | _ -> 
        printfn "Usage: program <output-file-path>"
        1
