#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "9afbf851954016f7505a48002bcad607f6a6e07740f9c9a5693efa59eede6e9d", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "lua"}
-- index_6925e5.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_6925e5.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function write_css(output_file)
  local file = io.open(output_file, "w")
  if not file then
    error("Could not open file for writing: " .. output_file)
  end

  -- Write comments
  file:write("/* abstraction-provenance: {\"artifact_sha256\": \"ede701dd0faa101fb7d23c7e6bd8e28625c33e7b3d07a7ededc1bf14cbfcb761\", \"source_sha256\": \"6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523\", \"target_language\": \"css\"} */\n")
  file:write("/* index.html — portiert nach css */\n")
  file:write("/* Quelle: html, Projects@MCP-Server-Monitor:public/index.html */\n")
  file:write("/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n")

  -- Root styles
  file:write(":root{\n")
  file:write("  --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n")
  file:write("  --ac:#6d5bd0; --ac-soft:#efecfb;\n")
  file:write("  --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n")
  file:write("  color-scheme: light;\n")
  file:write("}\n\n")

  -- Dark mode media query
  file:write("@media (prefers-color-scheme: dark){\n")
  file:write("  :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n")
  file:write("         --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n")
  file:write("}\n\n")

  -- Universal selector
  file:write("*{box-sizing:border-box}\n\n")

  -- Body styles
  file:write("body{margin:0;background:var(--bg);color:var(--text);\n")
  file:write("     font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n\n")

  -- Wrap class
  file:write(".wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}\n\n")

  -- Header styles
  file:write("header{padding:64px 0 36px;border-bottom:1px solid var(--line)}\n\n")

  -- Headings
  file:write("h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n")
  file:write("h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n")
  file:write("   color:var(--muted);font-weight:650}\n")
  file:write("h3{font-size:17px;margin:24px 0 6px}\n\n")

  -- Paragraph
  file:write("p{margin:0 0 14px;max-width:70ch}\n\n")

  -- Badges
  file:write(".badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}\n")
  file:write(".badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n")
  file:write("       background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n")
  file:write(".badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n\n")

  -- Table styles
  file:write("table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}\n")
  file:write("th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}\n")
  file:write("th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}\n\n")

  -- Code styles
  file:write("code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n")
  file:write("     font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n")
  file:write("pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n")
  file:write("    padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n")
  file:write("pre code{background:none;padding:0}\n\n")

  -- Card and note styles
  file:write(".card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}\n")
  file:write(".note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;\n")
  file:write("      padding:14px 16px;margin:0 0 16px;font-size:14.5px}\n")
  file:write(".note b{color:var(--warn)}\n\n")

  -- Form elements
  file:write("fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}\n")
  file:write("legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}\n")
  file:write("label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}\n")
  file:write("label.q input{margin-top:4px;flex:none}\n")
  file:write("label.q span small{display:block;color:var(--muted);font-size:13px}\n")
  file:write("#ergebnis{margin-top:6px}\n\n")

  -- Verdict styles
  file:write(".verdict{border:1px solid var(--line);border-left:4px solid var(--ac);\n")
  file:write("         border-radius:10px;padding:16px 18px;background:var(--soft)}\n")
  file:write(".verdict h3{margin:0 0 6px;font-size:18px}\n")
  file:write(".verdict .step{font-weight:650;margin:10px 0 0}\n")
  file:write(".verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);\n")
  file:write("            border-radius:8px;font-size:14px}\n\n")

  -- Probe styles
  file:write(".probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}\n")
  file:write(".probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);\n")
  file:write("             border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}\n\n")

  -- Button styles
  file:write(".btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;\n")
  file:write("     border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}\n")
  file:write(".btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}\n\n")

  -- Footer
  file:write("footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);\n")
  file:write("       color:var(--muted);font-size:14px}\n\n")

  -- Links
  file:write("a{color:var(--ac)}\n")

  file:close()
end

-- Main execution
if #arg ~= 1 then
  print("Usage: " .. arg[0] .. " <output_file>")
  os.exit(1)
end

local output_file = arg[1]
write_css(output_file)
print("CSS file written to: " .. output_file)
