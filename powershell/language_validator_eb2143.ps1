#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "e7a3f293466605ae578d00899a1724d43da4d548aeb1755b0ea28c453fe24dad", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "powershell"}
# language_validator.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Multi-language script validator supporting 8+ languages.
WebSearch integration for documentation lookup.
#>

class ValidationResult {
    [string]$Language
    [bool]$Valid
    [string[]]$Errors
    [string[]]$Warnings
    [string]$DocUrl

    ValidationResult([string]$language, [bool]$valid, [string[]]$errors, [string[]]$warnings, [string]$docUrl) {
        $this.Language = $language
        $this.Valid = $valid
        $this.Errors = $errors
        $this.Warnings = $warnings
        $this.DocUrl = $docUrl
    }
}

class LanguageValidator {
    static [hashtable]$Languages = @{
        "bash" = @{ cmd = "bash"; args = @("-n"); linter = "shellcheck" }
        "sh" = @{ cmd = "sh"; args = @("-n"); linter = "shellcheck" }
        "python" = @{ cmd = "python3"; args = @("-m", "py_compile"); linter = "pylint" }
        "perl" = @{ cmd = "perl"; args = @("-c"); linter = "perlcritic" }
        "raku" = @{ cmd = "raku"; args = @("-c"); linter = $null }
        "powershell" = @{ cmd = "pwsh"; args = @("-Command", "Get-Command"); linter = $null }
        "javascript" = @{ cmd = "node"; args = @("--check"); linter = "eslint" }
        "tcl" = @{ cmd = "tclsh"; args = @(); linter = $null }
    }

    [string]$Language
    [bool]$UseWebSearch
    [hashtable]$Config

    LanguageValidator([string]$language, [bool]$useWebSearch) {
        $this.Language = $language.ToLower()
        $this.UseWebSearch = $useWebSearch
        $this.Config = [LanguageValidator]::Languages[$this.Language]
        if ($null -eq $this.Config) {
            throw "Unsupported language: $language"
        }
    }

    [ValidationResult] Validate([string]$scriptPath) {
        $errors = @()
        $warnings = @()

        # Syntax check
        try {
            $allArgs = @($this.Config.cmd) + $this.Config.args + @($scriptPath)
            $result = Start-Process -FilePath $this.Config.cmd -ArgumentList $allArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput $null -RedirectStandardError "stderr.txt"
            
            if ($result.ExitCode -ne 0) {
                $errorContent = Get-Content "stderr.txt" -ErrorAction SilentlyContinue
                if ($errorContent) {
                    $errors += $errorContent
                } else {
                    $errors += "Syntax error occurred but no output captured."
                }
            }
        } catch {
            if ($_ -match "timeout") {
                $errors += "Validation timeout"
            } elseif ($_ -match "command.*not found") {
                $errors += "Command not found: $($this.Config.cmd)"
                if ($this.UseWebSearch) {
                    $docUrl = $this.FetchDocs()
                    return [ValidationResult]::new($this.Language, $false, $errors, $warnings, $docUrl)
                }
            } else {
                $errors += $_.Exception.Message
            }
        } finally {
            if (Test-Path "stderr.txt") {
                Remove-Item "stderr.txt" -Force
            }
        }

        # Linter check if available
        if ($this.Config.linter) {
            $linterWarnings = $this.RunLinter($scriptPath)
            $warnings += $linterWarnings
        }

        return [ValidationResult]::new($this.Language, ($errors.Count -eq 0), $errors, $warnings, $null)
    }

    [string[]] RunLinter([string]$scriptPath) {
        $linter = $this.Config.linter
        $warnings = @()

        try {
            switch ($linter) {
                "shellcheck" {
                    $result = Start-Process -FilePath "shellcheck" -ArgumentList "-f", "gcc", $scriptPath -NoNewWindow -PassThru -Wait -RedirectStandardOutput "stdout.txt" -RedirectStandardError "stderr.txt"
                    if ((Get-Content "stdout.txt" -ErrorAction SilentlyContinue)) {
                        $warnings += Get-Content "stdout.txt"
                    }
                }
                "pylint" {
                    $result = Start-Process -FilePath "pylint" -ArgumentList "--output-format=parseable", $scriptPath -NoNewWindow -PassThru -Wait -RedirectStandardOutput "stdout.txt" -RedirectStandardError "stderr.txt"
                    if ((Get-Content "stdout.txt" -ErrorAction SilentlyContinue)) {
                        $warnings += Get-Content "stdout.txt"
                    }
                }
            }
        } catch {
            $warnings += "Linter not installed: $linter"
        } finally {
            foreach ($file in @("stdout.txt", "stderr.txt")) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                }
            }
        }

        return $warnings
    }

    [string] FetchDocs() {
        if (-not $this.UseWebSearch) {
            return $null
        }

        $docs = @{
            "powershell" = "https://docs.microsoft.com/powershell/"
            "raku" = "https://docs.raku.org/"
            "tcl" = "https://www.tcl.tk/"
        }

        return $docs[$this.Language]
    }
}

function Main {
    param(
        [Parameter(Mandatory=$true)][string]$Script,
        [Parameter(Mandatory=$true)][string]$Lang,
        [switch]$NoWebSearch
    )

    try {
        $validator = [LanguageValidator]::new($Lang, (-not $NoWebSearch))
        $result = $validator.Validate($Script)

        Write-Host "Language: $($result.Language)"
        Write-Host "Valid: $($result.Valid)"

        if ($result.Errors.Count -gt 0) {
            Write-Host "Errors: $($result.Errors.Count)"
            $result.Errors | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
        }

        if ($result.Warnings.Count -gt 0) {
            Write-Host "Warnings: $($result.Warnings.Count)"
            $result.Warnings | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
        }

        if ($result.DocUrl) {
            Write-Host "Docs: $($result.DocUrl)"
        }

        exit (if ($result.Valid) { 0 } else { 1 })
    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Entry point simulation
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # This would normally be handled by command-line parsing
    # Here we simulate basic parameter handling
    $scriptPath = $args[0]
    $langIndex = [array]::IndexOf($args, "--lang")
    $langValue = if ($langIndex -ge 0 -and $langIndex + 1 -lt $args.Length) { $args[$langIndex + 1] } else { $null }
    $noWebSearch = [array]::Contains($args, "--no-websearch")

    if (-not $scriptPath -or -not $langValue) {
        Write-Host "Usage: language_validator.ps1 <script> --lang <language> [--no-websearch]"
        exit 1
    }

    Main -Script $scriptPath -Lang $langValue -NoWebSearch:$noWebSearch
}
