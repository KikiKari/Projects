#!/usr/bin/env pwsh
# test_hook_recovery.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_hook_recovery.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_hook_recovery.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

#Requires -Version 7

param()

# Import required modules
Add-Type -AssemblyName System.Security.Cryptography

# Define helper functions to mimic Node.js behavior
function New-Map {
    return @{}
}

function Add-ToMap($map, $key, $value) {
    $map[$key] = $value
}

function Remove-FromMap($map, $key) {
    $map.Remove($key)
}

function Get-MapKeys($map) {
    return $map.Keys
}

function ConvertTo-Uint8Array($array) {
    return [byte[]]$array
}

# Mock assert module
function Assert-Equal($actual, $expected, $message = "") {
    if ($actual -ne $expected) {
        throw "Assertion failed: Expected '$expected', but got '$actual'. $message"
    }
}

function Assert-Ok($condition, $message = "") {
    if (-not $condition) {
        throw "Assertion failed: $message"
    }
}

function Assert-Throws($scriptBlock, $exceptionType) {
    try {
        & $scriptBlock
        throw "Expected exception '$exceptionType' was not thrown"
    } catch {
        if ($_ -isnot $exceptionType) {
            throw "Expected exception '$exceptionType' but got '$($_.GetType())'"
        }
    }
}

function Assert-DeepEqual($actual, $expected, $message = "") {
    if (-not (Compare-Object $actual $expected)) {
        return
    }
    throw "Assertion failed: Objects are not equal. $message"
}

# Load hook-recovery.js content as a script block
$hookRecoveryPath = Join-Path $PSScriptRoot "../browser-extension/hook-recovery.js"
$hookRecoveryContent = Get-Content -Path $hookRecoveryPath -Raw

# Load proto-main.js content
$protoMainPath = Join-Path $PSScriptRoot "../browser-extension/proto-main.js"
$protoMainContent = Get-Content -Path $protoMainPath -Raw

# Define harness function
function New-Harness {
    param()
    
    $now = 1000
    $serial = 0
    $identity = 'stream-a'
    $timers = New-Map
    $events = @()
    $sockets = @()
    
    # Create controller using hook-recovery.js logic
    . ([ScriptBlock]::Create($hookRecoveryContent))
    
    $controller = Create-HookRecoveryController @{
        now = { return $now }
        uuid = { 
            $script:serial++
            return $serial.ToString()
        }
        identity = { return $identity }
        emit = { param($e) $events.Add($e) }
        later = {
            param($fn, $ms)
            $id = ++$script:serial
            Add-ToMap $timers $id @{ at = $now + $ms; fn = $fn }
            return $id
        }
        cancel = { param($id) Remove-FromMap $timers $id }
        connect = {
            param($template, $token)
            $s = @{
                token = $token
                closed = $false
                close = {
                    $this.closed = $true
                }
            }
            $sockets.Add($s)
            return $s
        }
    }
    
    $tick = {
        param($ms)
        $target = $now + $ms
        while ($true) {
            $nextTimers = @()
            foreach ($timerKey in Get-MapKeys $timers) {
                $timer = $timers[$timerKey]
                if ($timer.at -le $target) {
                    $nextTimers += [PSCustomObject]@{
                        key = $timerKey
                        at = $timer.at
                        fn = $timer.fn
                    }
                }
            }
            
            if ($nextTimers.Count -eq 0) {
                break
            }
            
            $nextTimers = $nextTimers | Sort-Object at
            $next = $nextTimers[0]
            
            $now = $next.at
            Remove-FromMap $timers $next.key
            & $next.fn
        }
        $script:now = $target
    }
    
    return @{
        controller = $controller
        tick = $tick
        events = $events
        sockets = $sockets
        timers = $timers
        stream = {
            param($v)
            $script:identity = $v
            $controller.CheckStream()
        }
        prime = {
            $controller.NativeConnected(@{supported = $true})
            $controller.Configure(@{enabled = $true; seconds = 3})
            $controller.NativeDisconnected()
        }
    }
}

