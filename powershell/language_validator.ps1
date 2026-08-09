#!/usr/bin/env pwsh
# language_validator.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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

    ValidationResult([string]$Language, [bool]$Valid, [string[]]$Errors, [string[]]$Warnings, [string]$DocUrl) {
        $this.Language = $Language
        $this.Valid = $Valid
        $this.Errors = $Errors
        $this.Warnings = $Warnings
        $this.DocUrl = $DocUrl
    }
}

class LanguageValidator {
    [hashtable]$Languages = @{
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

    LanguageValidator([string]$Language, [bool]$UseWebSearch) {
        $this.Language = $Language.ToLower()
        $this.UseWebSearch = $UseWebSearch
        $this.Config = $this.Languages[$this.Language]
        if ($null -eq $this.Config) {
            throw "Unsupported language: $Language"
        }
    }

    [ValidationResult] Validate([string]$ScriptPath) {
        $Errors = @()
        $Warnings = @()

        # Syntax check
        try {
            $ProcessParams = @{
                FilePath = $this.Config["cmd"]
                ArgumentList = $this.Config["args"] + $ScriptPath
                NoNewWindow = $true
                Wait = $true
                RedirectStandardOutput = [System.IO.Path]::GetTempFileName()
                RedirectStandardError = [System.IO.Path]::GetTempFileName()
            }

            $Process = Start-Process @ProcessParams -PassThru
            $Process.WaitForExit(30000) # 30 seconds timeout

            if ($Process.ExitCode -ne 0) {
                $ErrorContent = Get-Content $ProcessParams.RedirectStandardError -Raw
                if ($ErrorContent) {
                    $Errors += $ErrorContent.Trim()
                }
            }

            Remove-Item $ProcessParams.RedirectStandardOutput -ErrorAction SilentlyContinue
            Remove-Item $ProcessParams.RedirectStandardError -ErrorAction SilentlyContinue
        }
        catch [System.TimeoutException] {
            $Errors += "Validation timeout"
        }
        catch {
            $Errors += "Command not found: $($this.Config['cmd'])"
            if ($this.UseWebSearch) {
                $DocUrl = $this._FetchDocs()
                return [ValidationResult]::new($this.Language, $false, $Errors, $Warnings, $DocUrl)
            }
        }

        # Linter check if available
        if ($this.Config["linter"]) {
            $LinterWarnings = $this._RunLinter($ScriptPath)
            $Warnings += $LinterWarnings
        }

        return [ValidationResult]::new($this.Language, $Errors.Count -eq 0, $Errors, $Warnings, $null)
    }

    [string[]] _RunLinter([string]$ScriptPath) {
        $Linter = $this.Config["linter"]
        $Warnings = @()

        try {
            if ($Linter -eq "shellcheck") {
                $Result = Start-Process -FilePath "shellcheck" -ArgumentList "-f", "gcc", $ScriptPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())
                $Output = Get-Content $Result.StartInfo.RedirectStandardOutput -Raw
                if ($Output) {
                    $Warnings += $Output.Trim().Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
                }
                Remove-Item $Result.StartInfo.RedirectStandardOutput -ErrorAction SilentlyContinue
                Remove-Item $Result.StartInfo.RedirectStandardError -ErrorAction SilentlyContinue
            }
            elseif ($Linter -eq "pylint") {
                $Result = Start-Process -FilePath "pylint" -ArgumentList "--output-format=parseable", $ScriptPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())
                $Output = Get-Content $Result.StartInfo.RedirectStandardOutput -Raw
                if ($Output) {
                    $Warnings += $Output.Trim().Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
                }
                Remove-Item $Result.StartInfo.RedirectStandardOutput -ErrorAction SilentlyContinue
                Remove-Item $Result.StartInfo.RedirectStandardError -ErrorAction SilentlyContinue
            }
        }
        catch {
            $Warnings += "Linter not installed: $Linter"
        }

        return $Warnings
    }

    [string] _FetchDocs() {
        if (-not $this.UseWebSearch) {
            return $null
        }

        # Return known good documentation URLs
        $Docs = @{
            "powershell" = "https://docs.microsoft.com/powershell/"
            "raku" = "https://docs.raku.org/"
            "tcl" = "https://www.tcl.tk/"
        }
        return $Docs[$this.Language]
    }
}

function Main {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$Lang,
        
        [switch]$NoWebSearch
    )

    try {
        $Validator = [LanguageValidator]::new($Lang, (-not $NoWebSearch))
        $Result = $Validator.Validate($Script)

        Write-Output "Language: $($Result.Language)"
        Write-Output "Valid: $($Result.Valid)"
        if ($Result.Errors.Count -gt 0) {
            Write-Output "Errors: $($Result.Errors.Count)"
            $Result.Errors | Select-Object -First 5 | ForEach-Object { Write-Output "  - $_" }
        }
        if ($Result.Warnings.Count -gt 0) {
            Write-Output "Warnings: $($Result.Warnings.Count)"
            $Result.Warnings | Select-Object -First 5 | ForEach-Object { Write-Output "  - $_" }
        }
        if ($Result.DocUrl) {
            Write-Output "Docs: $($Result.DocUrl)"
        }

        exit ($Result.Valid ? 0 : 1)
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Entry point
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Parse command line arguments
    $Script = $null
    $Lang = $null
    $NoWebSearch = $false

    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            "--lang" {
                $i++
                if ($i -lt $args.Count) {
                    $Lang = $args[$i]
                }
            }
            "--no-websearch" {
                $NoWebSearch = $true
            }
            default {
                if ($null -eq $Script -and -not $args[$i].StartsWith("-")) {
                    $Script = $args[$i]
                }
            }
        }
    }

    if ($null -eq $Script -or $null -eq $Lang) {
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) <script> --lang <language> [--no-websearch]"
        exit 1
    }

    Main -Script $Script -Lang $Lang -NoWebSearch:$NoWebSearch
}
