// abstraction-provenance: {"artifact_sha256": "3edde83e5a53e9941189bd331a15210d650a43f3e9e2059a42e450bb1552834b", "source_sha256": "8c27d4100abf548d397238253c635c8516dc1bf3a1f72639a0d8228e949fcbbd", "target_language": "fsharp"}
// style.css — portiert nach fsharp
// Quelle: css, Projects@Vision-Check:Vision-Check/app/css/style.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

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

type KeyframeAnimation = {
    Name: string
    Keyframes: Map<string, Map<string, string>>
}

type CssDocument = {
    Variables: CssVariable list
    Rules: CssRule list
    MediaQueries: MediaQuery list
    Keyframes: KeyframeAnimation list
}

let createCssVariable name value = { Name = name; Value = value }
let createCssRule selector properties = { Selector = selector; Properties = properties }
let createMediaQuery condition rules = { Condition = condition; Rules = rules }
let createKeyframeAnimation name keyframes = { Name = name; Keyframes = keyframes }

let buildCss (doc: CssDocument) =
    let sb = StringBuilder()
    
    // Add header comment
    sb.AppendLine("/* ═══════════════════════════════════════════════════════════") |> ignore
    sb.AppendLine("   Vision-Check — Design System") |> ignore
    sb.AppendLine("   Dark-Tech Theme | Analyse-Board Layout") |> ignore
    sb.AppendLine("═══════════════════════════════════════════════════════════ */") |> ignore
    sb.AppendLine() |> ignore
    
    // Root variables
    sb.AppendLine(":root {") |> ignore
    sb.AppendLine("  /* Farben */") |> ignore
    doc.Variables |> List.iter (fun v -> 
        sb.AppendLine($"  {v.Name}: {v.Value};") |> ignore)
    sb.AppendLine("}") |> ignore
    sb.AppendLine() |> ignore
    
    // Regular rules
    doc.Rules |> List.iter (fun rule ->
        sb.AppendLine($"{rule.Selector} {{") |> ignore
        rule.Properties |> Map.iter (fun prop value ->
            sb.AppendLine($"  {prop}: {value};") |> ignore)
        sb.AppendLine("}") |> ignore
        sb.AppendLine() |> ignore
    )
    
    // Media queries
    doc.MediaQueries |> List.iter (fun mq ->
        sb.AppendLine($"@media ({mq.Condition}) {{") |> ignore
        mq.Rules |> List.iter (fun rule ->
            sb.AppendLine($"  {rule.Selector} {{") |> ignore
            rule.Properties |> Map.iter (fun prop value ->
                sb.AppendLine($"    {prop}: {value};") |> ignore)
            sb.AppendLine("  }") |> ignore
        )
        sb.AppendLine("}") |> ignore
        sb.AppendLine() |> ignore
    )
    
    // Keyframes
    doc.Keyframes |> List.iter (fun kf ->
        sb.AppendLine($"@keyframes {kf.Name} {{") |> ignore
        kf.Keyframes |> Map.iter (fun step props ->
            sb.AppendLine($"  {step} {{") |> ignore
            props |> Map.iter (fun prop value ->
                sb.AppendLine($"    {prop}: {value};") |> ignore)
            sb.AppendLine("  }") |> ignore
        )
        sb.AppendLine("}") |> ignore
        sb.AppendLine() |> ignore
    )
    
    sb.ToString()

