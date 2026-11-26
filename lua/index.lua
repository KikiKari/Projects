#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "90e6df73c1d5da49b850cc2e3e2c5c8fecd5b3edf2ed73eda567f6731bbfc63d", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "lua"}
-- index.css — portiert nach lua
-- Quelle: css, OpenClaw@main:src/index.css
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Add body styles
    table.insert(css, "body {")
    table.insert(css, "  margin: 0;")
    table.insert(css, "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',")
    table.insert(css, "    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',")
    table.insert(css, "    sans-serif;")
    table.insert(css, "  -webkit-font-smoothing: antialiased;")
    table.insert(css, "  -moz-osx-font-smoothing: grayscale;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Add code styles
    table.insert(css, "code {")
    table.insert(css, "  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',")
    table.insert(css, "    monospace;")
    table.insert(css, "}")

    return table.concat(css, "\n")
end

local function write_css_to_file(filename)
    local content = generate_css()
    local file = io.open(filename, "w")
    if file then
        file:write(content)
        file:close()
        return true
    else
        return false
    end
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_filename>")
    os.exit(1)
end

local output_filename = arg[1]
if write_css_to_file(output_filename) then
    print("CSS file generated successfully: " .. output_filename)
else
    print("Error: Could not write to file " .. output_filename)
    os.exit(1)
end
