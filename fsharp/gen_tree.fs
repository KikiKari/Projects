// abstraction-provenance: {"artifact_sha256": "f0b0d813518d63bff205cb9bfb02d94425e0f1f1807524f70de142e0d5925eb4", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "fsharp"}
// gen_tree.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
// (used because the `tree` binary is unavailable in this sandbox).
open System
open System.IO

let ROOT = "/workspace"
let OUT = "/workspace/important/openclaw-tree.txt"
let MAX_DEPTH = 6

let rec collect (path: string) (prefix: string) (depth: int) : string list =
    let lines = ResizeArray<string>()
    try
        let entries = Directory.GetFileSystemEntries(path) |> Array.sort
        let total = entries.Length
        for i in 0 .. entries.Length - 1 do
            let name = Path.GetFileName(entries.[i])
            let isLast = (i = total - 1)
            let connector = if isLast then "└── " else "├── "
            lines.Add(prefix + connector + name)
            let fullPath = Path.Combine(path, name)
            if depth < MAX_DEPTH && Directory.Exists(fullPath) && not (File.GetAttributes(fullPath).HasFlag(FileAttributes.ReparsePoint)) then
                let nextPrefix = if isLast then prefix + "    " else prefix + "│   "
                lines.AddRange(collect fullPath nextPrefix (depth + 1))
    with
    | :? UnauthorizedAccessException -> ()
    | :? DirectoryNotFoundException -> ()
    with lines |> List.ofSeq

let body = collect ROOT "" 1
let header = 
    "# OpenClaw Workspace Tree\n" +
    sprintf "# Generiert: %s\n" (DateTime.Now.ToString("o")) +
    sprintf "# Befehl: tree -a -L 6 %s (emuliert via gen_tree.fsx)\n" ROOT +
    "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"

let content = header + ".\n" + (String.Join("\n", body)) + "\n"

File.WriteAllText(OUT, content, Text.Encoding.UTF8)
printfn "written %s: %d lines, %d bytes" OUT (body.Length + 1) content.Length
