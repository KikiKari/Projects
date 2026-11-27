// abstraction-provenance: {"artifact_sha256": "f2fce4bdbb94273a10f774465366419dd5320afcfcc6e775fa4eb7292c4af516", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "fsharp"}
// peak-limiter.html — portiert nach fsharp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text
open System.Threading.Tasks

// Helper functions
let log10 x = Math.Log10 x
let sin x = Math.Sin x
let pi = Math.PI
let max a b = Math.Max(a, b)
let abs x = Math.Abs x

// Simulated core module functions
module Core =
    let limiterStrengthToDbfs strength =
        -0.01 * float strength

    let limiterMakeupCompensation threshold ratio =
        if threshold < -60. then 1. else 10. ** (threshold /. 20.)

    let createPeakLimiterNode (_context: obj) =
        // In real implementation this would create an actual audio node
        // For simulation we just return a task that completes immediately
        Task.FromResult(obj())

    type LimiterProtection = { enabled: bool; strength: int }

// Audio rendering simulation
type RenderResult = {
    kind: string
    strength: int option
    path: string
    inputDbfs: float
    outputDbfs: float
}

let peakDb (values: float[]) =
    let maxVal = values |> Array.fold (fun acc v -> max acc (abs v)) 1e-10
    20. * log10 maxVal

let render (kind: string) (strength: int option) (legacy: bool) =
    async {
        let rate = 48000
        let length = rate
        let data = Array.zeroCreate<float> length
        
        // Generate test signal based on kind
        for i in 0 .. length - 1 do
            if kind = "speech-band" then
                data.[i] <- 0.01 * sin(2. * pi * 220. * float i / float rate)
            elif kind = "short-high-tone" && i >= 5000 && i < 5100 then
                data.[i] <- 0.95 * sin(2. * pi * 8000. * float i / float rate)
            elif kind = "level-step" && i >= 5000 && i < 10000 then
                data.[i] <- 0.95 * sin(2. * pi * 1000. * float i / float rate)
        
        if kind = "impulse" then
            data.[5000] <- 0.95
            
        // Process through limiter/compressor simulation
        let processedData = 
            match strength with
            | None -> data // No processing
            | Some str ->
                if legacy then
                    // Compressor simulation
                    let threshold = Core.limiterStrengthToDbfs str
                    // Simplified compression model - in reality this would be more complex
                    data |> Array.map (fun v -> 
                        let db = 20. * log10(abs v)
                        if db > threshold then
                            let compressedDb = threshold + (db - threshold) / 20.
                            let sign = if v >= 0. then 1. else -1.
                            sign * (10. ** (compressedDb / 20.))
                        else v)
                else
                    // Peak limiter simulation
                    let limit = 10. ** (Core.limiterStrengthToDbfs str / 20.)
                    data |> Array.map (fun v -> 
                        if abs v > limit then
                            let sign = if v >= 0. then 1. else -1.
                            sign * limit
                        else v)

        let path = 
            match strength with
            | None -> "off"
            | Some _ when legacy -> "0.8.2-compressor"
            | Some _ -> "candidate-lookahead"

        return {
            kind = kind
            strength = strength
            path = path
            inputDbfs = peakDb data
            outputDbfs = peakDb processedData
        }
    }

let runTest () =
    async {
        try
            let! rows = 
                ["impulse"; "short-high-tone"; "level-step"; "speech-band"]
                |> List.collect (fun kind ->
                    [render kind None false] @
                    [25; 75; 100] 
                    |> List.collect (fun strength -> 
                        [render kind (Some strength) true; render kind (Some strength) false]))
                |> Async.Parallel
                
            let failures = 
                rows 
                |> Array.filter (fun row -> 
                    row.path = "candidate-lookahead" &&
                    (row.outputDbfs > (match row.strength with 
                                       | Some s -> Core.limiterStrengthToDbfs s 
                                       | None -> 0.) + 0.05 ||
                     (row.kind = "speech-band" && abs(row.outputDbfs - row.inputDbfs) > 0.05)))
                
            let passed = failures.Length = 0
            
            return {| passed = passed; failures = failures; rows = rows |}
        with
        | ex -> 
            return failwith ("FEHLER: " + ex.Message + ex.StackTrace)
    }

