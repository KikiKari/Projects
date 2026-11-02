#!/usr/bin/env pwsh
# test_status_overview_player.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview_player.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

#requires -version 7

using namespace System.Collections.Generic
using namespace System.Threading.Tasks

class Element {
    [string]$tag
    [hashtable]$style = @{}
    [System.Collections.Generic.List[object]]$children = [System.Collections.Generic.List[object]]::new()
    [hashtable]$listeners = @{}
    [bool]$muted = $false
    [bool]$paused = $true
    [string]$src = ''
    [int]$currentTime = 0

    Element([string]$tag) {
        $this.tag = $tag
    }

    [void] append([object[]]$nodes) {
        foreach ($node in $nodes) {
            $this.children.Add($node)
        }
    }

    [void] addEventListener([string]$name, [scriptblock]$fn) {
        if (-not $this.listeners.ContainsKey($name)) {
            $this.listeners[$name] = [System.Collections.Generic.HashSet[scriptblock]]::new()
        }
        [System.Collections.Generic.HashSet[scriptblock]]$this.listeners[$name].Add($fn) > $null
    }

    [void] removeEventListener([string]$name, [scriptblock]$fn) {
        if ($this.listeners.ContainsKey($name)) {
            [System.Collections.Generic.HashSet[scriptblock]]$this.listeners[$name].Remove($fn) > $null
        }
    }

    [void] emit([string]$name) {
        if ($this.listeners.ContainsKey($name)) {
            $fns = @() + ([System.Collections.Generic.HashSet[scriptblock]]$this.listeners[$name])
            foreach ($fn in $fns) {
                & $fn
            }
        }
    }

    [void] pause() {
        $this.paused = $true
    }

    [void] removeAttribute([string]$attr) {
        $this.src = ''
    }

    [void] load() {}

    [Task] play() {
        $this.paused = $false
        $task = [Task]::Run({
            Start-Sleep -Milliseconds 1
            if ($this.src.Contains('bad')) {
                $this.emit('error')
            } else {
                $this.currentTime += 1
                $this.emit('playing')
                $this.emit('timeupdate')
            }
        })
        return $task
    }
}

function Test-NineIndependentTilesStartMutedAndTryNextSource {
    $grid = [Element]::new('main')
    [scriptblock]$change = $null
    $rows = 0..8 | ForEach-Object {
        @{
            handle = "user$_"
            status = 'online'
            checkedAt = (Get-Date).ToFileTime()
            media = @(
                @{ protocol = 'hls'; url = "https://example.test/bad.m3u8" }
                @{ protocol = 'hls'; url = "https://example.test/good.m3u8" }
            )
        }
    }

    $context = @{
        document = @{
            getElementById = { return $grid }.GetNewClosure()
            createElement = { param($tag) return [Element]::new($tag) }.GetNewClosure()
        }
        chrome = @{
            runtime = @{
                sendMessage = { return @{ ok = $true; config = @{ interval = 5 }; rows = $rows } }.GetNewClosure()
            }
            storage = @{
                onChanged = @{
                    addListener = { param($fn) $change = $fn }.GetNewClosure()
                }
            }
        }
        window = @{ addEventListener = {} }
        URL = [uri]
        Date = [datetime]
        Promise = [System.Threading.Tasks.Task]
        Number = [double]
        String = [string]
        Array = [array]
        JSON = [Newtonsoft.Json.JsonConvert]
        Object = [object]
        setTimeout = { param($callback, $delay) Start-Sleep -Milliseconds $delay; & $callback }.GetNewClosure()
        clearTimeout = {}
    }

    # Simulate VM context execution by dot sourcing the script content with modified scope
    . ../browser-extension/status-overview-player.js
    
    Start-Sleep -Milliseconds 20

    if ($grid.children.Count -ne 29) {
        throw "Expected 29 children, got $($grid.children.Count)"
    }

    for ($i = 0; $i -lt 9; $i++) {
        $tile = $grid.children[$i]
        if ($tile.children[1].muted -ne $true) {
            throw "Tile $i is not muted"
        }
        if ($tile.children[1].src -notmatch 'good') {
            throw "Tile $i src does not match 'good': $($tile.children[1].src)"
        }
        if ($tile.children[2].textContent -notmatch 'abgespielt') {
            throw "Tile $i textContent does not match 'abgespielt': $($tile.children[2].textContent)"
        }
    }

    $rows[0] = @{
        handle = 'user0'
        status = 'offline'
        checkedAt = (Get-Date).ToFileTime()
        media = @()
    }
    
    & $change @{ 'tlc-overview-row-0' = @{} } 'session'
    
    Start-Sleep -Milliseconds 10

    if ($grid.children[0].hidden -ne $true) {
        throw "First tile should be hidden"
    }
    if ($grid.children[1].children[1].src -notmatch 'good') {
        throw "Second tile src does not match 'good'"
    }
}

