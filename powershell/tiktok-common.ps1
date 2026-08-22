#!/usr/bin/env pwsh
# tiktok-common.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Shared TikTok LIVE safety contract: handle normalization, per-CPU load
preflight, exact account LIVE selectors, strict HTTPS TikTok-CDN FLV
validation, and normalized extractor statuses.
#>

$DEFAULT_MAX_LOAD_PER_CPU = 1.5
$USERNAME_PATTERN = '^[A-Za-z0-9._]{1,24}$'
$FAILURE_STATUSES = @(
    'offline',
    'restricted',
    'overloaded',
    'dependency_missing',
    'technical_error'
)

function NormalizeUsername {
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Raw
    )
    
    $username = if ($null -eq $Raw) { '' } else { $Raw.ToString().Trim() -replace '^@+', '' }
    if ($username -notmatch $USERNAME_PATTERN) {
        throw [System.ArgumentException]::new('Invalid TikTok username; expected 1-24 letters, digits, dots, or underscores')
    }
    return $username
}

function LoadState {
    param(
        [hashtable]$EnvVars = $env:PSDefaultParameterValues.ContainsKey('env') ? $env:PSDefaultParameterValues['env'] : [System.Environment]::GetEnvironmentVariables()
    )
    
    $cpuCount = [Math]::Max(1, (Get-CimInstance Win32_Processor | Measure-Object).Count)
    $observed = if ($null -eq $EnvVars['TIKTOK_TEST_LOAD_PER_CPU']) {
        # Note: PowerShell doesn't have direct equivalent of os.loadavg(), using WMI as approximation
        $loadAvg = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average / 100
        $loadAvg / $cpuCount
    } else {
        [double]$EnvVars['TIKTOK_TEST_LOAD_PER_CPU']
    }
    $maximum = if ($null -eq $EnvVars['TIKTOK_MAX_LOAD_PER_CPU']) {
        $DEFAULT_MAX_LOAD_PER_CPU
    } else {
        [double]$EnvVars['TIKTOK_MAX_LOAD_PER_CPU']
    }
    if (-not [double]::IsFinite($observed) -or -not [double]::IsFinite($maximum) -or $maximum -le 0) {
        throw [System.ArgumentException]::new('Invalid TikTok load configuration')
    }
    return @{
        Overloaded = $observed -gt $maximum
        LoadPerCpu = $observed
        Maximum = $maximum
    }
}

function EnforceLoadLimit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method
    )
    
    $state = LoadState
    if (-not $state.Overloaded) { return $state }
    $output = @{
        status = 'overloaded'
        method = $Method
        loadPerCpu = [Math]::Round($state.LoadPerCpu, 3)
        maximum = $state.Maximum
        message = 'Host is overloaded; retry on another node or later'
    } | ConvertTo-Json -Compress
    [Console]::Error.WriteLine($output)
    exit 75
}

function LiveHrefSelectors {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    
    $href = "/@$Username/live"
    return @("a[href=`"$href`"]", "a[href^=`"$href?`"]")
}

function IsAllowedStreamUrl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Value
    )
    
    try {
        $url = [System.Uri]$Value
        $hostname = $url.Host.ToLower()
        return $url.Scheme -eq 'https' -and 
               $url.LocalPath.ToLower().Contains('.flv') -and
               $hostname -match '(^|\.)tiktokcdn(-[a-z0-9-]+)?\.com$'
    } catch {
        return $false
    }
}

function IsSuccessfulStreamResponse {
    param(
        [int]$Status,
        [string]$Value
    )
    
    return [int]::IsInteger($Status) -and
           $Status -ge 200 -and
           $Status -lt 300 -and
           (IsAllowedStreamUrl -Value $Value)
}

# Order matters: longer keys first so `_uhd_60` never matches as `hd_60`/`hd`.
$QUALITY_URL_PATTERN = '_((uhd_60)|(hd_60)|(origin)|(hd)|(sd)|(ld)|(ao))\.(flv|m3u8)'

function QualityKeyFromUrl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Value
    )
    
    try {
        $uri = [System.Uri]$Value
        $match = [regex]::Match($uri.LocalPath.ToLower(), $QUALITY_URL_PATTERN)
        return if ($match.Success) { $match.Groups[1].Value } else { $null }
    } catch {
        return $null
    }
}

