#!/usr/bin/env pwsh
# json_schema_validator.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
Erweitert Pydantic mit externen Schema-Dateien.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputValue,
    
    [Parameter(Mandatory=$true)]
    [string]$Schema,
    
    [switch]$File,
    
    [switch]$Repair = $true
)

class SchemaValidationError : System.Exception {
    SchemaValidationError([string]$message) : base($message) {}
}

function Load-Schema {
    param(
        [Parameter(Mandatory=$true)]
        [object]$SchemaSource
    )
    
    if ($SchemaSource -is [hashtable]) {
        return $SchemaSource
    }
    
    $schemaPath = [System.IO.Path]::GetFullPath($SchemaSource)
    if (Test-Path $schemaPath -PathType Leaf) {
        try {
            $content = Get-Content -Path $schemaPath -Raw
            return $content | ConvertFrom-Json -AsHashtable
        } catch {
            throw [SchemaValidationError]::new("Invalid JSON in schema file: $($_.Exception.Message)")
        }
    }
    
    # Versuche als JSON String zu parsen
    try {
        return $SchemaSource | ConvertFrom-Json -AsHashtable
    } catch {
        throw [SchemaValidationError]::new("Schema not found or invalid: $SchemaSource")
    }
}

function Validate-WithJsonSchema {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Data,
        
        [Parameter(Mandatory=$true)]
        [object]$Schema,
        
        [string]$Draft = "auto"
    )
    
    # PowerShell hat keine native JSON Schema Validierung
    # Daher wird hier eine vereinfachte Implementierung verwendet
    # In einer produktiven Umgebung sollte eine vollständige Implementierung verwendet werden
    
    $schemaDict = Load-Schema -SchemaSource $Schema
    
    # Einfache Validierung - prüft nur ob die Struktur übereinstimmt
    # Dies ist KEINE vollständige JSON Schema Validierung!
    
    if ($schemaDict.type -eq "object" -and $Data -is [hashtable]) {
        if ($schemaDict.required) {
            foreach ($requiredProp in $schemaDict.required) {
                if (-not $Data.ContainsKey($requiredProp)) {
                    throw [SchemaValidationError]::new("Required property '$requiredProp' is missing")
                }
            }
        }
        
        if ($schemaDict.properties) {
            foreach ($key in $Data.Keys) {
                if ($schemaDict.properties.ContainsKey($key)) {
                    $propSchema = $schemaDict.properties[$key]
                    if ($propSchema.type -eq "string" -and $Data[$key] -isnot [string]) {
                        throw [SchemaValidationError]::new("Property '$key' should be string")
                    }
                    if ($propSchema.type -eq "integer" -and $Data[$key] -isnot [int]) {
                        throw [SchemaValidationError]::new("Property '$key' should be integer")
                    }
                }
            }
        }
        return $true
    }
    
    throw [SchemaValidationError]::new("Schema validation failed: Data does not match schema")
}

function Parse-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RawInput,
        
        [bool]$Repair = $true
    )
    
    try {
        return $RawInput | ConvertFrom-Json -AsHashtable
    } catch {
        if ($Repair) {
            # Versuche einfache Reparaturen
            $repaired = $RawInput -replace "'", '"' -replace "True", "true" -replace "False", "false" -replace "None", "null"
            try {
                return $repaired | ConvertFrom-Json -AsHashtable
            } catch {
                throw [System.Exception]::new("Failed to parse JSON: $($_.Exception.Message)")
            }
        } else {
            throw [System.Exception]::new("Failed to parse JSON: $($_.Exception.Message)")
        }
    }
}

function Validate-AndConvert {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RawInput,
        
        [Parameter(Mandatory=$true)]
        [object]$Schema,
        
        [bool]$Repair = $true
    )
    
    $data = Parse-Json -RawInput $RawInput -Repair $Repair
    Validate-WithJsonSchema -Data $data -Schema $Schema
    return $data
}

class SchemaBuilder {
    static [hashtable] Object([hashtable]$Properties, [string[]]$Required) {
        $schema = @{
            type = "object"
            properties = $Properties
        }
        if ($Required) {
            $schema.required = $Required
        }
        return $schema
    }
    
    static [hashtable] String([string[]]$Enum, [string]$Pattern, [int]$MinLength) {
        $schema = @{ type = "string" }
        if ($Enum) {
            $schema.enum = $Enum
        }
        if ($Pattern) {
            $schema.pattern = $Pattern
        }
        if ($MinLength -ne $null) {
            $schema.minLength = $MinLength
        }
        return $schema
    }
    
    static [hashtable] Integer([int]$Minimum, [int]$Maximum) {
        $schema = @{ type = "integer" }
        if ($Minimum -ne $null) {
            $schema.minimum = $Minimum
        }
        if ($Maximum -ne $null) {
            $schema.maximum = $Maximum
        }
        return $schema
    }
    
    static [hashtable] Array([hashtable]$Items, [int]$MinItems) {
        $schema = @{
            type = "array"
            items = $Items
        }
        if ($MinItems -ne $null) {
            $schema.minItems = $MinItems
        }
        return $schema
    }
}

try {
    # Lade Input (Auto-detect file vs string)
    $rawInput = ""
    if ($File -or (Test-Path $InputValue -PathType Leaf)) {
        $rawInput = Get-Content -Path $InputValue -Raw
    } else {
        $rawInput = $InputValue
    }
    
    $result = Validate-AndConvert -RawInput $rawInput -Schema $Schema -Repair $Repair
    $result | ConvertTo-Json -Depth 100 | Write-Output
    Write-Error "✓ Validation passed" -ErrorAction SilentlyContinue
} catch [SchemaValidationError] {
    Write-Error "✗ Validation failed: $($_.Exception.Message)" -ErrorAction Stop
} catch {
    Write-Error "✗ Validation failed: $($_.Exception.Message)" -ErrorAction Stop
}
