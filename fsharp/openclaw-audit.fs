// abstraction-provenance: {"artifact_sha256": "a2bb5668ae2ed48562d5a2286d598a1c00b78d1a74a46d8c810cb7a7c8bbac28", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "fsharp"}
// openclaw-audit.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.Diagnostics
open System.IO
open System.Text

let runCommand (cmd: string) (args: string) : string =
    let startInfo = ProcessStartInfo(cmd, args)
    startInfo.RedirectStandardOutput <- true
    startInfo.RedirectStandardError <- true
    startInfo.UseShellExecute <- false
    startInfo.CreateNoWindow <- true

    use proc = new Process()
    proc.StartInfo <- startInfo
    proc.Start() |> ignore

    let output = proc.StandardOutput.ReadToEnd()
    let error = proc.StandardError.ReadToEnd()
    proc.WaitForExit()

    if String.IsNullOrEmpty(error) then output else output + "\n" + error

let getCurrentDateISO () =
    DateTime.Now.ToString("yyyy-MM-ddTHH:mm:sszzz")

let getDateStamp () =
    DateTime.Now.ToString("yyyy-MM-dd")

let getScriptDir () =
    Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)

let writeHeader (writer: StreamWriter) =
    writer.WriteLine("================================================================")
    writer.WriteLine("OpenClaw audit run")
    writer.WriteLine($"Started:  {getCurrentDateISO()}")
    writer.WriteLine($"Host:     {Environment.MachineName}")
    writer.WriteLine($"User:     {Environment.UserName}")
    let versionOutput = try runCommand "openclaw" "--version" with _ -> "unknown"
    writer.WriteLine($"Version:  {versionOutput.Trim()}")
    writer.WriteLine($"Output:   {getScriptDir()}/openclaw-audit-{getDateStamp()}.log")
    writer.WriteLine("================================================================")

let runCmd (writer: StreamWriter) (title: string) (cmdAndArgs: string[]) =
    writer.WriteLine()
    writer.WriteLine("----------------------------------------------------------------")
    writer.WriteLine($"### {title}")
    writer.WriteLine($"### $ {String.concat " " cmdAndArgs}")
    writer.WriteLine($"### {getCurrentDateISO()}")
    writer.WriteLine("----------------------------------------------------------------")

    let startInfo = ProcessStartInfo(cmdAndArgs.[0], String.Join(" ", cmdAndArgs.[1..]))
    startInfo.RedirectStandardOutput <- true
    startInfo.RedirectStandardError <- true
    startInfo.UseShellExecute <- false
    startInfo.CreateNoWindow <- true

    use proc = new Process()
    proc.StartInfo <- startInfo
    proc.Start() |> ignore

    let output = proc.StandardOutput.ReadToEnd()
    let error = proc.StandardError.ReadToEnd()
    proc.WaitForExit()

    writer.WriteLine(output)
    if not (String.IsNullOrEmpty(error)) then
        writer.WriteLine(error)

    writer.WriteLine($"[exit: {proc.ExitCode}]")

[<EntryPoint>]
let main _ =
    let scriptDir = getScriptDir()
    let dateStamp = getDateStamp()
    let outFile = Path.Combine(scriptDir, $"openclaw-audit-{dateStamp}.log")

    use fileStream = new FileStream(outFile, FileMode.Create, FileAccess.Write)
    use writer = new StreamWriter(fileStream, Encoding.UTF8)

    writeHeader writer

    let oc = [| "openclaw"; "--no-color" |]

    let commands = [|
        ("tasks audit --severity error", Array.append oc [| "tasks"; "audit"; "--severity"; "error" |])
        ("secrets audit", Array.append oc [| "secrets"; "audit" |])
        ("security audit", Array.append oc [| "security"; "audit" |])
        ("plugins doctor", Array.append oc [| "plugins"; "doctor" |])
        ("plugins deps", Array.append oc [| "plugins"; "deps" |])
        ("plugins registry", Array.append oc [| "plugins"; "registry" |])
        ("skills check", Array.append oc [| "skills"; "check" |])
        ("hooks check", Array.append oc [| "hooks"; "check" |])
        ("gateway status --deep", Array.append oc [| "gateway"; "status"; "--deep" |])
        ("channels status --probe", Array.append oc [| "channels"; "status"; "--probe" |])
        ("memory status --deep", Array.append oc [| "memory"; "status"; "--deep" |])
        ("sessions --all-agents", Array.append oc [| "sessions"; "--all-agents" |])
        ("tasks list", Array.append oc [| "tasks"; "list" |])
        ("cron list", Array.append oc [| "cron"; "list" |])
    |]

    for (title, cmdArgs) in commands do
        runCmd writer title cmdArgs

    writer.WriteLine()
    writer.WriteLine("================================================================")
    writer.WriteLine($"Audit complete: {getCurrentDateISO()}")
    writer.WriteLine("================================================================")

    Console.WriteLine($"Audit complete. Output: {outFile}")
    0
