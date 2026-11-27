#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "6f271efb8cddb3e4e41b13a8f6144a043f9c06bfa9df9b2d103412fd1891624d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "lua"}
-- peak-limiter.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
-- auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
-- auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

-- Pegelschutz: synthetischer Web-Audio-Vergleich
-- Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.

local json = require("cjson")

-- Hilfsfunktionen
local function log10(x)
    return math.log(x) / math.log(10)
end

local function peakDb(values)
    local max_val = 1e-10
    for _, v in ipairs(values) do
        max_val = math.max(max_val, math.abs(v))
    end
    return 20 * log10(max_val)
end

local function limiterStrengthToDbfs(strength)
    return -2 - 28 * (strength / 100)
end

local function limiterMakeupCompensation(threshold, ratio)
    return -threshold * (1 - 1 / ratio)
end

local function createBuffer(length)
    local data = {}
    for i = 1, length do
        data[i] = 0
    end
    return data
end

local function renderSignal(kind, strength, legacy)
    local rate = 48000
    local length = rate
    local data = createBuffer(length)

    -- Signal generieren
    for i = 1, length do
        if kind == 'speech-band' then
            data[i] = 0.01 * math.sin(2 * math.pi * 220 * (i-1) / rate)
        elseif kind == 'short-high-tone' and i >= 5000 and i < 5100 then
            data[i] = 0.95 * math.sin(2 * math.pi * 8000 * (i-1) / rate)
        elseif kind == 'level-step' and i >= 5000 and i < 10000 then
            data[i] = 0.95 * math.sin(2 * math.pi * 1000 * (i-1) / rate)
        end
    end
    
    if kind == 'impulse' then
        data[5000] = 0.95
    end

    -- Output simulieren (vereinfacht)
    local output_data = {}
    for i = 1, length do
        output_data[i] = data[i]
    end

    -- Effekte anwenden wenn nicht null
    if strength ~= null then
        if legacy then
            -- Kompressor-Effekt simulieren
            local threshold = limiterStrengthToDbfs(strength)
            local makeup = limiterMakeupCompensation(threshold, 20)
            
            -- Vereinfachte Kompression
            for i = 1, #output_data do
                local sample = output_data[i]
                if math.abs(sample) > 10^(threshold/20) then
                    output_data[i] = (sample > 0 and 1 or -1) * 10^(threshold/20)
                end
                output_data[i] = output_data[i] * 10^(makeup/20)
            end
        else
            -- Peak-Limiter simulieren
            local limit = 10^(limiterStrengthToDbfs(strength)/20)
            for i = 1, #output_data do
                if math.abs(output_data[i]) > limit then
                    output_data[i] = (output_data[i] > 0 and 1 or -1) * limit
                end
            end
        end
    end

    local inputDbfs = peakDb(data)
    local outputDbfs = peakDb(output_data)

    return {
        kind = kind,
        strength = strength,
        path = strength == null and 'off' or legacy and '0.8.2-compressor' or 'candidate-lookahead',
        inputDbfs = inputDbfs,
        outputDbfs = outputDbfs
    }
end

local function runTest()
    print("Läuft")
    
    local rows = {}
    local test_kinds = {'impulse', 'short-high-tone', 'level-step', 'speech-band'}
    local strengths = {25, 75, 100}
    
    for _, kind in ipairs(test_kinds) do
        table.insert(rows, renderSignal(kind, null, false))
        for _, strength in ipairs(strengths) do
            table.insert(rows, renderSignal(kind, strength, true))
            table.insert(rows, renderSignal(kind, strength, false))
        end
    end
    
    -- Fehler prüfen
    local failures = {}
    for _, row in ipairs(rows) do
        if row.path == 'candidate-lookahead' then
            local limit_db = limiterStrengthToDbfs(row.strength)
            if row.outputDbfs > limit_db + 0.05 or 
               (row.kind == 'speech-band' and math.abs(row.outputDbfs - row.inputDbfs) > 0.05) then
                table.insert(failures, row)
            end
        end
    end
    
    local result = {
        passed = #failures == 0,
        failures = failures,
        rows = rows
    }
    
    return json.encode(result)
end

-- Hauptprogramm
local function main()
    local filename = arg[1]
    if not filename then
        print("Verwendung: " .. arg[0] .. " <ausgabedatei>")
        os.exit(1)
    end
    
    local html_content = [[
<!doctype html>
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
</script></html>
]]
    
    local file = io.open(filename, "w")
    if not file then
        print("Fehler: Kann Datei nicht schreiben: " .. filename)
        os.exit(1)
    end
    
    file:write(html_content)
    file:close()
    
    print("HTML-Dokument erzeugt: " .. filename)
end

main()
