#!/usr/bin/env pwsh
# github_publisher.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Publish queued, provenance-checked artifacts without staging unrelated files.
#>

function Queue-Artifact {
    param(
        [hashtable]$State,
        [string]$Root,
        [string]$Path
    )

    $rootPath = (Resolve-Path $Root).Path
    $artifactPath = Resolve-Path $Path -ErrorAction Stop
    
    if (Test-Path $artifactPath -PathType Leaf) {
        $item = Get-Item $artifactPath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "artifact must not be a symlink"
        }
    }

    $relativePath = Resolve-Path $Path -Relative -ErrorAction Stop
    $relativePath = $relativePath -replace '^\.\\', ''
    
    $parts = $relativePath -split '[\\/]'
    if (-not $parts[0] -or $parts[0] -notin @("perl5", "powershell", "perl6", "tcl", "javascript", "ruby", "python", "lua", "shell", "go")) {
        throw "artifact is outside a language directory"
    }

    $content = [System.IO.File]::ReadAllBytes($artifactPath)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($content)
    $hexHash = ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
    
    if (-not $State.ContainsKey("ausstehende_veroeffentlichungen")) {
        $State["ausstehende_veroeffentlichungen"] = @{}
    }
    
    $State["ausstehende_veroeffentlichungen"][$relativePath] = $hexHash
}

function Publish-Pending {
    param(
        [string]$Root,
        [hashtable]$State,
        [scriptblock]$Save,
        [string]$Token,
        [System.Net.Http.HttpClient]$HttpClient = $null
    )

    $pending = $State["ausstehende_veroeffentlichungen"]
    if ($null -eq $pending) { $pending = @{} }
    
    if ($pending.GetType().Name -ne "Hashtable") {
        throw "invalid publication queue"
    }
    
    if ($pending.Count -eq 0) {
        return $true
    }
    
    if ([string]::IsNullOrWhiteSpace($Token)) {
        return $false
    }
    
    $rootPath = (Resolve-Path $Root).Path
    $headers = @{
        "Authorization" = "Bearer $($Token.Trim())"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent" = "abstractions-manager"
    }
    
    $success = $true
    
    $pendingClone = @{}
    foreach ($key in $pending.Keys) {
        $pendingClone[$key] = $pending[$key]
    }
    
    foreach ($entry in $pendingClone.GetEnumerator()) {
        $name = $entry.Key
        $expected = $entry.Value
        
        try {
            $localPath = Join-Path $rootPath $name
            
            if (Test-Path $localPath -PathType Leaf) {
                $item = Get-Item $localPath
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    throw "invalid queued path"
                }
            }
            
            $resolvedPath = Resolve-Path $localPath -ErrorAction Stop
            $relativeCheck = Resolve-Path $localPath -Relative -ErrorAction Stop
            $relativeCheck = $relativeCheck -replace '^\.\\', ''
            
            if ($relativeCheck -ne $name) {
                throw "invalid queued path"
            }
            
            $data = [System.IO.File]::ReadAllBytes($localPath)
            $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($data)
            $actualHash = ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
            
            if ($actualHash -ne $expected) {
                throw "queued artifact changed"
            }
            
            function Lookup-RemoteContent {
                param([string]$RemoteName)
                
                $endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/$([System.Uri]::EscapeDataString($RemoteName))?ref=gateway1-abstractions"
                $request = [System.Net.WebRequest]::Create($endpoint)
                $request.Method = "GET"
                $request.Headers["Authorization"] = $headers.Authorization
                $request.Headers["Accept"] = $headers.Accept
                $request.Headers["X-GitHub-Api-Version"] = $headers."X-GitHub-Api-Version"
                $request.UserAgent = $headers."User-Agent"
                $request.Timeout = 60000
                
                try {
                    $response = $request.GetResponse()
                    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                    $content = $reader.ReadToEnd()
                    $reader.Close()
                    $response.Close()
                    return @{ Endpoint = $endpoint; Content = $content }
                }
                catch [System.Net.WebException] {
                    $webEx = $_.Exception
                    if ($webEx.Response.StatusCode -eq 404) {
                        $webEx.Response.Close()
                        return @{ Endpoint = $endpoint; Content = $null }
                    }
                    throw
                }
            }
            
            function Test-SameContent {
                param([object]$Existing, [byte[]]$LocalData)
                
                if ($null -eq $Existing.Content) { return $false }
                
                try {
                    $parsed = $Existing.Content | ConvertFrom-Json
                    if ($parsed.encoding -eq "base64") {
                        $decoded = [System.Convert]::FromBase64String($parsed.content)
                        return [System.Linq.Enumerable]::SequenceEqual([byte[]]$decoded, $LocalData)
                    }
                }
                catch {
                    return $false
                }
                return $false
            }
            
            $lookupResult = Lookup-RemoteContent -RemoteName $name
            $existing = if ($lookupResult.Content) { 
                @{ Content = $lookupResult.Content | ConvertFrom-Json }
            } else { 
                $null 
            }
            
            if ($null -ne $existing -and -not (Test-SameContent -Existing $existing -LocalData $data)) {
                $candidate = [System.IO.Path]::GetDirectoryName($name)
                if (-not $candidate) { $candidate = "" }
                $filename = [System.IO.Path]::GetFileNameWithoutExtension($name)
                $extension = [System.IO.Path]::GetExtension($name)
                $alternate = if ($candidate) {
                    "$candidate/$filename_$($expected.Substring(0,12))$extension"
                } else {
                    "$filename_$($expected.Substring(0,12))$extension"
                }
                
                $lookupResult = Lookup-RemoteContent -RemoteName $alternate
                $existing = if ($lookupResult.Content) { 
                    @{ Content = $lookupResult.Content | ConvertFrom-Json }
                } else { 
                    $null 
                }
                
                if ($null -ne $existing -and -not (Test-SameContent -Existing $existing -LocalData $data)) {
                    throw "remote artifact conflict"
                }
            }
            
            if ($null -eq $existing) {
                $encodedContent = [System.Convert]::ToBase64String($data)
                $body = @{
                    message = "Publish script abstraction"
                    branch = "gateway1-abstractions"
                    content = $encodedContent
                } | ConvertTo-Json -Compress
                
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
                
                $request = [System.Net.WebRequest]::Create($lookupResult.Endpoint)
                $request.Method = "PUT"
                $request.Headers["Authorization"] = $headers.Authorization
                $request.Headers["Accept"] = $headers.Accept
                $request.Headers["X-GitHub-Api-Version"] = $headers."X-GitHub-Api-Version"
                $request.UserAgent = $headers."User-Agent"
                $request.ContentType = "application/json"
                $request.ContentLength = $bytes.Length
                $request.Timeout = 60000
                
                $stream = $request.GetRequestStream()
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Close()
                
                $response = $request.GetResponse()
                $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
                $content = $reader.ReadToEnd()
                $reader.Close()
                $response.Close()
            }
            
            $State["ausstehende_veroeffentlichungen"].Remove($name)
            & $Save $State
            
        }
        catch {
            $success = $false
        }
    }
    
    return $success
}
