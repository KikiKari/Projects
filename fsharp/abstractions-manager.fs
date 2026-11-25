// abstraction-provenance: {"artifact_sha256": "b7237626b27bbb15d8669337174246e48ed10997054c484e7d7561f25754c7dc", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "fsharp"}
// abstractions-manager.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

// This script is a simple wrapper that executes another script with the same arguments
// It mimics the behavior of the original bash script which uses 'exec' to replace itself

open System
open System.Diagnostics

[<EntryPoint>]
let main argv =
    let scriptPath = "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh"
    
    // Create process start info
    let startInfo = ProcessStartInfo(scriptPath)
    startInfo.UseShellExecute <- false
    
    // Pass all arguments to the target script
    for arg in argv do
        startInfo.ArgumentList.Add(arg)
    
    try
        // Start the process and wait for it to complete
        use process = Process.Start(startInfo)
        process.WaitForExit()
        
        // Return the exit code of the executed script
        process.ExitCode
    with
    | :? System.ComponentModel.Win32Exception as ex ->
        // Handle case where the script file is not found or cannot be executed
        eprintfn "Error executing script: %s" ex.Message
        1 // Return non-zero exit code to indicate error
