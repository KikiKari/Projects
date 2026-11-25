// abstraction-provenance: {"artifact_sha256": "8595f833291a8daeb182825b08d596163d1cf01d8ada2a7f89c38964bf0b039a", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "fsharp"}
// channel_status.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

// Channel Status Agent - Automatische Status-Updates

open System
open System.IO
open System.Diagnostics
open System.Text.Json
open System.Text.Json.Serialization
open System.CommandLine
open System.CommandLine.Invocation

// Konfiguration
let WORKSPACE = Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".openclaw", "workspace")
let LOGS_DB = Path.Combine(WORKSPACE, "db", "logs.db")
let CONFIG_FILE = Path.Combine(WORKSPACE, "config", "channel-status.json")
let LOG_FILE = Path.Combine(WORKSPACE, "logs", "channel-status.log")

let log (message: string) (level: string) =
    let timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
    let entry = $"[{timestamp}] [{level}] {message}"
    printfn "%s" entry
    Directory.CreateDirectory(Path.GetDirectoryName(LOG_FILE)) |> ignore
    File.AppendAllText(LOG_FILE, entry + Environment.NewLine)

let runCommand (cmd: string) (args: string) =
    let startInfo = ProcessStartInfo(
        FileName = cmd,
        Arguments = args,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false
    )
    use proc = new Process(StartInfo = startInfo)
    proc.Start() |> ignore
    let output = proc.StandardOutput.ReadToEnd()
    let error = proc.StandardError.ReadToEnd()
    proc.WaitForExit()
    (proc.ExitCode, output, error)

let getSystemStatus () =
    let status = JsonDocument.Parse("{}").RootElement
    let mutable nodes = Map.empty
    
    // Node-Status (vereinfacht)
    nodes <- nodes.Add("node1", {| name = "Gateway"; status = "online" |})
    nodes <- nodes.Add("node2", {| name = "Worker"; status = "online" |})
    nodes <- nodes.Add("node3", {| name = "Relay"; status = "offline"; reason = "disk full" |})
    nodes <- nodes.Add("node5", {| name = "Redmi"; status = "intermittent" |})
    nodes <- nodes.Add("node7", {| name = "Docker"; status = "planned" |})
    
    let mutable agents = Map.empty
    let mutable system = Map.empty
    
    // Agent-Status aus Cron
    try
        let (exitCode, stdout, _) = runCommand "crontab" "-l"
        if exitCode = 0 then
            let lines = stdout.Split([|'\n'|], StringSplitOptions.RemoveEmptyEntries)
            let activeCrons = lines |> Array.filter (fun line -> not (line.StartsWith("#"))) |> Array.length
            agents <- agents.Add("active_crons", activeCrons.ToString())
        else
            agents <- agents.Add("active_crons", "unknown")
    with
    | _ -> agents <- agents.Add("active_crons", "unknown")
    
    // System-Metriken
    try
        // Disk usage
        let (exitCode, stdout, _) = runCommand "df" "-h /"
        if exitCode = 0 then
            for line in stdout.Split([|'\n'|]) do
                if line.Contains("/") && line.Contains("%") then
                    let parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                    if parts.Length >= 5 then
                        system <- system.Add("disk_used", parts.[4])
                    break
        
        // RAM usage
        let (exitCode, stdout, _) = runCommand "free" "-h"
        if exitCode = 0 then
            for line in stdout.Split([|'\n'|]) do
                if line.Contains("Mem:") then
                    let parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                    if parts.Length >= 3 then
                        system <- system.Add("ram_total", parts.[1])
                        system <- system.Add("ram_used", parts.[2])
                    break
    with
    | _ -> ()
    
    {| 
        timestamp = DateTime.Now.ToString("o")
        nodes = nodes
        agents = agents
        system = system
    |}

