// abstraction-provenance: {"artifact_sha256": "ad6d33fc6ed271f0ee9d6cf857dc9c46f9433c010e09a2893e3d28d1e8655e93", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "fsharp"}
// icon-controls.css — portiert nach fsharp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type IconStyle = Plastisch | Glass | Linear

type IconData = {
    Name: string
    PropertyName: string
}

let iconData = [
    { Name = "auto-chat-refresh-counter"; PropertyName = "--icon-auto-chat-refresh-counter" }
    { Name = "browser"; PropertyName = "--icon-browser" }
    { Name = "captions"; PropertyName = "--icon-captions" }
    { Name = "chat-counter"; PropertyName = "--icon-chat-counter" }
    { Name = "fullscreen"; PropertyName = "--icon-fullscreen" }
    { Name = "mute"; PropertyName = "--icon-mute" }
    { Name = "off"; PropertyName = "--icon-off" }
    { Name = "on"; PropertyName = "--icon-on" }
    { Name = "pip"; PropertyName = "--icon-pip" }
    { Name = "play"; PropertyName = "--icon-play" }
    { Name = "player"; PropertyName = "--icon-player" }
    { Name = "protection-slider"; PropertyName = "--icon-protection-slider" }
    { Name = "recommendation-counter"; PropertyName = "--icon-recommendation-counter" }
    { Name = "report"; PropertyName = "--icon-report" }
    { Name = "reset"; PropertyName = "--icon-reset" }
    { Name = "settings"; PropertyName = "--icon-settings" }
    { Name = "status"; PropertyName = "--icon-status" }
    { Name = "stop"; PropertyName = "--icon-stop" }
    { Name = "unmute"; PropertyName = "--icon-unmute" }
    { Name = "volume-slider"; PropertyName = "--icon-volume-slider" }
]

let generateIconRule (style: IconStyle) =
    let styleName = match style with | Plastisch -> "plastisch" | Glass -> "glass" | Linear -> "linear"
    let selector = sprintf "html[data-icon-style=\"%s\"]" styleName
    let rules = 
        iconData
        |> List.map (fun icon -> 
            sprintf "%s:url(\"icons/%s/%s.png\")" icon.PropertyName styleName icon.Name)
        |> String.concat ";"
    sprintf "%s {%s;}" selector rules

let generateControlIconRules() =
    let baseRules = """
button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
button[data-control-icon][hidden] { display:none; }
input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
input[type="checkbox"]:checked { background-image:var(--icon-on); }
input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
.control-icon { display:inline-flex; align-items:center; }
input[type="range"] { min-height:32px; }
.icon-style-setting { display:flex; align-items:center; gap:8px; }"""
    
    let iconSpecificRules = 
        iconData
        |> List.map (fun icon -> 
            sprintf "[data-control-icon=\"%s\"] { --control-icon:var(%s); }" icon.Name icon.PropertyName)
        |> String.concat "\n"
    
    baseRules + "\n" + iconSpecificRules

let generateCSS() =
    let iconRules = 
        [Plastisch; Glass; Linear]
        |> List.map generateIconRule
        |> String.concat "\n"
    
    let controlIconRules = generateControlIconRules()
    
    iconRules + "\n" + controlIconRules

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Usage: %s <output-file>" (System.Reflection.Assembly.GetExecutingAssembly().GetName().Name)
        1
    else
        try
            let cssContent = generateCSS()
            File.WriteAllText(argv.[0], cssContent, Encoding.UTF8)
            printfn "CSS file generated successfully: %s" argv.[0]
            0
        with
        | ex ->
            printfn "Error generating CSS file: %s" ex.Message
            1
