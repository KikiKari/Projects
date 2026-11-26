// abstraction-provenance: {"artifact_sha256": "816b96a533399279f0b3832564821a3f06dc304451a7164cb9f3a95a755482a1", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "fsharp"}
// extract-tiktok-streamlink.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.Diagnostics
open System.Text.Json
open System.Text.RegularExpressions

let emitJson (args: string[]) =
    let keys = [| "success"; "method"; "username"; "url"; "quality"; "author"; "title"; "error"; "timestamp"; "status" |]
    let payload = ResizeArray()
    for i in 0 .. min (keys.Length - 1) (args.Length - 1) do
        if args.[i] <> "" then
            payload.Add(keys.[i], args.[i])
    let mutable successValue = false
    let successIndex = payload.FindIndex(fun kvp -> kvp.Key = "success")
    if successIndex >= 0 then
        let value = payload.[successIndex].Value
        payload.RemoveAt(successIndex)
        successValue <- value.ToLower() = "true"
        payload.Insert(successIndex, ("success", JsonSerializer.Serialize(successValue).Trim('\"')))
    let dict = dict payload
    JsonSerializer.Serialize(dict, JsonSerializerOptions(Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping))

[<EntryPoint>]
let main argv =
    let username = 
        if argv.Length > 0 && argv.[0].StartsWith("@") then 
            argv.[0].Substring(1) 
        else if argv.Length > 0 then 
            argv.[0] 
        else 
            ""
    let quality = if argv.Length > 1 then argv.[1] else "best"
    let jsonFlag = if argv.Length > 2 then argv.[2] else ""
    let timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

    if not (Regex.IsMatch(username, @"^[A-Za-z0-9._]{1,24}$")) then
        Console.Error.WriteLine("Invalid TikTok username")
        exit 64

    let validQualities = set ["best"; "worst"; "original"; "1080p60"; "720p60"; "720p"; "540p"; "360p"; "auto"]
    if not (validQualities.Contains(quality)) then
        Console.Error.WriteLine("Invalid stream quality")
        exit 64

    let loadPerCpu = 
        try
            use proc = Process.Start(ProcessStartInfo("python3", "-c \"import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))\"") |> fun psi -> 
                psi.RedirectStandardOutput <- true
                psi.UseShellExecute <- false
                psi)
            proc.WaitForExit()
            float (proc.StandardOutput.ReadToEnd().Trim())
        with _ -> 0.0

    let maxLoad = 
        match Environment.GetEnvironmentVariable("TIKTOK_MAX_LOAD_PER_CPU") with
        | null -> 1.5
        | value -> try float value with _ -> 1.5

    if loadPerCpu > maxLoad then
        let errorArgs = [| "false"; "streamlink"; username; ""; quality; ""; ""; "host overloaded"; timestamp; "overloaded" |]
        Console.Error.WriteLine(emitJson errorArgs)
        exit 75

    let streamlinkExists = 
        try
            use proc = Process.Start(ProcessStartInfo("which", "streamlink") |> fun psi -> 
                psi.RedirectStandardOutput <- true
                psi.UseShellExecute <- false)
            proc.WaitForExit()
            proc.ExitCode = 0
        with _ -> false

    if not streamlinkExists then
        let errorArgs = [| "false"; "streamlink"; username; ""; quality; ""; ""; "streamlink not installed"; timestamp; "dependency_missing" |]
        Console.Error.WriteLine(emitJson errorArgs)
        exit 2

    let liveUrl = $"https://www.tiktok.com/@{username}/live"
    let selector = 
        match quality with
        | "original" -> "origin,uhd_60,hd_60,hd,sd,ld,best,worst"
        | "auto" -> "best,origin,uhd_60,hd_60,hd,sd,ld,worst"
        | "1080p60" -> "uhd_60,hd_60,hd,sd,ld,worst"
        | "720p60" -> "hd_60,hd,sd,ld,worst"
        | "720p" -> "hd,sd,ld,worst"
        | "540p" -> "sd,ld,worst"
        | "360p" -> "ld,worst"
        | _ -> quality

    let startProcess (psi: ProcessStartInfo) =
        use proc = Process.Start(psi)
        let output = proc.StandardOutput.ReadToEnd()
        let error = proc.StandardError.ReadToEnd()
        proc.WaitForExit()
        (proc.ExitCode, output, error)

    let psiJson = ProcessStartInfo("streamlink", $"--json \"{liveUrl}\" {selector}")
    psiJson.RedirectStandardOutput <- true
    psiJson.RedirectStandardError <- true
    psiJson.UseShellExecute <- false
    let (exitCode, output, _) = startProcess psiJson

    if exitCode <> 0 || String.IsNullOrEmpty(output) then
        let psiStreamUrl = ProcessStartInfo("streamlink", $"--stream-url \"{liveUrl}\" {selector}")
        psiStreamUrl.RedirectStandardOutput <- true
        psiStreamUrl.RedirectStandardError <- true
        psiStreamUrl.UseShellExecute <- false
        let (exitCode2, url, _) = startProcess psiStreamUrl
        
        if exitCode2 <> 0 || String.IsNullOrEmpty(url) then
            let errorArgs = [| "false"; "streamlink"; username; ""; quality; ""; ""; "streamlink failed or no stream found"; timestamp; "offline" |]
            Console.Error.WriteLine(emitJson errorArgs)
            exit 1
        else
            if jsonFlag = "--json" then
                let successArgs = [| "true"; "streamlink"; username; url.Trim(); quality; ""; ""; ""; timestamp; "live" |]
                Console.WriteLine(emitJson successArgs)
            else
                Console.WriteLine(url.Trim())
            exit 0
    else
        try
            let doc = JsonDocument.Parse(output)
            let root = doc.RootElement
            let url = 
                if root.TryGetProperty("url", &_) then root.GetProperty("url").GetString() else ""
            
            let streams = 
                if root.TryGetProperty("streams", &_) then root.GetProperty("streams") else JsonElement()
            
            let mutable finalUrl = url
            if String.IsNullOrEmpty(finalUrl) && streams.ValueKind = JsonValueKind.Object then
                let streamKeys = ["best"; "worst"] @ [for prop in streams.EnumerateObject() -> prop.Name]
                for key in streamKeys do
                    if streams.TryGetProperty(key, &_) then
                        let streamObj = streams.GetProperty(key)
                        if streamObj.TryGetProperty("url", &_) then
                            finalUrl <- streamObj.GetProperty("url").GetString()
                            if not (String.IsNullOrEmpty(finalUrl)) then
                                break
            
            let author, title = "", ""
            let metadata = 
                if root.TryGetProperty("metadata", &_) then root.GetProperty("metadata") else JsonElement()
            
            if metadata.ValueKind = JsonValueKind.Object then
                let authorProp = if metadata.TryGetProperty("author", &_) then metadata.GetProperty("author").GetString() else ""
                let titleProp = if metadata.TryGetProperty("title", &_) then metadata.GetProperty("title").GetString() else ""
                (authorProp, titleProp)
            else
                ("", "")

            if String.IsNullOrEmpty(finalUrl) then
                let errorArgs = [| "false"; "streamlink"; username; ""; quality; author; title; "could not extract stream URL"; timestamp; "offline" |]
                Console.Error.WriteLine(emitJson errorArgs)
                exit 1
            else
                if jsonFlag = "--json" then
                    let successArgs = [| "true"; "streamlink"; username; finalUrl; quality; author; title; ""; timestamp; "live" |]
                    Console.WriteLine(emitJson successArgs)
                else
                    Console.WriteLine(finalUrl)
                exit 0
        with ex ->
            let errorArgs = [| "false"; "streamlink"; username; ""; quality; ""; ""; "invalid streamlink JSON"; timestamp; "technical_error" |]
            Console.Error.WriteLine(emitJson errorArgs)
            exit 2
