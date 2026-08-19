#!/usr/bin/env pwsh
# json_processor.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
JSON Processor mit Validierung und Reparatur.
Für robuste Verarbeitung von LLM-Outputs.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputValue,

    [switch]$File,

    [switch]$Repair = $true,

    [switch]$NoRepair,

    [switch]$Pretty
)

# Disable NoRepair if set
if ($NoRepair) { $Repair = $false }

# Custom Exception Classes
class JSONProcessingError : System.Exception {
    JSONProcessingError([string]$message) : base($message) {}
}

class JSONValidationError : JSONProcessingError {
    JSONValidationError([string]$message) : base($message) {}
}

class JSONRepairError : JSONProcessingError {
    JSONRepairError([string]$message) : base($message) {}
}


function Repair-JsonString {
    <#
    .SYNOPSIS
    Repariert häufige JSON-Fehler aus LLM-Outputs.
    #>
    param(
        [string]$RawJson
    )

    try {
        # Try to use Newtonsoft.Json.Linq if available (similar to json_repair)
        Add-Type -AssemblyName Newtonsoft.Json -ErrorAction SilentlyContinue
        if ([System.Management.Automation.PSTypeName]'Newtonsoft.Json.Linq.JObject'.TypeName) {
            $settings = New-Object Newtonsoft.Json.JsonSerializerSettings
            $settings.Formatting = 'None'
            $repaired = [Newtonsoft.Json.Linq.JObject]::Parse($RawJson)
            return $repaired.ToString()
        } else {
            Write-Warning "Newtonsoft.Json not found. Using fallback repairs."
        }
    } catch {
        Write-Warning "JSON repair with Newtonsoft failed: $_"
    }

    # Fallback: Manual repairs using regex
    $cleaned = $RawJson.Trim()

    # Remove JavaScript-style comments
    $cleaned = $cleaned -replace '//.*?$', '' -replace '/\*.*?\*/', ''

    # Remove trailing commas before ] or }
    $cleaned = $cleaned -replace ',(\s*[\}\]])', '$1'

    return $cleaned
}


function Parse-Json {
    <#
    .SYNOPSIS
    Parst JSON-String mit optionaler automatischer Reparatur.
    #>
    param(
        [string]$RawInput,
        [bool]$Repair = $true
    )

    $RawInput = $RawInput.Trim()

    # Try direct parsing first
    try {
        return $RawInput | ConvertFrom-Json
    } catch {
        # Continue to next steps
    }

    # Extract JSON from markdown code blocks
    if ($RawInput -match '```') {
        # Look for patterns like ```json ... ``` or ``` ... ```
        $patterns = @(
            '(?s)```json\s*(.*?)\s*```'
            '(?s)```\s*(\{.*?\})\s*```'
            '(?s)```\s*(\[.*?\])\s*```'
        )

        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($RawInput, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            foreach ($match in $matches) {
                try {
                    $jsonPart = $match.Groups[1].Value
                    return $jsonPart | ConvertFrom-Json
                } catch {
                    continue
                }
            }
        }
    }

    # Try repair
    if ($Repair) {
        try {
            $repaired = Repair-JsonString -RawJson $RawInput
            return $repaired | ConvertFrom-Json
        } catch {
            throw [JSONProcessingError]::new("Could not parse JSON even after repair: $_")
        }
    }

    throw [JSONProcessingError]::new("Could not parse JSON")
}


function ParseAndValidate {
    <#
    .SYNOPSIS
    Parst JSON und validiert gegen ein Schema.
    #>
    param(
        [string]$RawInput,
        [hashtable]$Schema,
        [bool]$Repair = $true,
        [bool]$Strict = $false
    )

    try {
        $data = Parse-Json -RawInput $RawInput -Repair $Repair
    } catch {
        throw [JSONValidationError]::new("JSON parsing failed: $_")
    }

    # Basic schema validation (PowerShell doesn't have built-in pydantic equivalent)
    # This is a simplified version that checks required fields only
    if ($Schema.ContainsKey("required")) {
        foreach ($field in $Schema.required) {
            if (-not (Get-Member -InputObject $data -Name $field -MemberType Properties)) {
                throw [JSONValidationError]::new("Missing required field: $field")
            }
        }
    }

    return $data
}


function Validate-ToolCall {
    <#
    .SYNOPSIS
    Validiert einen OpenClaw/Tool-Call JSON.
    #>
    param(
        [string]$RawJson,
        [string]$ToolName
    )

    $schema = @{
        required = @("tool", "arguments")
    }

    try {
        $toolCall = ParseAndValidate -RawInput $RawJson -Schema $schema -Repair $true
    } catch {
        throw [JSONValidationError]::new("Tool call validation failed: $_")
    }

    if ($ToolName -and $toolCall.tool -ne $ToolName) {
        throw [JSONValidationError]::new("Expected tool '$ToolName', got '$($toolCall.tool)'")
    }

    return @{
        tool = $toolCall.tool
        arguments = $toolCall.arguments
        reasoning = if ($toolCall.PSObject.Properties.Name -contains "reasoning") { $toolCall.reasoning } else { $null }
    }
}


function Safe-JsonLoads {
    <#
    .SYNOPSIS
    Sicheres JSON-Parsing mit Fallback auf Default-Wert.
    #>
    param(
        [string]$RawInput,
        [object]$Default = $null,
        [bool]$Repair = $true
    )

    try {
        return Parse-Json -RawInput $RawInput -Repair $Repair
    } catch {
        return $Default
    }
}


function Extract-JsonFromText {
    <#
    .SYNOPSIS
    Extrahiert alle JSON-Objekte aus einem Text.
    #>
    param(
        [string]$Text
    )

    $results = @()

    # Patterns for JSON objects and arrays
    $patterns = @(
        [regex]'(?s)\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'  # Objects
        [regex]'(?s)\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]'  # Arrays
    )

    foreach ($pattern in $patterns) {
        $matches = $pattern.Matches($Text)
        foreach ($match in $matches) {
            try {
                $parsed = Parse-Json -RawInput $match.Value -Repair $true
                $results += $parsed
            } catch {
                continue
            }
        }
    }

    return $results
}


# Main execution
try {
    $content = ""
    if ($File) {
        if (-not (Test-Path $InputValue)) {
            throw [System.IO.FileNotFoundException]::new("File not found: $InputValue")
        }
        $content = Get-Content -Path $InputValue -Raw
    } else {
        $content = $InputValue
    }

    $result = Parse-Json -RawInput $content -Repair $Repair

    if ($Pretty) {
        $result | ConvertTo-Json -Depth 100
    } else {
        $result | ConvertTo-Json -Compress
    }
} catch [JSONProcessingError] {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
} catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    exit 1
}
