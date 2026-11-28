// abstraction-provenance: {"artifact_sha256": "75be1af9ac7baf340a40596d184fed76067cce6dab69fe1d244657ac0e4faebb", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "fsharp"}
// peak-limiter_4ced2c.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

module PeakLimiter

open System.IO

type CssRule = {
    Selector: string
    Properties: Map<string, string>
}

type Stylesheet = CssRule list

let private serializeRule (rule: CssRule) =
    let props = 
        rule.Properties
        |> Map.toList
        |> List.map (fun (key, value) -> $"  {key}: {value};")
        |> String.concat "\n"
    $"{rule.Selector} {{\n{props}\n}}"

let private serializeStylesheet (stylesheet: Stylesheet) =
    stylesheet
    |> List.map serializeRule
    |> String.concat "\n\n"

let generateStylesheet () : Stylesheet = 
    [
        {
            Selector = "body"
            Properties = 
                [
                    "font", "16px system-ui"
                    "max-width", "1000px"
                    "margin", "40px auto"
                    "padding", "20px"
                ]
                |> Map.ofList
        }
        {
            Selector = "pre"
            Properties = 
                [
                    "white-space", "pre-wrap"
                ]
                |> Map.ofList
        }
        {
            Selector = "button"
            Properties = 
                [
                    "padding", "12px"
                ]
                |> Map.ofList
        }
    ]

let writeToFile (filePath: string) =
    let stylesheet = generateStylesheet()
    let content = serializeStylesheet stylesheet
    File.WriteAllText(filePath, content)

[] // Leere Liste als "Main"-Äquivalent für F#-Skript-Kompatibilität
