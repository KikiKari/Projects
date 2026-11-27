#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "258f39eb2ce879a9decfa7735746b17736fc875e979f76cc28fe3fabe8ec0eb0", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "powershell"}
# index.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create the HTML document structure
$html = @"
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation fÃ¼r TikTok LIVE Companion 0.8.0 â€“ Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion â€“ Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
"@

# Write the HTML content to the specified output file
$html | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "HTML file created at: $OutputPath"
