// abstraction-provenance: {"artifact_sha256": "b8addd307ac946329d0f2886dc9c8ada652f54b93ade4de4dc1ac316101a64c4", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "fsharp"}
// log_collector.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module LogCollector

open System
open System.IO
open System.Diagnostics
open System.Data.SQLite
open Newtonsoft.Json

let workspace = Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".openclaw", "workspace")
let dbPath = Path.Combine(workspace, "db", "logs.db")
let logDir = Path.Combine(workspace, "logs", "log-collector")

Directory.CreateDirectory(logDir) |> ignore

type Logger() =
    let logFile = 
        let today = DateTime.Now.ToString("yyyy-MM-dd")
        Path.Combine(logDir, sprintf "%s.log" today)
    
    member this.Log(level: string, msg: string) =
        let ts = DateTime.Now.ToString("o")
        let line = sprintf "[%s] [%s] %s" ts level msg
        printfn "%s" line
        File.AppendAllText(logFile, line + "\n")
    
    member this.Info(msg: string) = this.Log("INFO", msg)
    member this.Error(msg: string) = this.Log("ERROR", msg)

type LogCollector() =
    let logger = Logger()
    let mutable conn: SQLiteConnection option = None
    
    member private this.ConnectDb() =
        let connection = new SQLiteConnection(sprintf "Data Source=%s;Version=3;" dbPath)
        connection.Open()
        conn <- Some connection
        // Schema initialisieren falls nicht existiert
        this.InitSchema()
        connection
    
    member private this.InitSchema() =
        match conn with
        | Some c ->
            use cmd = new SQLiteCommand("SELECT name FROM sqlite_master WHERE type='table'", c)
            use reader = cmd.ExecuteReader()
            if not reader.HasRows then
                let schemaPath = Path.Combine(workspace, "db", "logs.db.schema.sql")
                if File.Exists(schemaPath) then
                    let schemaSql = File.ReadAllText(schemaPath)
                    use cmd2 = new SQLiteCommand(schemaSql, c)
                    cmd2.ExecuteNonQuery() |> ignore
        | None -> ()
    
    member private this.GetNodes() =
        match conn with
        | Some c ->
            use cmd = new SQLiteCommand("SELECT * FROM nodes", c)
            use reader = cmd.ExecuteReader()
            let nodes = ResizeArray<obj>()
            while reader.Read() do
                let node = dict [
                    "node_id", box (reader.["node_id"])
                    "vpn_ip", box (reader.["vpn_ip"])
                    "tailscale_ip", box (reader.["tailscale_ip"])
                    "wireguard_ip", box (reader.["wireguard_ip"])
                ]
                nodes.Add(node)
            nodes |> Seq.cast<obj> |> List.ofSeq
        | None -> []
    
    member private this.CheckVpn(ip: string) =
        try
            let psi = ProcessStartInfo("ping", sprintf "-c 1 -W 3 %s" ip)
            psi.UseShellExecute <- false
            psi.RedirectStandardOutput <- true
            psi.RedirectStandardError <- true
            let proc = Process.Start(psi)
            proc.WaitForExit(10000)
            proc.ExitCode = 0
        with _ -> false
    
    member private this.SshConnectAndCollect(node: obj) =
        let nodeDict = node :?> Map<string, obj>
        let nodeId = nodeDict.["node_id"] :?> string
        let vpnIp = 
            match nodeDict.TryGetValue("vpn_ip") with
            | (true, v) -> Some(v :?> string)
            | _ -> 
                match nodeDict.TryGetValue("tailscale_ip") with
                | (true, v) -> Some(v :?> string)
                | _ -> 
                    match nodeDict.TryGetValue("wireguard_ip") with
                    | (true, v) -> Some(v :?> string)
                    | _ -> None
        
        match vpnIp with
        | None ->
            logger.Error(sprintf "%s: Keine VPN-IP konfiguriert" nodeId)
            None
        | Some ip ->
            // 1. VPN-Check
            logger.Info(sprintf "%s: Prüfe VPN %s..." nodeId ip)
            if not (this.CheckVpn(ip)) then
                logger.Error(sprintf "%s: VPN nicht erreichbar" nodeId)
                this.LogSshConnection(nodeId, "tailscale", false, "VPN unreachable")
                None
            else
                // 2. SSH-Verbindung
                logger.Info(sprintf "%s: Verbinde via SSH..." nodeId)
                try
                    let logCommands = [
                        "journalctl -n 500 --no-pager"
                        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'"
                        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
                    ]
                    
                    let logsCollected = ResizeArray<obj>()
                    for cmd in logCommands do
                        let psi = ProcessStartInfo("ssh", sprintf "-o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw@%s %s" ip cmd)
                        psi.UseShellExecute <- false
                        psi.RedirectStandardOutput <- true
                        psi.RedirectStandardError <- true
                        let proc = Process.Start(psi)
                        if proc.WaitForExit(30000) then
                            if proc.ExitCode = 0 then
                                logsCollected.Add(dict [
                                    "command", box cmd
                                    "output", box (proc.StandardOutput.ReadToEnd())
                                    "timestamp", box (DateTime.Now.ToString("o"))
                                ])
                    
                    // Erfolg loggen
                    this.LogSshConnection(nodeId, "ssh", true, null)
                    
                    // In DB speichern
                    this.InsertLogs(nodeId, logsCollected |> Seq.cast<obj> |> List.ofSeq)
                    
                    Some(logsCollected.Count)
                    
                with
                | :? TimeoutException ->
                    logger.Error(sprintf "%s: SSH Timeout" nodeId)
                    this.LogSshConnection(nodeId, "ssh", false, "Timeout")
                    None
                | :? FileNotFoundException ->
                    logger.Error(sprintf "%s: SSH nicht verfügbar" nodeId)
                    None
                | ex ->
                    logger.Error(sprintf "%s: SSH Fehler: %s" nodeId ex.Message)
                    this.LogSshConnection(nodeId, "ssh", false, ex.Message)
                    None
    
    member private this.LogSshConnection(nodeId: string, connType: string, success: bool, error: string) =
        match conn with
        | Some c ->
            use cmd = new SQLiteCommand("""
                INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
                VALUES (@node_id, @connection_type, @success, @error_message)
            """, c)
            cmd.Parameters.AddWithValue("@node_id", nodeId) |> ignore
            cmd.Parameters.AddWithValue("@connection_type", connType) |> ignore
            cmd.Parameters.AddWithValue("@success", success) |> ignore
            cmd.Parameters.AddWithValue("@error_message", (if error = null then box DBNull.Value else box error)) |> ignore
            cmd.ExecuteNonQuery() |> ignore
        | None -> ()
    
    member private this.InsertLogs(nodeId: string, logs: obj list) =
        match conn with
        | Some c ->
            let retention = DateTime.Now.AddDays(30.0).ToString("o")
            
            for logEntry in logs do
                let logDict = logEntry :?> Map<string, obj>
                let command = logDict.["command"] :?> string
                let output = logDict.["output"] :?> string
                use cmd = new SQLiteCommand("""
                    INSERT INTO logs (node_id, log_type, source, content, severity, 
                                    collected_by, collection_method, retention_until)
                    VALUES (@node_id, 'system', @source, @content, 'info', @collected_by, 'ssh', @retention_until)
                """, c)
                cmd.Parameters.AddWithValue("@node_id", nodeId) |> ignore
                cmd.Parameters.AddWithValue("@source", (if command.Length > 50 then command.Substring(0, 50) else command)) |> ignore
                cmd.Parameters.AddWithValue("@content", (if output.Length > 10000 then output.Substring(0, 10000) else output)) |> ignore
                cmd.Parameters.AddWithValue("@collected_by", "node1") |> ignore
                cmd.Parameters.AddWithValue("@retention_until", retention) |> ignore
                cmd.ExecuteNonQuery() |> ignore
            
            logger.Info(sprintf "%s: %d Log-Einträge gespeichert" nodeId logs.Length)
        | None -> ()
    
    member private this.CleanupRetention() =
        match conn with
        | Some c ->
            use cmd = new SQLiteCommand("""
                DELETE FROM logs WHERE retention_until < datetime('now')
            """, c)
            let deleted = cmd.ExecuteNonQuery()
            logger.Info(sprintf "Retention-Cleanup: %d alte Logs gelöscht" deleted)
            deleted
        | None -> 0
    
    member this.RunCollectionCycle() =
        logger.Info("=" + String.replicate 59 "=")
        logger.Info("LOG COLLECTOR CYCLE START")
        logger.Info("=" + String.replicate 59 "=")
        
        let connection = this.ConnectDb()
        
        // 1. Nodes holen
        let nodes = this.GetNodes()
        logger.Info(sprintf "Gefunden: %d Nodes" nodes.Length)
        
        // 2. Collection-Run starten
        let runId = 
            match conn with
            | Some c ->
                use cmd = new SQLiteCommand("""
                    INSERT INTO collection_runs (started_at, nodes_total)
                    VALUES (CURRENT_TIMESTAMP, @nodes_total)
                """, c)
                cmd.Parameters.AddWithValue("@nodes_total", nodes.Length) |> ignore
                cmd.ExecuteNonQuery() |> ignore
                // In SQLite gibt es kein lastrowid, daher verwenden wir eine separate Abfrage
                use cmd2 = new SQLiteCommand("SELECT last_insert_rowid()", c)
                int64 (cmd2.ExecuteScalar())
            | None -> 0L
        
        // 3. Für jeden Node sammeln
        let mutable successCount = 0
        let mutable failedCount = 0
        let mutable totalLogs = 0
        
        for node in nodes do
            let nodeDict = node :?> Map<string, obj>
            let nodeId = nodeDict.["node_id"] :?> string
            if nodeId = "node1" then
                // Lokale Logs (Gateway selbst)
                logger.Info("node1: Lokale Collection (Gateway)")
                successCount <- successCount + 1
            else
                // Remote-Node abfragen
                match this.SshConnectAndCollect(node) with
                | Some result ->
                    successCount <- successCount + 1
                    totalLogs <- totalLogs + result
                | None -> failedCount <- failedCount + 1
        
        // 4. Run abschließen
        match conn with
        | Some c ->
            use cmd = new SQLiteCommand("""
                UPDATE collection_runs SET
                    finished_at = CURRENT_TIMESTAMP,
                    nodes_success = @nodes_success,
                    nodes_failed = @nodes_failed,
                    logs_collected = @logs_collected
                WHERE run_id = @run_id
            """, c)
            cmd.Parameters.AddWithValue("@nodes_success", successCount) |> ignore
            cmd.Parameters.AddWithValue("@nodes_failed", failedCount) |> ignore
            cmd.Parameters.AddWithValue("@logs_collected", totalLogs) |> ignore
            cmd.Parameters.AddWithValue("@run_id", runId) |> ignore
            cmd.ExecuteNonQuery() |> ignore
        | None -> ()
        
        // 5. Retention-Cleanup
        logger.Info("Retention-Cleanup (30 Tage)...")
        this.CleanupRetention() |> ignore
        
        logger.Info("=" + String.replicate 59 "=")
        logger.Info(sprintf "SUMMARY: %d OK, %d Failed, %d Logs" successCount failedCount totalLogs)
        logger.Info("=" + String.replicate 59 "=")

let main() =
    printfn "%s" ("=" + String.replicate 59 "=")
    printfn "LOG COLLECTOR"
    printfn "%s" ("=" + String.replicate 59 "=")
    
    let collector = LogCollector()
    
    try
        collector.RunCollectionCycle()
    with ex ->
        printfn "CRITICAL ERROR: %s" ex.Message
        printfn "%s" ex.StackTrace
        exit 1

[<EntryPoint>]
let entryPoint argv =
    main()
    0
