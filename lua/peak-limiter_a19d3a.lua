#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "16e00f4399c5102592e85f1d7ae473e66ff7d42b8e184160558f7705e7893707", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "lua"}
-- peak-limiter.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/peak-limiter.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function write_css_to_file(filename)
    local css_content = [[
/* abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

body {
  font: 16px system-ui;
  max-width: 1000px;
  margin: 40px auto;
  padding: 20px;
}

pre {
  white-space: pre-wrap;
}

button {
  padding: 12px;
}
]]

    local file = io.open(filename, "w")
    if not file then
        error("Could not open file " .. filename .. " for writing")
    end
    
    file:write(css_content)
    file:close()
end

-- Wenn ein Argument übergeben wurde, verwenden wir es als Dateinamen
if #arg > 0 then
    write_css_to_file(arg[1])
else
    -- Standardmäßig in "peak-limiter.css" schreiben
    write_css_to_file("peak-limiter.css")
end
