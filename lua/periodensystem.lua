#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "edbd5046332a6769e1643f675cf164e8388e6ce3799aed625fdba97ea43a94a8", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "lua"}
-- periodensystem.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/periodensystem.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function write_css_to_file(filename)
  local file = io.open(filename, "w")
  if not file then
    error("Could not open file for writing: " .. filename)
  end

  -- Write the CSS content programmatically
  file:write("/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */\n")
  file:write("/* periodensystem.html — portiert nach css */\n")
  file:write("/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n")
  file:write("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n")

  file:write("* { box-sizing: border-box; margin: 0; padding: 0; }\n")
  file:write(":root {\n")
  file:write("  --bg: #fafaf7;\n")
  file:write("  --surface: #ffffff;\n")
  file:write("  --border: rgba(0,0,0,0.12);\n")
  file:write("  --text: #1a1a1a;\n")
  file:write("  --text-muted: #666;\n")
  file:write("}\n")

  file:write("@media (prefers-color-scheme: dark) {\n")
  file:write("  :root {\n")
  file:write("    --bg: #1a1a1a;\n")
  file:write("    --surface: #242424;\n")
  file:write("    --border: rgba(255,255,255,0.15);\n")
  file:write("    --text: #f0f0f0;\n")
  file:write("    --text-muted: #aaa;\n")
  file:write("  }\n")
  file:write("}\n")

  file:write("body {\n")
  file:write("  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;\n")
  file:write("  background: var(--bg);\n")
  file:write("  color: var(--text);\n")
  file:write("  padding: 24px;\n")
  file:write("  max-width: 1100px;\n")
  file:write("  margin: 0 auto;\n")
  file:write("  line-height: 1.5;\n")
  file:write("}\n")

  file:write("h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }\n")
  file:write(".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }\n")

  file:write(".detail {\n")
  file:write("  background: var(--surface);\n")
  file:write("  border: 1px solid var(--border);\n")
  file:write("  border-radius: 12px;\n")
  file:write("  padding: 16px 20px;\n")
  file:write("  min-height: 110px;\n")
  file:write("  display: flex;\n")
  file:write("  align-items: center;\n")
  file:write("  gap: 20px;\n")
  file:write("  margin-bottom: 16px;\n")
  file:write("}\n")

  file:write(".detail-empty {\n")
  file:write("  color: var(--text-muted);\n")
  file:write("  font-size: 14px;\n")
  file:write("  text-align: center;\n")
  file:write("  width: 100%;\n")
  file:write("}\n")

  file:write(".symbol-box {\n")
  file:write("  font-size: 40px;\n")
  file:write("  font-weight: 500;\n")
  file:write("  line-height: 1;\n")
  file:write("  width: 80px;\n")
  file:write("  height: 80px;\n")
  file:write("  display: flex;\n")
  file:write("  align-items: center;\n")
  file:write("  justify-content: center;\n")
  file:write("  border-radius: 8px;\n")
  file:write("  flex-shrink: 0;\n")
  file:write("}\n")

  file:write(".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }\n")

  file:write(".info-meta {\n")
  file:write("  font-size: 13px;\n")
  file:write("  color: var(--text-muted);\n")
  file:write("  display: grid;\n")
  file:write("  grid-template-columns: repeat(2, minmax(0, 1fr));\n")
  file:write("  gap: 4px 24px;\n")
  file:write("}\n")

  file:write(".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }\n")

  file:write(".grid {\n")
  file:write("  display: grid;\n")
  file:write("  grid-template-columns: repeat(18, minmax(0, 1fr));\n")
  file:write("  gap: 3px;\n")
  file:write("}\n")

  file:write(".fgrid { margin-top: 8px; }\n")

  file:write(".cell {\n")
  file:write("  aspect-ratio: 1;\n")
  file:write("  border-radius: 4px;\n")
  file:write("  padding: 3px;\n")
  file:write("  display: flex;\n")
  file:write("  flex-direction: column;\n")
  file:write("  align-items: center;\n")
  file:write("  justify-content: center;\n")
  file:write("  cursor: pointer;\n")
  file:write("  font-family: inherit;\n")
  file:write("  line-height: 1;\n")
  file:write("  transition: transform 0.12s ease;\n")
  file:write("  border: 0;\n")
  file:write("  position: relative;\n")
  file:write("  overflow: hidden;\n")
  file:write("}\n")

  file:write(".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }\n")
  file:write(".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }\n")
  file:write(".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }\n")

  file:write(".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }\n")
  file:write(".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }\n")

  file:write(".cell-marker {\n")
  file:write("  cursor: default;\n")
  file:write("  font-size: 9px;\n")
  file:write("  font-weight: 500;\n")
  file:write("  border: 1px dashed currentColor;\n")
  file:write("  background: transparent !important;\n")
  file:write("}\n")

  file:write(".cell-marker:hover { transform: none; box-shadow: none; }\n")

  -- Category classes
  local categories = {
    {class="am", bg_light="#FCEBEB", fg_light="#501313", bg_dark="#791F1F", fg_dark="#F7C1C1"},
    {class="em", bg_light="#FAEEDA", fg_light="#412402", bg_dark="#633806", fg_dark="#FAC775"},
    {class="tm", bg_light="#E6F1FB", fg_light="#042C53", bg_dark="#0C447C", fg_dark="#B5D4F4"},
    {class="ptm", bg_light="#F1EFE8", fg_light="#2C2C2A", bg_dark="#444441", fg_dark="#D3D1C7"},
    {class="hm", bg_light="#E1F5EE", fg_light="#04342C", bg_dark="#085041", fg_dark="#9FE1CB"},
    {class="nm", bg_light="#EAF3DE", fg_light="#173404", bg_dark="#27500A", fg_dark="#C0DD97"},
    {class="h", bg_light="#EEEDFE", fg_light="#26215C", bg_dark="#3C3489", fg_dark="#CECBF6"},
    {class="eg", bg_light="#FBEAF0", fg_light="#4B1528", bg_dark="#72243E", fg_dark="#F4C0D1"},
    {class="la", bg_light="#FAECE7", fg_light="#4A1B0C", bg_dark="#712B13", fg_dark="#F5C4B3"},
    {class="ac", bg_light="#F5C4B3", fg_light="#4A1B0C", bg_dark="#993C1D", fg_dark="#F5C4B3"}
  }

  for _, cat in ipairs(categories) do
    file:write(".cat-" .. cat.class .. " { background: " .. cat.bg_light .. "; color: " .. cat.fg_light .. "; }\n")
  end

  file:write("@media (prefers-color-scheme: dark) {\n")
  for _, cat in ipairs(categories) do
    file:write("  .cat-" .. cat.class .. " { background: " .. cat.bg_dark .. "; color: " .. cat.fg_dark .. "; }\n")
  end
  file:write("}\n")

  file:write(".legend {\n")
  file:write("  display: grid;\n")
  file:write("  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));\n")
  file:write("  gap: 8px 16px;\n")
  file:write("  margin-top: 24px;\n")
  file:write("  font-size: 12px;\n")
  file:write("  color: var(--text-muted);\n")
  file:write("}\n")

  file:write(".legend-item { display: flex; align-items: center; gap: 8px; }\n")
  file:write(".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }\n")

  file:close()
end

-- Main execution
if #arg ~= 1 then
  print("Usage: " .. arg[0] .. " <output_filename>")
  os.exit(1)
end

local output_filename = arg[1]
write_css_to_file(output_filename)
print("CSS file written to: " .. output_filename)
