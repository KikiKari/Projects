// abstraction-provenance: {"artifact_sha256": "f95812d512f426ddd7bfa421508afc59ba8fe3dd75fb8cfa991a2e616b519308", "source_sha256": "f55ff3c9a1d0fb13ff0d5dd08f91e1c1a304c7d83f3d1bb93f165f2437d276b9", "target_language": "fsharp"}
// json_schema_validator.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace JsonSchemaValidator

open System
open System.IO
open System.Text.Json
open System.Text.Json.Serialization
open System.Text.RegularExpressions
open Newtonsoft.Json
open Newtonsoft.Json.Linq
open Newtonsoft.Json.Schema
open FSharp.Core

/// <summary>
/// JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
/// Erweitert Pydantic mit externen Schema-Dateien.
/// </summary>

type SchemaValidationError(message: string) =
    inherit Exception(message)

type JSONProcessingError(message: string) =
    inherit Exception(message)

type JSONValidationError(message: string) =
    inherit Exception(message)

module JsonProcessor =
    let parseJson (rawInput: string) (repair: bool) : obj =
        try
            // Try parsing as-is first
            let doc = JsonDocument.Parse(rawInput)
            doc.RootElement.ToString() |> box
        with
        | _ when repair ->
            // Attempt basic repairs like trailing commas
            let repaired = Regex.Replace(rawInput, ",[ \t\r\n]*}", "}") |> Regex.Replace(",[ \t\r\n]*\\]", "]")
            try
                let doc = JsonDocument.Parse(repaired)
                doc.RootElement.ToString() |> box
            with
            | ex -> raise (JSONProcessingError($"Failed to parse JSON even after repair: {ex.Message}"))
        | ex -> raise (JSONProcessingError($"Failed to parse JSON: {ex.Message}"))

