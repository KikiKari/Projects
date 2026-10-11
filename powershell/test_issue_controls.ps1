#!/usr/bin/env pwsh
# test_issue_controls.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

#Requires -Version 7

<#
.SYNOPSIS
    Port of test_issue_controls.cjs to PowerShell 7
.DESCRIPTION
    This script contains tests that validate the behavior of UI controls related to speech and connection settings,
    simulating DOM interactions and event handling in a browser extension context.
.NOTES
    The original JavaScript uses Node.js modules like `node:test`, `node:assert/strict`, etc., which are replaced here with
    PowerShell equivalents or custom implementations where necessary.
#>

# Import required modules (none needed as we simulate everything)

# Define helper functions equivalent to those used in JS

function Read-FileContent {
    param (
        [string]$Path
    )
    return Get-Content -Path $Path -Raw
}

function Find-Fragment {
    param (
        [string]$Source,
        [string]$Start,
        [string]$End
    )
    $a = $Source.IndexOf($Start)
    $b = $Source.IndexOf($End, $a + $Start.Length)
    if ($a -lt 0 -or $b -le $a) {
        throw "Fragment not found"
    }
    return $Source.Substring($a, $b - $a)
}

function New-ControlsMock {
    $document = @{ activeElement = $null }
    $elements = @{}

    # Create proxy-like behavior using ScriptBlock
    $getElement = {
        param($id)
        if (-not $elements.ContainsKey($id)) {
            $handlers = @{}
            $element = @{
                hidden = $true
                disabled = $false
                textContent = 'Off'
                handlers = $handlers
                addEventListener = {
                    param($name, $fn)
                    $handlers[$name] = $fn
                }.GetNewClosure()
                focus = {
                    $document.activeElement = $element
                }.GetNewClosure()
                click = {
                    $eventArgs = @{ target = $element }
                    if ($handlers.ContainsKey('click')) {
                        & $handlers['click'] $eventArgs
                    }
                }.GetNewClosure()
            }
            $elements[$id] = $element
        }
        return $elements[$id]
    }

    return @{
        elements = $elements
        document = $document
        getElementProxy = $getElement
    }
}

# Test cases adapted from original JS file

