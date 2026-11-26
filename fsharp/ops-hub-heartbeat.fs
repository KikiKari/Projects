// abstraction-provenance: {"artifact_sha256": "eeba1cd7ec60c11a29884d44bd0a9fffb94e63b468ed1e78d490f3fc67221646", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "fsharp"}
// ops-hub-heartbeat.js — portiert nach fsharp
// Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
// auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text.RegularExpressions

// Aktualisiere den Statusbericht mit aktueller Zeit
let statusPath = Path.Combine(__SOURCE_DIRECTORY__, "../docs/ops-hub/status.md")

let updateHeartbeat () =
    let content =
        try
            File.ReadAllText(statusPath)
        with
        | ex ->
            eprintfn "❌ Konnte status.md nicht lesen: %s" ex.Message
            Environment.Exit 1
            "" // Dieser Wert wird nie verwendet, da Exit aufgerufen wird

    let now = DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss", Globalization.CultureInfo.GetCultureInfo("de-DE"))
    let updated = Regex.Replace(content, @"(Letzter Heartbeat:) [^\n]*", "$1 " + now)

    try
        File.WriteAllText(statusPath, updated)
        printfn $"✅ Heartbeat aktualisiert: {now}"
    with
    | ex ->
        eprintfn "❌ Konnte status.md nicht schreiben: %s" ex.Message

updateHeartbeat ()
