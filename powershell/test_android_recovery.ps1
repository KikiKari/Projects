#!/usr/bin/env pwsh
# test_android_recovery.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_android_recovery.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

#Requires -Version 7.0

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text.Json

$ErrorActionPreference = 'Stop'

# Mock Node.js modules and functions
function New-MockDate {
    param([int]$Now)
    return @{
        Now = $Now
        Tick = { param([int]$Ms) $script:Now += $Ms }
    }
}

function New-MockTimers {
    $timers = @{}
    $intervals = @()
    return @{
        Timers = $timers
        Intervals = $intervals
        SetTimeout = {
            param([scriptblock]$Func, [int]$Ms)
            $id = ++$script:Seq
            $timers[$id] = @{ Func = $Func; At = $script:Now + $Ms }
            return $id
        }
        ClearTimeout = { param($Id) $timers.Remove($Id) }
        SetInterval = {
            param([scriptblock]$Func)
            $intervals += $Func
            return $intervals.Count
        }
        ClearInterval = { }
        Tick = {
            param([int]$Ms)
            $script:Now += $Ms
            foreach ($func in @($intervals)) {
                & $func
            }
            $expired = @()
            foreach ($pair in $timers.GetEnumerator()) {
                if ($pair.Value.At -le $script:Now) {
                    $expired += $pair.Key
                }
            }
            foreach ($id in $expired) {
                & $timers[$id].Func
                $timers.Remove($id)
            }
        }
    }
}

function New-MockVideo {
    return @{
        clientWidth = 100
        clientHeight = 100
        currentTime = 1
        paused = $false
        ended = $false
        readyState = 4
        dataset = @{}
        addEventListener = { param($n, $f) $listeners[$n] = $f }
        play = { $script:Plays++ }
        textTracks = @()
    }
}

function New-MockRoot {
    param([bool]$Ios)
    $video = New-MockVideo
    $listeners = @{}
    $events = @()
    $timers = New-MockTimers
    $seq = 0
    $plays = 0
    $now = 10000

    $root = @{
        location = @{ origin = 'https://www.tiktok.com'; pathname = '/@creator/live' }
        crypto = @{ randomUUID = { "11111111-1111-1111-1111-$('{0:D12}' -f (++$script:Seq))" } }
        Date = New-MockDate -Now $now
        document = @{
            scripts = @()
            body = @{ innerText = '' }
            querySelectorAll = { param($s) if ($s -eq 'video') { @($video) } else { @() } }
            querySelector = { $null }
        }
        tlcBridge = @{ postMessage = { param($s) $events += $s | ConvertFrom-Json } }
        addEventListener = { param($n, $f) $listeners[$n] = $f }
        postMessage = { param($m) $events += $m }
        setInterval = $timers.SetInterval
        clearInterval = $timers.ClearInterval
        setTimeout = $timers.SetTimeout
        clearTimeout = $timers.ClearTimeout
        top = $null
    }

    if ($Ios) {
        $root.Remove('tlcBridge')
        $root.webkit = @{
            messageHandlers = @{
                tlcBridge = @{ postMessage = { param($m) $events += $m } }
            }
        }
    }

    $root.top = $root

    # Load and execute the script in a mock context
    $scriptPath = Join-Path $raw 'android_recovery.js'
    $scriptContent = Get-Content $scriptPath -Raw
    Invoke-Expression $scriptContent

    return @{
        dispatch = {
            param($data)
            $event = @{
                source = $root
                origin = $root.location.origin
                data = @{ source = "tiktok-live-companion" } + $data
            }
            $listeners.message($event)
        }
        root = $root
        video = $video
        events = $events
        timers = $timers
        plays = { $plays }
        tick = $timers.Tick
        api = $root.TLC_MOBILE_RECOVERY
    }
}

# Test functions
function Test-PlayerRecoveryWaitsConfiguredInterval {
    $s = New-MockRoot -Ios $false
    $s.api.command('set-auto-reconnect', @{ enabled = $true; delaySeconds = 3 })
    $s.api.recover('stalled')
    Assert-Equal $s.timers.Timers.Count 1
    $s.tick(2999)
    Assert-Equal $s.plays.Invoke() 0
    $s.tick(1)
    Assert-Equal $s.plays.Invoke() 1
    Assert-Equal $s.root.location.pathname '/@creator/live'
}

function Test-UserPauseAndVLCCancelPendingRecovery {
    foreach ($cmd in @('pause', 'set-vlc-active')) {
        $s = New-MockRoot -Ios $false
        $s.api.command('set-auto-reconnect', @{ enabled = $true })
        $s.api.recover('stalled')
        $s.api.command($cmd, @{ active = $true })
        $s.tick(4000)
        Assert-Equal $s.plays.Invoke() 0
    }
}

function Test-MediaProgressCancelsAttemptWithoutReplacingMedia {
    $s = New-MockRoot -Ios $false
    $s.api.command('set-auto-reconnect', @{ enabled = $true })
    $s.api.recover('waiting')
    $s.video.currentTime = 2
    $s.tick(3000)
    Assert-Equal $s.plays.Invoke() 0
}

