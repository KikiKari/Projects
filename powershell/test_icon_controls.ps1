#!/usr/bin/env pwsh
# test_icon_controls.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_icon_controls.cjs
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Security

# Define root path
$root = Join-Path $PSScriptRoot "../browser-extension"

# Read the script content
$scriptContent = Get-Content -Path (Join-Path $root "icon-controls.js") -Raw

# Harness function equivalent
function Invoke-Harness {
    param(
        [string]$saved
    )

    # Elements map simulation
    $elements = @{}

    function Get-Element($id) {
        if (-not $elements.ContainsKey($id)) {
            $el = @{
                dataset = @{}
                value = ""
                textContent = switch ($id) {
                    "player-play" { "Play" }
                    "player-mute" { "Mute" }
                    default { "On" }
                }
                handlers = @{}
                attributes = @{}
                classList = @{ add = { } }
                setAttribute = { param($k, $v) $this.attributes[$k] = $v }
                getAttribute = { param($k) return $this.attributes[$k] }
                addEventListener = { param($n, $f) $this.handlers[$n] = $f }
                before = { throw "Unexpected decorative control image" }
            }
            $elements[$id] = $el
        }
        return $elements[$id]
    }

    # Storage simulation
    $storage = @{ "tlc-icon-style" = $saved }

    # Document mock
    $document = @{
        documentElement = @{ dataset = @{} }
        body = @{}
        getElementById = { param($id) Get-Element $id }
        createElement = { Get-Element ([System.Guid]::NewGuid().ToString()) }
        querySelectorAll = { $elements.Values }
    }

    # MutationObserver mock
    $observer = $null
    $MutationObserver = [PSCustomObject]@{
        Observe = { }
    }

    # LocalStorage mock
    $localStorage = @{
        getItem = { param($k) $storage[$k] }
        setItem = { param($k, $v) $storage[$k] = $v }
    }

    # Run script in constrained environment
    $sandbox = @{
        document = $document
        localStorage = $localStorage
        MutationObserver = [type]::GetType("System.Object")
    }

    # Create a new runspace to execute JavaScript-like logic
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [PowerShell]::Create()
    $ps.Runspace = $runspace
    $ps.AddScript($scriptContent).AddArgument($sandbox)
    $ps.Invoke()

    return @{
        elements = $elements
        document = $document
        storage = $storage
        observer = $MutationObserver
    }
}

# Test loop over styles
foreach ($style in @($null, "invalid", "plastisch", "glass", "linear")) {
    $h = Invoke-Harness -saved $style
    $expectedStyle = if (@("plastisch", "glass", "linear") -contains $style) { $style } else { "plastisch" }
    if ($h.document.documentElement.dataset.iconStyle -ne $expectedStyle) {
        throw "Assertion failed: Expected '$expectedStyle', got '$($h.document.documentElement.dataset.iconStyle)'"
    }

    $picker = $h.elements["icon-style"]
    $picker.value = "glass"
    & $picker.handlers.change
    if ($h.storage["tlc-icon-style"] -ne "glass") {
        throw "Assertion failed: Storage mismatch"
    }
    if ($h.document.documentElement.dataset.iconStyle -ne "glass") {
        throw "Assertion failed: Style mismatch after change"
    }

    foreach ($playing in @($false, $true)) {
        foreach ($muted in @($false, $true)) {
            $playEl = $h.elements["player-play"]
            $playEl.textContent = if ($playing) { "Stop" } else { "Play" }
            $muteEl = $h.elements["player-mute"]
            $muteEl.textContent = if ($muted) { "Unmute" } else { "Mute" }
            # Trigger observer manually if needed
            if ($h.observer) {
                & $h.observer
            }
            $expectedPlayIcon = if ($playing) { "stop" } else { "play" }
            $expectedMuteIcon = if ($muted) { "unmute" } else { "mute" }
            if ($playEl.dataset.controlIcon -ne $expectedPlayIcon) {
                throw "Assertion failed: Play icon mismatch"
            }
            if ($muteEl.dataset.controlIcon -ne $expectedMuteIcon) {
                throw "Assertion failed: Mute icon mismatch"
            }
        }
    }
}

# Manifest validation
$manifestPath = Join-Path $root "icons/manifest.json"
$manifest = Get-Content -Path $manifestPath | ConvertFrom-Json
if ($manifest.Count -ne 60) {
    throw "Assertion failed: Manifest count mismatch"
}

foreach ($m in $manifest) {
    $filePath = Join-Path $root "icons/$($m.style)/$($m.component).png"
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    $hexHash = -join ($hash | ForEach-Object { "{0:x2}" -f $_ })
    if ($hexHash -ne $m.sha256) {
        throw "Assertion failed: Hash mismatch for $($m.component)"
    }
}

# Additional assertions
$h = Invoke-Harness -saved "plastisch"
if ($h.elements["refresh-page-info"].attributes.title -ne "Refresh") {
    throw "Assertion failed: Title mismatch"
}
if ($h.elements["refresh-page-info"].attributes["aria-label"] -ne "Refresh") {
    throw "Assertion failed: aria-label mismatch"
}

$idsToCheck = @("chat-count", "player-volume", "speech-volume", "limiter-strength", "recommendation-limit", "auto-chat-refresh-minutes")
foreach ($id in $idsToCheck) {
    if ($h.elements.ContainsKey($id)) {
        throw "Assertion failed: Element $id should not exist"
    }
}

$controlElements = @{
    "player-play" = @("Play", "Stop")
    "player-mute" = @("Mute", "Unmute")
    "toggle-speech" = @("On", "Off")
    "toggle-hook" = @("On", "Off")
}

foreach ($pair in $controlElements.GetEnumerator()) {
    $id = $pair.Key
    $values = $pair.Value
    foreach ($value in $values) {
        $el = $h.elements[$id]
        $el.textContent = $value
        # Trigger observer manually if needed
        if ($h.observer) {
            & $h.observer
        }
        if (-not $el.attributes["aria-label"].EndsWith($value)) {
            throw "Assertion failed: aria-label does not end with $value"
        }
        if (-not $el.attributes.title.EndsWith($value)) {
            throw "Assertion failed: title does not end with $value"
        }
    }
}

# CSS check
$cssPath = Join-Path $root "icon-controls.css"
$css = Get-Content -Path $cssPath -Raw
if ($css -notmatch "button\[data-control-icon\] \{[^}]*font-size:0") {
    throw "Assertion failed: CSS pattern mismatch"
}

# Sidepanel check
$sidepanelPath = Join-Path $root "sidepanel.js"
$sidepanel = Get-Content -Path $sidepanelPath -Raw
if ($sidepanel -match "von bis zu \$\{requested\}") {
    throw "Assertion failed: Sidepanel contains unexpected string"
}

Write-Host "PASS: defaults, invalid stored style, three styles, persistence, 20 state combinations and 60 packaged asset hashes"
