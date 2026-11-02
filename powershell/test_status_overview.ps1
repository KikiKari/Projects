#!/usr/bin/env pwsh
# test_status_overview.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

#requires -version 7

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text.RegularExpressions
using namespace System.Threading.Tasks

$ErrorActionPreference = 'Stop'

# Load required modules
Add-Type -AssemblyName System.Web

# Define paths
$scriptPath = $MyInvocation.MyCommand.Path
$sourcePath = Join-Path (Split-Path $scriptPath -Parent) '../browser-extension/status-overview-worker.js'
$source = Get-Content -Path $sourcePath -Raw -Encoding UTF8

function Setup($fetchImpl, $captured = $null) {
    $local = @{}
    $session = @{}
    $alarms = [Dictionary[string, object]]::new()
    $opened = [List[object]]::new()
    $onAlarm = $null
    
    function Storage($data) {
        return @{
            Get = {
                param($keys)
                if ($keys -eq $null) {
                    return $data.Clone()
                }
                if (-not ($keys -is [array])) {
                    $keys = @($keys)
                }
                $result = @{}
                foreach ($key in $keys) {
                    if ($data.ContainsKey($key)) {
                        $result[$key] = $data[$key]
                    }
                }
                return $result
            }
            Set = {
                param($values)
                foreach ($kv in $values.GetEnumerator()) {
                    $data[$kv.Key] = $kv.Value
                }
            }
            Remove = {
                param($key)
                $data.Remove($key)
            }
        }
    }
    
    $chrome = @{
        storage = @{
            local = Storage($local)
            session = Storage($session)
        }
        alarms = @{
            onAlarm = @{
                AddListener = {
                    param($f)
                    $script:onAlarm = $f
                }
            }
            Create = {
                param($n, $v)
                $alarms[$n] = $v
            }
            Clear = {
                param($n)
                $alarms.Remove($n)
            }
        }
        runtime = @{
            onStartup = @{
                AddListener = {}
            }
            GetURL = {
                param($x)
                return "chrome-extension://test/$x"
            }
        }
        tabs = @{
            Create = {
                param($v)
                $opened.Add($v)
            }
            Get = {
                param($id)
                return @{id = $id; url = 'chrome-extension://test/status-overview.html'}
            }
        }
    }
    
    $core = @{
        InspectMetadata = {
            param($room)
            return @{media = if ($room.media) { $room.media } else { @() }}
        }
        LiveHandleFromUrl = {
            param($url)
            $match = [Regex]::Match($url, '@([^/]+)')
            if ($match.Success) {
                return $match.Groups[1].Value
            }
            return ''
        }
    }
    
    if ($captured) {
        $chrome.tabs.Query = {
            return $captured.tabs
        }
        $chrome.tabs.SendMessage = {
            param($id)
            $captured.scans += $id
            return [Task]::CompletedTask
        }
    }
    
    $context = @{
        chrome = $chrome
        core = $core
        fetch = $fetchImpl
        getState = {
            param($id)
            if ($captured -and $captured.states.ContainsKey($id)) {
                return $captured.states[$id]
            }
            return @{media = @()}
        }
        URL = [System.Uri]
        Date = [DateTime]
        Set = [HashSet[object]]
        Map = [Dictionary[object, object]]
        Object = [Object]
        Array = [Array]
        Math = [Math]
        Number = [Double]
        String = [String]
        Promise = [Task]
        AbortController = [System.Threading.CancellationTokenSource]
        setTimeout = {
            param($callback, $delay)
            Start-Sleep -Milliseconds $delay
            & $callback
        }
        clearTimeout = {}
    }
    
    # Create script block from source
    $scriptBlock = [ScriptBlock]::Create("$source`n`$globalThis.overview = TLCOverview;")
    
    # Execute in context
    $ExecutionContext.InvokeCommand.InvokeScript($false, $scriptBlock, $null, $context)
    
    return @{
        api = $context.overview
        opened = $opened
        session = $session
        alarms = $alarms
        Fire = {
            & $onAlarm @{name = 'tlc-overview-check'}
            Start-Sleep -Milliseconds 10
        }
    }
}

function Html($handle, $status, $media = @()) {
    $data = @{
        LiveRoom = @{
            liveRoomUserInfo = @{
                user = @{uniqueId = $handle}
                liveRoom = @{status = $status; media = $media}
            }
        }
    }
    return "<script id=`"SIGI_STATE`" type=`"application/json`">$([System.Text.Json.JsonSerializer]::Serialize($data))</script>"
}

