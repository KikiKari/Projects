#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "2513741a1bb76954d238fc06dce1ad7c0cacdd68a245dcc814688bc490832241", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "lua"}
-- peak-limiter.html — portiert nach lua
-- Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local json = require("cjson")

-- Function to simulate limiterStrengthToDbfs
local function limiterStrengthToDbfs(strength)
    return -20 + (strength / 100) * 20
end

-- Function to simulate limiterMakeupCompensation
local function limiterMakeupCompensation(threshold, ratio)
    return -(threshold * (1 - 1/ratio))
end

-- Peak level calculation in dBFS
local function peakDb(values)
    local max_val = 1e-10
    for _, v in ipairs(values) do
        max_val = math.max(max_val, math.abs(v))
    end
    return 20 * math.log(max_val, 10)
end

-- Render audio signal with optional processing
local function render(kind, strength, legacy)
    local rate = 48000
    local length = rate
    local data = {}

    -- Generate test signal based on kind
    for i = 1, length do
        data[i] = 0
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

    -- Simulate processing chain
    local processed_data = {}
    for i = 1, #data do
        processed_data[i] = data[i]
    end

    -- Apply dynamics processing if enabled
    if strength ~= nil then
        if legacy then
            -- Simulate compressor behavior
            local threshold = limiterStrengthToDbfs(strength)
            local makeup_gain = limiterMakeupCompensation(threshold, 20)
            
            -- Simple gain reduction simulation
            for i = 1, #processed_data do
                local sample = processed_data[i]
                if math.abs(sample) > 10^(threshold/20) then
                    processed_data[i] = sample * 10^(makeup_gain/20)
                end
            end
        else
            -- Simulate lookahead limiter behavior
            local limit_threshold = 10^(limiterStrengthToDbfs(strength)/20)
            for i = 1, #processed_data do
                if math.abs(processed_data[i]) > limit_threshold then
                    processed_data[i] = limit_threshold * (processed_data[i] > 0 and 1 or -1)
                end
            end
        end
    end

    -- Return results
    local path
    if strength == nil then
        path = 'off'
    elseif legacy then
        path = '0.8.2-compressor'
    else
        path = 'candidate-lookahead'
    end

    return {
        kind = kind,
        strength = strength,
        path = path,
        inputDbfs = peakDb(data),
        outputDbfs = peakDb(processed_data)
    }
end

-- Main execution function
local function runTest()
    print("Running audio tests...")
    local rows = {}
    
    -- Test all combinations
    local kinds = {'impulse', 'short-high-tone', 'level-step', 'speech-band'}
    local strengths = {25, 75, 100}
    
    for _, kind in ipairs(kinds) do
        table.insert(rows, render(kind, nil, false))
        for _, strength in ipairs(strengths) do
            table.insert(rows, render(kind, strength, true))
            table.insert(rows, render(kind, strength, false))
        end
    end
    
    -- Check for failures
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
    
    -- Output results
    local result = {
        passed = #failures == 0,
        failures = failures,
        rows = rows
    }
    
    return json.encode(result, {indent = true})
end

-- Write HTML file
local function writeHTML(filename)
    local f = io.open(filename, "w")
    
    f:write([[<!doctype html>
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
</script></html>]])
    
    f:close()
    print("HTML file written to " .. filename)
end

-- Main program
if #arg ~= 1 then
    print("Usage: lua " .. arg[0] .. " <output-file>")
    os.exit(1)
end

writeHTML(arg[1])
