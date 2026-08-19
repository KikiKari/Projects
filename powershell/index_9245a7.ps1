#!/usr/bin/env pwsh
# index.html — portiert nach powershell
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# Erstelle das HTML-Dokument strukturiert
$html = @"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0; url=3d.html">
<title>Weiterleitung zur 3D-Ansicht</title>
<link rel="canonical" href="3d.html">
<script>location.replace('3d.html');</script>
</head>
<body>
<p><a href="3d.html">3D-Ansicht öffnen</a></p>
</body>
</html>
"@

# Schreibe das HTML-Dokument in die angegebene Datei
$html | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host "HTML-Datei wurde erfolgreich erstellt: $OutputFile"
