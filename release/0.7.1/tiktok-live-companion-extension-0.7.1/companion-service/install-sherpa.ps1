param([string]$VoiceId = "")
$ErrorActionPreference = "Stop"

$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$modelRoot = Join-Path $configDir "sherpa-onnx"
$voiceConfigPath = Join-Path $configDir "sherpa-voices.json"
$releaseBase = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"
$runtimeReleaseBase = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.2"
$runtimeArchiveName = "sherpa-onnx-v1.13.2-win-x64-shared-MD-Release.tar.bz2"
$runtimeArchiveBytes = 19164500
$runtimeArchiveSha256 = "f91f488186e797dd9e9bc2a3dcbe18ddd244627af5d9fa3707f7a2f3bc4032ce"

New-Item -ItemType Directory -Force -Path $modelRoot | Out-Null

function Assert-ApprovedArchive([string]$Archive, [long]$ExpectedBytes, [string]$ExpectedSha256) {
  $item = Get-Item -LiteralPath $Archive
  if ($item.Length -ne $ExpectedBytes) { throw "Archivgröße stimmt nicht mit dem freigegebenen Katalog überein: $($item.Name)" }
  $actualSha256 = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualSha256 -ne $ExpectedSha256.ToLowerInvariant()) { throw "SHA-256 stimmt nicht mit dem freigegebenen Katalog überein: $($item.Name)" }
}

function Assert-SafeArchiveEntries([string]$Archive) {
  $entries = @(& tar -tf $Archive)
  if ($LASTEXITCODE -ne 0 -or $entries.Count -eq 0) { throw "Archivliste konnte nicht sicher gelesen werden." }
  foreach ($entryValue in $entries) {
    $entry = ([string]$entryValue).Replace('\', '/')
    $parts = @($entry.Split('/') | Where-Object { $_ -ne '' -and $_ -ne '.' })
    if ($entry.StartsWith('/') -or $entry -match '^[A-Za-z]:' -or $parts -contains '..') {
      throw "Archiv enthält einen unzulässigen Pfad."
    }
  }
  $details = @(& tar -tvf $Archive)
  if ($LASTEXITCODE -ne 0) { throw "Archivmetadaten konnten nicht sicher gelesen werden." }
  if ($details | Where-Object { ([string]$_) -match '^[lh]' }) {
    throw "Archive mit symbolischen oder harten Links werden nicht installiert."
  }
}

function Expand-ApprovedArchive([string]$Archive, [long]$ExpectedBytes, [string]$ExpectedSha256, [string]$Destination, [string]$ExpectedRoot = "") {
  $staging = Join-Path $modelRoot (".extract-" + [guid]::NewGuid().ToString("N"))
  try {
    Assert-ApprovedArchive $Archive $ExpectedBytes $ExpectedSha256
    Assert-SafeArchiveEntries $Archive
    New-Item -ItemType Directory -Path $staging | Out-Null
    & tar -xf $Archive -C $staging
    if ($LASTEXITCODE -ne 0) { throw "Freigegebenes Archiv konnte nicht entpackt werden." }
    $source = if ($ExpectedRoot) { Join-Path $staging $ExpectedRoot } else { $staging }
    if (-not (Test-Path -LiteralPath $source)) { throw "Erwartetes Archivverzeichnis fehlt: $ExpectedRoot" }
    if (Test-Path -LiteralPath $Destination) { throw "Installationsziel wurde während der Installation angelegt: $Destination" }
    Move-Item -LiteralPath $source -Destination $Destination
    if (-not $ExpectedRoot) { $staging = "" }
  } finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Recurse -Force }
    if (Test-Path -LiteralPath $Archive) { Remove-Item -LiteralPath $Archive -Force }
  }
}

function Ensure-SherpaCommand {
  $command = Get-Command sherpa-onnx-offline-tts -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }

  $scriptCandidates = @(
    (Join-Path $env:APPDATA "Python\Python314\Scripts\sherpa-onnx-offline-tts.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Python\Python314\Scripts\sherpa-onnx-offline-tts.exe")
  )
  foreach ($candidate in $scriptCandidates) {
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }

  $runtimeDir = Join-Path $modelRoot "runtime-win-x64"
  $runtimeExe = Get-ChildItem -LiteralPath $runtimeDir -Filter "sherpa-onnx-offline-tts.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($runtimeExe) { return $runtimeExe.FullName }

  $runtimeArchive = Join-Path $modelRoot $runtimeArchiveName
  $runtimeUrl = "$runtimeReleaseBase/$runtimeArchiveName"
  Write-Host "Lade Sherpa-ONNX Windows-TTS-Binary."
  Invoke-WebRequest -Uri $runtimeUrl -OutFile $runtimeArchive
  Expand-ApprovedArchive $runtimeArchive $runtimeArchiveBytes $runtimeArchiveSha256 $runtimeDir
  $runtimeExe = Get-ChildItem -LiteralPath $runtimeDir -Filter "sherpa-onnx-offline-tts.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($runtimeExe) { return $runtimeExe.FullName }
  throw "sherpa-onnx wurde nach der Installation nicht gefunden."
}

function Install-Model($voice) {
  $name = [string]$voice.model
  $target = Join-Path $modelRoot $name
  if (Test-Path -LiteralPath $target) { return $target }
  if (-not $voice.bytes -or [string]$voice.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw "Freigabedaten fehlen für Sherpa-Stimme: $($voice.id)" }
  $archive = Join-Path $modelRoot "$name.tar.bz2"
  $url = "$releaseBase/$name.tar.bz2"
  Write-Host "Lade Sherpa-Stimme: $name"
  Invoke-WebRequest -Uri $url -OutFile $archive
  Expand-ApprovedArchive $archive ([long]$voice.bytes) ([string]$voice.sha256) $target $name
  return $target
}

$sherpaCommand = Ensure-SherpaCommand
$catalogPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "voice-catalog.json"
$catalog = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json
$voices = if ($VoiceId) {
  @($catalog.voices | Where-Object { $_.id -eq $VoiceId })
} else {
  @($catalog.voices | Where-Object { $_.defaultInstall -eq $true })
}
if ($voices.Count -eq 0) { throw "Unbekannte oder nicht freigegebene Sherpa-Stimme: $VoiceId" }

$voiceMap = @{}
if (Test-Path -LiteralPath $voiceConfigPath) {
  $existingConfig = Get-Content -Raw -LiteralPath $voiceConfigPath | ConvertFrom-Json
  foreach ($voice in @($existingConfig.voices)) { if ($voice.id) { $voiceMap[[string]$voice.id] = $voice } }
}
foreach ($voice in $voices) {
  $modelDir = Install-Model $voice
  $voiceMap[[string]$voice.id] = [ordered]@{
    id = $voice.id
    name = $voice.name
    culture = $voice.culture
    gender = $voice.gender
    engine = "sherpa-onnx"
    family = if ($voice.family) { $voice.family } else { "vits-piper" }
    languageCode = if ($voice.languageCode) { $voice.languageCode } else { "" }
    sid = if ($null -ne $voice.sid) { [int]$voice.sid } else { 0 }
    model = $voice.model
    modelDir = $modelDir
  }
}

$config = [ordered]@{
  sherpaExecutable = $sherpaCommand
  voices = @($voiceMap.Values | Sort-Object culture, name)
}

[IO.File]::WriteAllText($voiceConfigPath, ($config | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "Sherpa-Stimmen gespeichert: $voiceConfigPath"
