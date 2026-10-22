#!/usr/bin/env pwsh
# test_voice_groups.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_voice_groups.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Lade benötigte Module
$ErrorActionPreference = "Stop"

# Definiere Hilfsfunktionen zur Emulation von DOM-Elementen
function New-HtmlElement {
    param (
        [string]$Tag
    )
    return @{
        tag = $Tag
        children = @()
        dataset = @{}
        value = ''
        label = $null
        Append = {
            param($Node)
            $this.children += $Node
        }
    }
}

# Pfade zu den benötigten Dateien
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourcePath = Join-Path $scriptDir "../browser-extension/sidepanel.js"
$voiceCatalogPath = Join-Path $scriptDir "../companion-service/voice-catalog.json"

# Lies den Quellcode und das Voice-Katalog JSON
$source = Get-Content -Path $sourcePath -Raw
$voiceData = Get-Content -Path $voiceCatalogPath -Raw | ConvertFrom-Json
$voices = $voiceData.voices

# Erstelle ein simuliertes select-Element
$select = New-HtmlElement -Tag 'select'

# Simuliere globale Variablen und Funktionen für den Kontext
$global:document = @{ createElement = { param($tag) New-HtmlElement -Tag $tag } }
$global:elements = @{ 'speech-voice' = $select }
$global:speechVoiceName = 'sherpa-de-supertonic-7'
$global:voiceCatalog = $voices
$global:clearChildren = {
    param($node)
    $node.children = @()
}

# Extrahiere relevante Code-Abschnitte aus der sidepanel.js
$baseVoiceOrderStart = $source.IndexOf('  const BASE_VOICE_ORDER')
$coreStart = $source.IndexOf('  const core =')
$sherpaSpeechVoicesStart = $source.IndexOf('  function sherpaSpeechVoices')
$loadSpeechVoicesStart = $source.IndexOf('  async function loadSpeechVoices')

$baseVoiceCode = $source.Substring($baseVoiceOrderStart, ($coreStart - $baseVoiceOrderStart))
$sherpaSpeechCode = $source.Substring($sherpaSpeechVoicesStart, ($loadSpeechVoicesStart - $sherpaSpeechVoicesStart))

# Führe den extrahierten JavaScript-Code im PowerShell-Kontext aus
Invoke-Expression $baseVoiceCode
Invoke-Expression $sherpaSpeechCode

# Rufe setSpeechVoiceOptions auf
setSpeechVoiceOptions @() $voices

# Prüfe ob alle Gruppen existieren und mindestens 3 Kinder haben
$labelsToCheck = @('Kyrillisch','Asiatisch','Abjad','Indisch','Effekt Stimmen')
foreach ($label in $labelsToCheck) {
    $group = $select.children | Where-Object { $_.label -eq $label }
    if (-not $group) {
        throw "Gruppe '$label' nicht gefunden"
    }
    if ($group.children.Count -lt 3) {
        throw "Gruppe '$label' hat weniger als 3 Kinder"
    }
}

# Spezifische Checks
$effektStimmenGroup = $select.children | Where-Object { $_.label -eq 'Effekt Stimmen' }
if ($effektStimmenGroup.children.Count -ne 5) {
    throw "Effekt Stimmen Gruppe hat nicht genau 5 Kinder"
}

if ($select.value -ne 'sherpa-de-supertonic-7') {
    throw "Select-Wert ist nicht 'sherpa-de-supertonic-7'"
}

# Zweiter Test: Setze spezielle Option
setSpeechVoiceOptions @(@{id='sherpa-de-supertonic-7'; name='Stil 3'; group=''}) $voices

if ($select.value -ne 'sherpa-de-supertonic-7') {
    throw "Select-Wert nach zweitem Set ist nicht 'sherpa-de-supertonic-7'"
}

$selectedOption = $effektStimmenGroup.children | Where-Object { $_.value -eq $select.value }
if (-not $selectedOption) {
    throw "Ausgewählte Option ist nicht in Effekt Stimmen Gruppe"
}

# Dritter Test: Ändere speechVoiceName und entferne Gruppen
$global:speechVoiceName = 'sherpa-ru-irina'
$voicesWithoutGroups = $voices | ForEach-Object {
    $newVoice = $_.PSObject.Copy()
    $newVoice.PSObject.Properties.Remove('group')
    $newVoice
}
setSpeechVoiceOptions @() $voicesWithoutGroups

if ($select.value -ne 'sherpa-ru-irina') {
    throw "Select-Wert nach drittem Set ist nicht 'sherpa-ru-irina'"
}

$kyrillischGroup = $select.children | Where-Object { $_.label -eq 'Kyrillisch' }
$selectedRussianOption = $kyrillischGroup.children | Where-Object { $_.value -eq 'sherpa-ru-irina' }
if (-not $selectedRussianOption) {
    throw "Russische Option ist nicht in Kyrillisch Gruppe"
}

Write-Host "PASS: five groups, all styles selectable, retained selection, legacy catalog fallback"
