// abstraction-provenance: {"artifact_sha256": "7a02838f6bd843dd3080df29723c9affbc461bce620a99f33228ef468c9029c2", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "fsharp"}
// openclaw-maintenance.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.Diagnostics
open System.IO

let runCommand (cmd: string) (args: string) =
    let startInfo = ProcessStartInfo(cmd, args)
    startInfo.UseShellExecute <- false
    startInfo.RedirectStandardOutput <- true
    startInfo.RedirectStandardError <- true
    use proc = Process.Start(startInfo)
    proc.WaitForExit()
    if proc.ExitCode <> 0 then
        failwith $"Command failed: {cmd} {args}"

[<EntryPoint>]
let main _ =
    let openClawBin = 
        match Environment.GetEnvironmentVariable("OPENCLAW_BIN") with
        | null | "" -> Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".local", "bin", "openclaw")
        | path -> path

    if not (File.Exists(openClawBin) && File.GetAttributes(openClawBin).HasFlag(FileAttributes.Executable)) then
        eprintfn "ERROR: OpenClaw binary not found: %s" openClawBin
        exit 1

    printfn "Using OpenClaw: %s" (Process.Start(ProcessStartInfo(openClawBin, "--version")).StandardOutput.ReadToEnd().Trim())

    // === 1. Service-/Config-Drift ===
    runCommand openClawBin "doctor"

    // === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
    runCommand openClawBin "plugins registry --refresh"
    
    match Environment.GetEnvironmentVariable("RUN_PLUGIN_UPDATE") with
    | "1" -> runCommand openClawBin "plugins update --all"
    | _ -> printfn "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable."

    // === 3. Tasks ===
    runCommand openClawBin "tasks maintenance --apply"

    // === 4. Sessions – alle Agents auf einmal ===
    runCommand openClawBin "sessions cleanup --enforce --all-agents"

    // === 5. Memory – status/index decken alle Agents ab ===
    runCommand openClawBin "memory status --deep --fix"
    runCommand openClawBin "memory index --force"

    // === 6. Memory promote – MUSS pro Agent ===
    for agent in ["main"; "knecht"; "docs"; "ops-hub"; "cron"] do
        runCommand openClawBin $"memory promote --apply --agent {agent}"

    // === 7. Secrets ===
    runCommand openClawBin "secrets reload"

    0
