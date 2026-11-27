// abstraction-provenance: {"artifact_sha256": "fcf2a5695539e422bdf255a3c8f7b7a3bda60a89c760f2bac0e42a087aa2e7a3", "source_sha256": "8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type HtmlElement = 
    | Element of string * HtmlAttribute list * HtmlElement list
    | Text of string
    | RawText of string

and HtmlAttribute = Attr of string * string

module Html =
    let tag name attrs children = Element(name, attrs, children)
    let text str = Text(str)
    let raw str = RawText(str)

    let html attrs children = tag "html" attrs children
    let head attrs children = tag "head" attrs children
    let body attrs children = tag "body" attrs children
    let title children = tag "title" [] children
    let meta attrs = tag "meta" attrs []
    let style children = tag "style" [] children
    let link attrs = tag "link" attrs []
    let div attrs children = tag "div" attrs children
    let span attrs children = tag "span" attrs children
    let h1 attrs children = tag "h1" attrs children
    let h3 attrs children = tag "h3" attrs children
    let p attrs children = tag "p" attrs children
    let em children = tag "em" [] children
    let img attrs = tag "img" attrs []

    let render (element: HtmlElement) : string =
        let rec renderAttrs attrs =
            attrs
            |> List.map (fun (Attr(name, value)) -> sprintf "%s=\"%s\"" name value)
            |> String.concat " "

        let rec renderElement indent element =
            match element with
            | Text(content) -> sprintf "%s%s" indent content
            | RawText(content) -> content
            | Element(tagName, attrs, children) ->
                let attrStr = 
                    if List.isEmpty attrs then "" 
                    else " " + renderAttrs attrs
                
                if List.isEmpty children then
                    sprintf "%s<%s%s />" indent tagName attrStr
                else
                    let childIndent = indent + "  "
                    let renderedChildren = 
                        children 
                        |> List.map (renderElement childIndent)
                        |> String.concat "\n"
                    
                    if List.exists (function RawText(_) -> true | _ -> false) children then
                        sprintf "%s<%s%s>\n%s\n%s</%s>" indent tagName attrStr renderedChildren indent tagName
                    else
                        sprintf "%s<%s%s>\n%s\n%s</%s>" indent tagName attrStr renderedChildren indent tagName

        "<!DOCTYPE html>\n" + (renderElement "" element)

let cssVariables = """
  :root {
    --bg: #FAF8F4;
    --ink: #1B1A17;
    --accent: #A8542F;
    --accent-2: #2E7D7B;
    --font-display: 'Newsreader', Georgia, serif;
    --font-body: 'Hanken Grotesk', -apple-system, sans-serif;
    --font-mono: 'JetBrains Mono', monospace;
  }
"""

let baseStyles = """
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: var(--font-body);
    background: var(--bg);
    color: var(--ink);
    padding: 32px 16px 80px;
  }
  h1 {
    font-family: var(--font-display);
    font-weight: 500;
    font-size: 28px;
    max-width: 1400px;
    margin: 0 auto 12px;
  }
  .intro {
    max-width: 1400px;
    margin: 0 auto 32px;
    color: #666;
    font-size: 14px;
    line-height: 1.5;
  }
  .grid {
    display: grid;
    gap: 32px;
    max-width: 1400px;
    margin: 0 auto;
  }
  .variant {
    background: #000;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 12px 40px rgba(0,0,0,0.15);
  }
  .variant-header {
    background: #fff;
    padding: 16px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    border-bottom: 1px solid #eee;
  }
  .variant-label {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    color: var(--accent);
    font-weight: 600;
  }
  .variant-title {
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 500;
  }
  .variant-desc {
    font-size: 13px;
    color: #666;
    flex: 1;
    text-align: right;
  }
  .scene {
    position: relative;
    aspect-ratio: 16 / 9;
    background: url('bg.png') center/cover no-repeat;
    overflow: hidden;
  }
  .orb {
    position: absolute;
    width: 12%;
    aspect-ratio: 1;
    left: 42%;
    top: 55%;
    transform: translate(-50%, -50%);
    cursor: pointer;
  }
  .orb img { width: 100%; height: 100%; object-fit: contain; }
"""

