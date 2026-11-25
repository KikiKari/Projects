// abstraction-provenance: {"artifact_sha256": "047e46f2041590547fdf215ade2a2d643e0fd8e94787d8dc4440624715301d02", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "fsharp"}
// abstractions-manager-cron.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Diagnostics

let private run () =
    let homeDir = Environment.GetEnvironmentVariable("HOME") |> Option.ofObj |> Option.defaultValue "/home/openclaw"
    let openClawHome = Path.Combine(homeDir, ".openclaw")
    
    // Set PATH
    let newPath = $"/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"
    Environment.SetEnvironmentVariable("PATH", newPath)
    
    // Load environment variables from .env file
    let envFile = Path.Combine(openClawHome, ".env")
    if File.Exists(envFile) then
        for line in File.ReadAllLines(envFile) do
            if not (line.Trim().StartsWith("#")) && line.Contains("=") then
                let parts = line.Split('=', 2)
                if parts.Length = 2 then
                    Environment.SetEnvironmentVariable(parts.[0].Trim(), parts.[1].Trim())
    
    // Check required OPENROUTER_API_KEY
    match Environment.GetEnvironmentVariable("OPENROUTER_API_KEY") with
    | null | "" -> failwith "OPENROUTER_API_KEY fehlt"
    | _ -> ()
    
    // Set GITHUB_TOKEN fallbacks
    let ghToken = 
        Environment.GetEnvironmentVariable("GITHUB_TOKEN") |> Option.ofObj
        |> Option.orElse (Environment.GetEnvironmentVariable("GH_TOKEN") |> Option.ofObj)
        |> Option.orElse (Environment.GetEnvironmentVariable("GH_ACCESS_TOKEN") |> Option.ofObj)
        |> Option.defaultValue ""
    
    if not (String.IsNullOrEmpty(ghToken)) then
        Environment.SetEnvironmentVariable("GITHUB_TOKEN", ghToken)
    
    // Create lock directory if it doesn't exist
    let locksDir = Path.Combine(openClawHome, "locks")
    if not (Directory.Exists(locksDir)) then
        Directory.CreateDirectory(locksDir) |> ignore
    
    let lockFile = Path.Combine(locksDir, "abstractions-manager.lock")
    
    // Try to acquire lock and run the Python script
    use process = new Process()
    process.StartInfo.FileName <- "/usr/bin/flock"
    process.StartInfo.Arguments <- $"--nonblock \"{lockFile}\" /usr/bin/python3 \"{Path.Combine(openClawHome, "workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py")}\""
    process.StartInfo.UseShellExecute <- false
    
    try
        if process.Start() then
            process.WaitForExit()
            exit process.ExitCode
        else
            exit 1
    with
    | ex ->
        eprintfn "Error starting process: %s" ex.Message
        exit 1

[<EntryPoint>]
let main argv =
    try
        run()
        0
    with
    | ex ->
        eprintfn "%s" ex.Message
        1