function Test-RetrySwitchesOnlyRequestedTile {
    $grid = [Element]::new('main')
    [scriptblock]$change = $null
    $rows = 0..8 | ForEach-Object {
        @{
            handle = "user$_"
            status = 'online'
            checkedAt = (Get-Date).AddMinutes(-10).ToFileTime()
            media = @(
                @{ protocol = 'hls'; url = "https://example.test/${_}-first.m3u8" }
                @{ protocol = 'hls'; url = "https://example.test/${_}-bad.m3u8" }
                @{ protocol = 'hls'; url = "https://example.test/${_}-next.m3u8" }
            )
        }
    }

    foreach ($row in $rows) {
        $row.checkedAt = (Get-Date).ToFileTime()
    }

    $context = @{
        document = @{
            getElementById = { return $grid }.GetNewClosure()
            createElement = { param($tag) return [Element]::new($tag) }.GetNewClosure()
        }
        chrome = @{
            runtime = @{
                sendMessage = { return @{ ok = $true; config = @{ interval = 5 }; rows = $rows } }.GetNewClosure()
            }
            storage = @{
                onChanged = @{
                    addListener = { param($fn) $change = $fn }.GetNewClosure()
                }
            }
        }
        window = @{ addEventListener = {} }
        URL = [uri]
        Date = [datetime]
        Promise = [System.Threading.Tasks.Task]
        Number = [double]
        String = [string]
        Array = [array]
        JSON = [Newtonsoft.Json.JsonConvert]
        Object = [object]
        setTimeout = { param($callback, $delay) Start-Sleep -Milliseconds $delay; & $callback }.GetNewClosure()
        clearTimeout = {}
    }

    # Simulate VM context execution
    . ../browser-extension/status-overview-player.js
    
    Start-Sleep -Milliseconds 20

    $untouched = $grid.children[1].children[1].src
    if ($grid.children[0].children[1].src -notmatch 'first') {
        throw "First tile src does not contain 'first'"
    }

    & $change @{ 'tlc-overview-retry-0' = @{ newValue = @{ handle = 'user0'; nonce = 1 } } } 'session'
    
    Start-Sleep -Milliseconds 20

    if ($grid.children[0].children[1].src -notmatch 'next') {
        throw "First tile src does not contain 'next'"
    }
    if ($grid.children[1].children[1].src -ne $untouched) {
        throw "Second tile src was changed unexpectedly"
    }

    & $change @{ 'tlc-overview-retry-0' = @{ newValue = @{ handle = 'other'; nonce = 2 } } } 'session'
    
    Start-Sleep -Milliseconds 10
    
    if ($grid.children[0].children[1].src -notmatch 'next') {
        throw "First tile src should still contain 'next'"
    }

    $rows[0].media = @(@{ protocol = 'hls'; url = 'https://example.test/only.m3u8' })
    $rows[0].checkedAt = (Get-Date).ToFileTime()
    
    & $change @{ 'tlc-overview-row-0' = @{} } 'session'
    
    Start-Sleep -Milliseconds 10

    & $change @{ 'tlc-overview-retry-0' = @{ newValue = @{ handle = 'user0'; nonce = 3 } } } 'session'
    
    Start-Sleep -Milliseconds 10
    
    if ($grid.children[0].children[1].src -notmatch 'only') {
        throw "First tile src does not contain 'only'"
    }
}

