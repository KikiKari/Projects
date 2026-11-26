// abstraction-provenance: {"artifact_sha256": "cbf08749e923ca4f26dbedf1a576738d4268e3048ad351f77cbe3f8ac861c1b3", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "fsharp"}
// generate-wavespeed.mjs — portiert nach fsharp
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Net.Http
open System.Text
open System.Text.Json
open System.Threading.Tasks

let key = 
    match Environment.GetEnvironmentVariable("WAVESPEED_API_KEY") with
    | null -> failwith "WAVESPEED_API_KEY fehlt."
    | k -> k

let baseDir = __SOURCE_DIRECTORY__
let mediaProductionDir = Path.Combine(baseDir, "..", "media-production")
let rawDir = Path.Combine(mediaProductionDir, "raw")
let publicDir = Path.Combine(baseDir, "..", "public", "media")
let jobsFile = Path.Combine(mediaProductionDir, "wavespeed-jobs.json")
let resultsFile = Path.Combine(mediaProductionDir, "wavespeed-results.json")

Directory.CreateDirectory(rawDir) |> ignore
Directory.CreateDirectory(publicDir) |> ignore

type Job = {
    id: string
    output: string
    prompt: string
    images: string[]
    aspectRatio: string
}

type LogEntry = {
    id: string
    requestId: string
    model: string
    resolution: string
    plannedCostUsd: float
    output: string
}

let deserializeJson<'T> (json: string) : 'T =
    JsonSerializer.Deserialize<'T>(json, JsonSerializerOptions(PropertyNameCaseInsensitive = true))

let serializeJson (obj: obj) : string =
    JsonSerializer.Serialize(obj, JsonSerializerOptions(WriteIndented = true))

let readJsonFile<'T> filePath =
    File.ReadAllText(filePath) |> deserializeJson<'T>

let writeJsonFile filePath (data: obj) =
    serializeJson data |> fun json -> File.WriteAllText(filePath, json)

let jobs: Job[] = readJsonFile<Job[]> jobsFile

let mutable log: LogEntry[] = 
    try
        readJsonFile<LogEntry[]> resultsFile
    with
    | _ -> [||]

let client = new HttpClient()

let isBase64String (str: string) =
    str.StartsWith("data:") || Uri.IsWellFormedUriString(str, UriKind.Absolute)

let rec waitForResult requestId attempts =
    async {
        do! Async.Sleep(4000)
        let request = new HttpRequestMessage(HttpMethod.Get, $"https://api.wavespeed.ai/api/v3/predictions/{requestId}/result")
        request.Headers.Add("Authorization", $"Bearer {key}")
        let! response = client.SendAsync(request) |> Async.AwaitTask
        let! content = response.Content.ReadAsStringAsync() |> Async.AwaitTask
        let result = JsonDocument.Parse(content).RootElement
        let status = 
            match result.TryGetProperty("data", &_) with
            | true when result.GetProperty("data").TryGetProperty("status", &_) ->
                result.GetProperty("data").GetProperty("status").GetString()
            | _ -> ""
        
        match status with
        | "completed" -> return result
        | "failed" -> failwith $"WaveSpeed job fehlgeschlagen: {requestId}"
        | _ when attempts >= 90 -> failwith $"Timeout beim Warten auf Ergebnis: {requestId}"
        | _ -> return! waitForResult requestId (attempts + 1)
    }

async {
    for job in jobs do
        let rawPath = Path.Combine(rawDir, $"{job.id}.png")
        let targetPath = Path.Combine(publicDir, $"{job.output}.png")
        
        if File.Exists(rawPath) then
            if not (Array.exists (fun (entry: LogEntry) -> entry.id = job.id) log) then
                let newEntry = {
                    id = job.id
                    requestId = "completed-before-resume"
                    model = "google/nano-banana-2/edit"
                    resolution = "4k"
                    plannedCostUsd = 0.14
                    output = Path.GetFileName(targetPath)
                }
                log <- Array.append log [|newEntry|]
                writeJsonFile resultsFile log
            printfn $"Übersprungen: {job.id} ist bereits vorhanden."
        else
            let imageTasks = 
                job.images 
                |> Array.map (fun image ->
                    async {
                        if isBase64String image then
                            return image
                        else
                            let imagePath = Path.Combine(baseDir, "..", image)
                            let bytes = File.ReadAllBytes(imagePath)
                            return $"data:image/png;base64,{Convert.ToBase64String(bytes)}"
                    })
            
            let! imageData = imageTasks |> Async.Parallel
            
            let payload = {| 
                prompt = job.prompt
                images = imageData
                aspect_ratio = job.aspectRatio
                resolution = "4k"
                output_format = "png"
                enable_web_search = false
                enable_image_search = false
                enable_sync_mode = false
                enable_base64_output = false
            |}
            
            let jsonPayload = JsonSerializer.Serialize(payload)
            let content = new StringContent(jsonPayload, Encoding.UTF8, "application/json")
            
            let request = new HttpRequestMessage(HttpMethod.Post, "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit")
            request.Headers.Add("Authorization", $"Bearer {key}")
            request.Content <- content
            
            let! response = client.SendAsync(request) |> Async.AwaitTask
            let! responseContent = response.Content.ReadAsStringAsync() |> Async.AwaitTask
            
            if not response.IsSuccessStatusCode then
                failwith $"WaveSpeed submit fehlgeschlagen: {response.StatusCode} {responseContent}"
            
            let responseJson = JsonDocument.Parse(responseContent).RootElement
            let requestId = 
                match responseJson.TryGetProperty("data", &_) with
                | true when responseJson.GetProperty("data").TryGetProperty("id", &_) ->
                    responseJson.GetProperty("data").GetProperty("id").GetString()
                | _ when responseJson.TryGetProperty("id", &_) ->
                    responseJson.GetProperty("id").GetString()
                | _ -> ""
            
            let! result = waitForResult requestId 0
            let imageUrl = 
                match result.TryGetProperty("data", &_) with
                | true when result.GetProperty("data").TryGetProperty("outputs", &_) ->
                    let outputs = result.GetProperty("data").GetProperty("outputs")
                    if outputs.GetArrayLength() > 0 then
                        outputs.[0].GetString()
                    else ""
                | _ -> ""
            
            if String.IsNullOrEmpty(imageUrl) then
                failwith $"Kein Output für {job.id}"
            
            let! imageResponse = client.GetAsync(imageUrl) |> Async.AwaitTask
            let! imageBytes = imageResponse.Content.ReadAsByteArrayAsync() |> Async.AwaitTask
            
            File.WriteAllBytes(rawPath, imageBytes)
            File.WriteAllBytes(targetPath, imageBytes)
            
            let newEntry = {
                id = job.id
                requestId = requestId
                model = "google/nano-banana-2/edit"
                resolution = "4k"
                plannedCostUsd = 0.14
                output = Path.GetFileName(targetPath)
            }
            
            log <- Array.append log [|newEntry|]
            writeJsonFile resultsFile log
            printfn $"Abgeschlossen: {job.id}"
    
    writeJsonFile resultsFile log
    printfn $"WaveSpeed abgeschlossen: {log.Length} Assets, geplante Basiskosten ${(float log.Length * 0.14).ToString("F2")}."

} |> Async.RunSynchronously
