// abstraction-provenance: {"artifact_sha256": "e54f63595dd6551ed0ce1c45e329acb97821385662a419c4e06c503c7d6d846f", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "fsharp"}
// check_nodes.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module CheckNodes

open System
open System.Diagnostics
open System.Text.Json
open System.IO
open System.Collections.Generic

// Node-Konfiguration (sollte aus config file geladen werden)
let NODES = dict [
    ("node1", dict [
        ("always_available", box true)
        ("capacity", box "medium")
        ("priority", box 2)
        ("description", box "Gateway-Master")
    ])
    ("node2", dict [
        ("always_available", box true)
        ("capacity", box "medium")
        ("priority", box 3)
        ("description", box "Stable Worker")
    ])
    ("node3", dict [
        ("always_available", box false)
        ("capacity", box "medium")
        ("priority", box 4)
        ("description", box "Bald verfügbar (nach Reorganisation)")
    ])
    ("node5", dict [
        ("always_available", box false)
        ("capacity", box "low")
        ("priority", box 5)
        ("device", box "Redmi Note 11S")
        ("description", box "Mobile (bei Internet verfügbar)")
    ])
    ("node7", dict [
        ("always_available", box true)
        ("capacity", box "high")
        ("priority", box 1)
        ("description", box "Docker Hauptarbeitspferd (bald verfügbar)")
    ])
]

type NodeStatus = {
    id: string
    online: bool
    available: bool
    response: string
}

let checkNodeStatus (nodeId: string) : NodeStatus =
    try
        let startInfo = ProcessStartInfo(
            FileName = "openclaw",
            Arguments = $"nodes status {nodeId}",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )
        
        use proc = new Process()
        proc.StartInfo <- startInfo
        proc.Start() |> ignore
        
        let finished = proc.WaitForExit(5000)
        if not finished then
            proc.Kill()
            { id = nodeId; online = false; available = unbox NODES.[nodeId].["always_available"]; response = "Timeout" }
        else
            let stdout = proc.StandardOutput.ReadToEnd()
            let isOnline = proc.ExitCode = 0 && 
                          (stdout.ToLower().Contains("online") || stdout.ToLower().Contains("active"))
            { id = nodeId; online = isOnline; available = unbox NODES.[nodeId].["always_available"]; response = if String.IsNullOrEmpty(stdout) then "No response" else stdout.Trim().Substring(0, min 100 stdout.Length) }
    with
    | :? System.Exception as ex -> 
        { id = nodeId; online = false; available = unbox NODES.[nodeId].["always_available"]; response = $"Error: {ex.Message}" }

let printTable (nodesStatus: NodeStatus list) =
    printfn "\n%s" (String.replicate 90 "=")
    printfn "%-8s %-12s %-12s %-10s %-10s %s" "Node" "Status" "Verfügbar" "Kapazität" "Priorität" "Gerät/Beschreibung"
    printfn "%s" (String.replicated 90 "=")
    
    for status in nodesStatus do
        let nodeId = status.id
        let config = NODES.[nodeId]
        
        let statusIcon = if status.online then "🟢 Online" else "🔴 Offline"
        let availIcon = if status.available then "✅ Immer" else "📱 Bedingt"
        let capacity = if config.ContainsKey("capacity") then unbox config.["capacity"] else "unknown"
        let priority = if config.ContainsKey("priority") then string (unbox<int> config.["priority"]) else "-"
        let device = if config.ContainsKey("device") then unbox config.["device"] 
                     elif config.ContainsKey("description") then unbox config.["description"] 
                     else ""
        
        printfn "%-8s %-12s %-12s %-10s %-10s %s" nodeId statusIcon availIcon capacity priority device
    
    printfn "%s" (String.replicated 90 "=")
    printfn "\nGeprüft am: %s" (DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))

let printJson (nodesStatus: NodeStatus list) =
    let output = dict [
        ("timestamp", box (DateTime.Now.ToString("o")))
        ("nodes", box (nodesStatus |> List.map (fun status -> 
            let nodeId = status.id
            (nodeId, box (dict [("status", box status); ("config", box NODES.[nodeId])]))
        ) |> dict))
    ]
    
    let options = JsonSerializerOptions(WriteIndented = true)
    let json = JsonSerializer.Serialize(output, options)
    printfn "%s" json

[<EntryPoint>]
let main argv =
    let args = argv |> Array.toList
    
    let format = 
        match args |> List.tryFindIndex (fun x -> x = "--format" || x = "-f") with
        | Some i when i + 1 < args.Length -> args.[i + 1]
        | _ -> "table"
    
    let saveFile = 
        match args |> List.tryFindIndex (fun x -> x = "--save" || x = "-s") with
        | Some i when i + 1 < args.Length -> Some args.[i + 1]
        | _ -> None
    
    printfn "🔍 Prüfe Node-Status..."
    
    // Prüfe alle Nodes
    let nodesStatus = 
        NODES.Keys 
        |> Seq.sort 
        |> Seq.map (fun nodeId ->
            printf $"  → {nodeId}... "
            let status = checkNodeStatus nodeId
            printfn "%s" (if status.online then "✓" else "✗")
            status
        )
        |> Seq.toList
    
    // Ausgabe
    match format with
    | "json" -> printJson nodesStatus
    | _ -> printTable nodesStatus
    
    // Speichern
    match saveFile with
    | Some filename ->
        let output = dict [
            ("timestamp", box (DateTime.Now.ToString("o")))
            ("nodes", box (nodesStatus |> List.map (fun s -> (s.id, box s)) |> dict))
        ]
        let options = JsonSerializerOptions(WriteIndented = true)
        let json = JsonSerializer.Serialize(output, options)
        File.WriteAllText(filename, json)
        printfn "\n💾 Gespeichert: %s" filename
    | None -> ()
    
    // Zusammenfassung
    let onlineCount = nodesStatus |> List.filter (fun s -> s.online) |> List.length
    printfn "\n📊 Zusammenfassung: %d/%d Nodes online" onlineCount nodesStatus.Length
    
    0
