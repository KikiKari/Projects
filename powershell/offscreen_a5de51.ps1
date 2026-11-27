#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "adf4dec388c8107e631bf97a1987200c19f510ae337688475de3b4291e223762", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "powershell"}
# offscreen.html — portiert nach powershell
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Erstelle den HTML-Inhalt strukturiert
$htmlContent = @"
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>
"@

# Schreibe den Inhalt in die angegebene Datei
$htmlContent | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "HTML-Datei wurde erfolgreich erstellt: $OutputPath"
