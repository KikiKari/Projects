#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "a25ac786dadecf3ba32e19a8f307e28091123859d4cd8b8f63d576203a36b521", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "powershell"}
# peak-limiter.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

<#
    .SYNOPSIS
        Generates the peak-limiter.css file.

    .DESCRIPTION
        This script generates the peak-limiter.css file with predefined styles
        and writes it to a specified output file.

    .PARAMETER OutputPath
        The path where the generated CSS file will be saved.

    .EXAMPLE
        .\generate-css.ps1 -OutputPath "peak-limiter.css"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS content as a here-string
$cssContent = @'
/* abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"} */
/* peak-limiter.html — portiert nach css */
/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */
/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

body {
  font: 16px system-ui;
  max-width: 1000px;
  margin: 40px auto;
  padding: 20px;
}

pre {
  white-space: pre-wrap;
}

button {
  padding: 12px;
}
'@

# Write the CSS content to the specified output file
Set-Content -Path $OutputPath -Value $cssContent -Encoding Utf8

Write-Host "CSS file generated at: $OutputPath"
