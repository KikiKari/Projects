#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "3b6f2d5894d4b8022ea194f6fc1a3e5f239593225e83968caea0ab2cfcc56188", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "lua"}
-- index_58ad28.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_58ad28.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function write_css(output_file)
  local css = {}

  -- Root variables for light theme
  table.insert(css, ":root {")
  table.insert(css, "  --bg: #ffffff;")
  table.insert(css, "  --soft: #f6f7f9;")
  table.insert(css, "  --line: #e3e6ea;")
  table.insert(css, "  --text: #16191d;")
  table.insert(css, "  --muted: #5f6773;")
  table.insert(css, "  --tg: #2481cc;")
  table.insert(css, "  --tg-soft: #e8f2fb;")
  table.insert(css, "  --tt: #fe2c55;")
  table.insert(css, "  --ok: #15803d;")
  table.insert(css, "  --ok-soft: #e7f6ec;")
  table.insert(css, "  --warn: #b45309;")
  table.insert(css, "  --warn-soft: #fdf3e3;")
  table.insert(css, "  color-scheme: light;")
  table.insert(css, "}")

  -- Dark theme media query
  table.insert(css, "")
  table.insert(css, "@media (prefers-color-scheme: dark) {")
  table.insert(css, "  :root {")
  table.insert(css, "    --bg: #0f1115;")
  table.insert(css, "    --soft: #171a21;")
  table.insert(css, "    --line: #262b36;")
  table.insert(css, "    --text: #f2f4f8;")
  table.insert(css, "    --muted: #9aa3b2;")
  table.insert(css, "    --tg-soft: #132a3d;")
  table.insert(css, "    --ok-soft: #12261a;")
  table.insert(css, "    --warn-soft: #2c2110;")
  table.insert(css, "    color-scheme: dark;")
  table.insert(css, "  }")
  table.insert(css, "}")

  -- Universal selector
  table.insert(css, "")
  table.insert(css, "* {")
  table.insert(css, "  box-sizing: border-box;")
  table.insert(css, "}")

  -- Body styles
  table.insert(css, "")
  table.insert(css, "body {")
  table.insert(css, "  margin: 0;")
  table.insert(css, "  background: var(--bg);")
  table.insert(css, "  color: var(--text);")
  table.insert(css, "  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;")
  table.insert(css, "}")

  -- Wrap container
  table.insert(css, "")
  table.insert(css, ".wrap {")
  table.insert(css, "  max-width: 820px;")
  table.insert(css, "  margin: 0 auto;")
  table.insert(css, "  padding: 0 20px 72px;")
  table.insert(css, "}")

  -- Header section
  table.insert(css, "")
  table.insert(css, "header {")
  table.insert(css, "  padding: 64px 0 40px;")
  table.insert(css, "  border-bottom: 1px solid var(--line);")
  table.insert(css, "  margin-bottom: 8px;")
  table.insert(css, "}")

  -- Main heading
  table.insert(css, "")
  table.insert(css, "h1 {")
  table.insert(css, "  font-size: 34px;")
  table.insert(css, "  line-height: 1.2;")
  table.insert(css, "  margin: 0 0 12px;")
  table.insert(css, "  letter-spacing: -0.02em;")
  table.insert(css, "}")

  -- Lede text
  table.insert(css, "")
  table.insert(css, ".lede {")
  table.insert(css, "  font-size: 18px;")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  margin: 0 0 22px;")
  table.insert(css, "  max-width: 60ch;")
  table.insert(css, "}")

  -- Section headings
  table.insert(css, "")
  table.insert(css, "h2 {")
  table.insert(css, "  font-size: 13px;")
  table.insert(css, "  margin: 44px 0 14px;")
  table.insert(css, "  text-transform: uppercase;")
  table.insert(css, "  letter-spacing: 0.06em;")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  font-weight: 650;")
  table.insert(css, "}")

  -- Subheadings
  table.insert(css, "")
  table.insert(css, "h3 {")
  table.insert(css, "  font-size: 17px;")
  table.insert(css, "  margin: 26px 0 6px;")
  table.insert(css, "}")

  -- Paragraphs
  table.insert(css, "")
  table.insert(css, "p {")
  table.insert(css, "  margin: 0 0 14px;")
  table.insert(css, "  max-width: 68ch;")
  table.insert(css, "}")

  -- Badges container
  table.insert(css, "")
  table.insert(css, ".badges {")
  table.insert(css, "  display: flex;")
  table.insert(css, "  gap: 7px;")
  table.insert(css, "  flex-wrap: wrap;")
  table.insert(css, "  margin-bottom: 22px;")
  table.insert(css, "}")

  -- Badge elements
  table.insert(css, "")
  table.insert(css, ".badge {")
  table.insert(css, "  font-size: 12px;")
  table.insert(css, "  font-weight: 650;")
  table.insert(css, "  padding: 4px 11px;")
  table.insert(css, "  border-radius: 99px;")
  table.insert(css, "  background: var(--soft);")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  border: 1px solid var(--line);")
  table.insert(css, "}")

  -- Active badge
  table.insert(css, "")
  table.insert(css, ".badge.on {")
  table.insert(css, "  background: var(--ok-soft);")
  table.insert(css, "  color: var(--ok);")
  table.insert(css, "  border-color: transparent;")
  table.insert(css, "}")

  -- Call to action container
  table.insert(css, "")
  table.insert(css, ".cta {")
  table.insert(css, "  display: flex;")
  table.insert(css, "  gap: 10px;")
  table.insert(css, "  flex-wrap: wrap;")
  table.insert(css, "}")

  -- Button styles
  table.insert(css, "")
  table.insert(css, ".btn {")
  table.insert(css, "  display: inline-block;")
  table.insert(css, "  font-weight: 650;")
  table.insert(css, "  font-size: 15px;")
  table.insert(css, "  padding: 11px 20px;")
  table.insert(css, "  border-radius: 9px;")
  table.insert(css, "  text-decoration: none;")
  table.insert(css, "  border: 1px solid var(--line);")
  table.insert(css, "  background: var(--bg);")
  table.insert(css, "  color: var(--text);")
  table.insert(css, "}")

  -- Primary button
  table.insert(css, "")
  table.insert(css, ".btn.primary {")
  table.insert(css, "  background: var(--tg);")
  table.insert(css, "  border-color: var(--tg);")
  table.insert(css, "  color: #fff;")
  table.insert(css, "}")

  -- Button hover state
  table.insert(css, "")
  table.insert(css, ".btn:hover {")
  table.insert(css, "  border-color: var(--tg);")
  table.insert(css, "}")

  -- Grid layout
  table.insert(css, "")
  table.insert(css, ".grid {")
  table.insert(css, "  display: grid;")
  table.insert(css, "  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));")
  table.insert(css, "  gap: 14px;")
  table.insert(css, "}")

  -- Card components
  table.insert(css, "")
  table.insert(css, ".card {")
  table.insert(css, "  border: 1px solid var(--line);")
  table.insert(css, "  border-radius: 12px;")
  table.insert(css, "  padding: 16px 18px;")
  table.insert(css, "  background: var(--bg);")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, ".card h3 {")
  table.insert(css, "  margin-top: 0;")
  table.insert(css, "  font-size: 15.5px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, ".card p {")
  table.insert(css, "  font-size: 14px;")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  margin: 0;")
  table.insert(css, "}")

  -- Ordered steps list
  table.insert(css, "")
  table.insert(css, "ol.steps {")
  table.insert(css, "  list-style: none;")
  table.insert(css, "  counter-reset: s;")
  table.insert(css, "  padding: 0;")
  table.insert(css, "  margin: 0;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "ol.steps li {")
  table.insert(css, "  counter-increment: s;")
  table.insert(css, "  position: relative;")
  table.insert(css, "  padding: 0 0 20px 40px;")
  table.insert(css, "  border-left: 2px solid var(--line);")
  table.insert(css, "  margin-left: 11px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "ol.steps li:last-child {")
  table.insert(css, "  border-left-color: transparent;")
  table.insert(css, "  padding-bottom: 0;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "ol.steps li::before {")
  table.insert(css, "  content: counter(s);")
  table.insert(css, "  position: absolute;")
  table.insert(css, "  left: -13px;")
  table.insert(css, "  top: 0;")
  table.insert(css, "  width: 24px;")
  table.insert(css, "  height: 24px;")
  table.insert(css, "  border-radius: 50%;")
  table.insert(css, "  background: var(--tg);")
  table.insert(css, "  color: #fff;")
  table.insert(css, "  display: flex;")
  table.insert(css, "  align-items: center;")
  table.insert(css, "  justify-content: center;")
  table.insert(css, "  font-size: 12px;")
  table.insert(css, "  font-weight: 700;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "ol.steps b {")
  table.insert(css, "  display: block;")
  table.insert(css, "  margin-bottom: 3px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "ol.steps p {")
  table.insert(css, "  font-size: 14.5px;")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  margin: 0 0 8px;")
  table.insert(css, "}")

  -- Inline code
  table.insert(css, "")
  table.insert(css, "code {")
  table.insert(css, "  background: var(--soft);")
  table.insert(css, "  padding: 2px 7px;")
  table.insert(css, "  border-radius: 5px;")
  table.insert(css, "  font-size: 13.5px;")
  table.insert(css, "  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;")
  table.insert(css, "  word-break: break-word;")
  table.insert(css, "}")

  -- Code blocks
  table.insert(css, "")
  table.insert(css, "pre {")
  table.insert(css, "  background: var(--soft);")
  table.insert(css, "  border: 1px solid var(--line);")
  table.insert(css, "  border-radius: 10px;")
  table.insert(css, "  padding: 13px 15px;")
  table.insert(css, "  overflow-x: auto;")
  table.insert(css, "  margin: 0 0 14px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "pre code {")
  table.insert(css, "  background: none;")
  table.insert(css, "  padding: 0;")
  table.insert(css, "  font-size: 13.5px;")
  table.insert(css, "  line-height: 1.7;")
  table.insert(css, "}")

  -- Tables
  table.insert(css, "")
  table.insert(css, "table {")
  table.insert(css, "  width: 100%;")
  table.insert(css, "  border-collapse: collapse;")
  table.insert(css, "  font-size: 14.5px;")
  table.insert(css, "  margin: 0 0 16px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "th,")
  table.insert(css, "td {")
  table.insert(css, "  text-align: left;")
  table.insert(css, "  padding: 9px 11px;")
  table.insert(css, "  border-bottom: 1px solid var(--line);")
  table.insert(css, "  vertical-align: top;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, "th {")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "  font-size: 12px;")
  table.insert(css, "  text-transform: uppercase;")
  table.insert(css, "  letter-spacing: 0.04em;")
  table.insert(css, "  font-weight: 650;")
  table.insert(css, "}")

  -- Note boxes
  table.insert(css, "")
  table.insert(css, ".note {")
  table.insert(css, "  border-left: 3px solid var(--warn);")
  table.insert(css, "  background: var(--warn-soft);")
  table.insert(css, "  border-radius: 0 9px 9px 0;")
  table.insert(css, "  padding: 13px 16px;")
  table.insert(css, "  margin: 0 0 16px;")
  table.insert(css, "  font-size: 14.5px;")
  table.insert(css, "}")

  table.insert(css, "")
  table.insert(css, ".note b {")
  table.insert(css, "  display: block;")
  table.insert(css, "  margin-bottom: 3px;")
  table.insert(css, "}")

  -- Links
  table.insert(css, "")
  table.insert(css, "a {")
  table.insert(css, "  color: var(--tg);")
  table.insert(css, "}")

  -- Footer
  table.insert(css, "")
  table.insert(css, "footer {")
  table.insert(css, "  margin-top: 52px;")
  table.insert(css, "  padding-top: 22px;")
  table.insert(css, "  border-top: 1px solid var(--line);")
  table.insert(css, "  font-size: 13.5px;")
  table.insert(css, "  color: var(--muted);")
  table.insert(css, "}")

  -- Write to file
  local file = io.open(output_file, "w")
  if not file then
    error("Could not open file for writing: " .. output_file)
  end
  
  for _, line in ipairs(css) do
    file:write(line .. "\n")
  end
  
  file:close()
end

-- Main execution
if #arg ~= 1 then
  print("Usage: " .. arg[0] .. " <output_file>")
  os.exit(1)
end

write_css(arg[1])
