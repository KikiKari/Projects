#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f5586974ea6508d3b597143c30f0da3af49336b70bf0b2547864ecf780cafa91", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "lua"}
-- index_4051ed.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_4051ed.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

-- abstraction-provenance: {"artifact_sha256": "c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79", "source_sha256": "4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24", "target_language": "lua"}
-- index.html — portiert nach css
-- Quelle: html, Projects@Telegram-Monitor:web/index.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

function generate_css()
    local css = {}

    -- Root variables
    table.insert(css, ":root{")
    table.insert(css, "  --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;")
    table.insert(css, "  --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;")
    table.insert(css, "  --ok:#15803d; --warn:#b45309; --err:#b91c1c;")
    table.insert(css, "  color-scheme: light;")
    table.insert(css, "}")

    -- Universal selector
    table.insert(css, "*{box-sizing:border-box}")

    -- Body styles
    table.insert(css, "body{margin:0;background:var(--bg);color:var(--text);")
    table.insert(css, "     font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}")

    -- Header styles
    table.insert(css, "header{background:var(--card);border-bottom:1px solid var(--line);padding:14px 20px;")
    table.insert(css, "       display:flex;align-items:center;gap:14px;flex-wrap:wrap;position:sticky;top:0;z-index:5}")
    table.insert(css, "header h1{font-size:17px;margin:0;font-weight:650}")

    -- Pill styles
    table.insert(css, ".pill{font-size:11px;padding:2px 8px;border-radius:99px;background:var(--accent-soft);")
    table.insert(css, "      color:var(--accent);font-weight:600;white-space:nowrap}")
    table.insert(css, ".pill.off{background:#f1f2f4;color:var(--muted)}")
    table.insert(css, ".pill.dc{background:var(--discord-soft);color:var(--discord)}")

    -- Navigation styles
    table.insert(css, "nav{display:flex;gap:4px;padding:0 20px;background:var(--card);border-bottom:1px solid var(--line)}")
    table.insert(css, "nav button{border:0;background:none;padding:11px 14px;font:inherit;font-weight:500;")
    table.insert(css, "           color:var(--muted);cursor:pointer;border-bottom:2px solid transparent}")
    table.insert(css, "nav button.active{color:var(--accent);border-bottom-color:var(--accent)}")

    -- Main content styles
    table.insert(css, "main{padding:20px;max-width:1080px;margin:0 auto}")

    -- Panel styles
    table.insert(css, ".panel{display:none} .panel.active{display:block}")

    -- Row styles
    table.insert(css, ".row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px}")

    -- Input and select styles
    table.insert(css, "input,select{padding:9px 11px;border:1px solid var(--line);border-radius:8px;font:inherit;")
    table.insert(css, "             background:var(--card);min-width:180px}")
    table.insert(css, "input:focus,select:focus{outline:2px solid var(--accent-soft);border-color:var(--accent)}")

    -- Button styles
    table.insert(css, "button.go{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:9px 16px;")
    table.insert(css, "          font:inherit;font-weight:600;cursor:pointer}")
    table.insert(css, "button.go.sec{background:var(--card);color:var(--text);border:1px solid var(--line)}")
    table.insert(css, "button.go.dc{background:var(--discord)}")
    table.insert(css, "button.go:disabled{opacity:.5;cursor:default}")

    -- Card styles
    table.insert(css, ".card{background:var(--card);border:1px solid var(--line);border-radius:12px;")
    table.insert(css, "      padding:14px 16px;margin-bottom:10px}")
    table.insert(css, ".card h3{margin:0 0 2px;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}")
    table.insert(css, ".card .meta{color:var(--muted);font-size:13px}")
    table.insert(css, ".card .desc{margin-top:7px;font-size:13.5px;white-space:pre-wrap}")

    -- Avatar styles
    table.insert(css, ".avatar{width:34px;height:34px;border-radius:50%;object-fit:cover;background:#eceff3;flex:none}")

    -- Head styles
    table.insert(css, ".head{display:flex;gap:11px;align-items:flex-start}")

    -- Score styles
    table.insert(css, ".score{font-variant-numeric:tabular-nums;font-size:12px;color:var(--muted);")
    table.insert(css, "       border:1px solid var(--line);border-radius:6px;padding:1px 6px}")

    -- Tag styles
    table.insert(css, ".tag{font-size:11px;padding:2px 7px;border-radius:5px;background:#f1f2f4;color:var(--muted);font-weight:600}")
    table.insert(css, ".tag.ok{background:#e7f6ec;color:var(--ok)} .tag.no{background:#fdeceb;color:var(--err)}")

    -- Post styles
    table.insert(css, ".post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;font-size:13.5px}")
    table.insert(css, ".post .when{color:var(--muted);font-size:12px}")
    table.insert(css, ".post .txt{white-space:pre-wrap;margin-top:2px}")

    -- Link styles
    table.insert(css, "a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}")

    -- Empty styles
    table.insert(css, ".empty{color:var(--muted);padding:22px;text-align:center;border:1px dashed var(--line);border-radius:12px}")

    -- Error styles
    table.insert(css, ".err{background:#fdeceb;border:1px solid #f5c6c2;color:var(--err);padding:10px 13px;")
    table.insert(css, "     border-radius:8px;margin-bottom:12px;font-size:13.5px}")

    -- Spin styles
    table.insert(css, ".spin{color:var(--muted);padding:16px 0}")

    -- Table styles
    table.insert(css, "table{width:100%;border-collapse:collapse;font-size:13.5px}")
    table.insert(css, "th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top}")
    table.insert(css, "th{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.03em}")

    -- Code styles
    table.insert(css, "code{background:#f1f2f4;padding:1px 5px;border-radius:4px;font-size:12.5px}")

    -- Hint styles
    table.insert(css, ".hint{color:var(--muted);font-size:13px;margin:-4px 0 14px}")

    -- Stream styles
    table.insert(css, ".stream{max-height:460px;overflow:auto;border:1px solid var(--line);border-radius:10px;")
    table.insert(css, "        padding:6px 12px;margin-top:10px;background:var(--card)}")

    -- Fresh post styles
    table.insert(css, ".post.fresh{border-left-color:var(--ok);background:#f3fbf5}")
    table.insert(css, ".post.fresh .when::after{content:\" NEU\";color:var(--ok);font-weight:700}")

    -- Dot styles
    table.insert(css, ".dot{width:8px;height:8px;border-radius:50%;background:var(--ok);display:inline-block;")
    table.insert(css, "     margin-right:6px;animation:pulse 2s infinite}")

    -- Keyframes
    table.insert(css, "@keyframes pulse{0%,100%{opacity:1}50%{opacity:.35}}")

    -- Idle styles
    table.insert(css, ".idle{background:var(--muted)!important;animation:none}")

    -- TT styles
    table.insert(css, ".tt-live{background:#fe2c55;color:#fff;font-weight:700;font-size:11px;")
    table.insert(css, "         padding:2px 9px;border-radius:99px}")
    table.insert(css, ".tt-off{background:#f1f2f4;color:var(--muted);font-weight:700;font-size:11px;")
    table.insert(css, "        padding:2px 9px;border-radius:99px}")

    -- TT player styles
    table.insert(css, ".tt-player{position:relative;width:100%;max-width:340px;aspect-ratio:9/16;background:#000;")
    table.insert(css, "           border-radius:10px;overflow:hidden;margin-top:10px;border:1px solid var(--line)}")
    table.insert(css, ".tt-player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}")

    -- Event styles
    table.insert(css, ".ev{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}")
    table.insert(css, ".ev:last-child{border-bottom:0}")
    table.insert(css, ".ev .k{font-weight:650;white-space:nowrap}")
    table.insert(css, ".ev .k.start{color:#fe2c55} .ev .k.end{color:var(--muted)}")

    return table.concat(css, "\n")
end

function write_css_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
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
print("CSS file written to: " .. output_filename)
