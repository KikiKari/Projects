#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "c374f82f5e199ae76f2a266edb1fff7a2dc636992c9e418c941ed06c241e81e3", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, OpenClaw@main:index.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function createHTML()
    local html = {}
    
    -- Helper function to add a line with proper indentation
    local function addLine(line, indentLevel)
        indentLevel = indentLevel or 0
        local indent = string.rep("  ", indentLevel)
        table.insert(html, indent .. line)
    end
    
    -- DOCTYPE
    table.insert(html, "<!DOCTYPE html>")
    
    -- Opening html tag
    addLine('<html lang="de">')
    
    -- Head section
    addLine("<head>", 1)
    
    -- Meta charset
    addLine('<meta charset="utf-8" />', 2)
    
    -- Icon link
    addLine('<link rel="icon" href="/favicon.ico" />', 2)
    
    -- Viewport meta
    addLine('<meta name="viewport" content="width=device-width, initial-scale=1" />', 2)
    
    -- Theme color meta
    addLine('<meta name="theme-color" content="#0b1020" />', 2)
    
    -- Description meta
    addLine('<meta', 2)
    addLine('name="description"', 3)
    addLine('content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."', 3)
    addLine('/>', 2)
    
    -- Apple touch icon
    addLine('<link rel="apple-touch-icon" href="/logo192.png" />', 2)
    
    -- Comment about manifest.json
    addLine("<!--", 2)
    addLine("  manifest.json provides metadata used when your web app is installed on a", 2)
    addLine("  user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/", 2)
    addLine("-->", 2)
    
    -- Manifest link
    addLine('<link rel="manifest" href="/manifest.json" />', 2)
    
    -- Title
    addLine("<title>OpenClaw</title>", 2)
    
    -- Closing head
    addLine("</head>", 1)
    
    -- Body section
    addLine("<body>", 1)
    
    -- Noscript message
    addLine("<noscript>You need to enable JavaScript to run this app.</noscript>", 2)
    
    -- Root div
    addLine('<div id="root"></div>', 2)
    
    -- Comment about the HTML template
    addLine("<!--", 2)
    addLine("  This HTML file is a template.", 2)
    addLine("  If you open it directly in the browser, you will see an empty page.", 2)
    addLine("", 2)
    addLine("  You can add webfonts, meta tags, or analytics to this file.", 2)
    addLine("  The build step will place the bundled scripts into the <body> tag.", 2)
    addLine("", 2)
    addLine("  To begin the development, run `npm start` or `yarn start`.", 2)
    addLine("  To create a production bundle, use `npm run build` or `yarn build`.", 2)
    addLine("-->", 2)
    
    -- Closing body
    addLine("</body>", 1)
    
    -- Script tag
    addLine('<script type="module" src="/src/index.jsx"></script>', 1)
    
    -- Closing html
    addLine("</html>")
    
    return table.concat(html, "\n")
end

-- Main execution
local filename = arg[1]

if not filename then
    print("Usage: " .. (arg[0] or "program") .. " <output_file>")
    os.exit(1)
end

local file, err = io.open(filename, "w")
if not file then
    print("Error opening file: " .. err)
    os.exit(1)
end

file:write(createHTML())
file:close()

print("HTML file created successfully: " .. filename)
