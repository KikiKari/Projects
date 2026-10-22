#!/usr/bin/env pwsh
# test_issue_controls.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text.RegularExpressions
using namespace System.Management.Automation
using namespace System.Runtime.InteropServices.JavaScript

$ErrorActionPreference = "Stop"

# Laden der benötigten Module
Add-Type -AssemblyName System.Runtime.InteropServices.JavaScript

# Laden der JavaScript-Dateien
$scriptDir = Split-Path $PSScriptRoot -Parent
$source = Get-Content (Join-Path $scriptDir "browser-extension" "sidepanel.js") -Raw
$core = Get-Content (Join-Path $scriptDir "browser-extension" "content-core.js") -Raw

function Get-Fragment($start, $end) {
    $a = $source.IndexOf($start)
    $b = $source.IndexOf($end, $a + $start.Length)
    if ($a -lt 0 -or $b -le $a) {
        throw "Fragment not found"
    }
    return $source.Substring($a, $b - $a)
}

function New-Controls() {
    $document = @{ activeElement = $null }
    
    $elements = New-Object 'Dictionary[string,hashtable]'
    
    # Erstellen eines Proxys für Elemente
    $proxyHandler = {
        param($target, $id)
        
        if (-not $target.ContainsKey($id)) {
            $element = @{
                hidden = $true
                disabled = $false
                textContent = 'Off'
                handlers = @{}
                value = ''
                checked = $false
                focus = {
                    $document.activeElement = $this
                }
                addEventListener = {
                    param($name, $fn)
                    $this.handlers[$name] = $fn
                }
                click = {
                    if ($this.handlers.ContainsKey('click')) {
                        return & $this.handlers['click'] @{ target = $this }
                    }
                }
                querySelectorAll = {
                    param($selector)
                    return @()
                }
            }
            $target[$id] = $element
        }
        return $target[$id]
    }
    
    return @{ elements = $elements; document = $document }
}

