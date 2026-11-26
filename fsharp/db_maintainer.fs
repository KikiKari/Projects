// abstraction-provenance: {"artifact_sha256": "2864c36a5b10f96eac01755a7ca3c56088ccdc8ab1a0575e11fbd4143bc564e3", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "fsharp"}
// db_maintainer.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module DbMaintainer

open System
open System.IO
open System.Diagnostics
open System.Security.Cryptography
open System.Text
open Newtonsoft.Json
open Newtonsoft.Json.Linq

// Konstanten
let WORKSPACE = Path.Combine("/home/openclaw/.openclaw/workspace")
let DB_DIR = Path.Combine(WORKSPACE, "db")
let BACKUP_DIR = Path.Combine(DB_DIR, "backups")
let LOG_DIR = Path.Combine(WORKSPACE, "logs", "db-maintainer")
let IMPORTANT_DIR = Path.Combine(WORKSPACE, "important")

// Verzeichnisse erstellen
Directory.CreateDirectory(BACKUP_DIR) |> ignore
Directory.CreateDirectory(LOG_DIR) |> ignore

type Logger() =
    let logFile = 
        let today = DateTime.Now.ToString("yyyy-MM-dd")
        Path.Combine(LOG_DIR, sprintf "%s.log" today)
    
    member this.Log(level: string, message: string) =
        let timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
        let line = sprintf "[%s] [%s] %s" timestamp level message
        printfn "%s" line
        use writer = new StreamWriter(logFile, true)
        writer.WriteLine(line)
    
    member this.Info(msg) = this.Log("INFO", msg)
    member this.Warn(msg) = this.Log("WARN", msg)
    member this.Error(msg) = this.Log("ERROR", msg)

type State = {
    last_check: string option
    last_backup: string option
    last_tree_update: string option
    file_hashes: Map<string, string>
}