# Test cases
Describe "Hook Recovery Tests" {
    It "hook default disabled and unverified protocol cannot create sockets" {
        $h = New-Harness
        $h.controller.NativeDisconnected()
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 0
        $h.controller.Configure(@{enabled = $true})
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 0
        Assert-Equal $h.events[-1].phase 'unavailable'
    }
    
    It "five synthetic hook failures recover without any media/navigation capability" {
        $h = New-Harness
        & $h.prime
        for ($i = 0; $i -lt 5; $i++) {
            & $h.tick 2999
            Assert-Equal $h.sockets.Count $i
            & $h.tick 1
            $token = $h.sockets[-1].token
            $h.controller.Stage($token, 'socket-open')
            & $h.tick 200
            $h.controller.Stage($token, 'first-frame')
            & $h.tick 100
            $h.controller.Stage($token, 'first-decoded-message')
            Assert-Equal $h.controller.Connected($token) $true
            Assert-Equal $h.events[-1].disconnectToDecodedMs 3300
            $h.controller.NativeConnected(@{supported = $true})
            Assert-Equal $h.sockets[-1].closed $true
            $h.controller.NativeDisconnected()
        }
    }
    
    It "open alone times out after ten seconds, one socket, backoff capped at 30 seconds" {
        $h = New-Harness
        & $h.prime
        & $h.tick 3000
        for ($i = 0; $i -lt 6; $i++) {
            $s = $h.sockets[-1]
            $h.controller.Stage($s.token, 'socket-open')
            & $h.tick 9999
            Assert-Equal $s.closed $false
            & $h.tick 1
            Assert-Equal $s.closed $true
            $delay = $h.events[-1].effectiveDelayMs
            Assert-Ok ($delay -le 30000)
            & $h.tick $delay
            $openSockets = $h.sockets | Where-Object { -not $_.closed }
            Assert-Equal $openSockets.Count 1
        }
    }
    
    It "native takeover cancels deadline and ignores stale socket callbacks" {
        $h = New-Harness
        & $h.prime
        & $h.tick 3000
        $token = $h.sockets[0].token
        $h.controller.NativeConnected(@{supported = $true})
        Assert-Equal $h.controller.Connected($token) $false
        $h.controller.Failed($token, 'socket-close')
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 1
        Assert-Equal $h.events[-1].phase 'native'
    }
    
    It "stream switch discards template and cancels scheduled attempt" {
        $h = New-Harness
        & $h.prime
        & $h.stream 'stream-b'
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 0
        $h.controller.NativeDisconnected()
        Assert-Equal $h.events[-1].phase 'unavailable'
    }
    
    It "disable closes owned socket and policy rejection forbids retries" {
        $h = New-Harness
        & $h.prime
        & $h.tick 3000
        $h.controller.Configure(@{enabled = $false})
        Assert-Equal $h.sockets[0].closed $true
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 1
        
        $p = New-Harness
        & $p.prime
        & $p.tick 3000
        $p.controller.Failed($p.sockets[0].token, 'policy-rejected')
        & $p.tick 60000
        Assert-Equal $p.sockets.Count 1
        Assert-Equal $p.events[-1].phase 'unavailable'
    }
    
    It "disposed document never reconnects after new configuration" {
        $h = New-Harness
        & $h.prime
        $h.controller.Dispose()
        $h.controller.Configure(@{enabled = $true})
        & $h.tick 60000
        Assert-Equal $h.sockets.Count 0
    }
    
    # Load proto-main.js content for testing
    . ([ScriptBlock]::Create($protoMainContent))
    
    It "ACK and heartbeat encoder round trips supported dialect and rejects malformed controls" {
        Assert-Equal (Inspect-TransportControl (Encode-Transport 'hb')).type 'hb'
        
        $ack = Inspect-TransportControl (Encode-Transport 'ack' '18446744073709551615' 'opaque')
        Assert-Equal $ack.id '18446744073709551615'
        Assert-Equal $ack.payload 'opaque'
        
        Assert-Equal (Inspect-TransportControl (Encode-Transport 'ack' 0)) $null
        Assert-Equal (Inspect-TransportControl (Encode-Transport 'hb' 1)) $null
        Assert-Equal (Inspect-TransportControl (ConvertTo-Uint8Array @(255))) $null
        
        Assert-Throws { Encode-Transport 'ack' -1 } ([System.ArgumentException])
    }
}

# Run tests
Invoke-Pester -ScriptBlock (Get-Command Describe).ScriptBlock