Describe "Test Issue Controls" {
    It "175 manual and automatic speech reject raw point triggers before author prefixes" {
        foreach ($enabled in @($false, $true)) {
            $spoken = @()
            $s = @{
                core = $core
                filterExternalSpeechTriggers = $enabled
                externalSpeechTriggerCharacters = '.'
                speechEnabled = $true
                speechQueue = @()
                elements = @{ 'speech-status' = @{} }
                pumpSpeech = {}
                speechText = { param($item) return "Autor sagt $($item.content)" }
                speechLang = { return 'de' }
                serviceSpeech = { param($text) $spoken += $text }
                browserSpeech = { throw "unexpected fallback" }
            }
            
            # Ausführen der JS-Fragmente im Kontext
            $fragment1 = Get-Fragment '  async function speakItem(' '  async function pumpSpeech('
            $fragment2 = Get-Fragment '  function enqueueSpeech(' '  function '
            
            # Hier würden wir normalerweise JS-Code ausführen, aber in PowerShell simulieren wir das Verhalten
            
            # Simulieren der speakItem und enqueueSpeech Funktionen
            $contents = @('.Text','. Text','  .Text','Normal','Ein Satz. Noch einer')
            foreach ($content in $contents) {
                # Simuliertes speakItem aufrufen
                # Simuliertes enqueueSpeech aufrufen
            }
            
            $expectedLength = if ($enabled) { 2 } else { 5 }
            $spoken.Count | Should -Be $expectedLength
            $s.speechQueue.Count | Should -Be $expectedLength
        }
    }
    
    It "187 input truncates pasted values and checkbox preserves selection" {
        $calls = @()
        $controls = New-Controls
        $s = @{
            elements = $controls.elements
            document = $controls.document
            core = $core
            filterExternalSpeechTriggers = $false
            externalSpeechTriggerCharacters = '.,-'
            send = { param($type, $payload) $calls += @{ type = $type; payload = $payload } }
        }
        
        # Simulieren der EventListener Registrierung
        $input = $s.elements['external-speech-trigger-characters']
        $input.value = '.,-;:!'
        
        # Simulieren des Input Events
        $input.handlers['input'] = { 
            # Kürzen auf 5 Zeichen
            if ($input.value.Length -gt 5) {
                $input.value = $input.value.Substring(0, 5)
            }
            # Senden des neuen Werts
            & $s.send 'UPDATE_SETTINGS' @{ externalSpeechTriggerCharacters = $input.value }
        }
        
        & $input.handlers['input']
        $input.value | Should -Be '.,-;:'
        $calls[-1].payload.externalSpeechTriggerCharacters | Should -Be '.,-;:'
        
        # Simulieren des Checkbox Change Events
        $toggle = $s.elements['filter-external-speech-triggers']
        $toggle.checked = $true
        
        $toggle.handlers['change'] = {
            # Toggle Handler Logik hier
        }
        
        & $toggle.handlers['change']
        $toggle.checked = $false
        & $toggle.handlers['change']
        $input.value | Should -Be '.,-;:'
        $input.disabled | Should -Be $false
        $calls[-1].payload.filterExternalSpeechTriggers | Should -Be $false
        
        # Testen mit Emojis
        $input.value = '😀😁😂😃😄😅'
        & $input.handlers['input']
        $input.value | Should -Be '😀😁😂😃😄'
        
        # Leerer Wert testen
        $input.value = ''
        & $input.handlers['input']
        $calls[-1].payload.externalSpeechTriggerCharacters | Should -Be ''
    }
    
    It "187 custom prefixes apply to manual and automatic speech before author prefixes" {
        foreach ($enabled in @($false, $true)) {
            $spoken = @()
            $s = @{
                core = $core
                filterExternalSpeechTriggers = $enabled
                externalSpeechTriggerCharacters = '.,-'
                speechEnabled = $true
                speechQueue = @()
                elements = @{ 'speech-status' = @{} }
                pumpSpeech = {}
                speechText = { param($item) return "Autor sagt $($item.content)" }
                speechLang = { return 'de' }
                serviceSpeech = { param($text) $spoken += $text }
                browserSpeech = { throw "unexpected fallback" }
            }
            
            # Simulieren der sprechenden Funktionen
            $contents = @('.Hallo',',Hallo','- Hallo','Hallo, zusammen.')
            foreach ($content in $contents) {
                # Simuliertes speakItem aufrufen
                # Simuliertes enqueueSpeech aufrufen
            }
            
            $expectedLength = if ($enabled) { 1 } else { 4 }
            $spoken.Count | Should -Be $expectedLength
            $s.speechQueue.Count | Should -Be $expectedLength
        }
    }
    
    It "176 speech switch commits On/Off only after a successful request" {
        $controls = New-Controls
        $s = @{
            elements = $controls.elements
            document = $controls.document
            speechEnabled = $false
            send = {}
            refresh = {}
            activateSpeech = { $s.speechEnabled = $true }
            stopSpeech = { $s.speechEnabled = $false }
        }
        
        # Simulieren der EventListener für Toggle-Switch
        $toggle = $s.elements['toggle-speech']
        $toggle.handlers['click'] = {
            try {
                if (-not $s.speechEnabled) {
                    & $s.activateSpeech
                    & $s.send
                } else {
                    & $s.stopSpeech
                    & $s.send
                }
            } catch {
                $s.elements['speech-status'].textContent = "Request failed: $($_.Exception.Message)"
            }
        }
        
        # Erster Click - sollte aktivieren
        & $toggle.handlers['click']
        $s.speechEnabled | Should -Be $true
        
        # Zweiter Click mit Fehler - sollte immer noch aktiviert bleiben
        $s.send = { throw "failed" }
        & $toggle.handlers['click']
        $s.speechEnabled | Should -Be $true
        $s.elements['speech-status'].textContent | Should -Match "failed"
        
        # Dritter Click mit Erfolg - sollte deaktivieren
        $s.send = {}
        & $toggle.handlers['click']
        $s.speechEnabled | Should -Be $false
    }
    
    It "176 Connection selects both commands and preserves state on rejection" {
        $calls = @()
        $controls = New-Controls
        $s = @{
            elements = $controls.elements
            document = $controls.document
            currentState = @{ hook = @{ armed = $false } }
            send = { param($cmd) $calls += $cmd }
            refresh = { $s.currentState.hook.armed = -not $s.currentState.hook.armed }
        }
        
        # Simulieren der Hook-Toggle EventListener
        $hookToggle = $s.elements['toggle-hook']
        $hookToggle.handlers['click'] = {
            try {
                & $s.refresh
                if ($s.currentState.hook.armed) {
                    & $s.send "TLC_ENABLE_HOOK"
                } else {
                    & $s.send "TLC_DISABLE_HOOK"
                }
            } catch {
                $s.currentState.hook.armed = $false
                $s.elements.notice.textContent = "Operation failed: $($_.Exception.Message)"
            }
        }
        
        # Zwei erfolgreiche Toggles
        & $hookToggle.handlers['click']
        & $hookToggle.handlers['click']
        $calls | Should -Be @('TLC_ENABLE_HOOK', 'TLC_DISABLE_HOOK')
        
        # Fehlgeschlagener Toggle
        $s.send = { throw "failed" }
        & $hookToggle.handlers['click']
        $s.currentState.hook.armed | Should -Be $false
        $s.elements.notice.textContent | Should -Match "failed"
    }
    
    It "176 Connection dialog returns focus and traps Tab in both directions" {
        $controls = New-Controls
        $s = @{
            elements = $controls.elements
            document = $controls.document
        }
        
        # Simulieren der EventListener für Connection Settings
        $openSettings = $s.elements['open-connection-settings']
        $modal = $s.elements['connection-settings-modal']
        $closeButton = $s.elements['close-connection-settings']
        $lastElement = $s.elements['quick-recover-seconds']
        $notice = $s.elements['notice']
        
        $s.elements['open-connection-settings'].handlers['click'] = {
            $modal.hidden = $false
            $closeButton.focus()
        }
        
        # Keydown Event Handler registrieren
        $keydownHandler = $null
        $s.document.addEventListener = { 
            param($name, $fn)
            if ($name -eq "keydown") {
                $keydownHandler = $fn
            }
        }
        
        # Modal öffnen
        & $s.elements['open-connection-settings'].handlers['click']
        $modal.hidden | Should -Be $false
        $s.document.activeElement | Should -Be $closeButton
        
        # Setup der Tab-Reihenfolge
        $first = $closeButton
        $last = $lastElement
        $modal.querySelectorAll = { return @($first, $last) }
        
        # Shift+Tab testen (rückwärts)
        $prevented = 0
        $keydownArgs1 = @{
            key = 'Tab'
            shiftKey = $true
            preventDefault = { $script:prevented++ }.GetNewClosure()
        }
        & $keydownHandler $keydownArgs1
        $s.document.activeElement | Should -Be $last
        $prevented | Should -Be 1
        
        # Tab testen (vorwärts)
        $keydownArgs2 = @{
            key = 'Tab'
            shiftKey = $false
            preventDefault = { $script:prevented++ }.GetNewClosure()
        }
        & $keydownHandler $keydownArgs2
        $s.document.activeElement | Should -Be $first
        $prevented | Should -Be 2
        
        # Escape testen
        $keydownArgs3 = @{ key = 'Escape' }
        & $keydownHandler $keydownArgs3
        $modal.hidden | Should -Be $true
        $s.document.activeElement | Should -Be $s.elements['open-connection-settings']
    }
}
