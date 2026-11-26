#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "a06ce069f7984735b079a0e45ec475d25d60cd4d78fddbd068b735d036323ff9", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "powershell"}
# gemini-ask.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
  gemini-ask.ps1 - CLI tool for Google Gemini API

.DESCRIPTION
  This script allows you to interact with the Google Gemini API from the command line.
  You can provide a question directly as an argument, read it from stdin, or load it from a file.

.PARAMETER Prompt
  The question or prompt to send to the Gemini API.

.PARAMETER File
  Path to a file containing the prompt.

.PARAMETER Model
  Specifies the model to use. Default is gemini-pro or the value of GEMINI_MODEL environment variable.

.PARAMETER System
  Provides a system-level instruction that guides the model's behavior.

.EXAMPLE
  .\gemini-ask.ps1 "Your question here"
  .\gemini-ask.ps1 -File prompt.txt
  Get-Content question.txt | .\gemini-ask.ps1
  .\gemini-ask.ps1 -Model gemini-pro "Your question"

.NOTES
  Requires GEMINI_API_KEY environment variable to be set.
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,

    [string]$File,

    [string]$Model,

    [string]$System
)

$DEFAULT_MODEL = if ($env:GEMINI_MODEL) { $env:GEMINI_MODEL } else { 'gemini-pro' }

function Main {
    # Check API key
    if (-not $env:GEMINI_API_KEY) {
        Write-Error "Error: GEMINI_API_KEY environment variable is required"
        exit 1
    }

    # Initialize variables
    $prompt = ''
    $modelName = $DEFAULT_MODEL
    $systemPrompt = ''

    # Parse arguments manually since we're handling complex cases
    $argsList = @()
    if ($RemainingArgs) {
        $argsList = $RemainingArgs
    }

    # Handle parameter-style arguments first
    if ($Model) {
        $modelName = $Model
    }

    if ($System) {
        $systemPrompt = $System
    }

    if ($File) {
        if (Test-Path $File) {
            $prompt = Get-Content -Path $File -Raw -Encoding UTF8
        } else {
            Write-Error "Error: File '$File' not found"
            exit 1
        }
    } elseif ($argsList.Count -gt 0) {
        # Join all remaining arguments into a single prompt string
        $prompt = ($argsList | ForEach-Object { $_ }) -join ' '
    } elseif (-not [Console]::IsInputRedirected) {
        # Read from stdin if available
        $stdin = [System.Console]::OpenStandardInput()
        $buffer = New-Object byte[] 1024
        $memoryStream = New-Object System.IO.MemoryStream
        do {
            $read = $stdin.Read($buffer, 0, $buffer.Length)
            if ($read -gt 0) {
                $memoryStream.Write($buffer, 0, $read)
            }
        } while ($read -gt 0)
        
        if ($memoryStream.Length -gt 0) {
            $encoding = New-Object System.Text.UTF8Encoding
            $prompt = $encoding.GetString($memoryStream.ToArray())
        }
        $memoryStream.Dispose()
    }

    if ([string]::IsNullOrWhiteSpace($prompt)) {
        Write-Error "Error: No prompt provided"
        Write-Host "Usage: gemini-ask `"your question`""
        Write-Host "       gemini-ask -Model gemini-pro `"your question`""
        Write-Host "       echo `"your question`" | gemini-ask"
        exit 1
    }

    try {
        # Since there's no direct PowerShell SDK for Gemini, we'll make REST calls
        $headers = @{
            'Content-Type' = 'application/json'
        }

        $uri = "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$($env:GEMINI_API_KEY)"

        $generationConfig = @{
            maxOutputTokens = 8192
            temperature     = 0.7
            topP            = 0.95
        }

        $bodyParts = @()

        if ($systemPrompt) {
            $bodyParts += @{
                role  = 'user'
                parts = @(@{text = $systemPrompt})
            }
            $bodyParts += @{
                role  = 'model'
                parts = @(@{text = 'Understood. I will follow that instruction.'})
            }
        }

        $bodyParts += @{
            role  = 'user'
            parts = @(@{text = $prompt.Trim()})
        }

        $body = @{
            contents         = $bodyParts
            generationConfig = $generationConfig
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body -UseBasicParsing

        if ($response.candidates -and $response.candidates[0].content.parts) {
            $outputText = ($response.candidates[0].content.parts | ForEach-Object { $_.text }) -join "`n"
            Write-Output $outputText
        } else {
            Write-Error "No valid response received from API"
            exit 1
        }
    } catch {
        Write-Error "Error: $($_.Exception.Message)"
        if ($_.Exception.Message -like '*API key*') {
            Write-Host "Make sure GEMINI_API_KEY is set correctly"
        }
        exit 1
    }
}

Main
