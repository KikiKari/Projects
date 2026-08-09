#!/usr/bin/env pwsh
# index.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the index.html file for TikTok LIVE Companion documentation.
.DESCRIPTION
    This script creates an HTML file with the structure and metadata required
    for the TikTok LIVE Companion documentation. It accepts an optional
    -OutputPath parameter to specify where the file should be written.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
    Defaults to "./index.html" if not specified.
.EXAMPLE
    .\Generate-IndexHtml.ps1 -OutputPath "C:\temp\index.html"
#>

param(
    [string]$OutputPath = "./index.html"
)

# Create the HTML structure
$html = @"
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
"@

# Write the HTML content to the specified file
$html | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Generated HTML file at: $OutputPath"
