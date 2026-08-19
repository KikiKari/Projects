#!/usr/bin/env pwsh
# index.css — portiert nach powershell
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create the CSS content as a here-string
$cssContent = @"
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
"@

# Write the CSS content to the specified output file
Set-Content -Path $OutputPath -Value $cssContent -Encoding UTF8

Write-Host "CSS file has been generated at: $OutputPath"
