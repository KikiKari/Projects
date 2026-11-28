// abstraction-provenance: {"artifact_sha256": "7303ad356124e4385de7a9dce9759f5b42f4c8cf5e62d5dbb0af745741b3a0ee", "source_sha256": "58d92c4f40bf7edb6d494c682f4fa1268aea0c52ab326535c779d2f2c808fffd", "target_language": "fsharp"}
// index_02dd11.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_02dd11.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

// index_02dd11.fs
// Erzeugt CSS-Dokument basierend auf dem Original

open System
open System.IO

type CssVariable = {
    Name: string
    Value: string
}

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type MediaQuery = {
    Condition: string
    Rules: CssRule list
}

type StyleSheet = {
    Variables: CssVariable list
    Rules: CssRule list
    MediaQueries: MediaQuery list
}

let createStyleSheet () : StyleSheet = {
    Variables = [
        { Name = "--bg-dark"; Value = "#0a0f1e" }
        { Name = "--bg-card"; Value = "#121826" }
        { Name = "--bg-panel"; Value = "#1a2236" }
        { Name = "--border"; Value = "#25324d" }
        { Name = "--text-main"; Value = "#e6ecf5" }
        { Name = "--text-muted"; Value = "#a0b0cc" }
        { Name = "--text-dim"; Value = "#6c7a96" }
        { Name = "--accent"; Value = "#5d8aff" }
        { Name = "--accent-hover"; Value = "#7a9fff" }
        { Name = "--accent-warn"; Value = "#fbd38d" }
        { Name = "--layer-0"; Value = "#ff7eb9" }
        { Name = "--layer-1"; Value = "#4fd1c5" }
        { Name = "--layer-2"; Value = "#ffd166" }
        { Name = "--layer-3-gpt"; Value = "#6a5acd" }
        { Name = "--layer-3-gemini"; Value = "#4285f4" }
        { Name = "--layer-3-claude"; Value = "#f4a261" }
    ]
    
    Rules = [
        // Basis-Stile
        { Selector = "*"; Properties = Map [("box-sizing", "border-box"); ("margin", "0"); ("padding", "0")] }
        
        { Selector = "body"
          Properties = Map [
            ("font-family", "'Inter', sans-serif")
            ("background", "var(--bg-dark)")
            ("color", "var(--text-main)")
            ("line-height", "1.5")
            ("overflow", "hidden")
            ("height", "100vh")
            ("display", "flex")
            ("flex-direction", "column")
          ] }
        
        // Header
        { Selector = "#app-header"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "space-between")
            ("padding", "12px 20px")
            ("background", "rgba(10, 15, 30, 0.8)")
            ("backdrop-filter", "blur(10px)")
            ("border-bottom", "1px solid var(--border)")
            ("position", "relative")
            ("z-index", "10")
          ] }
          
        { Selector = ".header-brand"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "10px")
          ] }
          
        { Selector = ".header-brand h1"
          Properties = Map [
            ("font-size", "18px")
            ("font-weight", "600")
            ("color", "var(--text-main)")
          ] }
          
        { Selector = ".layer-indicator"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "4px")
          ] }
          
        { Selector = ".layer-dot"
          Properties = Map [
            ("width", "8px")
            ("height", "8px")
            ("border-radius", "50%")
            ("opacity", "0.4")
          ] }
          
        { Selector = ".layer-dot.active"
          Properties = Map [
            ("opacity", "1")
            ("box-shadow", "0 0 6px currentColor")
          ] }
          
        { Selector = ".header-controls"
          Properties = Map [
            ("display", "flex")
            ("gap", "8px")
          ] }
          
        // Hauptbereich
        { Selector = "#board"
          Properties = Map [
            ("display", "flex")
            ("flex", "1")
            ("overflow", "hidden")
            ("padding", "16px")
            ("gap", "16px")
          ] }
          
        // Kamera-Panel
        { Selector = "#camera-panel"
          Properties = Map [
            ("flex", "1")
            ("display", "flex")
            ("flex-direction", "column")
            ("background", "var(--bg-card)")
            ("border-radius", "16px")
            ("border", "1px solid var(--border)")
            ("overflow", "hidden")
            ("min-width", "320px")
          ] }
          
        { Selector = ".panel-header"
          Properties = Map [
            ("display", "flex")
            ("justify-content", "space-between")
            ("align-items", "center")
            ("padding", "12px 16px")
            ("border-bottom", "1px solid var(--border)")
          ] }
          
        { Selector = ".panel-title"
          Properties = Map [
            ("font-size", "12px")
            ("font-weight", "600")
            ("text-transform", "uppercase")
            ("letter-spacing", "0.5px")
            ("color", "var(--text-muted)")
          ] }
          
        { Selector = ".badge"
          Properties = Map [
            ("font-size", "10px")
            ("padding", "2px 6px")
            ("border-radius", "4px")
            ("background", "rgba(106, 90, 205, 0.15)")
            ("color", "var(--layer-3-gpt)")
            ("border", "1px solid rgba(106, 90, 205, 0.3)")
          ] }
          
        { Selector = ".badge-idle"
          Properties = Map [
            ("background", "rgba(106, 205, 172, 0.15)")
            ("color", "#6acda5")
            ("border", "1px solid rgba(106, 205, 172, 0.3)")
          ] }
          
        { Selector = "#camera-viewport"
          Properties = Map [
            ("position", "relative")
            ("flex", "1")
            ("background", "#000")
            ("overflow", "hidden")
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "center")
          ] }
          
        { Selector = "#video, #canvas-overlay, #snap-canvas, #filtered-canvas"
          Properties = Map [
            ("position", "absolute")
            ("top", "0")
            ("left", "0")
            ("width", "100%")
            ("height", "100%")
            ("object-fit", "contain")
          ] }
          
        { Selector = "#canvas-overlay"
          Properties = Map [
            ("pointer-events", "none")
            ("z-index", "2")
          ] }
          
        { Selector = "#start-overlay"
          Properties = Map [
            ("position", "absolute")
            ("inset", "0")
            ("display", "flex")
            ("flex-direction", "column")
            ("align-items", "center")
            ("justify-content", "center")
            ("gap", "16px")
            ("background", "rgba(10, 15, 30, 0.8)")
            ("z-index", "5")
          ] }
          
        { Selector = "#pixel-loupe"
          Properties = Map [
            ("position", "absolute")
            ("bottom", "20px")
            ("right", "20px")
            ("background", "rgba(0, 0, 0, 0.7)")
            ("border-radius", "8px")
            ("padding", "8px")
            ("display", "none")
            ("flex-direction", "column")
            ("align-items", "center")
            ("gap", "6px")
            ("z-index", "3")
          ] }
          
        { Selector = "#loupe-canvas"
          Properties = Map [
            ("width", "80px")
            ("height", "80px")
            ("image-rendering", "pixelated")
            ("border", "1px solid rgba(255, 255, 255, 0.1)")
          ] }
          
        { Selector = "#loupe-info"
          Properties = Map [
            ("font-size", "10px")
            ("color", "var(--text-dim)")
          ] }
          
        { Selector = "#camera-controls"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("padding", "12px 16px")
            ("gap", "12px")
            ("border-top", "1px solid var(--border)")
          ] }
          
        { Selector = "select"
          Properties = Map [
            ("background", "var(--bg-panel)")
            ("color", "var(--text-main)")
            ("border", "1px solid var(--border)")
            ("border-radius", "6px")
            ("padding", "6px 10px")
            ("font-size", "12px")
          ] }
          
        // Rechtes Panel
        { Selector = "#right-panel"
          Properties = Map [
            ("width", "320px")
            ("display", "flex")
            ("flex-direction", "column")
            ("gap", "16px")
          ] }
          
        { Selector = ".card"
          Properties = Map [
            ("background", "var(--bg-card)")
            ("border-radius", "16px")
            ("border", "1px solid var(--border)")
            ("overflow", "hidden")
            ("display", "flex")
            ("flex-direction", "column")
          ] }
          
        { Selector = ".card-body"
          Properties = Map [
            ("padding", "16px")
            ("flex", "1")
          ] }
          
        { Selector = ".slider-row"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
            ("margin-bottom", "12px")
          ] }
          
        { Selector = ".slider-label"
          Properties = Map [
            ("font-size", "12px")
            ("width", "100px")
            ("color", "var(--text-muted)")
          ] }
          
        { Selector = "input[type=\"range\"]"
          Properties = Map [
            ("flex", "1")
            ("height", "4px")
            ("-webkit-appearance", "none")
            ("background", "var(--bg-panel)")
            ("border-radius", "2px")
            ("outline", "none")
          ] }
          
        { Selector = "input[type=\"range\"]::-webkit-slider-thumb"
          Properties = Map [
            ("-webkit-appearance", "none")
            ("width", "16px")
            ("height", "16px")
            ("border-radius", "50%")
            ("background", "var(--accent)")
            ("cursor", "pointer")
          ] }
          
        { Selector = ".slider-value"
          Properties = Map [
            ("font-size", "12px")
            ("width", "40px")
            ("text-align", "right")
            ("color", "var(--text-muted)")
          ] }
          
        // Tabs
        { Selector = ".tab-bar"
          Properties = Map [
            ("display", "flex")
            ("border-bottom", "1px solid var(--border)")
          ] }
          
        { Selector = ".tab"
          Properties = Map [
            ("flex", "1")
            ("padding", "10px 12px")
            ("font-size", "12px")
            ("background", "transparent")
            ("border", "none")
            ("color", "var(--text-dim)")
            ("cursor", "pointer")
            ("text-align", "center")
          ] }
          
        { Selector = ".tab.active"
          Properties = Map [
            ("color", "var(--text-main)")
            ("border-bottom", "2px solid var(--accent)")
            ("background", "rgba(93, 138, 255, 0.05)")
          ] }
          
        { Selector = ".tab-content"
          Properties = Map [
            ("display", "none")
          ] }
          
        { Selector = ".tab-content.active"
          Properties = Map [
            ("display", "block")
          ] }
          
        // Status-Leiste
        { Selector = "#status-bar"
          Properties = Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
            ("padding", "8px 20px")
            ("background", "rgba(10, 15, 30, 0.6)")
            ("border-top", "1px solid var(--border)")
            ("font-size", "12px")
            ("color", "var(--text-dim)")
          ] }
          
        { Selector = ".status-dot"
          Properties = Map [
            ("width", "8px")
            ("height", "8px")
            ("border-radius", "50%")
            ("background", "#6acda5")
          ] }
          
        { Selector = ".status-dot.loading"
          Properties = Map [
            ("background", "#fbd38d")
            ("animation", "pulse 1.5s infinite")
          ] }
          
        // Buttons
        { Selector = ".btn"
          Properties = Map [
            ("display", "inline-flex")
            ("align-items", "center")
            ("gap", "6px")
            ("padding", "8px 12px")
            ("border-radius", "8px")
            ("border", "1px solid var(--border)")
            ("background", "var(--bg-panel)")
            ("color", "var(--text-main)")
            ("font-size", "12px")
            ("font-weight", "500")
            ("cursor", "pointer")
            ("transition", "all 0.2s ease")
          ] }
          
        { Selector = ".btn:hover"
          Properties = Map [
            ("background", "rgba(93, 138, 255, 0.1)")
            ("border-color", "var(--accent)")
          ] }
          
        { Selector = ".btn:disabled"
          Properties = Map [
            ("opacity", "0.5")
            ("cursor", "not-allowed")
          ] }
          
        { Selector = ".btn-primary"
          Properties = Map [
            ("background", "var(--accent)")
            ("border-color", "var(--accent)")
            ("color", "white")
          ] }
          
        { Selector = ".btn-primary:hover:not(:disabled)"
          Properties = Map [
            ("background", "var(--accent-hover)")
            ("border-color", "var(--accent-hover)")
          ] }
          
        { Selector = ".btn-icon"
          Properties = Map [
            ("padding", "8px")
          ] }
          
        { Selector = ".btn-snap"
          Properties = Map [
            ("background", "linear-gradient(135deg, #ff7eb9, #ff758c)")
            ("border", "1px solid #ff7eb9")
            ("color", "white")
          ] }
          
        { Selector = ".btn-sm"
          Properties = Map [
            ("padding", "4px 8px")
            ("font-size", "11px")
          ] }
          
        // Spinner
        { Selector = ".spinner"
          Properties = Map [
            ("width", "16px")
            ("height", "16px")
            ("border", "2px solid rgba(255, 255, 255, 0.2)")
            ("border-left-color", "var(--accent)")
            ("border-radius", "50%")
            ("animation", "spin 1s linear infinite")
          ] }
          
        // Settings Modal
        { Selector = "#settings-modal"
          Properties = Map [
            ("position", "fixed")
            ("inset", "0")
            ("background", "rgba(0, 0, 0, 0.7)")
            ("display", "none")
            ("align-items", "center")
            ("justify-content", "center")
            ("z-index", "1000")
          ] }
          
        { Selector = ".modal-box"
          Properties = Map [
            ("background", "var(--bg-card)")
            ("border-radius", "16px")
            ("border", "1px solid var(--border)")
            ("padding", "20px")
            ("max-height", "90vh")
            ("overflow-y", "auto")
          ] }
          
        { Selector = ".modal-title"
          Properties = Map [
            ("font-size", "18px")
            ("font-weight", "600")
            ("margin-bottom", "20px")
            ("color", "var(--text-main)")
          ] }
          
        { Selector = ".settings-section"
          Properties = Map [
            ("margin-bottom", "24px")
          ] }
          
        { Selector = ".settings-section-title"
          Properties = Map [
            ("font-size", "14px")
            ("font-weight", "600")
            ("margin-bottom", "12px")
          ] }
          
        { Selector = ".settings-label"
          Properties = Map [
            ("display", "block")
            ("font-size", "12px")
            ("margin-bottom", "6px")
            ("color", "var(--text-muted)")
          ] }
          
        { Selector = ".settings-input"
          Properties = Map [
            ("width", "100%")
            ("padding", "10px 12px")
            ("border-radius", "8px")
            ("border", "1px solid var(--border)")
            ("background", "var(--bg-panel)")
            ("color", "var(--text-main)")
            ("font-size", "12px")
            ("margin-bottom", "4px")
          ] }
          
        { Selector = ".settings-hint"
          Properties = Map [
            ("font-size", "11px")
            ("color", "var(--text-dim)")
            ("margin-top", "4px")
          ] }
          
        { Selector = ".toggle-switch"
          Properties = Map [
            ("position", "relative")
            ("display", "inline-block")
            ("width", "40px")
            ("height", "20px")
          ] }
          
        { Selector = ".toggle-switch input"
          Properties = Map [
            ("opacity", "0")
            ("width", "0")
            ("height", "0")
          ] }
          
        { Selector = ".toggle-track"
          Properties = Map [
            ("position", "absolute")
            ("cursor", "pointer")
            ("top", "0")
            ("left", "0")
            ("right", "0")
            ("bottom", "0")
            ("background", "var(--bg-panel)")
            ("border", "1px solid var(--border)")
            ("border-radius", "20px")
            ("transition", ".3s")
          ] }
          
        { Selector = ".toggle-thumb"
          Properties = Map [
            ("position", "absolute")
            ("content", "\"\"")
            ("height", "14px")
            ("width", "14px")
            ("left", "3px")
            ("bottom", "2px")
            ("background", "var(--text-dim)")
            ("border-radius", "50%")
            ("transition", ".3s")
          ] }
          
        { Selector = "input:checked + .toggle-track"
          Properties = Map [
            ("background", "var(--accent)")
            ("border-color", "var(--accent)")
          ] }
          
        { Selector = "input:checked + .toggle-track .toggle-thumb"
          Properties = Map [
            ("background", "white")
            ("transform", "translateX(20px)")
          ] }
          
        // Pixel-Inspektor
        { Selector = ".pixel-swatch"
          Properties = Map [
            ("width", "24px")
            ("height", "24px")
            ("border-radius", "4px")
            ("border", "1px solid var(--border)")
          ] }
          
        { Selector = ".pixel-values"
          Properties = Map [
            ("display", "flex")
            ("flex-direction", "column")
            ("font-size", "11px")
            ("color", "var(--text-dim)")
            ("gap", "2px")
          ] }
          
        // Upload-Zone
        { Selector = "#upload-zone"
          Properties = Map [
            ("position", "fixed")
            ("inset", "0")
            ("background", "rgba(0, 0, 0, 0.8)")
            ("display", "none")
            ("align-items", "center")
            ("justify-content", "center")
            ("color", "var(--text-main)")
            ("font-size", "16px")
            ("z-index", "100")
          ] }
    ]
    
    MediaQueries = [
        {
            Condition = "(max-width: 768px)"
            Rules = [
                { Selector = "#board"; Properties = Map [("flex-direction", "column")] }
                { Selector = "#right-panel"; Properties = Map [("width", "100%")] }
                { Selector = "#camera-panel"; Properties = Map [("min-width", "unset")] }
            ]
        }
    ]
}