function Test-CaptionWebsocketActivityExpiresIndependentlyFromMenu {
    $s = New-MockRoot -Ios $false
    $s.dispatch(@{ type = "caption"; caption = @{ contents = @(@{ lang = "de"; text = "test" }) } })
    $lastEvent = $s.events | Where-Object { $_.type -eq "caption-state" } | Select-Object -Last 1
    Assert-Equal $lastEvent.payload.websocket $true
    $s.tick(16000)
    $lastEvent = $s.events | Where-Object { $_.type -eq 'caption-state' } | Select-Object -Last 1
    Assert-Equal $lastEvent.payload.websocket $false
    Assert-Equal $lastEvent.payload.activityTtlMs 15000
}

function Test-AndroidUsesByteIdenticalBrowserControllerAndProtocolParser {
    $mobilePath = '../../mobile/android/app/src/main/res/raw'
    $browserPath = '../browser-extension'
    foreach ($pair in @(
        @('hook_recovery.js', 'hook-recovery.js'),
        @('recovery_hook.js', 'hook.js'),
        @('proto_main.js', 'proto-main.js')
    )) {
        $mobileFile = Join-Path $mobilePath $pair[0]
        $browserFile = Join-Path $browserPath $pair[1]
        $mobileContent = Get-Content $mobileFile -Raw -Encoding Byte
        $browserContent = Get-Content $browserFile -Raw -Encoding Byte
        Assert-True ($mobileContent.Length -eq $browserContent.Length)
        for ($i = 0; $i -lt $mobileContent.Length; $i++) {
            if ($mobileContent[$i] -ne $browserContent[$i]) {
                throw "Files differ at byte $i"
            }
        }
    }
}

function Test-IOSWebKitBridgeReceivesCorrelatedRecoveryObservations {
    $s = New-MockRoot -Ios $true
    $s.tick(1000)
    $e = $s.events | Where-Object { $_.type -eq 'player-observation' } | Select-Object -First 1
    Assert-True ($null -ne $e)
    Assert-Equal $e.payload.frameKind 'top'
    Assert-Match $e.payload.documentId '^[a-f0-9-]{36}$'
    $s.dispatch(@{ type = 'caption'; caption = @{ text = 'ios-caption' } })
    $lastCaption = $s.events | Where-Object { $_.type -eq 'caption' } | Select-Object -Last 1
    Assert-Equal $lastCaption.payload.text 'ios-caption'
}

function Test-IOSAndAndroidInjectIdenticalRecoveryImplementations {
    $iosPath = '../../mobile/ios/Resources'
    $rawPath = '../../mobile/android/app/src/main/res/raw'
    foreach ($pair in @(
        @('android_recovery.js', 'mobile-recovery.js'),
        @('hook_recovery.js', 'hook-recovery.js'),
        @('recovery_hook.js', 'recovery-hook.js'),
        @('export_privacy.js', 'export-privacy.js'),
        @('proto_main.js', 'proto-main.js'),
        @('content_core.js', 'content-core.js')
    )) {
        $androidFile = Join-Path $rawPath $pair[0]
        $iosFile = Join-Path $iosPath $pair[1]
        $androidContent = Get-Content $androidFile -Raw -Encoding Byte
        $iosContent = Get-Content $iosFile -Raw -Encoding Byte
        Assert-True ($androidContent.Length -eq $iosContent.Length)
        for ($i = 0; $i -lt $androidContent.Length; $i++) {
            if ($androidContent[$i] -ne $iosContent[$i]) {
                throw "Files differ at byte $i"
            }
        }
    }
}

function Test-ConnectionOffStopsCompanionChatDelivery {
    foreach ($ios in $false, $true) {
        $s = New-MockRoot -Ios $ios
        $s.api.command('set-connection', @{ enabled = $false })
        $s.dispatch(@{ type = 'chat-message'; chatMessage = @{ content = 'hidden from Companion' } })
        $chatEvents = $s.events | Where-Object { $_.type -eq 'chat' }
        Assert-Equal $chatEvents.Count 0
        $s.api.command('set-connection', @{ enabled = $true })
        $s.dispatch(@{ type = 'chat-message'; chatMessage = @{ content = 'visible' } })
        $chatEvents = $s.events | Where-Object { $_.type -eq 'chat' }
        Assert-Equal $chatEvents.Count 1
        Assert-Equal $s.plays.Invoke() 0
    }
}

# Helper functions for assertions
function Assert-Equal($Actual, $Expected) {
    if ($Actual -ne $Expected) {
        throw "Assertion failed: Expected '$Expected', but got '$Actual'"
    }
}

function Assert-True($Condition) {
    if (-not $Condition) {
        throw "Assertion failed: Condition was false"
    }
}

function Assert-Match($Input, $Pattern) {
    if ($Input -notmatch $Pattern) {
        throw "Assertion failed: '$Input' does not match pattern '$Pattern'"
    }
}

# Run tests
Test-PlayerRecoveryWaitsConfiguredInterval
Test-UserPauseAndVLCCancelPendingRecovery
Test-MediaProgressCancelsAttemptWithoutReplacingMedia
Test-CaptionWebsocketActivityExpiresIndependentlyFromMenu
Test-AndroidUsesByteIdenticalBrowserControllerAndProtocolParser
Test-IOSWebKitBridgeReceivesCorrelatedRecoveryObservations
Test-IOSAndAndroidInjectIdenticalRecoveryImplementations
Test-ConnectionOffStopsCompanionChatDelivery

Write-Host "All tests passed!"
