// abstraction-provenance: {"artifact_sha256": "3abb67bf8ac22a041cbacaa0462783c8e3f4f84908f26856716c5782521c1e96", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "fsharp"}
// generate-elevenlabs.mjs — portiert nach fsharp
// Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Net.Http
open System.Text
open System.Text.Json
open System.Threading.Tasks

let key = 
    match Environment.GetEnvironmentVariable("ELEVENLABS_API_KEY") with
    | null -> failwith "ELEVENLABS_API_KEY fehlt."
    | k -> k

let voiceId = 
    match Environment.GetEnvironmentVariable("ELEVENLABS_VOICE_ID") with
    | null -> "JBFqnCBsd6RMkjVDRZzb"
    | id -> id

let text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

let client = new HttpClient()

let jsonBody = 
    JsonSerializer.Serialize({|
        text = text
        model_id = "eleven_multilingual_v2"
        voice_settings = {|
            stability = 0.58
            similarity_boost = 0.72
            style = 0.18
            use_speaker_boost = true
        |}
    |})

let request = new HttpRequestMessage(HttpMethod.Post, $"https://api.elevenlabs.io/v1/text-to-speech/{voiceId}?output_format=mp3_44100_128")
request.Headers.Add("xi-api-key", key)
request.Content <- new StringContent(jsonBody, Encoding.UTF8, "application/json")

let! response = client.SendAsync(request)

if not response.IsSuccessStatusCode then
    failwith $"ElevenLabs fehlgeschlagen: {response.StatusCode}"

let! audioBytes = response.Content.ReadAsByteArrayAsync()

let baseDir = __SOURCE_DIRECTORY__
let audioDir = Path.Combine(baseDir, "..", "public", "audio")
let audioPath = Path.Combine(audioDir, "project-narration.mp3")
let resultPath = Path.Combine(baseDir, "..", "media-production", "elevenlabs-result.json")

Directory.CreateDirectory(audioDir) |> ignore

File.WriteAllBytes(audioPath, audioBytes)

let resultJson = 
    JsonSerializer.Serialize({|
        model = "eleven_multilingual_v2"
        voiceId = voiceId
        characters = text.Length
        text = text
        output = "public/audio/project-narration.mp3"
    |}, JsonSerializerOptions(WriteIndented = true))

File.WriteAllText(resultPath, resultJson)

printfn $"ElevenLabs abgeschlossen: {text.Length} Zeichen."