let generateStyleCss() =
    let variables = [
        createCssVariable "--bg-deep" "#0a0f1e"
        createCssVariable "--bg-surface" "#111827"
        createCssVariable "--bg-card" "#1a2235"
        createCssVariable "--bg-hover" "#1f2d45"
        createCssVariable "--border" "rgba(99, 179, 237, 0.15)"
        createCssVariable "--border-glow" "rgba(99, 179, 237, 0.4)"
        createCssVariable "--accent" "#63b3ed"
        createCssVariable "--accent-2" "#4fd1c5"
        createCssVariable "--accent-warn" "#fbd38d"
        createCssVariable "--accent-ok" "#68d391"
        createCssVariable "--accent-err" "#fc8181"
        createCssVariable "--text-primary" "#e2e8f0"
        createCssVariable "--text-muted" "#718096"
        createCssVariable "--text-dim" "#4a5568"
        createCssVariable "--layer-0" "#805ad5"
        createCssVariable "--layer-1" "#4fd1c5"
        createCssVariable "--layer-2" "#fbd38d"
        createCssVariable "--layer-3-gpt" "#68d391"
        createCssVariable "--layer-3-gemini" "#63b3ed"
        createCssVariable "--layer-3-claude" "#fc8181"
        createCssVariable "--radius" "8px"
        createCssVariable "--radius-l" "14px"
        createCssVariable "--gap" "12px"
    ]
    
    let rules = [
        createCssRule "*" (Map [("box-sizing", "border-box"); ("margin", "0"); ("padding", "0")])
        createCssRule "*::before" (Map [("box-sizing", "border-box"); ("margin", "0"); ("padding", "0")])
        createCssRule "*::after" (Map [("box-sizing", "border-box"); ("margin", "0"); ("padding", "0")])
        createCssRule "html, body" (Map [
            ("height", "100%")
            ("background", "var(--bg-deep)")
            ("color", "var(--text-primary)")
            ("font-family", "'Inter', system-ui, -apple-system, sans-serif")
            ("font-size", "14px")
            ("line-height", "1.5")
            ("overflow", "hidden")
        ])
        createCssRule "#app-header" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "space-between")
            ("padding", "10px 16px")
            ("background", "var(--bg-surface)")
            ("border-bottom", "1px solid var(--border)")
            ("height", "52px")
            ("flex-shrink", "0")
            ("z-index", "100")
        ])
        createCssRule ".header-brand" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
        ])
        createCssRule ".header-brand svg" (Map [
            ("width", "28px")
            ("height", "28px")
            ("color", "var(--accent)")
        ])
        createCssRule ".header-brand h1" (Map [
            ("font-size", "16px")
            ("font-weight", "700")
            ("background", "linear-gradient(90deg, var(--accent), var(--accent-2))")
            ("-webkit-background-clip", "text")
            ("-webkit-text-fill-color", "transparent")
            ("background-clip", "text")
        ])
        createCssRule ".header-controls" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
        ])
        createCssRule "#app" (Map [
            ("display", "flex")
            ("flex-direction", "column")
            ("height", "100vh")
        ])
        createCssRule "#board" (Map [
            ("display", "grid")
            ("grid-template-columns", "1fr 320px")
            ("grid-template-rows", "1fr auto")
            ("gap", "var(--gap)")
            ("padding", "var(--gap)")
            ("flex", "1")
            ("overflow", "hidden")
        ])
        createCssRule "#camera-panel" (Map [
            ("grid-column", "1")
            ("grid-row", "1")
            ("background", "var(--bg-card)")
            ("border", "1px solid var(--border)")
            ("border-radius", "var(--radius-l)")
            ("display", "flex")
            ("flex-direction", "column")
            ("overflow", "hidden")
            ("position", "relative")
        ])
        createCssRule ".panel-header" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "space-between")
            ("padding", "10px 14px")
            ("border-bottom", "1px solid var(--border)")
            ("background", "var(--bg-surface)")
            ("flex-shrink", "0")
        ])
        createCssRule ".panel-title" (Map [
            ("font-size", "12px")
            ("font-weight", "600")
            ("text-transform", "uppercase")
            ("letter-spacing", "0.08em")
            ("color", "var(--text-muted)")
        ])
        createCssRule ".badge" (Map [
            ("display", "inline-flex")
            ("align-items", "center")
            ("gap", "4px")
            ("padding", "2px 8px")
            ("border-radius", "20px")
            ("font-size", "10px")
            ("font-weight", "600")
            ("text-transform", "uppercase")
        ])
        createCssRule ".badge-live" (Map [
            ("background", "rgba(104, 211, 145, 0.15)")
            ("color", "var(--accent-ok)")
        ])
        createCssRule ".badge-idle" (Map [
            ("background", "rgba(113, 128, 150, 0.15)")
            ("color", "var(--text-muted)")
        ])
        createCssRule ".badge-loading" (Map [
            ("background", "rgba(251, 211, 141, 0.15)")
            ("color", "var(--accent-warn)")
        ])
        createCssRule "#camera-viewport" (Map [
            ("flex", "1")
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "center")
            ("position", "relative")
            ("background", "#000")
            ("overflow", "hidden")
        ])
        createCssRule "#video" (Map [
            ("width", "100%")
            ("height", "100%")
            ("object-fit", "contain")
            ("display", "block")
        ])
        createCssRule "#canvas-overlay" (Map [
            ("position", "absolute")
            ("top", "0")
            ("left", "0")
            ("width", "100%")
            ("height", "100%")
            ("pointer-events", "none")
        ])
        createCssRule "#snap-canvas" (Map [("display", "none")])
        createCssRule "#pixel-loupe" (Map [
            ("position", "absolute")
            ("bottom", "16px")
            ("right", "16px")
            ("width", "160px")
            ("height", "160px")
            ("border", "2px solid var(--accent)")
            ("border-radius", "var(--radius)")
            ("overflow", "hidden")
            ("background", "#000")
            ("display", "none")
            ("box-shadow", "0 0 20px rgba(99, 179, 237, 0.3)")
        ])
        createCssRule "#loupe-canvas" (Map [
            ("width", "100%")
            ("height", "100%")
        ])
        createCssRule "#loupe-info" (Map [
            ("position", "absolute")
            ("bottom", "0")
            ("left", "0")
            ("right", "0")
            ("background", "rgba(0,0,0,0.8)")
            ("padding", "4px 6px")
            ("font-size", "10px")
            ("font-family", "'JetBrains Mono', monospace")
            ("color", "var(--accent)")
            ("text-align", "center")
        ])
        createCssRule "#camera-controls" (Map [
            ("padding", "10px 14px")
            ("border-top", "1px solid var(--border)")
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
            ("flex-wrap", "wrap")
            ("background", "var(--bg-surface)")
            ("flex-shrink", "0")
        ])
        createCssRule "#right-panel" (Map [
            ("grid-column", "2")
            ("grid-row", "1 / 3")
            ("display", "flex")
            ("flex-direction", "column")
            ("gap", "var(--gap)")
            ("overflow-y", "auto")
            ("padding-right", "2px")
        ])
        createCssRule "#right-panel::-webkit-scrollbar" (Map [("width", "4px")])
        createCssRule "#right-panel::-webkit-scrollbar-track" (Map [("background", "transparent")])
        createCssRule "#right-panel::-webkit-scrollbar-thumb" (Map [
            ("background", "var(--border)")
            ("border-radius", "2px")
        ])
        createCssRule ".card" (Map [
            ("background", "var(--bg-card)")
            ("border", "1px solid var(--border)")
            ("border-radius", "var(--radius-l)")
            ("overflow", "hidden")
        ])
        createCssRule ".card-body" (Map [("padding", "12px 14px")])
        createCssRule ".slider-row" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "8px")
            ("margin-bottom", "10px")
        ])
        createCssRule ".slider-row:last-child" (Map [("margin-bottom", "0")])
        createCssRule ".slider-label" (Map [
            ("width", "90px")
            ("font-size", "11px")
            ("color", "var(--text-muted)")
            ("flex-shrink", "0")
        ])
        createCssRule ".slider-row input[type=\"range\"]" (Map [
            ("flex", "1")
            ("-webkit-appearance", "none")
            ("height", "4px")
            ("border-radius", "2px")
            ("background", "var(--bg-deep)")
            ("outline", "none")
            ("cursor", "pointer")
        ])
        createCssRule ".slider-row input[type=\"range\"]::-webkit-slider-thumb" (Map [
            ("-webkit-appearance", "none")
            ("width", "14px")
            ("height", "14px")
            ("border-radius", "50%")
            ("background", "var(--accent)")
            ("border", "2px solid var(--bg-card)")
            ("cursor", "pointer")
            ("transition", "transform 0.15s")
        ])
        createCssRule ".slider-row input[type=\"range\"]::-webkit-slider-thumb:hover" (Map [
            ("transform", "scale(1.2)")
        ])
        createCssRule ".slider-value" (Map [
            ("width", "32px")
            ("font-size", "11px")
            ("color", "var(--accent)")
            ("font-family", "monospace")
            ("text-align", "right")
            ("flex-shrink", "0")
        ])
        createCssRule ".result-block" (Map [
            ("margin-bottom", "12px")
            ("padding", "10px")
            ("background", "var(--bg-surface)")
            ("border", "1px solid var(--border)")
            ("border-radius", "var(--radius)")
        ])
        createCssRule ".result-block:last-child" (Map [("margin-bottom", "0")])
        createCssRule ".result-header" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "space-between")
            ("margin-bottom", "6px")
        ])
        createCssRule ".layer-tag" (Map [
            ("display", "inline-flex")
            ("align-items", "center")
            ("gap", "5px")
            ("font-size", "10px")
            ("font-weight", "700")
            ("text-transform", "uppercase")
            ("letter-spacing", "0.06em")
        ])
        createCssRule ".result-text" (Map [
            ("font-size", "12px")
            ("color", "var(--text-primary)")
            ("line-height", "1.6")
            ("white-space", "pre-wrap")
        ])
        createCssRule ".detection-item" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("justify-content", "space-between")
            ("padding", "4px 0")
            ("border-bottom", "1px solid var(--border)")
            ("font-size", "12px")
        ])
        createCssRule ".detection-item:last-child" (Map [("border-bottom", "none")])
        createCssRule ".detection-class" (Map [
            ("font-weight", "600")
            ("color", "var(--layer-1)")
        ])
        createCssRule ".confidence-bar" (Map [
            ("display", "flex")
            ("align-items", "center")
            ("gap", "6px")
        ])
        createCssRule ".confidence-track" (Map [
            ("width", "60px")
            ("height", "4px")
            ("background", "var(--bg-deep)")
            ("border-radius", "2px")
            ("overflow", "hidden")
        ])
        createCssRule ".confidence-fill" (Map [
            ("height", "100%")
            ("background", "var(--accent-ok)")
            ("border-radius", "2px")
            ("transition", "width 0.3s")
        ])
        createCssRule ".confidence-pct" (Map [
            ("font-size", "10px")
            ("color", "var(--text-muted)")
            ("width", "32px")
            ("text-align", "right")
        ])
        createCssRule "#pixel-info" (Map [
            ("display", "flex")
            ("gap", "8px")
            ("align-items", "center")
        ])
        createCssRule ".pixel-swatch" (Map [
            ("width", "36px")
            ("height", "36px")
            ("border-radius", "var(--radius)")
            ("border", "2px solid var(--border)")
            ("flex-shrink", "0")
        ])
        createCssRule ".pixel-values" (Map [
            ("display", "flex")
            ("flex-direction", "column")
            ("gap", "2px")
        ])
        createCssRule ".pixel-values span" (Map [
            ("font-size", "11px")
            ("font-family", "'JetBrains Mono', monospace")
            ("color", "var(--text-primary)")
        ])
        createCssRule ".btn" (Map [
            ("display", "inline-flex")
            ("align-items", "center")
            ("gap", "6px")
            ("padding", "7px 14px")
            ("border", "1px solid var(--border)")
            ("border-radius", "var(--radius)")
            ("background", "var(--bg-surface)")
            ("color", "var(--text-primary)")
            ("font-size", "12px")
            ("font-weight", "500")
            ("cursor", "pointer")
            ("transition", "all 0.2s")
            ("white-space", "nowrap")
        ])
        createCssRule ".btn:hover" (Map [
            ("background", "var(--bg-hover)")
            ("border-color", "var(--border-glow)")
        ])
        createCssRule ".btn:disabled" (Map [
            ("opacity", "0.4")
            ("cursor", "not-allowed")
        ])
        createCssRule ".btn-primary" (Map [
            ("background", "rgba(99, 179, 237, 0.15)")
            ("border-color", "var(--accent)")
            ("color", "var(--accent)")
        ])
        createCssRule ".btn-primary:hover" (Map [
            ("background", "rgba(99, 179, 237, 0.25)")
        ])
        createCssRule ".btn-snap" (Map [
            ("background", "rgba(104, 211, 145, 0.15)")
            ("border-color", "var(--accent-ok)")
            ("color", "var(--accent-ok)")
            ("padding", "9px 20px")
            ("font-size", "13px")
            ("font-weight", "600")
        ])
        createCssRule ".btn-snap:hover" (Map [
            ("background", "rgba(104, 211, 145, 0.25)")
        ])
        createCssRule ".btn-danger" (Map [
            ("background", "rgba(252, 129, 129, 0.1)")
            ("border-color", "var(--accent-err)")
            ("color", "var(--accent-err)")
        ])
        createCssRule ".btn-sm" (Map [
            ("padding", "4px 10px")
            ("font-size", "11px")
        ])
        createCssRule ".btn-icon" (Map [
            ("padding", "7px")
            ("border-radius", "var(--radius)")
        ])
        createCssRule "select" (Map [
            ("background", "var(--bg-surface)")
            ("border", "1px solid var(--border)")
            ("color", "var(--text-primary)")
            ("border-radius", "var(--radius)")
            ("padding", "6px 10px")
            ("font-size", "12px")
            ("cursor", "pointer")
            ("outline", "none")
            ("transition", "border-color 0.2s")
        ])
        createCssRule "select:hover, select:focus" (Map [
            ("border-color", "var(--border-glow)")
        ])
        createCssRule ".spinner" (Map [
            ("width", "16px")
            ("height", "16px")
            ("border", "2px solid var(--border)")
            ("border-top-color", "var(--accent)")
            ("border-radius", "50%")
            ("animation", "spin 0.7s linear infinite")
            ("flex-shrink", "0")
        ])
        createCssRule "#settings-modal" (Map [
            ("display", "none")
            ("position", "fixed")
            ("inset", "0")
            ("background", "rgba(0,0,0,0.7)")
            ("z-index", "200")
            ("align-items", "center")
            ("justify-content", "center")
            ("backdrop-filter", "blur(4px)")
        ])
        createCssRule "#settings-modal.open" (Map [("display", "flex")])
        createCssRule ".modal-box" (Map [
            ("background", "var(--bg-card)")
            ("border", "1px solid var(--border-glow)")
            ("border-radius", "var(--radius-l)")
            ("padding", "24px")
            ("width", "480px")
            ("max-width", "calc(100vw - 32px)")
            ("max-height", "80vh")
            ("overflow-y", "auto")
        ])
        createCssRule ".modal-title" (Map [
            ("font-size", "16px")
            ("font-weight", "700")
            ("color", "var(--accent)")
            ("margin-bottom", "20px")
        ])
        createCssRule ".settings-section" (Map [("margin-bottom", "20px")])
        createCssRule ".settings-label" (Map [
            ("display", "block")
            ("font-size", "11px")
            ("font-weight", "600")
            ("text-transform", "uppercase")
            ("letter-spacing", "0.08em")
            ("color", "var(--text-muted)")
            ("margin-bottom", "6px")
        ])
        createCssRule ".settings-input" (Map [
            ("width", "100%")
            ("background", "var(--bg-deep)")
            ("border", "1px solid var(--border)")
            ("color", "var(--text-primary)")
            ("border-radius", "var(--radius)")
            ("padding", "8px 12px")
            ("font-size", "12px")
            ("font-family", "'JetBrains Mono', monospace")
            ("outline", "none")
            ("transition", "border-color 0.2s")
        ])
        createCssRule ".settings-input:focus" (Map [
            ("border-color", "var(--accent)")
        ])
        createCssRule ".settings-hint" (Map [
            ("font-size", "10px")
            ("color", "var(--text-dim)")
            ("margin-top", "4px")
        ])
        createCssRule ".settings-section-title" (Map [
            ("font-size", "13px")
            ("font-weight", "600")
            ("color", "var(--text-primary)")
            ("margin-bottom", "12px")
            ("padding-bottom", "8px")
            ("border-bottom", "1px solid var(--border)")
        ])
        createCssRule "#snapshot-area" (Map [("display", "none")])
        createCssRule "#snapshot-preview" (Map [
            ("width", "100%")
            ("border-radius", "var(--radius)")
            ("border", "1px solid var(--border)")
        ])
        createCssRule "#status-bar" (Map [
            ("grid-column", "1")
            ("grid-row", "2")
            ("background", "var(--bg-surface)")
            ("border", "1px solid var(--border)")
            ("border-radius", "var(--radius)")
            ("padding", "6px 12px")
            ("display", "flex")
            ("align-items", "center")
            ("gap", "12px")
            ("font-size", "11px")
            ("color", "var(--text-muted)")
            ("flex-shrink", "0")
        ])
        createCssRule ".status-dot" (Map [
            ("width", "6px")
            ("height", "6px")
            ("border-radius", "50%")
            ("background", "var(--text-dim)")
            ("flex-shrink", "0")
        ])
        createCssRule ".status-dot.ok" (Map [
            ("background", "var(--accent-ok)")
            ("box-shadow", "0 0 6px var(--accent-ok)")
        ])
        createCssRule ".status-dot.warn" (Map [("background", "var(--accent-warn)")])
        createCssRule ".status-dot.err" (Map [("background", "var(--accent-err)")])
        createCssRule "#status-text" (Map [("flex", "1")])
        createCssRule ".layer-indicator" (Map [
            ("display", "flex")
            ("gap", "4px")
            ("align-items", "center")
        ])
        createCssRule ".layer-dot" (Map [
            ("width", "8px")
            ("height", "8px")
            ("border-radius", "50%")
            ("opacity", "0.3")
            ("transition", "opacity 0.3s, box-shadow 0.3s")
        ])
        createCssRule ".layer-dot.active" (Map [
            ("opacity", "1")
            ("box-shadow", "0 0 6px currentColor")
        ])
        createCssRule ".tab-bar" (Map [
            ("display", "flex")
            ("gap", "2px")
            ("padding", "8px 14px")
            ("border-bottom", "1px solid var(--border)")
            ("background", "var(--bg-surface)")
        ])
        createCssRule ".tab" (Map [
            ("padding", "5px 12px")
            ("border-radius", "var(--radius)")
            ("font-size", "11px")
            ("font-weight", "600")
            ("cursor", "pointer")
            ("color", "var(--text-muted)")
            ("transition", "all 0.2s")
            ("border", "1px solid transparent")
            ("background", "transparent")
        ])
        createCssRule ".tab.active" (Map [
            ("background", "var(--bg-hover)")
            ("border-color", "var(--border-glow)")
            ("color", "var(--accent)")
        ])
        createCssRule ".tab-content" (Map [("display", "none")])
        createCssRule ".tab-content.active" (Map [("display", "block")])
        createCssRule ".species-card" (Map [
            ("display", "flex")
            ("gap", "10px")
            ("padding", "8px")
            ("background", "var(--bg-deep)")
            ("border-radius", "var(--radius)")
            ("margin-bottom", "8px")
            ("border", "1px solid var(--border)")
        ])
        createCssRule ".species-img" (Map [
            ("width", "48px")
            ("height", "48px")
            ("border-radius", "var(--radius)")
            ("object-fit", "cover")
            ("flex-shrink", "0")
            ("background", "var(--bg-surface)")
        ])
        createCssRule ".species-info" (Map [("flex", "1"); ("min-width", "0")])
        createCssRule ".species-name" (Map [
            ("font-size", "12px")
            ("font-weight", "600")
            ("color", "var(--layer-0)")
            ("white-space", "nowrap")
            ("overflow", "hidden")
            ("text-overflow", "ellipsis")
        ])
        createCssRule ".species-latin" (Map [
            ("font-size", "10px")
            ("color", "var(--text-muted)")
            ("font-style", "italic")
        ])
        createCssRule ".species-score" (Map [
            ("font-size", "10px")
            ("color", "var(--text-dim)")
            ("margin-top", "2px")
        ])
        createCssRule "#upload-zone" (Map [
            ("border", "2px dashed var(--border)")
            ("border-radius", "var(--radius)")
            ("padding", "20px")
            ("text-align", "center")
            ("cursor", "pointer")
            ("transition", "all 0.2s")
            ("color", "var(--text-muted)")
            ("font-size", "12px")
        ])
        createCssRule "#upload-zone:hover, #upload-zone.drag-over" (Map [
            ("border-color", "var(--accent)")
            ("background", "rgba(99, 179, 237, 0.05)")
            ("color", "var(--accent)")
        ])
        createCssRule ".toggle-switch" (Map [
            ("position", "relative")
            ("width", "36px")
            ("height", "20px")
            ("flex-shrink", "0")
        ])
        createCssRule ".toggle-switch input" (Map [("display", "none")])
        createCssRule ".toggle-track" (Map [
            ("position", "absolute")
            ("inset", "0")
            ("border-radius", "10px")
            ("background", "var(--bg-deep)")
            ("border", "1px solid var(--border)")
            ("cursor", "pointer")
            ("transition", "background 0.2s")
        ])
        createCssRule ".toggle-thumb" (Map [
            ("position", "absolute")
            ("top", "3px")
            ("left", "3px")
            ("width", "12px")
            ("height", "12px")
            ("border-radius", "50%")
            ("background", "var(--text-dim)")
            ("transition", "transform 0.2s, background 0.2s")
        ])
        createCssRule ".toggle-switch input:checked + .toggle-track" (Map [
            ("background", "rgba(99, 179, 237, 0.2)")
            ("border-color", "var(--accent)")
        ])
        createCssRule ".toggle-switch input:checked ~ .toggle-thumb, .toggle-switch input:checked + .toggle-track + .toggle-thumb" (Map [
            ("background", "var(--accent)")
            ("transform", "translateX(16px)")
        ])
    ]
    
    let mediaQueries = [
        createMediaQuery "max-width: 768px" [
            createCssRule "#board" (Map [
                ("grid-template-columns", "1fr")
                ("grid-template-rows", "1fr auto auto")
                ("overflow-y", "auto")
            ])
            createCssRule "#camera-panel" (Map [
                ("grid-column", "1")
                ("grid-row", "1")
                ("min-height", "55vw")
            ])
            createCssRule "#right-panel" (Map [
                ("grid-column", "1")
                ("grid-row", "2")
                ("overflow-y", "visible")
                ("max-height", "none")
            ])
            createCssRule "#status-bar" (Map [
                ("grid-column", "1")
                ("grid-row", "3")
            ])
            createCssRule "html, body" (Map [("overflow", "auto")])
        ]
    ]
    
    let keyframes = [
        createKeyframeAnimation "spin" (Map [("to", Map [("transform", "rotate(360deg)")])])
        createKeyframeAnimation "pulse-glow" (Map [
            ("0%, 100%", Map [("box-shadow", "0 0 4px var(--accent)")])
            ("50%", Map [("box-shadow", "0 0 16px var(--accent)")])
        ])
        createKeyframeAnimation "fadeIn" (Map [
            ("from", Map [
                ("opacity", "0")
                ("transform", "translateY(4px)")
            ])
            ("to", Map [
                ("opacity", "1")
                ("transform", "translateY(0)")
            ])
        ])
    ]
    
    { Variables = variables; Rules = rules; MediaQueries = mediaQueries; Keyframes = keyframes }

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Usage: program <output-file>"
        1
    else
        try
            let cssDoc = generateStyleCss()
            let cssContent = buildCss cssDoc
            File.WriteAllText(argv.[0], cssContent)
            printfn "CSS file generated successfully: %s" argv.[0]
            0
        with
        | ex ->
            printfn "Error generating CSS file: %s" ex.Message
            1