let formatDailyStatus (status: {| timestamp: string; nodes: Map<string, {| name: string; status: string; reason: string |}>; agents: Map<string, string>; system: Map<string, string> |}) =
    let onlineCount = status.nodes |> Map.toList |> List.sumBy (fun (_, node) -> if node.status = "online" then 1 else 0)
    
    let mutable message = $"""📊 **Täglicher Status-Report**
🗓️ {DateTime.Now.ToString("yyyy-MM-dd HH:mm")}

**🖥️ Nodes ({onlineCount}/5 online):**
"""
    
    for (nodeId, info) in status.nodes |> Map.toList do
        let emoji = 
            match info.status with
            | "online" -> "🟢"
            | "offline" -> "🔴"
            | _ -> "🟡"
        
        message <- message + $"{emoji} {info.name}: {info.status}"
        if obj.ReferenceEquals(info, {| name = ""; status = ""; reason = "" |}) && not (String.IsNullOrEmpty(info.reason)) then
            message <- message + $" ({info.reason})"
        message <- message + "\n"
    
    message <- message + $"\n**🤖 Agents:**\n"
    message <- message + $"Aktive Cron-Jobs: {status.agents.["active_crons"]}\n"
    
    if status.system.ContainsKey("disk_used") then
        message <- message + $"\n**💾 System:**\n"
        message <- message + $"Disk: {status.system.["disk_used"]} belegt\n"
        message <- message + $"RAM: {status.system.["ram_used"]} / {status.system.["ram_total"]}\n"
    
    message

let formatWeeklyStatus (_status: {| timestamp: string; nodes: Map<string, {| name: string; status: string; reason: string |}>; agents: Map<string, string>; system: Map<string, string> |}) =
    $"""📈 **Wöchentlicher Report**
📅 Woche {DateTime.Now.ToString("yyyy")} - {DateTime.Now.ToString("yyyy")}

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
"""

let sendToChannel (message: string) (channelType: string) (channelId: string) =
    if channelType = "telegram" then
        // Nutze OpenClaw message tool
        let cmd = "openclaw"
        let args = $"message send --target {channelId} --message \"{message}\""
        
        try
            let (exitCode, _, stderr) = runCommand cmd args
            if exitCode = 0 then
                log $"Message sent to {channelType} {channelId}" "INFO"
                true
            else
                log $"Failed to send: {stderr}" "ERROR"
                false
        with
        | ex -> 
            log $"Send error: {ex.Message}" "ERROR"
            false
    else
        log $"Channel type {channelType} not implemented" "WARN"
        false

let mainHandler (updateType: string) (alertMessage: string option) (channel: string) (dryRun: bool) =
    log $"Starting {updateType} status update" "INFO"
    
    // Status sammeln
    let status = getSystemStatus()
    
    // Message formatieren
    let message = 
        match updateType with
        | "daily" -> formatDailyStatus status
        | "weekly" -> formatWeeklyStatus status
        | "alert" -> $"🚨 **ALERT**\n{defaultArg alertMessage "Manual alert"}"
        | _ -> ""
    
    // Senden oder Dry-Run
    if dryRun then
        printfn "\n--- DRY RUN ---"
        printfn "%s" message
        printfn "--- END ---"
    else
        sendToChannel message "telegram" channel |> ignore
    
    log "Status update completed" "INFO"

[<EntryPoint>]
let main argv =
    Directory.CreateDirectory(Path.GetDirectoryName(LOG_FILE)) |> ignore
    
    let rootCommand = RootCommand(Description = "Channel Status Agent")
    
    let typeOption = Option<string>(
        "--type",
        "Type of status update (daily, weekly, alert)"
    )
    typeOption.IsRequired <- true
    rootCommand.AddOption(typeOption)
    
    let messageOption = Option<string>(
        "--message",
        "Alert message for alert type"
    )
    rootCommand.AddOption(messageOption)
    
    let channelOption = Option<string>(
        "--channel",
        fun () -> "-1002381931352"
    )
    rootCommand.AddOption(channelOption)
    
    let dryRunOption = Option<bool>(
        "--dry-run",
        "Show message without sending"
    )
    rootCommand.AddOption(dryRunOption)
    
    rootCommand.SetHandler(mainHandler, typeOption, messageOption, channelOption, dryRunOption)
    
    rootCommand.Invoke(argv)
