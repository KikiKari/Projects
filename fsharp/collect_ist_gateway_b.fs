// abstraction-provenance: {"artifact_sha256": "fe4688746f18408dbf2e18c2bc3f11f8307ab85b4eaa54dc10f6cbde8aaf3759", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "fsharp"}
// collect_ist_gateway_b.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Diagnostics
open System.Net.Http
open System.Text.RegularExpressions

let runCommand (cmd: string) (args: string) =
    let psi = ProcessStartInfo(cmd, args)
    psi.RedirectStandardOutput <- true
    psi.RedirectStandardError <- true
    psi.UseShellExecute <- false
    psi.CreateNoWindow <- true
    use proc = new Process()
    proc.StartInfo <- psi
    proc.Start() |> ignore
    let output = proc.StandardOutput.ReadToEnd()
    let error = proc.StandardError.ReadToEnd()
    proc.WaitForExit()
    if proc.ExitCode = 0 then output.Trim() else ""

let safeRunCommand (cmd: string) (args: string) =
    try
        let result = runCommand cmd args
        if String.IsNullOrEmpty(result) then "(nicht ermittelt)" else result
    with _ -> "(nicht ermittelt)"

let fileExists path = if File.Exists(path) then "vorhanden" else "fehlt"
let dirExists path = if Directory.Exists(path) then "vorhanden" else "fehlt"

let getEnvVar var = Environment.GetEnvironmentVariable(var)

let nowUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
let nowLocal = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss zzz").Replace("+", " UTC+").Replace("-", " UTC-")
let ts = DateTime.Now.ToString("yyyyMMdd-HHmmss")

let homeDir = getEnvVar "HOME"
let baseDir = Path.Combine(homeDir, ".openclaw")
let outDir = Path.Combine(baseDir, "workspace", "vscode")
let vscodeDir = Path.Combine(baseDir, ".vscode")

Directory.CreateDirectory(outDir) |> ignore

let istFile = Path.Combine(outDir, "IST-ZUSTAND_GATEWAY-B_NODE7.md")
let invFile = Path.Combine(outDir, "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md")
let cfgFile = Path.Combine(outDir, "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md")
let envFile = Path.Combine(outDir, "ENV-STATUS_GATEWAY-B_NODE7.md")
let runFile = Path.Combine(outDir, $"RUN-{ts}.md")

let openclawJson = Path.Combine(baseDir, "openclaw.json")
let envDot = Path.Combine(baseDir, ".env")
let envSystemd = Path.Combine(baseDir, "gateway.systemd.env")

let hostnameFqdn = 
    try 
        runCommand "hostname" "-f"
    with _ -> 
        runCommand "hostname" ""

let hostnameShort = runCommand "hostname" ""
let arch = runCommand "uname" "-m"
let kernel = runCommand "uname" "-r"

let osPretty = 
    try
        let content = File.ReadAllText("/etc/os-release")
        let matchResult = Regex.Match(content, @"^PRETTY_NAME=(.*)$")
        if matchResult.Success then 
            matchResult.Groups.[1].Value.Trim('"')
        else 
            ""
    with _ -> ""

let ipv4All = 
    try 
        runCommand "hostname" "-I"
    with _ -> 
        ""

let publicIp = 
    try
        use client = new HttpClient()
        client.Timeout <- TimeSpan.FromSeconds(4.0)
        client.GetStringAsync("http://ifconfig.me").Result
    with _ -> 
        "(nicht ermittelt)"

let tailscaleIp = 
    try 
        let result = runCommand "tailscale" "ip -4"
        result.Split('\n').[0]
    with _ -> 
        "(nicht ermittelt)"

let openclawVer = safeRunCommand "openclaw" "--version"
let nodeVer = safeRunCommand "node" "-v"

let writeIstFile() =
    let content = $"""
# IST-Zustand: Gateway B / Node 7

Stand (lokal): {nowLocal}  
Stand (UTC): {nowUtc}

## 1) Identität & System

- Gateway: **B**
- Node: **7**
- Hostname (short): `{hostnameShort}`
- Hostname (FQDN): `{hostnameFqdn}`
- Architektur: `{arch}`
- Kernel: `{kernel}`
- OS: `{osPretty}`
- IPv4 (lokal): `{ipv4All}`
- Public IPv4: `{publicIp}`
- Tailscale IPv4: `{tailscaleIp}`
- OpenClaw Version: `{openclawVer}`
- Node.js Version: `{nodeVer}`

## 2) Arbeitsverzeichnisse

- Basis: `{baseDir}`
- Funktionell VSCode: `{vscodeDir}`
- Workspace Doku: `{outDir}`

## 3) Kernartefakte (Existenz)

- `{openclawJson}`: {fileExists openclawJson}
- `{envDot}`: {fileExists envDot}
- `{envSystemd}`: {fileExists envSystemd}
- `{Path.Combine(baseDir, "plugins/installs.json")}`: {fileExists (Path.Combine(baseDir, "plugins/installs.json"))}
- `{Path.Combine(baseDir, "plugin-skills")}`: {dirExists (Path.Combine(baseDir, "plugin-skills"))}

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
"""
    File.WriteAllText(istFile, content)

