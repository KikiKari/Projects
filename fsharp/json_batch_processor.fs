// abstraction-provenance: {"artifact_sha256": "bccbc4b060cad3a51905845a577bd23bd4d5a4d8f45c498190b8e10fa2de7605", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "fsharp"}
// json_batch_processor.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text.Json
open System.Collections.Generic
open System.Threading.Tasks
open System.CommandLine
open System.CommandLine.Invocation

type BatchResult =
    {
        Index: int
        Source: string
        Success: bool
        Data: obj option
        Error: string option
    }
    member this.ToDict() =
        dict [
            ("index", box this.Index)
            ("source", box this.Source)
            ("success", box this.Success)
            ("data", box (match this.Data with Some d -> d | None -> null))
            ("error", box (match this.Error with Some e -> e | None -> null))
        ]

let readJsonl (filePath: string) : seq<obj> =
    seq {
        use reader = new StreamReader(filePath, Text.Encoding.UTF8)
        let mutable lineNum = 1
        while not reader.EndOfStream do
            let! line = reader.ReadLineAsync()
            if not (String.IsNullOrWhiteSpace(line)) then
                try
                    let json = JsonSerializer.Deserialize<obj>(line.Trim())
                    yield json
                with ex ->
                    yield {
                        Index = lineNum
                        Source = sprintf "%s:%d" filePath lineNum
                        Success = false
                        Data = None
                        Error = Some(sprintf "JSON decode error: %s" ex.Message)
                    } :> obj
            lineNum <- lineNum + 1
    }

let processBatch<'T> (inputs: 'T[]) (processor: 'T -> int -> Task<BatchResult>) (maxWorkers: int) : Task<BatchResult[]> =
    task {
        let results = Array.zeroCreate<BatchResult> inputs.Length
        let tasks = Array.init inputs.Length (fun i -> 
            task {
                try
                    let! result = processor inputs.[i] i
                    return result
                with ex ->
                    return {
                        Index = i
                        Source = inputs.[i].ToString()
                        Success = false
                        Data = None
                        Error = Some(sprintf "Unexpected error: %s" ex.Message)
                    }
            })
        
        let! completedTasks = Task.WhenAll(tasks) |> Async.AwaitTask
        Array.Copy(completedTasks, results, inputs.Length)
        Array.Sort(results, fun a b -> compare a.Index b.Index)
        return results
    }

let processFileBatch (filePaths: string[]) (repair: bool) (validateModel: Type option) (maxWorkers: int) : Task<BatchResult[]> =
    let processor (path: string) (idx: int) : Task<BatchResult> =
        task {
            try
                let! content = File.ReadAllTextAsync(path, Text.Encoding.UTF8)
                // In F# gibt es kein direktes Äquivalent zu parse_and_validate ohne externe Bibliotheken
                // Daher verwenden wir einfach das Parsen ohne Validierung
                let data = JsonSerializer.Deserialize<obj>(content)
                return {
                    Index = idx
                    Source = path
                    Success = true
                    Data = Some(data)
                    Error = None
                }
            with ex ->
                return {
                    Index = idx
                    Source = path
                    Success = false
                    Data = None
                    Error = Some(sprintf "%s: %s" (ex.GetType().Name) ex.Message)
                }
        }
    
    processBatch filePaths processor maxWorkers

let processJsonlFile (filePath: string) (repair: bool) (validateModel: Type option) : Task<BatchResult[]> =
    task {
        let results = ResizeArray<BatchResult>()
        use reader = new StreamReader(filePath, Text.Encoding.UTF8)
        let mutable lineNum = 1
        
        while not reader.EndOfStream do
            let! line = reader.ReadLineAsync()
            if not (String.IsNullOrWhiteSpace(line)) then
                try
                    // Auch hier ohne Validierung wie oben
                    let data = JsonSerializer.Deserialize<obj>(line.Trim())
                    results.Add({
                        Index = lineNum
                        Source = sprintf "%s:%d" filePath lineNum
                        Success = true
                        Data = Some(data)
                        Error = None
                    })
                with ex ->
                    results.Add({
                        Index = lineNum
                        Source = sprintf "%s:%d" filePath lineNum
                        Success = false
                        Data = None
                        Error = Some(sprintf "%s: %s" (ex.GetType().Name) ex.Message)
                    })
            lineNum <- lineNum + 1
        
        return results.ToArray()
    }

let writeJsonl (results: BatchResult[]) (outputPath: string) (onlySuccessful: bool) : unit =
    use writer = new StreamWriter(outputPath, false, Text.Encoding.UTF8)
    for result in results do
        if not onlySuccessful || result.Success then
            let dict = result.ToDict()
            let json = JsonSerializer.Serialize(dict)
            writer.WriteLine(json)

let createCommandLineHandler () =
    CommandHandler.Create(fun (inputs: string[]) (jsonl: bool) (repair: bool) (workers: int) (output: string option) (summary: bool) ->
        task {
            let allResults = ResizeArray<BatchResult>()
            
            if jsonl then
                for inputPath in inputs do
                    let! results = processJsonlFile inputPath repair None
                    allResults.AddRange(results)
            else
                let! results = processFileBatch inputs repair None workers
                allResults.AddRange(results)
            
            let successful = allResults |> Seq.filter (fun r -> r.Success) |> Seq.length
            let failed = allResults.Count - successful
            
            if summary then
                printfn "Processed: %d" allResults.Count
                printfn "Successful: %d" successful
                printfn "Failed: %d" failed
            else
                for result in allResults do
                    if result.Success then
                        match result.Data with
                        | Some data -> 
                            let json = JsonSerializer.Serialize(data)
                            printfn "%s" json
                        | None -> ()
                    else
                        match result.Error with
                        | Some error -> eprintfn "ERROR [%s]: %s" result.Source error
                        | None -> ()
            
            match output with
            | Some outputPath ->
                writeJsonl (allResults.ToArray()) outputPath false
                eprintfn "\nResults written to: %s" outputPath
            | None -> ()
            
            return if failed = 0 then 0 else 1
        } :> Task<int>
    )

[<EntryPoint>]
let main argv =
    let rootCommand = RootCommand("Batch JSON Processor")
    
    let inputsArgument = Argument<string[]>("inputs", "JSON files to process")
    rootCommand.AddArgument(inputsArgument)
    
    let jsonlOption = Option<bool>([|"--jsonl"; "-l"|], "Treat inputs as JSON-Lines files")
    rootCommand.AddOption(jsonlOption)
    
    let repairOption = Option<bool>([|"--repair"; "-r"|], () -> true, "Enable JSON repair")
    rootCommand.AddOption(repairOption)
    
    let workersOption = Option<int>([|"--workers"; "-w"|], () -> 4, "Parallel workers")
    rootCommand.AddOption(workersOption)
    
    let outputOption = Option<string option>([|"--output"; "-o"|], "Output JSON-Lines file")
    rootCommand.AddOption(outputOption)
    
    let summaryOption = Option<bool>([|"--summary"; "-s"|], "Show summary only")
    rootCommand.AddOption(summaryOption)
    
    rootCommand.Handler <- createCommandLineHandler()
    
    rootCommand.Invoke(argv)
