#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "d1639b8c061e4e9d117af2f83f123456194211ac63f082dff7078523dac028f6", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "powershell"}
# index.html — portiert nach powershell
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Erzeugt eine HTML-Weiterleitungsdatei ähnlich der index.html.

.DESCRIPTION
Dieses Skript generiert dynamisch eine HTML-Datei, die auf eine andere Seite weiterleitet,
entsprechend dem Inhalt der gegebenen index.html. Die erzeugte Datei kann optional
in eine angegebene Datei geschrieben werden.

.PARAMETER OutputPath
Gibt den Pfad an, wohin die HTML-Datei geschrieben werden soll.
Wenn nicht angegeben, wird der Inhalt auf die Standardausgabe ausgegeben.

.EXAMPLE
./generate-index.ps1 -OutputPath .\index.html
Schreibt die generierte HTML-Datei in index.html im aktuellen Verzeichnis.

.EXAMPLE
./generate-index.ps1
Gibt die generierte HTML-Struktur auf der Standardausgabe aus.
#>

param(
    [string]$OutputPath
)

# Ziel-URL für Weiterleitung
$targetUrl = "3d.html"

# Erstellen des HTML-Dokuments als String
$htmlContent = @"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0; url=$targetUrl">
<title>Weiterleitung zur 3D-Ansicht</title>
<link rel="canonical" href="$targetUrl">
<script>location.replace('$targetUrl');</script>
</head>
<body>
<p><a href="$targetUrl">3D-Ansicht öffnen</a></p>
</body>
</html>
"@

# Ausgabe je nach Parameter
if ($OutputPath) {
    # Sicherstellen, dass das Verzeichnis existiert
    $directory = Split-Path $OutputPath -Parent
    if ($directory -and !(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
    # Schreiben in Datei
    Set-Content -Path $OutputPath -Value $htmlContent -Encoding Utf8
} else {
    # Ausgabe auf Standardausgabe
    Write-Output $htmlContent
}
