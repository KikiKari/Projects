$ErrorActionPreference = "Stop"
$configPath = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion\service.json"
$extensionId = ""
if (Test-Path -LiteralPath $configPath) {
  try {
    $existing = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
    $extensionId = [string]$existing.extensionId
  } catch {
    $extensionId = ""
  }
}
if ($extensionId -notmatch '^[a-p]{32}$') {
  Write-Host "Die Erweiterungs-ID steht auf edge://extensions oder chrome://extensions beim TikTok LIVE Companion."
  $extensionId = Read-Host "Erweiterungs-ID"
}
if ($extensionId -notmatch '^[a-p]{32}$') { throw "Die Erweiterungs-ID ist ungueltig." }
$serviceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $serviceDir "setup.ps1") -ExtensionId $extensionId
