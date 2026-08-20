#!/usr/bin/env pwsh
# test_quick_validate.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_quick_validate.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Regression tests for quick skill validation.
#>

using namespace System.IO
using namespace System.Text

# Mock the quick_validate module functions
function Validate-Skill {
    param(
        [string]$SkillDir
    )
    
    $skillFile = Join-Path $SkillDir "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        return $false, "SKILL.md not found"
    }
    
    $content = Get-Content -Path $skillFile -Raw
    
    # Check for frontmatter fences
    $lines = $content -split "`n"
    $firstFenceIndex = -1
    $secondFenceIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            if ($firstFenceIndex -eq -1) {
                $firstFenceIndex = $i
            } elseif ($secondFenceIndex -eq -1) {
                $secondFenceIndex = $i
                break
            }
        }
    }
    
    if ($firstFenceIndex -eq -1 -or $secondFenceIndex -eq -1) {
        return $false, "Invalid frontmatter format"
    }
    
    return $true, ""
}

class TestQuickValidate {
    [string]$TempDir
    
    TestQuickValidate() {
        $this.TempDir = [Path]::Combine([Path]::GetTempPath(), "test_quick_validate_" + [Guid]::NewGuid().ToString())
        $null = New-Item -ItemType Directory -Path $this.TempDir -Force
    }
    
    [void] SetUp() {
        # Setup is done in constructor
    }
    
    [void] TearDown() {
        if (Test-Path $this.TempDir) {
            Remove-Item -Path $this.TempDir -Recurse -Force
        }
    }
    
    [void] TestAcceptsCrlfFrontmatter() {
        $skillDir = [Path]::Combine($this.TempDir, "crlf-skill")
        $null = New-Item -ItemType Directory -Path $skillDir -Force
        
        $content = "---`r`nname: crlf-skill`r`ndescription: ok`r`n---`r`n# Skill`n"
        $skillFile = [Path]::Combine($skillDir, "SKILL.md")
        [File]::WriteAllText($skillFile, $content, [Encoding]::UTF8)
        
        $result = Validate-Skill -SkillDir $skillDir
        $valid = $result[0]
        $message = $result[1]
        
        if (-not $valid) {
            throw "Test failed: $message"
        }
    }
    
    [void] TestRejectsMissingFrontmatterClosingFence() {
        $skillDir = [Path]::Combine($this.TempDir, "bad-skill")
        $null = New-Item -ItemType Directory -Path $skillDir -Force
        
        $content = "---`nname: bad-skill`ndescription: missing end`n# no closing fence`n"
        $skillFile = [Path]::Combine($skillDir, "SKILL.md")
        [File]::WriteAllText($skillFile, $content, [Encoding]::UTF8)
        
        $result = Validate-Skill -SkillDir $skillDir
        $valid = $result[0]
        $message = $result[1]
        
        if ($valid) {
            throw "Test should have failed but passed"
        }
        
        if ($message -ne "Invalid frontmatter format") {
            throw "Expected 'Invalid frontmatter format' but got '$message'"
        }
    }
    
    [void] TestFallbackParserHandlesMultilineFrontmatterWithoutPyyaml() {
        $skillDir = [Path]::Combine($this.TempDir, "multiline-skill")
        $null = New-Item -ItemType Directory -Path $skillDir -Force
        
        $content = @" 
---
name: multiline-skill
description: Works without pyyaml
allowed-tools:
  - gh
metadata: |
  {
    "owners": ["team-openclaw"]
  }
---
# Skill
"@
        
        $skillFile = [Path]::Combine($skillDir, "SKILL.md")
        [File]::WriteAllText($skillFile, $content, [Encoding]::UTF8)
        
        # In PowerShell we don't need to mock yaml library as our Validate-Skill doesn't use it
        $result = Validate-Skill -SkillDir $skillDir
        $valid = $result[0]
        $message = $result[1]
        
        if (-not $valid) {
            throw "Test failed: $message"
        }
    }
}

# Main execution
try {
    Write-Host "Running tests..." -ForegroundColor Green
    
    $test = [TestQuickValidate]::new()
    $test.SetUp()
    
    try {
        Write-Host "Testing CRLF frontmatter..." -NoNewline
        $test.TestAcceptsCrlfFrontmatter()
        Write-Host " PASSED" -ForegroundColor Green
        
        Write-Host "Testing missing frontmatter closing fence..." -NoNewline
        $test.TestRejectsMissingFrontmatterClosingFence()
        Write-Host " PASSED" -ForegroundColor Green
        
        Write-Host "Testing multiline frontmatter..." -NoNewline
        $test.TestFallbackParserHandlesMultilineFrontmatterWithoutPyyaml()
        Write-Host " PASSED" -ForegroundColor Green
        
        Write-Host "All tests passed!" -ForegroundColor Green
    }
    finally {
        $test.TearDown()
    }
}
catch {
    Write-Error "Test failed: $($_.Exception.Message)"
    exit 1
}
