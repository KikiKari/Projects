#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "a52f64c7b4dd75ca38fac23d6c9669f78ad4cdb1c6c2e7ec0f085d5a468af112", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "lua"}
-- index_57e3e2.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_57e3e2.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Root
    table.insert(css, ":root {")
    table.insert(css, "  color-scheme: light;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Universal selector
    table.insert(css, "* {")
    table.insert(css, "  box-sizing: border-box;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Body
    table.insert(css, "body {")
    table.insert(css, "  margin: 0;")
    table.insert(css, "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;")
    table.insert(css, "  background: #f7f7f5;")
    table.insert(css, "  color: #1d1c1a;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Wrap
    table.insert(css, ".wrap {")
    table.insert(css, "  max-width: 880px;")
    table.insert(css, "  margin: 0 auto;")
    table.insert(css, "  padding: 20px 16px 60px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Headings
    table.insert(css, "h1 {")
    table.insert(css, "  font-size: 22px;")
    table.insert(css, "  margin: 0 0 2px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Sub heading
    table.insert(css, ".sub {")
    table.insert(css, "  color: #6b6a66;")
    table.insert(css, "  font-size: 13px;")
    table.insert(css, "  margin-bottom: 16px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Bar
    table.insert(css, ".bar {")
    table.insert(css, "  display: flex;")
    table.insert(css, "  gap: 10px;")
    table.insert(css, "  align-items: center;")
    table.insert(css, "  margin-bottom: 16px;")
    table.insert(css, "  flex-wrap: wrap;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Buttons
    table.insert(css, "button {")
    table.insert(css, "  font-size: 13px;")
    table.insert(css, "  font-weight: 600;")
    table.insert(css, "  padding: 7px 13px;")
    table.insert(css, "  border: 1px solid #d9d8d3;")
    table.insert(css, "  border-radius: 8px;")
    table.insert(css, "  background: #fff;")
    table.insert(css, "  cursor: pointer;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, "button:hover {")
    table.insert(css, "  background: #f2f1ec;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, "button.primary {")
    table.insert(css, "  background: #1d1c1a;")
    table.insert(css, "  color: #fff;")
    table.insert(css, "  border-color: #1d1c1a;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Note
    table.insert(css, ".note {")
    table.insert(css, "  background: #fffdf4;")
    table.insert(css, "  border: 1px solid #f0e9c8;")
    table.insert(css, "  border-radius: 10px;")
    table.insert(css, "  padding: 12px 14px;")
    table.insert(css, "  font-size: 13px;")
    table.insert(css, "  color: #4a4734;")
    table.insert(css, "  margin-bottom: 16px;")
    table.insert(css, "  line-height: 1.5;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Section
    table.insert(css, ".section {")
    table.insert(css, "  background: #fff;")
    table.insert(css, "  border: 1px solid #e8e7e3;")
    table.insert(css, "  border-radius: 12px;")
    table.insert(css, "  margin-bottom: 14px;")
    table.insert(css, "  overflow: hidden;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".section > h2 {")
    table.insert(css, "  font-size: 15px;")
    table.insert(css, "  margin: 0;")
    table.insert(css, "  padding: 13px 16px;")
    table.insert(css, "  border-bottom: 1px solid #efeee9;")
    table.insert(css, "  display: flex;")
    table.insert(css, "  align-items: center;")
    table.insert(css, "  gap: 9px;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".section > h2 .badge {")
    table.insert(css, "  margin-left: auto;")
    table.insert(css, "  font-size: 12px;")
    table.insert(css, "  font-weight: 600;")
    table.insert(css, "  background: #efeee9;")
    table.insert(css, "  color: #5a5852;")
    table.insert(css, "  padding: 2px 9px;")
    table.insert(css, "  border-radius: 20px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Body
    table.insert(css, ".body {")
    table.insert(css, "  padding: 8px 16px 14px;")
    table.insert(css, "  font-size: 14px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Muted
    table.insert(css, ".muted {")
    table.insert(css, "  color: #8a8884;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Error
    table.insert(css, ".err {")
    table.insert(css, "  color: #c0392b;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Key-value pairs
    table.insert(css, ".kv {")
    table.insert(css, "  display: flex;")
    table.insert(css, "  justify-content: space-between;")
    table.insert(css, "  padding: 4px 0;")
    table.insert(css, "  border-bottom: 1px solid #f4f3ee;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".kv:last-child {")
    table.insert(css, "  border: none;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".kv .k {")
    table.insert(css, "  color: #6b6a66;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".kv .v {")
    table.insert(css, "  font-weight: 600;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Links
    table.insert(css, "a {")
    table.insert(css, "  color: #2b5cc4;")
    table.insert(css, "  text-decoration: none;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, "a:hover {")
    table.insert(css, "  text-decoration: underline;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Modal
    table.insert(css, ".modal {")
    table.insert(css, "  position: fixed;")
    table.insert(css, "  inset: 0;")
    table.insert(css, "  background: rgba(0, 0, 0, .35);")
    table.insert(css, "  display: none;")
    table.insert(css, "  align-items: flex-start;")
    table.insert(css, "  justify-content: center;")
    table.insert(css, "  padding: 40px 16px;")
    table.insert(css, "  overflow: auto;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".modal.open {")
    table.insert(css, "  display: flex;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Card
    table.insert(css, ".card {")
    table.insert(css, "  background: #fff;")
    table.insert(css, "  border-radius: 14px;")
    table.insert(css, "  max-width: 560px;")
    table.insert(css, "  width: 100%;")
    table.insert(css, "  padding: 20px;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".card h3 {")
    table.insert(css, "  margin: 0 0 4px;")
    table.insert(css, "  font-size: 17px;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".card p.hint {")
    table.insert(css, "  margin: 0 0 16px;")
    table.insert(css, "  font-size: 12px;")
    table.insert(css, "  color: #8a8884;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Field
    table.insert(css, ".field {")
    table.insert(css, "  margin-bottom: 12px;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".field label {")
    table.insert(css, "  display: block;")
    table.insert(css, "  font-size: 12px;")
    table.insert(css, "  font-weight: 600;")
    table.insert(css, "  color: #5a5852;")
    table.insert(css, "  margin-bottom: 3px;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".field input {")
    table.insert(css, "  width: 100%;")
    table.insert(css, "  font-size: 13px;")
    table.insert(css, "  padding: 7px 9px;")
    table.insert(css, "  border: 1px solid #d9d8d3;")
    table.insert(css, "  border-radius: 7px;")
    table.insert(css, "  font-family: ui-monospace, Menlo, monospace;")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, ".field .desc {")
    table.insert(css, "  font-size: 11px;")
    table.insert(css, "  color: #a8a6a1;")
    table.insert(css, "  margin-top: 2px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Actions
    table.insert(css, ".actions {")
    table.insert(css, "  display: flex;")
    table.insert(css, "  gap: 10px;")
    table.insert(css, "  justify-content: flex-end;")
    table.insert(css, "  margin-top: 8px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Warning
    table.insert(css, ".warn {")
    table.insert(css, "  background: #fdf3f3;")
    table.insert(css, "  border: 1px solid #f3d9d9;")
    table.insert(css, "  color: #9a3b3b;")
    table.insert(css, "  border-radius: 8px;")
    table.insert(css, "  padding: 10px 12px;")
    table.insert(css, "  font-size: 12px;")
    table.insert(css, "  margin-bottom: 14px;")
    table.insert(css, "}")

    return table.concat(css, "\n")
end

local function write_css_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file " .. filename .. " for writing")
    end
    
    file:write(generate_css())
    file:close()
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_filename>")
    os.exit(1)
end

local output_filename = arg[1]
write_css_to_file(output_filename)
