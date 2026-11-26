#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "c699931cadd7733e81a1c630f370571defe22368f1e62b13cafd026959771512", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion:site/index.html
-- auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
-- auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function createHTMLDocument()
    local html = {}
    
    -- Helper function to add a line with proper indentation
    local function addLine(line, indentLevel)
        indentLevel = indentLevel or 0
        table.insert(html, (" "):rep(indentLevel * 2) .. line)
    end
    
    -- DOCTYPE declaration
    table.insert(html, "<!doctype html>")
    
    -- Opening html tag
    addLine('<html lang="de">', 0)
    
    -- Head section
    addLine("<head>", 1)
    
    -- Meta tags
    addLine('<meta charset="UTF-8" />', 2)
    addLine('<meta name="viewport" content="width=device-width, initial-scale=1.0" />', 2)
    addLine('<meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />', 2)
    addLine('<meta name="theme-color" content="#ffffff" />', 2)
    
    -- Link tags
    addLine('<link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />', 2)
    addLine('<link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />', 2)
    
    -- Title
    addLine("<title>TikTok LIVE Companion – Dokumentation</title>", 2)
    
    -- Closing head
    addLine("</head>", 1)
    
    -- Body section
    addLine("<body>", 1)
    
    -- Root div
    addLine('<div id="root"></div>', 2)
    
    -- Script tag
    addLine('<script type="module" src="/src/main.tsx"></script>', 2)
    
    -- Closing body and html
    addLine("</body>", 1)
    addLine("</html>", 0)
    
    return table.concat(html, "\n")
end

-- Main execution
local function main()
    local filename = arg[1]
    
    if not filename then
        print("Usage: " .. (arg[0] or "script") .. " <output_file>")
        os.exit(1)
    end
    
    local content = createHTMLDocument()
    
    local file = io.open(filename, "w")
    if not file then
        print("Error: Could not open file '" .. filename .. "' for writing")
        os.exit(1)
    end
    
    file:write(content)
    file:close()
    
    print("HTML document created successfully: " .. filename)
end

main()
