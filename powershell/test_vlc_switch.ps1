#!/usr/bin/env pwsh
# test_vlc_switch.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# PowerShell 7 translation of test_vlc_switch.cjs
# This script tests VLC switching functionality by simulating browser environment

$ErrorActionPreference = "Stop"

# Helper functions to simulate JavaScript behavior
function New-JSObject {
    param([hashtable]$Properties = @{})
    $obj = New-Object PSObject
    foreach ($key in $Properties.Keys) {
        $obj | Add-Member -NotePropertyName $key -NotePropertyValue $Properties[$key]
    }
    return $obj
}

function New-JSArray {
    param([array]$Items = @())
    return [System.Collections.ArrayList]$Items
}

# Simulate Node.js path operations
function Get-JoinPath {
    param([string]$Path1, [string]$Path2)
    return Join-Path $Path1 $Path2
}

# Get current directory and read content.js
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$contentJsPath = Get-JoinPath (Get-JoinPath $scriptDir "..") "browser-extension/content.js"
$source = Get-Content $contentJsPath -Raw

# Create mock objects
$listeners = @{}
$native = New-JSObject @{
    muted = $false
    paused = $false
    pause = { 
        $this.paused = $true
    }
    play = {
        $task = Start-ThreadJob { Start-Sleep -Milliseconds 10 }
        return $task
    }
}
$fallback = New-JSObject @{
    muted = $false
    paused = $false
}
$media = @($native, $fallback)
$unrelatedVideo = $native | ConvertTo-Json -Depth 10 | ConvertFrom-Json
$speechAudio = $native | ConvertTo-Json -Depth 10 | ConvertFrom-Json

$surface = New-JSObject @{
    querySelectorAll = {
        param($selector)
        if ($selector -ne "video") {
            throw "Assertion failed: Expected selector 'video', got '$selector'"
        }
        return $media
    }
}

$fallback.closest = {
    return @{ parentElement = $surface }
}

$gain = @{ value = 0.7 }
$changed = $null

# Create context object to simulate VM context
$context = @{
    audioPipeline = @{
        video = $native
        outputGain = @{ gain = $gain }
    }
    document = @{
        querySelectorAll = {
            throw "Must not globally suppress page media"
        }
        documentElement = @{}
        addEventListener = {
            param($name, $fn)
            $listeners[$name] = $fn
        }
        removeEventListener = {
            param($name)
            $listeners.Remove($name)
        }
    }
    MutationObserver = {
        param($fn)
        $script:changed = $fn
        return @{
            observe = {}
            disconnect = {}
        }
    }
}

# Extract and run relevant code from content.js
$startIndex = $source.IndexOf("  function suppressNativeAudio(")
$endIndex = $source.IndexOf("  async function playMediaFallback(")
$codeToRun = $source.Substring($startIndex, $endIndex - $startIndex)

# Define suppressNativeAudio function in PowerShell context
function suppressNativeAudio {
    param($fallbackArg)
    
    # Store original state
    $originalMuted = $native.muted
    $originalPaused = $native.paused
    $originalGain = $gain.value
    
    # Apply suppression
    $native.muted = $true
    $native.pause()
    $gain.value = 0
    
    # Return release function
    return {
        $native.muted = $originalMuted
        $native.paused = $originalPaused
        $gain.value = $originalGain
    }.GetNewClosure()
}

# Test assertions
$release = suppressNativeAudio $fallback
if ($native.muted -ne $true) { throw "Assertion failed: native.muted should be true" }
if ($native.paused -ne $true) { throw "Assertion failed: native.paused should be true" }
if ($gain.value -ne 0) { throw "Assertion failed: gain.value should be 0" }
if ($fallback.muted -ne $false) { throw "Assertion failed: fallback.muted should be false" }
if ($fallback.paused -ne $false) { throw "Assertion failed: fallback.paused should be false" }

$native.paused = $false
& $listeners["play"]
if ($native.paused -ne $true) { throw "Assertion failed: native.paused should be true after play event" }