let generateHtml () =
    let sb = StringBuilder()
    sb.Append("<!doctype html>") |> ignore
    sb.Append("<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>") |> ignore
    sb.Append("<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>") |> ignore
    sb.Append("<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>") |> ignore
    sb.Append("<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>") |> ignore
    sb.Append("<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>") |> ignore
    sb.Append("<script src=\"../browser-extension/content-core.js\"></script>") |> ignore
    sb.Append("<script>") |> ignore
    sb.Append("const core = TLC_CONTENT_CORE;") |> ignore
    sb.Append("const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));") |> ignore
    sb.Append("async function render(kind, strength, legacy) {") |> ignore
    sb.Append("  const rate = 48000, length = rate;") |> ignore
    sb.Append("  const context = new OfflineAudioContext(1, length, rate);") |> ignore
    sb.Append("  const buffer = context.createBuffer(1, length, rate);") |> ignore
    sb.Append("  const data = buffer.getChannelData(0);") |> ignore
    sb.Append("  for (let i = 0; i < length; i++) {") |> ignore
    sb.Append("    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);") |> ignore
    sb.Append("    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);") |> ignore
    sb.Append("    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);") |> ignore
    sb.Append("  }") |> ignore
    sb.Append("  if (kind === 'impulse') data[5000] = 0.95;") |> ignore
    sb.Append("  const source = context.createBufferSource(); source.buffer = buffer;") |> ignore
    sb.Append("  if (strength === null) source.connect(context.destination);") |> ignore
    sb.Append("  else if (legacy) {") |> ignore
    sb.Append("    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();") |> ignore
    sb.Append("    const threshold = core.limiterStrengthToDbfs(strength);") |> ignore
    sb.Append("    compressor.threshold.value = threshold; compressor.knee.value = 0.5;") |> ignore
    sb.Append("    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;") |> ignore
    sb.Append("    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);") |> ignore
    sb.Append("    source.connect(compressor).connect(makeup).connect(context.destination);") |> ignore
    sb.Append("  } else {") |> ignore
    sb.Append("    const node = await core.createPeakLimiterNode(context);") |> ignore
    sb.Append("    node.setProtection({enabled:true, strength});") |> ignore
    sb.Append("    source.connect(node).connect(context.destination);") |> ignore
    sb.Append("  }") |> ignore
    sb.Append("  source.start();") |> ignore
    sb.Append("  const rendered = await context.startRendering();") |> ignore
    sb.Append("  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',") |> ignore
    sb.Append("    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};") |> ignore
    sb.Append("}") |> ignore
    sb.Append("document.getElementById('run').onclick = async () => {") |> ignore
    sb.Append("  const output = document.getElementById('result'); output.textContent = 'Läuft';") |> ignore
    sb.Append("  try {") |> ignore
    sb.Append("    const rows = [];") |> ignore
    sb.Append("    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {") |> ignore
    sb.Append("      rows.push(await render(kind, null, false));") |> ignore
    sb.Append("      for (const strength of [25,75,100]) {") |> ignore
    sb.Append("        rows.push(await render(kind, strength, true));") |> ignore
    sb.Append("        rows.push(await render(kind, strength, false));") |> ignore
    sb.Append("      }") |> ignore
    sb.Append("    }") |> ignore
    sb.Append("    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&") |> ignore
    sb.Append("      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||") |> ignore
    sb.Append("       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));") |> ignore
    sb.Append("    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);") |> ignore
    sb.Append("  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }") |> ignore
    sb.Append("};") |> ignore
    sb.Append("</script></html>") |> ignore
    sb.ToString()

[<EntryPoint>]
let main argv =
    if argv.Length > 0 then
        let outputPath = argv.[0]
        let htmlContent = generateHtml()
        File.WriteAllText(outputPath, htmlContent)
        printfn "HTML file generated at %s" outputPath
    else
        printfn "Usage: program <output-file-path>"
    0
