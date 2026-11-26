// abstraction-provenance: {"artifact_sha256": "9a8bf96b6eb6c47c79a9862f7f546f5f3478ee4a60cb0decc702ebb75c1e3e2e", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "fsharp"}
// frame.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.Diagnostics
open System.IO

let usage () =
    eprintfn "Usage:"
    eprintfn "  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg"
    eprintfn ""
    eprintfn "Examples:"
    eprintfn "  frame.sh video.mp4 --out /tmp/frame.jpg"
    eprintfn "  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg"
    eprintfn "  frame.sh video.mp4 --index 0 --out /tmp/frame0.png"
    Environment.Exit 2

let runFfmpeg args =
    let startInfo = ProcessStartInfo(
        FileName = "ffmpeg",
        Arguments = String.concat " " args,
        UseShellExecute = false,
        RedirectStandardOutput = true,
        RedirectStandardError = true
    )
    
    use proc = new Process()
    proc.StartInfo <- startInfo
    proc.Start() |> ignore
    proc.WaitForExit()
    
    if proc.ExitCode <> 0 then
        let stderr = proc.StandardError.ReadToEnd()
        if not (String.IsNullOrEmpty(stderr)) then
            eprintf "%s" stderr
        Environment.Exit 1

[<EntryPoint>]
let main argv =
    if Array.isEmpty argv || argv.[0] = "-h" || argv.[0] = "--help" then
        usage()
        
    let input = argv.[0]
    let mutable time = None
    let mutable index = None
    let mutable output = None
    
    let rec parseArgs i =
        if i >= argv.Length then ()
        else
            match argv.[i] with
            | "--time" when i + 1 < argv.Length ->
                time <- Some argv.[i + 1]
                parseArgs (i + 2)
            | "--index" when i + 1 < argv.Length ->
                index <- Some argv.[i + 1]
                parseArgs (i + 2)
            | "--out" when i + 1 < argv.Length ->
                output <- Some argv.[i + 1]
                parseArgs (i + 2)
            | _ ->
                eprintfn "Unknown arg: %s" argv.[i]
                usage()
                
    parseArgs 1
    
    if not (File.Exists input) then
        eprintfn "File not found: %s" input
        Environment.Exit 1
        
    match output with
    | None -> 
        eprintfn "Missing --out"
        usage()
    | Some outPath ->
        let dir = Path.GetDirectoryName(outPath)
        if not (String.IsNullOrEmpty(dir)) && not (Directory.Exists(dir)) then
            Directory.CreateDirectory(dir) |> ignore
            
        let args = 
            match index, time with
            | Some idx, _ ->
                [ "-hide_banner"; "-loglevel"; "error"; "-y"
                  "-i"; input
                  "-vf"; sprintf "select=eq(n\\,%s)" idx
                  "-vframes"; "1"
                  outPath ]
            | _, Some t ->
                [ "-hide_banner"; "-loglevel"; "error"; "-y"
                  "-ss"; t
                  "-i"; input
                  "-frames:v"; "1"
                  outPath ]
            | None, None ->
                [ "-hide_banner"; "-loglevel"; "error"; "-y"
                  "-i"; input
                  "-vf"; "select=eq(n\\,0)"
                  "-vframes"; "1"
                  outPath ]
                  
        runFfmpeg args
        printfn "%s" outPath
        0
