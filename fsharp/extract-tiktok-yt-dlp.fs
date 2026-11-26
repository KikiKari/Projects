// abstraction-provenance: {"artifact_sha256": "678f9e311aef810faae8bb151f44f7a5ebb87f039a4639df96747ff907c647d3", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "fsharp"}
// extract-tiktok-yt-dlp.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text.Json
open System.Diagnostics
open System.Text.RegularExpressions

let private emitJson (args: string[]) =
    let keys = [| "success"; "method"; "username"; "url"; "format"; "error"; "timestamp"; "status" |]
    let payload = 
        keys 
        |> Array.mapi (fun i key -> 
            if i < args.Length && args.[i] <> "" then Some(key, args.[i]) else None)
        |> Array.choose id
        |> dict
    
    let mutable successValue = false
    let payloadDict = Dictionary<string, obj>()
    for kvp in payload do
        if kvp.Key = "success" then
            successValue <- (string kvp.Value).ToLower() = "true"
            payloadDict.[kvp.Key] <- successValue :> obj
        else
            payloadDict.[kvp.Key] <- kvp.Value :> obj
    
    JsonSerializer.Serialize(payloadDict, JsonSerializerOptions(EscapeEncoder = Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping))

let private runPythonScript (script: string) (args: string[]) =
    let startInfo = ProcessStartInfo(
        FileName = "python3",
        Arguments = $"-c \"{script}\"",
        RedirectStandardInput = true,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false
    )
    
    use proc = new Process(StartInfo = startInfo)
    proc.Start() |> ignore
    proc.StandardInput.Write(script)
    proc.StandardInput.Close()
    
    let result = proc.StandardOutput.ReadToEnd()
    proc.WaitForExit()
    result.Trim()

let private runPythonWithArgs (script: string) (args: string[]) =
    let scriptArg = String.Join(" ", args |> Array.map (sprintf "\"%s\""))
    let fullScript = $"{script}\n{scriptArg}"
    
    let startInfo = ProcessStartInfo(
        FileName = "python3",
        Arguments = $"-c \"{script.Replace("\"", "\\\"")}\" {scriptArg}",
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false
    )
    
    use proc = new Process(StartInfo = startInfo)
    proc.Start() |> ignore
    
    let result = proc.StandardOutput.ReadToEnd()
    let error = proc.StandardError.ReadToEnd()
    proc.WaitForExit()
    
    if proc.ExitCode <> 0 then
        failwith error
    result.Trim()

