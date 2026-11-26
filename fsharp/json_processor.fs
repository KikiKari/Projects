// abstraction-provenance: {"artifact_sha256": "127083b59a671a41e6e9dd71e76fdf75b4391dbb7e8f93cbbc37da38a9a7d287", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "fsharp"}
// json_processor.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace JsonProcessor

open System
open System.IO
open System.Text.Json
open System.Text.RegularExpressions
open System.Collections.Generic
open Newtonsoft.Json
open Newtonsoft.Json.Linq

type JSONProcessingError(message: string) =
    inherit Exception(message)

type JSONValidationError(message: string) =
    inherit JSONProcessingError(message)

type JSONRepairError(message: string) =
    inherit JSONProcessingError(message)

module JsonProcessor =
    let private hasJsonRepair = false // In F# gibt es kein direktes Äquivalent zu json_repair

    let repairJsonString (rawJson: string) : string =
        if hasJsonRepair then
            try
                // Hier würde die Reparatur mit json_repair erfolgen
                rawJson
            with ex ->
                raise (JSONRepairError($"JSON repair failed: {ex.Message}"))
        else
            // Fallback: Manuelle Reparaturen
            let mutable cleaned = rawJson.Trim()
            
            // Entferne JavaScript-Kommentare
            cleaned <- Regex.Replace(cleaned, @"//.*?\n", "\n")
            cleaned <- Regex.Replace(cleaned, @"/\*.*?\*/", "", RegexOptions.Singleline)
            
            // Entferne trailing commas vor ] oder }
            cleaned <- Regex.Replace(cleaned, @",(\s*[}\]])", "$1")
            
            cleaned

    let parseJson (rawInput: string) (repair: bool) : obj =
        let trimmedInput = rawInput.Trim()
        
        // Versuche zuerst direktes Parsing
        try
            JsonSerializer.Deserialize<obj>(trimmedInput) |> ignore
            JsonSerializer.Deserialize<obj>(trimmedInput)
        with :? JsonException ->
            ()
        
        // Extrahiere JSON aus Markdown-Code-Blöcken
        if trimmedInput.Contains("```") then
            let patterns = [
                @"```json\s*(.*?)\s*```"
                @"```\s*(\{.*?\})\s*```"
                @"```\s*(\[.*?\])\s*```"
            ]
            
            for pattern in patterns do
                let matches = Regex.Matches(trimmedInput, pattern, RegexOptions.Singleline)
                for m in matches do
                    try
                        JsonSerializer.Deserialize<obj>(m.Groups.[1].Value) |> ignore
                        JsonSerializer.Deserialize<obj>(m.Groups.[1].Value)
                    with :? JsonException ->
                        ()
        
        // Versuche Reparatur
        if repair then
            try
                let repaired = repairJsonString trimmedInput
                JsonSerializer.Deserialize<obj>(repaired)
            with
            | :? JsonException as e -> raise (JSONProcessingError($"Could not parse JSON even after repair: {e.Message}"))
            | :? JSONRepairError as e -> raise (JSONProcessingError($"Could not parse JSON even after repair: {e.Message}"))
        
        raise (JSONProcessingError("Could not parse JSON"))

    type ToolCall = {
        tool: string
        arguments: Dictionary<string, obj>
        reasoning: string option
    }

    let validateToolCall (rawJson: string) (toolName: string option) : Dictionary<string, obj> =
        let toolCall = parseJson rawJson true :?> JObject
        
        let tool = toolCall.["tool"].ToString()
        let arguments = 
            match toolCall.["arguments"] with
            | null -> Dictionary<string, obj>()
            | arg -> arg.ToObject<Dictionary<string, obj>>()
        
        let reasoning = 
            match toolCall.["reasoning"] with
            | null -> None
            | r -> Some(r.ToString())
        
        match toolName with
        | Some expected when tool <> expected ->
            raise (JSONValidationError($"Expected tool '{expected}', got '{tool}'"))
        | _ -> ()
        
        let result = Dictionary<string, obj>()
        result.Add("tool", tool :> obj)
        result.Add("arguments", arguments :> obj)
        match reasoning with
        | Some r -> result.Add("reasoning", r :> obj)
        | None -> ()
        result

    let safeJsonLoads (rawInput: string) (defaultValue: obj) (repair: bool) : obj =
        try
            parseJson rawInput repair
        with :? JSONProcessingError ->
            defaultValue

    let extractJsonFromText (text: string) : obj list =
        let results = List<obj>()
        
        // Pattern für JSON-Objekte und Arrays
        let patterns = [
            @"\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}"  // Objekte
            @"\[[^\[\]]*(?:\[[^\[\]*\][^\[\]]*)*\]"  // Arrays
        ]
        
        for pattern in patterns do
            let matches = Regex.Matches(text, pattern)
            for m in matches do
                try
                    let parsed = parseJson m.Value true
                    results.Add(parsed)
                with :? JSONProcessingError ->
                    ()
        
        results |> List.ofSeq

    [<EntryPoint>]
    let main argv =
        let input = 
            if argv.Length > 0 then argv.[0] 
            else Console.ReadLine()
        
        let isFile = Array.contains "--file" argv || Array.contains "-f" argv
        let repair = not (Array.contains "--no-repair" argv)
        let pretty = Array.contains "--pretty" argv || Array.contains "-p" argv
        
        try
            let content = 
                if isFile then
                    File.ReadAllText(input)
                else
                    input
            
            let result = parseJson content repair
            
            let options = JsonSerializerOptions()
            options.WriteIndented <- pretty
            
            let output = JsonSerializer.Serialize(result, options)
            printfn "%s" output
            0
        with 
        | :? JSONProcessingError as e ->
            eprintf "Error: %s\n" e.Message
            1
        | ex ->
            eprintf "Unexpected error: %s\n" ex.Message
            1
