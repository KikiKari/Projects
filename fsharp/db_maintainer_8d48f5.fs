// abstraction-provenance: {"artifact_sha256": "4e3c27f9623b6209f5d7bc27936ccb0739b995c33a70a784082f7024c1ca5c4d", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "fsharp"}
// db_maintainer.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace OpenClaw.DbMaintainer

open System
open System.IO
open System.Diagnostics
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Collections.Generic

// Konfiguration
let WORKSPACE = 
    match Environment.GetEnvironmentVariable("OPENCLAW_WORKSPACE") with
    | null -> Path.GetFullPath(Path.Combine(__SOURCE_FILE__, "..", ".."))
    | path -> path

let DB_DIR = WORKSPACE
let BACKUP_DIR = Path.Combine(WORKSPACE, "db", "backups")
let LOG_DIR = Path.Combine(WORKSPACE, "logs", "db-maintainer")
let IMPORTANT_DIR = Path.Combine(WORKSPACE, "important")

// Verzeichnisse erstellen
Directory.CreateDirectory(BACKUP_DIR) |> ignore
Directory.CreateDirectory(LOG_DIR) |> ignore
Directory.CreateDirectory(IMPORTANT_DIR) |> ignore

type Logger() =
    let logFile = 
        let today = DateTime.Now.ToString("yyyy-MM-dd")
        Path.Combine(LOG_DIR, $"{today}.log")

    member this.Log(level: string, message: string) =
        let timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
        let line = $"[{timestamp}] [{level}] {message}"
        printfn "%s" line
        File.AppendAllText(logFile, line + "\n")

    member this.Info(msg: string) = this.Log("INFO", msg)
    member this.Warn(msg: string) = this.Log("WARN", msg)
    member this.Error(msg: string) = this.Log("ERROR", msg)

type State = {
    LastCheck: string option
    LastBackup: string option
    LastTreeUpdate: string option
    FileHashes: Map<string, string>
}

module State =
    let empty = {
        LastCheck = None
        LastBackup = None
        LastTreeUpdate = None
        FileHashes = Map.empty
    }

