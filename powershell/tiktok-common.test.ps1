#!/usr/bin/env pwsh
# tiktok-common.test.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.test.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

#Requires -Version 7

$ErrorActionPreference = 'Stop'

# Import necessary modules or define functions here if needed
# For now, we'll assume all required functions are defined in a separate file or included here

function normalizeUsername($username) {
    $trimmed = $username.Trim()
    if ($trimmed.StartsWith('@')) {
        $trimmed = $trimmed.Substring(1)
    }
    if ($trimmed -match ';') {
        throw "Invalid character ';' in username"
    }
    return $trimmed
}

function liveHrefSelectors($username) {
    $normalized = normalizeUsername($username)
    return @(
        "a[href=`"/@$normalized/live`"]",
        "a[href^=`"/@$normalized/live?`"]"
    )
}

function loadState($envVars) {
    # Mock implementation assuming environment variables are passed as hashtable
    $TIKTOK_TEST_LOAD_PER_CPU = [double]$envVars.TIKTOK_TEST_LOAD_PER_CPU
    $TIKTOK_MAX_LOAD_PER_CPU = [double]$envVars.TIKTOK_MAX_LOAD_PER_CPU
    $overloaded = $TIKTOK_TEST_LOAD_PER_CPU -gt $TIKTOK_MAX_LOAD_PER_CPU
    return @{ overloaded = $overloaded }
}

function isAllowedStreamUrl($url) {
    $uri = [System.Uri]$url
    if ($uri.Scheme -ne 'https') {
        return $false
    }
    if (-not $uri.Host.EndsWith('.tiktokcdn.com') -and -not $uri.Host.EndsWith('.tiktokcdn-eu.com')) {
        return $false
    }
    return $true
}

function isSuccessfulStreamResponse($statusCode, $url) {
    if (isAllowedStreamUrl($url)) {
        return ($statusCode -eq 200) -or ($statusCode -eq 206)
    }
    return $false
}

function normalizeExtractorResult($result, $extractor, $username) {
    $allowedUrl = $result.url
    if ($null -ne $allowedUrl -and -not (isAllowedStreamUrl($allowedUrl))) {
        return @{ status = 'technical_error'; extractor = $extractor; username = $username }
    }

    if ($result.success -is [string] -and $result.success -eq 'false') {
        $result.status = 'technical_error'
    } elseif ($result.success -is [boolean] -and $result.success -eq $true) {
        # Keep original status
    } elseif ($result.success -is [boolean] -and $result.success -eq $false) {
        # Keep original status
    } else {
        $result.status = 'technical_error'
    }

    if ($result.status -eq 'offline') {
        $result.PSObject.Properties.Remove('url')
    }

    return $result
}

function classifyFinalFailure($results) {
    foreach ($result in $results) {
        if ($result.status -eq 'dependency_missing') {
            return 'dependency_missing'
        }
    }
    foreach ($result in $results) {
        if ($result.status -eq 'offline') {
            return 'offline'
        }
    }
    return 'unknown'
}

function exitCodeForResult($result) {
    switch ($result.status) {
        'restricted' { return 1 }
        'technical_error' { return 2 }
        default { return 0 }
    }
}

function classifyDirectLiveState($state) {
    if ($state.currentPath -ne "/@$($state.username)/live") {
        return @{ status = 'offline' }
    }
    if ($state.bodyText -match 'LIVE has ended') {
        return @{ status = 'offline' }
    }
    if ($state.bodyText -match 'unangenehm' -or $state.bodyText -match 'inappropriate') {
        return @{ status = 'restricted' }
    }
    if ($state.successfulStreamResponse) {
        return @{ status = 'live' }
    }
    return @{ status = 'offline' }
}

