// abstraction-provenance: {"artifact_sha256": "d10f8337531b195ba3947db9f05f4b04c8644e4765271cb13daa50fcfc561546", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "fsharp"}
// node_health.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module NodeHealthMonitor

open System
open System.IO
open System.Diagnostics
open System.Collections.Generic
open Newtonsoft.Json

// Konfiguration
let WORKSPACE = Path.Combine("/home/openclaw/.openclaw/workspace")
let HEALTH_DB = Path.Combine(WORKSPACE, "db/health.db")
let LOG_FILE = Path.Combine(WORKSPACE, "logs/node-health.log")

// Node-Definitionen
type NodeConfig = {
    name: string
    host: string
    user: string
    critical: bool option
    ssh_key: string option
    ssh_opts: string option
    port: int option
    disk_warning: int option
    optional: bool option
}

let NODES = dict [
    ("node1", { 
        name = "Node 1"
        host = "localhost"
        user = "openclaw"
        critical = Some true
        ssh_key = None
        ssh_opts = None
        port = None
        disk_warning = None
        optional = None
    })
    ("node2", {
        name = "Node 2"
        host = "10.10.0.2"
        user = "root"
        critical = None
        ssh_key = Some "~/.ssh/id_rsa"
        ssh_opts = Some "-o ConnectTimeout=10 -o BatchMode=yes"
        port = None
        disk_warning = None
        optional = None
    })
    ("node3", {
        name = "Node 3"
        host = "localhost"
        user = "root"
        critical = None
        ssh_key = None
        ssh_opts = Some "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes"
        port = Some 18794
        disk_warning = Some 85
        optional = None
    })
    ("node5", {
        name = "Redmi"
        host = "192.168.1.x"
        user = "openclaw"
        critical = None
        ssh_key = None
        ssh_opts = None
        port = None
        disk_warning = None
        optional = Some true
    })
]

type Metrics = {
    timestamp: string
    available: bool
    cpu: float option
    ram: float option
    disk: int option
    load: float option
    gateway_status: string option
}

type Alert = {
    level: string
    message: string
}

let log (message: string) (level: string) =
    let timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
    let entry = sprintf "[%s] [%s] %s" timestamp level message
    printfn "%s" entry
    let logDir = Path.GetDirectoryName(LOG_FILE)
    Directory.CreateDirectory(logDir) |> ignore
    File.AppendAllText(LOG_FILE, entry + "\n")

let checkPing (host: string) (timeout: int) =
    try
        let psi = ProcessStartInfo("ping", sprintf "-c 1 -W %d %s" timeout host)
        psi.UseShellExecute <- false
        psi.RedirectStandardOutput <- true
        psi.RedirectStandardError <- true
        let proc = Process.Start(psi)
        proc.WaitForExit()
        proc.ExitCode = 0
    with
    | _ -> false

let checkSsh (nodeConfig: NodeConfig) =
    try
        let host = nodeConfig.host
        let user = defaultArg (Some nodeConfig.user) "root"
        let sshOpts = defaultArg nodeConfig.ssh_opts ""
        let port = nodeConfig.port
        
        let cmdParts = ["ssh"]
        let cmdParts = if not (String.IsNullOrEmpty(sshOpts)) then cmdParts @ (sshOpts.Split(' ') |> List.ofArray) else cmdParts
        let cmdParts = match port with Some p -> cmdParts @ ["-p"; string p] | None -> cmdParts
        let cmdParts = cmdParts @ ["-o"; "ConnectTimeout=10"; "-o"; "BatchMode=yes"; sprintf "%s@%s" user host; "echo"; "\"OK\""]
        
        let psi = ProcessStartInfo("ssh")
        psi.Arguments <- String.Join(" ", cmdParts |> List.skip 1)
        psi.UseShellExecute <- false
        psi.RedirectStandardOutput <- true
        psi.RedirectStandardError <- true
        let proc = Process.Start(psi)
        proc.WaitForExit()
        proc.ExitCode = 0 && (proc.StandardOutput.ReadToEnd().Contains("OK"))
    with
    | _ -> false