type DatabaseMaintainer() =
    let logger = Logger()
    let stateFile = Path.Combine(DB_DIR, "maintainer_state.json")
    let retentionDays = 3

    member private this.LoadState(): State =
        if File.Exists(stateFile) then
            try
                let json = File.ReadAllText(stateFile)
                let options = JsonSerializerOptions(PropertyNameCaseInsensitive = true)
                let dict = JsonSerializer.Deserialize<Dictionary<string, obj>>(json, options)
                
                let lastCheck = 
                    match dict.TryGetValue("last_check") with
                    | true, (:? string as s) when not(String.IsNullOrEmpty(s)) -> Some s
                    | _ -> None
                    
                let lastBackup = 
                    match dict.TryGetValue("last_backup") with
                    | true, (:? string as s) when not(String.IsNullOrEmpty(s)) -> Some s
                    | _ -> None
                    
                let lastTreeUpdate = 
                    match dict.TryGetValue("last_tree_update") with
                    | true, (:? string as s) when not(String.IsNullOrEmpty(s)) -> Some s
                    | _ -> None
                
                let fileHashes = 
                    match dict.TryGetValue("file_hashes") with
                    | true, (:? Dictionary<string, obj> as hashes) ->
                        hashes
                        |> Seq.choose (fun kvp -> 
                            match kvp.Value with
                            | :? string as hash -> Some(kvp.Key, hash)
                            | _ -> None)
                        |> Map.ofSeq
                    | _ -> Map.empty
                
                { LastCheck = lastCheck; LastBackup = lastBackup; LastTreeUpdate = lastTreeUpdate; FileHashes = fileHashes }
            with _ ->
                logger.Warn("Failed to load state, using default")
                State.empty
        else
            State.empty

    member private this.SaveState(state: State) =
        try
            let dict = Dictionary<string, obj>()
            state.LastCheck |> Option.iter (fun x -> dict.["last_check"] <- x)
            state.LastBackup |> Option.iter (fun x -> dict.["last_backup"] <- x)
            state.LastTreeUpdate |> Option.iter (fun x -> dict.["last_tree_update"] <- x)
            
            let hashes = Dictionary<string, string>()
            state.FileHashes |> Map.iter (fun k v -> hashes.[k] <- v)
            dict.["file_hashes"] <- hashes
            
            let options = JsonSerializerOptions(WriteIndented = true)
            let json = JsonSerializer.Serialize(dict, options)
            File.WriteAllText(stateFile, json)
        with ex ->
            logger.Error($"Failed to save state: {ex.Message}")

    member private this.GetFileHash(filepath: string): string option =
        try
            use stream = File.OpenRead(filepath)
            use md5 = MD5.Create()
            let hash = md5.ComputeHash(stream)
            Some(Convert.ToBase64String(hash))
        with _ ->
            None

    member private this.PythonTreeFallback(maxDepth: int): string =
        let root = WORKSPACE
        let lines = ResizeArray<string>()
        lines.Add(root)
        
        let rec walk (dirPath: string) (prefix: string) (depth: int) =
            if depth > maxDepth then ()
            else
                try
                    let entries = Directory.GetFileSystemEntries(dirPath) |> Array.sort
                    for i = 0 to entries.Length - 1 do
                        let entry = entries.[i]
                        let name = Path.GetFileName(entry)
                        let connector = if i = entries.Length - 1 then "└── " else "├── "
                        lines.Add(prefix + connector + name)
                        if Directory.Exists(entry) && not(File.GetAttributes(entry).HasFlag(FileAttributes.ReparsePoint)) then
                            let extension = if i = entries.Length - 1 then "    " else "│   "
                            walk entry (prefix + extension) (depth + 1)
                with _ -> ()
        
        walk root "" 1
        String.Join("\n", lines.ToArray()) + "\n"

    member private this.RunTreeCommand(): string option =
        try
            let startInfo = ProcessStartInfo("tree", $"-a -L 8 \"{WORKSPACE}\"")
            startInfo.UseShellExecute <- false
            startInfo.RedirectStandardOutput <- true
            startInfo.RedirectStandardError <- true
            startInfo.CreateNoWindow <- true
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            let outputTask = proc.StandardOutput.ReadToEndAsync()
            let errorTask = proc.StandardError.ReadToEndAsync()
            
            if proc.WaitForExit(60000) && proc.ExitCode = 0 then
                logger.Info("tree -a -L 8 executed successfully")
                Some(outputTask.Result)
            else
                logger.Warn($"tree command failed: {errorTask.Result.Trim()} - using Python fallback")
                Some(this.PythonTreeFallback(8))
        with :? FileNotFoundException ->
            logger.Warn("tree binary not installed - using Python fallback")
            Some(this.PythonTreeFallback(8))
        | ex ->
            logger.Error($"tree command exception: {ex.Message}")
            None

    member private this.UpdateTreeFile(treeOutput: string): bool =
        if String.IsNullOrEmpty(treeOutput) then
            false
        else
            let treeFile = Path.Combine(IMPORTANT_DIR, "openclaw-tree.txt")
            let header = $"""# OpenClaw Workspace Tree
# Generated: {DateTime.Now:o}
# Command: tree -a -L 8 {WORKSPACE}
# This file is automatically updated by db-maintainer

"""
            try
                File.WriteAllText(treeFile, header + treeOutput)
                logger.Info($"openclaw-tree.txt updated: {treeFile}")
                true
            with ex ->
                logger.Error($"Error writing openclaw-tree.txt: {ex.Message}")
                false

    member private this.ScanDocumentations(): (string * string * DateTime) list =
        let docs = ResizeArray<string * string * DateTime>()
        
        let patterns = ["*.md"; "**/*.md"]
        for pattern in patterns do
            try
                let searchOption = if pattern.Contains("**") then SearchOption.AllDirectories else SearchOption.TopDirectoryOnly
                for file in Directory.GetFiles(WORKSPACE, "*.md", searchOption) do
                    let relativePath = file.Replace(WORKSPACE, "").TrimStart('/', '\\')
                    if not(relativePath.Contains("db/backups")) && not(relativePath.Contains("node_modules")) then
                        try
                            let fileInfo = FileInfo(file)
                            match this.GetFileHash(file) with
                            | Some hash -> docs.Add(relativePath, hash, fileInfo.LastWriteTime)
                            | None -> ()
                        with _ -> ()
            with _ -> ()
        
        List.ofSeq docs

    member private this.CheckForChanges(): string list * Map<string, string> =
        let state = this.LoadState()
        let currentDocs = this.ScanDocumentations()
        
        let changes = ResizeArray<string>()
        let currentHashes = 
            currentDocs
            |> List.map (fun (path, hash, _) -> (path, hash))
            |> Map.ofList
        
        // Prüfe auf neue/geänderte Dateien
        for (path, hash, _) in currentDocs do
            match Map.tryFind path state.FileHashes with
            | None -> changes.Add($"NEW: {path}")
            | Some oldHash when oldHash <> hash -> changes.Add($"CHANGED: {path}")
            | _ -> ()
        
        // Prüfe auf gelöschte Dateien
        for oldPath in Map.keys state.FileHashes do
            if not(Map.containsKey oldPath currentHashes) then
                changes.Add($"DELETED: {oldPath}")
        
        List.ofSeq changes, currentHashes

    member private this.UpdateDatabases(): bool =
        try
            let scriptPath = Path.Combine(WORKSPACE, "scripts", "update_docs_db.py")
            let startInfo = ProcessStartInfo("python3", $"\"{scriptPath}\"")
            startInfo.UseShellExecute <- false
            startInfo.RedirectStandardOutput <- true
            startInfo.RedirectStandardError <- true
            startInfo.CreateNoWindow <- true
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            let outputTask = proc.StandardOutput.ReadToEndAsync()
            let errorTask = proc.StandardError.ReadToEndAsync()
            
            if proc.WaitForExit(60000) && proc.ExitCode = 0 then
                logger.Info("docs.db updated")
                true
            else
                logger.Error($"DB update failed: {errorTask.Result}")
                false
        with ex ->
            logger.Error($"DB update exception: {ex.Message}")
            false

    member private this.UpdateTreeDbV2(): bool =
        try
            let scriptPath = Path.Combine(WORKSPACE, "scripts", "tree_indexer_v2.py")
            let startInfo = ProcessStartInfo("python3", $"\"{scriptPath}\"")
            startInfo.UseShellExecute <- false
            startInfo.RedirectStandardOutput <- true
            startInfo.RedirectStandardError <- true
            startInfo.CreateNoWindow <- true
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            let outputTask = proc.StandardOutput.ReadToEndAsync()
            let errorTask = proc.StandardError.ReadToEndAsync()
            
            if proc.WaitForExit(120000) && proc.ExitCode = 0 then
                logger.Info("tree.db v2 updated")
                true
            else
                logger.Error($"Tree-DB v2 failed: {errorTask.Result}")
                false
        with ex ->
            logger.Error($"Tree-DB v2 exception: {ex.Message}")
            false

    member private this.CreateBackup(): string =
        let timestamp = DateTime.Now.ToString("yyyy-MM-dd_HH-mm")
        
        for dbName in ["docs.db"; "tree.db"] do
            let source = Path.Combine(DB_DIR, dbName)
            if File.Exists(source) then
                let backupName = $"{timestamp}_{dbName}.bak"
                let backupPath = Path.Combine(BACKUP_DIR, backupName)
                File.Copy(source, backupPath, true)
                logger.Info($"Backup created: {backupName}")
        
        timestamp

    member private this.CleanupOldBackups() =
        let cutoff = DateTime.Now.AddDays(-float retentionDays)
        let mutable deleted = 0
        
        for dbName in ["docs.db"; "tree.db"] do
            let pattern = $"*_{dbName}.bak"
            for backup in Directory.GetFiles(BACKUP_DIR, pattern) do
                try
                    let fileName = Path.GetFileName(backup)
                    let parts = fileName.Split('_')
                    if parts.Length >= 2 then
                        let dateStr = parts.[0]
                        let timeStr = parts.[1].Replace(".bak", "")
                        let backupTime = DateTime.ParseExact($"{dateStr}_{timeStr}", "yyyy-MM-dd_HH-mm", null)
                        
                        if backupTime < cutoff then
                            File.Delete(backup)
                            deleted <- deleted + 1
                            logger.Info($"Deleted old backup: {fileName}")
                with _ ->
                    logger.Warn($"Could not parse backup date: {Path.GetFileName(backup)}")
        
        if deleted = 0 then
            logger.Info("No old backups to delete")
        else
            logger.Info($"{deleted} old backups deleted (< 3 days)")

    member this.RunCycle() =
        logger.Info("=".PadRight(60, '='))
        logger.Info("DB MAINTAINER CYCLE START")
        logger.Info("=".PadRight(60, '='))
        
        let mutable state = this.LoadState()
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        logger.Info("Executing tree -a -L 8...")
        match this.RunTreeCommand() with
        | Some treeOutput ->
            if this.UpdateTreeFile(treeOutput) then
                state <- { state with LastTreeUpdate = Some(DateTime.Now.ToString("o")) }
        | None -> ()
        
        // 2. tree.db aktualisieren (intern v2)
        logger.Info("Updating tree.db v2...")
        this.UpdateTreeDbV2() |> ignore
        
        // 3. Änderungen prüfen
        logger.Info("Checking for documentation changes...")
        let changes, currentHashes = this.CheckForChanges()
        
        if not(List.isEmpty changes) then
            logger.Info($"{changes.Length} changes found:")
            changes |> List.take (min 10 changes.Length) |> List.iter (fun change -> logger.Info($"  - {change}"))
            if changes.Length > 10 then
                logger.Info($"  ... and {changes.Length - 10} more")
            
            // 4. docs.db aktualisieren
            logger.Info("Updating docs.db...")
            if this.UpdateDatabases() then
                state <- { state with 
                    LastCheck = Some(DateTime.Now.ToString("o"))
                    FileHashes = currentHashes
                }
        else
            logger.Info("No documentation changes found")
        
        // 5. Prüfe ob Backup fällig (stündlich)
        let doBackup = 
            match state.LastBackup with
            | Some lastBackupStr ->
                match DateTime.TryParse(lastBackupStr) with
                | (true, lastBackupTime) -> DateTime.Now - lastBackupTime >= TimeSpan.FromHours(1.0)
                | _ -> true
            | None -> true
        
        if doBackup then
            logger.Info("Creating hourly backup...")
            let timestamp = this.CreateBackup()
            state <- { state with LastBackup = Some(DateTime.Now.ToString("o")) }
            
            // 6. Alte Backups aufräumen (3 Tage Retention)
            logger.Info("Cleaning up old backups (3 day retention)...")
            this.CleanupOldBackups()
        else
            logger.Info("Backup not needed (last < 1h)")
        
        this.SaveState(state)
        
        logger.Info("=".PadRight(60, '='))
        logger.Info("DB MAINTAINER CYCLE END")
        logger.Info("=".PadRight(60, '='))

let main() =
    let maintainer = DatabaseMaintainer()
    try
        maintainer.RunCycle()
        0
    with ex ->
        maintainer.logger.Error($"CRITICAL ERROR: {ex.Message}")
        1

[<EntryPoint>]
let entryPoint argv =
    main()
