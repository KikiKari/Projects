#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "923cdc765e0015ebf22a579c431489c90c855c104b38171944b282be52f3d6df", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, Projects@Program-Derivation:public/index.html
-- auch in: Projects@Vision-Check:public/index.html
-- auch in: Projects@Weather-Check:public/index.html
-- auch in: Projects@abstractions:public/index.html
-- auch in: 5 weiteren Fundstellen
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function create_html_document()
    local html = {}
    
    -- DOCTYPE declaration
    table.insert(html, "<!DOCTYPE html>")
    table.insert(html, "<html lang=\"de\">")
    
    -- Head section
    table.insert(html, "<head>")
    table.insert(html, "<meta charset=\"utf-8\">")
    table.insert(html, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
    table.insert(html, "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">")
    table.insert(html, "<title>Weiterleitung zur 3D-Ansicht</title>")
    table.insert(html, "<link rel=\"canonical\" href=\"3d.html\">")
    table.insert(html, "<script>location.replace('3d.html');</script>")
    table.insert(html, "</head>")
    
    -- Body section
    table.insert(html, "<body>")
    table.insert(html, "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>")
    table.insert(html, "</body>")
    table.insert(html, "</html>")
    
    return table.concat(html, "\n")
end

local function write_to_file(filename, content)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end
    file:write(content)
    file:close()
end

-- Main execution
local output_filename = arg[1] or "index.html"
local html_content = create_html_document()
write_to_file(output_filename, html_content)

print("HTML document written to " .. output_filename)
