#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "7d5994f5ffd2d5ab7e6490a2f0daad0ecbc4ede86d632b3c07513469742e0fbf", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "lua"}
-- peak-limiter_4ced2c.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function write_css_to_file(filename)
    local file = io.open(filename, "w")
    
    if not file then
        error("Cannot open file '" .. filename .. "' for writing")
    end

    -- Write the CSS content
    file:write([[
/* abstraction-provenance: {"artifact_sha256": "c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */
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
]])
    
    file:close()
end

-- Check if a filename argument is provided
if #arg < 1 then
    print("Usage: " .. arg[0] .. " <output_filename>")
    os.exit(1)
end

-- Write CSS to the specified file
write_css_to_file(arg[1])