type DatabaseMaintainer() =
    let logger = Logger()
    let stateFile = Path.Combine(DB_DIR, "maintainer_state.json")
    let retentionDays = 3 // 3 Tage Backup-Aufbewahrung
    
    member private this.LoadState() =
        if File.Exists(stateFile) then
            let json = File.ReadAllText(stateFile)
            let stateObj = JsonConvert.DeserializeObject<JObject>(json)
            {
                last_check = stateObj.["last_check"] |> Option.ofObj |> Option.map string
                last_backup = stateObj.["last_backup"] |> Option.ofObj |> Option.map string
                last_tree_update = stateObj.["last_tree_update"] |> Option.ofObj |> Option.map string
                file_hashes = 
                    match stateObj.["file_hashes"] with
                    | null -> Map.empty
                    | hashes -> 
                        hashes.Children()
                        |> Seq.cast<JProperty>
                        |> Seq.map (fun prop -> prop.Name, string prop.Value)
                        |> Map.ofSeq
            }
        else
            {
                last_check = None
                last_backup = None
                last_tree_update = None
                file_hashes = Map.empty
            }
    
    member private this.SaveState(state: State) =
        let stateObj = JObject()
        state.last_check |> Option.iter (fun x -> stateObj.["last_check"] <- JValue(x))
        state.last_backup |> Option.iter (fun x -> stateObj.["last_backup"] <- JValue(x))
        state.last_tree_update |> Option.iter (fun x -> stateObj.["last_tree_update"] <- JValue(x))
        
        let hashesObj = JObject()
        state.file_hashes |> Map.iter (fun key value -> hashesObj.[key] <- JValue(value))
        stateObj.["file_hashes"] <- hashesObj
        
        let json = JsonConvert.SerializeObject(stateObj, Formatting.Indented)
        File.WriteAllText(stateFile, json)
    
    member private this.GetFileHash(filepath: string) =
        try
            use stream = File.OpenRead(filepath)
            use md5 = MD5.Create()
            let hash = md5.ComputeHash(stream)
            BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant()
        with
        | _ -> null
    
    member private this.RunTreeCommand() =
        try
            let startInfo = ProcessStartInfo(
                FileName = "tree",
                Arguments = sprintf "-a -L 8 \"%s\"" WORKSPACE,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            )
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            if proc.WaitForExit(60000) && proc.ExitCode = 0 then
                logger.Info("tree -a -L 8 erfolgreich ausgeführt")
                Some(proc.StandardOutput.ReadToEnd())
            else
                logger.Error(sprintf "tree command fehlgeschlagen: %s" (proc.StandardError.ReadToEnd()))
                None
        with
        | ex -> 
            logger.Error(sprintf "tree command Exception: %s" ex.Message)
            None
    
    member private this.UpdateTreeFile(treeOutput: string) =
        if String.IsNullOrEmpty(treeOutput) then
            false
        else
            let treeFile = Path.Combine(IMPORTANT_DIR, "openclaw-tree.txt")
            
            // Header mit Timestamp
            let header = sprintf "# OpenClaw Workspace Tree\n# Generiert: %s\n# Befehl: tree -a -L 8 %s\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n" (DateTime.Now.ToString("o")) WORKSPACE
            
            try
                File.WriteAllText(treeFile, header + treeOutput)
                logger.Info(sprintf "openclaw-tree.txt aktualisiert: %s" treeFile)
                true
            with
            | ex -> 
                logger.Error(sprintf "Fehler beim Schreiben von openclaw-tree.txt: %s" ex.Message)
                false
    
    member private this.ScanDocumentations() =
        let docs = ResizeArray<obj>()
        
        let patterns = ["*.md"; "**/*.md"]
        for pattern in patterns do
            let files = Directory.GetFiles(WORKSPACE, pattern, SearchOption.AllDirectories)
            for mdFile in files do
                let fileInfo = FileInfo(mdFile)
                if fileInfo.Exists && not fileInfo.Attributes.HasFlag(FileAttributes.ReparsePoint) then
                    let relativePath = mdFile.Replace(WORKSPACE, "").TrimStart('/', '\\')
                    if not (relativePath.Contains("db/backups")) && not (relativePath.Contains("node_modules")) then
                        docs.Add((
                            relativePath,
                            this.GetFileHash(mdFile),
                            fileInfo.LastWriteTimeUtc.ToFileTimeUtc()
                        ))
        
        docs
    
    member private this.CheckForChanges() =
        let state = this.LoadState()
        let currentDocs = this.ScanDocumentations()
        
        let changes = ResizeArray<string>()
        let currentHashes = Map.empty
        
        for (path: string, hash: string, _) in currentDocs do
            let currentHashes = Map.add path hash currentHashes
            
            if not (Map.containsKey path state.file_hashes) then
                changes.Add(sprintf "NEW: %s" path)
            elif state.file_hashes.[path] <> hash then
                changes.Add(sprintf "CHANGED: %s" path)
        
        // Prüfe auf gelöschte Dateien
        for oldPath in Map.keys state.file_hashes do
            if not (Map.containsKey oldPath currentHashes) then
                changes.Add(sprintf "DELETED: %s" oldPath)
        
        (changes, currentHashes)
    
    member private this.UpdateDatabases() =
        try
            let startInfo = ProcessStartInfo(
                FileName = "python3",
                Arguments = sprintf "\"%s\"" (Path.Combine(WORKSPACE, "scripts", "update_docs_db.py")),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            )
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            if proc.WaitForExit(60000) && proc.ExitCode = 0 then
                logger.Info("docs.db aktualisiert")
                true
            else
                logger.Error(sprintf "DB-Update fehlgeschlagen: %s" (proc.StandardError.ReadToEnd()))
                false
        with
        | ex -> 
            logger.Error(sprintf "DB-Update Exception: %s" ex.Message)
            false
    
    member private this.UpdateTreeDbV2() =
        try
            let startInfo = ProcessStartInfo(
                FileName = "python3",
                Arguments = sprintf "\"%s\"" (Path.Combine(WORKSPACE, "scripts", "tree_indexer_v2.py")),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            )
            
            use proc = new Process()
            proc.StartInfo <- startInfo
            proc.Start() |> ignore
            
            if proc.WaitForExit(120000) && proc.ExitCode = 0 then
                logger.Info("tree.db v2 aktualisiert")
                true
            else
                logger.Error(sprintf "Tree-DB v2 fehlgeschlagen: %s" (proc.StandardError.ReadToEnd()))
                false
        with
        | ex -> 
            logger.Error(sprintf "Tree-DB v2 Exception: %s" ex.Message)
            false
    
    member private this.CreateBackup() =
        let timestamp = DateTime.Now.ToString("yyyy-MM-dd_HH-mm")
        
        for dbName in ["docs.db"; "tree.db"] do
            let source = Path.Combine(DB_DIR, dbName)
            if File.Exists(source) then
                let backupName = sprintf "%s_%s.bak" timestamp dbName
                let backupPath = Path.Combine(BACKUP_DIR, backupName)
                File.Copy(source, backupPath, true)
                logger.Info(sprintf "Backup erstellt: %s" backupName)
        
        timestamp
    
    member private this.CleanupOldBackups() =
        let cutoff = DateTime.Now.AddDays(float -retentionDays)
        let mutable deleted = 0
        
        for dbName in ["docs.db"; "tree.db"] do
            let backups = Directory.GetFiles(BACKUP_DIR, sprintf "*_%s.bak" dbName)
            
            for backup in backups do
                try
                    let fileName = Path.GetFileName(backup)
                    let parts = fileName.Split('_')
                    let dateStr = parts.[0]
                    let timeStr = parts.[1]
                    let backupTime = DateTime.ParseExact(sprintf "%s_%s" dateStr timeStr, "yyyy-MM-dd_HH-mm", null)
                    
                    if backupTime < cutoff then
                        File.Delete(backup)
                        deleted <- deleted + 1
                        logger.Info(sprintf "Altes Backup gelöscht: %s" fileName)
                with
                | _ -> logger.Warn(sprintf "Konnte Backup-Datum nicht parsen: %s" (Path.GetFileName(backup)))
        
        if deleted = 0 then
            logger.Info("Keine alten Backups zum Löschen")
        else
            logger.Info(sprintf "%d alte Backups gelöscht (< 3 Tage)" deleted)
    
    member this.RunCycle() =
        logger.Info("============================================================")
        logger.Info("DB MAINTAINER CYCLE START")
        logger.Info("============================================================")
        
        let mutable state = this.LoadState()
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        logger.Info("Führe tree -a -L 8 aus...")
        match this.RunTreeCommand() with
        | Some treeOutput ->
            if this.UpdateTreeFile(treeOutput) then
                state <- { state with last_tree_update = Some(DateTime.Now.ToString("o")) }
        | None -> ()
        
        // 2. tree.db aktualisieren (intern v2)
        logger.Info("Aktualisiere tree.db v2...")
        this.UpdateTreeDbV2() |> ignore
        
        // 3. Änderungen prüfen
        logger.Info("Prüfe auf Dokumentations-Änderungen...")
        let changes, currentHashes = this.CheckForChanges()
        
        if changes.Count > 0 then
            logger.Info(sprintf "%d Änderungen gefunden:" changes.Count)
            let displayCount = min 10 changes.Count
            for i in 0 .. displayCount - 1 do
                logger.Info(sprintf "  - %s" changes.[i])
            if changes.Count > 10 then
                logger.Info(sprintf "  ... und %d weitere" (changes.Count - 10))
            
            // 4. docs.db aktualisieren
            logger.Info("Aktualisiere docs.db...")
            if this.UpdateDatabases() then
                state <- { 
                    state with 
                        last_check = Some(DateTime.Now.ToString("o"))
                        file_hashes = currentHashes
                }
        else
            logger.Info("Keine Dokumentations-Änderungen gefunden")
        
        // 5. Prüfe ob Backup fällig (stündlich)
        let doBackup = 
            match state.last_backup with
            | Some lastBackupStr ->
                match DateTime.TryParse(lastBackupStr) with
                | (true, lastBackupTime) -> DateTime.Now - lastBackupTime >= TimeSpan.FromHours(1.0)
                | _ -> true
            | None -> true
        
        if doBackup then
            logger.Info("Erstelle stündliches Backup...")
            let timestamp = this.CreateBackup()
            state <- { state with last_backup = Some(DateTime.Now.ToString("o")) }
            
            // 6. Alte Backups aufräumen (3 Tage Retention)
            logger.Info("Räume alte Backups auf (3 Tage Retention)...")
            this.CleanupOldBackups()
        else
            logger.Info("Backup nicht nötig (letztes < 1h)")
        
        this.SaveState(state)
        
        logger.Info("============================================================")
        logger.Info("DB MAINTAINER CYCLE END")
        logger.Info("============================================================")

let main() =
    let maintainer = DatabaseMaintainer()
    
    try
        maintainer.RunCycle()
    with
    | ex -> 
        maintainer.logger.Error(sprintf "CRITICAL ERROR: %s" ex.Message)
        exit 1

[<EntryPoint>]
let entryPoint argv =
    main()
    0
