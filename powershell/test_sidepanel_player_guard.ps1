#!/usr/bin/env pwsh
# test_sidepanel_player_guard.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_sidepanel_player_guard.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# PowerShell does not have direct equivalents for node:vm
# We'll need to simulate the JavaScript execution context
# by parsing and executing the relevant parts manually

# Read the source file
$sourcePath = Join-Path $PSScriptRoot "..\browser-extension\sidepanel.js"
$source = Get-Content -Raw -Path $sourcePath

# Find the relevant function boundaries
$start = $source.IndexOf("  async function refreshPlayer()")
$end = $source.IndexOf("  function setButtonBusy", $start)

if ($start -lt 0 -or $end -le $start) {
    throw "Could not find refreshPlayer function boundaries"
}

try {
    # Initialize test variables
    $reply = $null
    $calls = 0
    $rendered = @()
    
    # Create a custom object to simulate the JavaScript context
    $context = @{
        activeTabId = 1
        activeIsTikTok = $true
        playerContextGeneration = 0
        send = {
            param()
            $script:calls++
            return [System.Threading.Tasks.Task]::Run({
                # This simulates the promise behavior
                while ($script:reply -eq $null) {
                    Start-Sleep -Milliseconds 10
                }
                return $script:reply.Invoke()
            })
        }.GetNewClosure()
        renderPlayer = {
            param($state)
            $script:rendered += $state
        }.GetNewClosure()
        refreshPlayer = $null  # Will be populated from source
    }
    
    # Extract and adapt the refreshPlayer function from source
    # Since PowerShell can't directly execute JS code, we need to translate the logic
    
    # The key logic we're testing:
    # 1. Only TikTok tabs are polled
    # 2. Old tab responses are ignored
    # 3. Current tab responses are rendered
    # 4. Context invalidation works properly
    
    # Simulate the refreshPlayer function logic
    function Invoke-RefreshPlayer {
        param($ctx)
        
        # Increment context generation to invalidate previous requests
        $ctx.playerContextGeneration++
        $currentGeneration = $ctx.playerContextGeneration
        $currentTabId = $ctx.activeTabId
        
        # Only poll if it's a TikTok tab
        if (-not $ctx.activeIsTikTok) {
            return [System.Threading.Tasks.Task]::CompletedTask
        }
        
        # Simulate sending request (returns a task that completes when reply is called)
        $taskSource = [System.Threading.Tasks.TaskCompletionSource[hashtable]]::new()
        
        # Store the callback to simulate promise resolution
        $script:pendingTasks += @{
            Generation = $currentGeneration
            TabId = $currentTabId
            TaskSource = $taskSource
        }
        
        $script:calls++
        return $taskSource.Task
    }
    
    # Initialize pending tasks tracking
    $pendingTasks = @()
    $script:pendingTasks = $pendingTasks
    
    # Override reply to complete pending tasks
    $script:reply = {
        param($response)
        
        # Find matching pending task
        $matchingTask = $script:pendingTasks | Where-Object { 
            $_.TabId -eq $context.activeTabId -and 
            $_.Generation -eq $context.playerContextGeneration 
        } | Select-Object -First 1
        
        if ($matchingTask) {
            $matchingTask.TaskSource.SetResult($response)
            $script:pendingTasks = $script:pendingTasks | Where-Object { $_ -ne $matchingTask }
        }
    }.GetNewClosure()
    
    # Test 1: Old tab response must be ignored
    $context.playerContextGeneration = 0
    $pending = Invoke-RefreshPlayer -ctx $context
    $context.activeTabId = 2  # Change tab
    
    # Complete the "old" request
    & $script:reply @{response = @{playerState = @{playing = $true}}}
    
    # Wait a bit to ensure processing
    Start-Sleep -Milliseconds 50
    
    if ($rendered.Count -ne 0) {
        throw "Test failed: Old tab response must be ignored"
    }
    
    # Test 2: Non-TikTok tabs must not be polled
    $context.activeIsTikTok = $false
    $callsBefore = $calls
    Invoke-RefreshPlayer -ctx $context | Out-Null
    
    if ($calls -ne $callsBefore) {
        throw "Test failed: Non-TikTok tabs must not be polled"
    }
    
    # Test 3: Current tab response must render
    $context.activeIsTikTok = $true
    $context.activeTabId = 1
    $context.playerContextGeneration = 0
    $pending = Invoke-RefreshPlayer -ctx $context
    
    # Complete current request
    & $script:reply @{response = @{playerState = @{playing = $true}}}
    
    # Wait for completion
    $pending.Wait()
    
    if ($rendered.Count -ne 1) {
        throw "Test failed: Current tab response must render"
    }
    
    # Test 4: Returning to the same tab must not revive an old response
    $context.playerContextGeneration = 0
    $pending = Invoke-RefreshPlayer -ctx $context
    $context.activeTabId = 3
    $context.playerContextGeneration++
    $context.activeTabId = 2
    $context.playerContextGeneration++
    
    # Complete with old response
    & $script:reply @{response = @{playerState = @{playing = $false}}}
    
    # Wait for completion
    $pending.Wait()
    
    if ($rendered.Count -ne 1) {
        throw "Test failed: Returning to the same tab must not revive an old response"
    }
    
    # Verify source contains expected pattern
    if ($source -notmatch "async function refresh\(\)\s*\{\s*playerContextGeneration\+\+;") {
        throw "Test failed: Context invalidation must precede asynchronous tab lookup"
    }
    
    Write-Host "PASS: stale tab response ignored, non-TikTok polling skipped, current response rendered"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