let variant1Styles = """
  /* Variante 1: Karte daneben */
  .card-preview {
    position: absolute;
    left: 55%;
    top: 45%;
    background: rgba(255,255,255,0.98);
    padding: 16px 20px;
    border-radius: 12px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.25);
    width: 240px;
    animation: slideIn 0.3s ease-out;
  }
  .card-preview .badge {
    display: inline-block;
    background: var(--accent-2);
    color: white;
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 3px 8px;
    border-radius: 3px;
    margin-bottom: 8px;
  }
  .card-preview h3 {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 500;
    margin-bottom: 6px;
    color: var(--ink);
  }
  .card-preview p {
    font-size: 12px;
    color: #555;
    line-height: 1.4;
  }
  @keyframes slideIn {
    from { opacity: 0; transform: translateX(-8px); }
    to { opacity: 1; transform: translateX(0); }
  }
"""

let variant2Styles = """
  /* Variante 2: Minimaler Tooltip */
  .tooltip {
    position: absolute;
    left: 42%;
    top: 46%;
    transform: translate(-50%, -100%);
    color: white;
    text-shadow: 0 2px 12px rgba(0,0,0,0.8);
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 500;
    white-space: nowrap;
    animation: fadeUp 0.3s ease-out;
  }
  @keyframes fadeUp {
    from { opacity: 0; transform: translate(-50%, -80%); }
    to { opacity: 1; transform: translate(-50%, -100%); }
  }
"""

let variant3Styles = """
  /* Variante 3: Vollflächiges Overlay */
  .full-overlay {
    position: absolute;
    inset: 0;
    background: rgba(0,0,0,0.5);
    backdrop-filter: blur(6px);
    display: flex;
    align-items: center;
    justify-content: center;
    animation: fadeIn 0.35s ease-out;
  }
  .full-overlay .panel {
    background: rgba(255,255,255,0.98);
    padding: 32px 40px;
    border-radius: 20px;
    max-width: 420px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.4);
    text-align: center;
  }
  .full-overlay .badge {
    display: inline-block;
    background: var(--accent);
    color: white;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    padding: 4px 10px;
    border-radius: 4px;
    margin-bottom: 14px;
  }
  .full-overlay h3 {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 500;
    margin-bottom: 10px;
    color: var(--ink);
  }
  .full-overlay p {
    font-size: 14px;
    color: #555;
    line-height: 1.5;
    margin-bottom: 20px;
  }
  .full-overlay .preview-img {
    width: 100%;
    aspect-ratio: 16/10;
    background: linear-gradient(135deg, #A8542F, #2E7D7B);
    border-radius: 8px;
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.15em;
    opacity: 0.9;
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
"""

let responsiveStyles = """
  .instruction {
    text-align: center;
    color: #999;
    font-size: 12px;
    margin-top: 16px;
    font-family: var(--font-mono);
    letter-spacing: 0.15em;
    text-transform: uppercase;
  }

  @media (max-width: 900px) {
    .card-preview { width: 180px; padding: 12px 14px; }
    .card-preview h3 { font-size: 15px; }
    .card-preview p { font-size: 11px; }
    .tooltip { font-size: 15px; }
    .full-overlay .panel { padding: 20px 24px; max-width: 300px; }
    .full-overlay h3 { font-size: 20px; }
  }
"""

let documentHead = 
    Html.head [] [
        Html.meta [Attr("charset", "UTF-8")]
        Html.title [Html.text "Hover-Preview Varianten · Vergleich"]
        Html.style [
            Html.raw cssVariables
            Html.raw baseStyles
            Html.raw variant1Styles
            Html.raw variant2Styles
            Html.raw variant3Styles
            Html.raw responsiveStyles
        ]
        Html.link [
            Attr("rel", "preconnect")
            Attr("href", "https://fonts.googleapis.com")
        ]
        Html.link [
            Attr("rel", "preconnect")
            Attr("href", "https://fonts.gstatic.com")
            Attr("crossorigin", "")
        ]
        Html.link [
            Attr("href", "https://fonts.googleapis.com/css2?family=Newsreader:wght@400;500&family=Hanken+Grotesk:wght@400;500&family=JetBrains+Mono:wght@400;500&display=swap")
            Attr("rel", "stylesheet")
        ]
    ]

