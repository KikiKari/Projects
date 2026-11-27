// abstraction-provenance: {"artifact_sha256": "f0edd620e8d459f8348b9fd4cfc0c7a95c9579ac7941c1e754dd9c5d7aa5bfab", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "fsharp"}
// index_f17dea.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_f17dea.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type MediaQuery = {
    Condition: string
    Rules: CssRule list
}

type StyleSheet = {
    Rules: CssRule list
    MediaQueries: MediaQuery list
}

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let createMediaQuery condition rules =
    { Condition = condition; Rules = rules }

let styleSheet = {
    Rules = [
        // General Styles
        createRule "html" [
            "scroll-padding-top", "60px"
        ]
        
        createRule "body.has-navbar-fixed-top" [
            "padding-top", "60px"
        ]
        
        // Navbar Styles
        createRule ".navbar.is-fixed-top" [
            "position", "fixed"
            "top", "0"
            "left", "0"
            "right", "0"
            "z-index", "30"
            "min-height", "3.25rem"
        ]
        
        createRule ".navbar.is-flex-touch" [
            "display", "flex"
        ]
        
        createRule ".container.is-justify-content-space-around" [
            "justify-content", "space-around"
        ]
        
        createRule ".navbar-brand" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".navbar-logo" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".navbar-logo-tm" [
            "font-size", "0.75rem"
            "margin-left", "0.25rem"
        ]
        
        createRule ".navbar-burger" [
            "display", "block"
            "position", "relative"
            "cursor", "pointer"
        ]
        
        createRule ".navbar-burger span" [
            "display", "block"
            "height", "1px"
            "width", "20px"
            "background-color", "currentColor"
            "margin", "5px 0"
            "transition", "transform 0.3s ease"
        ]
        
        createRule ".navbar-menu" [
            "display", "none"
        ]
        
        createRule ".navbar-start" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".navbar-end" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".navbar-item" [
            "display", "block"
            "padding", "0.5rem 0.75rem"
        ]
        
        createRule ".navbar-link" [
            "display", "block"
            "padding", "0.5rem 0.75rem"
        ]
        
        createRule ".navbar-dropdown" [
            "display", "none"
            "position", "absolute"
            "top", "100%"
            "left", "0"
            "background-color", "white"
            "border-radius", "4px"
            "box-shadow", "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1)"
        ]
        
        createRule ".navbar-dropdown.is-right" [
            "left", "auto"
            "right", "0"
        ]
        
        createRule ".navbar-dropdown.is-rounded" [
            "border-radius", "4px"
        ]
        
        createRule ".navbar-divider" [
            "display", "block"
            "height", "1px"
            "background-color", "#dbdbdb"
            "margin", "0.5rem 0"
        ]
        
        createRule ".has-dropdown:hover .navbar-dropdown" [
            "display", "block"
        ]
        
        createRule ".navbar-search-wrapper" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".field.has-addons" [
            "display", "flex"
        ]
        
        createRule ".control" [
            "position", "relative"
        ]
        
        createRule ".autoComplete_options" [
            "flex-grow", "1"
        ]
        
        createRule ".input" [
            "display", "block"
            "width", "100%"
            "padding", "0.375rem 0.75rem"
            "font-size", "1rem"
            "line-height", "1.5"
            "color", "#495057"
            "background-color", "#fff"
            "background-clip", "padding-box"
            "border", "1px solid #ced4da"
            "border-radius", "0.25rem"
            "transition", "border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out"
        ]
        
        createRule ".button.is-primary" [
            "background-color", "#00d1b2"
            "border-color", "transparent"
            "color", "#fff"
        ]
        
        createRule ".icon" [
            "display", "inline-flex"
            "justify-content", "center"
            "align-items", "center"
        ]
        
        createRule ".modal" [
            "position", "fixed"
            "top", "0"
            "left", "0"
            "right", "0"
            "bottom", "0"
            "z-index", "40"
            "display", "none"
            "opacity", "0"
            "transition", "opacity 0.15s linear"
        ]
        
        createRule ".modal.is-active" [
            "display", "flex"
            "opacity", "1"
        ]
        
        createRule ".modal-background" [
            "position", "absolute"
            "top", "0"
            "left", "0"
            "right", "0"
            "bottom", "0"
            "background-color", "rgba(10, 10, 10, 0.86)"
        ]
        
        createRule ".modal-content" [
            "position", "relative"
            "width", "100%"
            "max-height", "calc(100vh - 160px)"
            "overflow", "auto"
            "margin", "0 auto"
            "padding", "20px"
        ]
        
        createRule ".box" [
            "background-color", "white"
            "border-radius", "6px"
            "box-shadow", "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02)"
            "padding", "1.25rem"
        ]
        
        createRule ".modal-close" [
            "position", "absolute"
            "top", "20px"
            "right", "20px"
            "width", "40px"
            "height", "40px"
            "background", "none"
            "border", "none"
            "cursor", "pointer"
        ]
        
        createRule ".options-search-controls" [
            "display", "flex"
            "flex-direction", "column"
            "gap", "1rem"
        ]
        
        createRule ".centreToggle" [
            "display", "flex"
            "align-items", "center"
            "gap", "0.5rem"
        ]
        
        createRule ".centreToggle input[type=\"checkbox\"]" [
            "width", "var(--switch-width, 10.5em)"
            "height", "2em"
            "appearance", "none"
            "background", "#ccc"
            "border-radius", "1em"
            "position", "relative"
            "cursor", "pointer"
        ]
        
        createRule ".centreToggle input[type=\"checkbox\"]:checked" [
            "background", "#00d1b2"
        ]
        
        createRule ".centreToggle input[type=\"checkbox\"]::before" [
            "content", "''"
            "position", "absolute"
            "width", "1.6em"
            "height", "1.6em"
            "background", "white"
            "border-radius", "50%"
            "top", "0.2em"
            "left", "0.2em"
            "transition", "transform 0.3s"
        ]
        
        createRule ".centreToggle input[type=\"checkbox\"]:checked::before" [
            "transform", "translateX(calc(var(--switch-width, 10.5em) - 2em))"
        ]
        
        createRule ".centreToggle .text" [
            "font-weight", "bold"
        ]
        
        createRule ".centreToggle .on" [
            "font-weight", "bold"
            "position", "absolute"
            "top", "50%"
            "transform", "translateY(-50%)"
            "left", "0.5em"
            "color", "white"
        ]
        
        createRule ".centreToggle .off" [
            "font-weight", "bold"
            "position", "absolute"
            "top", "50%"
            "transform", "translateY(-50%)"
            "right", "0.5em"
            "color", "#333"
        ]
        
        // Hero Section
        createRule ".hero.is-medium" [
            "min-height", "300px"
        ]
        
        createRule ".hero.is-primary" [
            "background-color", "#00d1b2"
            "color", "#fff"
        ]
        
        createRule ".hero-body" [
            "padding", "3rem 1.5rem"
        ]
        
        createRule ".title.is-1" [
            "font-size", "3rem"
        ]
        
        createRule ".subtitle.is-4" [
            "font-size", "1.5rem"
        ]
        
        createRule ".mt-3" [
            "margin-top", "0.75rem"
        ]
        
        createRule ".has-text-centered" [
            "text-align", "center"
        ]
        
        // Cards
        createRule ".card-home" [
            "border-radius", "6px"
            "box-shadow", "0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02)"
            "background-color", "white"
            "margin-bottom", "1.5rem"
        ]
        
        createRule ".card-content" [
            "padding", "1.5rem"
        ]
        
        createRule ".content.has-text-centered" [
            "text-align", "center"
        ]
        
        createRule ".title.is-5" [
            "font-size", "1.25rem"
            "margin-bottom", "0.5rem"
        ]
        
        createRule ".has-text-primary" [
            "color", "#00d1b2 !important"
        ]
        
        createRule ".icon.is-large" [
            "font-size", "2rem"
        ]
        
        // Links Block
        createRule ".raku.links-block" [
            "background-color", "#f5f5f5"
            "padding", "2rem 0"
        ]
        
        createRule ".columns.is-vcentered" [
            "align-items", "center"
        ]
        
        createRule ".column.is-one-third" [
            "flex", "none"
            "width", "33.3333%"
        ]
        
        createRule ".column.is-two-thirds" [
            "flex", "none"
            "width", "66.6666%"
        ]
        
        createRule ".pt-5" [
            "padding-top", "1.5rem"
        ]
        
        createRule ".head" [
            "font-weight", "bold"
            "margin-bottom", "0.5rem"
        ]
        
        // Footer
        createRule ".footer.main-footer" [
            "background-color", "#fafafa"
            "padding", "3rem 1.5rem"
        ]
        
        createRule ".level" [
            "display", "flex"
            "justify-content", "space-between"
            "align-items", "center"
        ]
        
        createRule ".level-left" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".level-right" [
            "display", "flex"
            "align-items", "center"
        ]
        
        createRule ".level-item" [
            "margin", "0 0.5rem"
        ]
    ]
    
    MediaQueries = [
        createMediaQuery "screen and (max-width: 1023px)" [
            createRule ".navbar-menu" [
                "background-color", "white"
                "box-shadow", "0 8px 16px rgba(10, 10, 10, 0.1)"
                "padding", "0.5rem 0"
            ]
            
            createRule ".navbar-menu.is-active" [
                "display", "block"
            ]
            
            createRule ".navbar-end" [
                "margin-top", "1rem"
            ]
        ]
        
        createMediaQuery "screen and (max-width: 768px)" [
            createRule ".title.is-1.is-size-2-mobile" [
                "font-size", "2rem"
            ]
            
            createRule ".columns.is-multiline" [
                "display", "flex"
                "flex-wrap", "wrap"
            ]
            
            createRule ".column.is-one-half" [
                "width", "100%"
            ]
            
            createRule ".column.is-one-third" [
                "width", "100%"
            ]
            
            createRule ".raku.links-block .columns" [
                "flex-direction", "column"
            ]
            
            createRule ".column.is-one-third" [
                "width", "100%"
            ]
            
            createRule ".column.is-two-thirds" [
                "width", "100%"
            ]
        ]
    ]
}