let formatCssVariable (variable: CssVariable) : string =
    sprintf "  %s: %s;" variable.Name variable.Value

let formatCssProperty (key: string) (value: string) : string =
    sprintf "  %s: %s;" key value

let formatCssRule (rule: CssRule) : string =
    let props = rule.Properties |> Map.toList |> List.map (fun (k,v) -> formatCssProperty k v) |> String.concat "\n"
    sprintf "%s {\n%s\n}" rule.Selector props

let formatMediaQuery (mq: MediaQuery) : string =
    let rules = mq.Rules |> List.map formatCssRule |> String.concat "\n\n"
    sprintf "@media %s {\n%s\n}" mq.Condition rules

let generateCss (stylesheet: StyleSheet) : string =
    let headerComment = 
        "/* abstraction-provenance: {\"artifact_sha256\": \"8b76660533c644ac76ba28b4dcfb567e78b781d329ee59f8e75ceb7f8348f402\", \"source_sha256\": \"02dd111b283ac08d7a9f3fbbe30150fb6db98097ed7bc68f2677c6df9c744bfb\", \"target_language\": \"css\"} */\n" +
        "/* index.html — portiert nach css */\n" +
        "/* Quelle: html, Projects@Vision-Check:Vision-Check/app/index.html */\n" +
        "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n"

    let rootBlock = 
        let vars = stylesheet.Variables |> List.map formatCssVariable |> String.concat "\n"
        sprintf ":root {\n%s\n}" vars

    let rules = stylesheet.Rules |> List.map formatCssRule |> String.concat "\n\n"
    
    let keyframes = 
        "@keyframes pulse {\n" +
        "  0% { opacity: 0.4; }\n" +
        "  50% { opacity: 1; }\n" +
        "  100% { opacity: 0.4; }\n" +
        "}\n\n" +
        "@keyframes spin {\n" +
        "  to { transform: rotate(360deg); }\n" +
        "}"

    let mediaQueries = stylesheet.MediaQueries |> List.map formatMediaQuery |> String.concat "\n\n"

    [headerComment; rootBlock; ""; rules; ""; keyframes; ""; mediaQueries] 
    |> String.concat "\n"

[<EntryPoint>]
let main argv =
    if Array.length argv <> 1 then
        printfn "Verwendung: %s <ausgabedatei>" argv.[0]
        1
    else
        try
            let stylesheet = createStyleSheet()
            let cssContent = generateCss stylesheet
            File.WriteAllText(argv.[0], cssContent)
            printfn "CSS erfolgreich generiert und gespeichert in %s" argv.[0]
            0
        with
        | ex ->
            printfn "Fehler beim Generieren der CSS-Datei: %s" ex.Message
            1
