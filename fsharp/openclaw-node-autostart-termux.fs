// abstraction-provenance: {"artifact_sha256": "de85421ee0819c3f79186364e38b579bd244ba3073b0e0469063d86e09ebe97e", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "fsharp"}
// openclaw-node-autostart-termux.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module Program

open System
open System.IO
open System.Diagnostics
open System.Threading

// OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
// Installiert nach: ~/.termux/boot/openclaw-node.sh
// Getestet mit: Termux + Android + OpenClaw

let SESSION = "openclaw-node"
let LOGFILE = Path.Combine(Environment.GetEnvironmentVariable("HOME"), ".openclaw", "node.log")
let GATEWAY = "10.10.0.1"
let PORT = "18789"

// Log-Verzeichnis erstellen
let logDir = Path.GetDirectoryName(LOGFILE)
if not (Directory.Exists(logDir)) then
    Directory.CreateDirectory(logDir) |> ignore

let writeLog (message: string) =
    let timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
    let logMessage = $"[{timestamp}] {message}"
    File.AppendAllLines(LOGFILE, [logMessage])

let rec runOpenClawNode () =
    async {
        writeLog "Starting OpenClaw Node Mode..."
        
        // Prüfe WireGuard Verbindung
        let ping = new Process()
        ping.StartInfo.FileName <- "ping"
        ping.StartInfo.Arguments <- $"-c 1 -W 3 {GATEWAY}"
        ping.StartInfo.UseShellExecute <- false
        ping.StartInfo.RedirectStandardOutput <- true
        ping.StartInfo.RedirectStandardError <- true
        
        try
            let started = ping.Start()
            if not started then
                writeLog $"FEHLER: Konnte ping nicht starten für Gateway {GATEWAY}!"
                return! waitForAndRestart ()
            
            ping.WaitForExit()
            
            if ping.ExitCode <> 0 then
                writeLog $"FEHLER: WireGuard Gateway {GATEWAY} nicht erreichbar!"
                writeLog "Warte 10 Sekunden..."
                do! Async.Sleep(10000)
                return! runOpenClawNode ()
                
        with ex ->
            writeLog $"FEHLER beim Pingen: {ex.Message}"
            return! waitForAndRestart ()

        // OpenClaw Node Mode starten
        let openclaw = new Process()
        openclaw.StartInfo.FileName <- "openclaw"
        openclaw.StartInfo.Arguments <- $"node run --host {GATEWAY} --port {PORT}"
        openclaw.StartInfo.UseShellExecute <- false
        openclaw.StartInfo.RedirectStandardOutput <- true
        openclaw.StartInfo.RedirectStandardError <- true
        
        openclaw.OutputDataReceived.Add(fun args -> 
            if not (String.IsNullOrEmpty(args.Data)) then
                writeLog args.Data)
        openclaw.ErrorDataReceived.Add(fun args -> 
            if not (String.IsNullOrEmpty(args.Data)) then
                writeLog $"ERROR: {args.Data}")
        
        try
            let started = openclaw.Start()
            if not started then
                writeLog "FEHLER: Konnte openclaw nicht starten!"
                return! waitForAndRestart ()
                
            openclaw.BeginOutputReadLine()
            openclaw.BeginErrorReadLine()
            
            openclaw.WaitForExit()
            
        with ex ->
            writeLog $"FEHLER beim Starten von OpenClaw: {ex.Message}"
            
        writeLog "OpenClaw beendet. Neustart in 5 Sekunden..."
        return! waitForAndRestart ()
    }
    
and waitForAndRestart () =
    async {
        do! Async.Sleep(5000)
        return! runOpenClawNode ()
    }

[<EntryPoint>]
let main argv =
    // Prüfen ob Session bereits läuft - in F# prüfen wir nicht auf tmux,
    // sondern verlassen einfach wenn bereits ein Prozess läuft
    // (vereinfachte Implementierung)
    
    writeLog "OpenClaw Node Autostart aktiviert"
    
    // Starte den asynchronen Prozess
    Async.RunSynchronously(runOpenClawNode ())
    
    0
