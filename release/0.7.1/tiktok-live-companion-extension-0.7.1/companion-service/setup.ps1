param(
  [string]$ExtensionId = "",
  [string]$BootstrapNonce = ""
)
$ErrorActionPreference = "Stop"
$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$configPath = Join-Path $configDir "service.json"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$existing = if (Test-Path -LiteralPath $configPath) { Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json } else { $null }
$existingInstallation = [bool]($existing -and $existing.pairingCode)
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
  throw "Die Chrome-Erweiterungs-ID fehlt oder ist ungültig."
}

$config = [ordered]@{
  pairingCode = $pairingCode
  auddApiToken = $auddToken
  extensionId = $configuredExtensionId
  port = 43117
}
if ($BootstrapNonce) {
  if ($BootstrapNonce -notmatch '^[A-Za-z0-9_-]{32,128}$') { throw "Der Pairing-Nonce ist ungültig." }
  $config.bootstrapNonce = $BootstrapNonce
  $config.bootstrapExpiresAtUtc = [DateTime]::UtcNow.AddMinutes(2).ToString("o")
}
$json = $config | ConvertTo-Json
[IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "Konfiguration gespeichert: $configPath"
if ($existingInstallation) {
  Write-Host "Bestehende Sprachdienst-Konfiguration wurde beibehalten und aktualisiert."
} else {
  Write-Host "Neue Sprachdienst-Konfiguration wurde angelegt."
}
Write-Host "Pairing-Code fuer das Sidepanel: $pairingCode"

$serviceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $serviceDir "install-sherpa.ps1")