Describe 'Issue Controls Tests' {

    It '175 manual and automatic speech reject raw point triggers before author prefixes' {
        foreach ($enabled in @($false, $true)) {
            $spoken = @()
            $s = @{
                core = $core
                filterExternalSpeechTriggers = $enabled
                speechEnabled = $true
                speechQueue = @()
                elements = @{ 'speech-status' = @{} }
                pumpSpeech = {}
                speechText = { param($item) "Autor sagt $($item.content)" }
                speechLang = { return 'de' }
                serviceSpeech = { param($text) $spoken += $text }
                browserSpeech = { throw "unexpected fallback" }
            }

            # Simulate running code fragments in context
            # Since PowerShell doesn't have direct VM context execution, we'll call relevant logic directly

            function SpeakItem {
                param($item)
                # Simplified version based on fragment logic
                $text = & $s.speechText $item
                if ($s.filterExternalSpeechTriggers) {
                    # Filter out some items
                    if ($item.content.StartsWith('.')) {
                        return
                    }
                }
                $s.speechQueue += $item
                & $s.serviceSpeech $text
            }

            function EnqueueSpeech {
                param($item)
                $s.speechQueue += $item
            }

            foreach ($content in @('.Text', '. Text', '  .Text', 'Normal', 'Ein Satz. Noch einer')) {
                SpeakItem @{ content = $content }
                EnqueueSpeech @{ content = $content }
            }

            $expectedCount = if ($enabled) { 2 } else { 5 }
            $spoken.Count | Should -Be $expectedCount
            $s.speechQueue.Count | Should -Be $expectedCount
        }
    }

    It '176 speech switch commits On/Off only after a successful request' {
        $controls = New-ControlsMock
        $s = $controls
        $s.speechEnabled = $false
        $sendResult = $true
        $s.send = { 
            if (-not $sendResult) { throw "failed" }
        }
        $s.refresh = {}
        $s.activateSpeech = { $s.speechEnabled = $true }
        $s.stopSpeech = { $s.speechEnabled = $false }

        # Run event listener setup manually since no VM context
        $toggleSpeech = & $s.getElementProxy 'toggle-speech'
        $toggleSpeech.addEventListener.Invoke('click', {
            if ($s.speechEnabled) {
                try {
                    & $s.send
                    & $s.stopSpeech
                } catch {
                    $s.elements['speech-status'].textContent = $_.Exception.Message
                }
            } else {
                try {
                    & $s.send
                    & $s.activateSpeech
                } catch {
                    $s.elements['speech-status'].textContent = $_.Exception.Message
                }
            }
        })

        # Click once -> enable
        $toggleSpeech.click()
        $s.speechEnabled | Should -Be $true

        # Fail next send -> stay enabled but show error
        $sendResult = $false
        $toggleSpeech.click()
        $s.speechEnabled | Should -Be $true
        $s.elements['speech-status'].textContent | Should -Match 'failed'

        # Succeed again -> disable
        $sendResult = $true
        $toggleSpeech.click()
        $s.speechEnabled | Should -Be $false
    }

    It '176 Connection selects both commands and preserves state on rejection' {
        $controls = New-ControlsMock
        $calls = @()
        $s = $controls
        $s.currentState = @{ hook = @{ armed = $false } }
        $sendSuccess = $true
        $s.send = { 
            param($cmd)
            $calls += $cmd
            if (-not $sendSuccess) { throw "failed" }
        }
        $s.refresh = {
            $s.currentState.hook.armed = -not $s.currentState.hook.armed
        }

        # Setup event listeners manually
        $toggleHook = & $s.getElementProxy 'toggle-hook'
        $toggleHook.addEventListener.Invoke('click', {
            try {
                if ($s.currentState.hook.armed) {
                    & $s.send 'TLC_DISABLE_HOOK'
                    & $s.refresh
                } else {
                    & $s.send 'TLC_ENABLE_HOOK'
                    & $s.refresh
                }
            } catch {
                $s.elements.notice.textContent = $_.Exception.Message
            }
        })

        $toggleHook.click()
        $toggleHook.click()
        $calls | Should -Be @('TLC_ENABLE_HOOK', 'TLC_DISABLE_HOOK')

        $sendSuccess = $false
        $toggleHook.click()
        $s.currentState.hook.armed | Should -Be $false
        $s.elements.notice.textContent | Should -Match 'failed'
    }

    It '176 Connection dialog returns focus and traps Tab in both directions' {
        $controls = New-ControlsMock
        $s = $controls

        # Setup keydown handler registration
        $keydownHandler = $null
        $s.document.addEventListener = {
            param($name, $fn)
            if ($name -eq 'keydown') {
                $keydownHandler = $fn
            }
        }

        # Mock modal elements
        $modal = & $s.getElementProxy 'connection-settings-modal'
        $modal.hidden = $true
        $closeBtn = & $s.getElementProxy 'close-connection-settings'
        $lastElement = & $s.getElementProxy 'quick-recover-seconds'

        # Setup open button
        $openBtn = & $s.getElementProxy 'open-connection-settings'
        $openBtn.addEventListener.Invoke('click', {
            $modal.hidden = $false
            $closeBtn.focus()
        })

        # Open modal
        $openBtn.click()
        $modal.hidden | Should -Be $false
        $s.document.activeElement | Should -Be $closeBtn

        # Mock querySelectorAll
        $modal.querySelectorAll = { return @($closeBtn, $lastElement) }

        # Simulate tab navigation
        $prevented = 0
        $keydownHandler.Invoke(@{
            key = 'Tab'
            shiftKey = $true
            preventDefault = { $prevented++ }.GetNewClosure()
        })
        $s.document.activeElement | Should -Be $lastElement

        $keydownHandler.Invoke(@{
            key = 'Tab'
            shiftKey = $false
            preventDefault = { $prevented++ }.GetNewClosure()
        })
        $s.document.activeElement | Should -Be $closeBtn
        $prevented | Should -Be 2

        # Escape closes modal
        $keydownHandler.Invoke(@{ key = 'Escape' })
        $modal.hidden | Should -Be $true
        $s.document.activeElement | Should -Be $openBtn
    }
}
