param()
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Speech

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  try {
    $voices = @($synth.GetInstalledVoices() |
      Where-Object { $_.Enabled } |
      ForEach-Object {
        [pscustomobject]@{
          id = $_.VoiceInfo.Name
          name = $_.VoiceInfo.Name
          culture = $_.VoiceInfo.Culture.Name
          gender = $_.VoiceInfo.Gender.ToString()
          age = $_.VoiceInfo.Age.ToString()
        }
      }
    )
  } catch {
    $voices = @()
  }
  if ($voices.Count -eq 0) {
    "[]"
  } else {
    $voices | ConvertTo-Json -Compress
  }
} finally {
  $synth.Dispose()
}
