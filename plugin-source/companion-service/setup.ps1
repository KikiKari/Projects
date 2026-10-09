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

$serviceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $serviceDir 'service-runtime.ps1')
$config = [ordered]@{}
if ($existing) {
  foreach ($property in $existing.PSObject.Properties) { $config[$property.Name] = $property.Value }
}
$config.pairingCode = $pairingCode
$config.auddApiToken = $auddToken
$config.extensionId = $configuredExtensionId
$config.port = Get-TlcServicePort $existing
if ($BootstrapNonce) {
  if ($BootstrapNonce -notmatch '^[A-Za-z0-9_-]{32,128}$') { throw "Der Pairing-Nonce ist ungültig." }
  $config.bootstrapNonce = $BootstrapNonce
  $config.bootstrapExpiresAtUtc = [DateTime]::UtcNow.AddMinutes(2).ToString("o")
}
$json = $config | ConvertTo-Json -Depth 32
[IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "Konfiguration gespeichert: $configPath"
if ($existingInstallation) {
  Write-Host "Bestehende Sprachdienst-Konfiguration wurde beibehalten und aktualisiert."
} else {
  Write-Host "Neue Sprachdienst-Konfiguration wurde angelegt."
}
Write-Host "Pairing-Code fuer das Sidepanel: $pairingCode"

if (-not (Test-Path -LiteralPath (Join-Path $configDir 'sherpa-voices.json'))) {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $serviceDir "install-sherpa.ps1")
  if ($LASTEXITCODE -ne 0) { throw 'Sherpa-Einrichtung fehlgeschlagen.' }
}

$startScriptPath = Join-Path $configDir "start-service.ps1"
$installScriptPath = Join-Path $configDir "install-service.ps1"
$protocolScriptPath = Join-Path $configDir "protocol-handler.cmd"
$setupScriptPath = Join-Path $serviceDir "setup.ps1"
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
  Write-Host "Der Pairing-Code wird automatisch an die anfragende Erweiterung uebergeben."
  Write-Host "Nur falls die Kopplung nicht bestaetigt wird, kann der oben angezeigte Code manuell verwendet werden."
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
  [IO.File]::WriteAllText("$configPath", (`$serviceConfig | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding(`$false)))
}
. "$serviceDir\service-runtime.ps1"
Start-TlcService -ConfigPath "$configPath" -ServiceDirectory "$serviceDir"
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

echo TikTok LIVE Companion wird mit CMD eingerichtet ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$setupScriptPath" -ExtensionId "!TLC_EXTENSION!" -BootstrapNonce "!TLC_NONCE!"
if errorlevel 1 (
  echo Installation fehlgeschlagen. Das Fenster bleibt zur Diagnose offen.
  pause
  exit /b 1
)

:install_complete
echo.
echo Einrichtung abgeschlossen. Der Sprachdienst wurde gestartet.
echo Der Pairing-Code wird automatisch an die anfragende Erweiterung uebergeben.
echo Falls das Sidepanel die Kopplung nicht bestaetigt, kann der oben angezeigte Code weiterhin manuell verwendet werden.
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

Start-TlcService -ConfigPath $configPath -ServiceDirectory $serviceDir -Restart
Write-Host "Vorhandene Kopplung, Dienstport, API-Einstellungen und Sherpa-Stimmen bleiben erhalten."
