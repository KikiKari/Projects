#!/usr/bin/env pwsh
# quick_validate.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/quick_validate.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Quick validation script for skills - minimal version
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillDirectory
)

$MAX_SKILL_NAME_LENGTH = 64

function Extract-Frontmatter {
    param([string]$Content)
    
    $lines = $Content -split "`n"
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") {
        return $null
    }
    
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            return ($lines[1..($i-1)] -join "`n")
        }
    }
    
    return $null
}

function Parse-SimpleFrontmatter {
    param([string]$FrontmatterText)
    
    $parsed = @{}
    $currentKey = $null
    
    foreach ($rawLine in ($FrontmatterText -split "`n")) {
        $stripped = $rawLine.Trim()
        if (-not $stripped -or $stripped.StartsWith("#")) {
            continue
        }
        
        $isIndented = [char]::IsWhiteSpace($rawLine[0])
        if ($isIndented) {
            if ($null -eq $currentKey) {
                return $null
            }
            $currentValue = $parsed[$currentKey]
            if ($currentValue) {
                $parsed[$currentKey] = "$currentValue`n$stripped"
            } else {
                $parsed[$currentKey] = $stripped
            }
            continue
        }
        
        if (-not $stripped.Contains(":")) {
            return $null
        }
        
        $parts = $stripped.Split(":", 2)
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        
        if (-not $key) {
            return $null
        }
        
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or 
            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        
        $parsed[$key] = $value
        $currentKey = $key
    }
    
    return $parsed
}

function Validate-Skill {
    param([string]$SkillPath)
    
    $skillMdPath = Join-Path $SkillPath "SKILL.md"
    
    if (-not (Test-Path $skillMdPath)) {
        return $false, "SKILL.md not found"
    }
    
    try {
        $content = Get-Content -Path $skillMdPath -Encoding UTF8 -Raw
    } catch {
        return $false, "Could not read SKILL.md: $($_.Exception.Message)"
    }
    
    $frontmatterText = Extract-Frontmatter $content
    if ($null -eq $frontmatterText) {
        return $false, "Invalid frontmatter format"
    }
    
    $frontmatter = Parse-SimpleFrontmatter $frontmatterText
    if ($null -eq $frontmatter) {
        return $false, "Invalid YAML in frontmatter: unsupported syntax without PyYAML installed"
    }
    
    $allowedProperties = @("name", "description", "license", "allowed-tools", "metadata")
    $unexpectedKeys = ($frontmatter.Keys | Where-Object { $_ -notin $allowedProperties })
    
    if ($unexpectedKeys.Count -gt 0) {
        $allowedList = ($allowedProperties | Sort-Object) -join ", "
        $unexpectedList = ($unexpectedKeys | Sort-Object) -join ", "
        return $false, "Unexpected key(s) in SKILL.md frontmatter: $unexpectedList. Allowed properties are: $allowedList"
    }
    
    if (-not $frontmatter.ContainsKey("name")) {
        return $false, "Missing 'name' in frontmatter"
    }
    
    if (-not $frontmatter.ContainsKey("description")) {
        return $false, "Missing 'description' in frontmatter"
    }
    
    $name = $frontmatter["name"]
    if ($null -eq $name) { $name = "" }
    $name = $name.Trim()
    
    if ($name) {
        if ($name -notmatch "^[a-z0-9-]+$") {
            return $false, "Name '$name' should be hyphen-case (lowercase letters, digits, and hyphens only)"
        }
        
        if ($name.StartsWith("-") -or $name.EndsWith("-") -or $name.Contains("--")) {
            return $false, "Name '$name' cannot start/end with hyphen or contain consecutive hyphens"
        }
        
        if ($name.Length -gt $MAX_SKILL_NAME_LENGTH) {
            return $false, "Name is too long ($($name.Length) characters). Maximum is $MAX_SKILL_NAME_LENGTH characters."
        }
    }
    
    $description = $frontmatter["description"]
    if ($null -eq $description) { $description = "" }
    $description = $description.Trim()
    
    if ($description) {
        if ($description.Contains("<") -or $description.Contains(">")) {
            return $false, "Description cannot contain angle brackets (< or >)"
        }
        
        if ($description.Length -gt 1024) {
            return $false, "Description is too long ($($description.Length) characters). Maximum is 1024 characters."
        }
    }
    
    return $true, "Skill is valid!"
}

# Main execution
if ($args.Count -ne 1) {
    Write-Host "Usage: powershell quick_validate.ps1 <skill_directory>"
    exit 1
}

$valid, $message = Validate-Skill $SkillDirectory
Write-Host $message
if ($valid) {
    exit 0
} else {
    exit 1
}
