// abstraction-provenance: {"artifact_sha256": "49f13b842560e1fd2303bdc12cd9bff25a21e8edc1d0f6a1109e67dea58145ba", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "fsharp"}
// json_websearch.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace JsonWebSearch

open System
open System.IO
open System.Text.Json
open System.Collections.Generic
open System.CommandLine
open System.CommandLine.Invocation

/// <summary>
/// JSON Utils + WebSearch integration.
/// Fetch API schemas from web, validate real API responses, batch-validate endpoints.
/// </summary>

// Simulated imports from json-utils
module JsonUtils =
    // Placeholder functions to simulate the behavior of imported modules
    let parseJson (data: string) (repair: bool) : obj = 
        JsonSerializer.Deserialize<obj>(data)

    let validateWithJsonSchema (data: obj) (schemaPath: string) : unit = 
        ()

    let parseAndValidate (jsonData: string) (schema: obj) : obj = 
        JsonSerializer.Deserialize<obj>(jsonData)

    let processFileBatch (files: string[]) : unit = 
        ()

type WebSearchResult = {
    Query: string
    JsonData: obj
    ValidationErrors: string list
    SchemaMatched: bool
    SourceUrl: string
}

type WebSearchJSON(useRepair: bool) =
    /// <summary>
    /// Combine WebSearch with JSON validation.
    /// 
    /// Use cases:
    /// 1. Search for API documentation, extract schema
    /// 2. Validate real API responses against schemas
    /// 3. Batch-validate multiple API endpoints
    /// 4. Auto-repair common API response errors
    /// </summary>
    
    let jsonAvailable = true // Assuming always available in this translation

    member this.SearchAndValidate(query: string, ?schema: obj, ?schemaPath: string) : WebSearchResult =
        /// <summary>
        /// Search web for JSON data, validate against schema.
        /// 
        /// This is a placeholder - in real usage, this would:
        /// 1. Call WebSearch to find API docs
        /// 2. Extract JSON examples/schemas from results
        /// 3. Parse and validate with json-utils
        /// </summary>
        
        // Simulate web search result (would be actual search in production)
        let mockResponse = dict [
            ("api", box (if not (String.IsNullOrEmpty(query)) then query.Split(' ').[0] else "unknown"))
            ("version", box "1.0")
            ("endpoints", box [|
                dict [("path", box "/items"); ("method", box "GET")]
                dict [("path", box "/items"); ("method", box "POST")]
            |])
        ]

        // Validate with json-utils if available
        let validationErrors = ResizeArray<string>()
        let mutable schemaMatched = false

        if jsonAvailable && (schema.IsSome || schemaPath.IsSome) then
            try
                match schemaPath with
                | Some path -> JsonUtils.validateWithJsonSchema mockResponse path
                | None -> ()
                schemaMatched <- true
            with
            | ex -> validationErrors.Add(ex.Message)

        {
            Query = query
            JsonData = mockResponse
            ValidationErrors = validationErrors |> List.ofSeq
            SchemaMatched = schemaMatched
            SourceUrl = sprintf "https://api.github.com/search?q=%s" (query.Replace(" ", "+"))
        }

    member this.ValidateApiResponse(responseData: string, endpoint: string, ?expectedSchema: obj) : obj =
        /// <summary>
        /// Validate an API response with auto-repair.
        /// 
        /// Uses json-utils for robust parsing.
        /// </summary>
        
        if not jsonAvailable then
            JsonSerializer.Deserialize<obj>(responseData)
        else
            // Use json-utils parser with auto-repair
            let result = JsonUtils.parseJson responseData useRepair
            
            match expectedSchema with
            | Some schema ->
                try
                    JsonUtils.parseAndValidate (JsonSerializer.Serialize(result)) schema |> ignore
                with
                | ex -> printfn "Schema validation failed for %s: %s" endpoint ex.Message
            | None -> ()
            
            result

    member this.BatchValidateEndpoints(endpoints: string[], responses: string[], ?schemaPath: string) : WebSearchResult[] =
        /// <summary>
        /// Batch-validate multiple API endpoint responses.
        /// </summary>
        
        let results = ResizeArray<WebSearchResult>()
        Array.iter2 (fun endpoint response ->
            try
                let jsonData = this.ValidateApiResponse(response, endpoint)
                results.Add({
                    Query = endpoint
                    JsonData = jsonData
                    ValidationErrors = []
                    SchemaMatched = true
                    SourceUrl = endpoint
                })
            with
            | ex -> results.Add({
                Query = endpoint
                JsonData = dict []
                ValidationErrors = [ex.Message]
                SchemaMatched = false
                SourceUrl = endpoint
            })
        ) endpoints responses
        results.ToArray()

    member this.GenerateApiSchema(sampleResponse: string, endpoint: string) : obj =
        /// <summary>
        /// Generate JSON Schema from sample API response.
        /// </summary>
        
        if not jsonAvailable then
            dict [] :> obj
        else
            let data = JsonUtils.parseJson sampleResponse false
            
            // Basic schema generation
            let rec inferSchema (obj: obj) (path: string) : obj =
                match obj with
                | :? IDictionary<string, obj> as dict ->
                    let properties = dict |> Seq.map (fun kvp -> kvp.Key, inferSchema kvp.Value (sprintf "%s.%s" path kvp.Key)) |> dict
                    dict [
                        ("type", box "object")
                        ("properties", box properties)
                    ] :> obj
                | :? IList<obj> as list when list.Count > 0 ->
                    dict [
                        ("type", box "array")
                        ("items", inferSchema list.[0] (sprintf "%s[]" path))
                    ] :> obj
                | :? string -> dict [("type", box "string")] :> obj
                | :? int -> dict [("type", box "integer")] :> obj
                | :? float -> dict [("type", box "number")] :> obj
                | :? bool -> dict [("type", box "boolean")] :> obj
                | _ -> dict [("type", box "null")] :> obj
            
            let schema = dict [
                ("$schema", box "http://json-schema.org/draft-07/schema#")
                ("title", box (sprintf "%s Response Schema" endpoint))
            ]
            
            // Merge with inferred schema
            let inferred = inferSchema data "root" :?> IDictionary<string, obj>
            inferred |> Seq.iter (fun kvp -> schema.[kvp.Key] <- kvp.Value)
            
            schema :> obj

