#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "73dbd30dceaf31f69bc023b7ac6d7a5577bd82c2c7eace48982a8119c4a125ed", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "lua"}
-- offscreen.html — portiert nach lua
-- Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function createOffscreenHTML(outputFile)
    local htmlContent = [[<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>]]

    local file = io.open(outputFile, "w")
    if not file then
        error("Could not open file for writing: " .. outputFile)
    end
    
    file:write(htmlContent)
    file:close()
    
    print("Offscreen HTML document created successfully: " .. outputFile)
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output-file>")
    os.exit(1)
end

local outputFile = arg[1]
createOffscreenHTML(outputFile)
