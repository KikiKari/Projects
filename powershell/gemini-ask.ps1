#!/usr/bin/env pwsh
# gemini-ask.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    gemini-ask.ps1 - CLI tool for Google Gemini API

.DESCRIPTION
    This script allows you to interact with the Google Gemini API from the command line.
    You can provide a prompt as an argument, through stdin, or from a file.

.PARAMETER Prompt
    The prompt to send to the Gemini API.

.PARAMETER File
    Path to a file containing the prompt.

.PARAMETER Model
    The model to use (default: gemini-pro or GEMINI_MODEL environment variable).

.PARAMETER System
    System prompt to provide context or instructions.

.EXAMPLE
    .\gemini-ask.ps1 "Your question here"
    .\gemini-ask.ps1 -File prompt.txt
    .\gemini-ask.ps1 -Model gemini-pro "Your question"
    echo "Your question" | .\gemini-ask.ps1

.ENVIRONMENT
    GEMINI_API_KEY - Required API key
    GEMINI_MODEL   - Optional default model (default: gemini-pro)
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$PromptArgs,

    [Alias('f')]
    [string]$File,

    [Alias('m')]
    [string]$Model = $env:GEMINI_MODEL,

    [Alias('s')]
    [string]$System
)

# Set default model if not provided
if (-not $Model) {
    $Model = 'gemini-pro'
}

# Check API key
if (-not $env:GEMINI_API_KEY) {
    Write-Error "Error: GEMINI_API_KEY environment variable is required"
    exit 1
}

# Parse arguments to handle flags like --model, --file, etc.
$prompt = ""
$remainingArgs = @()

for ($i = 0; $i -lt $PromptArgs.Count; $i++) {
    $arg = $PromptArgs[$i]
    if ($arg -eq '--model' -or $arg -eq '-m') {
        if ($i + 1 -lt $PromptArgs.Count) {
            $Model = $PromptArgs[$i + 1]
            $i++
        }
    }
    elseif ($arg -eq '--system' -or $arg -eq '-s') {
        if ($i + 1 -lt $PromptArgs.Count) {
            $System = $PromptArgs[$i + 1]
            $i++
        }
    }
    elseif ($arg -eq '--file' -or $arg -eq '-f') {
        if ($i + 1 -lt $PromptArgs.Count) {
            $File = $PromptArgs[$i + 1]
            $i++
        }
    }
    else {
        $remainingArgs += $arg
    }
}

# Handle file input
if ($File) {
    if (Test-Path $File) {
        $prompt = Get-Content -Path $File -Raw
    } else {
        Write-Error "Error: File '$File' not found"
        exit 1
    }
}
# Handle positional arguments
elseif ($remainingArgs.Count -gt 0) {
    $prompt = $remainingArgs -join " "
}
# Handle stdin input
elseif (-not [Console]::IsInputRedirected) {
    Write-Error "Error: No prompt provided"
    Write-Host "Usage: gemini-ask ""your question"""
    Write-Host "       gemini-ask --model gemini-pro ""your question"""
    Write-Host "       echo ""your question"" | gemini-ask"
    exit 1
}
else {
    $prompt = [Console]::In.ReadToEnd()
}

if (-not $prompt.Trim()) {
    Write-Error "Error: No prompt provided"
    Write-Host "Usage: gemini-ask ""your question"""
    Write-Host "       gemini-ask --model gemini-pro ""your question"""
    Write-Host "       echo ""your question"" | gemini-ask"
    exit 1
}

try {
    # Prepare headers and body for REST API call
    $headers = @{
        'Content-Type' = 'application/json'
    }

    $generationConfig = @{
        maxOutputTokens = 8192
        temperature     = 0.7
        topP           = 0.95
    }

    if ($System) {
        # Use chat with system prompt
        $body = @{
            contents = @(
                @{ role = 'user'; parts = @(@{ text = $System }) },
                @{ role = 'model'; parts = @(@{ text = 'Understood. I will follow that instruction.' }) },
                @{ role = 'user'; parts = @(@{ text = $prompt }) }
            )
            generationConfig = $generationConfig
        }
    } else {
        # Direct generation
        $body = @{
            contents = @(
                @{ role = 'user'; parts = @(@{ text = $prompt }) }
            )
            generationConfig = $generationConfig
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 10
    $url = "https://generativelanguage.googleapis.com/v1beta/models/$Model:generateContent?key=$($env:GEMINI_API_KEY)"

    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $jsonBody

    if ($response.candidates -and $response.candidates.Count -gt 0) {
        $text = $response.candidates[0].content.parts[0].text
        Write-Output $text
    } else {
        Write-Error "No response from API"
        exit 1
    }
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    if ($_.Exception.Message -like "*API key*") {
        Write-Host "Make sure GEMINI_API_KEY is set correctly"
    }
    exit 1
}