let getNodeMetrics (nodeConfig: NodeConfig) =
    let host = nodeConfig.host
    let user = defaultArg (Some nodeConfig.user) "root"
    
    let metrics = {
        timestamp = DateTime.Now.ToString("o")
        available = false
        cpu = None
        ram = None
        disk = None
        load = None
        gateway_status = None
    }
    
    let cmd = sprintf """ssh -o ConnectTimeout=10 %s@%s '
        # CPU
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    '""" user host
    
    try
        use proc = new Process()
        proc.StartInfo <- ProcessStartInfo("bash", sprintf "-c \"%s\"" cmd)
        proc.StartInfo.UseShellExecute <- false
        proc.StartInfo.RedirectStandardOutput <- true
        proc.StartInfo.RedirectStandardError <- true
        proc.Start() |> ignore
        proc.WaitForExit(15000) |> ignore
        
        if proc.ExitCode = 0 then
            let mutable resultMetrics = { metrics with available = true }
            let output = proc.StandardOutput.ReadToEnd()
            
            for line in output.Trim().Split('\n') do
                if line.Contains(":") then
                    let parts = line.Split(':')
                    if parts.Length >= 2 then
                        let key = parts.[0].Trim()
                        let value = parts.[1].Trim()
                        match key with
                        | "CPU" -> 
                            if not (String.IsNullOrEmpty(value)) then
                                resultMetrics <- { resultMetrics with cpu = Some(float value) }
                        | "RAM" -> 
                            if not (String.IsNullOrEmpty(value)) then
                                resultMetrics <- { resultMetrics with ram = Some(float value) }
                        | "DISK" -> 
                            if not (String.IsNullOrEmpty(value)) then
                                resultMetrics <- { resultMetrics with disk = Some(int value) }
                        | "LOAD" -> 
                            if not (String.IsNullOrEmpty(value)) then
                                resultMetrics <- { resultMetrics with load = Some(float value) }
                        | "GATEWAY" -> 
                            resultMetrics <- { resultMetrics with gateway_status = Some(value) }
                        | _ -> ()
            
            resultMetrics
        else
            metrics
    with
    | :? TimeoutException ->
        log (sprintf "SSH timeout for %s" nodeConfig.name) "WARN"
        metrics
    | ex ->
        log (sprintf "Error checking %s: %s" nodeConfig.name ex.Message) "ERROR"
        metrics

let checkAlerts (nodeId: string) (nodeConfig: NodeConfig) (metrics: Metrics) =
    let alerts = ResizeArray<Alert>()
    
    // Verfügbarkeit
    if not metrics.available then
        if not (defaultArg nodeConfig.optional false) then
            alerts.Add({ level = "CRITICAL"; message = sprintf "Node %s nicht erreichbar!" nodeConfig.name })
    else
        // CPU
        match metrics.cpu with
        | Some cpu when cpu > 90.0 ->
            alerts.Add({ level = "WARNING"; message = sprintf "Node %s: CPU bei %.1f%%" nodeConfig.name cpu })
        | _ -> ()
        
        // RAM
        match metrics.ram with
        | Some ram when ram > 90.0 ->
            alerts.Add({ level = "WARNING"; message = sprintf "Node %s: RAM bei %.1f%%" nodeConfig.name ram })
        | _ -> ()
        
        // Disk
        let diskThreshold = defaultArg nodeConfig.disk_warning 85
        match metrics.disk with
        | Some disk when disk > diskThreshold ->
            let level = if disk > 95 then "CRITICAL" else "WARNING"
            alerts.Add({ level = level; message = sprintf "Node %s: Disk bei %d%%" nodeConfig.name disk })
        | _ -> ()
        
        // Gateway
        match nodeConfig.critical, metrics.gateway_status with
        | Some true, Some status when status = "inactive" ->
            alerts.Add({ level = "CRITICAL"; message = sprintf "Node %s: OpenClaw Gateway nicht aktiv!" nodeConfig.name })
        | _ -> ()
    
    alerts |> List.ofSeq

