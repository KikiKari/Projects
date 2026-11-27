#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "033478438022c28ac7e74cf1ce87ffaee9e50f887d4b1bbc90e038f38efbe0ee", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "powershell"}
# offscreen.html — portiert nach powershell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML file for TikTok LIVE Companion with text-to-speech capabilities.
.DESCRIPTION
    This script creates a minimal HTML document that includes a JavaScript file
    for offscreen text-to-speech processing. The output is written to a specified file.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
.EXAMPLE
    .\Generate-OffscreenHtml.ps1 -OutputPath "C:\temp\offscreen.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define HTML structure elements
$docType = "<!doctype html>"
$htmlOpen = "<html lang=`"de`">"
$headOpen = "  <head>"
$metaCharset = "    <meta charset=`"utf-8`">"
$title = "    <title>TikTok LIVE Companion Sprachausgabe</title>"
$headClose = "  </head>"
$bodyOpen = "  <body>"
$scriptTag = "    <script src=`"offscreen.js`"></script>"
$bodyClose = "  </body>"
$htmlClose = "</html>"

# Combine all elements into complete HTML structure
$htmlContent = @(
    $docType
    $htmlOpen
    $headOpen
    $metaCharset
    $title
    $headClose
    $bodyOpen
    $scriptTag
    $bodyClose
    $htmlClose
) -join "`n"

# Write content to specified output file
$htmlContent | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "HTML file generated successfully at: $OutputPath"
