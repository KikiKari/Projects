param([string]$ExtensionId = "")
$ErrorActionPreference = "Stop"
$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$configPath = Join-Path $configDir "service.json"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$existing = if (Test-Path -LiteralPath $configPath) { Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json } else { $null }
if ($existing -and $existing.pairingCode) {
  $pairingCode = [string]$existing.pairingCode
} else {
  $bytes = New-Object byte[] 24
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
  $pairingCode = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}
$auddToken = if ($existing -and $null -ne $existing.auddApiToken) { [string]$existing.auddApiToken } else { "" }
$configuredExtensionId = if ($ExtensionId) { $ExtensionId } elseif ($existing -and $existing.extensionId) { [string]$existing.extensionId } else { "" }
if ($configuredExtensionId -notmatch '^[a-p]{32}$') {
  throw "Die Chrome-Erweiterungs-ID fehlt oder ist ungültig. Bitte den im Sidepanel angezeigten Setup-Befehl verwenden."
}

$config = [ordered]@{
  pairingCode = $pairingCode
  auddApiToken = $auddToken
  extensionId = $configuredExtensionId
  port = 43117
}
$json = $config | ConvertTo-Json
[IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "Konfiguration gespeichert: $configPath"
Write-Host "Pairing-Code für das Sidepanel: $pairingCode"

$serviceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $serviceDir "install-sherpa.ps1")

$npmPath = (Get-Command npm.cmd -ErrorAction Stop).Source
$startScriptPath = Join-Path $configDir "start-service.ps1"
$startScript = @"
param([string]`$LaunchUri = "")
`$ErrorActionPreference = "Stop"
if (`$LaunchUri -match '[?&]nonce=([A-Za-z0-9_-]{32,128})') {
  `$serviceConfig = Get-Content -Raw -LiteralPath "$configPath" | ConvertFrom-Json
  `$serviceConfig | Add-Member -NotePropertyName bootstrapNonce -NotePropertyValue `$Matches[1] -Force
  `$serviceConfig | Add-Member -NotePropertyName bootstrapExpiresAtUtc -NotePropertyValue ([DateTime]::UtcNow.AddMinutes(2).ToString("o")) -Force
  [IO.File]::WriteAllText("$configPath", (`$serviceConfig | ConvertTo-Json), (New-Object Text.UTF8Encoding(`$false)))
}
`$client = New-Object Net.Sockets.TcpClient
try {
  `$connect = `$client.BeginConnect("127.0.0.1", 43117, `$null, `$null)
  if (`$connect.AsyncWaitHandle.WaitOne(250) -and `$client.Connected) { exit 0 }
} finally {
  `$client.Dispose()
}
Start-Process -FilePath "$npmPath" -ArgumentList @("start") -WorkingDirectory "$serviceDir" -WindowStyle Hidden
"@
[IO.File]::WriteAllText($startScriptPath, $startScript, (New-Object Text.UTF8Encoding($false)))

$protocolKey = "HKCU:\Software\Classes\tiktok-live-companion"
New-Item -Path "$protocolKey\shell\open\command" -Force | Out-Null
New-ItemProperty -Path $protocolKey -Name "(Default)" -Value "URL:TikTok LIVE Companion" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $protocolKey -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
$protocolCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startScriptPath`" `"%1`""
New-ItemProperty -Path "$protocolKey\shell\open\command" -Name "(Default)" -Value $protocolCommand -PropertyType String -Force | Out-Null

& $startScriptPath
Write-Host "Der Sprachdienst wurde mit npm start im Hintergrund gestartet."