[<EntryPoint>]
let main argv =
    try
        if argv.Length < 1 then
            eprintfn "Invalid TikTok username"
            exit 64
            
        let username = if argv.[0].StartsWith("@") then argv.[0].Substring(1) else argv.[0]
        let format = if argv.Length > 1 then argv.[1] else "best"
        let jsonFlag = if argv.Length > 2 then argv.[2] else ""
        let timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        // Validate username
        let usernameRegex = Regex(@"^[A-Za-z0-9._]{1,24}$")
        if not (usernameRegex.IsMatch(username)) then
            eprintfn "Invalid TikTok username"
            exit 64
            
        // Validate format
        let validFormats = [
            "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld"
            "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
            "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
            "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld"
            "hls-sd/hls-ld/flv-sd/flv-ld"
            "hls-ld/flv-ld"
            "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
        ]
        
        if not (validFormats |> List.contains format) then
            eprintfn "Invalid yt-dlp format"
            exit 64
            
        // Check system load
        let loadPerCpuScript = "import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))"
        let loadPerCpu = runPythonWithArgs loadPerCpuScript [||]
        let maxLoad = Environment.GetEnvironmentVariable("TIKTOK_MAX_LOAD_PER_CPU") |> function null -> "1.5" | s -> s
        
        let compareLoadScript = "import sys; sys.exit(0 if float(sys.argv[1]) > float(sys.argv[2]) else 1)"
        try
            runPythonWithArgs compareLoadScript [| loadPerCpu; maxLoad |] |> ignore
        with _ ->
            let errorMsg = emitJson [| "false"; "yt-dlp"; username; ""; format; "host overloaded"; timestamp; "overloaded" |]
            eprintfn "%s" errorMsg
            exit 75
            
        // Check if yt-dlp exists
        try
            use proc = Process.Start(ProcessStartInfo(FileName = "which", Arguments = "yt-dlp", RedirectStandardOutput = true))
            proc.WaitForExit()
            if proc.ExitCode <> 0 then
                let errorMsg = emitJson [| "false"; "yt-dlp"; username; ""; format; "yt-dlp not installed"; timestamp; "dependency_missing" |]
                eprintfn "%s" errorMsg
                exit 2
        with _ ->
            let errorMsg = emitJson [| "false"; "yt-dlp"; username; ""; format; "yt-dlp not installed"; timestamp; "dependency_missing" |]
            eprintfn "%s" errorMsg
            exit 2
            
        // Create temp directory
        let tmpDir = Path.Combine(Path.GetTempPath(), $"tiktok-yt-dlp.{Guid.NewGuid().ToString("N").Substring(0, 6)}")
        Directory.CreateDirectory(tmpDir) |> ignore
        
        // Cleanup on exit
        AppDomain.CurrentDomain.ProcessExit.Add(fun _ -> 
            if Directory.Exists(tmpDir) then
                Directory.Delete(tmpDir, true)
        )
        
        let stdoutFile = Path.Combine(tmpDir, "stdout.json")
        let stderrFile = Path.Combine(tmpDir, "stderr.log")
        let liveUrl = $"https://www.tiktok.com/@{username}/live"
        
        // Run yt-dlp
        let startInfo = ProcessStartInfo(
            FileName = "yt-dlp",
            Arguments = $"--no-warnings --dump-single-json --skip-download --format \"{format}\" \"{liveUrl}\"",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        )
        
        use proc = new Process(StartInfo = startInfo)
        proc.Start() |> ignore
        
        let stdoutTask = proc.StandardOutput.ReadToEndAsync()
        let stderrTask = proc.StandardError.ReadToEndAsync()
        
        proc.WaitForExit()
        
        let stdout = stdoutTask.Result
        let stderr = stderrTask.Result
        
        File.WriteAllText(stdoutFile, stdout)
        File.WriteAllText(stderrFile, stderr)
        
        if proc.ExitCode <> 0 then
            let status, code = 
                if Regex.IsMatch(stderr.ToLower(), "not currently live|no live cdn found|not available|private video") then
                    "offline", 1
                else
                    "technical_error", 2
                    
            let errorPreview = if stderr.Length > 1000 then stderr.Substring(0, 1000) else stderr
            let errorMsg = emitJson [| "false"; "yt-dlp"; username; ""; format; errorPreview; timestamp; status |]
            eprintfn "%s" errorMsg
            exit code
            
        // Extract URL from JSON
        let extractUrlScript = """
import json, sys
d=json.load(sys.stdin)
candidates=[]
if isinstance(d.get("url"), str):
    candidates.append(d["url"])
for item in d.get("formats", []) or []:
    if isinstance(item, dict) and isinstance(item.get("url"), str):
        candidates.append(item["url"])
for value in candidates:
    low = value.lower()
    if value.startswith("https://") and (".m3u8" in low or ".flv" in low) and "only_audio=1" not in low:
        print(value)
        break
"""
        
        let url = 
            try
                runPythonWithArgs extractUrlScript [| |]
            with _ -> ""
            
        if String.IsNullOrEmpty(url) then
            let errorMsg = emitJson [| "false"; "yt-dlp"; username; ""; format; "could not extract HTTPS video URL"; timestamp; "offline" |]
            eprintfn "%s" errorMsg
            exit 1
            
        if jsonFlag = "--json" then
            let successMsg = emitJson [| "true"; "yt-dlp"; username; url; format; ""; timestamp; "live" |]
            printfn "%s" successMsg
        else
            printfn "%s" url
            
        // Cleanup
        if Directory.Exists(tmpDir) then
            Directory.Delete(tmpDir, true)
            
        0
    with
    | ex ->
        eprintfn "Unexpected error: %s" ex.Message
        1