function NormalizeExtractorResult {
    param(
        [Parameter(Mandatory=$true)]
        $Value,
        [Parameter(Mandatory=$true)]
        [string]$Method,
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    
    $technicalError = @{
        success = $false
        status = 'technical_error'
        method = $Method
        username = $Username
        message = 'invalid extractor result'
    }
    
    if ($null -eq $Value -or $Value.GetType().Name -ne 'PSCustomObject' -or $Value -is [array]) {
        return $technicalError
    }
    
    if ($Value.success -eq $true) {
        if ($Value.status -ne 'live' -or -not (IsAllowedStreamUrl -Value $Value.url)) {
            return $technicalError
        }
        return $Value | Add-Member -NotePropertyName success -NotePropertyValue $true -PassThru |
                      Add-Member -NotePropertyName status -NotePropertyValue 'live' -PassThru
    }
    
    if ($Value.success -ne $false) {
        return $technicalError
    }
    
    $result = $Value.PSObject.Copy()
    $result | Add-Member -NotePropertyName success -NotePropertyValue $false -Force
    
    if ($FAILURE_STATUSES -contains $Value.status) {
        $result | Add-Member -NotePropertyName status -NotePropertyValue $Value.status -Force
    } else {
        $result | Add-Member -NotePropertyName status -NotePropertyValue 'technical_error' -Force
    }
    
    $resultMethod = if ($Value.method -is [string]) { $Value.method } else { $Method }
    $resultUsername = if ($Value.username -is [string]) { $Value.username } else { $Username }
    $result | Add-Member -NotePropertyName method -NotePropertyValue $resultMethod -Force
    $result | Add-Member -NotePropertyName username -NotePropertyValue $resultUsername -Force
    
    $result.PSObject.Properties.Remove('url')
    $result.PSObject.Properties.Remove('streams')
    $result.PSObject.Properties.Remove('allUrls')
    
    return $result
}

function ClassifyFinalFailure {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    $statuses = @()
    foreach ($result in $Results) {
        if ($null -ne $result -and $null -ne $result.status -and $FAILURE_STATUSES -contains $result.status) {
            $statuses += $result.status
        }
    }
    $statusSet = $statuses | Sort-Object -Unique
    
    if ($statusSet -contains 'overloaded') { return 'overloaded' }
    if ($statusSet -contains 'restricted') { return 'restricted' }
    if ($statusSet -contains 'technical_error') { return 'technical_error' }
    if ($statusSet -contains 'offline') { return 'offline' }
    if ($statusSet -contains 'dependency_missing') { return 'dependency_missing' }
    return 'technical_error'
}

function ExitCodeForResult {
    param(
        [Parameter(Mandatory=$true)]
        $Result
    )
    
    if ($null -ne $Result -and $Result.success -eq $true -and $Result.status -eq 'live') { return 0 }
    if ($null -ne $Result -and $Result.status -eq 'overloaded') { return 75 }
    if ($null -ne $Result -and @('offline', 'restricted').Contains($Result.status)) { return 1 }
    return 2
}

function ClassifyDirectLiveState {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )
    
    $username = $Params.username
    $currentPath = $Params.currentPath
    $title = $Params.title
    $bodyText = $Params.bodyText
    $successfulStreamResponse = $Params.successfulStreamResponse
    
    $expectedPath = "/@$username/live"
    if ($currentPath -ne $expectedPath) {
        return @{ status = 'offline'; reason = 'target live page redirected' }
    }
    if ($successfulStreamResponse) {
        return @{ status = 'live'; reason = 'successful TikTok CDN stream response' }
    }

    $normalizedBody = if ($null -eq $bodyText) { '' } else { ($bodyText -replace '\s+', ' ').ToLower() }
    $normalizedTitle = if ($null -eq $title) { '' } else { $title.ToLower() }
    $accountLiveTitle = $normalizedTitle.Contains("(@$($username.ToLower())) is live")
    
    $endedMarkers = @(
        'live has ended',
        'das live ist beendet',
        'live wurde beendet',
        'dieses live ist beendet',
        'stream has ended'
    )
    foreach ($marker in $endedMarkers) {
        if ($normalizedBody.Contains($marker)) {
            return @{ status = 'offline'; reason = 'target live page reports ended stream' }
        }
    }

    $restrictionMarkers = @(
        'dieses live enthält themen, die von einigen als unangenehm empfunden werden könnten',
        'melde dich an, um das beste aus deiner tiktok-erfahrung herauszuholen',
        'bei tiktok anmelden',
        'melde dich an für das volle live-erlebnis',
        'melde dich an für das vollständige erlebnis',
        'this live may contain content that could be uncomfortable',
        'log in to tiktok',
        'log in for the full live experience',
        'mature content',
        'age-restricted',
        'viewer discretion'
    )
    
    if ($accountLiveTitle) {
        foreach ($marker in $restrictionMarkers) {
            if ($normalizedBody.Contains($marker)) {
                return @{ status = 'restricted'; reason = 'target live page requires authentication' }
            }
        }
        return @{ 
            status = 'restricted'
            reason = 'target is live but no accessible media response was available'
        }
    }
    
    return @{ status = 'offline'; reason = 'no account-specific live signal' }
}

function ForcedOffline {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    
    if ([System.Environment]::GetEnvironmentVariable('TIKTOK_TEST_OFFLINE') -ne '1') { return $false }
    $output = @{
        success = $false
        status = 'offline'
        method = $Method
        username = $Username
        message = 'forced offline test mode'
    } | ConvertTo-Json -Compress
    [Console]::Error.WriteLine($output)
    return $true
}

Export-ModuleMember -Function @(
    'ClassifyDirectLiveState',
    'ClassifyFinalFailure',
    'EnforceLoadLimit',
    'ExitCodeForResult',
    'ForcedOffline',
    'IsAllowedStreamUrl',
    'IsSuccessfulStreamResponse',
    'LiveHrefSelectors',
    'LoadState',
    'NormalizeExtractorResult',
    'NormalizeUsername',
    'QualityKeyFromUrl'
)
