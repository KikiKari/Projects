#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "02241bafd79b279e0c8cfeca4d1a810bdd071dbfcf34baf8cf984a58cc28e416", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "lua"}
-- icon-controls.css — portiert nach lua
-- Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
-- auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
-- auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_css(output_file)
    local styles = {"plastisch", "glass", "linear"}
    local icons = {
        "auto-chat-refresh-counter", "browser", "captions", "chat-counter",
        "fullscreen", "mute", "off", "on", "pip", "play", "player",
        "protection-slider", "recommendation-counter", "report", "reset",
        "settings", "status", "stop", "unmute", "volume-slider"
    }

    local file = io.open(output_file, "w")
    if not file then
        error("Could not open file for writing: " .. output_file)
    end

    -- Generate style rules
    for _, style in ipairs(styles) do
        file:write(string.format('html[data-icon-style="%s"] {', style))
        for _, icon in ipairs(icons) do
            file:write(string.format('--icon-%s:url("icons/%s/%s.png");', icon, style, icon))
        end
        file:write('}\n')
    end

    -- Generate base styles
    file:write([[
button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
button[data-control-icon][hidden] { display:none; }
input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
input[type="checkbox"]:checked { background-image:var(--icon-on); }
input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
.control-icon { display:inline-flex; align-items:center; }
input[type="range"] { min-height:32px; }
.icon-style-setting { display:flex; align-items:center; gap:8px; }
]])

    -- Generate icon control rules
    for _, icon in ipairs(icons) do
        file:write(string.format('[data-control-icon="%s"] { --control-icon:var(--icon-%s); }\n', icon, icon))
    end

    file:close()
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output-file>")
    os.exit(1)
end

generate_css(arg[1])
