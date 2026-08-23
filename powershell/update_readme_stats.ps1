#!/usr/bin/env pwsh
# update_readme_stats.py — portiert nach powershell
# Quelle: python, OpenClaw@main:scripts/update_readme_stats.py
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Fetch ClawHub stats and update README.md download counts and security status.
#>

$API_BASE = "https://clawhub.ai/api/v1"
$TOKEN = $env:CLAWHUB_TOKEN

$SKILLS = @(
    @("Cluster Gateway",           "cluster-gateway"),
    @("MCP Tool Utils",            "mcp-tool-utils"),
    @("Reports Creator",           "reports-creator"),
    @("Relay Node",                "relay-node"),
    @("JSON Utils",                "json-utils"),
    @("Log Collector",             "log-collector"),
    @("TikTok Live Monitor",       "tiktok-live-monitor"),
    @("Doc Scraper",               "doc-scraper"),
    @("Workspace Database Manager","workspace-database-manager"),
    @("Scripting Utils",           "scripting-utils")
)

function Fetch-Skill($slug) {
    $url = "$API_BASE/skills/$slug"
    $headers = @{
        Accept = "application/json"
    }
    if ($TOKEN) {
        $headers.Authorization = "Bearer $TOKEN"
    }
    try {
        $response = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec 10 -UseBasicParsing
        return $response.Content | ConvertFrom-Json
    } catch {
        throw $_
    }
}

function Parse-Skill($data) {
    $skill = $data.skill
    if (-not $skill) { $skill = @{} }
    $stats = $skill.stats
    if (-not $stats) { $stats = @{} }
    $latestVersion = $data.latestVersion
    if (-not $latestVersion) { $latestVersion = @{} }
    $version = $latestVersion.version
    if (-not $version) { $version = "1.0.0" }
    $mod = $data.moderation

    $downloads = $stats.downloads
    if (-not $downloads) { $downloads = 0 }

    if ($null -eq $mod) {
        $security = "✅ Pass"
    } elseif ($mod.isMalwareBlocked) {
        $security = "🚫 Blocked"
    } else {
        $security = "🔍 Review"
    }

    return @{
        downloads = $downloads
        version   = if ($version.StartsWith("v")) { $version } else { "v$version" }
        security  = $security
    }
}

function Main() {
    $stats = @{}
    $errors = 0
    
    foreach ($item in $SKILLS) {
        $name, $slug = $item
        try {
            $data = Fetch-Skill $slug
            $s = Parse-Skill $data
            $stats[$slug] = $s
            Write-Host "  OK  $slug`: $($s.downloads) downloads, $($s.version), $($s.security)"
        } catch {
            Write-Error "  ERR $slug`: $_"
            $errors++
        }
    }

    if ($stats.Count -eq 0) {
        Write-Error "No data fetched — aborting."
        exit 1
    }

    $content = Get-Content -Path "README.md" -Raw -Encoding UTF8

    foreach ($item in $SKILLS) {
        $name, $slug = $item
        if (-not $stats.ContainsKey($slug)) {
            continue
        }
        $dl = $stats[$slug].downloads
        $pattern = "(\|\s*\[?$([regex]::Escape($name))\]?[^|]*\|[^|]*\|)\s*\d+\s*(\|)"
        $replacement = "`$1 $dl `$2"
        $new_content = [regex]::Replace($content, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($new_content -ne $content) {
            $content = $new_content
            Write-Host "  Updated: $name -> $dl"
        }
    }

    Set-Content -Path "README.md" -Value $content -Encoding UTF8
    Write-Host "Done: $($stats.Count) skills, $errors errors."
}

Main