let writeInvFile() =
    let topLevelContent = 
        try
            Directory.GetFileSystemEntries(baseDir) 
            |> Array.map Path.GetFileName
            |> String.concat "\n"
        with _ -> ""
    
    let vscodeContent = 
        if Directory.Exists(vscodeDir) then
            try
                let dirInfo = DirectoryInfo(vscodeDir)
                dirInfo.GetFiles() 
                |> Array.map (fun f -> f.Name)
                |> String.concat "\n"
            with _ -> ""
        else "(nicht vorhanden)"
    
    let pluginSkillsContent = 
        let pluginSkillsDir = Path.Combine(baseDir, "plugin-skills")
        if Directory.Exists(pluginSkillsDir) then
            try
                Directory.GetDirectories(pluginSkillsDir)
                |> Array.map Path.GetFileName
                |> String.concat "\n"
            with _ -> ""
        else "(nicht vorhanden)"
    
    let backupFiles = 
        try
            let pattern = Path.Combine(baseDir, "openclaw.json.bak*")
            let dir = Path.GetDirectoryName(pattern)
            let filePattern = Path.GetFileName(pattern)
            if Directory.Exists(dir) then
                Directory.GetFiles(dir, filePattern)
                |> Array.map Path.GetFileName
                |> String.concat "\n"
            else "(keine gefunden)"
        with _ -> "(keine gefunden)"
    
    let content = $"""
# Artefakt-Inventar: Gateway B / Node 7

Stand: {nowLocal}

## Top-Level in ~/.openclaw

```text
{topLevelContent}
```

## ~/.openclaw/.vscode

```text
{vscodeContent}
```

## plugin-skills/

```text
{pluginSkillsContent}
```

## openclaw.json Backups

```text
{backupFiles}
```
"""
    File.WriteAllText(invFile, content)

let writeCfgFile() =
    let keyPositions = 
        if File.Exists(openclawJson) then
            try
                let content = File.ReadAllText(openclawJson)
                let lines = content.Split('\n')
                lines 
                |> Array.mapi (fun i line -> (i+1, line))
                |> Array.filter (fun (_, line) -> Regex.IsMatch(line, @"""gateway""|\""session\""|\""dmScope\""|\""auth\""|\""secrets\""|\""tools\""|\""plugins\""|\""profile\""|\""alsoAllow\""|\""denyCommands"""))
                |> Array.map (fun (lineNum, line) -> $"{lineNum}: {line}")
                |> String.concat "\n"
            with _ -> ""
        else "openclaw.json fehlt"
    
    let snippet = 
        if File.Exists(openclawJson) then
            try
                let lines = File.ReadAllLines(openclawJson)
                let startIdx = max 0 (580 - 1)
                let endIdx = min (lines.Length - 1) (780 - 1)
                lines.[startIdx..endIdx] |> String.concat "\n"
            with _ -> "{ \"error\": \"Fehler beim Lesen\" }"
        else "{ \"error\": \"openclaw.json fehlt\" }"
    
    let content = $"""
# OpenClaw Config Snapshot: Gateway B / Node 7

Stand: {nowLocal}

## Schlüsselpositionen (grep)

```text
{keyPositions}
```

## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)

```json
{snippet}
```
"""
    File.WriteAllText(cfgFile, content)

let writeEnvFile() =
    let filesList = 
        try
            let files = [envDot; envSystemd] |> List.filter File.Exists
            files 
            |> List.map (fun path -> 
                let info = FileInfo(path)
                $"{info.Name} - {info.Length} bytes - {info.LastWriteTime}")
            |> String.concat "\n"
        with _ -> ""
    
    let envDotContent = 
        if File.Exists(envDot) then
            try
                File.ReadAllText(envDot)
            with _ -> "# Fehler beim Lesen"
        else "# .env fehlt"
    
    let envSystemdContent = 
        if File.Exists(envSystemd) then
            try
                File.ReadAllText(envSystemd)
            with _ -> "# Fehler beim Lesen"
        else "# gateway.systemd.env fehlt"
    
    let content = $"""
# ENV-Status: Gateway B / Node 7

Stand: {nowLocal}

## Dateien

```text
{filesList}
```

## .env (vollständig, ungefiltert)

```dotenv
{envDotContent}
```

## gateway.systemd.env (vollständig, ungefiltert)

```dotenv
{envSystemdContent}
```
"""
    File.WriteAllText(envFile, content)

let writeRunFile() =
    let scriptPath = System.Reflection.Assembly.GetEntryAssembly().Location
    let content = $"""
# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): {nowLocal}
- Zeit (UTC): {nowUtc}
- Script: {scriptPath}

## Erzeugte Dateien

- {Path.GetFileName(istFile)}
- {Path.GetFileName(invFile)}
- {Path.GetFileName(cfgFile)}
- {Path.GetFileName(envFile)}

"""
    File.WriteAllText(runFile, content)

[<EntryPoint>]
let main argv =
    writeIstFile()
    writeInvFile()
    writeCfgFile()
    writeEnvFile()
    writeRunFile()
    
    printfn "OK: IST-Zustand erfasst."
    printfn "Ausgabeordner: %s" outDir
    printfn "Dateien:"
    
    if Directory.Exists(outDir) then
        Directory.GetFiles(outDir)
        |> Array.map Path.GetFileName
        |> Array.iter (printfn "- %s")
    
    0
