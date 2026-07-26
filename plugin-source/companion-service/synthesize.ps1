param(
  [Parameter(Mandatory = $true)][string]$Language,
  [Parameter(Mandatory = $true)][string]$OutputPath,
  [Parameter(Mandatory = $false)][string]$TextPath = "",
  [Parameter(Mandatory = $false)][string]$VoiceName = ""
)
$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Speech
$text = if ($TextPath -and (Test-Path -LiteralPath $TextPath)) {
  [IO.File]::ReadAllText($TextPath, [System.Text.UTF8Encoding]::new($false))
} else {
  [Console]::In.ReadToEnd()
}
if ([string]::IsNullOrWhiteSpace($text)) { throw "Leerer TTS-Text" }

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  if (-not [string]::IsNullOrWhiteSpace($VoiceName)) {
    try { $synth.SelectVoice($VoiceName) }
    catch [System.ArgumentException] { Write-Verbose "Gewünschte Stimme nicht nutzbar; Standardstimme wird verwendet." }
  } elseif ($Language -ne "auto") {
    $prefix = if ($Language.StartsWith("en")) { "en" } else { "de" }
    $voice = $null
    try {
      $voice = $synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name.StartsWith($prefix) } | Select-Object -First 1
    } catch {
      $voice = $null
    }
    if ($voice) {
      try { $synth.SelectVoice($voice.VoiceInfo.Name) }
      catch [System.ArgumentException] { Write-Verbose "Gewünschte Stimme nicht nutzbar; Standardstimme wird verwendet." }
    }
  }
  try { $synth.Volume = 100 } catch { }
  $synth.SetOutputToWaveFile($OutputPath)
  $synth.Speak($text)
} finally {
  $synth.Dispose()
}
