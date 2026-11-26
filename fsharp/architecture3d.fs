// abstraction-provenance: {"artifact_sha256": "ca0c47cdd664b7d29fc5afd203a24c6cfb8ff47c404fc2ae8b3356024018b8e9", "source_sha256": "dbaea8c95e59c0899e7e4b8d3cced26cf954364749b998f1841e8d3d5f745baf", "target_language": "fsharp"}
// architecture3d.css — portiert nach fsharp
// Quelle: css, Projects@TikTok-Live-Companion:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-Android:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-iOS:site/src/architecture3d.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/src/architecture3d.css
// auch in: 1 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module Architecture3D

open System
open System.IO
open System.Text

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type MediaQuery = {
    Condition: string
    Rules: CssRule list
}

type StyleSheet = {
    Root: CssRule option
    Rules: CssRule list
    MediaQueries: MediaQuery list
}

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createMediaQuery condition rules =
    { Condition = condition; Rules = rules }

let styleSheet = {
    Root = Some(createRule ":root" ["color-scheme", "light"])
    Rules = [
        createRule ".architecture-3d-page" [
            "min-height", "100vh"
            "overflow-x", "hidden"
            "background", "#fffdf9"
            "color", "#14223c"
            "padding-bottom", "48px"
        ]
        
        createRule ".architecture-3d-header" [
            "min-height", "70px"
            "display", "flex"
            "align-items", "center"
            "justify-content", "space-between"
            "gap", "20px"
            "padding", "12px max(22px, calc((100vw - 1240px)/2))"
            "border-bottom", "1px solid #d9e2ec"
            "background", "rgba(255,253,249,.96)"
        ]
        
        createRule ".architecture-3d-header a" [
            "color", "#14223c"
            "text-decoration", "none"
            "font-weight", "800"
        ]
        
        createRule ".architecture-3d-header b" [
            "color", "#e5384f"
        ]
        
        createRule ".architecture-3d-header nav" [
            "display", "flex"
            "gap", "20px"
        ]
        
        createRule ".architecture-3d-intro, .architecture-3d-workspace, .architecture-3d-legend, .architecture-3d-note" [
            "width", "min(1240px, calc(100% - 36px))"
            "margin-inline", "auto"
        ]
        
        createRule ".architecture-3d-intro" [
            "padding", "54px 0 26px"
        ]
        
        createRule ".architecture-3d-intro h1" [
            "margin", "5px 0 15px"
            "font-size", "clamp(2.35rem, 5vw, 4.3rem)"
            "line-height", "1.02"
            "letter-spacing", "-.05em"
        ]
        
        createRule ".architecture-3d-intro > p:last-child" [
            "max-width", "820px"
            "color", "#526078"
            "font-size", "1.05rem"
            "line-height", "1.7"
        ]
        
        createRule ".architecture-3d-eyebrow" [
            "margin", "0"
            "color", "#0c8f9d"
            "font-size", ".73rem"
            "font-weight", "900"
            "letter-spacing", ".14em"
        ]
        
        createRule ".architecture-3d-workspace" [
            "display", "grid"
            "grid-template-columns", "minmax(0, 1fr) 290px"
            "gap", "18px"
        ]
        
        createRule ".architecture-3d-scene-shell" [
            "min-height", "650px"
            "position", "relative"
            "overflow", "hidden"
            "border-radius", "16px"
            "background", "#0f1729"
            "box-shadow", "0 20px 55px rgba(16,29,52,.22)"
        ]
        
        createRule ".architecture-3d-scene" [
            "position", "absolute"
            "inset", "0"
            "opacity", "0"
            "transition", "opacity .18s ease"
            "touch-action", "pan-y"
        ]
        
        createRule ".architecture-3d-scene.is-ready" [
            "opacity", "1"
        ]
        
        createRule ".architecture-3d-scene canvas" [
            "display", "block"
            "width", "100%"
            "height", "100%"
        ]
        
        createRule ".architecture-3d-scene:focus-visible" [
            "outline", "3px solid #25c5d2"
            "outline-offset", "-5px"
        ]
        
        createRule ".architecture-3d-fallback" [
            "position", "absolute"
            "inset", "0"
            "width", "100%"
            "height", "100%"
            "object-fit", "contain"
            "background", "#0f1729"
        ]
        
        createRule ".architecture-3d-controls" [
            "position", "absolute"
            "right", "14px"
            "top", "14px"
            "display", "flex"
            "gap", "8px"
            "z-index", "4"
        ]
        
        createRule ".architecture-3d-controls button, .architecture-3d-step button" [
            "min-height", "44px"
            "border", "1px solid #60708a"
            "border-radius", "9px"
            "background", "rgba(15,23,41,.88)"
            "color", "white"
            "padding", "9px 13px"
            "font-weight", "800"
            "cursor", "pointer"
        ]
        
        createRule ".architecture-3d-inspector" [
            "align-self", "stretch"
            "padding", "24px"
            "border", "1px solid #d4dee8"
            "border-radius", "16px"
            "background", "white"
        ]
        
        createRule ".architecture-3d-inspector h2" [
            "margin", "9px 0"
            "font-size", "1.45rem"
        ]
        
        createRule ".architecture-3d-inspector > p:not(.architecture-3d-eyebrow)" [
            "color", "#526078"
            "min-height", "48px"
        ]
        
        createRule ".architecture-3d-inspector dl" [
            "margin", "25px 0"
        ]
        
        createRule ".architecture-3d-inspector dl div" [
            "padding", "12px 0"
            "border-bottom", "1px solid #e2e8f0"
        ]
        
        createRule ".architecture-3d-inspector dt" [
            "color", "#758198"
            "font-size", ".74rem"
            "text-transform", "uppercase"
            "letter-spacing", ".08em"
        ]
        
        createRule ".architecture-3d-inspector dd" [
            "margin", "4px 0 0"
            "font-weight", "800"
            "overflow-wrap", "anywhere"
        ]
        
        createRule ".architecture-3d-step" [
            "display", "grid"
            "grid-template-columns", "1fr 1fr"
            "gap", "8px"
        ]
        
        createRule ".architecture-3d-step button" [
            "background", "#14223c"
        ]
        
        createRule ".architecture-3d-legend" [
            "display", "flex"
            "flex-wrap", "wrap"
            "gap", "24px"
            "padding", "23px 0 10px"
        ]
        
        createRule ".architecture-3d-legend span" [
            "display", "inline-flex"
            "align-items", "center"
            "gap", "9px"
            "font-size", ".85rem"
            "font-weight", "750"
        ]
        
        createRule ".architecture-3d-legend i" [
            "width", "30px"
            "height", "4px"
            "display", "inline-block"
            "background", "#25c5d2"
        ]
        
        createRule ".architecture-3d-legend i.audio" [
            "background", "#ff557a"
        ]
        
        createRule ".architecture-3d-legend i.token" [
            "background", "repeating-linear-gradient(90deg,#e9a12d 0 7px,transparent 7px 11px)"
        ]
        
        createRule ".architecture-3d-note" [
            "color", "#66758a"
            "font-size", ".82rem"
        ]
    ]
    
    MediaQueries = [
        createMediaQuery "(max-width: 820px)" [
            createRule ".architecture-3d-workspace" [
                "grid-template-columns", "1fr"
            ]
            createRule ".architecture-3d-scene-shell" [
                "min-height", "520px"
            ]
            createRule ".architecture-3d-inspector" [
                "order", "2"
            ]
        ]
        
        createMediaQuery "(max-width: 520px)" [
            createRule ".architecture-3d-header" [
                "padding-inline", "16px"
                "gap", "8px"
                "font-size", ".82rem"
            ]
            createRule ".architecture-3d-header nav" [
                "gap", "10px"
            ]
            createRule ".architecture-3d-intro" [
                "padding-top", "35px"
            ]
            createRule ".architecture-3d-intro h1" [
                "font-size", "clamp(2rem, 10vw, 2.75rem)"
                "overflow-wrap", "anywhere"
            ]
            createRule ".architecture-3d-intro > p:last-child" [
                "overflow-wrap", "anywhere"
            ]
            createRule ".architecture-3d-scene-shell" [
                "min-height", "460px"
            ]
            createRule ".architecture-3d-controls" [
                "left", "10px"
                "right", "10px"
                "justify-content", "space-between"
            ]
            createRule ".architecture-3d-controls button" [
                "min-width", "44px"
                "padding-inline", "8px"
                "font-size", ".77rem"
            ]
            createRule ".architecture-3d-legend" [
                "display", "grid"
                "gap", "12px"
            ]
        ]
        
        createMediaQuery "(prefers-reduced-motion: reduce)" [
            createRule ".architecture-3d-scene" [
                "transition", "none"
            ]
        ]
    ]
}

