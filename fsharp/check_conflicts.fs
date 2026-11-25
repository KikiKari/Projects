// abstraction-provenance: {"artifact_sha256": "6730429e182d9dacfdf97cd38789c32788caf389989f0eb536b4343cc0f1a992", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "fsharp"}
// check_conflicts.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

module CheckConflicts

open System
open System.IO
open System.Security.Cryptography
open System.Text

// Pfade definieren
let CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
let GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"

// Hilfsfunktion zur Berechnung des SHA256-Hashes einer Datei
let getFileHash (filePath: string) : string =
    use sha256 = SHA256.Create()
    use stream = File.OpenRead(filePath)
    let hashBytes = sha256.ComputeHash(stream)
    BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant()

// Funktion zur Überprüfung von Konflikten
let checkConflicts () =
    let conflicts = ResizeArray<obj>()
    
    // Gemeinsame Skills ermitteln
    let commonSkills = ResizeArray<string>()
    if Directory.Exists(CLAWHUB_DIR) && Directory.Exists(GIT_DIR) then
        let clawhubSkills = 
            Directory.GetDirectories(CLAWHUB_DIR)
            |> Array.map Path.GetFileName
            |> Set.ofArray
        let gitSkills = 
            Directory.GetDirectories(GIT_DIR)
            |> Array.map Path.GetFileName
            |> Set.ofArray
        Set.intersect clawhubSkills gitSkills |> Set.iter commonSkills.Add
    
    printfn $"Prüfe {commonSkills.Count} Skills auf Konflikte...\n"
    
    for skill in commonSkills |> Seq.sort do
        let clawhubPath = Path.Combine(CLAWHUB_DIR, skill)
        let gitPath = Path.Combine(GIT_DIR, skill)
        
        let skillConflicts = ResizeArray<obj>()
        
        // ClawHub Dateien sammeln
        let clawhubFiles = dict<string, string>()
        for file in Directory.GetFiles(clawhubPath, "*", SearchOption.AllDirectories) do
            if not (file.Contains(".git")) then
                let relPath = file.Substring(clawhubPath.Length + 1)
                clawhubFiles.[relPath] <- file
        
        // Git Dateien sammeln
        let gitFiles = dict<string, string>()
        for file in Directory.GetFiles(gitPath, "*", SearchOption.AllDirectories) do
            if not (file.Contains(".git")) then
                let relPath = file.Substring(gitPath.Length + 1)
                gitFiles.[relPath] <- file
        
        // Gemeinsame Dateien vergleichen
        let commonFiles = Set.intersect (clawhubFiles.Keys |> Set.ofSeq) (gitFiles.Keys |> Set.ofSeq)
        for relPath in commonFiles do
            let clawhubFile = clawhubFiles.[relPath]
            let gitFile = gitFiles.[relPath]
            
            if getFileHash(clawhubFile) <> getFileHash(gitFile) then
                let clawhubInfo = File.GetLastWriteTime(clawhubFile)
                let gitInfo = File.GetLastWriteTime(gitFile)
                
                let newer = if clawhubInfo > gitInfo then "clawhub" else "git"
                
                skillConflicts.Add(
                    {| 
                        file = relPath
                        clawhub_modified = clawhubInfo.ToString("yyyy-MM-dd HH:mm:ss")
                        git_modified = gitInfo.ToString("yyyy-MM-dd HH:mm:ss")
                        newer = newer
                    |}
                )
        
        if skillConflicts.Count > 0 then
            conflicts.Add(
                {| 
                    skill = skill
                    conflicts = skillConflicts
                |}
            )
    
    // Ausgabe der Ergebnisse
    if conflicts.Count > 0 then
        printfn "⚠️  KONFLIKTE GEFUNDEN:"
        printfn "================================================================================"
        
        for conflict in conflicts do
            printfn $"\n📦 Skill: {conflict.skill}"
            printfn "----------------------------------------"
            
            for fileConflict in conflict.conflicts do
                printfn $"  📄 {fileConflict.file}"
                printfn $"     ClawHub: {fileConflict.clawhub_modified}"
                printfn $"     Git:     {fileConflict.git_modified}"
                printfn $"     Neuer:   {fileConflict.newer.ToUpper()}"
                printfn ""
        
        printfn "================================================================================"
        printfn $"Gesamt: {conflicts.Count} Skills mit Konflikten"
        printfn "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
    else
        printfn "✅ Keine Konflikte gefunden!"
        printfn "Alle gemeinsamen Skills sind synchron."

// Hauptfunktion
[<EntryPoint>]
let main argv =
    checkConflicts()
    0