let formatRule rule =
    let props = rule.Properties |> Map.toList |> List.map (fun (key, value) -> $"    {key}: {value};") |> String.concat "\n"
    $"{rule.Selector} {{\n{props}\n}}"

let formatMediaQuery mq =
    let rules = mq.Rules |> List.map formatRule |> String.concat "\n\n"
    $"@media {mq.Condition} {{\n{rules}\n}}"

let generateCSS (stylesheet: StyleSheet) =
    let rules = stylesheet.Rules |> List.map formatRule |> String.concat "\n\n"
    let mediaQueries = stylesheet.MediaQueries |> List.map formatMediaQuery |> String.concat "\n\n"
    $"{rules}\n\n{mediaQueries}"

// Kommentare hinzufügen
let addComments (cssContent: string) =
    let header = 
        "/* abstraction-provenance: {\"artifact_sha256\": \"9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204\", \"source_sha256\": \"f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37\", \"target_language\": \"css\"} */\n" +
        "/* index.html — portiert nach css */\n" +
        "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */\n" +
        "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */\n" +
        "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n"
    
    header + cssContent

[<EntryPoint>]
let main argv =
    let cssContent = generateCSS styleSheet |> addComments
    
    match argv with
    | [||] -> 
        Console.WriteLine(cssContent)
        0
    | [|filename|] -> 
        File.WriteAllText(filename, cssContent)
        0
    | _ -> 
        Console.Error.WriteLine("Usage: program [<output-file>]")
        1