$npmPath = (Get-Command npm.cmd -ErrorAction Stop).Source
$startScriptPath = Join-Path $configDir "start-service.ps1"
$installScriptPath = Join-Path $configDir "install-service.ps1"
$protocolScriptPath = Join-Path $configDir "protocol-handler.cmd"
$setupScriptPath = Join-Path $serviceDir "setup.ps1"
$serviceRoot = Split-Path -Parent $serviceDir
foreach ($generatedScriptPath in @($startScriptPath, $installScriptPath)) {
  if (Test-Path -LiteralPath $generatedScriptPath) {
    Remove-Item -LiteralPath $generatedScriptPath -Force
  }
}
$installScript = @"
param(
  [Parameter(Mandatory = `$true)][string]`$ExtensionId,
  [Parameter(Mandatory = `$true)][string]`$BootstrapNonce
)
`$ErrorActionPreference = "Stop"
Set-Location -LiteralPath "$serviceDir"
try {
  & "$setupScriptPath" -ExtensionId `$ExtensionId -BootstrapNonce `$BootstrapNonce
  Write-Host "Einrichtung abgeschlossen. Der Sprachdienst wurde gestartet."
  Write-Host "Den individuellen Pairing-Code oben markieren und mit STRG+C kopieren."
  Write-Host "Danach im Sidepanel in das Feld Pairing-Code klicken und mit STRG+V einfuegen."
  Read-Host "Eingabetaste zum Schliessen"
} catch {
  Write-Error `$_
  Read-Host "Installation fehlgeschlagen. Eingabetaste zum Schließen"
  exit 1
}
"@
[IO.File]::WriteAllText($installScriptPath, $installScript, (New-Object Text.UTF8Encoding($false)))
$startScript = @"
param([string]`$LaunchUri = "")
`$ErrorActionPreference = "Stop"
if (`$LaunchUri -match '^tiktok-live-companion://install(?:[/?]|$)') {
  `$extensionMatch = [regex]::Match(`$LaunchUri, '^tiktok-live-companion://install/[A-Za-z0-9_-]{32,128}/([a-p]{32})$')
  `$nonceMatch = [regex]::Match(`$LaunchUri, '^tiktok-live-companion://install/([A-Za-z0-9_-]{32,128})/[a-p]{32}$')
  if (-not `$extensionMatch.Success -or -not `$nonceMatch.Success) { exit 2 }
  `$shell = Get-Command pwsh.exe -ErrorAction SilentlyContinue
  if (-not `$shell) { `$shell = Get-Command powershell.exe -ErrorAction Stop }
  `$arguments = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', '`"$installScriptPath`"',
    '-ExtensionId', `$extensionMatch.Groups[1].Value,
    '-BootstrapNonce', `$nonceMatch.Groups[1].Value
  )
  `$process = Start-Process -FilePath `$shell.Source -ArgumentList `$arguments -WorkingDirectory "$serviceDir" -Wait -PassThru
  exit `$process.ExitCode
}
if (`$LaunchUri -match '^tiktok-live-companion://start/([A-Za-z0-9_-]{32,128})$') {
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

$protocolScript = @"
@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "TLC_URI=%~1"
if /i not "!TLC_URI:~0,31!"=="tiktok-live-companion://install" goto start_service

set "TLC_EXTENSION="
set "TLC_NONCE="
set "TLC_PAYLOAD=!TLC_URI:tiktok-live-companion://install/=!"
for /f "tokens=1,2 delims=/" %%A in ("!TLC_PAYLOAD!") do (
  set "TLC_NONCE=%%A"
  set "TLC_EXTENSION=%%B"
)
if not defined TLC_EXTENSION exit /b 2
if not defined TLC_NONCE exit /b 2

cd /d "$serviceRoot"
echo TikTok LIVE Companion wird mit CMD eingerichtet ...
call "$npmPath" run setup -- -ExtensionId "!TLC_EXTENSION!" -BootstrapNonce "!TLC_NONCE!"
if not errorlevel 1 goto install_complete

echo CMD-Installation fehlgeschlagen. PowerShell-Fallback wird ausgefuehrt ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$setupScriptPath" -ExtensionId "!TLC_EXTENSION!" -BootstrapNonce "!TLC_NONCE!"
if errorlevel 1 (
  echo Installation fehlgeschlagen. Das Fenster bleibt zur Diagnose offen.
  pause
  exit /b 1
)

:install_complete
echo.
echo Einrichtung abgeschlossen. Der Sprachdienst wurde gestartet.
echo Den individuellen Pairing-Code oben markieren und mit STRG+C kopieren.
echo Danach im Sidepanel in das Feld Pairing-Code klicken und mit STRG+V einfuegen.
echo.
pause
exit /b 0

:start_service
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$startScriptPath" "%TLC_URI%"
exit /b %errorlevel%
"@
[IO.File]::WriteAllText($protocolScriptPath, $protocolScript, (New-Object Text.UTF8Encoding($false)))

$protocolKey = "HKCU:\Software\Classes\tiktok-live-companion"
New-Item -Path "$protocolKey\shell\open\command" -Force | Out-Null
New-ItemProperty -Path $protocolKey -Name "(Default)" -Value "URL:TikTok LIVE Companion" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $protocolKey -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
$protocolCommand = "cmd.exe /d /c `"`"$protocolScriptPath`" `"%1`"`""
New-ItemProperty -Path "$protocolKey\shell\open\command" -Name "(Default)" -Value $protocolCommand -PropertyType String -Force | Out-Null

if ($BootstrapNonce) {
  $headers = @{
    Origin = "chrome-extension://$configuredExtensionId"
    Authorization = "Bearer $pairingCode"
  }
  $runningService = $null
  try {
    $runningService = Invoke-RestMethod -Uri "http://127.0.0.1:43117/v1/health" -Headers $headers -Method Get -TimeoutSec 2
  } catch {
    $runningService = $null
  }
  if ($runningService -and $runningService.version -eq "0.7.1") {
    $listenerPid = 0
    try {
      $listener = Get-NetTCPConnection -LocalAddress "127.0.0.1" -LocalPort 43117 -State Listen -ErrorAction Stop | Select-Object -First 1
      $listenerPid = [int]$listener.OwningProcess
    } catch {
      $netstatLine = netstat -ano -p tcp | Select-String -Pattern '^\s*TCP\s+127\.0\.0\.1:43117\s+\S+\s+LISTENING\s+(\d+)\s*$' | Select-Object -First 1
      if ($netstatLine -and $netstatLine.Matches.Count) { $listenerPid = [int]$netstatLine.Matches[0].Groups[1].Value }
    }
    if ($listenerPid -le 0) { throw "Der laufende Sprachdienst konnte nicht eindeutig ermittelt werden." }
    $listenerProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $listenerPid"
    if (-not $listenerProcess -or $listenerProcess.Name -ne "node.exe" -or $listenerProcess.CommandLine -notmatch '(?i)\bnode(?:\.exe)?\b\s+server\.mjs\b') {
      throw "Port 43117 wird nicht vom erwarteten TikTok-LIVE-Companion-Dienst verwendet."
    }
    Stop-Process -Id $listenerPid -Force
    Write-Host "Vorhandener Sprachdienst wurde fuer die saubere Neueinrichtung beendet."
    for ($attempt = 0; $attempt -lt 20; $attempt += 1) {
      Start-Sleep -Milliseconds 100
      $probe = New-Object Net.Sockets.TcpClient
      try {
        $connection = $probe.BeginConnect("127.0.0.1", 43117, $null, $null)
        if (-not ($connection.AsyncWaitHandle.WaitOne(100) -and $probe.Connected)) { break }
      } finally {
        $probe.Dispose()
      }
    }
  }
}

& $startScriptPath
Write-Host "Der Sprachdienst wurde mit npm start im Hintergrund gestartet."
