// abstraction-provenance: {"artifact_sha256": "4a715b3890fbe5f1ad777b9b0998edc88dc7ce72f1205074eced38e05aca0045", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "fsharp"}
// index_57e3e2.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

// F# Programm zur Erzeugung der CSS-Datei index_57e3e2.css
open System
open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type StyleSheet = CssRule list

let createRule selector properties =
    { Selector = selector; Properties = Map.ofList properties }

let formatCss (rules: StyleSheet) =
    rules
    |> List.map (fun rule ->
        let props = 
            rule.Properties
            |> Map.toList
            |> List.map (fun (key, value) -> $"  {key}: {value};")
            |> String.concat "\n"
        $"{rule.Selector} {{\n{props}\n}}"
    )
    |> String.concat "\n\n"

let generateStylesheet() : StyleSheet =
    [
        // Kommentare werden als spezielle Regeln behandelt
        createRule "/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */" []
        createRule "/* index.html — portiert nach css */" []
        createRule "/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */" []
        createRule "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */" []

        createRule ":root" [
            "color-scheme", "light"
        ]

        createRule "*" [
            "box-sizing", "border-box"
        ]

        createRule "body" [
            "margin", "0"
            "font-family", "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif"
            "background", "#f7f7f5"
            "color", "#1d1c1a"
        ]

        createRule ".wrap" [
            "max-width", "880px"
            "margin", "0 auto"
            "padding", "20px 16px 60px"
        ]

        createRule "h1" [
            "font-size", "22px"
            "margin", "0 0 2px"
        ]

        createRule ".sub" [
            "color", "#6b6a66"
            "font-size", "13px"
            "margin-bottom", "16px"
        ]

        createRule ".bar" [
            "display", "flex"
            "gap", "10px"
            "align-items", "center"
            "margin-bottom", "16px"
            "flex-wrap", "wrap"
        ]

        createRule "button" [
            "font-size", "13px"
            "font-weight", "600"
            "padding", "7px 13px"
            "border", "1px solid #d9d8d3"
            "border-radius", "8px"
            "background", "#fff"
            "cursor", "pointer"
        ]

        createRule "button:hover" [
            "background", "#f2f1ec"
        ]

        createRule "button.primary" [
            "background", "#1d1c1a"
            "color", "#fff"
            "border-color", "#1d1c1a"
        ]

        createRule ".note" [
            "background", "#fffdf4"
            "border", "1px solid #f0e9c8"
            "border-radius", "10px"
            "padding", "12px 14px"
            "font-size", "13px"
            "color", "#4a4734"
            "margin-bottom", "16px"
            "line-height", "1.5"
        ]

        createRule ".section" [
            "background", "#fff"
            "border", "1px solid #e8e7e3"
            "border-radius", "12px"
            "margin-bottom", "14px"
            "overflow", "hidden"
        ]

        createRule ".section > h2" [
            "font-size", "15px"
            "margin", "0"
            "padding", "13px 16px"
            "border-bottom", "1px solid #efeee9"
            "display", "flex"
            "align-items", "center"
            "gap", "9px"
        ]

        createRule ".section > h2 .badge" [
            "margin-left", "auto"
            "font-size", "12px"
            "font-weight", "600"
            "background", "#efeee9"
            "color", "#5a5852"
            "padding", "2px 9px"
            "border-radius", "20px"
        ]

        createRule ".body" [
            "padding", "8px 16px 14px"
            "font-size", "14px"
        ]

        createRule ".muted" [
            "color", "#8a8884"
        ]

        createRule ".err" [
            "color", "#c0392b"
        ]

        createRule ".kv" [
            "display", "flex"
            "justify-content", "space-between"
            "padding", "4px 0"
            "border-bottom", "1px solid #f4f3ee"
        ]

        createRule ".kv:last-child" [
            "border", "none"
        ]

        createRule ".kv .k" [
            "color", "#6b6a66"
        ]

        createRule ".kv .v" [
            "font-weight", "600"
        ]

        createRule "a" [
            "color", "#2b5cc4"
            "text-decoration", "none"
        ]

        createRule "a:hover" [
            "text-decoration", "underline"
        ]

        createRule ".modal" [
            "position", "fixed"
            "inset", "0"
            "background", "rgba(0, 0, 0, .35)"
            "display", "none"
            "align-items", "flex-start"
            "justify-content", "center"
            "padding", "40px 16px"
            "overflow", "auto"
        ]

        createRule ".modal.open" [
            "display", "flex"
        ]

        createRule ".card" [
            "background", "#fff"
            "border-radius", "14px"
            "max-width", "560px"
            "width", "100%"
            "padding", "20px"
        ]

        createRule ".card h3" [
            "margin", "0 0 4px"
            "font-size", "17px"
        ]

        createRule ".card p.hint" [
            "margin", "0 0 16px"
            "font-size", "12px"
            "color", "#8a8884"
        ]

        createRule ".field" [
            "margin-bottom", "12px"
        ]

        createRule ".field label" [
            "display", "block"
            "font-size", "12px"
            "font-weight", "600"
            "color", "#5a5852"
            "margin-bottom", "3px"
        ]

        createRule ".field input" [
            "width", "100%"
            "font-size", "13px"
            "padding", "7px 9px"
            "border", "1px solid #d9d8d3"
            "border-radius", "7px"
            "font-family", "ui-monospace, Menlo, monospace"
        ]

        createRule ".field .desc" [
            "font-size", "11px"
            "color", "#a8a6a1"
            "margin-top", "2px"
        ]

        createRule ".actions" [
            "display", "flex"
            "gap", "10px"
            "justify-content", "flex-end"
            "margin-top", "8px"
        ]

        createRule ".warn" [
            "background", "#fdf3f3"
            "border", "1px solid #f3d9d9"
            "color", "#9a3b3b"
            "border-radius", "8px"
            "padding", "10px 12px"
            "font-size", "12px"
            "margin-bottom", "14px"
        ]
    ]

[<EntryPoint>]
let main argv =
    let stylesheet = generateStylesheet()
    let cssContent = formatCss stylesheet
    
    let outputPath = 
        if argv.Length > 0 then argv.[0]
        else "index_57e3e2.css"
    
    File.WriteAllText(outputPath, cssContent)
    printfn "CSS file generated: %s" outputPath
    0
