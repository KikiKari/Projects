#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "3b45c404747dcf7f137f4a0236e94539b8cde70e0b085b4b2a306c25e556e667", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "lua"}
-- offscreen.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
-- auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
-- auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
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
    if file then
        file:write(htmlContent)
        file:close()
        return true
    else
        return false
    end
end

if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_file>")
    os.exit(1)
end

local success = createOffscreenHTML(arg[1])
if not success then
    print("Error: Could not write to file " .. arg[1])
    os.exit(1)
end
