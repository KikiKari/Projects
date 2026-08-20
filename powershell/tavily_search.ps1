#!/usr/bin/env pwsh
# tavily_search.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/tavily/scripts/tavily_search.py
# auch in: OpenClaw@gateway2:skills/tavily/scripts/tavily_search.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Tavily AI Search - Optimized search for LLMs and AI applications
.DESCRIPTION
Requires: Install-Module -Name TavilyClient -Scope CurrentUser
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [string]$ApiKey,
    
    [ValidateSet("basic", "advanced")]
    [string]$Depth = "basic",
    
    [ValidateSet("general", "news")]
    [string]$Topic = "general",
    
    [int]$MaxResults = 5,
    
    [switch]$NoAnswer,
    
    [switch]$RawContent,
    
    [switch]$Images,
    
    [string[]]$IncludeDomains,
    
    [string[]]$ExcludeDomains,
    
    [switch]$Json
)

function Search-Tavily {
    param(
        [string]$Query,
        [string]$ApiKey,
        [string]$SearchDepth = "basic",
        [string]$Topic = "general",
        [int]$MaxResults = 5,
        [bool]$IncludeAnswer = $true,
        [bool]$IncludeRawContent = $false,
        [bool]$IncludeImages = $false,
        [string[]]$IncludeDomains,
        [string[]]$ExcludeDomains
    )
    
    try {
        # Check if module exists
        if (-not (Get-Module -ListAvailable -Name TavilyClient)) {
            return @{
                error = "TavilyClient PowerShell module not installed. Run: Install-Module -Name TavilyClient -Scope CurrentUser"
                install_command = "Install-Module -Name TavilyClient -Scope CurrentUser"
            }
        }
        
        if ([string]::IsNullOrWhiteSpace($ApiKey)) {
            return @{
                error = "Tavily API key required. Get one at https://tavily.com"
                setup_instructions = "Set TAVILY_API_KEY environment variable or pass -ApiKey parameter"
            }
        }
        
        Import-Module TavilyClient
        
        $client = New-TavilyClient -ApiKey $ApiKey
        
        # Build search parameters
        $searchParams = @{
            Query = $Query
            SearchDepth = $SearchDepth
            Topic = $Topic
            MaxResults = $MaxResults
            IncludeAnswer = $IncludeAnswer
            IncludeRawContent = $IncludeRawContent
            IncludeImages = $IncludeImages
        }
        
        if ($IncludeDomains) {
            $searchParams.IncludeDomains = $IncludeDomains
        }
        
        if ($ExcludeDomains) {
            $searchParams.ExcludeDomains = $ExcludeDomains
        }
        
        $response = Invoke-TavilySearch @searchParams
        
        return @{
            success = $true
            query = $Query
            answer = $response.answer
            results = $response.results
            images = $response.images
            response_time = $response.response_time
            usage = $response.usage
        }
    }
    catch {
        return @{
            error = $_.Exception.Message
            query = $Query
        }
    }
}

# Main execution
try {
    # Get API key from parameter or environment
    if (-not $ApiKey) {
        $ApiKey = $env:TAVILY_API_KEY
    }
    
    $result = Search-Tavily `
        -Query $Query `
        -ApiKey $ApiKey `
        -SearchDepth $Depth `
        -Topic $Topic `
        -MaxResults $MaxResults `
        -IncludeAnswer (-not $NoAnswer) `
        -IncludeRawContent $RawContent `
        -IncludeImages $Images `
        -IncludeDomains $IncludeDomains `
        -ExcludeDomains $ExcludeDomains
    
    if ($Json) {
        $result | ConvertTo-Json -Depth 5
    }
    else {
        if ($result.ContainsKey("error")) {
            Write-Error "Error: $($result.error)"
            if ($result.ContainsKey("install_command")) {
                Write-Error "`nTo install: $($result.install_command)"
            }
            if ($result.ContainsKey("setup_instructions")) {
                Write-Error "`nSetup: $($result.setup_instructions)"
            }
            exit 1
        }
        
        # Format human-readable output
        Write-Output "Query: $($result.query)"
        Write-Output "Response time: $(if ($result.response_time) { "$($result.response_time)s" } else { "N/A" })"
        Write-Output "Credits used: $(if ($result.usage -and $result.usage.credits) { $result.usage.credits } else { "N/A" })`n"
        
        if ($result.answer) {
            Write-Output "=== AI ANSWER ==="
            Write-Output $result.answer
            Write-Output ""
        }
        
        if ($result.results) {
            Write-Output "=== RESULTS ==="
            for ($i = 0; $i -lt $result.results.Count; $i++) {
                $item = $result.results[$i]
                Write-Output "`n$($i+1). $(if ($item.title) { $item.title } else { "No title" })"
                Write-Output "   URL: $(if ($item.url) { $item.url } else { "N/A" })"
                Write-Output "   Score: $(if ($item.score) { "{0:F3}" -f $item.score } else { "N/A" })"
                if ($item.content) {
                    $content = $item.content
                    if ($content.Length -gt 200) {
                        $content = $content.Substring(0, 200) + "..."
                    }
                    Write-Output "   $content"
                }
            }
        }
        
        if ($result.images) {
            Write-Output "`n=== IMAGES ($($result.images.Count)) ==="
            $imageCount = [Math]::Min(5, $result.images.Count)
            for ($i = 0; $i -lt $imageCount; $i++) {
                Write-Output "   $($result.images[$i])"
            }
        }
    }
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    exit 1
}
