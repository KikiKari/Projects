#!/usr/bin/env pwsh
# status-overview.css — portiert nach powershell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-03 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# Create the CSS content using PowerShell syntax
$cssContent = @(
    "*{box-sizing:border-box}",
    "html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}",
    "body{display:flex;flex-direction:column;height:100vh}",
    "header{display:flex;gap:1em;align-items:baseline;padding:0 12px}",
    "h1{font-size:17px;margin:8px 0}",
    "header p{font-size:12px;color:#bbb;margin:0}",
    "main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}",
    ".tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}",
    ".tile h2{font-size:13px;margin:3px 8px}",
    ".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}",
    ".tile p{font-size:11px;margin:3px 8px;color:#ddd}",
    "main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}",
    ".tile[hidden]{display:none}"
)

# Join all CSS rules with newlines
$fullCSS = $cssContent -join "`n"

# Write to the specified output file
Set-Content -Path $OutputFile -Value $fullCSS -Encoding UTF8

Write-Host "CSS file written to: $OutputFile"
