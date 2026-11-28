// abstraction-provenance: {"artifact_sha256": "c0b0d84502f23689e5710a081c550b6a468fb26df2fb4723cb67effa9d43d64b", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "fsharp"}
// periodensystem.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

module PeriodensystemCSS

open System
open System.IO
open System.Text

let generateCSS () : string =
    let sb = StringBuilder()

    // Main reset and root variables
    sb.AppendLine("/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */") |> ignore
    sb.AppendLine("/* periodensystem.html — portiert nach css */") |> ignore
    sb.AppendLine("/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */") |> ignore
    sb.AppendLine("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */") |> ignore
    sb.AppendLine() |> ignore
    
    sb.AppendLine("* { box-sizing: border-box; margin: 0; padding: 0; }") |> ignore
    sb.AppendLine(":root {") |> ignore
    sb.AppendLine("  --bg: #fafaf7;") |> ignore
    sb.AppendLine("  --surface: #ffffff;") |> ignore
    sb.AppendLine("  --border: rgba(0,0,0,0.12);") |> ignore
    sb.AppendLine("  --text: #1a1a1a;") |> ignore
    sb.AppendLine("  --text-muted: #666;") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Dark mode media query
    sb.AppendLine("@media (prefers-color-scheme: dark) {") |> ignore
    sb.AppendLine("  :root {") |> ignore
    sb.AppendLine("    --bg: #1a1a1a;") |> ignore
    sb.AppendLine("    --surface: #242424;") |> ignore
    sb.AppendLine("    --border: rgba(255,255,255,0.15);") |> ignore
    sb.AppendLine("    --text: #f0f0f0;") |> ignore
    sb.AppendLine("    --text-muted: #aaa;") |> ignore
    sb.AppendLine("  }") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Body styles
    sb.AppendLine("body {") |> ignore
    sb.AppendLine("  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;") |> ignore
    sb.AppendLine("  background: var(--bg);") |> ignore
    sb.AppendLine("  color: var(--text);") |> ignore
    sb.AppendLine("  padding: 24px;") |> ignore
    sb.AppendLine("  max-width: 1100px;") |> ignore
    sb.AppendLine("  margin: 0 auto;") |> ignore
    sb.AppendLine("  line-height: 1.5;") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Header styles
    sb.AppendLine("h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }") |> ignore
    sb.AppendLine(".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }") |> ignore
    
    // Detail section
    sb.AppendLine(".detail {") |> ignore
    sb.AppendLine("  background: var(--surface);") |> ignore
    sb.AppendLine("  border: 1px solid var(--border);") |> ignore
    sb.AppendLine("  border-radius: 12px;") |> ignore
    sb.AppendLine("  padding: 16px 20px;") |> ignore
    sb.AppendLine("  min-height: 110px;") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  gap: 20px;") |> ignore
    sb.AppendLine("  margin-bottom: 16px;") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".detail-empty {") |> ignore
    sb.AppendLine("  color: var(--text-muted);") |> ignore
    sb.AppendLine("  font-size: 14px;") |> ignore
    sb.AppendLine("  text-align: center;") |> ignore
    sb.AppendLine("  width: 100%;") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Symbol box
    sb.AppendLine(".symbol-box {") |> ignore
    sb.AppendLine("  font-size: 40px;") |> ignore
    sb.AppendLine("  font-weight: 500;") |> ignore
    sb.AppendLine("  line-height: 1;") |> ignore
    sb.AppendLine("  width: 80px;") |> ignore
    sb.AppendLine("  height: 80px;") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  justify-content: center;") |> ignore
    sb.AppendLine("  border-radius: 8px;") |> ignore
    sb.AppendLine("  flex-shrink: 0;") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Info sections
    sb.AppendLine(".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }") |> ignore
    
    sb.AppendLine(".info-meta {") |> ignore
    sb.AppendLine("  font-size: 13px;") |> ignore
    sb.AppendLine("  color: var(--text-muted);") |> ignore
    sb.AppendLine("  display: grid;") |> ignore
    sb.AppendLine("  grid-template-columns: repeat(2, minmax(0, 1fr));") |> ignore
    sb.AppendLine("  gap: 4px 24px;") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }") |> ignore
    
    // Grid layout
    sb.AppendLine(".grid {") |> ignore
    sb.AppendLine("  display: grid;") |> ignore
    sb.AppendLine("  grid-template-columns: repeat(18, minmax(0, 1fr));") |> ignore
    sb.AppendLine("  gap: 3px;") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".fgrid { margin-top: 8px; }") |> ignore
    
    // Cell styles
    sb.AppendLine(".cell {") |> ignore
    sb.AppendLine("  aspect-ratio: 1;") |> ignore
    sb.AppendLine("  border-radius: 4px;") |> ignore
    sb.AppendLine("  padding: 3px;") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  flex-direction: column;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  justify-content: center;") |> ignore
    sb.AppendLine("  cursor: pointer;") |> ignore
    sb.AppendLine("  font-family: inherit;") |> ignore
    sb.AppendLine("  line-height: 1;") |> ignore
    sb.AppendLine("  transition: transform 0.12s ease;") |> ignore
    sb.AppendLine("  border: 0;") |> ignore
    sb.AppendLine("  position: relative;") |> ignore
    sb.AppendLine("  overflow: hidden;") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }") |> ignore
    sb.AppendLine(".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }") |> ignore
    sb.AppendLine(".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }") |> ignore
    
    sb.AppendLine(".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }") |> ignore
    sb.AppendLine(".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }") |> ignore
    
    // Marker cells
    sb.AppendLine(".cell-marker {") |> ignore
    sb.AppendLine("  cursor: default;") |> ignore
    sb.AppendLine("  font-size: 9px;") |> ignore
    sb.AppendLine("  font-weight: 500;") |> ignore
    sb.AppendLine("  border: 1px dashed currentColor;") |> ignore
    sb.AppendLine("  background: transparent !important;") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".cell-marker:hover { transform: none; box-shadow: none; }") |> ignore
    
    // Category colors - light mode
    sb.AppendLine(".cat-am { background: #FCEBEB; color: #501313; }") |> ignore
    sb.AppendLine(".cat-em { background: #FAEEDA; color: #412402; }") |> ignore
    sb.AppendLine(".cat-tm { background: #E6F1FB; color: #042C53; }") |> ignore
    sb.AppendLine(".cat-ptm { background: #F1EFE8; color: #2C2C2A; }") |> ignore
    sb.AppendLine(".cat-hm { background: #E1F5EE; color: #04342C; }") |> ignore
    sb.AppendLine(".cat-nm { background: #EAF3DE; color: #173404; }") |> ignore
    sb.AppendLine(".cat-h { background: #EEEDFE; color: #26215C; }") |> ignore
    sb.AppendLine(".cat-eg { background: #FBEAF0; color: #4B1528; }") |> ignore
    sb.AppendLine(".cat-la { background: #FAECE7; color: #4A1B0C; }") |> ignore
    sb.AppendLine(".cat-ac { background: #F5C4B3; color: #4A1B0C; }") |> ignore
    
    // Category colors - dark mode
    sb.AppendLine("@media (prefers-color-scheme: dark) {") |> ignore
    sb.AppendLine("  .cat-am { background: #791F1F; color: #F7C1C1; }") |> ignore
    sb.AppendLine("  .cat-em { background: #633806; color: #FAC775; }") |> ignore
    sb.AppendLine("  .cat-tm { background: #0C447C; color: #B5D4F4; }") |> ignore
    sb.AppendLine("  .cat-ptm { background: #444441; color: #D3D1C7; }") |> ignore
    sb.AppendLine("  .cat-hm { background: #085041; color: #9FE1CB; }") |> ignore
    sb.AppendLine("  .cat-nm { background: #27500A; color: #C0DD97; }") |> ignore
    sb.AppendLine("  .cat-h { background: #3C3489; color: #CECBF6; }") |> ignore
    sb.AppendLine("  .cat-eg { background: #72243E; color: #F4C0D1; }") |> ignore
    sb.AppendLine("  .cat-la { background: #712B13; color: #F5C4B3; }") |> ignore
    sb.AppendLine("  .cat-ac { background: #993C1D; color: #F5C4B3; }") |> ignore
    sb.AppendLine("}") |> ignore
    
    // Legend styles
    sb.AppendLine(".legend {") |> ignore
    sb.AppendLine("  display: grid;") |> ignore
    sb.AppendLine("  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));") |> ignore
    sb.AppendLine("  gap: 8px 16px;") |> ignore
    sb.AppendLine("  margin-top: 24px;") |> ignore
    sb.AppendLine("  font-size: 12px;") |> ignore
    sb.AppendLine("  color: var(--text-muted);") |> ignore
    sb.AppendLine("}") |> ignore
    
    sb.AppendLine(".legend-item { display: flex; align-items: center; gap: 8px; }") |> ignore
    sb.AppendLine(".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }") |> ignore
    
    sb.ToString()

[<EntryPoint>]
let main argv =
    let filePath = 
        if argv.Length > 0 then argv.[0] 
        else "periodensystem.css"
    
    try
        let cssContent = generateCSS()
        File.WriteAllText(filePath, cssContent)
        printfn $"CSS file successfully written to {filePath}"
        0
    with
    | ex ->
        eprintfn $"Error writing CSS file: {ex.Message}"
        1
