// abstraction-provenance: {"artifact_sha256": "ddf0e1b4a22d86e718810086da114d8e7d31e9c0db4f382cbc50d91b80eec4d1", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "fsharp"}
// peak-limiter.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text
open System.Threading.Tasks

type AudioBuffer = float[]

type OfflineAudioContext(sampleRate: int, length: int, channels: int) =
    member val SampleRate = sampleRate with get
    member val Length = length with get
    member val Channels = channels with get
    
    member this.createBuffer(channels: int, length: int, rate: int) : AudioBuffer =
        Array.zeroCreate length
        
    member this.createGain() = 
        { new obj() with member x.ToString() = "GainNode" }
        
    member this.createDynamicsCompressor() = 
        { new obj() with member x.ToString() = "DynamicsCompressorNode" }

type AudioNode() = class end

type BufferSource(buffer: AudioBuffer) =
    inherit AudioNode()
    member val buffer = buffer with get, set
    member this.connect(_destination: obj) = this

module Core =
    let limiterStrengthToDbfs(strength: int) : float =
        match strength with
        | 25 -> -6.0
        | 75 -> -2.0
        | 100 -> 0.0
        | _ -> 0.0
        
    let limiterMakeupCompensation(threshold: float, ratio: float) : float =
        Math.Pow(10.0, (-threshold / ratio))
        
    let createPeakLimiterNode(_context: OfflineAudioContext) : Task<obj> =
        Task.FromResult({ new obj() with member x.ToString() = "PeakLimiterNode" })

module Math =
    let log10 x = Math.Log10(x)
    let sin x = Math.Sin(x)
    let pi = Math.PI

let peakDb (values: float[]) : float =
    let maxVal = values |> Array.fold (fun max v -> Math.Max(max, Math.Abs(v))) 1e-10
    20.0 * Math.log10 maxVal

let render (kind: string) (strength: int option) (legacy: bool) : Task<string> =
    task {
        let rate = 48000
        let length = rate
        let context = OfflineAudioContext(1, length, rate)
        let buffer = context.createBuffer(1, length, rate)
        let data = buffer
        
        for i in 0 .. length - 1 do
            if kind = "speech-band" then
                data.[i] <- 0.01 * Math.sin(2.0 * Math.pi * 220.0 * float i / float rate)
            elif kind = "short-high-tone" && i >= 5000 && i < 5100 then
                data.[i] <- 0.95 * Math.sin(2.0 * Math.pi * 8000.0 * float i / float rate)
            elif kind = "level-step" && i >= 5000 && i < 10000 then
                data.[i] <- 0.95 * Math.sin(2.0 * Math.pi * 1000.0 * float i / float rate)
                
        if kind = "impulse" then data.[5000] <- 0.95
        
        let source = BufferSource(data)
        
        if strength.IsNone then
            ignore(source.connect(context :> obj))
        elif legacy then
            let compressor = context.createDynamicsCompressor()
            let makeup = context.createGain()
            let threshold = Core.limiterStrengthToDbfs(strength.Value)
            // In real implementation these would be actual audio param settings
            ignore(source.connect(compressor))
            ignore(compressor :?> obj |> ignore)
            ignore(makeup :?> obj |> ignore)
        else
            let! node = Core.createPeakLimiterNode(context)
            ignore(source.connect(node))
            ignore(node :?> obj |> ignore)
            
        source.buffer <- data
        // Simulate rendering result
        let rendered = Array.copy data
        let inputDbfs = peakDb data
        let outputDbfs = peakDb rendered
        
        return sprintf """{"kind":"%s","strength":%s,"path":"%s","inputDbfs":%f,"outputDbfs":%f}""" 
                kind 
                (match strength with Some s -> string s | None -> "null")
                (if strength.IsNone then "off"
                 elif legacy then "0.8.2-compressor"
                 else "candidate-lookahead")
                inputDbfs
                outputDbfs
    }

let generateTestResults() : Task<string> =
    task {
        let rows = ResizeArray<string>()
        
        for kind in [| "impulse"; "short-high-tone"; "level-step"; "speech-band" |] do
            let! row1 = render kind None false
            rows.Add(row1)
            
            for strength in [| 25; 75; 100 |] do
                let! row2 = render kind (Some strength) true
                rows.Add(row2)
                let! row3 = render kind (Some strength) false
                rows.Add(row3)
                
        let failures = 
            rows 
            |> Seq.filter (fun row -> 
                row.Contains("\"path\":\"candidate-lookahead\"") &&
                (row.Contains("\"outputDbfs\":") && // Simplified check
                 not (row.Contains("\"kind\":\"speech-band\"")))) // Simplified failure logic
            |> Seq.toList
            
        return sprintf "{\n  \"passed\": %b,\n  \"failures\": [%s],\n  \"rows\": [%s]\n}" 
                (List.isEmpty failures)
                (failures |> List.map (sprintf "\n    %s") |> String.concat ",")
                (rows |> Seq.map (sprintf "\n    %s") |> String.concat ",")
    }

let generateHtml() : string =
    """<!doctype html>
<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>
<script src="../browser-extension/content-core.js"></script>
<script>
const core = TLC_CONTENT_CORE;
const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));
async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  const context = new OfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) {
    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
  }
  if (kind === 'impulse') data[5000] = 0.95;
  const source = context.createBufferSource(); source.buffer = buffer;
  if (strength === null) source.connect(context.destination);
  else if (legacy) {
    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();
    const threshold = core.limiterStrengthToDbfs(strength);
    compressor.threshold.value = threshold; compressor.knee.value = 0.5;
    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;
    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    source.connect(compressor).connect(makeup).connect(context.destination);
  } else {
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({enabled:true, strength});
    source.connect(node).connect(context.destination);
  }
  source.start();
  const rendered = await context.startRendering();
  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};
}
document.getElementById('run').onclick = async () => {
  const output = document.getElementById('result'); output.textContent = 'Läuft';
  try {
    const rows = [];
    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {
      rows.push(await render(kind, null, false));
      for (const strength of [25,75,100]) {
        rows.push(await render(kind, strength, true));
        rows.push(await render(kind, strength, false));
      }
    }
    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&
      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));
    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);
  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }
};
</script></html>"""

[<EntryPoint>]
let main argv =
    try
        let outputPath = 
            if argv.Length > 0 then argv.[0] 
            else "peak-limiter.html"
            
        let htmlContent = generateHtml()
        File.WriteAllText(outputPath, htmlContent, Encoding.UTF8)
        printfn $"HTML file generated: {outputPath}"
        0
    with ex ->
        eprintfn $"Error: {ex.Message}"
        1
