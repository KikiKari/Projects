#!/usr/bin/env pwsh
# test_vlc_switch.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# PowerShell 7 translation of test_vlc_switch.cjs
# This script tests VLC switching functionality by simulating browser environment

# Helper functions to mimic JavaScript behavior
function New-ObjectFromTemplate($template) {
    $newObj = @{}
    $template.PSObject.Properties | ForEach-Object {
        $newObj[$_.Name] = $_.Value
    }
    return $newObj
}

function Assert-Equal($actual, $expected, $message = "") {
    if ($actual -ne $expected) {
        throw "Assertion failed: expected '$expected', got '$actual'. $message"
    }
}

function Assert-Match($text, $pattern, $message = "") {
    if (-not ($text -match $pattern)) {
        throw "Assertion failed: text does not match pattern '$pattern'. $message"
    }
}

function Assert-DoesNotMatch($text, $pattern, $message = "") {
    if ($text -match $pattern) {
        throw "Assertion failed: text should not match pattern '$pattern'. $message"
    }
}

try {
    # Get script directory
    $scriptDir = Split-Path $MyInvocation.MyCommand.Path
    $projectRoot = Join-Path $scriptDir ".."
    
    # Read content.js
    $contentJsPath = Join-Path $projectRoot "browser-extension" "content.js"
    $source = Get-Content $contentJsPath -Raw
    
    # Setup mock objects
    $listeners = @{}
    $native = @{ 
        muted = $false
        paused = $false
        pause = { $this.paused = $true }
        play = { $this.paused = $false; return [PSCustomObject]@{ } }
    }
    
    $fallback = @{ 
        muted = $false
        paused = $false
        closest = $null
    }
    
    $media = @($native, $fallback)
    $unrelatedVideo = New-ObjectFromTemplate($native)
    $speechAudio = New-ObjectFromTemplate($native)
    
    $surface = @{
        querySelectorAll = {
            param($selector)
            Assert-Equal $selector "video"
            return $media
        }
    }
    
    $fallback.closest = { return @{ parentElement = $surface } }
    
    $gain = @{ value = 0.7 }
    $changed = $null
    
    # Create context simulation
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
                $null = $listeners.Remove($name)
            }
        }
        MutationObserver = [PSCustomObject]@{
            observe = {}
            disconnect = {}
        }
    }
    
    # Extract and run suppressNativeAudio function
    $startPos = $source.IndexOf("  function suppressNativeAudio(")
    $endPos = $source.IndexOf("  async function playMediaFallback(")
    $suppressFunctionCode = $source.Substring($startPos, $endPos - $startPos)
    
    # Execute the function code in context (simulated)
    Invoke-Expression $suppressFunctionCode
    
    # Call suppressNativeAudio
    $release = suppressNativeAudio $fallback
    
    # Assertions
    Assert-Equal $native.muted $true
    Assert-Equal $native.paused $true
    Assert-Equal $gain.value 0
    Assert-Equal $fallback.muted $false
    Assert-Equal $fallback.paused $false
    
    $native.paused = $false
    (& $listeners['play'])
    Assert-Equal $native.paused $true
    
    $replacement = New-ObjectFromTemplate($native)
    $replacement.muted = $false
    $replacement.paused = $false
    $media += $replacement
    
    # Simulate change callback
    if ($changed) { & $changed }
    
    Assert-Equal $replacement.muted $true
    Assert-Equal $replacement.paused $true
    
    # Release and verify restoration
    & $release
    Assert-Equal $native.muted $false
    Assert-Equal $native.paused $false
    Assert-Equal $gain.value 0.7
    Assert-Equal $listeners.Count 0
    Assert-Equal $unrelatedVideo.paused $false
    Assert-Equal $speechAudio.paused $false
    
    # Test with unrelated video
    $context.audioPipeline.video = $unrelatedVideo
    $releaseUnrelated = suppressNativeAudio $fallback
    Assert-Equal $gain.value 0.7 "Unrelated audio pipeline must remain unchanged"
    & $releaseUnrelated
    
    # Read background.js
    $backgroundJsPath = Join-Path $projectRoot "browser-extension" "background.js"
    $background = Get-Content $backgroundJsPath -Raw
    
    $normalStart = $background.IndexOf("async function openNormalLive(")
    $normalEnd = $background.IndexOf("chrome.sidePanel.setPanelBehavior")
    $normal = $background.Substring($normalStart, $normalEnd - $normalStart)
    
    # Assertions on normal function
    Assert-Match $normal "await chrome.tabs.update\(tabId, \{ url: normalLiveUrl\(handle\) \}\)"
    Assert-DoesNotMatch $normal "if \(reloading\)"
    Assert-Match $source "if \(holder\?\.isConnected\) return holder.querySelector\(`"video`"\)"
    
    Write-Host "PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused"
    
    # Exercise switch functionality
    $sidepanelJsPath = Join-Path $projectRoot "browser-extension" "sidepanel.js"
    $panel = Get-Content $sidepanelJsPath -Raw
    
    $clickStart = $panel.IndexOf('  elements["player-vlc-frame"].addEventListener("click"')
    $clickEnd = $panel.IndexOf('  elements["player-volume"].addEventListener', $clickStart)
    
    $click = $null
    $starts = 0
    
    $button = @{
        addEventListener = {
            param($event, $fn)
            $click = $fn
        }
    }
    
    $panelContext = @{
        elements = @{ 'player-vlc-frame' = $button }
        installVlcIfNeeded = {
            throw "Internal replacement must not wait for desktop installation"
        }
        runPlayer = {
            param($action, $target)
            Assert-Equal $action "play-vlc-source"
            Assert-Equal $target $button
            $starts++
        }
    }
    
    $clickCode = $panel.Substring($clickStart, $clickEnd - $clickStart)
    Invoke-Expression $clickCode
    
    # Simulate click
    & $click
    Assert-Equal $starts 1 "VLC click dispatches internal player immediately"
    
    # Test primaryVideo selection logic
    $largeNative = @{
        closest = { return $null }
        getBoundingClientRect = { return @{ width = 1000; height = 1000 } }
    }
    
    $smallReplacement = @{
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
    
    $primaryVideoStart = $source.IndexOf("  function primaryVideo(")
    $primaryVideoEnd = $source.IndexOf("  function playerToggleControl(")
    $primaryVideoCode = $source.Substring($primaryVideoStart, $primaryVideoEnd - $primaryVideoStart)
    
    Invoke-Expression $primaryVideoCode
    
    Assert-Equal (primaryVideo) $smallReplacement "Active replacement wins regardless of video size"
    
    $selection.activeMediaFallbackItem = $null
    $selection.mediaFallbackRunning = $true
    Assert-Equal (primaryVideo) $smallReplacement "Starting replacement owns player controls"
    
    $selection.mediaFallbackRunning = $false
    Assert-Equal (primaryVideo) $largeNative "Inactive replacement excluded from native selection"
    
    # Test navigation
    $navigated = 0
    $ctx = @{
        chrome = @{
            tabs = @{
                get = { return @{ url = "https://www.tiktok.com/@test/live" } }
                update = { $navigated++ }
            }
        }
        getState = { return @{} }
        pageHandle = { return "test" }
        cancelEmbedSession = { }
        cancelRecoveryForModeChange = { }
        closeEmbedChatSource = { }
        armLiveTab = { }
        normalLiveUrl = { return "https://www.tiktok.com/@test/live" }
    }
    
    Invoke-Expression $normal
    
    openNormalLive 1
    Assert-Equal $navigated 1 "Normal must navigate even from the same LIVE URL"
    
    # Test media fallback failure handling
    $released = 0
    $removed = 0
    $created = 0
    
    $video = @{
        pause = { }
        removeAttribute = { }
        load = { }
    }
    
    $player = @{
        mediaFallbackRunning = $false
        mediaFallbackPageUrl = "live"
        location = @{ href = "live" }
        attemptedMediaFallbackUrls = @()
        activeMediaFallbackItem = $null
        releaseNativeAudio = $null
        mediaFallbackCandidates = { param($x) return $x }
        mediaFallbackKey = { param($x) return $x.url }
        ensureMediaFallbackVideo = {
            $created++
            return $video
        }
        suppressNativeAudio = {
            return {
                $released++
            }
        }
        setMediaFallbackStatus = { }
        destroyMediaFallbackPlayer = { }
        tryMediaUrl = {
            return @{ ok = $false; reason = "test failure" }
        }
        getPlayerState = { return @{} }
        document = @{
            getElementById = {
                return @{ remove = { $removed++ } }
            }
        }
    }
    
    $playMediaFallbackStart = $source.IndexOf("  async function playMediaFallback(")
    $playMediaFallbackEnd = $source.IndexOf("  async function configureLimiter(")
    $playMediaFallbackCode = $source.Substring($playMediaFallbackStart, $playMediaFallbackEnd - $playMediaFallbackStart)
    
    Invoke-Expression $playMediaFallbackCode
    
    playMediaFallback @()
    Assert-Equal $created 0 "No sources must not cover the native player"
    
    $result = playMediaFallback @(@{ url = "test"; quality = "test" })
    Assert-Equal $result.activated $false
    Assert-Equal $released 1 "Failed startup restores native audio"
    Assert-Equal $removed 1 "Failed startup removes replacement"
    Assert-Equal $player.mediaFallbackRunning $false
    
    Write-Host "PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay"
    
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
