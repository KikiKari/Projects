#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "03869de76848bde6a3f4d7e039e1575f62fbcbc4ff2a2097f6f02c287ce5a0d8", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
-- auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function create_html_document()
    local html = {}
    
    -- Doctype declaration
    table.insert(html, "<!doctype html>")
    table.insert(html, "<html lang=\"de\">")
    
    -- Head section
    table.insert(html, "  <head>")
    table.insert(html, "    <meta charset=\"UTF-8\" />")
    table.insert(html, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />")
    table.insert(html, "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />")
    table.insert(html, "    <meta name=\"theme-color\" content=\"#ffffff\" />")
    table.insert(html, "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />")
    table.insert(html, "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />")
    table.insert(html, "    <title>TikTok LIVE Companion – Dokumentation</title>")
    table.insert(html, "  </head>")
    
    -- Body section
    table.insert(html, "  <body>")
    table.insert(html, "    <div id=\"root\"></div>")
    table.insert(html, "    <script type=\"module\" src=\"/src/main.tsx\"></script>")
    table.insert(html, "  </body>")
    
    table.insert(html, "</html>")
    
    return table.concat(html, "\n")
end

local function write_to_file(content, filename)
    local file = io.open(filename, "w")
    if file then
        file:write(content)
        file:close()
        return true
    else
        return false
    end
end

-- Main execution
local output_filename = arg[1] or "index.html"
local html_content = create_html_document()

if write_to_file(html_content, output_filename) then
    print("HTML document successfully written to " .. output_filename)
else
    print("Error: Could not write to file " .. output_filename)
    os.exit(1)
end
