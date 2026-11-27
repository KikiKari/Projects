// abstraction-provenance: {"artifact_sha256": "bbaa28dedeb21cedbe26d04cd053b9a32c66056b1a76de571edead9c70ce10e7", "source_sha256": "460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94", "target_language": "fsharp"}
// popup.html — portiert nach fsharp
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

let generatePopupHtml () =
    let sb = StringBuilder()

    sb.Append("<!DOCTYPE html>") |> ignore
    sb.Append("<html lang=\"de\">") |> ignore
    sb.Append("<head>") |> ignore
    sb.Append("<meta charset=\"utf-8\">") |> ignore
    sb.Append("<title>TikTok Live Companion</title>") |> ignore
    sb.Append("<style>") |> ignore
    sb.Append(":root{") |> ignore
    sb.Append("--bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;") |> ignore
    sb.Append("--accent:#fe2c55; --ok:#22c55e;") |> ignore
    sb.Append("color-scheme: dark;") |> ignore
    sb.Append("}") |> ignore
    sb.Append("@media (prefers-color-scheme: light){") |> ignore
    sb.Append(":root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }") |> ignore
    sb.Append("}") |> ignore
    sb.Append("*{box-sizing:border-box}") |> ignore
    sb.Append("body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);") |> ignore
    sb.Append("font:14px/1.45 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}") |> ignore
    sb.Append(".wrap{padding:12px}") |> ignore
    sb.Append("header{display:flex;gap:8px;align-items:center;margin-bottom:10px}") |> ignore
    sb.Append("h1{font-size:14px;margin:0;font-weight:650;flex:1}") |> ignore
    sb.Append(".badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;") |> ignore
    sb.Append("background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}") |> ignore
    sb.Append(".badge.live{background:var(--accent);color:#fff}") |> ignore
    sb.Append(".badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}") |> ignore
    sb.Append(".badge.live .dot{animation:pulse 1.6s infinite}") |> ignore
    sb.Append("@keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}") |> ignore
    sb.Append(".row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}") |> ignore
    sb.Append("input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);") |> ignore
    sb.Append("background:var(--card);color:var(--text);padding:6px 9px}") |> ignore
    sb.Append("button{cursor:pointer;font-weight:600}") |> ignore
    sb.Append("button.primary{background:var(--accent);border-color:var(--accent);color:#fff}") |> ignore
    sb.Append(".player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;") |> ignore
    sb.Append("border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}") |> ignore
    sb.Append(".player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}") |> ignore
    sb.Append(".placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;") |> ignore
    sb.Append("align-items:center;justify-content:center;color:var(--muted);") |> ignore
    sb.Append("text-align:center;padding:16px;font-size:13px}") |> ignore
    sb.Append(".card{background:var(--card);border:1px solid var(--line);border-radius:10px;") |> ignore
    sb.Append("padding:10px 12px;margin-bottom:8px}") |> ignore
    sb.Append("h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);") |> ignore
    sb.Append("margin:0 0 6px;font-weight:650}") |> ignore
    sb.Append(".meta{color:var(--muted);font-size:12.5px}") |> ignore
    sb.Append(".strong{color:var(--text);font-weight:600}") |> ignore
    sb.Append(".stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}") |> ignore
    sb.Append(".stream:last-child{border-bottom:0}") |> ignore
    sb.Append(".stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}") |> ignore
    sb.Append(".stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}") |> ignore
    sb.Append(".stream.now{color:var(--accent);font-weight:650}") |> ignore
    sb.Append(".err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;") |> ignore
    sb.Append("border-radius:8px;font-size:12.5px;margin-bottom:8px}") |> ignore
    sb.Append("@media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }") |> ignore
    sb.Append(".note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}") |> ignore
    sb.Append("a{color:var(--accent)}") |> ignore
    sb.Append("</style>") |> ignore
    sb.Append("</head>") |> ignore
    sb.Append("<body>") |> ignore
    sb.Append("<div class=\"wrap\">") |> ignore
    sb.Append("<header>") |> ignore
    sb.Append("<h1>TikTok Live Companion</h1>") |> ignore
    sb.Append("<span class=\"badge\" id=\"badge\"><span class=\"dot\"></span><span id=\"badgeText\">—</span></span>") |> ignore
    sb.Append("</header>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<div class=\"row\">") |> ignore
    sb.Append("<input id=\"user\" placeholder=\"@name\" style=\"flex:1;min-width:120px\">") |> ignore
    sb.Append("<button class=\"primary\" id=\"go\">Anzeigen</button>") |> ignore
    sb.Append("<button id=\"force\" title=\"Player ohne Statusabfrage laden\">Player</button>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("<div class=\"row\">") |> ignore
    sb.Append("<select id=\"every\" style=\"flex:1\">") |> ignore
    sb.Append("<option value=\"1\">Prüfung jede Minute</option>") |> ignore
    sb.Append("<option value=\"2\" selected>alle 2 Minuten</option>") |> ignore
    sb.Append("<option value=\"5\">alle 5 Minuten</option>") |> ignore
    sb.Append("<option value=\"0\">nur manuell</option>") |> ignore
    sb.Append("</select>") |> ignore
    sb.Append("<label class=\"meta\"><input type=\"checkbox\" id=\"notify\" checked> benachrichtigen</label>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<div id=\"error\"></div>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<div class=\"player\" id=\"player\">") |> ignore
    sb.Append("<div class=\"placeholder\" id=\"placeholder\">") |> ignore
    sb.Append("<div style=\"font-size:28px\">📺</div>") |> ignore
    sb.Append("<div id=\"phText\">Konto eingeben und „Anzeigen“ drücken.</div>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<div class=\"card\">") |> ignore
    sb.Append("<h2>Status</h2>") |> ignore
    sb.Append("<div id=\"status\" class=\"meta\">—</div>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<div class=\"card\">") |> ignore
    sb.Append("<h2>Letzte Sendungen</h2>") |> ignore
    sb.Append("<div id=\"streams\" class=\"meta\">—</div>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("") |> ignore
    sb.Append("<p class=\"note\">") |> ignore
    sb.Append("Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,") |> ignore
    sb.Append("keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen") |> ignore
    sb.Append("Quellen; nichts davon umgeht eine Zugangskontrolle.") |> ignore
    sb.Append("</p>") |> ignore
    sb.Append("</div>") |> ignore
    sb.Append("<script src=\"tiktok-companion.js\"></script>") |> ignore
    sb.Append("<script src=\"popup.js\"></script>") |> ignore
    sb.Append("</body>") |> ignore
    sb.Append("</html>") |> ignore

    sb.ToString()

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "popup.html"

    try
        let htmlContent = generatePopupHtml()
        File.WriteAllText(outputPath, htmlContent, Encoding.UTF8)
        printfn $"HTML file generated successfully at {outputPath}"
        0
    with
    | ex ->
        eprintfn $"Error generating HTML file: {ex.Message}"
        1
