#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "7a5c5c6f07a6dd1581d6c78be5011f09baf8d2c75046569e5c5d0a018fd3fb08", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "powershell"}
# github_publisher.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Publish queued, provenance-checked artifacts without staging unrelated files.
#>

param()

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

$Global:LANGUAGES = @(
    "c", "cpp", "css", "fsharp", "go", "java", "javascript", "lua", "perl5",
    "perl6", "php", "powershell", "python", "ruby", "shell", "tcl"
) | Sort-Object

function Get-Sha256Hash {
    param([byte[]]$Data)
    
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($Data)
        return [BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Synchronize-Checkout {
    <#
    .SYNOPSIS
    Reconcile a remote snapshot into the checkout without changing its Git history.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        
        [string]$Remote = "https://github.com/KikiKari/OpenClaw.git",
        
        [string]$Branch = "gateway1-abstractions"
    )
    
    $rootPath = Resolve-Path $Root
    $tmpDir = New-TemporaryDirectory -Prefix "abstractions-snapshot-"
    try {
        $snapshot = Join-Path $tmpDir "repo"
        & git clone --quiet --depth=1 --single-branch --branch $Branch -- $Remote $snapshot 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone failed"
        }
        
        $revision = & git -C $snapshot rev-parse HEAD
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get revision"
        }
        $revision = $revision.Trim()
        
        $counts = @{}
        
        foreach ($language in $Global:LANGUAGES | Sort-Object) {
            $source = Join-Path $snapshot $language
            $target = Join-Path $rootPath $language
            
            if (Test-Path -LiteralPath $source -PathType Leaf) {
                throw "Language directory is a file"
            }
            
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                throw "Language directory is a file"
            }
            
            if (-not (Test-Path $target)) {
                New-Item -ItemType Directory -Path $target > $null
            }
            
            $known = @{}
            Get-ChildItem -LiteralPath $target -File | ForEach-Object {
                if ((Get-ItemProperty -LiteralPath $_.FullName).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    return
                }
                $fileContent = [System.IO.File]::ReadAllBytes($_.FullName)
                $known[(Get-Sha256Hash -Data $fileContent)] = $true
            }
            
            $files = @()
            if (Test-Path $source) {
                $files = Get-ChildItem -LiteralPath $source -File
                foreach ($item in $files) {
                    if ((Get-ItemProperty -LiteralPath $item.FullName).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                        throw "Invalid remote abstraction"
                    }
                }
            }
            
            $counts[$language] = $files.Count
            
            foreach ($item in $files) {
                $data = [System.IO.File]::ReadAllBytes($item.FullName)
                $digest = Get-Sha256Hash -Data $data
                
                if ($known.ContainsKey($digest)) {
                    continue
                }
                
                $destination = Join-Path $target $item.Name
                if (Test-Path -LiteralPath $destination -PathType Container) {
                    $destination = Join-Path $target "$($item.BaseName)__pool_$($digest)$($item.Extension)"
                } elseif (Test-Path -LiteralPath $destination) {
                    $existingData = [System.IO.File]::ReadAllBytes($destination)
                    if (-not [System.Collections.StructuralComparisons]::StructuralEqualityComparer.Equals($data, $existingData)) {
                        throw "Local abstraction conflict"
                    }
                    continue
                }
                
                [System.IO.File]::WriteAllBytes($destination, $data)
                $known[$digest] = $true
            }
        }
        
        return @{
            Revision = $revision
            Counts = $counts
        }
    }
    finally {
        if (Test-Path $tmpDir) {
            Remove-Item -Recurse -Force $tmpDir
        }
    }
}

