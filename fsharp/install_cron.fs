// abstraction-provenance: {"artifact_sha256": "7e0601e972eb018d4abf374786405333c450bbe797b265735a11a4a79486c00d", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "fsharp"}
// install_cron.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Installiert den DB-Maintainer als Cron-Job

open System
open System.IO
open System.Text.Json
open System.Text.Json.Serialization

let CRON_JOB = """
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
""".Trim()

type CronJob = {
    schedule: string
    command: string
    enabled: bool
}

type Jobs = Map<string, CronJob>

let install() =
    let workspace = Path.Combine("/home/openclaw/.openclaw/workspace")
    let cronFile = Path.Combine(workspace, "crons", "db-maintainer.cron")
    
    // Stelle sicher, dass das Verzeichnis existiert
    Directory.CreateDirectory(Path.GetDirectoryName(cronFile)) |> ignore
    
    // Schreibe die Cron-Datei
    File.WriteAllText(cronFile, CRON_JOB)
    
    printfn $"✅ Cron-Job installiert: {cronFile}"
    printfn "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    // Auch in OpenClaw cron registrieren
    let jobsJson = Path.Combine(workspace, ".openclaw", "cron", "jobs.json")
    if File.Exists(jobsJson) then
        let jsonContent = File.ReadAllText(jobsJson)
        let options = JsonSerializerOptions()
        options.WriteIndented <- true
        let jobs = JsonSerializer.Deserialize<Map<string, CronJob>>(jsonContent)
        
        let updatedJobs = 
            jobs 
            |> Map.add "db-maintainer" {
                schedule = "*/30 * * * *"
                command = "python3 skills/db-maintainer/scripts/db_maintainer.py"
                enabled = true
            }
        
        let serializedJobs = JsonSerializer.Serialize(updatedJobs, options)
        File.WriteAllText(jobsJson, serializedJobs)
        
        printfn "✅ In OpenClaw cron registriert"

// Hauptprogramm
install()
