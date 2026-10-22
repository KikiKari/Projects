#!/usr/bin/env pwsh
# verify-downloads.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:site/scripts/verify-downloads.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/scripts/verify-downloads.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Verify the candidate's actual HTTP downloads against committed files.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BaseUrl,

    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]$Report
)

$ErrorActionPreference = 'Stop'

# Get script directory and root path
$scriptPath = $PSScriptRoot
$root = Split-Path -Path $scriptPath -Parent

# Define checksum file path
$checksum = Join-Path $root 'public/downloads/tiktok-live-companion-0.8.2-SHA256.txt'

# Initialize results array
$results = @()

# Read checksum file content
$checksumContent = Get-Content -Path $checksum -Encoding utf8

foreach ($line in $checksumContent) {
    if (-not $line.Trim()) { continue }
    
    # Split line into expected hash and filename
    $parts = $line.Split('  ', 2)
    $expected = $parts[0]
    $name = $parts[1]
    
    # Build URL
    $baseUrlTrimmed = $BaseUrl.TrimEnd('/')
    $url = "$baseUrlTrimmed/downloads/$name"
    
    try {
        # Download file content
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
        $data = $response.Content
        
        # Convert string data to byte array for proper hashing
        $encoding = [System.Text.Encoding]::UTF8
        $dataBytes = $encoding.GetBytes($data)
        
        # Calculate actual SHA256 hash
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $actualBytes = $sha256.ComputeHash($dataBytes)
        $actual = [BitConverter]::ToString($actualBytes).Replace('-', '').ToLower()
        
        # Compare with expected hash
        if ($actual -ne $expected) {
            throw "HTTP artifact mismatch: $name"
        }
        
        # Compare with local file content
        $localFilePath = Join-Path $root "public/downloads/$name"
        if (-not (Test-Path $localFilePath)) {
            throw "Local file not found: $localFilePath"
        }
        
        $localFileContent = [System.IO.File]::ReadAllBytes($localFilePath)
        if (-not (Compare-Object $dataBytes $localFileContent -SyncWindow 0)) {
            throw "HTTP artifact mismatch: $name"
        }
        
        # Create memory stream from downloaded data for zip operations
        $memoryStream = New-Object System.IO.MemoryStream($dataBytes, 0, $dataBytes.Length)
        $memoryStream.Position = 0
        
        # Open zip archive
        $archive = New-Object System.IO.Compression.ZipArchive($memoryStream, [System.IO.Compression.ZipArchiveMode]::Read)
        
        # Test zip integrity
        $corruptedEntry = $null
        foreach ($entry in $archive.Entries) {
            try {
                $stream = $entry.Open()
                $stream.Close()
            } catch {
                $corruptedEntry = $entry.FullName
                break
            }
        }
        
        if ($corruptedEntry) {
            throw "Corrupt archive: $name at entry $corruptedEntry"
        }
        
        # Special checks for extension archives
        if ($name.Contains('-extension-')) {
            # Read manifest.json
            $manifestEntry = $archive.GetEntry('manifest.json')
            if ($manifestEntry) {
                $manifestStream = New-Object System.IO.StreamReader($manifestEntry.Open())
                $manifestContent = $manifestStream.ReadToEnd()
                $manifestStream.Close()
                
                $manifest = $manifestContent | ConvertFrom-Json
                
                if ($manifest.version -ne '0.8.2') {
                    throw "Wrong extension version"
                }
                
                # Check source files
                $sourceFiles = @('background.js', 'content.js', 'sidepanel.js', 'sidepanel.html')
                $sourceBasePath = Join-Path (Split-Path -Path $root -Parent) 'plugin-source/browser-extension'
                
                foreach ($source in $sourceFiles) {
                    $sourceEntry = $archive.GetEntry($source)
                    if ($sourceEntry) {
                        $sourceStream = New-Object System.IO.MemoryStream
                        $sourceEntryStream = $sourceEntry.Open()
                        $sourceEntryStream.CopyTo($sourceStream)
                        $sourceEntryStream.Close()
                        
                        $archiveContent = $sourceStream.ToArray()
                        $sourceStream.Close()
                        
                        $sourceFilePath = Join-Path $sourceBasePath $source
                        if (Test-Path $sourceFilePath) {
                            $fileContent = [System.IO.File]::ReadAllBytes($sourceFilePath)
                            
                            if (-not (Compare-Object $archiveContent $fileContent -SyncWindow 0)) {
                                throw "Extension source mismatch: $source"
                            }
                        } else {
                            throw "Source file not found: $sourceFilePath"
                        }
                    } else {
                        throw "Missing source file in archive: $source"
                    }
                }
            } else {
                throw "Missing manifest.json in extension archive"
            }
        }
        
        # Close archive and memory stream
        $archive.Dispose()
        $memoryStream.Close()
        
        # Add result
        $results += @{
            name = $name
            sha256 = $actual
            bytes = $dataBytes.Length
            verified = $true
        }
    } catch {
        # Clean up resources on error
        if ($archive) { $archive.Dispose() }
        if ($memoryStream) { $memoryStream.Close() }
        throw $_
    }
}

# Prepare report data
$reportData = @{
    base_url = $BaseUrl
    artifacts = $results
}

# Write report file
$reportJson = ConvertTo-Json $reportData -Depth 10 -Indentation 2
Set-Content -Path $Report.FullName -Value $reportJson -Encoding utf8

# Output results
Write-Output (ConvertTo-Json $results -Depth 10 -Indentation 2)
