#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "d8dd6143493b45c0fce88b139189a75397180339e3dc5ad6995b6d1f20231a45", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "lua"}
-- index_5f1051.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_5f1051.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Add comments
    table.insert(css, "/* abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"} */")
    table.insert(css, "/* index.html — portiert nach css */")
    table.insert(css, "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */")
    table.insert(css, "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */")
    table.insert(css, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */")
    table.insert(css, "")

    -- body
    table.insert(css, "body {")
    table.insert(css, "    background-color: white;")
    table.insert(css, "    color: black;")
    table.insert(css, "    margin: 0;")
    table.insert(css, "    padding: 0;")
    table.insert(css, "    font-family: Arial, sans-serif;")
    table.insert(css, "}")
    table.insert(css, "")

    -- table
    table.insert(css, "table {")
    table.insert(css, "    border-collapse: collapse;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .globalnav-container
    table.insert(css, ".globalnav-container {")
    table.insert(css, "    width: 780px;")
    table.insert(css, "    border: 0;")
    table.insert(css, "    cellpadding: 0;")
    table.insert(css, "    cellspacing: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .header-left
    table.insert(css, ".header-left {")
    table.insert(css, "    vertical-align: top;")
    table.insert(css, "    text-align: left;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .header-right
    table.insert(css, ".header-right {")
    table.insert(css, "    vertical-align: top;")
    table.insert(css, "    text-align: right;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .logo-link
    table.insert(css, ".logo-link {")
    table.insert(css, "    text-decoration: none;")
    table.insert(css, "    border: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .logo-image
    table.insert(css, ".logo-image {")
    table.insert(css, "    border: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .hosted-by
    table.insert(css, ".hosted-by {")
    table.insert(css, "    font-size: 1px;")
    table.insert(css, "    text-decoration: none;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .active-state-logo
    table.insert(css, ".active-state-logo {")
    table.insert(css, "    border: 0;")
    table.insert(css, "    title: \"This site is hosted by ActiveState\";")
    table.insert(css, "}")
    table.insert(css, "")

    -- #globalnav
    table.insert(css, "#globalnav {")
    table.insert(css, "    clear: both;")
    table.insert(css, "}")
    table.insert(css, "")

    -- #globalnav ul
    table.insert(css, "#globalnav ul {")
    table.insert(css, "    list-style-type: none;")
    table.insert(css, "    margin: 0;")
    table.insert(css, "    padding: 0;")
    table.insert(css, "    overflow: hidden;")
    table.insert(css, "}")
    table.insert(css, "")

    -- #globalnav li
    table.insert(css, "#globalnav li {")
    table.insert(css, "    float: left;")
    table.insert(css, "}")
    table.insert(css, "")

    -- #globalnav a
    table.insert(css, "#globalnav a {")
    table.insert(css, "    display: block;")
    table.insert(css, "    padding: 8px 16px;")
    table.insert(css, "    text-decoration: none;")
    table.insert(css, "    color: #000;")
    table.insert(css, "}")
    table.insert(css, "")

    -- #globalnav a.here
    table.insert(css, "#globalnav a.here {")
    table.insert(css, "    background-color: #3163CE;")
    table.insert(css, "    color: white;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .divider-top
    table.insert(css, ".divider-top {")
    table.insert(css, "    border-top: 2px solid #3163CE;")
    table.insert(css, "    width: 780px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .search-table
    table.insert(css, ".search-table {")
    table.insert(css, "    width: 780px;")
    table.insert(css, "    border: 0;")
    table.insert(css, "    cellpadding: 2;")
    table.insert(css, "    cellspacing: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .search-container
    table.insert(css, ".search-container {")
    table.insert(css, "    display: table-cell;")
    table.insert(css, "    vertical-align: middle;")
    table.insert(css, "    margin: 0px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .search-form
    table.insert(css, ".search-form {")
    table.insert(css, "    display: inline;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .search-input
    table.insert(css, ".search-input {")
    table.insert(css, "    size: 20;")
    table.insert(css, "    maxlength: 255;")
    table.insert(css, "    value: \"\";")
    table.insert(css, "}")
    table.insert(css, "")

    -- .submit-button
    table.insert(css, ".submit-button {")
    table.insert(css, "    border: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .hidden-input
    table.insert(css, ".hidden-input {")
    table.insert(css, "    display: none;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .banner
    table.insert(css, ".banner {")
    table.insert(css, "    text-align: right;")
    table.insert(css, "    font-weight: bold;")
    table.insert(css, "    margin: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .divider-yellow
    table.insert(css, ".divider-yellow {")
    table.insert(css, "    border-top: 1px solid #FFCE00;")
    table.insert(css, "    margin-bottom: 2px;")
    table.insert(css, "    width: 780px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .content-table
    table.insert(css, ".content-table {")
    table.insert(css, "    width: 780px;")
    table.insert(css, "    border: 0;")
    table.insert(css, "    cellpadding: 0;")
    table.insert(css, "    cellspacing: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .keylist
    table.insert(css, ".keylist {")
    table.insert(css, "    margin: 0;")
    table.insert(css, "    padding: 0;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .keylist dt
    table.insert(css, ".keylist dt {")
    table.insert(css, "    font-weight: bold;")
    table.insert(css, "    margin-top: 10px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .keylist dd
    table.insert(css, ".keylist dd {")
    table.insert(css, "    margin-left: 20px;")
    table.insert(css, "    margin-bottom: 10px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .footer
    table.insert(css, ".footer {")
    table.insert(css, "    text-align: center;")
    table.insert(css, "    clear: both;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .footer small
    table.insert(css, ".footer small {")
    table.insert(css, "    font-size: 12px;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .footer a
    table.insert(css, ".footer a {")
    table.insert(css, "    text-decoration: none;")
    table.insert(css, "    color: #000;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .footer a:hover
    table.insert(css, ".footer a:hover {")
    table.insert(css, "    text-decoration: underline;")
    table.insert(css, "}")
    table.insert(css, "")

    -- .clear
    table.insert(css, ".clear {")
    table.insert(css, "    clear: both;")
    table.insert(css, "}")

    return table.concat(css, "\n")
end

local function write_css_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file " .. filename .. " for writing")
    end
    
    file:write(generate_css())
    file:close()
end

-- Main execution
local output_filename = arg[1] or "index_5f1051.css"
write_css_to_file(output_filename)
