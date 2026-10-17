param([string]$VoiceId = "")
$ErrorActionPreference = "Stop"
# A Node process started from PowerShell 7 can inherit its module search path.
# Load the utility module belonging to the interpreter running this installer.
Import-Module (Join-Path $PSHOME "Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1") -Force

$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$modelRoot = Join-Path $configDir "sherpa-onnx"
$voiceConfigPath = Join-Path $configDir "sherpa-voices.json"
$releaseBase = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"

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
  $approvedRoot = [IO.Path]::GetFullPath($modelRoot).TrimEnd('\') + '\'
  foreach ($candidate in @($staging, $Destination, $Archive)) {
    if (-not [IO.Path]::GetFullPath($candidate).StartsWith($approvedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Installationspfad liegt außerhalb des Modellverzeichnisses." }
  }
  try {
    Assert-ApprovedArchive $Archive $ExpectedBytes $ExpectedSha256
    Assert-SafeArchiveEntries $Archive
    New-Item -ItemType Directory -Path $staging | Out-Null
    & tar -xf $Archive -C $staging
    if ($LASTEXITCODE -ne 0) { throw "Freigegebenes Archiv konnte nicht entpackt werden." }
    $source = if ($ExpectedRoot) { Join-Path $staging $ExpectedRoot } else { $staging }
    if (-not [IO.Path]::GetFullPath($source).StartsWith([IO.Path]::GetFullPath($staging), [StringComparison]::OrdinalIgnoreCase)) { throw "Archivquelle liegt außerhalb des Installationsverzeichnisses." }
    if (-not (Test-Path -LiteralPath $source)) { throw "Erwartetes Archivverzeichnis fehlt: $ExpectedRoot" }
    if (Test-Path -LiteralPath $Destination) { throw "Installationsziel wurde während der Installation angelegt: $Destination" }
    Move-Item -LiteralPath $source -Destination $Destination
    if (-not $ExpectedRoot) { $staging = "" }
  } finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Recurse -Force }
    if (Test-Path -LiteralPath $Archive) { Remove-Item -LiteralPath $Archive -Force }
  }
}

function Install-Model($voice) {
  $name = [string]$voice.model
  $target = Join-Path $modelRoot $name
  if (Test-Path -LiteralPath $target) { return $target }
  if (-not $voice.bytes -or [string]$voice.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw "Freigabedaten fehlen für Sherpa-Stimme: $($voice.id)" }
  $archive = Join-Path $modelRoot "$name.tar.bz2"
  $url = "$releaseBase/$name.tar.bz2"
  Write-Host "Lade Sherpa-Stimme: $name"
  if (-not (Test-Path -LiteralPath $archive)) { Invoke-WebRequest -Uri $url -OutFile $archive }
  Expand-ApprovedArchive $archive ([long]$voice.bytes) ([string]$voice.sha256) $target $name
  return $target
}

$runtimePython = Join-Path $modelRoot "python-runtime\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $runtimePython)) {
  $launcher = Get-Command py -ErrorAction SilentlyContinue
  if (-not $launcher) { throw "Python 3 mit Windows-Python-Launcher wird für Unicode-Sherpa-Stimmen benötigt." }
  & $launcher.Source -3 -m venv (Join-Path $modelRoot "python-runtime")
  if ($LASTEXITCODE -ne 0) { throw "Sherpa-Python-Umgebung konnte nicht erstellt werden." }
}
$runtimeProbe = @'
import sys
try:
    import sherpa_onnx, numpy
    valid = sherpa_onnx.__version__ == '1.13.4' and numpy.__version__ == '2.5.4'
except ImportError:
    valid = False
sys.exit(0 if valid else 1)
'@
& $runtimePython -c $runtimeProbe
if ($LASTEXITCODE -ne 0) {
  & $runtimePython -m pip install --only-binary=:all: -r (Join-Path $PSScriptRoot "sherpa-runtime-requirements.txt")
  if ($LASTEXITCODE -ne 0) { throw "Sherpa-Python-Laufzeit konnte nicht installiert werden." }
}
$sherpaCommand = "sherpa-onnx-offline-tts"
$catalogPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "voice-catalog.json"
$catalog = Get-Content -Raw -Encoding UTF8 -LiteralPath $catalogPath | ConvertFrom-Json
$voices = if ($VoiceId) {
  @($catalog.voices | Where-Object { $_.id -eq $VoiceId })
} else {
  @($catalog.voices | Where-Object { $_.defaultInstall -eq $true })
}
if ($voices.Count -eq 0) { throw "Unbekannte oder nicht freigegebene Sherpa-Stimme: $VoiceId" }

$voiceMap = @{}
if (Test-Path -LiteralPath $voiceConfigPath) {
  $existingConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $voiceConfigPath | ConvertFrom-Json
  foreach ($voice in @($existingConfig.voices)) { if ($voice.id) { $voiceMap[[string]$voice.id] = $voice } }
}
foreach ($voice in $voices) {
  $modelDir = Install-Model $voice
  $sid = if ($null -ne $voice.sid) { [int]$voice.sid } else { 0 }
  $speakers = if ($voice.speakers) { [int]$voice.speakers } elseif ($voice.family -eq "supertonic") { 10 } else { 1 }
  if ($sid -lt 0 -or $sid -ge $speakers) { throw "Ungültige Sprecher-ID: $($voice.id)" }
  $required = if ($voice.family -eq "supertonic") {
    @("duration_predictor.int8.onnx", "text_encoder.int8.onnx", "vector_estimator.int8.onnx", "vocoder.int8.onnx", "tts.json", "unicode_indexer.bin", "voice.bin")
  } else { @("tokens.txt") }
  foreach ($file in $required) { if (-not (Test-Path -LiteralPath (Join-Path $modelDir $file) -PathType Leaf)) { throw "Modelldatei fehlt: $file" } }
  if ($voice.family -ne "supertonic" -and -not (Get-ChildItem -LiteralPath $modelDir -Filter "*.onnx" -File)) { throw "ONNX-Modelldatei fehlt." }
  $voiceMap[[string]$voice.id] = [ordered]@{
    id = $voice.id
    name = $voice.name
    culture = $voice.culture
    gender = $voice.gender
    engine = "sherpa-onnx"
    family = if ($voice.family) { $voice.family } else { "vits-piper" }
    languageCode = if ($voice.languageCode) { $voice.languageCode } else { "" }
    group = if ($voice.group) { $voice.group } else { "" }
    speakers = $speakers
    sid = if ($null -ne $voice.sid) { [int]$voice.sid } else { 0 }
    model = $voice.model
    modelDir = $modelDir
  }
}

$config = [ordered]@{
  sherpaExecutable = if ($existingConfig -and $existingConfig.sherpaExecutable) { $existingConfig.sherpaExecutable } else { $sherpaCommand }
  sherpaPython = $runtimePython
  voices = @($voiceMap.Values | Sort-Object culture, name)
}

[IO.File]::WriteAllText($voiceConfigPath, ($config | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "Sherpa-Stimmen gespeichert: $voiceConfigPath"
