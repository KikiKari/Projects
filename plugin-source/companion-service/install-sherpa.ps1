$ErrorActionPreference = "Stop"

$configDir = Join-Path $env:LOCALAPPDATA "TikTokLiveCompanion"
$modelRoot = Join-Path $configDir "sherpa-onnx"
$voiceConfigPath = Join-Path $configDir "sherpa-voices.json"
$releaseBase = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"
$runtimeReleaseBase = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.4"
$runtimeArchiveName = "sherpa-onnx-v1.13.4-win-x64-shared-MT-Release.tar.bz2"

New-Item -ItemType Directory -Force -Path $modelRoot | Out-Null

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

  New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
  $runtimeArchive = Join-Path $modelRoot $runtimeArchiveName
  $runtimeUrl = "$runtimeReleaseBase/$runtimeArchiveName"
  Write-Host "Lade Sherpa-ONNX Windows-TTS-Binary."
  Invoke-WebRequest -Uri $runtimeUrl -OutFile $runtimeArchive
  tar -xf $runtimeArchive -C $runtimeDir
  Remove-Item -LiteralPath $runtimeArchive -Force
  $runtimeExe = Get-ChildItem -LiteralPath $runtimeDir -Filter "sherpa-onnx-offline-tts.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($runtimeExe) { return $runtimeExe.FullName }
  throw "sherpa-onnx wurde nach der Installation nicht gefunden."
}

function Install-Model([string]$name) {
  $target = Join-Path $modelRoot $name
  if (Test-Path -LiteralPath $target) { return $target }
  $archive = Join-Path $modelRoot "$name.tar.bz2"
  $url = "$releaseBase/$name.tar.bz2"
  Write-Host "Lade Sherpa-Stimme: $name"
  Invoke-WebRequest -Uri $url -OutFile $archive
  tar -xf $archive -C $modelRoot
  if (-not (Test-Path -LiteralPath $target)) { throw "Sherpa-Modell wurde nicht entpackt: $name" }
  Remove-Item -LiteralPath $archive -Force
  return $target
}

$sherpaCommand = Ensure-SherpaCommand
$voices = @(
  @{ id = "sherpa-de-eva-k"; name = "Sherpa Eva"; culture = "de-DE"; gender = "Female"; model = "vits-piper-de_DE-eva_k-x_low" },
  @{ id = "sherpa-de-kerstin"; name = "Sherpa Kerstin"; culture = "de-DE"; gender = "Female"; model = "vits-piper-de_DE-kerstin-low" },
  @{ id = "sherpa-de-ramona"; name = "Sherpa Ramona"; culture = "de-DE"; gender = "Female"; model = "vits-piper-de_DE-ramona-low" },
  @{ id = "sherpa-de-thorsten"; name = "Sherpa Thorsten"; culture = "de-DE"; gender = "Male"; model = "vits-piper-de_DE-thorsten-medium" },
  @{ id = "sherpa-de-karlsson"; name = "Sherpa Karlsson"; culture = "de-DE"; gender = "Male"; model = "vits-piper-de_DE-karlsson-low" },
  @{ id = "sherpa-de-pavoque"; name = "Sherpa Pavoque"; culture = "de-DE"; gender = "Male"; model = "vits-piper-de_DE-pavoque-low" },
  @{ id = "sherpa-en-amy"; name = "Sherpa Amy"; culture = "en-US"; gender = "Female"; model = "vits-piper-en_US-amy-low" },
  @{ id = "sherpa-en-lessac"; name = "Sherpa Lessac"; culture = "en-US"; gender = "Female"; model = "vits-piper-en_US-lessac-medium" },
  @{ id = "sherpa-en-libritts"; name = "Sherpa LibriTTS"; culture = "en-US"; gender = "Female"; model = "vits-piper-en_US-libritts_r-medium" },
  @{ id = "sherpa-en-ryan"; name = "Sherpa Ryan"; culture = "en-US"; gender = "Male"; model = "vits-piper-en_US-ryan-high" },
  @{ id = "sherpa-en-danny"; name = "Sherpa Danny"; culture = "en-US"; gender = "Male"; model = "vits-piper-en_US-danny-low" },
  @{ id = "sherpa-en-alan"; name = "Sherpa Alan"; culture = "en-US"; gender = "Male"; model = "vits-piper-en_GB-alan-low" }
)

$installedVoices = foreach ($voice in $voices) {
  $modelDir = Install-Model $voice.model
  [ordered]@{
    id = $voice.id
    name = $voice.name
    culture = $voice.culture
    gender = $voice.gender
    engine = "sherpa-onnx"
    modelDir = $modelDir
  }
}

$config = [ordered]@{
  sherpaExecutable = $sherpaCommand
  voices = @($installedVoices)
}

[IO.File]::WriteAllText($voiceConfigPath, ($config | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "Sherpa-Stimmen gespeichert: $voiceConfigPath"