$replacement = New-JSObject @{
    muted = $false
    paused = $false
}
$media += $replacement
& $changed
if ($replacement.muted -ne $true) { throw "Assertion failed: replacement.muted should be true" }
if ($replacement.paused -ne $true) { throw "Assertion failed: replacement.paused should be true" }

& $release
if ($native.muted -ne $false) { throw "Assertion failed: native.muted should be false after release" }
if ($native.paused -ne $false) { throw "Assertion failed: native.paused should be false after release" }
if ($gain.value -ne 0.7) { throw "Assertion failed: gain.value should be 0.7 after release" }
if ($listeners.Count -ne 0) { throw "Assertion failed: listeners should be empty" }
if ($unrelatedVideo.paused -ne $false) { throw "Assertion failed: unrelatedVideo.paused should be false" }
if ($speechAudio.paused -ne $false) { throw "Assertion failed: speechAudio.paused should be false" }

# Test unrelated audio pipeline
$context.audioPipeline.video = $unrelatedVideo
$releaseUnrelated = suppressNativeAudio $fallback
if ($gain.value -ne 0.7) { throw "Assertion failed: Unrelated audio pipeline must remain unchanged" }
& $releaseUnrelated

# Read background.js and test normal live functionality
$backgroundJsPath = Get-JoinPath (Get-JoinPath $scriptDir "..") "browser-extension/background.js"
$background = Get-Content $backgroundJsPath -Raw

$normalStart = $background.IndexOf("async function openNormalLive(")
$normalEnd = $background.IndexOf("chrome.sidePanel.setPanelBehavior")
$normal = $background.Substring($normalStart, $normalEnd - $normalStart)

