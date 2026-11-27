#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "d3caf4e94fbd2d644fef8fe823700d41d4b3fb912770143f3d82320abbe5f064", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "lua"}
-- status-overview.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function createHTMLDocument()
    -- Create the basic HTML structure
    local html = {}
    
    -- Add DOCTYPE
    table.insert(html, "<!doctype html>")
    
    -- Start html tag with lang attribute
    table.insert(html, "<html lang=\"de\">")
    
    -- Head section
    table.insert(html, "<head>")
    table.insert(html, "<meta charset=\"utf-8\">")
    table.insert(html, "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">")
    table.insert(html, "<title>STATUS-Overview</title>")
    table.insert(html, "<link rel=\"stylesheet\" href=\"status-overview.css\">")
    table.insert(html, "</head>")
    
    -- Body section
    table.insert(html, "<body>")
    table.insert(html, "<main id=\"grid\" aria-label=\"LIVE-Übersicht\"></main>")
    table.insert(html, "<script src=\"vendor-mpegts.js\"></script>")
    table.insert(html, "<script src=\"status-overview-player.js\"></script>")
    table.insert(html, "</body>")
    
    -- Close html tag
    table.insert(html, "</html>")
    
    return table.concat(html, "\n")
end

-- Main execution
local function main()
    local filename = arg[1]
    
    if not filename then
        io.stderr:write("Usage: ", arg[0], " <output-file>\n")
        os.exit(1)
    end
    
    local content = createHTMLDocument()
    
    local file, err = io.open(filename, "w")
    if not file then
        io.stderr:write("Error opening file: ", err, "\n")
        os.exit(1)
    end
    
    file:write(content)
    file:close()
end

main()
