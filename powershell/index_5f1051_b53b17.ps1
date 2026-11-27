#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "bb0d71e1d0ac6e5a0de13759f83ef9732c7c5ee23be0085a13d833dc21f91f6d", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "powershell"}
# index_5f1051.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/index_5f1051.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

<#
    .SYNOPSIS
        Generates the index_5f1051.css file with predefined styles.

    .DESCRIPTION
        This script generates a CSS file that matches the structure and content
        of the original index_5f1051.css. It accepts an optional parameter to specify
        the output path for the generated CSS file.

    .PARAMETER OutputPath
        The path where the CSS file will be saved. Defaults to "./index_5f1051.css".

    .EXAMPLE
        .\Generate-CSS.ps1 -OutputPath "C:\temp\styles.css"
#>

param(
    [string]$OutputPath = "./index_5f1051.css"
)

# Ensure the directory exists
$directory = Split-Path $OutputPath -Parent
if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
}

# Define CSS content as a here-string
$cssContent = @'
/* abstraction-provenance: {"artifact_sha256": "cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */
/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */
/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */

body {
    background-color: white;
    color: black;
    margin: 0;
    padding: 0;
    font-family: Arial, sans-serif;
}

table {
    border-collapse: collapse;
}

.globalnav-container {
    width: 780px;
    border: 0;
    cellpadding: 0;
    cellspacing: 0;
}

.header-left {
    vertical-align: top;
    text-align: left;
}

.header-right {
    vertical-align: top;
    text-align: right;
}

.logo-link {
    text-decoration: none;
    border: 0;
}

.logo-image {
    border: 0;
}

.hosted-by {
    font-size: 1px;
    text-decoration: none;
}

.active-state-logo {
    border: 0;
    title: "This site is hosted by ActiveState";
}

#globalnav {
    clear: both;
}

#globalnav ul {
    list-style-type: none;
    margin: 0;
    padding: 0;
    overflow: hidden;
}

#globalnav li {
    float: left;
}

#globalnav a {
    display: block;
    padding: 8px 16px;
    text-decoration: none;
    color: #000;
}

#globalnav a.here {
    background-color: #3163CE;
    color: white;
}

.divider-top {
    border-top: 2px solid #3163CE;
    width: 780px;
}

.search-table {
    width: 780px;
    border: 0;
    cellpadding: 2;
    cellspacing: 0;
}

.search-container {
    display: table-cell;
    vertical-align: middle;
    margin: 0px;
}

.search-form {
    display: inline;
}

.search-input {
    size: 20;
    maxlength: 255;
    value: "";
}

.submit-button {
    border: 0;
}

.hidden-input {
    display: none;
}

.banner {
    text-align: right;
    font-weight: bold;
    margin: 0;
}

.divider-yellow {
    border-top: 1px solid #FFCE00;
    margin-bottom: 2px;
    width: 780px;
}

.content-table {
    width: 780px;
    border: 0;
    cellpadding: 0;
    cellspacing: 0;
}

.keylist {
    margin: 0;
    padding: 0;
}

.keylist dt {
    font-weight: bold;
    margin-top: 10px;
}

.keylist dd {
    margin-left: 20px;
    margin-bottom: 10px;
}

.footer {
    text-align: center;
    clear: both;
}

.footer small {
    font-size: 12px;
}

.footer a {
    text-decoration: none;
    color: #000;
}

.footer a:hover {
    text-decoration: underline;
}

.clear {
    clear: both;
}
'@

# Write CSS content to file
Set-Content -Path $OutputPath -Value $cssContent -Encoding Utf8

Write-Host "CSS file successfully generated at: $OutputPath"