module JsonSchemaValidator =

    let private hasJsonSchema = true // Assuming Newtonsoft.Json.Schema is available

    /// <summary>
    /// Lädt ein JSON Schema aus verschiedenen Quellen.
    /// </summary>
    /// <param name="schemaSource">Pfad zur Schema-Datei oder Schema-Dict oder JSON String</param>
    /// <returns>Schema als Dictionary</returns>
    let loadSchema (schemaSource: obj) : JObject =
        match schemaSource with
        | :? JObject as jo -> jo
        | :? string as pathOrJson ->
            let path = Path.Combine(Environment.CurrentDirectory, pathOrJson)
            if File.Exists(path) then
                try
                    File.ReadAllText(path) |> JObject.Parse
                with
                | :? JsonException as e -> raise (SchemaValidationError($"Invalid JSON in schema file: {e.Message}"))
            else
                // Try parsing as JSON string
                try
                    JObject.Parse(pathOrJson)
                with
                | :? JsonException -> raise (SchemaValidationError($"Schema not found or invalid: {pathOrJson}"))
        | _ -> failwith "Unsupported schema source type"

    /// <summary>
    /// Validiert Daten gegen ein JSON Schema.
    /// </summary>
    /// <param name="data">Zu validierende Daten</param>
    /// <param name="schema">JSON Schema (Pfad, String oder Dict)</param>
    /// <param name="draft">JSON Schema Draft Version ("auto", "draft7", "2020-12")</param>
    /// <returns>True wenn valid</returns>
    let validateWithJsonSchema (data: obj) (schema: obj) (draft: string) : bool =
        if not hasJsonSchema then
            raise (SchemaValidationError("Newtonsoft.Json.Schema not available"))
        
        let schemaDict = loadSchema schema
        let settings = ValidationSettings()
        settings.ValidateSchema = true
        
        let jtokenData = 
            match data with
            | :? string as s -> JToken.Parse(s)
            | _ -> JToken.FromObject(data)
            
        let schemaObj = JSchema.Parse(schemaDict.ToString())
        let valid = jtokenData.IsValid(schemaObj, settings)
        if not valid then
            raise (SchemaValidationError("Schema validation failed"))
        valid

    /// <summary>
    /// Parst, repariert und validiert JSON gegen Schema.
    /// </summary>
    /// <param name="rawInput">JSON-String</param>
    /// <param name="schema">JSON Schema</param>
    /// <param name="repair">Ob Reparatur versucht werden soll</param>
    /// <returns>Validierte Daten</returns>
    let validateAndConvert (rawInput: string) (schema: obj) (repair: bool) : obj =
        let data = JsonProcessor.parseJson rawInput repair
        validateWithJsonSchema data schema "auto" |> ignore
        data

    /// <summary>
    /// Hilfsklasse zum Erstellen von JSON Schemas.
    /// </summary>
    type SchemaBuilder() =
        
        /// <summary>
        /// Erstellt ein Object-Schema.
        /// </summary>
        static member Object(properties: Map<string, JObject>, required: string list option) : JObject =
            let schema = JObject()
            schema.["type"] <- JValue("object")
            schema.["properties"] <- JObject(properties |> Seq.map (fun kv -> JProperty(kv.Key, kv.Value)))
            match required with
            | Some reqList -> schema.["required"] <- JArray(reqList |> List.map JValue)
            | None -> ()
            schema

        /// <summary>
        /// Erstellt ein String-Schema.
        /// </summary>
        static member String(?enum: string list, ?pattern: string, ?minLength: int) : JObject =
            let schema = JObject()
            schema.["type"] <- JValue("string")
            match enum with
            | Some e -> schema.["enum"] <- JArray(e |> List.map JValue)
            | None -> ()
            match pattern with
            | Some p -> schema.["pattern"] <- JValue(p)
            | None -> ()
            match minLength with
            | Some len -> schema.["minLength"] <- JValue(len)
            | None -> ()
            schema

        /// <summary>
        /// Erstellt ein Integer-Schema.
        /// </summary>
        static member Integer(?minimum: int, ?maximum: int) : JObject =
            let schema = JObject()
            schema.["type"] <- JValue("integer")
            match minimum with
            | Some min -> schema.["minimum"] <- JValue(min)
            | None -> ()
            match maximum with
            | Some max -> schema.["maximum"] <- JValue(max)
            | None -> ()
            schema

        /// <summary>
        /// Erstellt ein Array-Schema.
        /// </summary>
        static member Array(items: JObject, ?minItems: int) : JObject =
            let schema = JObject()
            schema.["type"] <- JValue("array")
            schema.["items"] <- items
            match minItems with
            | Some mi -> schema.["minItems"] <- JValue(mi)
            | None -> ()
            schema

module Program =
    [<EntryPoint>]
    let main argv =
        let usage = "Usage: dotnet run -- [options] <input>"
        let mutable inputFile = ""
        let mutable schemaFile = ""
        let mutable isFile = false
        let mutable repair = true
        
        // Simple argument parsing
        let args = argv |> List.ofArray
        let rec parseArgs remaining =
            match remaining with
            | "--schema" :: schema :: rest -> schemaFile <- schema; parseArgs rest
            | "-s" :: schema :: rest -> schemaFile <- schema; parseArgs rest
            | "--file" :: rest -> isFile <- true; parseArgs rest
            | "-f" :: rest -> isFile <- true; parseArgs rest
            | "--repair" :: rest -> repair <- true; parseArgs rest
            | "-r" :: rest -> repair <- true; parseArgs rest
            | "--no-repair" :: rest -> repair <- false; parseArgs rest
            | input :: [] -> inputFile <- input
            | [] -> ()
            | _ -> printfn "%s" usage; exit 1
            
        parseArgs args
        
        if inputFile = "" || schemaFile = "" then
            printfn "%s" usage
            exit 1
            
        let rawInput =
            let path = Path.GetFullPath(inputFile)
            if isFile || File.Exists(path) then
                File.ReadAllText(path)
            else
                inputFile
                
        try
            let result = JsonSchemaValidator.validateAndConvert rawInput schemaFile repair
            printfn "%s" (result.ToString())
            printfn "\n✓ Validation passed"
            0
        with
        | :? JSONProcessingError as e
        | :? SchemaValidationError as e ->
            eprintfn "✗ Validation failed: %s" e.Message
            1
        | ex ->
            eprintfn "✗ Unexpected error: %s" ex.Message
            1