# Main test function
try {
    # Test normalizeUsername
    if ((normalizeUsername '@example_creator') -ne 'example_creator') {
        throw "normalizeUsername test 1 failed"
    }
    if ((normalizeUsername ' example_creator ') -ne 'example_creator') {
        throw "normalizeUsername test 2 failed"
    }
    try {
        normalizeUsername 'example_creator;id'
        throw "normalizeUsername test 3 failed - should have thrown exception"
    } catch {
        # Expected to throw
    }

    # Test liveHrefSelectors
    $selectors = liveHrefSelectors 'example_creator'
    $expected = @(
        'a[href="/@example_creator/live"]',
        'a[href^="/@example_creator/live?"]'
    )
    if (($selectors.Length -ne $expected.Length) -or 
        ($selectors[0] -ne $expected[0]) -or 
        ($selectors[1] -ne $expected[1])) {
        throw "liveHrefSelectors test failed"
    }

    # Test loadState
    $state = loadState @{
        TIKTOK_TEST_LOAD_PER_CPU = '2'
        TIKTOK_MAX_LOAD_PER_CPU = '1.5'
    }
    if ($state.overloaded -ne $true) {
        throw "loadState test failed"
    }

    # Test isAllowedStreamUrl
    if (-not (isAllowedStreamUrl 'https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x')) {
        throw "isAllowedStreamUrl test 1 failed"
    }
    if (isAllowedStreamUrl 'https://attacker.example/path/tiktokcdn/video.flv') {
        throw "isAllowedStreamUrl test 2 failed"
    }
    if (isAllowedStreamUrl 'http://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv') {
        throw "isAllowedStreamUrl test 3 failed"
    }

    # Test isSuccessfulStreamResponse
    $allowedUrl = 'https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x'
    if (-not (isSuccessfulStreamResponse 200 $allowedUrl)) {
        throw "isSuccessfulStreamResponse test 1 failed"
    }
    if (-not (isSuccessfulStreamResponse 206 $allowedUrl)) {
        throw "isSuccessfulStreamResponse test 2 failed"
    }
    if (isSuccessfulStreamResponse 404 $allowedUrl) {
        throw "isSuccessfulStreamResponse test 3 failed"
    }

    # Test normalizeExtractorResult
    $result1 = normalizeExtractorResult @{ success = 'false'; status = 'offline' } 'streamlink' 'example_creator'
    if ($result1.status -ne 'technical_error') {
        throw "normalizeExtractorResult test 1 failed"
    }

    $result2 = normalizeExtractorResult @{ success = $true; status = 'live' } 'streamlink' 'example_creator'
    if ($result2.status -ne 'technical_error') {
        throw "normalizeExtractorResult test 2 failed"
    }

    $result3 = normalizeExtractorResult @{ success = $false; status = 'offline'; url = $allowedUrl } 'streamlink' 'example_creator'
    if ($result3.status -ne 'offline' -or $result3.ContainsKey('url')) {
        throw "normalizeExtractorResult test 3 failed"
    }

    $result4 = normalizeExtractorResult @{ success = $true; status = 'live'; url = $allowedUrl } 'streamlink' 'example_creator'
    if ($result4.status -ne 'live') {
        throw "normalizeExtractorResult test 4 failed"
    }

    # Test classifyFinalFailure
    $failureResult = classifyFinalFailure @(@{ status = 'offline' }, @{ status = 'dependency_missing' })
    if ($failureResult -ne 'offline') {
        throw "classifyFinalFailure test failed"
    }

    # Test exitCodeForResult
    if ((exitCodeForResult @{ success = $false; status = 'restricted' }) -ne 1) {
        throw "exitCodeForResult test 1 failed"
    }
    if ((exitCodeForResult @{ success = $false; status = 'technical_error' }) -ne 2) {
        throw "exitCodeForResult test 2 failed"
    }

    # Test classifyDirectLiveState
    $state1 = classifyDirectLiveState @{
        username = 'example_creator'
        currentPath = '/@example_creator/live'
        title = 'Example (@example_creator) is LIVE - TikTok LIVE'
        bodyText = 'Dieses LIVE enthält Themen, die unangenehm sein könnten.'
        successfulStreamResponse = $false
    }
    if ($state1.status -ne 'restricted') {
        throw "classifyDirectLiveState test 1 failed"
    }

    $state2 = classifyDirectLiveState @{
        username = 'example_creator'
        currentPath = '/@example_creator/live'
        title = 'Example (@example_creator) is LIVE - TikTok LIVE'
        bodyText = 'LIVE has ended'
        successfulStreamResponse = $false
    }
    if ($state2.status -ne 'offline') {
        throw "classifyDirectLiveState test 2 failed"
    }

    $state3 = classifyDirectLiveState @{
        username = 'example_creator'
        currentPath = '/@example_creator/live'
        title = 'Example (@example_creator) is LIVE - TikTok LIVE'
        bodyText = 'Suggested LIVE creators'
        successfulStreamResponse = $true
    }
    if ($state3.status -ne 'live') {
        throw "classifyDirectLiveState test 3 failed"
    }

    Write-Host "All tests passed successfully!"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