let formatProperties (properties: Map<string, string>) =
    properties
    |> Map.toList
    |> List.map (fun (key, value) -> $"  {key}: {value};")
    |> String.concat "\n"

let formatRule (rule: CssRule) =
    $"{rule.Selector} {{\n{formatProperties rule.Properties}\n}}"

let formatMediaQuery (mediaQuery: MediaQuery) =
    let rules = mediaQuery.Rules |> List.map formatRule |> String.concat "\n"
    $"@media {mediaQuery.Condition} {{\n{rules}\n}}"

let generateCSS (styleSheet: StyleSheet) =
    let sb = StringBuilder()
    
    match styleSheet.Root with
    | Some root -> sb.AppendLine(formatRule root) |> ignore
    | None -> ()
    
    styleSheet.Rules 
    |> List.iter (formatRule >> sb.AppendLine >> ignore)
    
    styleSheet.MediaQueries 
    |> List.iter (formatMediaQuery >> sb.AppendLine >> ignore)
    
    sb.ToString()

[<EntryPoint>]
let main args =
    let cssContent = generateCSS styleSheet
    
    match args with
    | [| filename |] -> 
        File.WriteAllText(filename, cssContent)
        printfn "CSS file generated: %s" filename
    | _ -> 
        printfn "Usage: program <output-file>"
        printfn "\nGenerated CSS:\n%s" cssContent
    
    0
