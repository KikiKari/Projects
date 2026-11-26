// abstraction-provenance: {"artifact_sha256": "4dca3fa136b97f71c1cfa913c702a3ea3c310d7410d882846b9e5fcde859cc56", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "fsharp"}
// find-sessions.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Diagnostics
open System.Text.RegularExpressions

let usage () =
    Console.Error.WriteLine """Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help"""
    exit 0

let runTmuxCommand args =
    let psi = ProcessStartInfo("tmux", String.concat " " args)
    psi.UseShellExecute <- false
    psi.RedirectStandardOutput <- true
    psi.RedirectStandardError <- true
    use proc = Process.Start(psi)
    proc.WaitForExit()
    if proc.ExitCode = 0 then
        Some(proc.StandardOutput.ReadToEnd())
    else
        None

let listSessions label tmuxArgs query =
    let format = "#{session_name}\t#{session_attached}\t#{session_created_string}"
    match runTmuxCommand (tmuxArgs @ ["list-sessions"; "-F"; format]) with
    | None ->
        Console.Error.WriteLine $"No tmux server found on {label}"
        false
    | Some output ->
        let lines = output.Split([| '\n' |], StringSplitOptions.RemoveEmptyEntries)
        let filteredLines = 
            if String.IsNullOrWhiteSpace(query) then
                lines
            else
                lines
                |> Array.filter (fun line -> 
                    let parts = line.Split('\t')
                    if parts.Length > 0 then
                        parts.[0].ToLower().Contains(query.ToLower())
                    else
                        false)

        if filteredLines.Length = 0 then
            Console.WriteLine $"No sessions found on {label}"
        else
            Console.WriteLine $"Sessions on {label}:"
            for line in filteredLines do
                let parts = line.Split('\t')
                if parts.Length >= 3 then
                    let name = parts.[0]
                    let attached = if parts.[1] = "1" then "attached" else "detached"
                    let created = parts.[2]
                    Console.WriteLine $"  - {name} ({attached}, started {created})"
        true

[<EntryPoint>]
let main argv =
    let mutable socketName = ""
    let mutable socketPath = ""
    let mutable query = ""
    let mutable scanAll = false
    let socketDir = 
        match Environment.GetEnvironmentVariable("CLAWDBOT_TMUX_SOCKET_DIR") with
        | null ->
            let tmpDir = 
                match Environment.GetEnvironmentVariable("TMPDIR") with
                | null -> "/tmp"
                | tmp -> tmp
            Path.Combine(tmpDir, "clawdbot-tmux-sockets")
        | dir -> dir

    let mutable i = 0
    while i < argv.Length do
        match argv.[i] with
        | ("-L" | "--socket") when i + 1 < argv.Length ->
            socketName <- argv.[i + 1]
            i <- i + 2
        | ("-S" | "--socket-path") when i + 1 < argv.Length ->
            socketPath <- argv.[i + 1]
            i <- i + 2
        | ("-A" | "--all") ->
            scanAll <- true
            i <- i + 1
        | ("-q" | "--query") when i + 1 < argv.Length ->
            query <- argv.[i + 1]
            i <- i + 2
        | ("-h" | "--help") ->
            usage()
        | _ ->
            Console.Error.WriteLine $"Unknown option: {argv.[i]}"
            usage()
            exit 1

    if scanAll && (not (String.IsNullOrWhiteSpace(socketName)) || not (String.IsNullOrWhiteSpace(socketPath))) then
        Console.Error.WriteLine "Cannot combine --all with -L or -S"
        exit 1

    if not (String.IsNullOrWhiteSpace(socketName)) && not (String.IsNullOrWhiteSpace(socketPath)) then
        Console.Error.WriteLine "Use either -L or -S, not both"
        exit 1

    try
        Process.Start("tmux", "-V") |> ignore
    with
        | :? FileNotFoundException ->
            Console.Error.WriteLine "tmux not found in PATH"
            exit 1
        | _ -> ()

    if scanAll then
        if not (Directory.Exists(socketDir)) then
            Console.Error.WriteLine $"Socket directory not found: {socketDir}"
            exit 1

        let sockets = Directory.GetFiles(socketDir)
        if sockets.Length = 0 then
            Console.Error.WriteLine $"No sockets found under {socketDir}"
            exit 1

        let mutable exitCode = 0
        for sock in sockets do
            if File.Exists(sock) then
                if not (listSessions $"socket path '{sock}'" [ "-S"; sock ] query) then
                    exitCode <- 1
        exit exitCode

    let tmuxArgs, socketLabel =
        if not (String.IsNullOrWhiteSpace(socketName)) then
            [ "-L"; socketName ], $"socket name '{socketName}'"
        elif not (String.IsNullOrWhiteSpace(socketPath)) then
            [ "-S"; socketPath ], $"socket path '{socketPath}'"
        else
            [], "default socket"

    if not (listSessions socketLabel tmuxArgs query) then
        1
    else
        0
