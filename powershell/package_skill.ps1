#!/usr/bin/env pwsh
# package_skill.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/package_skill.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Skill Packager - Creates a distributable .skill file of a skill folder

.DESCRIPTION
This script packages a skill folder into a .skill file (zip format).
It validates the skill before packaging and excludes certain directories.

.PARAMETER SkillPath
The path to the skill folder to be packaged.

.PARAMETER OutputDirectory
Optional output directory for the .skill file (defaults to current directory).

.EXAMPLE
powershell -File utils/package_skill.ps1 skills/public/my-skill
powershell -File utils/package_skill.ps1 skills/public/my-skill ./dist
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillPath,
    
    [string]$OutputDirectory
)

# Import required modules
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Test-IsWithin {
    param(
        [System.IO.DirectoryInfo]$Path,
        [System.IO.DirectoryInfo]$Root
    )
    
    try {
        $null = $Path.FullName.Substring($Root.FullName.Length) 
        return $true
    }
    catch {
        return $false
    }
}

function Import-QuickValidate {
    # Convert relative path to absolute for importing
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $validatePath = Join-Path $scriptDir "quick_validate.ps1"
    
    if (-not (Test-Path $validatePath)) {
        $validatePath = Join-Path (Get-Location) "utils/quick_validate.ps1"
    }
    
    if (Test-Path $validatePath) {
        . $validatePath
        return $true
    }
    else {
        Write-Error "Cannot find quick_validate.ps1"
        return $false
    }
}

function Invoke-PackageSkill {
    param(
        [string]$SkillPathParam,
        [string]$OutputDirParam
    )
    
    $skillPath = Resolve-Path $SkillPathParam -ErrorAction SilentlyContinue
    if (-not $skillPath) {
        Write-Host "[ERROR] Skill folder not found: $SkillPathParam" -ForegroundColor Red
        return $null
    }
    
    $skillPath = Get-Item $skillPath.Path
    if (-not $skillPath.PSIsContainer) {
        Write-Host "[ERROR] Path is not a directory: $($skillPath.FullName)" -ForegroundColor Red
        return $null
    }
    
    $skillMd = Join-Path $skillPath.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) {
        Write-Host "[ERROR] SKILL.md not found in $($skillPath.FullName)" -ForegroundColor Red
        return $null
    }
    
    Write-Host "Validating skill..."
    $validationResult = Confirm-SkillValidation $skillPath.FullName
    
    if (-not $validationResult.Valid) {
        Write-Host "[ERROR] Validation failed: $($validationResult.Message)" -ForegroundColor Red
        Write-Host "   Please fix the validation errors before packaging." -ForegroundColor Red
        return $null
    }
    
    Write-Host "[OK] $($validationResult.Message)`n" -ForegroundColor Green
    
    $skillName = $skillPath.Name
    
    if ($OutputDirParam) {
        $outputPath = Resolve-Path $OutputDirParam -ErrorAction SilentlyContinue
        if (-not $outputPath) {
            $outputPath = New-Item -ItemType Directory -Path $OutputDirParam -Force
        }
        else {
            $outputPath = Get-Item $outputPath.Path
        }
    }
    else {
        $outputPath = Get-Location
    }
    
    $skillFilename = Join-Path $outputPath.FullName "$skillName.skill"
    
    $excludedDirs = @(".git", ".svn", ".hg", "__pycache__", "node_modules")
    
    try {
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($skillPath.FullName, $skillFilename, $compressionLevel, $false)
        
        # Reopen the zip to remove excluded files/dirs
        $zipArchive = [System.IO.Compression.ZipFile]::Open($skillFilename, "Update")
        
        $entriesToRemove = @()
        foreach ($entry in $zipArchive.Entries) {
            # Check if entry contains excluded directories
            $pathParts = $entry.FullName -split '/'
            foreach ($part in $pathParts) {
                if ($excludedDirs -contains $part) {
                    $entriesToRemove += $entry
                    break
                }
            }
            
            # Skip symlinks (symbolic links are not preserved in zip)
            # This is just a safety check - PowerShell doesn't easily detect symlinks in zip entries
        }
        
        foreach ($entry in $entriesToRemove) {
            Write-Host "[WARN] Skipping excluded content: $($entry.FullName)" -ForegroundColor Yellow
            $entry.Delete()
        }
        
        # Additional security checks would go here if needed
        
        $zipArchive.Dispose()
        
        Write-Host "`n[OK] Successfully packaged skill to: $skillFilename" -ForegroundColor Green
        return $skillFilename
    }
    catch {
        Write-Host "[ERROR] Error creating .skill file: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Main execution
try {
    if (-not (Import-QuickValidate)) {
        exit 1
    }
    
    Write-Host "Packaging skill: $SkillPath"
    if ($OutputDirectory) {
        Write-Host "   Output directory: $OutputDirectory"
    }
    Write-Host ""
    
    $result = Invoke-PackageSkill -SkillPathParam $SkillPath -OutputDirParam $OutputDirectory
    
    if ($result) {
        exit 0
    }
    else {
        exit 1
    }
}
catch {
    Write-Host "[ERROR] Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
