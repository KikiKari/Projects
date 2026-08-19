#!/usr/bin/env pwsh
# index.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML file for TikTok LIVE Companion documentation.
.DESCRIPTION
    This script creates an HTML document with metadata and structure matching the original,
    and writes it to a specified output file.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
.EXAMPLE
    .\generate-html.ps1 -OutputPath "index.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create HTML content using PowerShell's here-string and variable interpolation capabilities
$htmlContent = @"
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
"@

# Write the content to the specified output file
$htmlContent | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "HTML file generated successfully at: $OutputPath"
