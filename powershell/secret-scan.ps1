#!/usr/bin/env pwsh
# secret-scan.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/secret-scan.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

$root = Split-Path $PSScriptRoot -Parent
$skipped = @(
  "node_modules"
  ".next"
  ".git"
  ".pytest_cache"
  "__pycache__"
  "media-production/raw"
  "media-production/private"
)
$patterns = @(
  [regex] 'sk-(?:proj|svcacct|ant|or-v1|admin)-[A-Za-z0-9_-]{20,}'
  [regex] '(?:nvapi|lin_api|ntn|vcp)_[A-Za-z0-9_-]{20,}'
  [regex] 'ELEVENLABS_API_KEY\s*=\s*["''"]?[A-Za-z0-9]{20,}'
  [regex] 'WAVESPEED_API_KEY\s*=\s*["''"]?[A-Za-z0-9]{20,}'
)
$findings = @()

function Walk-Directory($url, $relative = "") {
  $items = Get-ChildItem -Path $url -Force
  foreach ($entry in $items) {
    $rel = Join-Path $relative $entry.Name
    $skipEntry = $false
    
    if ($entry.Name -eq ".env" -or 
        ($entry.Name.StartsWith(".env.") -and $entry.Name -ne ".env.example")) {
      $skipEntry = $true
    }
    
    foreach ($item in $skipped) {
      if ($rel -eq $item -or $rel.StartsWith("$item$([System.IO.Path]::DirectorySeparatorChar)") -or $rel.Split([System.IO.Path]::DirectorySeparatorChar) -contains $item) {
        $skipEntry = $true
        break
      }
    }
    
    if ($skipEntry) { continue }
    
    $target = $entry.FullName
    if ($entry.PSIsContainer) {
      Walk-Directory $target $rel
    }
    else {
      if ($entry.Length -lt 2000000) {
        try {
          $content = Get-Content -Path $target -Raw -Encoding UTF8
          foreach ($pattern in $patterns) {
            if ($pattern.IsMatch($content)) {
              $findings += $rel
              break
            }
          }
        } catch {
          # Ignore files that can't be read
        }
      }
    }
  }
}

Walk-Directory $root

if ($findings.Count -gt 0) {
  $uniqueFindings = $findings | Sort-Object -Unique
  $errorMessage = "Secret-Scan fehlgeschlagen: $($uniqueFindings -join ', ')"
  Write-Error $errorMessage
  exit 1
}

Write-Host "Secret-Scan bestanden."
