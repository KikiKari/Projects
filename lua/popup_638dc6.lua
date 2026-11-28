#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "b40751e451aaa26cc3295d5e405cdb8dbd1773a0597039326fecf92081162cb8", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "lua"}
-- popup.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/popup.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function write_popup_css(output_file)
    local css_content = {}

    -- Root variables for dark theme
    table.insert(css_content, ":root {")
    table.insert(css_content, "  --bg: #0f1115;")
    table.insert(css_content, "  --card: #171a21;")
    table.insert(css_content, "  --line: #262b36;")
    table.insert(css_content, "  --text: #f2f4f8;")
    table.insert(css_content, "  --muted: #9aa3b2;")
    table.insert(css_content, "  --accent: #fe2c55;")
    table.insert(css_content, "  --ok: #22c55e;")
    table.insert(css_content, "  color-scheme: dark;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Light theme media query
    table.insert(css_content, "@media (prefers-color-scheme: light) {")
    table.insert(css_content, "  :root {")
    table.insert(css_content, "    --bg: #fff;")
    table.insert(css_content, "    --card: #f6f7f9;")
    table.insert(css_content, "    --line: #e3e6ea;")
    table.insert(css_content, "    --text: #16191d;")
    table.insert(css_content, "    --muted: #6b7280;")
    table.insert(css_content, "  }")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Universal selector
    table.insert(css_content, "* {")
    table.insert(css_content, "  box-sizing: border-box;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Body styles
    table.insert(css_content, "body {")
    table.insert(css_content, "  margin: 0;")
    table.insert(css_content, "  width: 420px;")
    table.insert(css_content, "  max-height: 600px;")
    table.insert(css_content, "  overflow: auto;")
    table.insert(css_content, "  background: var(--bg);")
    table.insert(css_content, "  color: var(--text);")
    table.insert(css_content, "  font: 14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Wrap class
    table.insert(css_content, ".wrap {")
    table.insert(css_content, "  padding: 12px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Header styles
    table.insert(css_content, "header {")
    table.insert(css_content, "  display: flex;")
    table.insert(css_content, "  gap: 8px;")
    table.insert(css_content, "  align-items: center;")
    table.insert(css_content, "  margin-bottom: 10px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Heading styles
    table.insert(css_content, "h1 {")
    table.insert(css_content, "  font-size: 14px;")
    table.insert(css_content, "  margin: 0;")
    table.insert(css_content, "  font-weight: 650;")
    table.insert(css_content, "  flex: 1;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Badge styles
    table.insert(css_content, ".badge {")
    table.insert(css_content, "  font-size: 11px;")
    table.insert(css_content, "  font-weight: 700;")
    table.insert(css_content, "  padding: 3px 9px;")
    table.insert(css_content, "  border-radius: 99px;")
    table.insert(css_content, "  background: #2a2f3a;")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  display: inline-flex;")
    table.insert(css_content, "  align-items: center;")
    table.insert(css_content, "  gap: 5px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".badge.live {")
    table.insert(css_content, "  background: var(--accent);")
    table.insert(css_content, "  color: #fff;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".badge .dot {")
    table.insert(css_content, "  width: 6px;")
    table.insert(css_content, "  height: 6px;")
    table.insert(css_content, "  border-radius: 50%;")
    table.insert(css_content, "  background: currentColor;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".badge.live .dot {")
    table.insert(css_content, "  animation: pulse 1.6s infinite;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Keyframes for pulse animation
    table.insert(css_content, "@keyframes pulse {")
    table.insert(css_content, "  0%, 100% {")
    table.insert(css_content, "    opacity: 1;")
    table.insert(css_content, "  }")
    table.insert(css_content, "  50% {")
    table.insert(css_content, "    opacity: .25;")
    table.insert(css_content, "  }")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Row styles
    table.insert(css_content, ".row {")
    table.insert(css_content, "  display: flex;")
    table.insert(css_content, "  gap: 6px;")
    table.insert(css_content, "  flex-wrap: wrap;")
    table.insert(css_content, "  align-items: center;")
    table.insert(css_content, "  margin-bottom: 8px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Input, select, button styles
    table.insert(css_content, "input, select, button {")
    table.insert(css_content, "  font: inherit;")
    table.insert(css_content, "  border-radius: 7px;")
    table.insert(css_content, "  border: 1px solid var(--line);")
    table.insert(css_content, "  background: var(--card);")
    table.insert(css_content, "  color: var(--text);")
    table.insert(css_content, "  padding: 6px 9px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, "button {")
    table.insert(css_content, "  cursor: pointer;")
    table.insert(css_content, "  font-weight: 600;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, "button.primary {")
    table.insert(css_content, "  background: var(--accent);")
    table.insert(css_content, "  border-color: var(--accent);")
    table.insert(css_content, "  color: #fff;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Player styles
    table.insert(css_content, ".player {")
    table.insert(css_content, "  position: relative;")
    table.insert(css_content, "  width: 100%;")
    table.insert(css_content, "  aspect-ratio: 9/16;")
    table.insert(css_content, "  max-height: 360px;")
    table.insert(css_content, "  background: #000;")
    table.insert(css_content, "  border-radius: 10px;")
    table.insert(css_content, "  overflow: hidden;")
    table.insert(css_content, "  border: 1px solid var(--line);")
    table.insert(css_content, "  margin: 8px 0;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".player iframe {")
    table.insert(css_content, "  position: absolute;")
    table.insert(css_content, "  inset: 0;")
    table.insert(css_content, "  width: 100%;")
    table.insert(css_content, "  height: 100%;")
    table.insert(css_content, "  border: 0;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Placeholder styles
    table.insert(css_content, ".placeholder {")
    table.insert(css_content, "  position: absolute;")
    table.insert(css_content, "  inset: 0;")
    table.insert(css_content, "  display: flex;")
    table.insert(css_content, "  flex-direction: column;")
    table.insert(css_content, "  gap: 6px;")
    table.insert(css_content, "  align-items: center;")
    table.insert(css_content, "  justify-content: center;")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  text-align: center;")
    table.insert(css_content, "  padding: 16px;")
    table.insert(css_content, "  font-size: 13px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Card styles
    table.insert(css_content, ".card {")
    table.insert(css_content, "  background: var(--card);")
    table.insert(css_content, "  border: 1px solid var(--line);")
    table.insert(css_content, "  border-radius: 10px;")
    table.insert(css_content, "  padding: 10px 12px;")
    table.insert(css_content, "  margin-bottom: 8px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Heading 2 styles
    table.insert(css_content, "h2 {")
    table.insert(css_content, "  font-size: 11px;")
    table.insert(css_content, "  text-transform: uppercase;")
    table.insert(css_content, "  letter-spacing: .05em;")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  margin: 0 0 6px;")
    table.insert(css_content, "  font-weight: 650;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Meta styles
    table.insert(css_content, ".meta {")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  font-size: 12.5px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Strong styles
    table.insert(css_content, ".strong {")
    table.insert(css_content, "  color: var(--text);")
    table.insert(css_content, "  font-weight: 600;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Stream styles
    table.insert(css_content, ".stream {")
    table.insert(css_content, "  display: flex;")
    table.insert(css_content, "  gap: 8px;")
    table.insert(css_content, "  padding: 5px 0;")
    table.insert(css_content, "  border-bottom: 1px solid var(--line);")
    table.insert(css_content, "  font-size: 12.5px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".stream:last-child {")
    table.insert(css_content, "  border-bottom: 0;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".stream .when {")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  white-space: nowrap;")
    table.insert(css_content, "  font-variant-numeric: tabular-nums;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".stream .t {")
    table.insert(css_content, "  flex: 1;")
    table.insert(css_content, "  min-width: 0;")
    table.insert(css_content, "  overflow: hidden;")
    table.insert(css_content, "  text-overflow: ellipsis;")
    table.insert(css_content, "  white-space: nowrap;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    table.insert(css_content, ".stream.now {")
    table.insert(css_content, "  color: var(--accent);")
    table.insert(css_content, "  font-weight: 650;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Error styles
    table.insert(css_content, ".err {")
    table.insert(css_content, "  background: #3a1d22;")
    table.insert(css_content, "  border: 1px solid #5c2a33;")
    table.insert(css_content, "  color: #ffb4c0;")
    table.insert(css_content, "  padding: 8px 10px;")
    table.insert(css_content, "  border-radius: 8px;")
    table.insert(css_content, "  font-size: 12.5px;")
    table.insert(css_content, "  margin-bottom: 8px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Light theme error styles
    table.insert(css_content, "@media (prefers-color-scheme: light) {")
    table.insert(css_content, "  .err {")
    table.insert(css_content, "    background: #fdeceb;")
    table.insert(css_content, "    border-color: #f5c6c2;")
    table.insert(css_content, "    color: #b91c1c;")
    table.insert(css_content, "  }")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Note styles
    table.insert(css_content, ".note {")
    table.insert(css_content, "  font-size: 11.5px;")
    table.insert(css_content, "  color: var(--muted);")
    table.insert(css_content, "  line-height: 1.4;")
    table.insert(css_content, "  margin-top: 8px;")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Link styles
    table.insert(css_content, "a {")
    table.insert(css_content, "  color: var(--accent);")
    table.insert(css_content, "}")
    table.insert(css_content, "")

    -- Write to file
    local file = io.open(output_file, "w")
    if file then
        file:write(table.concat(css_content, "\n"))
        file:close()
        print("CSS file written to: " .. output_file)
    else
        print("Error: Could not open file " .. output_file .. " for writing")
    end
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_file>")
    os.exit(1)
end

write_popup_css(arg[1])
