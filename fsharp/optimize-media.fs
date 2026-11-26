// abstraction-provenance: {"artifact_sha256": "e8de62ebeea775f4ad6405ad3a5c43d1d738492c5982b85c9f36657272a9ec57", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "fsharp"}
// optimize-media.mjs — portiert nach fsharp
// Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Threading.Tasks
open FSharp.Control.Tasks

// Sharp-Instanz für Bildverarbeitung
let sharp = SharpLib.Sharp

let directory = Path.Combine(__SOURCE_DIRECTORY__, "../public/media/")

let convertImage file =
    task {
        if not (file.EndsWith(".png")) then
            return ()
        else
            let stem = Path.GetFileNameWithoutExtension(file)
            let sourcePath = Path.Combine(directory, file)
            
            // WebP-Konvertierung
            do! sharp(sourcePath)
                .WebP(quality = 84)
                .ToFileAsync(Path.Combine(directory, $"{stem}.webp"))
            
            // AVIF-Konvertierung
            do! sharp(sourcePath)
                .Avif(quality = 58)
                .ToFileAsync(Path.Combine(directory, $"{stem}.avif"))
    }

[<EntryPoint>]
let main argv =
    task {
        let files = Directory.GetFiles(directory, "*.png") |> Array.map Path.GetFileName
        
        do! files |> Array.map convertImage |> Task.WhenAll |> Task.Ignore
        
        printfn "WebP- und AVIF-Derivate erzeugt."
        return 0
    }
    |> Async.AwaitTask
    |> Async.RunSynchronously
