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

function Test-GermanSpecialChars([string]$Value) {
  foreach ($code in @(0x00E4, 0x00F6, 0x00FC, 0x00C4, 0x00D6, 0x00DC, 0x00DF)) {
    if ($Value.IndexOf([char]$code) -ge 0) { return $true }
  }
  return $false
}

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  $selectedCulture = ""
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
      try {
        $synth.SelectVoice($voice.VoiceInfo.Name)
        $selectedCulture = $voice.VoiceInfo.Culture.Name
      }
      catch [System.ArgumentException] { Write-Verbose "Gewünschte Stimme nicht nutzbar; Standardstimme wird verwendet." }
    }
  }
  if ([string]::IsNullOrWhiteSpace($selectedCulture)) {
    try { $selectedCulture = $synth.Voice.Culture.Name } catch { $selectedCulture = "" }
  }
  $ssmlLanguage = if ($Language -and $Language -ne "auto") {
    if ($Language.StartsWith("en")) { "en-US" } else { "de-DE" }
  } elseif (Test-GermanSpecialChars $text) {
    "de-DE"
  } elseif (-not [string]::IsNullOrWhiteSpace($selectedCulture)) {
    $selectedCulture
  } else {
    ""
  }
  try { $synth.Volume = 100 } catch { }
  $synth.SetOutputToWaveFile($OutputPath)
  if (-not [string]::IsNullOrWhiteSpace($ssmlLanguage)) {
    $escapedText = [System.Security.SecurityElement]::Escape($text)
    $synth.SpeakSsml("<speak version=""1.0"" xml:lang=""$ssmlLanguage"">$escapedText</speak>")
  } else {
    $synth.Speak($text)
  }
} finally {
  $synth.Dispose()
}