function Test-SelectsFirstOnlineEntries {
    $grid = [Element]::new('main')
    [scriptblock]$change = $null
    $config = @{
        interval = 5
        expanded = $true
        grid2 = $true
        reverse = $false
        autoSort = $true
    }
    $rows = 0..19 | ForEach-Object {
        @{
            handle = "user$_"
            status = if ($_ % 2 -eq 1) { 'online' } else { 'offline' }
            checkedAt = (Get-Date).ToFileTime()
            media = @( @{ protocol = 'hls'; url = "https://example.test/$_.m3u8" } )
        }
    }

    $context = @{
        document = @{
            getElementById = { return $grid }.GetNewClosure()
            createElement = { param($tag) return [Element]::new($tag) }.GetNewClosure()
        }
        chrome = @{
            runtime = @{
                sendMessage = { return @{ ok = $true; config = $config; rows = $rows } }.GetNewClosure()
            }
            storage = @{
                onChanged = @{
                    addListener = { param($fn) $change = $fn }.GetNewClosure()
                }
            }
        }
        window = @{ addEventListener = {} }
        URL = [uri]
        Date = [datetime]
        Promise = [System.Threading.Tasks.Task]
        Number = [double]
        String = [string]
        Array = [array]
        JSON = [Newtonsoft.Json.JsonConvert]
        Object = [object]
        Map = [System.Collections.Generic.Dictionary[string,object]]
        setTimeout = { param($callback, $delay) Start-Sleep -Milliseconds $delay; & $callback }.GetNewClosure()
        clearTimeout = {}
    }

    # Simulate VM context execution
    . ../browser-extension/status-overview-player.js
    
    Start-Sleep -Milliseconds 20

    $shown = $grid.children[0..19] | Where-Object { $_.hidden -ne $true } | ForEach-Object { $grid.children.IndexOf($_) }
    $expected = @(1, 3, 5, 7)
    if ((Compare-Object $shown $expected) -ne $null) {
        throw "Shown indices don't match expected. Got: $($shown -join ', ') Expected: $($expected -join ', ')"
    }

    $config.reverse = $true
    & $change @{ 'tlc-overview-config' = @{} } 'local'
    
    Start-Sleep -Milliseconds 20
    
    $shown = $grid.children[0..19] | Where-Object { $_.hidden -ne $true } | ForEach-Object { $grid.children.IndexOf($_) }
    $expected = @(13, 15, 17, 19)
    if ((Compare-Object $shown $expected) -ne $null) {
        throw "Shown indices don't match expected in reverse mode. Got: $($shown -join ', ') Expected: $($expected -join ', ')"
    }
    if ($grid.children[19].style.order -ne '0') {
        throw "Last child order style incorrect"
    }

    $config.grid2 = $false
    & $change @{ 'tlc-overview-config' = @{} } 'local'
    
    Start-Sleep -Milliseconds 20
    
    $shownCount = ($grid.children[0..19] | Where-Object { $_.hidden -ne $true }).Count
    if ($shownCount -ne 9) {
        throw "Expected 9 shown items, got $shownCount"
    }
    if ($grid.children[19].style.order -ne '0') {
        throw "Last child order style incorrect after grid2 change"
    }

    $config.expanded = $false
    & $change @{ 'tlc-overview-config' = @{} } 'local'
    
    Start-Sleep -Milliseconds 20
    
    $shown = $grid.children[0..19] | Where-Object { $_.hidden -ne $true } | ForEach-Object { $grid.children.IndexOf($_) }
    $expected = @(1, 3, 5, 7)
    if ((Compare-Object $shown $expected) -ne $null) {
        throw "Shown indices don't match expected after expanded change. Got: $($shown -join ', ') Expected: $($expected -join ', ')"
    }
}

# Run tests
Test-NineIndependentTilesStartMutedAndTryNextSource
Test-RetrySwitchesOnlyRequestedTile
Test-SelectsFirstOnlineEntries

Write-Host "All tests passed!" -ForegroundColor Green
