// abstraction-provenance: {"artifact_sha256": "17fd399021b158f4c570ad32825b9d47de3fee3e009e5350cabd21e5a2973c96", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "fsharp"}
// peak-limiter.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/peak-limiter.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type CssDocument = {
    Comments: string list
    Rules: CssRule list
}

let createCssRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createCssDocument comments rules =
    { Comments = comments; Rules = rules }

let formatCssRule (rule: CssRule) =
    let propertyStrings = 
        rule.Properties
        |> Map.toList
        |> List.map (fun (key, value) -> $"  {key}: {value};")
    String.concat Environment.NewLine (rule.Selector + " {" :: propertyStrings @ ["}"])

let formatCssDocument (doc: CssDocument) =
    let commentLines = doc.Comments |> List.map (fun c -> $"/* {c} */")
    let ruleLines = doc.Rules |> List.map formatCssRule
    String.concat (Environment.NewLine + Environment.NewLine) (commentLines @ ruleLines)

let generatePeakLimiterCss () =
    let comments = [
        "abstraction-provenance: {\"artifact_sha256\": \"3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d\", \"source_sha256\": \"162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b\", \"target_language\": \"css\"}"
        "peak-limiter.html — portiert nach css"
        "Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html"
        "auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html"
        "auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html"
        "auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html"
        "Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py"
    ]
    
    let rules = [
        createCssRule "body" [
            "font", "16px system-ui"
            "max-width", "1000px"
            "margin", "40px auto"
            "padding", "20px"
        ]
        createCssRule "pre" [
            "white-space", "pre-wrap"
        ]
        createCssRule "button" [
            "padding", "12px"
        ]
    ]
    
    createCssDocument comments rules

[<EntryPoint>]
let main argv =
    let cssDocument = generatePeakLimiterCss()
    let cssContent = formatCssDocument cssDocument
    
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "peak-limiter.css"
    
    File.WriteAllText(outputPath, cssContent)
    printfn $"CSS file written to {outputPath}"
    0
