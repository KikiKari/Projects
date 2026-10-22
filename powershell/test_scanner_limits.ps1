#!/usr/bin/env pwsh
# test_scanner_limits.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_scanner_limits.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Resolve-Path "$PSScriptRoot/.."
$sources = @(
    @("browser-extension/content.js", "  function explicitCardSummary", $true),
    @("mobile-shared/webview-bridge.js", "  function primaryVideo", $false)
)

function structuredClone($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj.GetType().Name -eq "String") { return $obj }
    if ($obj.GetType().Name -eq "Int32") { return $obj }
    if ($obj.GetType().Name -eq "Boolean") { return $obj }
    
    $clone = @{}
    foreach ($prop in $obj.PSObject.Properties) {
        $clone[$prop.Name] = structuredClone($prop.Value)
    }
    return $clone
}

foreach ($source in $sources) {
    $file = $source[0]
    $end = $source[1]
    $browser = $source[2]
    
    $sourcePath = Join-Path $root $file
    $content = Get-Content -Path $sourcePath -Raw
    
    $startIndex = $content.IndexOf("  async function scanRecommendations(run)")
    $endIndex = $content.IndexOf($end, $startIndex)
    $code = $content.Substring($startIndex, $endIndex - $startIndex)
    
    if ($code.Length -le 100) {
        throw "Code length check failed"
    }
    
    foreach ($n in @(1, 50, 51, 299, 300, 301)) {
        $updates = @()
        $cards = @(1..301 | ForEach-Object { 
            @{ 
                handle = "creator$($_ - 1)"
                card = @{ 
                    scrollIntoView = { }
                    dispatchEvent = { }
                }
            }
        })
        
        $run = @{
            limit = [Math]::Min($n, 300)
            sourceUrl = "https://www.tiktok.com/@creator/live"
            runId = "test"
            cancelled = $false
        }
        
        $context = @{
            root = @{}
            scrollX = 0
            scrollY = 0
            innerHeight = 800
            location = @{ href = $run.sourceUrl }
            Date = [DateTime]
            MouseEvent = [System.Management.Automation.PSCustomObject]
            setTimeout = { param($fn) & $fn; return 1 }
            window = @{
                scrollX = 0
                scrollY = 0
                innerHeight = 800
                scrollTo = { }
                scrollBy = { }
            }
            scrollTo = { }
            scrollBy = { }
            activeRecommendationScan = $run
            RECOMMENDATION_SCAN_MAX_ROUNDS = 12
            RECOMMENDATION_SCAN_MAX_MS = 45000
            core = (Get-Content -Path (Join-Path $root "browser-extension/content-core.js") -Raw)
            recommendationCards = { return $cards }
            recommendationItem = { 
                param($e, $p) 
                return @{ 
                    handle = $e.handle
                    position = $p
                    title = "x" * 300
                }
            }
            text = { param($str) return $str.ToString() }
            emit = { 
                param($type, $p) 
                $updates += ,(structuredClone($p))
            }
            emitRecommendationProgress = { 
                param($r, $status, $items) 
                $updates += ,(structuredClone(@{ status = $status; items = $items }))
            }
        }
        
        # Execute the JavaScript code in PowerShell context
        # This is a simplified execution - actual JS VM emulation would be complex
        Invoke-Expression $code
        
        # Call scanRecommendations with the run object
        & $context.scanRecommendations($run)
        
        $lastUpdate = $updates[-1]
        if ($lastUpdate.status -ne "complete") {
            throw "Expected status 'complete', got '$($lastUpdate.status)'"
        }
        
        if ($lastUpdate.items.Count -ne [Math]::Min($n, 300)) {
            throw "Expected items count $([Math]::Min($n, 300)), got $($lastUpdate.items.Count)"
        }
        
        $lastItemPosition = $lastUpdate.items[-1].position
        if ($lastItemPosition -ne [Math]::Min($n, 300)) {
            throw "Expected last item position $([Math]::Min($n, 300)), got $lastItemPosition"
        }
    }
    
    Write-Host "PASS synthetic production scan loop: $file; 1,50,51,299,300,301"
}
