// abstraction-provenance: {"artifact_sha256": "d5baf199cac17dc4805ef77588588b6339c3a87943a40640b22fd0f83e479358", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "fsharp"}
// index_6925e5.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_6925e5.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

module CssWriter

open System
open System.IO

type CssVariable = {
    Name: string
    LightValue: string
    DarkValue: string option
}

type CssRule = {
    Selector: string
    Properties: (string * string) list
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

let createStyleSheet () = {
    Variables = [
        { Name = "--bg"; LightValue = "#fff"; DarkValue = Some "#0f1115" }
        { Name = "--soft"; LightValue = "#f6f7f9"; DarkValue = Some "#171a21" }
        { Name = "--line"; LightValue = "#e3e6ea"; DarkValue = Some "#262b36" }
        { Name = "--text"; LightValue = "#16191d"; DarkValue = Some "#f2f4f8" }
        { Name = "--muted"; LightValue = "#5f6773"; DarkValue = Some "#9aa3b2" }
        { Name = "--ac"; LightValue = "#6d5bd0"; DarkValue = None }
        { Name = "--ac-soft"; LightValue = "#efecfb"; DarkValue = Some "#1e1a33" }
        { Name = "--ok"; LightValue = "#15803d"; DarkValue = None }
        { Name = "--ok-soft"; LightValue = "#e7f6ec"; DarkValue = Some "#12261a" }
        { Name = "--warn"; LightValue = "#b45309"; DarkValue = None }
        { Name = "--warn-soft"; LightValue = "#fdf3e3"; DarkValue = Some "#2c2110" }
    ]
    Rules = [
        { Selector = ":root"; Properties = [ ("color-scheme", "light") ] }
        { Selector = "*"; Properties = [ ("box-sizing", "border-box") ] }
        { Selector = "body"; Properties = [
            ("margin", "0")
            ("background", "var(--bg)")
            ("color", "var(--text)")
            ("font", "16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif")
          ]}
        { Selector = ".wrap"; Properties = [
            ("max-width", "840px")
            ("margin", "0 auto")
            ("padding", "0 20px 72px")
          ]}
        { Selector = "header"; Properties = [
            ("padding", "64px 0 36px")
            ("border-bottom", "1px solid var(--line)")
          ]}
        { Selector = "h1"; Properties = [
            ("font-size", "34px")
            ("line-height", "1.2")
            ("margin", "0 0 12px")
            ("letter-spacing", "-.02em")
          ]}
        { Selector = ".lede"; Properties = [
            ("font-size", "18px")
            ("color", "var(--muted)")
            ("margin", "0 0 20px")
            ("max-width", "62ch")
          ]}
        { Selector = "h2"; Properties = [
            ("font-size", "13px")
            ("margin", "48px 0 14px")
            ("text-transform", "uppercase")
            ("letter-spacing", ".06em")
            ("color", "var(--muted)")
            ("font-weight", "650")
          ]}
        { Selector = "h3"; Properties = [
            ("font-size", "17px")
            ("margin", "24px 0 6px")
          ]}
        { Selector = "p"; Properties = [
            ("margin", "0 0 14px")
            ("max-width", "70ch")
          ]}
        { Selector = ".badges"; Properties = [
            ("display", "flex")
            ("gap", "7px")
            ("flex-wrap", "wrap")
            ("margin-bottom", "20px")
          ]}
        { Selector = ".badge"; Properties = [
            ("font-size", "12px")
            ("font-weight", "650")
            ("padding", "4px 11px")
            ("border-radius", "99px")
            ("background", "var(--soft)")
            ("color", "var(--muted)")
            ("border", "1px solid var(--line)")
          ]}
        { Selector = ".badge.on"; Properties = [
            ("background", "var(--ok-soft)")
            ("color", "var(--ok)")
            ("border-color", "transparent")
          ]}
        { Selector = "table"; Properties = [
            ("border-collapse", "collapse")
            ("width", "100%")
            ("font-size", "14.5px")
            ("margin", "0 0 14px")
          ]}
        { Selector = "th,td"; Properties = [
            ("text-align", "left")
            ("padding", "9px 10px")
            ("border-bottom", "1px solid var(--line)")
            ("vertical-align", "top")
          ]}
        { Selector = "th"; Properties = [
            ("font-size", "12px")
            ("text-transform", "uppercase")
            ("letter-spacing", ".04em")
            ("color", "var(--muted)")
          ]}
        { Selector = "code"; Properties = [
            ("background", "var(--soft)")
            ("padding", "2px 7px")
            ("border-radius", "5px")
            ("font-size", "13.5px")
            ("font-family", "ui-monospace,SFMono-Regular,Menlo,monospace")
            ("word-break", "break-word")
          ]}
        { Selector = "pre"; Properties = [
            ("background", "var(--soft)")
            ("border", "1px solid var(--line)")
            ("border-radius", "10px")
            ("padding", "13px 15px")
            ("overflow-x", "auto")
            ("margin", "0 0 14px")
          ]}
        { Selector = "pre code"; Properties = [
            ("background", "none")
            ("padding", "0")
          ]}
        { Selector = ".card"; Properties = [
            ("border", "1px solid var(--line)")
            ("border-radius", "12px")
            ("padding", "18px 20px")
            ("background", "var(--bg)")
          ]}
        { Selector = ".note"; Properties = [
            ("background", "var(--warn-soft)")
            ("border", "1px solid transparent")
            ("border-radius", "10px")
            ("padding", "14px 16px")
            ("margin", "0 0 16px")
            ("font-size", "14.5px")
          ]}
        { Selector = ".note b"; Properties = [
            ("color", "var(--warn)")
          ]}
        { Selector = "fieldset"; Properties = [
            ("border", "1px solid var(--line)")
            ("border-radius", "10px")
            ("padding", "14px 16px")
            ("margin", "0 0 14px")
          ]}
        { Selector = "legend"; Properties = [
            ("font-size", "12px")
            ("text-transform", "uppercase")
            ("letter-spacing", ".05em")
            ("color", "var(--muted)")
            ("padding", "0 6px")
          ]}
        { Selector = "label.q"; Properties = [
            ("display", "flex")
            ("gap", "10px")
            ("align-items", "flex-start")
            ("padding", "7px 0")
            ("font-size", "15px")
            ("cursor", "pointer")
          ]}
        { Selector = "label.q input"; Properties = [
            ("margin-top", "4px")
            ("flex", "none")
          ]}
        { Selector = "label.q span small"; Properties = [
            ("display", "block")
            ("color", "var(--muted)")
            ("font-size", "13px")
          ]}
        { Selector = "#ergebnis"; Properties = [
            ("margin-top", "6px")
          ]}
        { Selector = ".verdict"; Properties = [
            ("border", "1px solid var(--line)")
            ("border-left", "4px solid var(--ac)")
            ("border-radius", "10px")
            ("padding", "16px 18px")
            ("background", "var(--soft)")
          ]}
        { Selector = ".verdict h3"; Properties = [
            ("margin", "0 0 6px")
            ("font-size", "18px")
          ]}
        { Selector = ".verdict .step"; Properties = [
            ("font-weight", "650")
            ("margin", "10px 0 0")
          ]}
        { Selector = ".verdict .w"; Properties = [
            ("margin-top", "12px")
            ("padding", "11px 13px")
            ("background", "var(--warn-soft)")
            ("border-radius", "8px")
            ("font-size", "14px")
          ]}
        { Selector = ".probe"; Properties = [
            ("display", "flex")
            ("gap", "8px")
            ("flex-wrap", "wrap")
            ("margin-bottom", "12px")
          ]}
        { Selector = ".probe input"; Properties = [
            ("flex", "1 1 240px")
            ("padding", "10px 12px")
            ("border", "1px solid var(--line)")
            ("border-radius", "9px")
            ("background", "var(--bg)")
            ("color", "var(--text)")
            ("font-size", "15px")
          ]}
        { Selector = ".btn"; Properties = [
            ("font-weight", "650")
            ("font-size", "15px")
            ("padding", "10px 18px")
            ("border-radius", "9px")
            ("border", "1px solid var(--ac)")
            ("background", "var(--ac)")
            ("color", "#fff")
            ("cursor", "pointer")
          ]}
        { Selector = ".btn.ghost"; Properties = [
            ("background", "var(--bg)")
            ("color", "var(--text)")
            ("border-color", "var(--line)")
          ]}
        { Selector = "footer"; Properties = [
            ("margin-top", "56px")
            ("padding-top", "22px")
            ("border-top", "1px solid var(--line)")
            ("color", "var(--muted)")
            ("font-size", "14px")
          ]}
        { Selector = "a"; Properties = [
            ("color", "var(--ac)")
          ]}
    ]
    MediaQueries = [
        {
            Condition = "(prefers-color-scheme: dark)"
            Rules = [{ Selector = ":root"; Properties = [ ("color-scheme", "dark") ] }]
        }
    ]
}

let writeCssProperty (writer: StreamWriter) (property: string * string) =
    let (name, value) = property
    writer.Write("\n  ")
    writer.Write(name)
    writer.Write(":")
    writer.Write(value)
    writer.Write(";")

let writeCssRule (writer: StreamWriter) (rule: CssRule) =
    writer.Write(rule.Selector)
    writer.Write("{")
    rule.Properties |> List.iter (writeCssProperty writer)
    writer.Write("\n}")

let writeMediaQuery (writer: StreamWriter) (mediaQuery: MediaQuery) =
    writer.Write("\n@media ")
    writer.Write(mediaQuery.Condition)
    writer.Write("{")
    mediaQuery.Rules |> List.iter (fun rule -> 
        writer.Write("\n  ")
        writeCssRule writer rule)
    writer.Write("\n}")

let writeVariables (writer: StreamWriter) (variables: CssVariable list) =
    writer.Write(":root{")
    variables |> List.iter (fun v -> 
        writer.Write("\n  ")
        writer.Write(v.Name)
        writer.Write(":")
        writer.Write(v.LightValue)
        writer.Write(";"))
    writer.Write("\n  color-scheme: light;\n}")
    
    writer.Write("\n@media (prefers-color-scheme: dark){\n  :root{")
    variables |> List.iter (fun v -> 
        writer.Write("\n    ")
        writer.Write(v.Name)
        writer.Write(":")
        writer.Write(defaultArg v.DarkValue v.LightValue)
        writer.Write(";"))
    writer.Write("\n    color-scheme: dark; \n  }\n}")

let generateCss (styleSheet: StyleSheet) (filePath: string) =
    use writer = new StreamWriter(filePath)
    
    // Write comments
    writer.WriteLine("/* abstraction-provenance: {\"artifact_sha256\": \"ede701dd0faa101fb7d23c7e6bd8e28625c33e7b3d07a7ededc1bf14cbfcb761\", \"source_sha256\": \"6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523\", \"target_language\": \"css\"} */")
    writer.WriteLine("/* index.html — portiert nach css */")
    writer.WriteLine("/* Quelle: html, Projects@MCP-Server-Monitor:public/index.html */")
    writer.WriteLine("/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */")
    writer.WriteLine()
    
    // Write variables
    writeVariables writer styleSheet.Variables
    writer.WriteLine()
    
    // Write rules
    styleSheet.Rules |> List.iter (fun rule -> 
        writeCssRule writer rule
        writer.WriteLine())
    
    // Write media queries
    styleSheet.MediaQueries |> List.iter (fun mq -> 
        writeMediaQuery writer mq
        writer.WriteLine())

[<EntryPoint>]
let main argv =
    if argv.Length <> 1 then
        printfn "Usage: CssWriter <output-file>"
        1
    else
        try
            let styleSheet = createStyleSheet()
            generateCss styleSheet argv.[0]
            printfn "CSS file generated successfully: %s" argv.[0]
            0
        with
        | ex ->
            printfn "Error generating CSS file: %s" ex.Message
            1