function Update-StatusCounts {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Revision,
        
        [Parameter(Mandatory)]
        [hashtable]$Counts
    )
    
    $text = Get-Content -Path $Path -Raw -Encoding UTF8
    
    $rows = @(
        "## Bestand"
        ""
        "GitHub-Stand: `$Revision$"
        ""
        "| Zielsprache | Dateien |"
        "|---|---:|"
    )
    
    foreach ($language in $Global:LANGUAGES | Sort-Object) {
        $rows += "| $language | $($Counts[$language]) |"
    }
    
    $total = ($Counts.Values | Measure-Object -Sum).Sum
    $rows += "| **gesamt** | **$total** |"
    $rows += ""
    $rows += ""
    
    $rowsText = $rows -join "`n"
    $updated = [regex]::Replace($text, "(?ms)^## Bestand\n.*?(?=^## Quellen\n)", $rowsText)
    
    if ($text -eq $updated) {
        throw "Status inventory section missing"
    }
    
    Set-Content -Path $Path -Value $updated -Encoding UTF8
}

function Queue-Artifact {
    param(
        [Parameter(Mandatory)]
        [hashtable]$State,
        
        [Parameter(Mandatory)]
        [string]$Root,
        
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $rootPath = Resolve-Path $Root
    $resolvedPath = Resolve-Path $Path
    
    if ((Get-ItemProperty -LiteralPath $resolvedPath).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw "Artifact must not be a symlink"
    }
    
    $relative = (Resolve-Path -Relative -Path $resolvedPath -RelativeTo $rootPath).TrimStart(".\").Replace("\", "/")
    
    if ($relative -ne 'STATUS.md' -and ($relative.Split("/")[0] -notin $Global:LANGUAGES)) {
        throw "Artifact is outside a language directory"
    }
    
    if (-not $State.ContainsKey("ausstehende_veroeffentlichungen")) {
        $State["ausstehende_veroeffentlichungen"] = @{}
    }
    
    $content = [System.IO.File]::ReadAllBytes($resolvedPath)
    $State["ausstehende_veroeffentlichungen"][$relative] = Get-Sha256Hash -Data $content
}

function Publish-Pending {
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        
        [Parameter(Mandatory)]
        [hashtable]$State,
        
        [Parameter(Mandatory)]
        [scriptblock]$Save,
        
        [string]$Token,
        
        [scriptblock]$Sync
    )
    
    $pending = $State["ausstehende_veroeffentlichungen"]
    if ($null -eq $pending) {
        $pending = @{}
    }
    
    if ($pending.GetType().Name -ne "Hashtable") {
        throw "Invalid publication queue"
    }
    
    if (($pending.Count -eq 0) -and ($null -eq $Sync)) {
        return $true
    }
    
    if ([string]::IsNullOrWhiteSpace($Token)) {
        return $false
    }
    
    $rootPath = Resolve-Path $Root
    
    $headers = @{
        Authorization = "Bearer $($Token.Trim())"
        Accept = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent" = "abstractions-manager"
    }
    
    $success = $true
    
    $entries = $pending.GetEnumerator() | Sort-Object { if ($_.Key -eq 'STATUS.md') { 0 } else { 1 } }, Key
    
    $synced = $false
    
    foreach ($entry in $entries) {
        $name = $entry.Key
        $expected = $entry.Value
        
        try {
            $path = Join-Path $rootPath $name
            
            if ((Test-Path -LiteralPath $path -PathType Container) -or 
                (Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                throw "Invalid queued path"
            }
            
            $resolvedPath = Resolve-Path -LiteralPath $path
            $relativePath = (Resolve-Path -Relative -Path $resolvedPath -RelativeTo $rootPath).TrimStart(".\").Replace("\", "/")
            
            if ($relativePath -ne $name) {
                throw "Invalid queued path"
            }
            
            $data = [System.IO.File]::ReadAllBytes($path)
            if ((Get-Sha256Hash -Data $data) -ne $expected) {
                throw "Queued artifact changed"
            }
            
            if ($name -eq 'STATUS.md' -and $null -ne $Sync) {
                if (-not $success) {
                    throw "Artifact publication incomplete"
                }
                
                $syncResult = & $Sync $rootPath
                $revision = $syncResult.Revision
                $counts = $syncResult.Counts
                $synced = $true
                
                Update-StatusCounts -Path $path -Revision $revision -Counts $counts
                $data = [System.IO.File]::ReadAllBytes($path)
                $expected = Get-Sha256Hash -Data $data
                $pending[$name] = $expected
                & $Save $State
            }
            
            function Lookup-RemoteFile {
                param([string]$RemoteName)
                
                $endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/$([uri]::EscapeDataString($RemoteName))"
                $requestParams = @{
                    Uri = "$endpoint?ref=gateway1-abstractions"
                    Headers = $headers
                    Method = "GET"
                    UseBasicParsing = $true
                }
                
                try {
                    $response = Invoke-WebRequest @requestParams -TimeoutSec 60
                    $content = $response.Content | ConvertFrom-Json
                    return @{ Endpoint = $endpoint; Content = $content }
                }
                catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        return @{ Endpoint = $endpoint; Content = $null }
                    }
                    throw
                }
            }
            
            function Test-SameContent {
                param($Existing, [byte[]]$Data)
                
                return ($null -ne $Existing -and 
                        $Existing.encoding -eq "base64" -and
                        [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Existing.content)) -eq [System.Text.Encoding]::UTF8.GetString($Data))
            }
            
            $lookupResult = Lookup-RemoteFile -RemoteName $name
            $endpoint = $lookupResult.Endpoint
            $existing = $lookupResult.Content
            
            if ($name -eq 'STATUS.md' -and $null -ne $existing -and -not (Test-SameContent -Existing $existing -Data $data)) {
                $sha = $existing.sha
                if ([string]::IsNullOrWhiteSpace($sha)) {
                    throw "Missing remote status version"
                }
                
                $body = @{
                    message = "Update abstraction status"
                    branch = "gateway1-abstractions"
                    content = [Convert]::ToBase64String($data)
                    sha = $sha
                } | ConvertTo-Json -Compress
                
                $requestParams = @{
                    Uri = $endpoint
                    Headers = $headers
                    Method = "PUT"
                    Body = $body
                    UseBasicParsing = $true
                }
                
                $response = Invoke-WebRequest @requestParams -TimeoutSec 60
                $content = $response.Content | ConvertFrom-Json
            }
            elseif ($null -ne $existing -and -not (Test-SameContent -Existing $existing -Data $data)) {
                $candidate = [System.IO.Path]::GetDirectoryName($name)
                if ([string]::IsNullOrEmpty($candidate)) {
                    $candidate = "."
                }
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($name)
                $extension = [System.IO.Path]::GetExtension($name)
                $alternate = Join-Path $candidate "$fileName_$($expected.Substring(0, 12))$extension" -Resolve
                
                $lookupResult = Lookup-RemoteFile -RemoteName $alternate
                $existing = $lookupResult.Content
                
                if ($null -ne $existing -and -not (Test-SameContent -Existing $existing -Data $data)) {
                    throw "Remote artifact conflict"
                }
            }
            
            if ($null -eq $existing) {
                $body = @{
                    message = "Publish script abstraction"
                    branch = "gateway1-abstractions"
                    content = [Convert]::ToBase64String($data)
                } | ConvertTo-Json -Compress
                
                $requestParams = @{
                    Uri = $endpoint
                    Headers = $headers
                    Method = "PUT"
                    Body = $body
                    UseBasicParsing = $true
                }
                
                $response = Invoke-WebRequest @requestParams -TimeoutSec 60
                $content = $response.Content | ConvertFrom-Json
            }
            
            $pending.Remove($name)
            & $Save $State
        }
        catch {
            $success = $false
        }
    }
    
    if ($null -ne $Sync -and -not $synced) {
        try {
            & $Sync $rootPath
        }
        catch {
            $success = $false
        }
    }
    
    return $success
}

function New-TemporaryDirectory {
    param([string]$Prefix = "tmp")
    
    $tempPath = [System.IO.Path]::GetRandomFileName()
    $tempDir = Join-Path $env:TEMP "$Prefix$tempPath"
    New-Item -ItemType Directory -Path $tempDir > $null
    return $tempDir
}
