// abstraction-provenance: {"artifact_sha256": "5741fb33dbed189c414698d11a83b56ba6b4e13200b4e14a3b6236bfaef7c7e5", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "fsharp"}
// dispatch_job.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Job Dispatcher - Verteilt Jobs auf passende Nodes

open System
open System.Diagnostics
open System.IO
open System.Collections.Generic

// Node-Konfiguration
let NODES = dict [
    ("node1", dict [("always_available", box true); ("capacity", box "medium"); ("priority", box 2)])
    ("node2", dict [("always_available", box true); ("capacity", box "medium"); ("priority", box 3)])
    ("node3", dict [("always_available", box false); ("capacity", box "medium"); ("priority", box 4)])
    ("node5", dict [("always_available", box false); ("capacity", box "low"); ("priority", box 5); ("device", box "Redmi Note 11S")])
    ("node7", dict [("always_available", box true); ("capacity", box "high"); ("priority", box 1)])
]

type JobDispatcher() =
    /// Bewertet Job-Gewicht
    member this.GetJobWeight(scriptPath: string, targetLangsCount: int) : string =
        if not (File.Exists scriptPath) then
            "medium"
        else
            let scriptSize = FileInfo(scriptPath).Length
            let totalWork = scriptSize * int64 targetLangsCount
            
            if totalWork > 50000L then // > 50KB
                "heavy"
            elif totalWork > 10000L then // > 10KB
                "medium"
            else
                "light"
    
    /// Wählt besten Node basierend auf Job-Gewicht
    member this.SelectNode(jobWeight: string) : string =
        let preferred = 
            match jobWeight with
            | "heavy" -> ["node7"; "node2"; "node1"] // Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            | "medium" -> ["node2"; "node1"; "node7"] // Mittlere Jobs → Stable Nodes
            | _ -> ["node5"; "node1"; "node2"] // Leichte Jobs → Mobile/verfügbare Nodes
        
        // Prüfe Verfügbarkeit
        let rec findAvailable nodes =
            match nodes with
            | [] -> "node1" // Fallback
            | node :: rest ->
                if this.CheckNodeAvailable node then
                    node
                else
                    findAvailable rest
        
        findAvailable preferred
    
    /// Prüft ob Node erreichbar ist
    member this.CheckNodeAvailable(nodeId: string) : bool =
        if not (NODES.ContainsKey nodeId) then
            false
        else
            let node = NODES.[nodeId]
            
            // Nicht immer-verfügbare Nodes nur wenn explizit requested
            if not (node.ContainsKey "always_available") || unbox<bool> node.["always_available"] = false then
                // Für light-jobs prüfen wir ob online
                if nodeId = "node5" then // Redmi
                    this.CheckMobileOnline()
                else
                    false
            else
                // Für immer-verfügbare Nodes: prüfe ob wirklich online
                try
                    let startInfo = ProcessStartInfo(
                        FileName = "openclaw",
                        Arguments = $"nodes status {nodeId}",
                        RedirectStandardOutput = true,
                        UseShellExecute = false
                    )
                    use proc = Process.Start(startInfo)
                    proc.WaitForExit(3000)
                    proc.ExitCode = 0
                with
                | _ -> unbox<bool> node.["always_available"]
    
    /// Prüft ob Redmi (Node 5) Internet hat
    member private this.CheckMobileOnline() : bool =
        try
            let startInfo = ProcessStartInfo(
                FileName = "openclaw",
                Arguments = "nodes status node5",
                RedirectStandardOutput = true,
                UseShellExecute = false
            )
            use proc = Process.Start(startInfo)
            proc.WaitForExit(5000)
            let output = proc.StandardOutput.ReadToEnd().ToLower()
            proc.ExitCode = 0 && output.Contains("online")
        with
        | _ -> false
    
    /// Dispatched Job und gibt Info zurück
    member this.Dispatch(jobScript: string, ?targetLangs: string list) : Map<string, obj> =
        let targetLangs = defaultArg targetLangs ["perl5"]
        let weight = this.GetJobWeight(jobScript, List.length targetLangs)
        let selectedNode = this.SelectNode(weight)
        
        Map [
            ("job", box jobScript)
            ("weight", box weight)
            ("selected_node", box selectedNode)
            ("target_langs", box targetLangs)
            ("status", box "dispatched")
        ]

module Main =
    open System
    
    [<EntryPoint>]
    let main argv =
        let parseArgs (args: string[]) =
            let mutable job = ""
            let mutable langs = "perl5"
            let mutable weight = ""
            let mutable execute = false
            
            let rec parse acc = function
                | "--job" :: value :: rest | "-j" :: value :: rest ->
                    job <- value
                    parse acc rest
                | "--langs" :: value :: rest | "-l" :: value :: rest ->
                    langs <- value
                    parse acc rest
                | "--weight" :: value :: rest | "-w" :: value :: rest ->
                    weight <- value
                    parse acc rest
                | "--execute" :: rest | "-x" :: rest ->
                    execute <- true
                    parse acc rest
                | arg :: rest -> parse (arg :: acc) rest
                | [] -> List.rev acc
            
            ignore (parse [] (List.ofArray args))
            (job, langs, weight, execute)
        
        let (jobArg, langsArg, weightArg, executeFlag) = parseArgs argv
        
        if String.IsNullOrEmpty jobArg then
            printfn "❌ Job argument is required"
            1
        else
            let jobPath = jobArg
            if not (File.Exists jobPath) then
                printfn $"❌ Job not found: {jobPath}"
                1
            else
                let dispatcher = JobDispatcher()
                let targetLangs = langsArg.Split(',') |> Array.toList
                
                // Determine weight
                let weight = 
                    if String.IsNullOrEmpty weightArg then
                        dispatcher.GetJobWeight(jobPath, List.length targetLangs)
                    else
                        weightArg
                
                // Select node
                let selectedNode = dispatcher.SelectNode(weight)
                
                // Output
                printfn "📦 Job Dispatch Information"
                printfn "=================================================="
                let fileInfo = FileInfo(jobPath)
                printfn $"Job: {jobPath}"
                printfn $"Size: {fileInfo.Length} bytes"
                printfn $"Target langs: {String.Join(", ", targetLangs)}"
                printfn $"Job weight: {weight}"
                printfn $"Selected node: {selectedNode}"
                printfn "=================================================="
                
                if executeFlag then
                    printfn $"\n🚀 Executing on {selectedNode}..."
                    // TODO: Implement remote execution
                    printfn "(Remote execution not yet implemented)"
                else
                    let currentExe = System.Reflection.Assembly.GetEntryAssembly().Location
                    printfn $"\n💡 To execute: {currentExe} --job {jobArg} --execute"
                
                0