let documentBody =
    Html.body [] [
        Html.h1 [] [Html.text "Hover-Preview · drei Varianten im Vergleich"]
        Html.p ["class", "intro"] [
            Html.raw "Gleiche Szene, gleiche Kugel-Position (Beispiel: Projekt-Kugel \"Weather-Check\").<br>Alle drei Varianten zeigen den Zustand "
            Html.em [Html.text "bei Maushover"]
            Html.raw ". Welche soll ins Projekt?"
        ]
        
        Html.div ["class", "grid"] [
            // Variante 1
            Html.div ["class", "variant"] [
                Html.div ["class", "variant-header"] [
                    Html.div [] [
                        Html.div ["class", "variant-label"] [Html.text "Variante 1"]
                        Html.div ["class", "variant-title"] [Html.text "Karte daneben"]
                    ]
                    Html.div ["class", "variant-desc"] [
                        Html.text "Kompakte Card rechts der Kugel · Titel + Badge + kurze Beschreibung aus content.ts · dezent, nicht störend"
                    ]
                ]
                Html.div ["class", "scene"] [
                    Html.div ["class", "orb"] [
                        Html.img ["src", "orb-01-teal.png"; "alt", ""] []
                    ]
                    Html.div ["class", "card-preview"] [
                        Html.span ["class", "badge"] [Html.text "GitHub · Public"]
                        Html.h3 [] [Html.text "Weather-Check"]
                        Html.p [] [
                            Html.text "Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen."
                        ]
                    ]
                ]
            ]
            
            // Variante 2
            Html.div ["class", "variant"] [
                Html.div ["class", "variant-header"] [
                    Html.div [] [
                        Html.div ["class", "variant-label"] [Html.text "Variante 2"]
                        Html.div ["class", "variant-title"] [Html.text "Minimaler Tooltip"]
                    ]
                    Html.div ["class", "variant-desc"] [
                        Html.text "Nur der Titel schwebt über der Kugel · maximal reduziert · schnell erfassbar · lässt die Bildwirkung ungestört"
                    ]
                ]
                Html.div ["class", "scene"] [
                    Html.div ["class", "orb"] [
                        Html.img ["src", "orb-01-teal.png"; "alt", ""] []
                    ]
                    Html.div ["class", "tooltip"] [Html.text "Weather-Check"]
                ]
            ]
            
            // Variante 3
            Html.div ["class", "variant"] [
                Html.div ["class", "variant-header"] [
                    Html.div [] [
                        Html.div ["class", "variant-label"] [Html.text "Variante 3"]
                        Html.div ["class", "variant-title"] [Html.text "Vollflächiges Overlay"]
                    ]
                    Html.div ["class", "variant-desc"] [
                        Html.text "Zentrales Modal mit Preview-Bild + Titel + Beschreibung · prominent · lädt zum Klicken ein · verdeckt aber Szene"
                    ]
                ]
                Html.div ["class", "scene"] [
                    Html.div ["class", "orb"] [
                        Html.img ["src", "orb-01-teal.png"; "alt", ""] []
                    ]
                    Html.div ["class", "full-overlay"] [
                        Html.div ["class", "panel"] [
                            Html.div ["class", "preview-img"] [Html.text "PROJEKT-PREVIEW"]
                            Html.span ["class", "badge"] [Html.text "GitHub · Public"]
                            Html.h3 [] [Html.text "Weather-Check"]
                            Html.p [] [
                                Html.text "Progressive Web App für lokale Wetterdaten mit Live-Radar und Push-Benachrichtigungen."
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        Html.p ["class", "instruction"] [Html.text "Sag mir welche Variante — dann baue ich sie ins Frontend ein."]
    ]

let document = 
    Html.html ["lang", "de"] [
        documentHead
        documentBody
    ]

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "index.html"
    
    let htmlContent = Html.render document
    File.WriteAllText(outputPath, htmlContent)
    printfn "HTML file generated at: %s" outputPath
    0
