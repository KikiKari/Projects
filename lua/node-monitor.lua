#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "5ef8afb9318a067cc1b1058a699b5a7a96403d059d21c497e27d979d968c31fe", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "lua"}
-- node-monitor.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/node-monitor.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function write_css_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end

    -- Write the CSS content programmatically
    file:write("/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */\n")
    file:write("/* node-monitor.html — portiert nach css */\n")
    file:write("/* Quelle: html, OpenClaw@main:examples/node-monitor.html */\n")
    file:write("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n")

    file:write(":root {\n")
    file:write("  --bg: #0d1117;\n")
    file:write("  --surface: #161b22;\n")
    file:write("  --border: #30363d;\n")
    file:write("  --text: #e6edf3;\n")
    file:write("  --green: #3fb950;\n")
    file:write("  --red: #f85149;\n")
    file:write("  --accent: #58a6ff;\n")
    file:write("}\n\n")

    file:write("* {\n")
    file:write("  box-sizing: border-box;\n")
    file:write("  margin: 0;\n")
    file:write("  padding: 0;\n")
    file:write("}\n\n")

    file:write("body {\n")
    file:write("  background: var(--bg);\n")
    file:write("  color: var(--text);\n")
    file:write("  font-family: -apple-system, sans-serif;\n")
    file:write("  padding: 1.5rem;\n")
    file:write("}\n\n")

    file:write("h1 {\n")
    file:write("  color: var(--accent);\n")
    file:write("  margin-bottom: 1rem;\n")
    file:write("  font-size: 1.2rem;\n")
    file:write("}\n\n")

    file:write("canvas {\n")
    file:write("  display: block;\n")
    file:write("  border: 1px solid var(--border);\n")
    file:write("  border-radius: 8px;\n")
    file:write("  background: var(--surface);\n")
    file:write("}\n\n")

    file:write("#log {\n")
    file:write("  margin-top: 1rem;\n")
    file:write("  height: 140px;\n")
    file:write("  overflow-y: auto;\n")
    file:write("  background: var(--surface);\n")
    file:write("  border: 1px solid var(--border);\n")
    file:write("  border-radius: 8px;\n")
    file:write("  padding: .75rem;\n")
    file:write("  font-size: .78rem;\n")
    file:write("  font-family: monospace;\n")
    file:write("  color: #8b949e;\n")
    file:write("}\n\n")

    file:write("#log .err {\n")
    file:write("  color: var(--red);\n")
    file:write("}\n\n")

    file:write("#log .ok {\n")
    file:write("  color: var(--green);\n")
    file:write("}\n")

    file:close()
end

-- Check command line argument
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output-file>")
    os.exit(1)
end

-- Generate CSS file
write_css_to_file(arg[1])