Describe 'TLC Overview Tests' {
    It 'checks LIVE and offline via direct requests without opening tabs' {
        $requested = [List[string]]::new()
        $x = Setup({
            param($url)
            $requested.Add($url)
            $name = [Regex]::Match($url, '@([^/]+)').Groups[1].Value
            $status = if ($name -eq 'one') { 2 } else { 4 }
            return @{
                ok = $true
                text = { return Html $name $status @(@{url='https://cdn.test/a.flv'; audioOnly=$false}) }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('@One','Two'); interval=5}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        
        $rows = ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows
        $rows[0].status | Should -Be 'online'
        $rows[0].media.Count | Should -Be 1
        $rows[1].status | Should -Be 'offline'
        $rows[1].media.Count | Should -Be 0
        $requested.Count | Should -Be 2
        $x.opened.Count | Should -Be 0
        $x.alarms['tlc-overview-check'].periodInMinutes | Should -Be 5
    }
    
    It 'unavailable or mismatched response is an error, never falsely offline' {
        $x = Setup({
            param($url)
            if ($url.Contains('@one/')) {
                return @{ok = $false}
            }
            return @{
                ok = $true
                text = { return Html 'other' 4 }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one','two')}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $rows = ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows
        $rows[0].status | Should -Be 'error'
        $rows[1].status | Should -Be 'error'
    }
    
    It 'rejects duplicate and invalid names; opens overview in requested window' {
        $x = Setup({})
        { $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('a','@A')}}) } | Should -Throw
        { $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('bad/name')}}) } | Should -Throw
        $x.api.message(@{type='TLC_OVERVIEW_OPEN'; windowId=23})
        $x.opened[0].windowId | Should -Be 23
        $x.opened[0].url | Should -Match 'status-overview.html'
        { $x.api.message(@{type='TLC_OVERVIEW_OPEN'}) } | Should -Throw
    }
    
    It 'does not apply an obsolete result after changing a handle' {
        $release = $null
        $pending = New-Object TaskCompletionSource[void]
        $x = Setup({
            $pending.Task.Wait()
            return @{
                ok = $true
                text = { return Html 'one' 2 }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one')}})
        $check = $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        Start-Sleep -Milliseconds 1
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('two')}})
        $pending.SetResult($null)
        $check.Wait()
        $row = ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows[0]
        $row.handle | Should -Be 'two'
        $row.status | Should -Be 'unknown'
    }
    
    It 'playing streams are skipped until playback stops and timer can be disabled' {
        $seen = [List[string]]::new()
        $x = Setup({
            param($url)
            $seen.Add($url)
            $name = [Regex]::Match($url, '@([^/]+)').Groups[1].Value
            return @{
                ok = $true
                text = { return Html $name 2 }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one','two'); interval=5}})
        $sender = @{tab=@{id=42}; url='chrome-extension://test/status-overview.html'}
        $x.api.message(@{type='TLC_OVERVIEW_PLAYBACK'; index=0; handle='one'; playing=$true}, $sender)
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $seen.Count | Should -Be 1
        $seen[0] | Should -Match '@two'
        $x.api.message(@{type='TLC_OVERVIEW_PLAYBACK'; index=0; handle='one'; playing=$false}, $sender)
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $seen.Count | Should -Be 3
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one','two'); enabled=$false}})
        $x.alarms.ContainsKey('tlc-overview-check') | Should -Be $false
        $x.Fire()
        $seen.Count | Should -Be 3
    }
    
    It 'persists settings, limits sources, and resets only handles' {
        $media = @(0..34 | ForEach-Object { @{url="https://cdn.test/$_.flv"; audioOnly=($_ -eq 0)} })
        $x = Setup({
            return @{
                ok = $true
                text = { return Html 'one' 2 $media }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one'); interval=7; maxLinks=30; showLinks=$true; autoSort=$true; skipOnline=$false}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $state = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $state.rows[0].media.Count | Should -Be 30
        $state.rows[0].media[0].audioOnly | Should -Be $true
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{maxLinks=5}})
        $state = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $state.rows[0].media.Count | Should -Be 5
        $x.api.message(@{type='TLC_OVERVIEW_RESET'})
        $state = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $state.rows[0].handle | Should -Be ''
        $state.rows[0].media.Count | Should -Be 0
        $state.config.interval | Should -Be 7
        $state.config.autoSort | Should -Be $true
        $state.config.showLinks | Should -Be $true
    }
    
    It 'skips online streams only when the option is enabled' {
        $calls = 0
        $x = Setup({
            $calls++
            return @{
                ok = $true
                text = { return Html 'one' 2 @(@{url='https://cdn.test/a.flv'}) }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one'); skipOnline=$true}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $calls | Should -Be 1
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{skipOnline=$false}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $calls | Should -Be 2
    }
    
    It 'retry targets the original handle and rejects stale or invalid slots' {
        $x = Setup({})
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one','two'); skipOnline=$true}})
        $x.session['tlc-overview-row-1'] = @{handle='two'; status='online'; media=@(@{url='https://cdn.test/a.flv'})}
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=1; handle='two'})
        $x.session['tlc-overview-retry-1'].handle | Should -Be 'two'
        { $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=1; handle='one'}) } | Should -Throw
        { $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=9; handle='two'}) } | Should -Throw
    }
    
    It 'online without links is checked on schedule and retries only its own slot' {
        $seen = [List[string]]::new()
        $x = Setup({
            param($url)
            $name = [Regex]::Match($url, '@([^/]+)').Groups[1].Value
            $seen.Add($name)
            $media = if ($name -eq 'two') { @(@{url='https://cdn.test/two.flv'}) } else { @() }
            return @{
                ok = $true
                text = { return Html $name 2 $media }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one','two'); skipOnline=$true}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $seen | Should -Be @('one','two','one')
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=0; handle='one'})
        $seen | Should -Be @('one','two','one','one')
    }
    
    It 'top selection is persisted and reset preserves it' {
        $x = Setup({})
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{top='monitor'}})
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).config.top | Should -Be 'monitor'
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{top='connection'}})
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).config.top | Should -Be 'connection'
        $x.api.message(@{type='TLC_OVERVIEW_RESET'})
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).config.top | Should -Be 'connection'
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{top=''}})
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).config.top | Should -Be ''
    }
    
    It 'manual zero-link retry rescans only matching LIVE tab and imports its captured sources' {
        $captured = @{
            tabs = @(
                @{id=1; url='https://www.tiktok.com/@one/live'},
                @{id=2; url='https://www.tiktok.com/@two/live'}
            )
            states = @{
                1 = @{media=@()}
                2 = @{media=@(@{url='https://cdn.test/wrong.flv'})}
            }
            scans = @()
        }
        
        $x = Setup({
            return @{
                ok = $true
                text = { return Html 'one' 2 }
            }
        }, $captured)
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one')}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows[0].media.Count | Should -Be 0
        $captured.states[1].media = @(@{url='https://cdn.test/live.flv'; protocol='FLV'})
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=0; handle='one'})
        $row = ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows[0]
        $row.media[0].url | Should -Be 'https://cdn.test/live.flv'
        $captured.scans | Should -Be @(1,1)
    }
    
    It 'twenty handles, persistent grid options and high-index actions are supported' {
        $x = Setup({
            param($url)
            $name = [Regex]::Match($url, '@([^/]+)').Groups[1].Value
            return @{
                ok = $true
                text = { return Html $name 2 @(@{url="https://cdn.test/$name.flv"}) }
            }
        })
        
        $handles = @(0..19 | ForEach-Object { "user$_" })
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=$handles; expanded=$true; reverse=$true; grid2=$true}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $result = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $result.rows.Count | Should -Be 20
        $result.rows[19].status | Should -Be 'online'
        $result.config.reverse | Should -Be $true
        $result.config.grid2 | Should -Be $true
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=19; handle='user19'})
        $x.session['tlc-overview-retry-19'].handle | Should -Be 'user19'
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{expanded=$false}})
        $result = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $result.config.handles[19] | Should -Be 'user19'
        $x.api.message(@{type='TLC_OVERVIEW_RESET'})
        $result = $x.api.message(@{type='TLC_OVERVIEW_GET'})
        $result.config.handles.ForEach({ $_ -eq '' }) | Should -Contain $true
    }
    
    It 'manual retry refreshes playing stream URLs only when skipOnline is disabled' {
        $count = 0
        $x = Setup({
            $count++
            return @{
                ok = $true
                text = { return Html 'one' 2 @(@{url="https://cdn.test/live-$count.flv"}) }
            }
        })
        
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{handles=@('one'); skipOnline=$false}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $sender = @{tab=@{id=42}; url='chrome-extension://test/status-overview.html'}
        $x.api.message(@{type='TLC_OVERVIEW_PLAYBACK'; index=0; handle='one'; playing=$true}, $sender)
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=0; handle='one'})
        $count | Should -Be 2
        ($x.api.message(@{type='TLC_OVERVIEW_GET'})).rows[0].media[0].url | Should -Match 'live-2'
        $x.session['tlc-overview-retry-0'].handle | Should -Be 'one'
        $x.api.message(@{type='TLC_OVERVIEW_SET'; config=@{skipOnline=$true}})
        $x.api.message(@{type='TLC_OVERVIEW_CHECK'})
        $x.api.message(@{type='TLC_OVERVIEW_RETRY'; index=0; handle='one'})
        $count | Should -Be 2
    }
}
