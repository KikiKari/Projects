// abstraction-provenance: {"artifact_sha256": "2d96b6971ecd8744c7826731ae27ff052c2ae1d46f06ad389b1bab8e8a730bab", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "fsharp"}
// index_4051ed.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_4051ed.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

// index_4051ed.fs
open System.IO
open System.Text

let generateCSS () : string =
    let sb = StringBuilder()

    // Root variables
    sb.AppendLine(":root {") |> ignore
    sb.AppendLine("  --bg: #f6f7f9;") |> ignore
    sb.AppendLine("  --card: #fff;") |> ignore
    sb.AppendLine("  --line: #e3e6ea;") |> ignore
    sb.AppendLine("  --text: #16191d;") |> ignore
    sb.AppendLine("  --muted: #6b7280;") |> ignore
    sb.AppendLine("  --accent: #2481cc;") |> ignore
    sb.AppendLine("  --accent-soft: #e8f2fb;") |> ignore
    sb.AppendLine("  --discord: #5865f2;") |> ignore
    sb.AppendLine("  --discord-soft: #eceefe;") |> ignore
    sb.AppendLine("  --ok: #15803d;") |> ignore
    sb.AppendLine("  --warn: #b45309;") |> ignore
    sb.AppendLine("  --err: #b91c1c;") |> ignore
    sb.AppendLine("  color-scheme: light;") |> ignore
    sb.AppendLine("}") |> ignore

    // Universal selector
    sb.AppendLine("* { box-sizing: border-box; }") |> ignore

    // Body styles
    sb.AppendLine("body {") |> ignore
    sb.AppendLine("  margin: 0;") |> ignore
    sb.AppendLine("  background: var(--bg);") |> ignore
    sb.AppendLine("  color: var(--text);") |> ignore
    sb.AppendLine("  font: 15px/1.5 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;") |> ignore
    sb.AppendLine("}") |> ignore

    // Header styles
    sb.AppendLine("header {") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("  border-bottom: 1px solid var(--line);") |> ignore
    sb.AppendLine("  padding: 14px 20px;") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  gap: 14px;") |> ignore
    sb.AppendLine("  flex-wrap: wrap;") |> ignore
    sb.AppendLine("  position: sticky;") |> ignore
    sb.AppendLine("  top: 0;") |> ignore
    sb.AppendLine("  z-index: 5;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("header h1 {") |> ignore
    sb.AppendLine("  font-size: 17px;") |> ignore
    sb.AppendLine("  margin: 0;") |> ignore
    sb.AppendLine("  font-weight: 650;") |> ignore
    sb.AppendLine("}") |> ignore

    // Pill styles
    sb.AppendLine(".pill {") |> ignore
    sb.AppendLine("  font-size: 11px;") |> ignore
    sb.AppendLine("  padding: 2px 8px;") |> ignore
    sb.AppendLine("  border-radius: 99px;") |> ignore
    sb.AppendLine("  background: var(--accent-soft);") |> ignore
    sb.AppendLine("  color: var(--accent);") |> ignore
    sb.AppendLine("  font-weight: 600;") |> ignore
    sb.AppendLine("  white-space: nowrap;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".pill.off {") |> ignore
    sb.AppendLine("  background: #f1f2f4;") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".pill.dc {") |> ignore
    sb.AppendLine("  background: var(--discord-soft);") |> ignore
    sb.AppendLine("  color: var(--discord);") |> ignore
    sb.AppendLine("}") |> ignore

    // Navigation styles
    sb.AppendLine("nav {") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  gap: 4px;") |> ignore
    sb.AppendLine("  padding: 0 20px;") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("  border-bottom: 1px solid var(--line);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("nav button {") |> ignore
    sb.AppendLine("  border: 0;") |> ignore
    sb.AppendLine("  background: none;") |> ignore
    sb.AppendLine("  padding: 11px 14px;") |> ignore
    sb.AppendLine("  font: inherit;") |> ignore
    sb.AppendLine("  font-weight: 500;") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  cursor: pointer;") |> ignore
    sb.AppendLine("  border-bottom: 2px solid transparent;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("nav button.active {") |> ignore
    sb.AppendLine("  color: var(--accent);") |> ignore
    sb.AppendLine("  border-bottom-color: var(--accent);") |> ignore
    sb.AppendLine("}") |> ignore

    // Main content styles
    sb.AppendLine("main {") |> ignore
    sb.AppendLine("  padding: 20px;") |> ignore
    sb.AppendLine("  max-width: 1080px;") |> ignore
    sb.AppendLine("  margin: 0 auto;") |> ignore
    sb.AppendLine("}") |> ignore

    // Panel styles
    sb.AppendLine(".panel {") |> ignore
    sb.AppendLine("  display: none;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".panel.active {") |> ignore
    sb.AppendLine("  display: block;") |> ignore
    sb.AppendLine("}") |> ignore

    // Row styles
    sb.AppendLine(".row {") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  gap: 8px;") |> ignore
    sb.AppendLine("  flex-wrap: wrap;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  margin-bottom: 14px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Input and select styles
    sb.AppendLine("input, select {") |> ignore
    sb.AppendLine("  padding: 9px 11px;") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("  border-radius: 8px;") |> ignore
    sb.AppendLine("  font: inherit;") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("  min-width: 180px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("input:focus, select:focus {") |> ignore
    sb.AppendLine("  outline: 2px solid var(--accent-soft);") |> ignore
    sb.AppendLine("  border-color: var(--accent);") |> ignore
    sb.AppendLine("}") |> ignore

    // Button styles
    sb.AppendLine("button.go {") |> ignore
    sb.AppendLine("  background: var(--accent);") |> ignore
    sb.AppendLine("  color: #fff;") |> ignore
    sb.AppendLine("  border: 0;") |> ignore
    sb.AppendLine("  border-radius: 8px;") |> ignore
    sb.AppendLine("  padding: 9px 16px;") |> ignore
    sb.AppendLine("  font: inherit;") |> ignore
    sb.AppendLine("  font-weight: 600;") |> ignore
    sb.AppendLine("  cursor: pointer;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("button.go.sec {") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("  color: var(--text);") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("button.go.dc {") |> ignore
    sb.AppendLine("  background: var(--discord);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("button.go:disabled {") |> ignore
    sb.AppendLine("  opacity: .5;") |> ignore
    sb.AppendLine("  cursor: default;") |> ignore
    sb.AppendLine("}") |> ignore

    // Card styles
    sb.AppendLine(".card {") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("  border-radius: 12px;") |> ignore
    sb.AppendLine("  padding: 14px 16px;") |> ignore
    sb.AppendLine("  margin-bottom: 10px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".card h3 {") |> ignore
    sb.AppendLine("  margin: 0 0 2px;") |> ignore
    sb.AppendLine("  font-size: 15px;") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  align-items: center;") |> ignore
    sb.AppendLine("  gap: 8px;") |> ignore
    sb.AppendLine("  flex-wrap: wrap;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".card .meta {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-size: 13px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".card .desc {") |> ignore
    sb.AppendLine("  margin-top: 7px;") |> ignore
    sb.AppendLine("  font-size: 13.5px;") |> ignore
    sb.AppendLine("  white-space: pre-wrap;") |> ignore
    sb.AppendLine("}") |> ignore

    // Avatar styles
    sb.AppendLine(".avatar {") |> ignore
    sb.AppendLine("  width: 34px;") |> ignore
    sb.AppendLine("  height: 34px;") |> ignore
    sb.AppendLine("  border-radius: 50%;") |> ignore
    sb.AppendLine("  object-fit: cover;") |> ignore
    sb.AppendLine("  background: #eceff3;") |> ignore
    sb.AppendLine("  flex: none;") |> ignore
    sb.AppendLine("}") |> ignore

    // Head styles
    sb.AppendLine(".head {") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  gap: 11px;") |> ignore
    sb.AppendLine("  align-items: flex-start;") |> ignore
    sb.AppendLine("}") |> ignore

    // Score styles
    sb.AppendLine(".score {") |> ignore
    sb.AppendLine("  font-variant-numeric: tabular-nums;") |> ignore
    sb.AppendLine("  font-size: 12px;") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("  border-radius: 6px;") |> ignore
    sb.AppendLine("  padding: 1px 6px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Tag styles
    sb.AppendLine(".tag {") |> ignore
    sb.AppendLine("  font-size: 11px;") |> ignore
    sb.AppendLine("  padding: 2px 7px;") |> ignore
    sb.AppendLine("  border-radius: 5px;") |> ignore
    sb.AppendLine("  background: #f1f2f4;") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-weight: 600;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".tag.ok {") |> ignore
    sb.AppendLine("  background: #e7f6ec;") |> ignore
    sb.AppendLine("  color: var(--ok);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".tag.no {") |> ignore
    sb.AppendLine("  background: #fdeceb;") |> ignore
    sb.AppendLine("  color: var(--err);") |> ignore
    sb.AppendLine("}") |> ignore

    // Post styles
    sb.AppendLine(".post {") |> ignore
    sb.AppendLine("  border-left: 3px solid var(--accent-soft);") |> ignore
    sb.AppendLine("  padding: 6px 0 6px 11px;") |> ignore
    sb.AppendLine("  margin: 9px 0;") |> ignore
    sb.AppendLine("  font-size: 13.5px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".post .when {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-size: 12px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".post .txt {") |> ignore
    sb.AppendLine("  white-space: pre-wrap;") |> ignore
    sb.AppendLine("  margin-top: 2px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Link styles
    sb.AppendLine("a {") |> ignore
    sb.AppendLine("  color: var(--accent);") |> ignore
    sb.AppendLine("  text-decoration: none;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("a:hover {") |> ignore
    sb.AppendLine("  text-decoration: underline;") |> ignore
    sb.AppendLine("}") |> ignore

    // Empty state styles
    sb.AppendLine(".empty {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  padding: 22px;") |> ignore
    sb.AppendLine("  text-align: center;") |> ignore
    sb.AppendLine("  border: 1px dashed var(--line);") |> ignore
    sb.AppendLine("  border-radius: 12px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Error styles
    sb.AppendLine(".err {") |> ignore
    sb.AppendLine("  background: #fdeceb;") |> ignore
    sb.AppendLine("  border: 1px solid #f5c6c2;") |> ignore
    sb.AppendLine("  color: var(--err);") |> ignore
    sb.AppendLine("  padding: 10px 13px;") |> ignore
    sb.AppendLine("  border-radius: 8px;") |> ignore
    sb.AppendLine("  margin-bottom: 12px;") |> ignore
    sb.AppendLine("  font-size: 13.5px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Spinner styles
    sb.AppendLine(".spin {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  padding: 16px 0;") |> ignore
    sb.AppendLine("}") |> ignore

    // Table styles
    sb.AppendLine("table {") |> ignore
    sb.AppendLine("  width: 100%;") |> ignore
    sb.AppendLine("  border-collapse: collapse;") |> ignore
    sb.AppendLine("  font-size: 13.5px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("th, td {") |> ignore
    sb.AppendLine("  text-align: left;") |> ignore
    sb.AppendLine("  padding: 8px 10px;") |> ignore
    sb.AppendLine("  border-bottom: 1px solid var(--line);") |> ignore
    sb.AppendLine("  vertical-align: top;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine("th {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-weight: 600;") |> ignore
    sb.AppendLine("  font-size: 12px;") |> ignore
    sb.AppendLine("  text-transform: uppercase;") |> ignore
    sb.AppendLine("  letter-spacing: .03em;") |> ignore
    sb.AppendLine("}") |> ignore

    // Code styles
    sb.AppendLine("code {") |> ignore
    sb.AppendLine("  background: #f1f2f4;") |> ignore
    sb.AppendLine("  padding: 1px 5px;") |> ignore
    sb.AppendLine("  border-radius: 4px;") |> ignore
    sb.AppendLine("  font-size: 12.5px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Hint styles
    sb.AppendLine(".hint {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-size: 13px;") |> ignore
    sb.AppendLine("  margin: -4px 0 14px;") |> ignore
    sb.AppendLine("}") |> ignore

    // Stream styles
    sb.AppendLine(".stream {") |> ignore
    sb.AppendLine("  max-height: 460px;") |> ignore
    sb.AppendLine("  overflow: auto;") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("  border-radius: 10px;") |> ignore
    sb.AppendLine("  padding: 6px 12px;") |> ignore
    sb.AppendLine("  margin-top: 10px;") |> ignore
    sb.AppendLine("  background: var(--card);") |> ignore
    sb.AppendLine("}") |> ignore

    // Fresh post styles
    sb.AppendLine(".post.fresh {") |> ignore
    sb.AppendLine("  border-left-color: var(--ok);") |> ignore
    sb.AppendLine("  background: #f3fbf5;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".post.fresh .when::after {") |> ignore
    sb.AppendLine("  content: \" NEU\";") |> ignore
    sb.AppendLine("  color: var(--ok);") |> ignore
    sb.AppendLine("  font-weight: 700;") |> ignore
    sb.AppendLine("}") |> ignore

    // Dot styles
    sb.AppendLine(".dot {") |> ignore
    sb.AppendLine("  width: 8px;") |> ignore
    sb.AppendLine("  height: 8px;") |> ignore
    sb.AppendLine("  border-radius: 50%;") |> ignore
    sb.AppendLine("  background: var(--ok);") |> ignore
    sb.AppendLine("  display: inline-block;") |> ignore
    sb.AppendLine("  margin-right: 6px;") |> ignore
    sb.AppendLine("  animation: pulse 2s infinite;") |> ignore
    sb.AppendLine("}") |> ignore

    // Pulse animation
    sb.AppendLine("@keyframes pulse {") |> ignore
    sb.AppendLine("  0%, 100% { opacity: 1; }") |> ignore
    sb.AppendLine("  50% { opacity: .35; }") |> ignore
    sb.AppendLine("}") |> ignore

    // Idle styles
    sb.AppendLine(".idle {") |> ignore
    sb.AppendLine("  background: var(--muted) !important;") |> ignore
    sb.AppendLine("  animation: none;") |> ignore
    sb.AppendLine("}") |> ignore

    // TikTok live/off styles
    sb.AppendLine(".tt-live {") |> ignore
    sb.AppendLine("  background: #fe2c55;") |> ignore
    sb.AppendLine("  color: #fff;") |> ignore
    sb.AppendLine("  font-weight: 700;") |> ignore
    sb.AppendLine("  font-size: 11px;") |> ignore
    sb.AppendLine("  padding: 2px 9px;") |> ignore
    sb.AppendLine("  border-radius: 99px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".tt-off {") |> ignore
    sb.AppendLine("  background: #f1f2f4;") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("  font-weight: 700;") |> ignore
    sb.AppendLine("  font-size: 11px;") |> ignore
    sb.AppendLine("  padding: 2px 9px;") |> ignore
    sb.AppendLine("  border-radius: 99px;") |> ignore
    sb.AppendLine("}") |> ignore

    // TikTok player styles
    sb.AppendLine(".tt-player {") |> ignore
    sb.AppendLine("  position: relative;") |> ignore
    sb.AppendLine("  width: 100%;") |> ignore
    sb.AppendLine("  max-width: 340px;") |> ignore
    sb.AppendLine("  aspect-ratio: 9/16;") |> ignore
    sb.AppendLine("  background: #000;") |> ignore
    sb.AppendLine("  border-radius: 10px;") |> ignore
    sb.AppendLine("  overflow: hidden;") |> ignore
    sb.AppendLine("  margin-top: 10px;") |> ignore
    sb.AppendLine("  border: 1px solid var(--line);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".tt-player iframe {") |> ignore
    sb.AppendLine("  position: absolute;") |> ignore
    sb.AppendLine("  inset: 0;") |> ignore
    sb.AppendLine("  width: 100%;") |> ignore
    sb.AppendLine("  height: 100%;") |> ignore
    sb.AppendLine("  border: 0;") |> ignore
    sb.AppendLine("}") |> ignore

    // Event styles
    sb.AppendLine(".ev {") |> ignore
    sb.AppendLine("  display: flex;") |> ignore
    sb.AppendLine("  gap: 10px;") |> ignore
    sb.AppendLine("  padding: 7px 0;") |> ignore
    sb.AppendLine("  border-bottom: 1px solid var(--line);") |> ignore
    sb.AppendLine("  font-size: 13.5px;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".ev:last-child {") |> ignore
    sb.AppendLine("  border-bottom: 0;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".ev .k {") |> ignore
    sb.AppendLine("  font-weight: 650;") |> ignore
    sb.AppendLine("  white-space: nowrap;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".ev .k.start {") |> ignore
    sb.AppendLine("  color: #fe2c55;") |> ignore
    sb.AppendLine("}") |> ignore

    sb.AppendLine(".ev .k.end {") |> ignore
    sb.AppendLine("  color: var(--muted);") |> ignore
    sb.AppendLine("}") |> ignore

    sb.ToString()

[<EntryPoint>]
let main argv =
    let cssContent = generateCSS()
    
    if argv.Length > 0 then
        File.WriteAllText(argv.[0], cssContent)
        printfn "CSS file generated: %s" argv.[0]
    else
        printfn "%s" cssContent
    
    0