let sendAlert (alert: Alert) =
    try
        let scriptPath = Path.Combine(WORKSPACE, "skills/channel-status-agent/scripts/channel_status.py")
        let psi = ProcessStartInfo("python3", sprintf "\"%s\" --type alert --message \"%s: %s\"" scriptPath alert.level alert.message)
        psi.UseShellExecute <- false
        psi.RedirectStandardOutput <- true
        psi.RedirectStandardError <- true
        let proc = Process.Start(psi)
        proc.WaitForExit() |> ignore
        log (sprintf "Alert sent: %s" alert.message) "INFO"
    with
    | ex -> log (sprintf "Failed to send alert: %s" ex.Message) "ERROR"

let main argv =
    let args = argv |> Array.toList
    
    let mutable nodeArg = "all"
    let mutable checkArg = "all"
    let mutable sendAlerts = false
    
    let rec parseArgs args =
        match args with
        | "--node" :: value :: rest ->
            nodeArg <- value
            parseArgs rest
        | "--check" :: value :: rest ->
            checkArg <- value
            parseArgs rest
        | "--alert" :: rest ->
            sendAlerts <- true
            parseArgs rest
        | _ :: rest -> parseArgs rest
        | [] -> ()
    
    parseArgs args
    
    // Nodes bestimmen
    let nodesToCheck = 
        if nodeArg = "all" then
            NODES
        else
            match NODES.TryGetValue(nodeArg) with
            | true, config -> dict [(nodeArg, config)]
            | false, _ -> 
                log (sprintf "Unknown node: %s" nodeArg) "ERROR"
                exit 1
    
    // Health-Checks durchführen
    let allAlerts = ResizeArray<Alert>()
    
    for kvp in nodesToCheck do
        let nodeId = kvp.Key
        let nodeConfig = kvp.Value
        log (sprintf "Checking %s (%s)" nodeConfig.name nodeId) "INFO"
        
        // Ping
        if checkArg = "ping" || checkArg = "all" then
            if nodeConfig.host <> "localhost" then
                let pingOk = checkPing nodeConfig.host 10
                log (sprintf "  Ping: %s" (if pingOk then "OK" else "FAILED")) "INFO"
        
        // SSH
        if checkArg = "ssh" || checkArg = "all" then
            let sshOk = checkSsh nodeConfig
            log (sprintf "  SSH: %s" (if sshOk then "OK" else "FAILED")) "INFO"
        
        // Metriken
        if checkArg = "metrics" || checkArg = "all" then
            let metrics = getNodeMetrics nodeConfig
            
            if metrics.available then
                match metrics.cpu with Some cpu -> log (sprintf "  CPU: %.1f%%" cpu) "INFO" | None -> log "  CPU: N/A" "INFO"
                match metrics.ram with Some ram -> log (sprintf "  RAM: %.1f%%" ram) "INFO" | None -> log "  RAM: N/A" "INFO"
                match metrics.disk with Some disk -> log (sprintf "  Disk: %d%%" disk) "INFO" | None -> log "  Disk: N/A" "INFO"
                match metrics.load with Some load -> log (sprintf "  Load: %.2f" load) "INFO" | None -> log "  Load: N/A" "INFO"
            else
                log "  Metrics: UNAVAILABLE" "INFO"
            
            // Alerts prüfen
            let alerts = checkAlerts nodeId nodeConfig metrics
            allAlerts.AddRange(alerts)
    
    // Alerts senden
    if sendAlerts && allAlerts.Count > 0 then
        log (sprintf "\nSending %d alerts..." allAlerts.Count) "INFO"
        for alert in allAlerts do
            sendAlert alert
    elif allAlerts.Count > 0 then
        log (sprintf "\n%d alerts found (use --alert to send)" allAlerts.Count) "INFO"
    else
        log "\nAll nodes healthy!" "INFO"
    
    0

[<EntryPoint>]
let entryPoint argv =
    main argv
