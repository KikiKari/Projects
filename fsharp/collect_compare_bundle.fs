// abstraction-provenance: {"artifact_sha256": "3e814be87bfa79506d01dcd0a80e2ad63fcbc06d716994c9ff0f23b5f114f6f3", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "fsharp"}
// collect_compare_bundle.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Diagnostics
open System.Text

let runCommand (cmd: string) (args: string) : string =
    let startInfo = ProcessStartInfo(cmd, args)
    startInfo.RedirectStandardOutput <- true
    startInfo.UseShellExecute <- false
    startInfo.CreateNoWindow <- true

    use proc = new Process()
    proc.StartInfo <- startInfo
    proc.Start() |> ignore
    let output = proc.StandardOutput.ReadToEnd()
    proc.WaitForExit()
    output.Trim()

let appendToFile (filePath: string) (content: string) =
    File.AppendAllText(filePath, content + Environment.NewLine)

let appendFileVerbatim (mdFile: string) (label: string) (path: string) (lang: string) =
    let header = $"\n## {label}\n\nPfad: `{path}`\n\n```{lang}\n"
    let footer = "\n```\n"
    appendToFile mdFile header
    if File.Exists(path) then
        appendToFile mdFile (File.ReadAllText(path))
    else
        appendToFile mdFile $"[FEHLT] {path}"
    appendToFile mdFile footer

let appendEnvVerbatim (mdFile: string) =
    let header = "\n## Umgebungsvariablen (env)\n\n```text\n"
    let footer = "\n```\n"
    appendToFile mdFile header
    let envVars = Environment.GetEnvironmentVariables()
    for entry in envVars do
        let e = entry :?> Collections.DictionaryEntry
        appendToFile mdFile $"{e.Key}={e.Value}"
    appendToFile mdFile footer

let appendDirFilesVerbatim (mdFile: string) (section: string) (dir: string) =
    let header = $"\n## {section}\n\n"
    appendToFile mdFile header
    if not (Directory.Exists(dir)) then
        appendToFile mdFile $"[FEHLT] {dir}"
        ()
    else
        appendToFile mdFile $"Basisverzeichnis: `{dir}`"
        let files = Directory.GetFiles(dir, "*", SearchOption.AllDirectories)
                        |> Array.sort
        for file in files do
            let relativePath = file.Replace(dir, "").TrimStart(Path.DirectorySeparatorChar)
            let fileHeader = $"\n### Datei: `{relativePath}`\n\n```text\n"
            let fileFooter = "\n```\n"
            appendToFile mdFile fileHeader
            appendToFile mdFile (File.ReadAllText(file))
            appendToFile mdFile fileFooter

[<EntryPoint>]
let main _ =
    let root = "/home/openclaw/.openclaw"
    let outDir = Path.Combine(root, "workspace", "vscode", "compare")
    let transferDir = Path.Combine(outDir, "transfer")
    let mdFile = Path.Combine(outDir, "local-gateway-config.md")
    let treeFile = Path.Combine(outDir, "tree.txt")
    let backupFile = "/home/openclaw/openclaw-backup.tar.gz"

    let nowLocal = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss zzz")
    let nowUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    let host =
        try
            runCommand "hostname" "-f"
        with
        | _ -> runCommand "hostname" ""

    let openclawJson = Path.Combine(root, "openclaw.json")
    let execApprovalsJson = Path.Combine(root, "exec-approvals.json")
    let gatewaySystemdEnv = Path.Combine(root, "gateway.systemd.env")
    let dotEnv = Path.Combine(root, ".env")
    let configDir = Path.Combine(root, ".config")
    let agentsDir = Path.Combine(root, "agents")

    Directory.CreateDirectory(outDir) |> ignore
    Directory.CreateDirectory(transferDir) |> ignore

    // Check if 'tree' is installed
    try
        runCommand "which" "tree" |> ignore
    with
    | _ ->
        Console.Error.WriteLine("Fehler: 'tree' ist nicht installiert.")
        exit 1

    // Write initial markdown content
    let initialMdContent = $"""# Lokaler Gateway-Konfigurationsstand

Generiert: {nowLocal}
UTC: {nowUtc}
Host: {host}

Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten."""
    File.WriteAllText(mdFile, initialMdContent + Environment.NewLine)

    appendFileVerbatim mdFile "openclaw.json" openclawJson "json"
    appendFileVerbatim mdFile "exec-approvals.json" execApprovalsJson "json"
    appendFileVerbatim mdFile "gateway.systemd.env" gatewaySystemdEnv "dotenv"
    appendFileVerbatim mdFile ".env" dotEnv "dotenv"
    appendEnvVerbatim mdFile
    appendDirFilesVerbatim mdFile ".config (alle Dateien rekursiv)" configDir
    appendDirFilesVerbatim mdFile "agents (alle Dateien rekursiv)" agentsDir

    // Run tree command and save to file
    let treeOutput = runCommand "tree" $"-a -L 6 \"{root}\""
    File.WriteAllText(treeFile, treeOutput)

    // Create backup using openclaw CLI
    let backupArgs = $"backup create --output \"{backupFile}\" --verify"
    runCommand "openclaw" backupArgs |> ignore

    // Copy backup file to output directory
    File.Copy(backupFile, Path.Combine(outDir, Path.GetFileName(backupFile)), true)

    printfn "OK"
    printfn "Erzeugt:"
    printfn "- %s" mdFile
    printfn "- %s" treeFile
    printfn "- %s" backupFile
    printfn "- %s (leer)" transferDir

    0