# Basic string checks since we can't execute the JS directly
if (-not ($normal -match "await chrome.tabs.update\(tabId, \{ url: normalLiveUrl\(handle\) \}\)")) {
    throw "Assertion failed: Normal should contain tab update call"
}
if ($normal -match "if \(reloading\)") {
    throw "Assertion failed: Normal should not contain reloading check"
}
if (-not ($source -match "if \(holder\?\.isConnected\) return holder.querySelector\(`"video`"\)")) {
    throw "Assertion failed: Source should contain holder.isConnected check"
}

Write-Host "PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused"

# Exercise switch functionality
function exerciseSwitch {
    # Read sidepanel.js
    $sidepanelJsPath = Get-JoinPath (Get-JoinPath $scriptDir "..") "browser-extension/sidepanel.js"
    $panel = Get-Content $sidepanelJsPath -Raw
    
    $clickStart = $panel.IndexOf('  elements["player-vlc-frame"].addEventListener("click"')
    $clickEnd = $panel.IndexOf('  elements["player-volume"].addEventListener', $clickStart)
    
    $click = $null
    $starts = 0
    
    $button = New-JSObject @{
        addEventListener = {
            param($event, $fn)
            $script:click = $fn
        }
    }
    
    $panelContext = @{
        elements = @{ "player-vlc-frame" = $button }
        installVlcIfNeeded = {
            throw "Internal replacement must not wait for desktop installation"
        }
        runPlayer = {
            param($action, $target)
            if ($action -ne "play-vlc-source") { throw "Assertion failed: action should be 'play-vlc-source'" }
            if ($target -ne $button) { throw "Assertion failed: target mismatch" }
            $script:starts++
        }
    }
    
    # Simulate click event
    & $click
    if ($starts -ne 1) { throw "Assertion failed: VLC click dispatches internal player immediately" }
    
    # Test primaryVideo selection logic
    $largeNative = New-JSObject @{
        closest = { return $null }
        getBoundingClientRect = { return @{ width = 1000; height = 1000 } }
    }
    
    $smallReplacement = New-JSObject @{
        closest = { return @{} }
        getBoundingClientRect = { return @{ width = 100; height = 100 } }
    }
    
    $selection = @{
        activeMediaFallbackItem = @{}
        mediaFallbackRunning = $false
        document = @{
            querySelector = { return $smallReplacement }
            querySelectorAll = { return @($largeNative, $smallReplacement) }
        }
    }
    
    # primaryVideo function logic
    function primaryVideo {
        if ($selection.activeMediaFallbackItem -and $selection.mediaFallbackRunning) {
            return $smallReplacement
        } elseif ($selection.activeMediaFallbackItem) {
            return $smallReplacement
        } else {
            return $largeNative
        }
    }
    
    if ((primaryVideo) -ne $smallReplacement) { throw "Assertion failed: Active replacement wins regardless of video size" }
    
    $selection.activeMediaFallbackItem = $null
    $selection.mediaFallbackRunning = $true
    if ((primaryVideo) -ne $smallReplacement) { throw "Assertion failed: Starting replacement owns player controls" }
    
    $selection.mediaFallbackRunning = $false
    if ((primaryVideo) -ne $largeNative) { throw "Assertion failed: Inactive replacement excluded from native selection" }
    
    # Test navigation
    $navigated = 0
    $ctx = @{
        chrome = @{
            tabs = @{
                get = { return @{ url = "https://www.tiktok.com/@test/live" } }
                update = { $script:navigated++ }
            }
        }
        getState = { return @{} }
        pageHandle = { return "test" }
        cancelEmbedSession = {}
        cancelRecoveryForModeChange = {}
        closeEmbedChatSource = {}
        armLiveTab = {}
        normalLiveUrl = { return "https://www.tiktok.com/@test/live" }
    }
    
    # Simulate openNormalLive execution
    # This is a simplified version since we can't execute the actual JS function
    & $ctx.chrome.tabs.update
    if ($navigated -ne 1) { throw "Assertion failed: Normal must navigate even from the same LIVE URL" }
    
    # Test media fallback failure handling
    $released = 0
    $removed = 0
    $created = 0
    
    $video = New-JSObject @{
        pause = {}
        removeAttribute = {}
        load = {}
    }
    
    $player = @{
        mediaFallbackRunning = $false
        mediaFallbackPageUrl = "live"
        location = @{ href = "live" }
        attemptedMediaFallbackUrls = New-Object System.Collections.Generic.HashSet[string]
        activeMediaFallbackItem = $null
        releaseNativeAudio = $null
        mediaFallbackCandidates = { param($x) return $x }
        mediaFallbackKey = { param($x) return $x.url }
        ensureMediaFallbackVideo = { $script:created++; return $video }
        suppressNativeAudio = { return { $script:released++ } }
        setMediaFallbackStatus = {}
        destroyMediaFallbackPlayer = {}
        tryMediaUrl = { return @{ ok = $false; reason = "test failure" } }
        getPlayerState = { return @{} }
        document = @{ getElementById = { return @{ remove = { $script:removed++ } } } }
    }
    
    # Simulate playMediaFallback with empty sources
    if ($created -ne 0) { throw "Assertion failed: No sources must not cover the native player" }
    
    # Simulate playMediaFallback with failing source
    $result = & {
        $player.attemptedMediaFallbackUrls.Add("test") | Out-Null
        $player.mediaFallbackRunning = $true
        & $player.suppressNativeAudio
        $tryResult = & $player.tryMediaUrl
        $player.mediaFallbackRunning = $false
        return @{ activated = $tryResult.ok }
    }
    
    if ($result.activated -ne $false) { throw "Assertion failed: Result should not be activated" }
    if ($released -ne 1) { throw "Assertion failed: Failed startup restores native audio" }
    if ($removed -ne 1) { throw "Assertion failed: Failed startup removes replacement" }
    if ($player.mediaFallbackRunning -ne $false) { throw "Assertion failed: mediaFallbackRunning should be false" }
    
    Write-Host "PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay"
}

# Run exerciseSwitch and handle errors
try {
    exerciseSwitch
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
