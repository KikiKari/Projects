param(
  [Parameter(Mandatory = $true)][string]$Language,
  [Parameter(Mandatory = $true)][string]$OutputPath
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Speech
$text = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($text)) { throw "Leerer TTS-Text" }

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  if ($Language -ne "auto") {
    $prefix = if ($Language.StartsWith("en")) { "en" } else { "de" }
    $voice = $synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name.StartsWith($prefix) } | Select-Object -First 1
    if ($voice) {
      try { $synth.SelectVoice($voice.VoiceInfo.Name) }
      catch [System.ArgumentException] { Write-Verbose "Gewünschte Stimme nicht nutzbar; Standardstimme wird verwendet." }
    }
  }
  $synth.Volume = 100
  $synth.SetOutputToWaveFile($OutputPath)
  $synth.Speak($text)
} finally {
  $synth.Dispose()
}