module Program =
    [<EntryPoint>]
    let main argv =
        let rootCommand = Command("json-websearch", "JSON Utils + WebSearch integration")
        
        let searchOption = Option<string>("--search", "Search query for API docs")
        let validateFileOption = Option<string>("--validate-file", "JSON file to validate")
        let schemaOption = Option<string>("--schema", "Schema file path")
        let generateSchemaOption = Option<string>("--generate-schema", "Generate schema from sample JSON file")
        let endpointOption = Option<string>("--endpoint", "API endpoint identifier")
        
        rootCommand.AddOption(searchOption)
        rootCommand.AddOption(validateFileOption)
        rootCommand.AddOption(schemaOption)
        rootCommand.AddOption(generateSchemaOption)
        rootCommand.AddOption(endpointOption)
        
        rootCommand.SetHandler(fun search validateFile schema generateSchema endpoint ->
            let ws = WebSearchJSON(true)
            
            match search with
            | Some query ->
                let result = ws.SearchAndValidate(query, schemaPath = schema)
                printfn "Query: %s" result.Query
                printfn "Data: %s" (JsonSerializer.Serialize(result.JsonData, indented = true))
                printfn "Schema matched: %b" result.SchemaMatched
                if not (List.isEmpty result.ValidationErrors) then
                    printfn "Errors: %A" result.ValidationErrors
            | None ->
                match generateSchema, endpoint with
                | Some filePath, Some endpointName ->
                    let sample = File.ReadAllText(filePath)
                    let schemaObj = ws.GenerateApiSchema(sample, endpointName)
                    printfn "%s" (JsonSerializer.Serialize(schemaObj, indented = true))
                | _ -> ()
        , searchOption, validateFileOption, schemaOption, generateSchemaOption, endpointOption)
        
        rootCommand.Invoke(argv) |> ignore
        0
