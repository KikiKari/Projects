$ErrorActionPreference = "Stop"
$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$configPath = Join-Path $configDir "service.json"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$bytes = New-Object byte[] 24
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$pairingCode = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$secureToken = Read-Host "AudD API-Token (leer lassen, wenn Songerkennung noch nicht genutzt wird)" -AsSecureString
$tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
try {
  $auddToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPtr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
}

$config = [ordered]@{
  pairingCode = $pairingCode
  auddApiToken = $auddToken
  port = 43117
}
$json = $config | ConvertTo-Json
[IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "Konfiguration gespeichert: $configPath"
Write-Host "Pairing-Code für das Sidepanel: $pairingCode"
